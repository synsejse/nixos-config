"""Update all NixOS inputs and custom sources, then verify the full system builds."""

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import urllib.error
import urllib.request


def update_release_inputs(repo: Path) -> None:
    flake = repo / "flake.nix"
    original = text = flake.read_text()
    for name, upstream in (
        ("mocktail", "komaruworld/mocktail"),
        ("lanzaboote", "nix-community/lanzaboote"),
    ):
        headers = {"Accept": "application/vnd.github+json", "User-Agent": "nixos-update"}
        if token := os.environ.get("GITHUB_TOKEN"):
            headers["Authorization"] = f"Bearer {token}"
        request = urllib.request.Request(
            f"https://api.github.com/repos/{upstream}/releases/latest", headers=headers
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            release = json.load(response)
        tag = release.get("tag_name", "")
        if release.get("draft") or release.get("prerelease") or not re.fullmatch(
            r"v?\d+(?:\.\d+)+", tag
        ):
            raise ValueError(f"Unexpected stable release tag for {upstream}: {tag!r}")
        text, count = re.subn(
            rf'"github:{re.escape(upstream)}/[^"\n]+"',
            f'"github:{upstream}/{tag}"',
            text,
        )
        if count != 1:
            raise ValueError(f"Expected exactly one {name} input URL in flake.nix")
        print(f"Latest {name} release: {tag}", flush=True)
    if text != original:
        flake.write_text(text)


def main() -> None:
    parser = argparse.ArgumentParser(prog="update-system", description=__doc__)
    parser.add_argument("config", nargs="?", default="/etc/nixos", help="config directory")
    repo = Path(parser.parse_args().config).resolve()
    for relative in (
        "flake.nix",
        "pkgs/t3code/default.nix",
        "pkgs/mocktail-vr/default.nix",
        "pkgs/pangolin-client/default.nix",
    ):
        if not (repo / relative).is_file():
            parser.error(f"Missing {relative} in {repo}")

    def run(*args: str) -> None:
        print(f"$ {shlex.join(args)}", flush=True)
        subprocess.run(args, cwd=repo, check=True)

    try:
        update_release_inputs(repo)
        run("nix", "flake", "update")
        run(
            "nix-update", "--file", "update-packages.nix", "--version=unstable",
            "--version-regex", "v(.*-nightly[.].*)",
            "--use-github-releases", "--github-releases-limit", "100",
            "--override-filename", "pkgs/t3code/default.nix", "t3code",
        )
        run(
            "nix-update", "--file", "update-packages.nix",
            "--version-regex", "linux-(.*)",
            "--use-github-releases", "--github-releases-limit", "100",
            "--override-filename", "pkgs/pangolin-client/default.nix", "pangolin-client",
        )
        run(
            "nix-update", "--file", "update-packages.nix", "--version=branch=vr",
            "--override-filename", "pkgs/mocktail-vr/default.nix", "mocktail-vr",
        )
        run("nix", "build", "--no-link", ".#nixosConfigurations.nixos.config.system.build.toplevel")
    except (OSError, ValueError, urllib.error.URLError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Update failed; the running system is unchanged: {error}\n")

    print("\nAll sources are current and the system builds successfully.")
    print(f"Review: git -C {shlex.quote(str(repo))} diff")
    print(f"Activate: sudo nixos-rebuild switch --flake {shlex.quote(str(repo) + '#nixos')}")
    print("Restart updated applications after activation; reboot for kernel/desktop updates.")


if __name__ == "__main__":
    main()

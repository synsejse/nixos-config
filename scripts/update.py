"""Update all NixOS inputs and custom sources, then verify the full system builds."""

import argparse
from pathlib import Path
import shlex
import subprocess


def main() -> None:
    parser = argparse.ArgumentParser(prog="update-system", description=__doc__)
    parser.add_argument("config", nargs="?", default="/etc/nixos", help="config directory")
    repo = Path(parser.parse_args().config).resolve()
    for relative in ("flake.nix", "pkgs/t3code/default.nix"):
        if not (repo / relative).is_file():
            parser.error(f"Missing {relative} in {repo}")

    def run(*args: str) -> None:
        print(f"$ {shlex.join(args)}", flush=True)
        subprocess.run(args, cwd=repo, check=True)

    try:
        run("nix", "flake", "update")
        run(
            "nix-update", "--file", "update-packages.nix", "--version=unstable",
            "--version-regex", "v(.*-nightly[.].*)",
            "--use-github-releases", "--github-releases-limit", "100",
            "--override-filename", "pkgs/t3code/default.nix", "t3code",
        )
        run("nix", "build", "--no-link", ".#nixosConfigurations.nixos.config.system.build.toplevel")
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Update failed; the running system is unchanged: {error}\n")

    print("\nAll sources are current and the system builds successfully.")
    print(f"Review: git -C {shlex.quote(str(repo))} diff")
    print(f"Activate: sudo nixos-rebuild switch --flake {shlex.quote(str(repo) + '#nixos')}")
    print("Restart updated applications after activation; reboot for kernel/desktop updates.")


if __name__ == "__main__":
    main()

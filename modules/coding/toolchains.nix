{ pkgs, ... }:

{

  programs.java = {
    enable = true;
    package = pkgs.jdk21;
  };

  # Also expose these to IDEs launched from the desktop.
  environment.variables = {
    JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };

  environment.systemPackages = with pkgs; [
    nodejs_24

    # Common build tools
    gnumake
    cmake
    ninja
    pkg-config

    # C/C++ compiler, debugger, language server and formatter
    gcc
    gdb
    clang-tools

    # Rust compiler, Cargo, formatter, lints and language server
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    # Java build tools and language server; programs.java provides the JDK.
    maven
    gradle
    jdt-language-server

    # Nix language server and formatter
    nixd
    nixfmt
  ];
}

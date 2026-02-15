{
  description = "ZeroClaw - Zero overhead. Zero compromise. 100% Rust. 100% Agnostic.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    # ZeroClaw upstream source
    zeroclaw-src = {
      url = "github:theonlyhennygod/zeroclaw";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, crane, fenix, flake-utils, zeroclaw-src, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        inherit (pkgs) lib;

        fenixPkgs = fenix.packages.${system};

        # Use stable Rust toolchain from fenix
        toolchain = fenixPkgs.stable.toolchain;

        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

        # Common build inputs
        buildInputs = with pkgs; [
          openssl
        ] ++ lib.optionals pkgs.stdenv.isDarwin [
          darwin.apple_sdk.frameworks.Security
          darwin.apple_sdk.frameworks.SystemConfiguration
        ];

        nativeBuildInputs = with pkgs; [
          pkg-config
        ];

        # Source from upstream repository
        src = zeroclaw-src;

        # Build dependencies first (for caching and clippy)
        cargoArtifacts = craneLib.buildDepsOnly {
          inherit src buildInputs nativeBuildInputs;
        };

        # Build the crate
        zeroclaw = craneLib.buildPackage {
          inherit src buildInputs nativeBuildInputs cargoArtifacts;

          # Preserve the release profile optimizations from Cargo.toml
          CARGO_PROFILE_RELEASE_OPT_LEVEL = "z";
          CARGO_PROFILE_RELEASE_LTO = "true";
          CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1";
          CARGO_PROFILE_RELEASE_STRIP = "true";
          CARGO_PROFILE_RELEASE_PANIC = "abort";

          # Disable tests during build (run separately if needed)
          doCheck = false;

          meta = with lib; {
            description = "Zero overhead. Zero compromise. 100% Rust. The fastest, smallest AI assistant.";
            homepage = "https://github.com/theonlyhennygod/zeroclaw";
            license = licenses.mit;
            maintainers = [ ];
            mainProgram = "zeroclaw";
            platforms = platforms.all;
          };
        };

        # Development shell
        devShell = craneLib.devShell {
          packages = with pkgs; [
            rust-analyzer
            cargo-watch
            cargo-edit
          ];

          inherit buildInputs nativeBuildInputs;
        };

      in
      {
        packages = {
          default = zeroclaw;
          zeroclaw = zeroclaw;
        };

        devShells = {
          default = devShell;
        };

        checks = {
          # Build the crate as part of `nix flake check`
          build = zeroclaw;

          # Run clippy on the crate source
          clippy = craneLib.cargoClippy {
            inherit src buildInputs nativeBuildInputs cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          };

          # Check formatting
          fmt = craneLib.cargoFmt {
            inherit src;
          };
        };
      }
    ) // {
      # Home-Manager module
      homeManagerModules = {
        default = import ./nix/home-manager.nix;
        zeroclaw = import ./nix/home-manager.nix;
      };
    };
}

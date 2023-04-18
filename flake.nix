{
  description = "COSMIC desktop environment";

  inputs = {
     nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
     flake-utils.url = "github:numtide/flake-utils";
     nix-filter.url = "github:numtide/nix-filter";
     crane = {
        url = "github:ipetkov/crane";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     fenix = {
        url = "github:nix-community/fenix";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-applets = {
        url = "github:pop-os/cosmic-applets/8b46cc209f2aaec5ef6f0b6f743b472c66130117";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-applibrary = {
        url = "github:pop-os/cosmic-applibrary/514c155720029ee22b1e47c07a1629d96acc43c7";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-bg = {
        url = "github:pop-os/cosmic-bg/fe4bf3a3430a55cc6af71caecae53caf9effec65";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-comp = {
        url = "github:pop-os/cosmic-comp/8f6ad6201752a8f40607473977c96f058524cb6f";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-launcher = {
        url = "github:pop-os/cosmic-launcher/f8d4973d3550cada1ba02b9e0cc44ca8def13dcf";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-osd = {
        url = "github:pop-os/cosmic-osd/cbcaf2c605ebfa790a9a7fcb19a4f7f8b5c08ba9";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-panel = {
        url = "github:pop-os/cosmic-panel/4014221516bb7a94cd3ec0fccaf9b329be164c2a";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-session = {
        url = "github:pop-os/cosmic-session/32f229986b5c8532e33701899186dd0043431435";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-settings = {
        url = "github:pop-os/cosmic-settings/efdd934e6219acbfccb60e6fc65a9a064a323471";
        flake = false;
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-settings-daemon = {
        url = "github:pop-os/cosmic-settings-daemon/37fd3fda3f25525cdfb5ad21f58c5260d7da8e15";
        inputs.nixpkgs.follows = "nixpkgs";
     };
     cosmic-workspaces = {
        url = "github:pop-os/cosmic-workspaces-epoch/60a4a2fa6323327741af9da08e3d0d7eb3a802bf";
        flake = false;
        inputs.nixpkgs.follows = "nixpkgs";
     };
     xdpc = {
        url = "github:pop-os/xdg-desktop-portal-cosmic/387bc6df7b74f2926c4ad252d1f77efe30edfeeb";
        inputs.nixpkgs.follows = "nixpkgs";
     };
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, crane, fenix }:
     flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.lib.${system}.overrideToolchain fenix.packages.${system}.stable.toolchain;

        pkgDef = {
          src = nix-filter.lib.filter {
            root = ./.;
            exclude = [
              ./.gitignore
              ./flake.nix
              ./flake.lock
              ./LICENSE
              ./justfile
              ./debian
            ];
          };
          nativeBuildInputs = with pkgs; [ pkg-config autoPatchelfHook ];
          buildInputs = with pkgs; [
            appstream-glib
            cargo
            clang
            cmake
            dbus
            desktop-file-utils
            egl-wayland
            glib
            gtk4
            lld
            llvm
            llvmPackages_15.llvm
            libclang
            libglvnd
            libinput
            libpulseaudio
            libxkbcommon
            mesa
            meson
            ninja
            pipewire
            pkg-config
            seatd
            systemd
          ];
          runtimeDependencies = with pkgs; [ wayland libglvnd ];
        };

	# COSMIC Applets section
        cargoArtifacts = craneLib.buildDepsOnly pkgDef;
        cosmic-applets = craneLib.buildPackage (pkgDef // {
          inherit cargoArtifacts;
        });
      in {
        checks = {
          inherit cosmic-applets;
        };

        packages.default = cosmic-applets;

        apps.default = flake-utils.lib.mkApp {
          drv = cosmic-applets;
        };

        devShells.default = pkgs.mkShell rec {
          inputsFrom = builtins.attrValues self.checks.${system};
          LD_LIBRARY_PATH = pkgs.lib.strings.makeLibraryPath (builtins.concatMap (d: d.runtimeDependencies) inputsFrom);
        };
      });

  nixConfig = {
    # Cache for the Rust toolchain in fenix
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
}

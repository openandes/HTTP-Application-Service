{
  description = "Open Andes HTTP Application Service";

  inputs = {
    # 1. nixpkgs: The main collection of Nix packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    # 2. The Go development workbench flake from FlakeHub
    gnu-nix-go.url = "https://flakehub.com/f/Open-Andes/gnu-nix-go/0.1.1";
  };

  outputs = { self, nixpkgs, gnu-nix-go, ... }:
    let
      # Define the systems we want to build for
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      # Helper function to generate outputs for all supported systems
      # This helper passes (system, pkgs) to the function 'f'
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems
        (system: f system (import nixpkgs { inherit system; }));

    in {

      ## 1. The Package Output (The compiled executable)
      # ✅ FIX 1: The function must accept pkgs as the second argument.
      # ✅ FIX 3: The body must be a set { ... }
      packages = forAllSystems (system: pkgs: {
        default =
          pkgs.buildGoModule rec { # ✅ FIX 2: Use 'pkgs' instead of the undefined 'systemPkgs'
            pname = "open-andes-http-application-service";
            version = "0.1.0";

            src = ./.;
            # NOTE: Update this hash after the first build attempt
            vendorHash = null;

            meta =
              with pkgs.lib; { # ✅ FIX 2: Use 'pkgs.lib' instead of 'systemPkgs.lib'
                description = "Open Andes HTTP Application Service";
                license = licenses.agpl3;
              };
          };
      });

      ## 2. The Application Output (The executable wrapper for running)
      apps = forAllSystems (system: pkgs: {
        default = {
          type = "app";
          program = "${
              self.packages.${system}.default
            }/bin/open-andes-http-application-service";
        };
      });

      ## 3. The Development Shell (Re-uses the Go environment)
      # ✅ FIX 1: The function must accept pkgs as the second argument.
      devShells = forAllSystems
        (system: pkgs: { default = gnu-nix-go.devShells.${system}.default; });
    };
}

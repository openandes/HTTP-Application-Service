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
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate outputs for all supported systems
      # This helper passes (system, pkgs) to the function 'f'
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems
        (system: f system (import nixpkgs { inherit system; }));

    in {

      ## 1. The Package Output (The compiled executable)
      packages = forAllSystems (system: pkgs: {
        default =
	    gnu-nix-go.lib.buildGo rec { 
            pname = "open-andes-http-application-service";
            version = "0.1.0";

            src = ./.;
            # NOTE: Update this hash after the first build attempt
            vendorHash = null;

            meta =
              with pkgs.lib; { 
                description = "Open Andes HTTP Application Service";
                license = licenses.agpl3;
              };
          };
      });

      ## 2. The Application Output (The executable wrapper for running)
      apps = forAllSystems (system: pkgs: {
        default = {
          type = "app";
	  program = "${self.packages.${system}.default}/bin/http-application-service";
        };
      });

      ## 3. The Development Shell (Re-uses the Go environment)
      devShells = forAllSystems
        (system: pkgs: { default = gnu-nix-go.devShells.${system}.default; });
    };
}

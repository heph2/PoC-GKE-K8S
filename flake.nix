{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.terranix.url = "github:terranix/terranix";
  inputs.nur.url = "github:nix-community/NUR";
  
  outputs = { self, nixpkgs, flake-utils, terranix, nur }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      nur-pkgs = import nur {
        nurpkgs = nixpkgs.legacyPackages.${system};
        pkgs = nixpkgs.legacyPackages.${system};
      };
    in {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          terraform
          google-cloud-sdk
          kubernetes-helm
          kustomize
          nur-pkgs.repos.heph2.google-cloud-sdk-auth-plugin
        ];
      };
      defaultPackage = terranix.lib.terranixConfiguration {
	      inherit system;
	      modules = [ ./config.nix ];
      };
    });
}

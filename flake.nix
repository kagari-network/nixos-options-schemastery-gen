{
    description = "config";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    inputs.flake-utils.url = "github:numtide/flake-utils";

    outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system: let 
        pkgs = import nixpkgs { inherit system; };
    in {
    }) // (with builtins; with nixpkgs.lib; let
        case = value: set: if hasAttr value set then set.${value} else set.default;
        filterOptions = filterAttrs (name: value:
            typeOf value == "set" && (value ? visible -> (!(value.visible == "shallow") && value.visible)));
        transformOptions = options: flip mapAttrs (filterOptions options) (name: value:
            if value ? _type && hasPrefix "option" value._type
                then {
                    type = value.type.name;
                } // (case value.type.name {
                    attrsOf = transformOptions {
                        elem = mkOption {
                            type = value.type.nestedTypes.elemType;
                            description = "";
                        };
                    };
                    listOf = transformOptions {
                        elem = mkOption {
                            type = value.type.nestedTypes.elemType;
                            description = "";
                        };
                    };
                    submodule = transformOptions (evalModules {
                        modules = value.type.getSubModules;
                    }).options;
                    default = {};
                })else if value ? _type
                    then {}
                    else transformOptions value);
    in {
        nixosConfigurations.schema = nixosSystem {
            system = "x86_64-linux";
            modules = [{
                boot.isContainer = true;
            }];
        };
        schema = transformOptions self.nixosConfigurations.schema.options;
    });
}
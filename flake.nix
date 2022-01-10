{
  outputs = { self }: {
    nixosModules.argonone-i2c = import ./nix/hardware/i2c.nix;
    nixosModules.argonone-power-button = import ./nix/hardware/power-button.nix;
  };
}

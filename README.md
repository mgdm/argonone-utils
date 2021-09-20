# Argon ONE utils

A port of the logic of the [Argon ONE fan control daemon script](https://download.argon40.com/argon1.sh) to Go instead of Python.

**This probably won't work for you**. I use this on my [Raspberry Pi 4B running NixOS](https://mgdm.net/weblog/nixos-on-raspberry-pi-4/). Everything is hard coded to work on that machine with no accounting for other OSes or configurations.

## I'm using NixOS! How do I set it up?

There's no warranty of any kind for this.

The Argon ONE's fan is controlled using I2C. On Raspbian, enabling I2C is a simple matter of using `raspi-config`, which will add a line similar to `dtparam=i2c_arm=on` to `/boot/config.txt`, and rebooting. This doesn't work for me on NixOS even using the Pi's kernel, so I had to work on a device tree overlay to enable it instead. For some reason I think the i2c bus names under NixOS are swapped, so this code works with i2c-1 whereas on Raspbian I believe it would be i2c-0 (I have not tested this).

The overlay looks like [nix/hardware/i2c.nix](nix/hardware/i2c.nix). Copy that somewhere under `/etc/nixos` and include that in your `configuration.nix` as follows:

```nix
imports =
[
    ./hardware-configuration.nix
    ./hardware/i2c.nix
];

# Other settings go here...

hardware.raspberry-pi."4".i2c.enable = true;
```

(This option name uses the convention of the [nixos-hardware overlay](https://github.com/NixOS/nixos-hardware/), to which I will eventually PR this).

Then to configure the service:

```nix
# Import the overlay to provide the argonone-utils package
nixpkgs.overlays = [ (import ./overlays) ];

systemd.services.argonone-fancontrold = {
    enable = true;
    wantedBy = [ "default.target" ];

    serviceConfig = {
        DynamicUser = true;
        Group = "i2c";

        ExecStart = "${pkgs.argonone-utils}/bin/argonone-fancontrold";
    };
};
```

In `hardware-configuration.nix`, I made the following additions:

```nix
boot.initrd.kernelModules = [  "i2c-dev" "i2c-bcm2835"  ];
boot.kernelModules = [ "i2c-dev" "i2c-bcm2835" ];
hardware.i2c.enable = true; # This adds the i2c group
```

Hopefully that should be it!

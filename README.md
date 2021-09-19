# Argon ONE fan control daemon

A port of the logic of the [Argon ONE fan control daemon script](https://download.argon40.com/argon1.sh) to Go instead of Python.

**This probably won't work for you**. I use this on my [Raspberry Pi 4B running NixOS](https://mgdm.net/weblog/nixos-on-raspberry-pi-4/). Everything is hard coded to work on that machine with no accounting for other OSes or configurations.

## I'm using NixOS! How do I set it up?

The Argon ONE's fan is controlled using I2C. On Raspbian, enabling I2C is a simple matter of using `raspi-config`, which will add a line similar to `dtparam=i2c_arm=on` to `/boot/config.txt`, and rebooting. This doesn't work for me on NixOS even using the Pi's kernel, so I had to work on a device tree overlay to enable it instead. It looks like [the file below](#i2c-nix). Include that in your `configuration.nix` as follows:

```nix
imports =
[
    ./hardware-configuration.nix
    ./i2c.nix
];

// Other settings

hardware.raspberry-pi."4".i2c.enable = true;
```

(This uses the convention of the [nixos-hardware overlay](https://github.com/NixOS/nixos-hardware/), to which I will eventually PR the overlay).

In `hardware-configuration.nix`, I made the following additions:

```nix
boot.initrd.kernelModules = [  "i2c-dev" "i2c-bcm2835"  ];
boot.kernelModules = [ "i2c-dev" "i2c-bcm2835" ];
```

# i2c.nix

```nix
# /etc/nixos/i2c.nix
{ config, lib, pkgs, ... }:

let cfg = config.hardware.raspberry-pi."4".i2c;
in {
    options.hardware = {
        raspberry-pi."4".i2c = {
            enable = lib.mkEnableOption ''
                Enable the Raspberry Pi 4 hardware i2c controller.
                '';
        };
    };

    config = lib.mkIf cfg.enable {
        hardware.deviceTree = {
            overlays = [
            {
                name = "i2c0";
                dtsText = ''

	            /dts-v1/;
                /plugin/;

                /{
                    compatible = "raspberrypi,4-model-b";

                    fragment@1 {
                        target = <&i2c1>;
                        __overlay__ {
                            status = "okay";
                        };
                    };
                };
                '';
            }
            ];
        };
    };
}
```
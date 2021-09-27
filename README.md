# Argon ONE utils

A port of the logic of the [Argon ONE fan control daemon script](https://download.argon40.com/argon1.sh) to Go instead of Python.

**This probably won't work for you**. I use this on my [Raspberry Pi 4B running NixOS](https://mgdm.net/weblog/nixos-on-raspberry-pi-4/). Everything is hard coded to work on that machine with no accounting for other OSes or configurations.

## I'm using NixOS! How do I set up the fan control daemon?

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

## I'm using NixOS! How do I make the power button work?

Most of the functionality for making the power button turn the machine off already exists in the kernel and systemd. There's no need for a script to monitor the GPIOs unless you want to do something different like a quick press for reboot or a long press for shut down. The supplied Argon ONE script monitors the GPIO at 100Hz in order to do this. 

I thought about rewriting this like I did with the fan control, but using interrupts, but then I got told by @adventureloop about the `gpio-keys` kernel module. This needs some device tree overlays to set up on NixOS (again, it's probably simpler on Raspbian), but once the overlay is applied systemd will respond to a double tap on the power button by shutting down. This is only the first step--it doesn't turn off the board. However, with a quick systemd one-shot unit, we can poke the right i2c command at the board to make it cut the power just after everything else is shut down.

To use it:
* include [power-button.nix](nix/hardware/power-button.nix) in your configuration
* add `gpio-keys` to boot.kernelModules (I will add this to power-button.nix eventually)
* enable it using `hardware.argon-one.power-button.enable = true;`

After a rebuild, a double tap the power button should cleanly shut down and turn the machine off.

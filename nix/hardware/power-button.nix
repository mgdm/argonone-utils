{ config, lib, pkgs, ... }:

let cfg = config.hardware.argon-one.power-button;
in {
  options.hardware = {
    argon-one.power-button = {
      enable = lib.mkEnableOption ''
        Use the Argon ONE power button to shut down the machine
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Add a script to make the case power board turn off the power once
    # the Pi has shut down

    systemd.services.argonone-power-off = {
      wantedBy = [ "poweroff.target" ];
      after = [ "systemd-poweroff.service" ];

      script = "${pkgs.i2c-tools}/bin/i2cset -y 1 0x01a 0xff";

      unitConfig = { DefaultDependencies = "no"; };

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "i2c";
        TimeoutStartSec = "0";
      };
    };

    # Add the device tree overlay to expose the power button for the gpio-keys module
    hardware.deviceTree = {
      overlays = [{
        name = "power-button";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
          	compatible = "raspberrypi,4-model-b";

          	fragment@0 {
          		// Configure the gpio pin controller
          		target = <&gpio>;
          		__overlay__ {
          			pin_state: button_pins@0 {
          				brcm,pins = <4>; // gpio number
          				brcm,function = <0>; // 0 = input, 1 = output
          				brcm,pull = <1>; // 0 = none, 1 = pull down, 2 = pull up
          			};
          		};
          	};
          	fragment@1 {
          		target-path = "/";
          		__overlay__ {
          			button: button@0 {
          				compatible = "gpio-keys";
          				pinctrl-names = "default";
          				pinctrl-0 = <&pin_state>;
          				status = "okay";

          				key: key {
          					linux,code = <116>;
          					gpios = <&gpio 4 1>;
          					label = "KEY_POWER";
          				};
          			};
          		};
          	};

          	__overrides__ {
          		gpio =        <&key>,"gpios:4",
          			          <&button>,"reg:0",
          			          <&pin_state>,"brcm,pins:0",
          			          <&pin_state>,"reg:0";
          		label =       <&key>,"label";
          		keycode =     <&key>,"linux,code:0";
          		gpio_pull =   <&pin_state>,"brcm,pull:0";
          		active_high = <&key>,"gpios:4";
          	};

          };
        '';
      }];
    };
  };
}
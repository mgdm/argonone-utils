{ config, pkgs, ... }:

pkgs.buildGoModule rec {
	name = "argonone-fancontrold";
	version = "0.1.0";

	src = pkgs.fetchFromGitHub {
		owner = "mgdm";
		repo = "argonone-utils";
		rev = "main";
		sha256 = "1cf544i24zbgprfj51yli2l3fwalcsb2vb5p7r257k73q457hgzc";
	};

	vendorSha256 = "18qwmg249lr7xb9f7lrrflhsr7drx750ndqd8hirq5hgj4c4f66k";
}

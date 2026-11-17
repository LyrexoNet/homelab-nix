{ conix, fig, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "lyrix";
  networking.networkmanager.enable = true;
  hardware.enableRedistributableFirmware = true;
  networking.firewall.enable = false;
  networking.hostId = "d1ef2617";

  time.timeZone = "America/New_York";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdhT/HpmwhN1TkNdcU7njGkzr6qugERwDIX84Cl/43s atlas-1-to-lycore"
  ];

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    htop
    nano
    vim
    pciutils
    usbutils
  ];

  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  
  fileSystems."/storage" = {
    device = "pool"; # Or "pool/dataset" if mounting a child dataset
    fsType = "zfs";
    options = [ "nofail" ];
  };

  users.users.lyrexo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdhT/HpmwhN1TkNdcU7njGkzr6qugERwDIX84Cl/43s atlas-1-to-lycore"
    ];
  };

  security.sudo.enable = true;

  system.stateVersion = "26.05";

  nix.settings.trusted-users = [ "root" "lyrexo" ];
}

{ conix, fig, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  virtualisation.libvirtd = {
    enable = true;
    dbus.enable = true;
  };

  programs.virt-manager.enable = true;

    environment.pathsToLink = [ "/share/cockpit" ];
  services.dbus.packages = [ pkgs.libvirt-dbus ];
  
  services.cockpit = {
    enable = true;
    openFirewall = true;
    allowed-origins = [
      "https://10.7.4.84:9090"
      "https://localhost:9090"
      "https://lyrix.lyrexo.net"
    ];
    plugins = [
      pkgs.cockpit-files
      pkgs.cockpit-podman
      pkgs.cockpit-machines
    ];
  };

  virtualisation.libvirtd.qemu = {
    runAsRoot = true;
  };

  networking.hostName = "lyrix";
  networking.useDHCP = false;
  networking.bridges.br0.interfaces = [ "enp3s0" ];
  networking.interfaces.enp3s0.useDHCP = false;
  networking.interfaces.br0.macAddress = "00:e0:4d:03:0f:e4";
  networking.interfaces.br0.ipv4.addresses = [{
    address = "10.7.4.84";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.7.4.1";
  networking.nameservers = [ "10.7.4.1" ];
  hardware.enableRedistributableFirmware = true;
  networking.firewall.enable = false;
  networking.hostId = "d1ef2617";

  time.timeZone = "America/New_York";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
    };
  };

  services.forgejo = {
    enable = true;
    stateDir = "/storage/storage/git_storage/forgejo";
    customDir = "/storage/storage/forgejo-app/custom";
    repositoryRoot = "/storage/storage/git_storage/forgejo/repositories";
    dump.backupDir = "/storage/storage/forgejo-app/dump";
    settings = {
      server = {
        APP_DATA_PATH = "/storage/storage/git_storage/forgejo/data";
        DOMAIN = "git.lyrexo.net";
        ROOT_URL = "https://git.lyrexo.net/";
      };
    };
  };

  systemd.services.forgejo-storage-permissions = {
    description = "Grant Forgejo access to the storage volume";
    unitConfig.RequiresMountsFor = "/storage/storage";
    before = [ "forgejo.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.acl pkgs.findutils ];
    script = ''
      setfacl -R -m u:forgejo:rwX /storage/storage
      find /storage/storage -type d -exec setfacl -m d:u:forgejo:rwx {} +
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.services.forgejo = {
    requires = [ "forgejo-storage-permissions.service" ];
    after = [ "forgejo-storage-permissions.service" ];
  };
  
  services.samba = {
    enable = true;
    package = pkgs.samba4Full;
    openFirewall = true;

    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "Lyrix NAS";
        "netbios name" = "LYRIX";
        security = "user";
        "map to guest" = "never";
      };

      storage = {
        path = "/storage/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = [ "lyrexo" ];
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdhT/HpmwhN1TkNdcU7njGkzr6qugERwDIX84Cl/43s atlas-1-to-lycore"
  ];

  users.mutableUsers = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    htop
    nano
    vim
    pciutils
    usbutils
    cockpit
    cockpit-machines
    libvirt-dbus
    virt-manager
  ];

  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" "btrfs" ];
  boot.zfs.forceImportRoot = false;
  
  fileSystems."/storage/storage" = {
    device = "/dev/disk/by-uuid/95a2ad85-67e6-446a-9635-ae1c6fbd8bc4";
    fsType = "btrfs";
    options = [ "nofail" ];
  };

  users.users.lyrexo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdhT/HpmwhN1TkNdcU7njGkzr6qugERwDIX84Cl/43s atlas-1-to-lycore"
    ];
  };

  security.sudo.enable = true;

  system.stateVersion = "26.05";

  nix.settings.trusted-users = [ "root" "lyrexo" ];
}

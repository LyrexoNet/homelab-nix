{ config, pkgs, ... }:

let
  wireguardPort = 51820;
  externalInterface = "br0";
in
{
  environment.systemPackages = [ pkgs.wireguard-tools ];

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    inherit externalInterface;
    internalInterfaces = [ "wg0" ];
  };

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.8.0.1/24" "fdc9:281f:04d7:9ee9::1/64" ];
    listenPort = wireguardPort;
    privateKeyFile = "/etc/wireguard/private.key";

    postSetup = ''
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${externalInterface} -j MASQUERADE
      ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fdc9:281f:04d7:9ee9::/64 -o ${externalInterface} -j MASQUERADE
    '';

    postShutdown = ''
      ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o ${externalInterface} -j MASQUERADE
      ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fdc9:281f:04d7:9ee9::/64 -o ${externalInterface} -j MASQUERADE
    '';

    peers = [
      {
        publicKey = "fUUWCSwUljwSlLnogEACSR9mgfSCSVtjh6vzQa50EQk=";
        allowedIPs = [ "10.8.0.2/32" "fdc9:281f:04d7:9ee9::2/128" ];
      }
    ];
  };
}

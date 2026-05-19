{ ... }: {

  services.tailscale.enable = true;

  # Allow Tailscale traffic through the firewall
  networking.firewall = {
    allowedUDPPorts = [ 41641 ];
    trustedInterfaces = [ "tailscale0" ];
    # Allow traffic from the Tailscale subnet
    checkReversePath = "loose";
  };

  # Tailscale runs as a service; authenticate once with:
  #   sudo tailscale up
  # Then it connects automatically on every boot.
  # All your devices on the same Tailscale account see each other
  # regardless of network, NAT, or firewall between them.
}

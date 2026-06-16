# Grants the logged-in user read access to the Corne's raw HID node (usage page
# 0xFF60) so the keyb-viewer reader runs without sudo.
# Import from your nixos-config, e.g.:
#   imports = [ /home/jaidaken/projects/keyb-viewer/host/nixos/keyb-viewer-udev.nix ];
{
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="615e", TAG+="uaccess"
  '';
}

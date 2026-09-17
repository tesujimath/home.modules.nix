{ config, lib, ... }:

let
  cfg = config.tesujimath.vmware-fusion-support;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.tesujimath.vmware-fusion-support = {
    enable = mkEnableOption "Enable support for VMware Fusion";
  };

  config = mkIf cfg.enable {
    programs = {
      # ignored unless fish is enabled
      fish.functions = {
        vmrun = {
          description = "Execute vmrun from its installation directory without having to have that on path";
          body = ''"/Applications/VMware Fusion.app/Contents/Library/vmrun" $argv'';
        };

        start-windows-nogui = {
          description = "Start the well-known Windows VM using the password created by VMware Fusion";
          body = ''vmrun -T fusion -vp (security find-generic-password -s "$HOME/Virtual Machines.localized/Windows 11 64-bit Arm.vmwarevm/Windows 11 64-bit Arm.vmx" -w) start "$HOME/Virtual Machines.localized/Windows 11 64-bit Arm.vmwarevm/" nogui'';
        };
      };

      # ignored unless zsh is enabled
      zsh.initContent = ''
        vmrun() {
          "/Applications/VMware Fusion.app/Contents/Library/vmrun" "$@"
        }

        start-windows-nogui() {
          vmrun -T fusion -vp $(security find-generic-password -s "$HOME/Virtual Machines.localized/Windows 11 64-bit Arm.vmwarevm/Windows 11 64-bit Arm.vmx" -w) start "$HOME/Virtual Machines.localized/Windows 11 64-bit Arm.vmwarevm/" nogui
        }
      '';
    };
  };
}

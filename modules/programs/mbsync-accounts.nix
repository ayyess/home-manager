{ lib, ... }:

with lib;

let
  channelModule = types.submodule {
    options = {

      remotePath = mkOption {
        type = types.str;
        default = "";
        example = "INBOX";
        description = ''
          Relative path to remote mailbox (can be empty).
        '';
      };

      localPath = mkOption {
        type = types.str;
        default = "";
        example = "inbox";
        description = ''
          Relative path to local mailbox (can be empty).
        '';
      };

      create = mkOption {
        type = types.enum [ "none" "maildir" "imap" "both" ];
        default = "none";
        example = "maildir";
        description = ''
                Automatically create missing mailboxes within the
                given mail store.
        '';
      };

      remove = mkOption {
        type = types.enum [ "none" "maildir" "imap" "both" ];
        default = "none";
        example = "imap";
        description = ''
                Propagate mailbox deletions to the given mail store.
        '';
      };

      expunge = mkOption {
        type = types.enum [ "none" "maildir" "imap" "both" ];
        default = "none";
        example = "both";
        description = ''
                Permanently remove messages marked for deletion from
                the given mail store.
        '';
      };

      patterns = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
                Pattern of mailboxes to synchronize.
        '';
      };
    };
  };
in
{
  options.mbsync = {
    enable = mkEnableOption "synchronization using mbsync";

    flatten = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = ".";
      description = ''
        If set, flattens the hierarchy within the maildir by
        substituting the canonical hierarchy delimiter
        <literal>/</literal> with this value.
      '';
    };

    channels = mkOption {
      type = types.listOf channelModule;
      description = ''
        Channels to sync
      '';
    };
  };
}

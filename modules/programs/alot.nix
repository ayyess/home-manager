# alot config loader is sensitive to leading space !
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.alot;

  alotAccounts = filter (a: a.notmuch.enable)
    (attrValues config.accounts.email.accounts);

  boolStr = v: if v then "True" else "False";

  accountStr = account: with account;
    concatStringsSep "\n" (
      [ "[[${name}]]" ]
      ++ mapAttrsToList (n: v: n + "=" + v) (
        {
          address = address;
          realname = realName;
          sendmail_command =
            optionalString (alot.sendMailCommand != null) alot.sendMailCommand;
          sent_box = "maildir" + "://" + maildir.absPath + "/" + folders.sent;
          draft_box = "maildir" + "://"+ maildir.absPath + "/" + folders.drafts;
        }
        // optionalAttrs (aliases != []) {
          aliases = concatStringsSep "," aliases;
        }
        // optionalAttrs (gpg != null) {
          gpg_key = gpg.key;
          encrypt_by_default = if gpg.encryptByDefault then "all" else "none";
          sign_by_default = boolStr gpg.signByDefault;
        }
        // optionalAttrs (signature.showSignature != "none") {
          signature = pkgs.writeText "signature.txt" signature.text;
          signature_as_attachment =
            boolStr (signature.showSignature == "attach");
        }
      )
      ++ [ alot.extraConfig ]
      ++ [ "[[[abook]]]" ]
      ++ mapAttrsToList (n: v: n + "=" + v) alot.contactCompletion
    );

  configFile =
    let
      bindingsToStr = attrSet:
        concatStringsSep "\n" (mapAttrsToList (n: v: "${n} = ${v}") attrSet);
    in
      ''
        # Generated by Home Manager.
        # See http://alot.readthedocs.io/en/latest/configuration/config_options.html

        ${cfg.extraConfig}

        [bindings]
        ${bindingsToStr cfg.bindings.global}

        [[bufferlist]]
        ${bindingsToStr cfg.bindings.bufferlist}
        [[search]]
        ${bindingsToStr cfg.bindings.search}
        [[envelope]]
        ${bindingsToStr cfg.bindings.envelope}
        [[taglist]]
        ${bindingsToStr cfg.bindings.taglist}
        [[thread]]
        ${bindingsToStr cfg.bindings.thread}

        [accounts]

        ${concatStringsSep "\n\n" (map accountStr alotAccounts)}
      '';

in

{
  options.programs.alot = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to enable the Alot mail user agent. Alot uses the
        Notmuch email system and will therefore be automatically
        enabled for each email account that is managed by Notmuch.
      '';
    };

    hooks = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Content of the hooks file.
      '';
    };

    bindings = mkOption {
      type = types.submodule {
        options = {
          global = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Global keybindings.";
          };

          bufferlist = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Bufferlist mode keybindings.";
          };

          search = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Search mode keybindings.";
          };

          envelope = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Envelope mode keybindings.";
          };

          taglist = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Taglist mode keybindings.";
          };

          thread = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Thread mode keybindings.";
          };
        };
      };
      default = {};
      description = ''
        Keybindings.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = ''
        auto_remove_unread = True
        ask_subject = False
        handle_mouse = True
        initial_command = "search tag:inbox AND NOT tag:killed"
        input_timeout = 0.3
        prefer_plaintext = True
        thread_indent_replies = 4
      '';
      description = ''
        Extra lines added to alot configuration file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages =  [ pkgs.alot ];

    xdg.configFile."alot/config".text = configFile;

    xdg.configFile."alot/hooks.py".text =
      ''
        # Generated by Home Manager.
      ''
      + cfg.hooks;
  };
}

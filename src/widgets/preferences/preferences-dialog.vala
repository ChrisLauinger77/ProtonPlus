namespace ProtonPlus.Widgets.Preferences {
    public class PreferencesDialog : Adw.PreferencesDialog {
        public PreferencesDialog (Gee.LinkedList<Models.Launcher> launchers) {
            set_search_enabled (true);

            // General Page
            var general_page = new Adw.PreferencesPage () {
                title = _("General"),
                icon_name = "preferences-system-symbolic"
            };
            add (general_page);

            var appearance_group = new Adw.PreferencesGroup () {
                title = _("Appearance")
            };
            general_page.add (appearance_group);

            var theme_row = new ThemeRow ();
            theme_row.add_prefix (new Gtk.Image.from_icon_name ("palette-symbolic"));
            appearance_group.add (theme_row);

            var language_row = new LanguageRow ();
            language_row.add_prefix (new Gtk.Image.from_icon_name ("globe-symbolic"));
            appearance_group.add (language_row);

            var help_page = new Adw.PreferencesGroup () {
                title = _("Help"),
            };
            var introduction_btn = new Adw.ButtonRow () {
                title = _("Show Introduction")
            };
            introduction_btn.set_start_icon_name ("help-about-symbolic");
            introduction_btn.activated.connect (() => {
                var window = this.get_root () as Window;
                var dialog = new Introduction.Introduction ();
                dialog.present (window);
            });
            help_page.add (introduction_btn);
            general_page.add (help_page);

            // Tools Page
            var tools_page = new Adw.PreferencesPage () {
                title = _("Tools"),
                icon_name = "toolbox-symbolic"
            };
            add (tools_page);

            var updates_group = new Adw.PreferencesGroup () {
                title = _("Updates")
            };
            tools_page.add (updates_group);

            var background_updates_row = new Adw.SwitchRow () {
                title = _("Background updates"),
                subtitle = _("Automatically update the tools in the background"),
            };
            Globals.SETTINGS.bind ("background-updates", background_updates_row, "active", SettingsBindFlags.DEFAULT);
            Globals.SETTINGS.changed["background-updates"].connect (Utils.System.systemd_handler);
            updates_group.add (background_updates_row);

            var background_updates_frequency_row = new BackgroundUpdatesFrequencyRow () {
                subtitle = _("Set how often to check for updates in the background"),
            };
            background_updates_row.bind_property ("active", background_updates_frequency_row, "sensitive", BindingFlags.SYNC_CREATE);
            updates_group.add (background_updates_frequency_row);

            var check_updates_on_boot_row = new Adw.SwitchRow () {
                title = _("Check updates on boot"),
                subtitle = _("Check for tool updates when the system starts"),
            };
            Globals.SETTINGS.bind ("check-updates-on-boot", check_updates_on_boot_row, "active", SettingsBindFlags.DEFAULT);
            Globals.SETTINGS.changed["check-updates-on-boot"].connect (Utils.System.systemd_handler);
            updates_group.add (check_updates_on_boot_row);

            var check_updates_on_launch_row = new Adw.SwitchRow () {
                title = _("Check updates on launch"),
                subtitle = _("Update the tools when the application is launched"),
            };
            Globals.SETTINGS.bind ("check-updates-on-launch", check_updates_on_launch_row, "active", SettingsBindFlags.DEFAULT);
            updates_group.add (check_updates_on_launch_row);

            var migrate_default_prefix_row = new Adw.SwitchRow () {
                title = _("Migrate default prefix"),
                subtitle = _("Automatically migrate the default prefix when updating"),
            };
            Globals.SETTINGS.bind ("migrate-default-prefix", migrate_default_prefix_row, "active", SettingsBindFlags.DEFAULT);
            updates_group.add (migrate_default_prefix_row);

            var tools_behavior_group = new Adw.PreferencesGroup () {
                title = _("Behavior")
            };
            tools_page.add (tools_behavior_group);

            var legacy_tools_row = new Adw.SwitchRow () {
                title = _("Show legacy tools"),
                subtitle = _("Display older tools that are no longer actively maintained"),
            };
            legacy_tools_row.add_prefix (new Gtk.Image.from_icon_name ("box-archive-symbolic"));
            Globals.SETTINGS.bind ("show-legacy-tools", legacy_tools_row, "active", SettingsBindFlags.DEFAULT);
            tools_behavior_group.add (legacy_tools_row);

            // Launchers Page
            var launchers_page = new Adw.PreferencesPage () {
                title = _("Launchers"),
                icon_name = "grip-symbolic"
            };

            bool has_launchers = false;
            foreach (var launcher in launchers) {
                if (launcher is ProtonPlus.Models.Launchers.Steam) {
                    var steam_launcher = launcher as ProtonPlus.Models.Launchers.Steam;

                    var steam_group = new Adw.PreferencesGroup () {
                        title = "Steam",
                    };

                    var compatibility_tools = new Gee.ArrayList<ProtonPlus.Models.Tools.Simple> ();
                    foreach (var compatibility_tool in steam_launcher.compatibility_tools) {
                        if (!compatibility_tool.display_title.contains ("Steam Linux Runtime"))
                            compatibility_tools.add (compatibility_tool);
                    }
                    compatibility_tools.sort ((a, b) => {
                        return strcmp (
                            b.display_title.collate_key_for_filename (),
                            a.display_title.collate_key_for_filename ()
                        );
                    });

                    var model = new GLib.ListStore (typeof (ProtonPlus.Models.Tools.Simple));
                    foreach (var compatibility_tool in compatibility_tools) {
                        model.append (compatibility_tool);
                    }

                    var expression = new Gtk.PropertyExpression (typeof (ProtonPlus.Models.Tools.Simple), null, "display_title");

                    var compatibility_tool_row = new ToolRow (model, expression) {
                        title = _("Default compatibility tool"),
                        subtitle = _("The compatibility tool games will use by default")
                    };
                    compatibility_tool_row.add_prefix (new Gtk.Image.from_icon_name ("screwdriver-wrench-symbolic"));

                    for (var i = 0; i < (int) compatibility_tools.size; i++) {
                        if (compatibility_tools[i].internal_title == steam_launcher.default_compatibility_tool) {
                            compatibility_tool_row.set_selected ((uint) i);
                            break;
                        }
                    }

                    compatibility_tool_row.notify["selected-item"].connect (() => {
                        var selected_tool = compatibility_tool_row.get_selected_item () as ProtonPlus.Models.Tools.Simple;
                        if (selected_tool != null) {
                            steam_launcher.change_default_compatibility_tool (selected_tool.internal_title);
                        }
                    });
                    steam_group.add (compatibility_tool_row);

                    var profiles_model = new GLib.ListStore (typeof (ProtonPlus.Models.SteamProfile));
                    foreach (var profile in steam_launcher.profiles) {
                        profiles_model.append (profile);
                    }

                    var profile_row = new SteamProfileRow (profiles_model) {
                        title = _("Selected profile"),
                        subtitle = _("Currently selected profile for Steam"),
                    };
                    profile_row.add_prefix (new Gtk.Image.from_icon_name ("avatar-default-symbolic"));
                    profile_row.set_sensitive (steam_launcher.profiles.length () > 1);

                    var last_profile_id = Globals.SETTINGS.get_string ("steam-selected-profile-id");
                    for (var i = 0; i < (int) steam_launcher.profiles.length (); i++) {
                        if (steam_launcher.profiles.nth_data (i).steam_id == last_profile_id) {
                            profile_row.set_selected ((uint) i);
                            break;
                        }
                    }

                    profile_row.notify["selected-item"].connect (() => {
                        var selected_profile = profile_row.get_selected_item () as ProtonPlus.Models.SteamProfile;
                        if (selected_profile != null) {
                            Globals.SETTINGS.set_string ("steam-selected-profile-id", selected_profile.steam_id);
                            steam_launcher.switch_profile.begin (selected_profile);
                        }
                    });
                    steam_group.add (profile_row);

                    launchers_page.add (steam_group);
                    has_launchers = true;
                    break;
                }
            }

            if (has_launchers) {
                add (launchers_page);
            }

            // Advanced Page
            var advanced_page = new Adw.PreferencesPage () {
                title = _("Advanced"),
                icon_name = "preferences-other-symbolic"
            };
            add (advanced_page);

            var tokens_group = new Adw.PreferencesGroup () {
                title = _("API Tokens")
            };
            advanced_page.add (tokens_group);

            var github_access_token_row = new AccessTokenRow (
                "GitHub",
                "github-symbolic",
                "https://github.com/settings/tokens"
            );
            Globals.SETTINGS.bind ("github-api-key", github_access_token_row, "text", SettingsBindFlags.DEFAULT);
            tokens_group.add (github_access_token_row);

            var gitlab_access_token_row = new AccessTokenRow (
                "GitLab",
                "gitlab-symbolic",
                "https://gitlab.com/-/user_settings/personal_access_tokens"
            );
            Globals.SETTINGS.bind ("gitlab-api-key", gitlab_access_token_row, "text", SettingsBindFlags.DEFAULT);
            tokens_group.add (gitlab_access_token_row);

            var network_group = new Adw.PreferencesGroup () {
                title = _("Network")
            };
            advanced_page.add (network_group);

            var proxy_mode_row = new ProxyModeRow ();
            network_group.add (proxy_mode_row);

            var proxy_url_row = new Adw.EntryRow () {
                title = _("Proxy URL"),
            };
            proxy_url_row.set_tooltip_text (_("Example: http://127.0.0.1:7890 or socks5://127.0.0.1:1080"));
            proxy_url_row.set_sensitive (Globals.SETTINGS.get_enum ("proxy-mode") == 1);
            Globals.SETTINGS.bind ("proxy-url", proxy_url_row, "text", SettingsBindFlags.DEFAULT);
            Globals.SETTINGS.changed["proxy-mode"].connect (() => {
                proxy_url_row.set_sensitive (Globals.SETTINGS.get_enum ("proxy-mode") == 1);
                Utils.Web.update_proxy_settings ();
            });
            Globals.SETTINGS.changed["proxy-url"].connect (() => {
                Utils.Web.update_proxy_settings ();
            });
            network_group.add (proxy_url_row);

            var experimental_group = new Adw.PreferencesGroup () {
                title = _("Experimental")
            };
            advanced_page.add (experimental_group);

            var experimental_features_row = new Adw.SwitchRow () {
                title = _("Preview features"),
                subtitle = _("Enable experimental features for early testing"),
            };
            experimental_features_row.add_prefix (new Gtk.Image.from_icon_name ("flask-symbolic"));
            Globals.SETTINGS.bind ("experimental-features", experimental_features_row, "active", SettingsBindFlags.DEFAULT);
            experimental_group.add (experimental_features_row);

            var maintenance_group = new Adw.PreferencesGroup () {
                title = _("Maintenance")
            };
            advanced_page.add (maintenance_group);
            maintenance_group.add (new RefreshApplicationDataRow (this));
            maintenance_group.add (new DeleteCacheRow ());

            // System Page
            var system_page = new Adw.PreferencesPage () {
                title = _("System"),
                icon_name = "dialog-information-symbolic"
            };
            add (system_page);

            var environment_group = new Adw.PreferencesGroup () {
                title = _("Software Environment")
            };
            system_page.add (environment_group);

            environment_group.add (new Adw.ActionRow () {
                title = _("SteamOS"),
                subtitle = Globals.IS_STEAM_OS ? _("Yes") : _("No")
            });

            environment_group.add (new Adw.ActionRow () {
                title = _("Flatpak"),
                subtitle = Globals.IS_FLATPAK ? _("Yes") : _("No")
            });

            var hardware_group = new Adw.PreferencesGroup () {
                title = _("Hardware")
            };
            system_page.add (hardware_group);

            string hwcaps_str = "";
            foreach (var hwcap in Globals.HWCAPS) {
                if (hwcaps_str != "")
                    hwcaps_str += ", ";
                hwcaps_str += hwcap;
            }

            hardware_group.add (new Adw.ActionRow () {
                title = _("HWCAPS"),
                subtitle = hwcaps_str
            });

            var dependencies_group = new Adw.PreferencesGroup () {
                title = _("Dependencies")
            };
            system_page.add (dependencies_group);

            dependencies_group.add (new Adw.ActionRow () {
                title = _("Protontricks"),
                subtitle = Globals.PROTONTRICKS_INSTALLED ? _("Yes") : _("No")
            });

            dependencies_group.add (new Adw.ActionRow () {
                title = _("Protontricks (Flatpak)"),
                subtitle = Globals.PROTONTRICKS_FLATPAK_INSTALLED ? _("Yes") : _("No")
            });

            dependencies_group.add (new Adw.ActionRow () {
                title = _("MangoHud"),
                subtitle = Globals.MANGOHUD_INSTALLED ? _("Yes") : _("No")
            });

            dependencies_group.add (new Adw.ActionRow () {
                title = _("MangoHud (Flatpak)"),
                subtitle = Globals.MANGOHUD_FLATPAK_INSTALLED ? _("Yes") : _("No")
            });

            dependencies_group.add (new Adw.ActionRow () {
                title = _("Gamescope"),
                subtitle = Globals.GAMESCOPE_INSTALLED ? _("Yes") : _("No")
            });

            dependencies_group.add (new Adw.ActionRow () {
                title = _("ScopeBuddy"),
                subtitle = Globals.SCOPEBUDDY_INSTALLED ? _("Yes") : _("No")
            });

            dependencies_group.add (new Adw.ActionRow () {
                title = _("Feral Gamemode"),
                subtitle = Globals.GAMEMODE_INSTALLED ? _("Yes") : _("No")
            });

            var detected_launchers_group = new Adw.PreferencesGroup () {
                title = _("Detected Launchers")
            };
            system_page.add (detected_launchers_group);

            ProtonPlus.Models.Launcher[] all_launchers = {
                new ProtonPlus.Models.Launchers.Steam (ProtonPlus.Models.Launcher.InstallationTypes.SYSTEM),
                new ProtonPlus.Models.Launchers.Steam (ProtonPlus.Models.Launcher.InstallationTypes.FLATPAK),
                new ProtonPlus.Models.Launchers.Steam (ProtonPlus.Models.Launcher.InstallationTypes.SNAP),
                new ProtonPlus.Models.Launchers.Lutris (ProtonPlus.Models.Launcher.InstallationTypes.SYSTEM),
                new ProtonPlus.Models.Launchers.Lutris (ProtonPlus.Models.Launcher.InstallationTypes.FLATPAK),
                new ProtonPlus.Models.Launchers.Bottles (ProtonPlus.Models.Launcher.InstallationTypes.SYSTEM),
                new ProtonPlus.Models.Launchers.Bottles (ProtonPlus.Models.Launcher.InstallationTypes.FLATPAK),
                new ProtonPlus.Models.Launchers.HeroicGamesLauncher (ProtonPlus.Models.Launcher.InstallationTypes.SYSTEM),
                new ProtonPlus.Models.Launchers.HeroicGamesLauncher (ProtonPlus.Models.Launcher.InstallationTypes.FLATPAK),
                new ProtonPlus.Models.Launchers.WineZGUI (ProtonPlus.Models.Launcher.InstallationTypes.SYSTEM),
                new ProtonPlus.Models.Launchers.WineZGUI (ProtonPlus.Models.Launcher.InstallationTypes.FLATPAK)
            };

            foreach (var launcher in all_launchers) {
                detected_launchers_group.add (new Adw.ActionRow () {
                    title = "%s (%s)".printf (launcher.title, launcher.get_installation_type_title ()),
                    subtitle = launcher.installed ? _("Installed") : _("Not installed")
                });
            }
        }
    }
}

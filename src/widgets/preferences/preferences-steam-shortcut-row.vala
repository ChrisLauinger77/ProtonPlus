namespace ProtonPlus.Widgets.Preferences {
    public class SteamShortcutRow : Adw.ActionRow {
        Models.SteamProfile profile { get; set; }
        Gtk.Button shortcut_button;

        construct {
            shortcut_button = new Gtk.Button ();
            shortcut_button.add_css_class ("flat");
            shortcut_button.set_valign (Gtk.Align.CENTER);
            shortcut_button.clicked.connect (shortcut_button_clicked);

            set_title (_ ("Manage shortcut"));
            add_prefix (new Gtk.Image.from_icon_name ("bookmark-symbolic"));
            add_suffix (shortcut_button);
        }

        public SteamShortcutRow (Models.SteamProfile profile) {
            load (profile);
        }

        public void load (Models.SteamProfile profile) {
            this.profile = profile;
            refresh ();
        }

        void refresh () {
            var shortcut_installed = profile.shortcuts.get_installed_status ();
            shortcut_button.set_label (!shortcut_installed ? _ ("Create shortcut") : _ ("Delete shortcut"));
            set_subtitle (!shortcut_installed ? _ ("Create a shortcut of ProtonPlus in Steam") : _ ("Delete the shortcut of ProtonPlus in Steam"));
        }

        void shortcut_button_clicked () {
            var installed = profile.shortcuts.get_installed_status ();

            if (installed) {
                var success = profile.shortcuts.uninstall ();
                if (!success) {
                    var dialog = new Main.ErrorDialog (
                        _ ("Failed to delete shortcut"),
                        _ ("ProtonPlus was unable to remove the shortcut from Steam. This might happen if Steam is currently running or if the shortcuts file is inaccessible."), // vala-lint=line-length
                        ""
                    );
                    ProtonPlus.Widgets.Window.present_dialog_for_controller (dialog, (Gtk.Window) this.get_root ());
                }
                refresh ();
            } else {
                shortcut_button.set_sensitive (false);
                var current_profile = profile;
                current_profile.shortcuts.install.begin ((obj, res) => {
                    var success = current_profile.shortcuts.install.end (res);
                    if (!success) {
                        var dialog = new Main.ErrorDialog (
                            _ ("Failed to create shortcut"),
                            _ ("ProtonPlus was unable to add the shortcut to Steam. Please ensure Steam is closed and try again."),
                            ""
                        );
                        ProtonPlus.Widgets.Window.present_dialog_for_controller (dialog, (Gtk.Window) this.get_root ());
                    }
                    shortcut_button.set_sensitive (true);
                    refresh ();
                });
            }
        }
    }
}

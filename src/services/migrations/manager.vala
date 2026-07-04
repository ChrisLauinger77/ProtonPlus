namespace ProtonPlus.Services.Migrations {

    public class Manager : GLib.Object {
        private Gee.ArrayList<IMigration?> migrations;

        public Manager () {
            this.migrations = new Gee.ArrayList<IMigration> ();
            this.register_migrations ();
        }

        private void register_migrations () {
            this.migrations.add ( new Versions.v0_5_21 ());
            this.migrations.add ( new Versions.v0_6_0 ());
        }

        public void check_and_migrate (string current_version) {
            var settings = ProtonPlus.Globals.SETTINGS;

            if (settings == null) {
                print ("GSettings is not initialized. Skipping migration check.\n");
                return;
            }

            string last_version = settings.get_string ("last-version");

            if (last_version == "") {
                if (settings.get_boolean ("first-run") == false) {
                    last_version = "0.5.0";
                } else {
                    settings.set_string ("last-version", current_version);
                    return;
                }
            }

            if (last_version == current_version) {
                return;
            }

            print ("Detected version change from %s to %s. Running migration stack…\n", last_version, current_version);

            foreach (var step in this.migrations) {
                if (compare_versions (step.version, last_version) > 0 &&
                    compare_versions (step.version, current_version) <= 0) {

                    try {
                        step.migrate ();
                    } catch (GLib.Error e) {
                        critical ("Migration failed during migration to version %s: %s", step.version, e.message);
                    }
                }
            }

            // After successfully completing all migrations, update the version in GSettings
            settings.set_string ("last-version", current_version);
        }

        /**
         * Helper method for comparing semantic versions (X.Y.Z)
         * Returns: > 0 if v1 > v2, < 0 if v1 < v2, 0 if v1 == v2
         */
        private int compare_versions (string v1, string v2) {
            string[] parts1 = v1.split (".");
            string[] parts2 = v2.split (".");

            int max_length = int.max (parts1.length, parts2.length);

            for (int i = 0; i < max_length; i++) {
                int p1 = i < parts1.length ? int.parse (parts1[i]) : 0;
                int p2 = i < parts2.length ? int.parse (parts2[i]) : 0;

                if (p1 != p2) {
                    return p1 - p2;
                }
            }

            return 0;
        }
    }
}

namespace ProtonPlus.Services.Migrations.Versions {
    using ProtonPlus.Utils;

    public class v0_6_0 : Object, IMigration {
        public string version { get; default = "0.6.0"; }

        public async void migrate () {
            print ("Migration: Performing specific changes for version 0.6.0…\n");

            yield CacheManager.clear_cache ();
        }

        public void post_migrate (MigrationContext? context = null) {
            if (context == null || context.window == null) {
                return;
            }

            var dialog = new ProtonPlus.Widgets.Introduction.Introduction ();
            dialog.present (context.window);
        }
    }
}

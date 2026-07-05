namespace ProtonPlus.Services.Migrations.Versions {
    using ProtonPlus.Utils;

    public class v0_6_0 : Object, IMigration {
        public string version { get; default = "0.6.0"; }
        public ProtonPlus.Widgets.Window? window { get; private set; }

        public v0_6_0 (ProtonPlus.Widgets.Window? window = null) {
            this.window = window;
        }

        public async void migrate () {
            print ("Migration: Performing specific changes for version 0.6.0…\n");

            yield CacheManager.clear_cache ();

                var window = this.window;
                var dialog = new ProtonPlus.Widgets.Introduction.Introduction ();
                dialog.present (window);
        }
    }
}

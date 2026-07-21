namespace ProtonPlus {
    public static int main (string[] args) {
        Globals.load ();

        Globals.setupLanguage ();
        Notify.init (Config.APP_NAME);

        if (args.length > 1) {
            var migration_manager = new ProtonPlus.Services.Migrations.Manager ();
            migration_manager.check_and_migrate_sync (Config.APP_VERSION);

            var cli = new CLI.Handler ();
            var loop = new MainLoop ();
            int result = 0;
            cli.run.begin (args, (obj, res) => {
                result = cli.run.end (res);
                loop.quit ();
            });
            loop.run ();
            return result;
        }

        var application = new Widgets.Application ();
        int status = application.run (args);
        Notify.uninit ();
        return status;
    }
}

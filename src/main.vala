namespace ProtonPlus {
    public static int main (string[] args) {
        if (!Thread.supported ()) {
            warning ("Threads are not supported!");
            return -1;
        }

        Globals.load ();

        Globals.setupLanguage ();
        Notify.init (Config.APP_NAME);

        if (args.length > 1) {
            var migration_manager = new ProtonPlus.Services.Migrations.Manager ();
            var migration_loop = new MainLoop ();
            migration_manager.check_and_migrate.begin (Config.APP_VERSION, (obj, res) => {
                migration_manager.check_and_migrate.end (res);
                migration_loop.quit ();
            });
            migration_loop.run ();

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

namespace ProtonPlus.Services.Migrations {

    public interface IMigration : Object {
        public abstract string version { get; }
        public abstract async void migrate () throws GLib.Error;
    }
}

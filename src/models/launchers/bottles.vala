namespace ProtonPlus.Models.Launchers {
    public class Bottles : Launcher {
        public Bottles (Launcher.InstallationTypes installation_type) {
            string[] directories = null;

            switch (installation_type) {
            case Launcher.InstallationTypes.SYSTEM:
                directories = new string[] { "/.local/share/bottles" };
                break;
            case Launcher.InstallationTypes.FLATPAK:
                directories = new string[] { "/.var/app/com.usebottles.bottles/data/bottles" };
                break;
            case Launcher.InstallationTypes.SNAP:
                break;
            }

            base ("Bottles", installation_type, Globals.RESOURCE_BASE + "/bottles.svg", directories);

            if (installed) {
                install.connect ((release) => true);
                uninstall.connect ((release) => true);
            }
        }
    }
}

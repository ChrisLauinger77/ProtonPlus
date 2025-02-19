namespace ProtonPlus.Models.Runners {
    public class Luxtorpeda : GitHub {
        public Luxtorpeda (Group group) {
            Object (group: group,
                    title: "Luxtorpeda",
                    description: _("Luxtorpeda provides Linux-native game engines for certain Windows-only games."),
                    endpoint: "https://api.github.com/repos/luxtorpeda-dev/luxtorpeda/releases",
                    asset_position: 0);
        }

        public override string get_directory_name (string release_name) {
            return @"$title $release_name";
        }
    }
}
namespace ProtonPlus.Models {
    public class Group : Object {
        public string title { get; set; }
        public string description { get; set; }
        public string directory { get; set; }
        public Launcher launcher { get; set; }
        public Gee.LinkedList<Tool> tools { get; set; }

        public Group (string title, string description, string directory, Launcher launcher) {
            this.title = title;
            this.description = description;
            this.directory = directory;
            this.launcher = launcher;

            if (!FileUtils.test (launcher.directory + directory, FileTest.IS_DIR)) {
                Utils.Filesystem.create_directory_async.begin (launcher.directory + directory, null);
            }
        }

        public List<string> get_tool_directories () {
            var directories = new List<string> ();

            try {
                foreach (var directory_path in launcher.get_tool_directories (this)) {
                    var compatibilitytoolvdf_path = "%s/compatibilitytool.vdf".printf (directory_path);

                    if (FileUtils.test (compatibilitytoolvdf_path, FileTest.IS_REGULAR)) {
                        var simple_runner = new Tools.Simple.from_path (directory_path);
                        directories.append (simple_runner.title);
                        continue;
                    }

                    File directory = File.new_for_path (directory_path);
                    FileEnumerator? enumerator = directory.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);

                    if (enumerator != null) {
                        FileInfo? file_info;
                        while ((file_info = enumerator.next_file ()) != null) {
                            if (file_info.get_file_type () != FileType.DIRECTORY)
                            continue;

                            var title = file_info.get_name ();

                            if (title != "LegacyRuntime")
                            directories.append (title);
                        }
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }

            return directories;
        }
    }
}

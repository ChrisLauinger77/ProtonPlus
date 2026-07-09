namespace ProtonPlus.Models.Launchers {
    public class Steam : Launcher {
        public List<SteamProfile> profiles;
        public SteamProfile profile { get; set; }
        public string default_compatibility_tool { get; set; }
        public HashTable<uint, string> compatibility_tool_hashtable;

        public Steam (Launcher.InstallationTypes installation_type) {
            string[] directories = null;

            switch (installation_type) {
                case Launcher.InstallationTypes.SYSTEM:
                    directories = new string[] {
                        "%s/Steam".printf (Environment.get_user_data_dir ()),
                        "%s/.local/share/Steam".printf (Environment.get_home_dir ()),
                        "%s/.steam/steam".printf (Environment.get_home_dir ()),
                        "%s/.steam/root".printf (Environment.get_home_dir ()),
                        "%s/.steam/debian-installation".printf (Environment.get_home_dir ()),
                        "/usr/share/steam",
                    };
                    break;
                case Launcher.InstallationTypes.FLATPAK:
                    directories = new string[] { "%s/.var/app/com.valvesoftware.Steam/data/Steam".printf (Environment.get_home_dir ()) };
                    break;
                case Launcher.InstallationTypes.SNAP:
                    directories = new string[] { "%s/snap/steam/common/.steam/root".printf (Environment.get_home_dir ()) };
                    break;
            }

            base ("Steam", installation_type, "%s/steam.svg".printf (Config.RESOURCE_BASE), directories);

            has_library_support = true;
        }

        public override List<string> get_tool_directories (Group group) {
            var directories = new List<string> ();
            directories.append (this.directory + group.directory);
            directories.append ("/usr/share/steam" + group.directory);

            if (installation_type != Launcher.InstallationTypes.FLATPAK) {
                return directories;
            }

            foreach (var extension_root in get_flatpak_steam_extension_roots ()) {
                if (is_tool_root (extension_root) && !path_exists_in_list (directories, extension_root)) {
                    directories.append (extension_root);
                }

                var extension_share_tools = "%s/share/steam%s".printf (extension_root, group.directory);
                if (FileUtils.test (extension_share_tools, FileTest.IS_DIR) && !path_exists_in_list (directories, extension_share_tools)) {
                    directories.append (extension_share_tools);
                }
            }

            return directories;
        }

        private List<string> get_flatpak_steam_extension_roots () {
            var extension_roots = new List<string> ();

            var runtime_roots = new string[] {
                "%s/.local/share/flatpak/runtime".printf (Environment.get_home_dir ()),
                "/var/lib/flatpak/runtime"
            };

            foreach (var runtime_root in runtime_roots) {
                if (!FileUtils.test (runtime_root, FileTest.IS_DIR)) {
                    continue;
                }

                try {
                    var runtime_root_file = File.new_for_path (runtime_root);
                    var runtime_enumerator = runtime_root_file.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);
                    if (runtime_enumerator == null) {
                        continue;
                    }

                    FileInfo? runtime_info;
                    while ((runtime_info = runtime_enumerator.next_file ()) != null) {
                        if (runtime_info.get_file_type () != FileType.DIRECTORY) {
                            continue;
                        }

                        var extension_id = runtime_info.get_name ();
                        if (!(extension_id.has_prefix ("com.valvesoftware.Steam.CompatibilityTool.") ||
                            extension_id.has_prefix ("com.valvesoftware.Steam.Utility."))) {
                            continue;
                        }

                        var extension_root = "%s/%s".printf (runtime_root, extension_id);
                        var extension_root_file = File.new_for_path (extension_root);
                        var arch_enumerator = extension_root_file.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);
                        if (arch_enumerator == null) {
                            continue;
                        }

                        FileInfo? arch_info;
                        while ((arch_info = arch_enumerator.next_file ()) != null) {
                            if (arch_info.get_file_type () != FileType.DIRECTORY) {
                                continue;
                            }

                            var arch_root = "%s/%s".printf (extension_root, arch_info.get_name ());
                            var arch_root_file = File.new_for_path (arch_root);
                            var branch_enumerator = arch_root_file.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);
                            if (branch_enumerator == null) {
                                continue;
                            }

                            FileInfo? branch_info;
                            while ((branch_info = branch_enumerator.next_file ()) != null) {
                                if (branch_info.get_file_type () != FileType.DIRECTORY) {
                                    continue;
                                }

                                var branch_root = "%s/%s".printf (arch_root, branch_info.get_name ());
                                var active_files = "%s/active/files".printf (branch_root);
                                if (FileUtils.test (active_files, FileTest.IS_DIR) && !path_exists_in_list (extension_roots, active_files)) {
                                    extension_roots.append (active_files);
                                }

                                var branch_root_file = File.new_for_path (branch_root);
                                var deploy_enumerator = branch_root_file.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);
                                if (deploy_enumerator == null) {
                                    continue;
                                }

                                FileInfo? deploy_info;
                                while ((deploy_info = deploy_enumerator.next_file ()) != null) {
                                    if (deploy_info.get_file_type () != FileType.DIRECTORY) {
                                        continue;
                                    }

                                    var deploy_name = deploy_info.get_name ();
                                    if (deploy_name == "active") {
                                        continue;
                                    }

                                    var deploy_files = "%s/%s/files".printf (branch_root, deploy_name);
                                    if (!FileUtils.test (deploy_files, FileTest.IS_DIR)) {
                                        continue;
                                    }

                                    if (!path_exists_in_list (extension_roots, deploy_files)) {
                                        extension_roots.append (deploy_files);
                                    }
                                }
                            }
                        }
                    }
                } catch (Error e) {
                    warning (e.message);
                }
            }

            return extension_roots;
        }

        private bool path_exists_in_list (List<string> paths, string target_path) {
            foreach (var path in paths) {
                if (path == target_path) {
                    return true;
                }
            }

            return false;
        }

        private bool is_tool_root (string path) {
            return FileUtils.test ("%s/compatibilitytool.vdf".printf (path), FileTest.IS_REGULAR);
        }

        public async void switch_profile (SteamProfile profile) {
            if (this.profile != null) {
                foreach (var non_steam_game in this.profile.non_steam_games) {
                    games.remove (non_steam_game);
                }
            }

            this.profile = profile;

            foreach (var game in (List<Games.Steam>) games) {
                var launch_options = profile.launch_options_hashtable.get (game.appid);
                game.launch_options = launch_options;
            }

            foreach (var non_steam_game in profile.non_steam_games) {
                games.append (non_steam_game);
            }
        }

        public override int get_compatibility_tool_usage_count (string compatibility_tool_name) {
            int count = 0;

            bool is_default_tool = (compatibility_tool_name == default_compatibility_tool);

            foreach (var game in games) {
                if (game.compatibility_tool == compatibility_tool_name || (is_default_tool && game.compatibility_tool == "Default")) {
                    if (!game.is_native)
                    count++;
                }
            }

            foreach (var profile in profiles) {
                foreach (var game in profile.non_steam_games) {
                    if (game.compatibility_tool == compatibility_tool_name || (is_default_tool && game.compatibility_tool == "Default")) {
                        if (!game.is_native)
                        count++;
                    }
                }
            }

            return count;
        }

        public override async bool load_game_library () {
            games = new List<Game> ();

            compatibility_tools.clear ();

            var awacy_games = yield Models.Games.Steam.AwacyGame.get_awacy_games ();

            var compatibility_tool_hashtable_loaded = yield load_compatibility_tool_hashtable ();
            if (!compatibility_tool_hashtable_loaded)
            return false;

            var default_compatibility_tool = compatibility_tool_hashtable.get (0);
            if (default_compatibility_tool != null)
            this.default_compatibility_tool = default_compatibility_tool;

            var libraryfolder_content = yield Utils.Filesystem.get_file_content_async ("%s/steamapps/libraryfolders.vdf".printf (directory));

            if (libraryfolder_content.length > 0) {
                var current_libraryfolder_content = "";
                var current_libraryfolder_id = 0;
                var current_libraryfolder_path = "";
                var current_apps = "";
                var current_appid = "";
                var current_steamapps_path = "";
                var current_manifest_path = "";
                var current_manifest_content = "";
                var current_name = "";
                var current_installdir = "";
                var start_text = "";
                var end_text = "";
                var start_pos = 0;
                var end_pos = 0;
                var current_position = 0;

                var proton_regex = / (?i)Proton\s*\d+ (\.\d+)?/;
                var name_regex = /\"name\"\s+\"([^\"]+)\"/;
                var dir_regex = /\"installdir\"\s+\"([^\"]+)\"/;

                var excluded_appids = new Gee.HashSet<string> ();
                excluded_appids.add_all_array (new string[] {
                    "2230260", "1826330", "1161040", "1070560", "1628350", "228980", "4183110", "3086180"
                });

                var natival_compatibility_tool_appids = new Gee.HashSet<string> ();
                natival_compatibility_tool_appids.add_all_array (new string[] {
                    "2180100", "1493710", "3658110", "4628710", "2348590", "2805730"
                });

                while (true) {
                    start_text = "%i\"\n\t{".printf (current_libraryfolder_id++);
                    end_text = "}";
                    start_pos = libraryfolder_content.index_of (start_text, 0) + start_text.length;

                    if (start_pos - start_text.length == -1)
                    break;

                    end_pos = libraryfolder_content.index_of (end_text, start_pos);
                    current_libraryfolder_content = libraryfolder_content.substring (start_pos, end_pos - start_pos);
                    current_position = end_pos;

                    if (current_libraryfolder_content.contains ("apps")) {
                        end_pos = libraryfolder_content.index_of (end_text, current_position + 1);
                        current_libraryfolder_content = libraryfolder_content.substring (start_pos, end_pos - start_pos);

                        start_text = "path\"\t\t\"";
                        end_text = "\"";
                        start_pos = current_libraryfolder_content.index_of (start_text, 0) + start_text.length;
                        end_pos = current_libraryfolder_content.index_of (end_text, start_pos);
                        current_libraryfolder_path = current_libraryfolder_content.substring (start_pos, end_pos - start_pos);
                        current_position = end_pos;

                        start_text = "apps\"\n\t\t{\n";
                        end_text = "}";
                        start_pos = current_libraryfolder_content.index_of (start_text, current_position) + start_text.length;
                        end_pos = current_libraryfolder_content.index_of (end_text, start_pos);
                        current_apps = current_libraryfolder_content.substring (start_pos, end_pos - start_pos);
                        current_position = 0;

                        while (true) {
                            start_text = "\t\t\t\"";
                            end_text = "\"";
                            start_pos = current_apps.index_of (start_text, current_position) + start_text.length;

                            if (start_pos - start_text.length == -1)
                            break;

                            end_pos = current_apps.index_of (end_text, start_pos + start_text.length);
                            current_appid = current_apps.substring (start_pos, end_pos - start_pos);
                            current_position = end_pos;

                            uint id = 0;
                            var id_valid = uint.try_parse (current_appid, out id);
                            if (!id_valid)
                            continue;

                            if (excluded_appids.contains (current_appid))
                                continue;

                            current_steamapps_path = "%s/steamapps".printf (current_libraryfolder_path);
                            if (!FileUtils.test (current_steamapps_path, FileTest.IS_DIR))
                            continue;

                            current_manifest_path = "%s/appmanifest_%s.acf".printf (current_steamapps_path, current_appid);
                            if (!FileUtils.test (current_manifest_path, FileTest.IS_REGULAR))
                            continue;
                            current_manifest_content = Utils.Filesystem.get_file_content (current_manifest_path);

                            MatchInfo name_match;
                            if (!name_regex.match (current_manifest_content, 0, out name_match))
                            continue;
                            current_name = name_match.fetch (1);

                            MatchInfo dir_match;
                            if (!dir_regex.match (current_manifest_content, 0, out dir_match))
                            continue;
                            current_installdir = dir_match.fetch (1);

                            if (current_name.contains ("Steam Linux Runtime")) {
                                var simple_runner = new Tools.Simple.with_path (
                                    current_name,
                                    current_name.down ().split (".", 2)[0].replace (" ", "_"),
                                    "%s/common/%s".printf (current_steamapps_path, current_installdir)
                                );
                                simple_runner.sort_priority = get_compatibility_tool_sort_priority (simple_runner);
                                compatibility_tools.add (simple_runner);
                                continue;
                            }

                            if (proton_regex.match (current_name) ||
                                current_name == "Proton Hotfix" ||
                                natival_compatibility_tool_appids.contains (current_appid)) {
                                var simple_runner = new Tools.Simple.with_path (
                                    current_name,
                                    current_name.down ().split (".", 2)[0].replace (" ", "_"),
                                    "%s/common/%s".printf (current_steamapps_path, current_installdir)
                                );
                                simple_runner.sort_priority = get_compatibility_tool_sort_priority (simple_runner);
                                compatibility_tools.add (simple_runner);
                                continue;
                            }

                            if (!FileUtils.test ("%s/common/%s".printf (current_steamapps_path, current_installdir), FileTest.IS_DIR))
                            continue;

                            var game = new Games.Steam (id, current_name, current_installdir, current_libraryfolder_id, current_libraryfolder_path, this);

                            if (awacy_games.has_key (game.appid)) {
                                var awacy_game = awacy_games.get (game.appid);
                                game.awacy_name = awacy_game.name;
                                game.awacy_status = awacy_game.status;
                            }

                            var compatibility_tool = compatibility_tool_hashtable.get (game.appid);
                            if (compatibility_tool == null)
                            compatibility_tool = "Default";
                            game.compatibility_tool = compatibility_tool;

                            games.append (game);
                        }
                    } else {
                        continue;
                    }
                }
            }

            try {
                foreach (var group in groups) {
                    var tool_directory = "%s%s".printf (directory, group.directory);
                    if (!FileUtils.test (tool_directory, FileTest.IS_DIR)) {
                        continue;
                    }

                    File directory = File.new_for_path (tool_directory);
                    FileEnumerator? enumerator = directory.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);

                    if (enumerator != null) {
                        FileInfo? file_info;
                        while ((file_info = enumerator.next_file ()) != null) {
                            if (file_info.get_file_type () != FileType.DIRECTORY)
                            continue;

                            if (file_info.get_name ().contains ("wine-proton-exp") || file_info.get_name () == "LegacyRuntime") {
                                continue;
                            }

                            var file_path = "%s/%s".printf (directory.get_path (), file_info.get_name ());
                            var simple_runner = new Tools.Simple.from_path (file_path);
                            simple_runner.sort_priority = get_compatibility_tool_sort_priority (simple_runner);
                            compatibility_tools.add (simple_runner);
                        }
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }

            if (installation_type == Launcher.InstallationTypes.FLATPAK) {
                add_flatpak_extension_tools_to_compatibility_tools ();
            }

            sort_compatibility_tools ();

            return true;
        }

        private void add_flatpak_extension_tools_to_compatibility_tools () {
            foreach (var extension_root in get_flatpak_steam_extension_roots ()) {
                if (is_tool_root (extension_root)) {
                    var simple_runner = new Tools.Simple.from_path (extension_root);
                    add_compatibility_tool_if_missing (simple_runner);
                }

                var extension_tools_root = "%s/share/steam/compatibilitytools.d".printf (extension_root);
                if (!FileUtils.test (extension_tools_root, FileTest.IS_DIR)) {
                    continue;
                }

                try {
                    var extension_tools_directory = File.new_for_path (extension_tools_root);
                    var enumerator = extension_tools_directory.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);
                    if (enumerator == null) {
                        continue;
                    }

                    FileInfo? file_info;
                    while ((file_info = enumerator.next_file ()) != null) {
                        if (file_info.get_file_type () != FileType.DIRECTORY) {
                            continue;
                        }

                        var tool_path = "%s/%s".printf (extension_tools_root, file_info.get_name ());
                        add_compatibility_tool_if_missing (new Tools.Simple.from_path (tool_path));
                    }
                } catch (Error e) {
                    warning (e.message);
                }
            }
        }

        private void add_compatibility_tool_if_missing (Tools.Simple simple_runner) {
            foreach (var existing_runner in compatibility_tools) {
                if (existing_runner.path == simple_runner.path || existing_runner.internal_title == simple_runner.internal_title) {
                    return;
                }
            }

            simple_runner.sort_priority = get_compatibility_tool_sort_priority (simple_runner);
            compatibility_tools.add (simple_runner);
        }

        public void register_compatibility_tool (Tools.Simple simple_runner) {
            add_compatibility_tool_if_missing (simple_runner);
            sort_compatibility_tools ();
        }

        public void unregister_compatibility_tool_by_path (string tool_path) {
            var tool = compatibility_tools.first_match ((tool) => {
                return tool.path == tool_path;
            });

            if (tool == null) {
                return;
            }

            compatibility_tools.remove (tool);
            sort_compatibility_tools ();
        }

        private void sort_compatibility_tools () {
            compatibility_tools.sort ((a, b) => {
                if (a.sort_priority != b.sort_priority)
                    return a.sort_priority - b.sort_priority;

                int a_major = 0;
                int a_minor = 0;
                int b_major = 0;
                int b_minor = 0;

                var has_a_proton_version = try_parse_any_proton_version (a.display_title, out a_major, out a_minor);
                var has_b_proton_version = try_parse_any_proton_version (b.display_title, out b_major, out b_minor);

                if (has_a_proton_version && has_b_proton_version) {
                    if (a_major != b_major)
                        return b_major - a_major;

                    if (a_minor != b_minor)
                        return b_minor - a_minor;
                }

                return strcmp (a.display_title.down (), b.display_title.down ());
            });
        }

        private int get_compatibility_tool_sort_priority (Tools.Simple tool) {
            var title = tool.display_title.down ();
            var internal_title = tool.internal_title.down ();

            if (internal_title == "proton_experimental" || title.contains ("proton experimental")) {
                return 100;
            }

            if (internal_title == "proton_hotfix" || title.contains ("proton hotfix")) {
                return 150;
            }

            int major = 0;
            int minor = 0;
            if (try_parse_proton_version (tool.display_title, out major, out minor)) {
                return 200;
            }

            if (title.contains ("proton") || internal_title.contains ("proton")) {
                return 300;
            }

            if (title.contains ("steam linux runtime") || internal_title.contains ("steamlinuxruntime")) {
                return 400;
            }

            return 500;
        }

        private bool try_parse_proton_version (string title, out int major, out int minor) {
            major = 0;
            minor = 0;

            try {
                var regex = new GLib.Regex ("(?i)^\\s*proton\\s+(\\d+)(?:\\.(\\d+))?");
                GLib.MatchInfo match;
                if (!regex.match (title, 0, out match)) {
                    return false;
                }

                int.try_parse (match.fetch (1), out major);

                var minor_text = match.fetch (2);
                if (minor_text != null && minor_text != "") {
                    int.try_parse (minor_text, out minor);
                }

                return true;
            } catch (GLib.RegexError e) {
                return false;
            }
        }

        private bool try_parse_any_proton_version (string title, out int major, out int minor) {
            major = 0;
            minor = 0;

            try {
                // Matches custom names like GE-Proton11-1, proton-cachyos-11.0, etc.
                var regex = new GLib.Regex ("(?i)proton[^0-9]*(\\d+)(?:[\\._-](\\d+))?");
                GLib.MatchInfo match;
                if (!regex.match (title, 0, out match)) {
                    return false;
                }

                int.try_parse (match.fetch (1), out major);

                var minor_text = match.fetch (2);
                if (minor_text != null && minor_text != "") {
                    int.try_parse (minor_text, out minor);
                }

                return true;
            } catch (GLib.RegexError e) {
                return false;
            }
        }

        async bool load_compatibility_tool_hashtable () {
            compatibility_tool_hashtable = new HashTable<uint, string> (null, null);

            var config_content = yield Utils.Filesystem.get_file_content_async ("%s/config/config.vdf".printf (directory));
            var compat_tool_mapping_content = "";
            var compat_tool_mapping_item = "";
            uint compat_tool_mapping_item_appid = 0;
            var compat_tool_mapping_item_name = "";
            var start_text = "";
            var end_text = "";
            var start_pos = 0;
            var end_pos = 0;
            var current_position = 0;

            start_text = "CompatToolMapping\"\n\t\t\t\t";

            if (!config_content.contains (start_text)) {
                compatibility_tool_hashtable.set (0, "proton_experimental");

                return true;
            }

            end_text = "\n\t\t\t\t}";
            start_pos = config_content.index_of (start_text, 0) + start_text.length;
            end_pos = config_content.index_of (end_text, start_pos);
            compat_tool_mapping_content = config_content.substring (start_pos, end_pos - start_pos);

            while (true) {
                start_text = "\"";
                end_text = "}";
                start_pos = compat_tool_mapping_content.index_of (start_text, current_position);

                if (start_pos == -1)
                break;

                end_pos = compat_tool_mapping_content.index_of (end_text, start_pos) + 1;
                compat_tool_mapping_item = compat_tool_mapping_content.substring (start_pos, end_pos - start_pos);
                current_position = end_pos;

                start_text = "\"";
                end_text = "\"";
                start_pos = compat_tool_mapping_item.index_of (start_text, 0) + start_text.length;
                end_pos = compat_tool_mapping_item.index_of (end_text, start_pos);
                var compat_tool_mapping_item_appid_text = compat_tool_mapping_item.substring (start_pos, end_pos - start_pos);
                var compat_tool_mapping_item_appid_valid = uint.try_parse (compat_tool_mapping_item_appid_text, out compat_tool_mapping_item_appid);
                if (!compat_tool_mapping_item_appid_valid)
                continue;

                start_text = "name\"\t\t\"";
                end_text = "\"";
                start_pos = compat_tool_mapping_item.index_of (start_text, 0) + start_text.length;
                end_pos = compat_tool_mapping_item.index_of (end_text, start_pos);
                compat_tool_mapping_item_name = compat_tool_mapping_item.substring (start_pos, end_pos - start_pos);

                compatibility_tool_hashtable.set (compat_tool_mapping_item_appid, compat_tool_mapping_item_name);
            }

            return true;
        }

        public bool change_default_compatibility_tool (string compatibility_tool) {
            var default_id = 0;
            var config_path = "%s/config/config.vdf".printf (directory);
            var config_content = Utils.Filesystem.get_file_content (config_path);
            var compat_tool_mapping_content = "";
            var compat_tool_mapping_item = "";
            var compat_tool_mapping_item_appid = 0;
            var compat_tool_mapping_item_name = "";
            var start_text = "";
            var end_text = "";
            var start_pos = 0;
            var end_pos = 0;

            start_text = "\"CompatToolMapping\"\n\t\t\t\t{";
            end_text = "\n\t\t\t\t}";
            if (config_content.index_of (start_text, 0) == -1) {
                var start_steam_text = "\"Steam\"\n\t\t\t{";
                var start_steam_pos = config_content.index_of (start_steam_text, 0);
                var insert_pos = start_steam_pos + start_steam_text.length;
                config_content =
                config_content.substring (0, insert_pos) +
                "\n\t\t\t\t\"CompatToolMapping\"\n\t\t\t\t{\n\t\t\t\t}" +
                config_content.substring (insert_pos);
            }
            start_pos = config_content.index_of (start_text, 0) + start_text.length;
            end_pos = config_content.index_of (end_text, start_pos);
            compat_tool_mapping_content = config_content.substring (start_pos, end_pos - start_pos);

            if (compat_tool_mapping_content.contains ("\"%i\"".printf (default_id))) {
                start_text = "\t\t\t\t\t\"%i\"".printf (default_id);
                start_pos = compat_tool_mapping_content.index_of (start_text, 0);
                if (start_pos == -1)
                return false;

                end_text = "}";
                end_pos = compat_tool_mapping_content.index_of (end_text, start_pos + start_text.length) + end_text.length;
                if (end_pos == -1)
                return false;

                compat_tool_mapping_item = compat_tool_mapping_content.substring (start_pos, end_pos - start_pos);

                start_text = "\"";
                start_pos = compat_tool_mapping_item.index_of (start_text, 0) + start_text.length;
                if (start_pos == -1)
                return false;

                end_text = "\"";
                end_pos = compat_tool_mapping_item.index_of (end_text, start_pos);
                if (end_pos == -1)
                return false;

                var compat_tool_mapping_item_appid_text = compat_tool_mapping_item.substring (start_pos, end_pos - start_pos);
                var compat_tool_mapping_item_appid_valid = int.try_parse (compat_tool_mapping_item_appid_text, out compat_tool_mapping_item_appid);
                if (!compat_tool_mapping_item_appid_valid)
                return false;

                if (compat_tool_mapping_item_appid != 0)
                return false;

                start_text = "name\"\t\t\"";
                start_pos = compat_tool_mapping_item.index_of (start_text, 0) + start_text.length;
                if (start_pos == -1)
                return false;

                end_text = "\"";
                end_pos = compat_tool_mapping_item.index_of (end_text, start_pos);
                if (end_pos == -1)
                return false;

                compat_tool_mapping_item_name = compat_tool_mapping_item.substring (start_pos, end_pos - start_pos);

                var compat_tool_mapping_item_modified = compat_tool_mapping_item.replace (compat_tool_mapping_item_name, compatibility_tool);

                config_content = config_content.replace (compat_tool_mapping_item, compat_tool_mapping_item_modified);
            } else {
                config_content =
                config_content.substring (0, start_pos) +
                "\n\t\t\t\t\t\"%i\"\n\t\t\t\t\t{\n".printf (default_id) +
                "\t\t\t\t\t\t\"name\"\t\t\"%s\"\n".printf (compatibility_tool) +
                "\t\t\t\t\t\t\"config\"\t\t\"\"\n" +
                "\t\t\t\t\t\t\"priority\"\t\t\"75\"\n" +
                "\t\t\t\t\t}" +
                config_content.substring (start_pos);
            }

            var modified = Utils.Filesystem.modify_file (config_path, config_content);
            if (!modified)
            return false;

            this.default_compatibility_tool = compatibility_tool;

            return true;
        }
    }
}

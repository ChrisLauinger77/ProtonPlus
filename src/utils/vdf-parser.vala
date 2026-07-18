using Json;
using Gee;

namespace ProtonPlus.Utils {

    public class VdfParser : GLib.Object {

        public static Models.Steam.SteamLibraryConfig? parse_library_folders (string vdf_content) {
            var config = new Models.Steam.SteamLibraryConfig ();

            try {
                string json_str = convert_vdf_to_json (vdf_content);

                var parser = new Json.Parser ();
                parser.load_from_data (json_str);

                var root_object = parser.get_root ().get_object ();
                if (!root_object.has_member ("libraryfolders")) {
                    return null;
                }

                var folders_object = root_object.get_object_member ("libraryfolders");

                foreach (var member_name in folders_object.get_members ()) {
                    if (folders_object.get_member (member_name).get_node_type () != Json.NodeType.OBJECT) {
                        continue;
                    }

                    var folder_node = folders_object.get_object_member (member_name);
                    var folder = new Models.Steam.LibraryFolder ();
                    folder.id = int.parse (member_name);
                    folder.path = folder_node.get_string_member ("path");
                    folder.label = folder_node.has_member ("label") ? folder_node.get_string_member ("label") : "";

                    if (folder_node.has_member ("totalsize")) {
                        folder.totalsize = int64.parse (folder_node.get_string_member ("totalsize"));
                    }
                    if (folder_node.has_member ("apps")) {
                        var apps_node = folder_node.get_object_member ("apps");
                        foreach (var app_id in apps_node.get_members ()) {
                            var val_node = apps_node.get_member (app_id);
                            string val = val_node.get_node_type () == Json.NodeType.VALUE ? val_node.get_value ().get_string () : "";
                            folder.apps.set (app_id, val);
                        }
                    }

                    config.folders.add (folder);
                }

                return config;

            } catch (Error e) {
                warning ("Error parsing VDF/JSON: %s", e.message);
                return null;
            }
        }

        public static string convert_vdf_to_json (string vdf) {
            string res = vdf;

            try {
                var comment_regex = new Regex ("//.*");
                res = comment_regex.replace (res, res.length, 0, "");

                var comma_regex = new Regex ("\"\\s*\\n\\s*\"");
                res = comma_regex.replace (res, res.length, 0, "\",\n\"");

                var bracket_comma_regex = new Regex ("}\\s*\\n\\s*\"");
                res = bracket_comma_regex.replace (res, res.length, 0, "},\n\"");

                var colon_regex = new Regex ("\"\\s+(\"[^\"]*\"|{)");
                res = colon_regex.replace (res, res.length, 0, "\": \\1");

                res = "{\n" + res + "\n}";

            } catch (RegexError e) {
                critical ("Regex error: %s", e.message);
            }

            return res;
        }
    }
}

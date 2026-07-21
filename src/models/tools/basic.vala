namespace ProtonPlus.Models.Tools {
    public abstract class Basic : Tool {
        internal ProtonPlus.Models.Launchers.Runners.IRunner? source_runner { get; set; }
        internal string endpoint { get; set; }
        internal string directory_name_format { get; set; }
        public string tag { get; set; }

        public virtual string get_directory_name (string release_name) {
            if (release_name.contains ("Latest"))
                return release_name;

            var directory_name = new StringBuilder (directory_name_format);

            directory_name.replace ("$release_name", release_name);
            directory_name.replace ("$title", title);

            if (directory_name.len > 0 && directory_name.str[0] == '_') {
                directory_name.replace ("_", "", 1);
                directory_name.str = directory_name.str.ascii_down ();
            }

            if (directory_name.len > 0 && directory_name.str[0] == '!') {
                directory_name.replace ("!", "", 1);
                var split = directory_name.str.split (":");
                if (split.length >= 3)
                    directory_name.str = split[0].replace (split[1], split[2]);
            }

            if (directory_name.len > 0 && directory_name.str[0] == '&') {
                directory_name.replace ("&", "", 1);
                var split = directory_name.str.split (":");
                if (split.length >= 4)
                    directory_name.str = split[0].contains (split[1]) ? split[2] : split[3];
            }

            return directory_name.str;
        }

        private string render_variant_asset_name (Variant variant, string release_name, string tag_name) {
            var asset_name = new StringBuilder (variant.format);
            asset_name.replace ("$title", title);
            asset_name.replace ("$release_name", release_name);
            asset_name.replace ("$tag_name", tag_name);
            return asset_name.str;
        }

        private string get_archive_stem (string asset_name) {
            return Utils.ArchiveHelper.strip_archive_extension (asset_name);
        }

        private bool variant_matches_asset (string expected_asset_name, string asset_name) {
            if (asset_name == expected_asset_name)
                return true;

            return get_archive_stem (asset_name) == expected_asset_name;
        }

        public virtual Gee.LinkedList<Variant> create_release_variants (
            string release_name,
            string tag_name,
            Gee.LinkedList<ProtonPlus.Models.Internal.Assets.IAsset> assets,
            string? fallback_download_url = null
        ) {
            var release_variants = new Gee.LinkedList<Variant> ();

            foreach (var variant in this.variants) {
                string? variant_download_url = null;
                var expected_asset_name = render_variant_asset_name (variant, release_name, tag_name);

                foreach (var asset in assets) {
                    if (variant_matches_asset (expected_asset_name, asset.name)) {
                        variant_download_url = asset.download_url;
                        break;
                    }
                }

                if (variant_download_url == null && variant.is_default) {
                    variant_download_url = fallback_download_url;
                }

                release_variants.add (new Variant (variant.name, variant.format, variant.is_default, this, variant_download_url));
            }

            return release_variants;
        }

        public string? get_default_variant_download_url (Gee.LinkedList<Variant> release_variants, string? fallback_download_url = null) {
            foreach (var variant in release_variants) {
                if (variant.is_default && variant.download_url != null && variant.download_url != "") {
                    return variant.download_url;
                }
            }

            return fallback_download_url;
        }

        public virtual void update_variant_download_url (string release_name) {
            foreach (var variant in this.variants) {
                var url = new StringBuilder (variant.format);
                url.replace ("$title", title);
                url.replace ("$release_name", release_name);
                variant.download_url = url.str;
            }
        }

        private string get_variant_directory_suffix (Variant variant) {
            if (variant.is_default)
                return "";

            var sanitized_variant_name = variant.name.replace (" ", "_").replace ("/", "_");
            return "-%s".printf (sanitized_variant_name);
        }

        private bool marker_matches_current_runner (string directory_path) {
            var endpoint_marker = "%s/.protonplus_runner_endpoint".printf (directory_path);
            if (FileUtils.test (endpoint_marker, FileTest.IS_REGULAR)) {
                var installed_endpoint = Utils.Filesystem.get_file_content (endpoint_marker).strip ();
                if (installed_endpoint == endpoint)
                    return true;
            }

            var title_marker = "%s/.protonplus_runner_title".printf (directory_path);
            if (FileUtils.test (title_marker, FileTest.IS_REGULAR)) {
                var installed_title = Utils.Filesystem.get_file_content (title_marker).strip ();
                if (installed_title == title)
                    return true;
            }

            return false;
        }

        private void persist_runner_markers (string directory_path) {
            var endpoint_marker = "%s/.protonplus_runner_endpoint".printf (directory_path);
            var title_marker = "%s/.protonplus_runner_title".printf (directory_path);

            if (FileUtils.test (endpoint_marker, FileTest.IS_REGULAR))
                Utils.Filesystem.modify_file (endpoint_marker, endpoint);
            else
                Utils.Filesystem.create_file (endpoint_marker, endpoint);

            if (FileUtils.test (title_marker, FileTest.IS_REGULAR))
                Utils.Filesystem.modify_file (title_marker, title);
            else
                Utils.Filesystem.create_file (title_marker, title);
        }

        private bool identifier_matches_tool (string identifier) {
            if (identifier == "")
                return false;

            if (identifier == title || identifier == "%s Latest".printf (title))
                return true;

            if (releases == null || releases.size == 0)
                return false;

            foreach (var release in releases) {
                var directory_name = get_directory_name (release.title);
                if (identifier == directory_name)
                    return true;

                foreach (var variant in variants) {
                    if (identifier == "%s%s".printf (directory_name, get_variant_directory_suffix (variant)))
                        return true;
                }
            }

            return false;
        }

        private string? get_matching_usage_identifier_for_directory (string directory_path) {
            if (marker_matches_current_runner (directory_path)) {
                var compatibilitytoolvdf_path = "%s/compatibilitytool.vdf".printf (directory_path);
                if (!FileUtils.test (compatibilitytoolvdf_path, FileTest.IS_REGULAR))
                    return Path.get_basename (directory_path);

                var simple_runner = new Tools.Simple.from_path (directory_path);
                return simple_runner.internal_title != "" ? simple_runner.internal_title : Path.get_basename (directory_path);
            }

            var directory_name = Path.get_basename (directory_path);
            if (identifier_matches_tool (directory_name)) {
                persist_runner_markers (directory_path);
                return directory_name;
            }

            var compatibilitytoolvdf_path = "%s/compatibilitytool.vdf".printf (directory_path);
            if (!FileUtils.test (compatibilitytoolvdf_path, FileTest.IS_REGULAR))
                return null;

            var simple_runner = new Tools.Simple.from_path (directory_path);
            if (identifier_matches_tool (simple_runner.internal_title)) {
                persist_runner_markers (directory_path);
                return simple_runner.internal_title;
            }

            if (identifier_matches_tool (simple_runner.title)) {
                persist_runner_markers (directory_path);
                return simple_runner.internal_title != "" ? simple_runner.internal_title : simple_runner.title;
            }

            return null;
        }

        private string? get_installed_usage_identifier () {
            foreach (var directory_root in group.launcher.get_tool_directories (group)) {
                var direct_match = get_matching_usage_identifier_for_directory (directory_root);
                if (direct_match != null)
                    return direct_match;

                if (!FileUtils.test (directory_root, FileTest.IS_DIR))
                    continue;

                try {
                    File directory = File.new_for_path (directory_root);
                    FileEnumerator? enumerator = directory.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);

                    if (enumerator == null)
                        continue;

                    FileInfo? file_info;
                    while ((file_info = enumerator.next_file ()) != null) {
                        if (file_info.get_file_type () != FileType.DIRECTORY)
                            continue;

                        var directory_path = "%s/%s".printf (directory_root, file_info.get_name ());
                        var child_match = get_matching_usage_identifier_for_directory (directory_path);
                        if (child_match != null)
                            return child_match;
                    }
                } catch (Error e) {
                    warning (e.message);
                }
            }

            return null;
        }

        public override bool is_installed () {
            return get_installed_usage_identifier () != null;
        }

        public override bool is_used () {
            var usage_identifier = get_installed_usage_identifier ();
            if (usage_identifier == null)
                return false;

            return group.launcher.get_compatibility_tool_usage_count (usage_identifier) > 0;
        }

        public bool is_asset_exclude (string title, string[]? exclude_asset) {
            if (exclude_asset == null)
                return false;

            var excluded = false;

            foreach (var excluded_asset in exclude_asset) {
                if (title.contains (excluded_asset)) {
                    excluded = true;
                    break;
                }
            }

            return excluded;
        }
    }
}

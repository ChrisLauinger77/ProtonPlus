namespace ProtonPlus.Widgets.Games.LaunchOptionsEditor {
    using Adw;

    class EntryBinding : BaseBinding, ILaunchOption {
        public unowned LaunchOptionEntryField entry_field { get; set; }
        public unowned Gtk.Switch toggle { get; set; }

        public EntryBinding (LaunchOptionEntryField entry_field, Gtk.Switch toggle) {
            base (true, LaunchLineType.ADDITIONAL);
            this.entry_field = entry_field;
            this.toggle = toggle;
        }

        public void parse_tokens (string[] tokens_pool, bool[] consumed) {
            if (tokens_pool.length != consumed.length)
                return;

            string custom_args = "";

            for (var i = 0; i < tokens_pool.length; i++) {
                if (!consumed[i] && tokens_pool[i] != "%command%") {
                    if (custom_args != "")
                        custom_args += " ";

                    custom_args += tokens_pool[i];
                    consumed[i] = true;
                }
            }

            if (custom_args != "") {
                this.entry_field.set_text (custom_args);
                this.toggle.set_active (true);
            }

            foreach (var child in this._children) {
                child.parse_tokens (tokens_pool, consumed);
            }
        }

        public void append_command_segments (Gee.LinkedList<string> segments) {
            if (!this.toggle.get_active ())
                return;

            string text = this.entry_field.get_text ().strip ();
            if (text == "")
                return;

            string[] custom_tokens = text.split (" ");
            foreach (var token in custom_tokens) {
                if (token.strip () != "") {
                    segments.add (token);
                }
            }

            foreach (var child in this._children) {
                if (child.is_active ()) {
                    child.append_command_segments (segments);
                }
            }
        }

        public void clear () {
            this.toggle.set_active (false);
            this.entry_field.set_text ("");
            foreach (var child in this._children) {
                child.clear ();
            }
        }

        public bool is_active () {
            return this.toggle.get_active () && this.entry_field.get_text ().strip () != "";
        }

        public Gee.LinkedList<string> get_env_tokens () {
            return get_custom_tokens (true);
        }

        public Gee.LinkedList<string> get_argument_tokens () {
            return get_custom_tokens (false);
        }

        private Gee.LinkedList<string> get_custom_tokens (bool environment_tokens) {
            var result = new Gee.LinkedList<string> ();
            if (!this.toggle.get_active ())
                return result;

            string text = this.entry_field.get_text ().strip ();
            if (text == "")
                return result;

            foreach (var token in text.split (" ")) {
                var cleaned_token = token.strip ();
                if (cleaned_token != "" && cleaned_token.contains ("=") == environment_tokens)
                    result.add (cleaned_token);
            }

            return result;
        }
    }
}

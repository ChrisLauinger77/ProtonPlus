namespace ProtonPlus.Widgets.Games.LaunchOptionsEditor.Groups {
    using Adw;

    public class AudioOptionsGroup : BaseOptionsGroup {

        LaunchOptionSpinTile pulse_latency_tile { get; private set; }
        LaunchOptionEnvCombo winealsa_channels_tile { get; private set; }
        LaunchOptionTile winealsa_spacial_tile { get; private set; }


        public AudioOptionsGroup (LaunchOptionsList launch_option_handlers) {
            base (launch_option_handlers, true);

            this.title = _ ("Audio options");
            this.description = _ ("Audio-related launch options.");

            pulse_latency_tile = create_spin_tile (
                _ ("PulseAudio low latency"),
                _ ("Enables low latency mode in PulseAudio which can reduce audio latency in some games (60, 90, 120)."),
                _ ("MSEC"),
                30, 360,
                90,
                 "PULSE_LATENCY_MSEC="
            );

            string[] winealsa_channel_display_opts = {
                _ ("Disabled"),
                "2 (stereo)",
                "4 (2 front, 2 rear)",
                "6 (5.1)",
                "8 (7.1)"
            };

            string[] winealsa_channel_value_opts = { "", "2", "4", "6", "8" };

            winealsa_channels_tile = new LaunchOptionEnvCombo (
                "WINEALSA_CHANNELS",
                _ ("WINEALSA Channels"),
                _ ("Sets the number of ALSA output channels used by Wine. Available from GE-Proton11-1."),
                winealsa_channel_display_opts,
                winealsa_channel_value_opts
            );

            winealsa_channels_tile.changed.connect (() => {
                refresh_winealsa_spacial_state ();
                this.changed ();
            });

            launch_option_handlers.add (winealsa_channels_tile);

            winealsa_spacial_tile = create_tile (
                _ ("WINEALSA Spatial Audio"),
                _ ("Enables spatial mixing in Wine ALSA audio output. Requires WINEALSA Channels set to 4, 6, or 8. Available from GE-Proton11-1."),
                { "WINEALSA_SPACIAL=1" }
            );

            winealsa_spacial_tile.toggle.notify["active"].connect (() => {
                if (!is_winealsa_spacial_supported () && winealsa_spacial_tile.toggle.get_active ()) {
                    winealsa_spacial_tile.toggle.set_active (false);
                }
            });

            refresh_winealsa_spacial_state ();

            this.add (pulse_latency_tile);
            this.add (winealsa_channels_tile);
            this.add (winealsa_spacial_tile);
        }

        private bool is_winealsa_spacial_supported () {
            var channels = winealsa_channels_tile.value;
            return channels == "4" || channels == "6" || channels == "8";
        }

        private void refresh_winealsa_spacial_state () {
            var spacial_supported = is_winealsa_spacial_supported ();
            winealsa_spacial_tile.set_sensitive (spacial_supported);
            if (!spacial_supported) {
                winealsa_spacial_tile.toggle.set_active (false);
            }
        }
    }
}

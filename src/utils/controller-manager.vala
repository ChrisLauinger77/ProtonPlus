namespace ProtonPlus.Utils {
    public class ControllerManager : Object {
        private class GamepadState : Object {
            public SDL.Joystick.JoystickID id;
            public SDL.Gamepad.Gamepad gamepad;
            public double stick_y = 0;

            public GamepadState (SDL.Joystick.JoystickID id, SDL.Gamepad.Gamepad gamepad) {
                this.id = id;
                this.gamepad = gamepad;
            }
        }

        Widgets.Window window;
        uint timeout_id = 0;
        uint repeat_timeout_id = 0;
        bool sdl_initialized = false;
        bool controller_active = false;
        Gtk.Widget? highlighted = null;
        Gtk.EventControllerMotion? motion = null;
        bool is_motion_attached = false;
        GamepadState? repeating_gamepad = null;
        SDL.Gamepad.GamepadButton repeating_button = SDL.Gamepad.GamepadButton.INVALID;
        Gee.ArrayList<GamepadState> gamepads = new Gee.ArrayList<GamepadState> ();
        Gee.ArrayList<Adw.Dialog> dialogs = new Gee.ArrayList<Adw.Dialog> ();

        const double DEADZONE = 0.25;
        const double SCROLL_SPEED = 12.0;
        const uint INITIAL_REPEAT_DELAY = 350;
        const uint REPEAT_INTERVAL = 75;

        public ControllerManager (Widgets.Window window) {
            this.window = window;

            motion = new Gtk.EventControllerMotion ();
            motion.motion.connect ((x, y) => deactivate_controller_mode ());
            window.notify["is-active"].connect (() => {
                if (!window.is_active)
                    reset_stick_state ();
            });
        }

        public void start () {
            if (timeout_id != 0)
                return;

            if (!SDL.Init.init (SDL.Init.InitFlags.GAMEPAD)) {
                warning ("SDL3 gamepad init FAILED: %s", SDL.Error.get_error ());
                return;
            }

            sdl_initialized = true;
            SDL.Gamepad.set_gamepad_events_enabled (true);

            unowned SDL.Joystick.JoystickID[]? ids = SDL.Gamepad.get_gamepads ();
            if (ids != null) {
                foreach (var id in ids)
                    open_gamepad (id);

                SDL.StdInc.free ((void*) ids);
            } else {
                warning ("Unable to enumerate gamepads: %s", SDL.Error.get_error ());
            }

            ((Gtk.Widget) window).add_controller (motion);
            is_motion_attached = true;

            timeout_id = GLib.Timeout.add (16, poll);
        }

        public void stop () {
            stop_button_repeat ();

            if (timeout_id != 0) {
                GLib.Source.remove (timeout_id);
                timeout_id = 0;
            }

            if (is_motion_attached)
                ((Gtk.Widget) window).remove_controller (motion);

            is_motion_attached = false;
            reset_stick_state ();
            close_gamepads ();
            dialogs.clear ();
            deactivate_controller_mode ();

            if (sdl_initialized) {
                SDL.Init.quit_subsystem (SDL.Init.InitFlags.GAMEPAD);
                sdl_initialized = false;
            }
        }

        public void register_dialog (Adw.Dialog dialog) {
            if (!dialogs.contains (dialog)) {
                dialog.closed.connect (() => unregister_dialog (dialog));
            } else {
                dialogs.remove (dialog);
            }

            dialogs.add (dialog);
            clear_highlight ();
        }

        void unregister_dialog (Adw.Dialog dialog) {
            if (dialogs.remove (dialog))
                clear_highlight ();
        }

        bool poll () {
            SDL.Events.Event event;
            while (SDL.Events.poll_event (out event)) {
                switch (event.type) {
                case SDL.Events.EventType.GAMEPAD_ADDED :
                    open_gamepad (event.gdevice.which);
                    break;
                case SDL.Events.EventType.GAMEPAD_REMOVED :
                    close_gamepad (event.gdevice.which);
                    break;
                case SDL.Events.EventType.GAMEPAD_BUTTON_DOWN :
                    if (window.is_active)
                        handle_button_down (event.gbutton.which, event.gbutton.button);
                    break;
                case SDL.Events.EventType.GAMEPAD_BUTTON_UP :
                    handle_button_up (event.gbutton.which, event.gbutton.button);
                    break;
                case SDL.Events.EventType.GAMEPAD_AXIS_MOTION :
                    if (window.is_active)
                        handle_axis (event.gaxis.which, event.gaxis.axis, event.gaxis.value);
                    break;
                default :
                    break;
                }
            }

            if (!window.is_active) {
                reset_stick_state ();
                return GLib.Source.CONTINUE;
            }

            var stick_y = get_scroll_stick_y ();
            if (stick_y != 0)
                scroll (stick_y * SCROLL_SPEED);

            return GLib.Source.CONTINUE;
        }

        void open_gamepad (SDL.Joystick.JoystickID id) {
            if (find_gamepad (id) != null)
                return;

            var gamepad = SDL.Gamepad.open_gamepad (id);
            if (gamepad == null) {
                warning ("Unable to open gamepad: %s", SDL.Error.get_error ());
                return;
            }

            gamepads.add (new GamepadState (id, gamepad));
        }

        void close_gamepad (SDL.Joystick.JoystickID id) {
            var state = find_gamepad (id);
            if (state == null)
                return;

            if (repeating_gamepad == state)
                stop_button_repeat ();

            gamepads.remove (state);
            SDL.Gamepad.close_gamepad (state.gamepad);
        }

        void close_gamepads () {
            foreach (var state in gamepads)
                SDL.Gamepad.close_gamepad (state.gamepad);

            gamepads.clear ();
        }

        GamepadState? find_gamepad (SDL.Joystick.JoystickID id) {
            foreach (var state in gamepads) {
                if (state.id == id)
                    return state;
            }

            return null;
        }

        void activate_controller_mode () {
            if (!controller_active) {
                controller_active = true;
                window.add_css_class ("controller-active");
            }
            update_highlight (get_focused_widget ());
        }

        void deactivate_controller_mode () {
            if (!controller_active)
                return;

            controller_active = false;
            window.remove_css_class ("controller-active");
            clear_highlight ();
        }

        void update_highlight (Gtk.Widget? widget) {
            if (highlighted == widget)
                return;

            clear_highlight ();
            highlighted = widget;
            highlighted?.add_css_class ("controller-focus");
        }

        void clear_highlight () {
            highlighted?.remove_css_class ("controller-focus");

            highlighted = null;
        }

        void handle_button_down (SDL.Joystick.JoystickID id, SDL.Gamepad.GamepadButton button) {
            var gamepad = find_gamepad (id);
            if (gamepad == null)
                return;

            activate_controller_mode ();
            switch (button) {
            case DPAD_UP :
            case DPAD_DOWN :
            case DPAD_LEFT :
            case DPAD_RIGHT :
                move_focus (button);
                start_button_repeat (gamepad, button);
                break;
            case SOUTH :
                activate_focused ();
                break;
            case EAST :
                if (!dismiss_popup ())
                    dismiss_dialog ();
                break;
            case START :
                if (get_active_dialog () == null)
                    window.open_menu ();
                break;
            case BACK :
                if (get_active_dialog () == null)
                    window.open_launchers ();
                break;
            case LEFT_SHOULDER :
                switch_tab (-1);
                break;
            case RIGHT_SHOULDER :
                switch_tab (1);
                break;
            default :
                break;
            }
            update_highlight (get_focused_widget ());
        }

        void handle_button_up (SDL.Joystick.JoystickID id, SDL.Gamepad.GamepadButton button) {
            if (repeating_gamepad != null && repeating_gamepad.id == id && repeating_button == button)
                stop_button_repeat ();
        }

        void start_button_repeat (GamepadState gamepad, SDL.Gamepad.GamepadButton button) {
            stop_button_repeat ();
            repeating_gamepad = gamepad;
            repeating_button = button;
            repeat_timeout_id = GLib.Timeout.add (INITIAL_REPEAT_DELAY, () => {
                if (!can_repeat_button ()) {
                    clear_button_repeat_state ();
                    return GLib.Source.REMOVE;
                }

                move_focus (repeating_button);
                update_highlight (get_focused_widget ());
                repeat_timeout_id = GLib.Timeout.add (REPEAT_INTERVAL, () => {
                    if (!can_repeat_button ()) {
                        clear_button_repeat_state ();
                        return GLib.Source.REMOVE;
                    }

                    move_focus (repeating_button);
                    update_highlight (get_focused_widget ());
                    return GLib.Source.CONTINUE;
                });
                return GLib.Source.REMOVE;
            });
        }

        bool can_repeat_button () {
            return window.is_active && repeating_gamepad != null && gamepads.contains (repeating_gamepad);
        }

        void stop_button_repeat () {
            if (repeat_timeout_id != 0)
                GLib.Source.remove (repeat_timeout_id);

            clear_button_repeat_state ();
        }

        void clear_button_repeat_state () {
            repeat_timeout_id = 0;
            repeating_gamepad = null;
            repeating_button = SDL.Gamepad.GamepadButton.INVALID;
        }

        void move_focus (SDL.Gamepad.GamepadButton button) {
            var root = get_input_root ();
            switch (button) {
            case DPAD_UP :
                if (!root.child_focus (Gtk.DirectionType.UP))
                    root.child_focus (Gtk.DirectionType.TAB_BACKWARD);
                break;
            case DPAD_DOWN :
                if (!root.child_focus (Gtk.DirectionType.DOWN))
                    root.child_focus (Gtk.DirectionType.TAB_FORWARD);
                break;
            case DPAD_LEFT :
                root.child_focus (Gtk.DirectionType.LEFT);
                break;
            case DPAD_RIGHT :
                root.child_focus (Gtk.DirectionType.RIGHT);
                break;
            default :
                break;
            }
        }

        void handle_axis (SDL.Joystick.JoystickID id, SDL.Gamepad.GamepadAxis axis, int16 raw) {
            if (axis != SDL.Gamepad.GamepadAxis.LEFTY)
                return;

            var gamepad = find_gamepad (id);
            if (gamepad == null)
                return;

            double value = raw / 32767.0;
            if (value > 1)
                value = 1;
            else if (value < -1)
                value = -1;

            gamepad.stick_y = Math.fabs (value) > DEADZONE ? value : 0;
            if (gamepad.stick_y != 0)
                activate_controller_mode ();
        }

        double get_scroll_stick_y () {
            double value = 0;
            foreach (var gamepad in gamepads) {
                if (Math.fabs (gamepad.stick_y) > Math.fabs (value))
                    value = gamepad.stick_y;
            }

            return value;
        }

        void reset_stick_state () {
            foreach (var gamepad in gamepads)
                gamepad.stick_y = 0;

            stop_button_repeat ();
        }

        Gtk.Widget get_input_root () {
            var dialog = get_active_dialog ();
            if (dialog != null)
                return dialog;

            return window;
        }

        Gtk.Widget? get_focused_widget () {
            var dialog = get_active_dialog ();
            if (dialog != null)
                return dialog.get_focus ();

            return window.get_focus ();
        }

        Adw.Dialog? get_active_dialog () {
            if (dialogs.size == 0)
                return null;

            return dialogs.get (dialogs.size - 1);
        }

        void activate_focused () {
            var focused = get_focused_widget ();
            if (focused != null)
                focused.activate ();
        }

        void scroll (double delta) {
            Gtk.Widget? widget = get_focused_widget ();
            if (widget == null)
                widget = get_input_root ();

            while (widget != null) {
                if (widget is Gtk.ScrolledWindow) {
                    var adjustment = ((Gtk.ScrolledWindow) widget).get_vadjustment ();
                    var maximum = adjustment.upper - adjustment.page_size;
                    if (maximum < adjustment.lower)
                        maximum = adjustment.lower;

                    var target = adjustment.value + delta;
                    if (target < adjustment.lower)
                        target = adjustment.lower;
                    if (target > maximum)
                        target = maximum;

                    adjustment.set_value (target);
                    return;
                }
                widget = widget.get_parent ();
            }
        }

        bool dismiss_popup () {
            Gtk.Widget? widget = get_focused_widget ();
            if (widget == null)
                widget = get_input_root ();

            while (widget != null) {
                if (widget is Gtk.Popover) {
                    ((Gtk.Popover) widget).popdown ();
                    return true;
                }
                widget = widget.get_parent ();
            }
            return false;
        }

        void dismiss_dialog () {
            var dialog = get_active_dialog ();
            if (dialog != null)
                dialog.close ();
        }

        void switch_tab (int delta) {
            var dialog = get_active_dialog ();
            if (dialog != null) {
                var preferences = dialog as Widgets.Preferences.PreferencesDialog;
                if (preferences != null)
                    preferences.switch_page (delta);
                return;
            }

            var model = window.main_box.view_stack.pages;
            int count = (int) model.get_n_items ();
            if (count == 0)
                return;

            string? current = window.main_box.view_stack.visible_child_name;
            int current_index = 0;
            for (int i = 0; i < count; i++) {
                var page = (Adw.ViewStackPage) model.get_item ((uint) i);
                if (page.name == current) {
                    current_index = i;
                    break;
                }
            }

            for (int step = 1; step <= count; step++) {
                int index = ((current_index + delta * step) % count + count) % count;
                var page = (Adw.ViewStackPage) model.get_item ((uint) index);
                if (page.visible) {
                    window.main_box.view_stack.visible_child_name = page.name;
                    break;
                }
            }
        }
    }
}

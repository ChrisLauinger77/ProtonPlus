namespace ProtonPlus.Utils {
    public class ControllerManager : Object {
        Widgets.Window window;
        uint timeout_id = 0;
        double stick_y = 0;
        bool controller_active = false;
        Gtk.Widget? highlighted = null;
        Adw.PreferencesDialog? active_prefs_dialog = null;
        Adw.PreferencesPage[] ? prefs_pages = null;
        Gtk.EventControllerMotion? motion = null;

        bool is_motion_attached = false;

        const double DEADZONE = 0.25;
        const double SCROLL_SPEED = 12.0;

        public ControllerManager (Widgets.Window window) {
            this.window = window;

            motion = new Gtk.EventControllerMotion ();
            motion.motion.connect ((x, y) => deactivate_controller_mode ());

            start ();
        }

        public void start () {
            if (timeout_id != 0)
                return;

            SDL.Hints.set_hint (SDL.Hints.JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");

            if (!SDL.Init.init (SDL.Init.InitFlags.GAMEPAD)) {
                warning ("SDL3 gamepad init FAILED: %s", SDL.Error.get_error ());
                return;
            }

            var ids = SDL.Gamepad.get_gamepads ();
            if (ids != null) {
                foreach (var id in ids)
                    SDL.Gamepad.open_gamepad (id);
            } else {
                warning ("No gamepads found at init");
            }

            ((Gtk.Widget) window).add_controller (motion);
            is_motion_attached = true;

            timeout_id = GLib.Timeout.add (16, poll);
        }

        public void stop () {
            if (timeout_id != 0 && !is_motion_attached) {
                GLib.Source.remove (timeout_id);
                timeout_id = 0;
            }
            if (is_motion_attached && window != null && ((Gtk.Widget) window).get_root () != null) {
                ((Gtk.Widget) window).remove_controller (motion);
            }
            is_motion_attached = false;
            deactivate_controller_mode ();
            active_prefs_dialog = null;
            prefs_pages = null;

            SDL.Init.quit_subsystem (SDL.Init.InitFlags.GAMEPAD);
        }

        public void set_preferences_dialog (Adw.PreferencesDialog? dialog, Adw.PreferencesPage[]? pages) {
            active_prefs_dialog = dialog;
            prefs_pages = pages;
            if (dialog == null) {
                clear_highlight ();
            }
        }

        bool poll () {
            SDL.Events.Event event;
            while (SDL.Events.poll_event (out event)) {
                switch (event.type) {
                case SDL.Events.EventType.GAMEPAD_ADDED :
                    SDL.Gamepad.open_gamepad (event.gdevice.which);
                    break;
                case SDL.Events.EventType.GAMEPAD_BUTTON_DOWN :
                    handle_button (event.gbutton.button);
                    break;
                case SDL.Events.EventType.GAMEPAD_AXIS_MOTION :
                    handle_axis (event.gaxis.axis, event.gaxis.value);
                    break;
                    default :
                    break;
                }
            }

            if (stick_y != 0)
                scroll (stick_y * SCROLL_SPEED);

            return GLib.Source.CONTINUE;
        }

        void activate_controller_mode () {
            if (!controller_active) {
                controller_active = true;
                window.add_css_class ("controller-active");
            }
            update_highlight (window.get_focus ());
        }

        void deactivate_controller_mode () {
            if (!controller_active)return;
            controller_active = false;
            window.remove_css_class ("controller-active");
            clear_highlight ();
        }

        void update_highlight (Gtk.Widget? widget) {
            if (highlighted == widget)return;
            clear_highlight ();
            highlighted = widget;
            highlighted?.add_css_class ("controller-focus");
        }

        void clear_highlight () {
            highlighted?.remove_css_class ("controller-focus");

            highlighted = null;
        }

        void handle_button (SDL.Gamepad.GamepadButton button) {
            activate_controller_mode ();
            switch (button) {
            case DPAD_UP :
                if (is_inside_expander_row ())
                    window.child_focus (Gtk.DirectionType.TAB_BACKWARD);
                else
                    window.child_focus (Gtk.DirectionType.UP);
                break;
            case DPAD_DOWN :
                if (is_inside_expander_row ())
                    window.child_focus (Gtk.DirectionType.TAB_FORWARD);
                else
                    window.child_focus (Gtk.DirectionType.DOWN);
                break;
            case DPAD_LEFT :
                window.child_focus (Gtk.DirectionType.LEFT);
                break;
            case DPAD_RIGHT :
                window.child_focus (Gtk.DirectionType.RIGHT);
                break;
            case SOUTH :
                activate_focused ();
                break;
            case EAST:
                if (!dismiss_popup () && active_prefs_dialog != null)
                    active_prefs_dialog.close ();
                break;
            case START:
                // ((ProtonPlus.Widgets.Window) window).open_menu ();
                break;
            case BACK:
                // ((ProtonPlus.Widgets.Window) window).open_launchers ();
                break;
            case LEFT_SHOULDER:
                switch_tab (-1);
                break;
            case RIGHT_SHOULDER:
                switch_tab (1);
                break;
            default:
                break;
            }
            update_highlight (window.get_focus ());
        }

        void handle_axis (SDL.Gamepad.GamepadAxis axis, int16 raw) {
            if (axis != SDL.Gamepad.GamepadAxis.LEFTY)
                return;
            double v = raw / 32767.0;
            double new_y = Math.fabs (v) > DEADZONE ? v : 0;
            if (new_y != 0)activate_controller_mode ();
            stick_y = new_y;
        }

        void activate_focused () {
            var focused = window.get_focus ();
            if (focused != null)
                focused.activate ();
        }

        bool is_inside_expander_row () {
            Gtk.Widget? w = window.get_focus ();
            while (w != null) {
                if (w is Adw.ExpanderRow) {
                    return true;
                }
                w = w.get_parent ();
            }
            return false;
        }

        void scroll (double delta) {
            Gtk.Widget? w = window.get_focus ();
            while (w != null) {
                if (w is Gtk.ScrolledWindow) {
                    var adj = ((Gtk.ScrolledWindow) w).get_vadjustment ();
                    var target = adj.value + delta;
                    if (target < adj.lower)target = adj.lower;
                    if (target > adj.upper - adj.page_size)target = adj.upper - adj.page_size;
                    adj.set_value (target);
                    return;
                }
                w = w.get_parent ();
            }
        }

        bool dismiss_popup () {
            Gtk.Widget? w = window.get_focus ();
            while (w != null) {
                if (w is Gtk.Popover) {
                    ((Gtk.Popover) w).popdown ();
                    return true;
                }
                w = w.get_parent ();
            }
            return false;
        }

        void switch_tab (int delta) {
            if (active_prefs_dialog != null && prefs_pages != null && prefs_pages.length > 0) {
                int n = prefs_pages.length;
                var current = active_prefs_dialog.visible_page;
                int cur_idx = 0;
                for (int i = 0; i < n; i++) {
                    if (prefs_pages[i] == current) { cur_idx = i; break; }
                }
                int next_idx = ((cur_idx + delta) % n + n) % n;
                active_prefs_dialog.visible_page = prefs_pages[next_idx];
                return;
            }

            var model = window.main_box.view_stack.pages;
            int n = (int) model.get_n_items ();
            if (n == 0)return;

            string? current = window.main_box.view_stack.visible_child_name;
            int cur_idx = 0;
            for (int i = 0; i < n; i++) {
                var page = (Adw.ViewStackPage) model.get_item ((uint) i);
                if (page.name == current) {
                    cur_idx = i;
                    break;
                }
            }

            for (int step = 1; step <= n; step++) {
                int idx = ((cur_idx + delta * step) % n + n) % n;
                var page = (Adw.ViewStackPage) model.get_item ((uint) idx);
                if (page.visible) {
                    window.main_box.view_stack.visible_child_name = page.name;
                    break;
                }
            }
        }
    }
}

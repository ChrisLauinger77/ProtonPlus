namespace ProtonPlus.Widgets.Introduction {
    using Adw;
    using Gtk;

    class Controller : Base {
        public Controller () {
            base (
                _("Controller support"),
                _("Basic controller support is available for navigating ProtonPlus.\nMore controller functionality and improvements are planned for future updates."), // vala-lint=line-length
                "gamepad-symbolic"
            );
        }
    }
}

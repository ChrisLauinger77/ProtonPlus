namespace AppTests.FilesystemTest {
    using GLib;

    public void register_tests () {
        Test.add_func ("/filesystem/delete-nested-directory", test_delete_nested_directory);
        Test.add_func ("/filesystem/move-conflict-completes", test_move_conflict_completes);
    }

    private string create_temp_directory () {
        try {
            return DirUtils.make_tmp ("protonplus-filesystem-test-XXXXXX");
        } catch (FileError e) {
            critical ("Could not create test directory: %s", e.message);
            assert_not_reached ();
        }
    }

    private bool delete_directory (string path) {
        var loop = new MainLoop ();
        bool deleted = false;

        ProtonPlus.Utils.Filesystem.delete_directory.begin (path, (obj, result) => {
            assert (obj == null);
            deleted = ProtonPlus.Utils.Filesystem.delete_directory.end (result);
            loop.quit ();
        });
        loop.run ();

        return deleted;
    }

    private void test_delete_nested_directory () {
        var root = create_temp_directory ();
        var nested = Path.build_filename (root, "first", "second");
        assert (ProtonPlus.Utils.Filesystem.create_directory (nested));

        var file_path = Path.build_filename (nested, "content.txt");
        ProtonPlus.Utils.Filesystem.create_file (file_path, "test content");
        assert (FileUtils.test (file_path, FileTest.IS_REGULAR));

        assert (delete_directory (root));
        assert (!FileUtils.test (root, FileTest.EXISTS));
    }

    private void test_move_conflict_completes () {
        var root = create_temp_directory ();
        var source = Path.build_filename (root, "source");
        var target = Path.build_filename (root, "target");
        assert (ProtonPlus.Utils.Filesystem.create_directory (source));
        assert (ProtonPlus.Utils.Filesystem.create_directory (target));

        var source_file = Path.build_filename (source, "existing.txt");
        var target_file = Path.build_filename (target, "existing.txt");
        ProtonPlus.Utils.Filesystem.create_file (source_file, "source");
        ProtonPlus.Utils.Filesystem.create_file (target_file, "target");

        var loop = new MainLoop ();
        bool callback_completed = false;
        bool move_succeeded = true;
        var timeout_id = Timeout.add_seconds (5, () => {
            loop.quit ();
            return Source.REMOVE;
        });

        ProtonPlus.Utils.Filesystem.move_dir_contents.begin (source, target, (obj, result) => {
            assert (obj == null);
            move_succeeded = ProtonPlus.Utils.Filesystem.move_dir_contents.end (result);
            callback_completed = true;
            Source.remove (timeout_id);
            loop.quit ();
        });
        loop.run ();

        assert (callback_completed);
        assert (!move_succeeded);
        assert (ProtonPlus.Utils.Filesystem.get_file_content (source_file) == "source");
        assert (ProtonPlus.Utils.Filesystem.get_file_content (target_file) == "target");
        assert (delete_directory (root));
    }
}

namespace AppTests.MetadataTest {
    using GLib;

    public void register_tests () {
        Test.add_func ("/protonplus-metadata/saves-and-loads", test_saves_and_loads);
    }

    private string create_temp_directory () {
        try {
            return DirUtils.make_tmp ("protonplus-metadata-test-XXXXXX");
        } catch (FileError e) {
            critical ("Could not create test directory: %s", e.message);
            assert_not_reached ();
        }
    }

    private void test_saves_and_loads () {
        var directory = create_temp_directory ();
        var metadata = ProtonPlus.Utils.Metadata.load (directory);
        metadata.runner_endpoint = "https://example.test/releases";
        metadata.runner_title = "Example Runner";
        metadata.tag = "v1.2.3";

        assert (metadata.save (directory));
        assert (FileUtils.test (Path.build_filename (directory, ".protonplus"), FileTest.IS_REGULAR));

        var loaded_metadata = ProtonPlus.Utils.Metadata.load (directory);
        assert (loaded_metadata.runner_endpoint == "https://example.test/releases");
        assert (loaded_metadata.runner_title == "Example Runner");
        assert (loaded_metadata.tag == "v1.2.3");

        ProtonPlus.Utils.Filesystem.delete_file (Path.build_filename (directory, ".protonplus"));
        try {
            File.new_for_path (directory).delete (null);
        } catch (Error e) {
            critical ("Could not delete temporary directory: %s", e.message);
            assert_not_reached ();
        }
    }
}

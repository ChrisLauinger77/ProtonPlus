namespace AppTests.VdfBinaryTest {
    using GLib;

    public void register_tests () {
        Test.add_func ("/vdf-binary/parent-data-after-child", test_parent_data_after_child);
        Test.add_func ("/vdf-binary/similar-node-prefixes", test_similar_node_prefixes);
    }

    private string create_temp_file (out string root) throws FileError {
        root = DirUtils.make_tmp ("protonplus-vdf-test-XXXXXX");
        return Path.build_filename (root, "shortcuts.vdf");
    }

    private void write_cstring (DataOutputStream writer, string value) throws Error {
        writer.put_string (value);
        writer.put_byte ('\0');
    }

    private void remove_temp_file (string root, string path) {
        assert (FileUtils.remove (path) == 0);
        assert (DirUtils.remove (root) == 0);
    }

    private void test_parent_data_after_child () {
        string root;

        try {
            var path = create_temp_file (out root);
            var stream = File.new_for_path (path).create (FileCreateFlags.PRIVATE);
            var writer = new DataOutputStream (stream);
            writer.byte_order = DataStreamByteOrder.LITTLE_ENDIAN;

            writer.put_byte (0x00);
            write_cstring (writer, "root");
            writer.put_byte (0x01);
            write_cstring (writer, "before");
            write_cstring (writer, "first");
            writer.put_byte (0x00);
            write_cstring (writer, "child");
            writer.put_byte (0x01);
            write_cstring (writer, "value");
            write_cstring (writer, "nested");
            writer.put_byte (0x08);
            writer.put_byte (0x01);
            write_cstring (writer, "after");
            write_cstring (writer, "second");
            writer.put_byte (0x08);
            writer.put_byte (0x08);
            stream.close ();

            var binary = new ProtonPlus.Utils.VDF.Binary (path);
            assert (binary.nodes["root"]["before"].get_string () == "first");
            assert (binary.nodes["root"]["after"].get_string () == "second");
            assert (binary.nodes["root.child"]["value"].get_string () == "nested");

            remove_temp_file (root, path);
        } catch (Error e) {
            critical ("Could not exercise binary VDF parsing: %s", e.message);
            assert_not_reached ();
        }
    }

    private void test_similar_node_prefixes () {
        string root;

        try {
            var path = create_temp_file (out root);
            var stream = File.new_for_path (path).create (FileCreateFlags.PRIVATE);
            var writer = new DataOutputStream (stream);
            writer.put_byte (0x08);
            stream.close ();

            var binary = new ProtonPlus.Utils.VDF.Binary (path);
            var foo = new ProtonPlus.Utils.VDF.Node ("foo");
            var foobar = new ProtonPlus.Utils.VDF.Node ("foobar");
            var foobar_child = new ProtonPlus.Utils.VDF.Node ("foobar.child");
            foo["value"] = new Variant.string ("foo");
            foobar["value"] = new Variant.string ("foobar");
            foobar_child["value"] = new Variant.string ("child");
            binary.nodes["foo"] = foo;
            binary.nodes["foobar"] = foobar;
            binary.nodes["foobar.child"] = foobar_child;
            binary.save ();

            var reloaded = new ProtonPlus.Utils.VDF.Binary (path);
            assert (reloaded.nodes.has_key ("foo"));
            assert (!reloaded.nodes.has_key ("foo.child"));
            assert (reloaded.nodes.has_key ("foobar.child"));

            remove_temp_file (root, path);
        } catch (Error e) {
            critical ("Could not exercise binary VDF serialization: %s", e.message);
            assert_not_reached ();
        }
    }
}

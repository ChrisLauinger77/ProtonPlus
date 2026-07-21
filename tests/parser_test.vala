namespace AppTests.ParserTest {
    using GLib;

    public void register_tests () {
        Test.add_func ("/parser/length-aware-byte-conversion", test_length_aware_byte_conversion);
    }

    private void test_length_aware_byte_conversion () {
        uint8 data[4];
        data[0] = 't';
        data[1] = 'e';
        data[2] = 's';
        data[3] = 't';

        assert (ProtonPlus.Utils.Parser.data_to_string (data) == "test");
    }
}

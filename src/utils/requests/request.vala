namespace ProtonPlus.Utils.Requests {
    public class Request : Object {
        private Soup.Message message;
        private Soup.Session session;

        public Request (string uri, string method = "GET") {
            message = new Soup.Message (method, uri);
            session = Proxy.session;
        }

        public async ReturnCode send (out string? response) {
            response = null;

            try {
                Bytes bytes = yield session.send_and_read_async (message, Priority.DEFAULT, null);

                response = Parser.data_to_string (bytes.get_data ());

                if (response == null)
                    return ReturnCode.UNKNOWN_ERROR;

                return ReturnCode.VALID_REQUEST;
            } catch (Error e) {
                if (e is Soup.SessionError.PARSING ||
                    e.message.contains ("TLS handshake") ||
                    e.message.contains ("TLS connection")) {
                    return ReturnCode.TLS_HANDSHAKE_ERROR;
                }

                if (e.message.contains ("Temporary failure in name resolution"))
                    return ReturnCode.CONNECTION_ISSUE;

                if (e.message.contains ("Connection refused"))
                    return ReturnCode.CONNECTION_REFUSED;

                if (e.message.contains ("Name or service not known"))
                    return ReturnCode.CONNECTION_UNKNOWN;

                warning (e.message);
                return ReturnCode.UNKNOWN_ERROR;
            }
        }
    }
}

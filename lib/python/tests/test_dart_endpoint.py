from python.dart_endpoint import main
from mock import patch, MagicMock

@patch("python.dart_endpoint.fileinput.input")
class TestDartEndpoint:
    def test_startup(self, mock_input: MagicMock):
        mock_input.side_effect = ["startup{}", "Exit"]

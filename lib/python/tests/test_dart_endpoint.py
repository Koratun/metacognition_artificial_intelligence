from pydantic import BaseModel, ValidationError
from uuid import uuid4
from python.dart_endpoint import main, format_response
from python.schemas import ResponseType, Command, CreateLayer
from python.layers.input import Input
from python.layers import layer_packages
from mock import patch, MagicMock


@patch("python.dart_endpoint.fileinput.input")
@patch("python.dart_endpoint.write_back")
class TestDartEndpoint:
    def request_and_response(
            self, 
            mock_response: MagicMock, 
            mock_input: MagicMock, 
            request: str, 
            response: str = None, 
            validation_scheme: BaseModel = None,
            error=False
        ):
        mock_input.return_value = [request]
        main()
        if error:
            assert mock_response.call_args.kwargs['error']
        elif validation_scheme:
            try:
                validation_scheme.parse_raw(request[request.find('{'):])
                assert False
            except ValidationError as e:
                assert mock_response.call_args[0][0] == format_response(ResponseType.VALIDATION_ERROR, errors=e.errors())
        elif response:
            assert mock_response.call_args[0][0] == response
        else:
            print("This test was constructed incorrectly.")
            assert False


    def build_request(self, c: Command, model: BaseModel) -> str:
        return c.value + model.json(by_alias=True)
        

    def test_startup(self, mock_response: MagicMock, mock_input: MagicMock):
        self.request_and_response(
            mock_response,
            mock_input,
            "startup{}", 
            response=format_response(ResponseType.STARTUP, category_list=layer_packages)
        )

        self.request_and_response(
            mock_response,
            mock_input,
            "startup",
            error=True
        )


    def test_create_layer(self, mock_response: MagicMock, mock_input: MagicMock):
        # Test success state
        force_id = uuid4()
        with patch("python.directed_acyclic_graph.uuid4") as mock_id:
            mock_id.return_value = force_id
            layer = Input
            self.request_and_response(
                mock_response,
                mock_input,
                self.build_request(Command.CREATE, CreateLayer(layer="Input")),
                response=format_response(
                    ResponseType.CREATION,
                    node_id=force_id,
                    layer_settings=layer.get_settings_data_fields(),
                    node_connection_limits=dict(
                        min_upstream=layer.min_upstream_nodes,
                        max_upstream=layer.max_upstream_nodes,
                        min_downstream=layer.min_downstream_nodes,
                        max_downstream=layer.max_downstream_nodes,
                    )
                )
            )

        # Test error states
        self.request_and_response(
            mock_response,
            mock_input,
            "create{baaaaaaad request}",
            validation_scheme=CreateLayer
        )

        self.request_and_response(
            mock_response,
            mock_input,
            'create{"wrong_schema": null}',
            validation_scheme=CreateLayer
        )

        self.request_and_response(
            mock_response,
            mock_input,
            'create{"layer": "BadLayer"}',
            validation_scheme=CreateLayer
        )


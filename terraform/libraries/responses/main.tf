resource "aws_api_gateway_method_response" "method_response" {
	rest_api_id   = var.s_parent_id
	resource_id   = var.s_resource_id
	http_method   = var.s_http_method
	status_code   = var.s_status_code
	response_models = var.s_response_models
	response_parameters = {
		"method.response.header.Access-Control-Allow-Origin" = true
	}
}

resource "aws_api_gateway_integration_response" "integration_response" {
	rest_api_id   = aws_api_gateway_method_response.method_response.rest_api_id		
	resource_id   = aws_api_gateway_method_response.method_response.resource_id
	http_method   = aws_api_gateway_method_response.method_response.http_method		
	status_code   = aws_api_gateway_method_response.method_response.status_code		
	selection_pattern = var.s_selection_pattern
	response_parameters = {
		"method.response.header.Access-Control-Allow-Origin" = var.s_integration_allowed_origin
	}
	response_templates = var.s_integration_response_templates
}
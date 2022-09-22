
resource "aws_api_gateway_resource" "resource" {
    rest_api_id = var.api_resource_id
    parent_id   = var.api_parent_id
    path_part   = var.api_path_part
}

resource "random_string" "validator_name" {
    length = 16
}


resource "aws_api_gateway_request_validator" "request_validator" {
    name                        = "validator-${random_string.validator_name.result}"
    rest_api_id                 = aws_api_gateway_resource.resource.rest_api_id
    validate_request_body       = var.api_validate_req_body
    validate_request_parameters = var.api_validate_req_params
    depends_on                  = [aws_api_gateway_resource.resource]
}

resource "aws_api_gateway_method" "method" {
    rest_api_id          = aws_api_gateway_resource.resource.rest_api_id
    resource_id          = aws_api_gateway_resource.resource.id
    http_method          = var.api_http_method
    authorization        = var.api_authorization
    # authorizer_id        = var.api_authorization_id
    # authorization_scopes = var.api_authorization_scopes
    request_models       = var.api_req_models
    request_parameters   = var.api_req_params
    request_validator_id = aws_api_gateway_request_validator.request_validator.id
}

resource "aws_api_gateway_method_response" "method_response" {
    rest_api_id     = aws_api_gateway_resource.resource.rest_api_id
    resource_id     = aws_api_gateway_resource.resource.id
    http_method     = aws_api_gateway_method.method.http_method
    status_code     = "200"
    response_models = var.api_resp_models
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [aws_api_gateway_method.method]
}

resource "aws_api_gateway_integration" "integration" {
    rest_api_id             = aws_api_gateway_resource.resource.rest_api_id
    resource_id             = aws_api_gateway_resource.resource.id
    http_method             = aws_api_gateway_method.method.http_method
    integration_http_method = var.api_integration_http_method
    type                    = var.api_integration_type
    uri                     = var.api_integration_uri
    credentials             = var.api_integration_role
    request_templates       = var.api_req_templates
    passthrough_behavior    = var.api_passthrough_behavior
    request_parameters      = var.api_integration_req_params
    cache_key_parameters    = var.api_cache_key_params
}

resource "aws_api_gateway_integration_response" "integration_response" {
    rest_api_id = aws_api_gateway_resource.resource.rest_api_id
    resource_id = aws_api_gateway_resource.resource.id
    http_method = aws_api_gateway_method.method.http_method
    status_code = aws_api_gateway_method_response.method_response.status_code
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = var.api_integration_allowed_origin
    }
    depends_on         = [aws_api_gateway_integration.integration]
    response_templates = var.api_resp_templates
}

# OPTIONS method for CORS
resource "aws_api_gateway_method" "options_method" {
    rest_api_id   = aws_api_gateway_resource.resource.rest_api_id
    resource_id   = aws_api_gateway_resource.resource.id
    http_method   = "OPTIONS"
    authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_method_response" {
    rest_api_id = aws_api_gateway_resource.resource.rest_api_id
    resource_id = aws_api_gateway_resource.resource.id
    http_method = aws_api_gateway_method.options_method.http_method
    status_code = "200"
    response_models = {
        "application/json" = "Empty"
    }
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin"  = true
    }
    depends_on = [aws_api_gateway_method.options_method]
}

resource "aws_api_gateway_integration" "options_integration" {
    rest_api_id = aws_api_gateway_resource.resource.rest_api_id
    resource_id = aws_api_gateway_resource.resource.id
    http_method = aws_api_gateway_method.options_method.http_method
    type        = "MOCK"
    depends_on  = [aws_api_gateway_method.options_method]
    request_templates = {
        "application/json" = <<EOF
{
"statusCode": 200
}
EOF
    }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id = aws_api_gateway_resource.resource.rest_api_id
    resource_id = aws_api_gateway_resource.resource.id
    http_method = aws_api_gateway_method.options_method.http_method
    status_code = aws_api_gateway_method_response.options_method_response.status_code
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,duskorization'",
        "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
        "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    }
    response_templates = { "application/json" = "" }
    depends_on         = [aws_api_gateway_method_response.options_method_response]
}
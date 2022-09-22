/*
    Test 123
*/
terraform {
    backend "s3" {
        bucket = "seanezell-terraform-backend"
        key = "what2play-games/terraform.tfstate"
        region = "us-west-2"
        dynamodb_table = "terraform_state"
    }
}

resource "aws_api_gateway_rest_api" "api" {
    name = "GamesAPI"
	description = "Games API for What2Play"
}

resource "aws_cloudwatch_log_group" "api_cw" {
    name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${aws_api_gateway_stage.stage_settings.stage_name}"
    retention_in_days = 14
}

resource "aws_api_gateway_deployment" "apigw_deployment" {
	depends_on = [module.apigw_endpoints]
	rest_api_id = aws_api_gateway_rest_api.api.id
	description = "Deployed on ${timestamp()}"

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_api_gateway_stage" "stage_settings" {
	rest_api_id   = aws_api_gateway_rest_api.api.id
	deployment_id = aws_api_gateway_deployment.apigw_deployment.id
	stage_name    = "v1"
}

resource "aws_api_gateway_method_settings" "method_settings" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	stage_name  = aws_api_gateway_stage.stage_settings.stage_name
	method_path = "*/*"

	settings {
		metrics_enabled = true
		logging_level   = "INFO"
		data_trace_enabled = true
	}
}

resource "aws_api_gateway_base_path_mapping" "apigw-bpm" {
	api_id      = aws_api_gateway_rest_api.api.id
	domain_name = "api.seanezell.com"
	base_path = "games"
	stage_name = aws_api_gateway_stage.stage_settings.stage_name
}

resource "aws_api_gateway_gateway_response" "apigwgw-resp-validation" {
	rest_api_id   = aws_api_gateway_rest_api.api.id
	status_code   = "400"
	response_type = "BAD_REQUEST_BODY"

	response_templates = {
		"application/json" = "{\"message\": \"$context.error.validationErrorString\"}"
	}
}


//! Finish filling this out for /add. Turn it into a for_each 
//! Build Cognito Authorizers and add that here
//! Is the DDB table setup? Do that here?
//! Write some lambdas!
module "apigw_endpoints" {
	source = "./libraries/endpoints"

	api_resource_id = aws_api_gateway_rest_api.api.id
	api_parent_id = aws_api_gateway_rest_api.api.resource_id
	api_path_part = "add"
	api_req_models = ""
	api_integration_uri = ""
	api_integration_role = ""
	api_req_templates = ""
	api_resp_templates = ""
	api_validate_req_body = true

}
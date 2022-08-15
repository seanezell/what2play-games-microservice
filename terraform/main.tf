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
    name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${aws_api_gateway_stage.StageSettings.stage_name}"
    retention_in_days = 14
}

resource "aws_api_gateway_deployment" "apigw-deployment" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	description = "Deployed on ${timestamp()}"

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_api_gateway_stage" "StageSettings" {
	rest_api_id   = aws_api_gateway_rest_api.api.id
	deployment_id = aws_api_gateway_deployment.apigw-deployment.id
	stage_name    = "v1"
}

resource "aws_api_gateway_method_settings" "s" {
	rest_api_id = aws_api_gateway_rest_api.api.id
	stage_name  = aws_api_gateway_stage.StageSettings.stage_name
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
	stage_name = aws_api_gateway_stage.StageSettings.stage_name
}
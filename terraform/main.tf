/*
    Terraform to build What2Play Games API
	Sean Ezell
*/
terraform {
    backend "s3" {
        bucket = "seanezell-terraform-backend"
        key = "what2play-games/terraform.tfstate"
        region = "us-west-2"
        dynamodb_table = "terraform_state"
    }
}

/*
	PERMISSION THINGS
*/
data "aws_caller_identity" "current_identity" {}

data "aws_iam_policy_document" "policy_doc" {
    
    statement {
		sid = "CreateSelfLogGroup"
		effect = "Allow"
		actions = [
			"logs:CreateLogStream",
			"logs:DescribeLogGroups",
			"logs:DescribeLogStreams",
			"logs:PutLogEvents",
			"logs:GetLogEvents",
			"logs:FilterLogEvents",
			"logs:CreateLogDelivery",
			"logs:GetLogDelivery",
			"logs:UpdateLogDelivery",
			"logs:DeleteLogDelivery",
			"logs:ListLogDeliveries",
			"logs:PutResourcePolicy",
			"logs:DescribeResourcePolicies",
			"logs:DescribeLogGroups"
			]
		resources = ["*"]
    }

	statement {
		sid = "APIGWtoLambdaThatShouldNotReallyBeHere"
		effect = "Allow"
		actions = [
			"lambda:GetFunction",
            "lambda:InvokeFunction"
		]
		resources = [
			"arn:aws:lambda:us-west-2:${data.aws_caller_identity.current_identity.id}:function:*"
		]
	}
	statement {
		sid = "DDB"
		effect = "Allow"
		actions = [ 
			"dynamodb:PutItem", 
			"dynamodb:GetItem",  
			"dynamodb:DeleteItem"
		]
		resources = ["arn:aws:dynamodb:us-west-2:${data.aws_caller_identity.current_identity.id}:table/games"]
	}
}

module "iam" {
    source = "./libraries/iam"

    s_policy_name = "what2play_games_policy"
    s_role_name = "what2play_games_role"
    s_policy = data.aws_iam_policy_document.policy_doc.json
    s_services_list = ["apigateway.amazonaws.com", "lambda.amazonaws.com"]
}

resource "aws_dynamodb_table" "games_ddb" {
	name        	= "games"
	billing_mode 	= "PROVISIONED"
	read_capacity  = 5
	write_capacity = 5
	hash_key       = "game_name"
	point_in_time_recovery { 
		enabled = true 
	}
	attribute {
		name = "game_name"
		type = "S"
	}
}

/*
	LAMBDA THINGS
*/
data "archive_file" "lambdas" {
	for_each         = toset(var.lambdas)
	type             = "zip"
	source_dir      = "${path.module}/../lambda/${each.key}"
	output_file_mode = "0666"
	output_path      = "${path.module}/zip/${each.key}.zip"
}

resource "aws_lambda_function" "lambdas" {
	for_each = toset(var.lambdas)
	#filename 		= "${path.module}/zip/${each.key}.zip"
	filename 		= data.archive_file.lambdas["${each.key}"].output_path
	function_name 	= each.key
	role            = module.iam.output_roleid
    handler			= "index.handler"
	#source_code_hash= filebase64sha256("${path.module}/zip/${each.key}.zip")
	source_code_hash= data.archive_file.lambdas["${each.key}"].output_base64sha256
	timeout			= 30
	runtime			= "nodejs16.x"
	publish			= true
}

resource "aws_cloudwatch_log_group" "logs" {
	for_each = toset(var.lambdas)
    name = "/aws/lambda/${each.key}"
    retention_in_days = 14
}

/*
	APIGW THINGS
*/
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

	triggers = {
		redeployment = sha1(jsonencode([
			module.apigw_endpoints,
			aws_api_gateway_model.request_models
		])),
		redeployment = filesha1("${path.module}/schemas/add-schema.json")
	}

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

resource "aws_api_gateway_usage_plan" "apigw_usage_plan" {
	name = "what2play_gamesapi_usage_plan"
	api_stages {
		api_id = aws_api_gateway_rest_api.api.id
		stage  = aws_api_gateway_stage.stage_settings.stage_name
	}

	#   quota_settings {
	#     limit  = 20
	#     offset = 2
	#     period = "WEEK"
	#   }

	#   throttle_settings {
	#     burst_limit = 5
	#     rate_limit  = 10
	#   }
}

resource "aws_api_gateway_api_key" "apigw_api_key" {
	name = "What2Play_GamesAPI_Key"
}


resource "aws_api_gateway_usage_plan_key" "apigw_api_key_usageplan" {
	key_id        = aws_api_gateway_api_key.apigw_api_key.id
	key_type      = "API_KEY"
	usage_plan_id = aws_api_gateway_usage_plan.apigw_usage_plan.id
}

/*
	APIGW ENDPOINTS
*/
module "apigw_endpoints" {
	for_each = var.endpoints
	source = "./libraries/endpoints"

	s_api_resource_id = aws_api_gateway_rest_api.api.id
	s_api_parent_id = aws_api_gateway_rest_api.api.root_resource_id
	s_api_path_part = each.key
	s_api_req_models = { "application/json" = aws_api_gateway_model.request_models["${each.key}"].name }
	s_api_integration_uri = aws_lambda_function.lambdas["${each.value.uri}"].invoke_arn
	s_api_integration_role = module.iam.output_roleid
	s_api_req_templates = { "application/json" = file("${path.module}/mapping-templates/${each.value.request_mapping}.vtl") }
	s_api_resp_templates = each.value.response_mapping != "" ? { "application/json" = file("${path.module}/mapping-templates/${each.value.response_mapping}.vtl") } : null
	s_api_validate_req_body = true
}

resource "aws_api_gateway_model" "request_models" {
	for_each = var.endpoints
	rest_api_id  = aws_api_gateway_rest_api.api.id
	name         = "${each.key}Model"
	description  = "request payload for ${each.key}"
	content_type = "application/json"
	schema = file("${path.module}/schemas/${each.value.request_schema}.json")
}

module "responses400" {
	for_each = var.endpoints
	source = "./libraries/responses"

	depends_on = [module.apigw_endpoints]
	s_parent_id = aws_api_gateway_rest_api.api.id
	s_resource_id = module.apigw_endpoints["${each.key}"].output_apigw_resource_id
	s_http_method = module.apigw_endpoints["${each.key}"].output_apigw_http_method
	s_status_code = "400"
	s_selection_pattern = ".*statusCode.*400.*"
	s_integration_response_templates = { "application/json" = file("${path.module}/mapping-templates/responses-errors.vtl") }
}

module "responses500" {
	for_each = var.endpoints
	source = "./libraries/responses"

	depends_on = [module.apigw_endpoints]
	s_parent_id = aws_api_gateway_rest_api.api.id
	s_resource_id = module.apigw_endpoints["${each.key}"].output_apigw_resource_id
	s_http_method = module.apigw_endpoints["${each.key}"].output_apigw_http_method
	s_status_code = "500"
	s_selection_pattern = ".*statusCode.*500.*"
	s_integration_response_templates = { "application/json" = file("${path.module}/mapping-templates/responses-errors.vtl") }
}
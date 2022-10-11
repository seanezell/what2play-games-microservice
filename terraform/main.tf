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

	# statement {
	# 	sid = "APIGWtoLambdaThatShouldNotReallyBeHere"
	# 	effect = "Allow"
	# 	actions = [
	# 		"lambda:GetFunction",
    #         "lambda:InvokeFunction"
	# 	]
	# 	resources = [
	# 		"arn:aws:lambda:us-west-2:${data.aws_caller_identity.current.id}:function:*"
	# 	]
	# }
}

resource "aws_iam_policy" "policy" {
    name = "what2play_games_policy"
    path = "/" 
    policy = data.aws_iam_policy_document.policy_doc.json
}

data "aws_iam_policy_document" "assume_role_policy" {
    statement {
		actions = ["sts:AssumeRole"]
		effect = "Allow"
		principals {
			identifiers = ["apigateway.amazonaws.com", "lambda.amazonaws.com"]
			type = "Service"
		}
	}
}

resource "aws_iam_role" "role" {
    name = "what2play_games_role"
    assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
    force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "name" {
    role = aws_iam_role.role.name
    policy_arn = aws_iam_policy.policy.arn
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
	filename 		= "${path.module}/zip/${each.key}.zip"
	function_name 	= each.key
	role            = aws_iam_role.role.arn
    handler			= "index.handler"
	source_code_hash= filebase64sha256("${path.module}/zip/${each.key}.zip")
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
	api_parent_id = aws_api_gateway_rest_api.api.root_resource_id
	api_path_part = "add"
	#api_req_models = ""
	api_integration_uri = aws_lambda_function.lambdas["add-games"].invoke_arn
	api_integration_role = aws_iam_role.role.arn
	#api_req_templates = ""
	#api_resp_templates = ""
	api_validate_req_body = true

}
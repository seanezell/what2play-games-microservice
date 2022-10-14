resource "aws_iam_policy" "policy" {
    name = var.s_policy_name
    path = "/" 
    policy = var.s_policy
}

data "aws_iam_policy_document" "assume_role_policy" {
    statement {
		actions = ["sts:AssumeRole"]
		effect = "Allow"
		principals {
			identifiers = var.s_services_list
			type = "Service"
		}
	}
}

resource "aws_iam_role" "role" {
    name = var.s_role_name
    assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
    force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "name" {
    role = aws_iam_role.role.name
    policy_arn = aws_iam_policy.policy.arn
}
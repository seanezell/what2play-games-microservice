variable "lambdas" {
	description = "List of Lambda functions to create"
	type        = list(string)
}

variable "endpoints" {
	description = "list of endpoints"
	type = map(any)
}
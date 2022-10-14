variable "s_api_resource_id" {
    description = "API resource id"
    type        = string
}

variable "s_api_parent_id" {
    description = "API root resource id"
    type        = string
}

variable "s_api_path_part" {
    description = "API path for the resource"
    type        = string
}

variable "s_api_http_method" {
    description = "HTTP method for the resource"
    type        = string
    default     = "POST"
}

variable "s_api_authorization" {
    description = "Authorization model for the resource"
    type        = string
    default     = "NONE"
}

# variable "s_api_authorization_id" {
#     description = "Authorizer ID"
#     type        = string
# }

# variable "s_api_authorization_scopes" {
#     description = "authorization scopes"
#     type        = list(any)
# }

variable "s_api_req_models" {
    description = "Request model for the resource"
    type        = map(any)
    default     = { "application/json" = "Empty" }
}

variable "s_api_integration_http_method" {
    description = "HTTP method for the integration"
    type        = string
    default     = "POST"
}

variable "s_api_integration_type" {
    description = "API integration type. Lambda, HTTP, Mock, AWS, VPC"
    type        = string
    default     = "AWS"
}

variable "s_api_integration_uri" {
    description = "URL for the resource"
    type        = string
}

variable "s_api_integration_role" {
    description = "Role ARN for the resource"
    type        = string
}

variable "s_api_req_templates" {
    description = "Request template for the resource"
    type        = map(any)
    default     = { "application/json" = "Empty" }
}

variable "s_api_resp_templates" {
    description = "Response template for the resource"
    type        = map(any)
    default     = { "application/json" = "Empty" }
}

variable "s_api_passthrough_behavior" {
    description = "Passthrough behavior for the resource. Options are WHEN_NO_MATCH, WHEN_NO_TEMPLATES, NEVER"
    type        = string
    default     = "NEVER"
}

variable "s_api_integration_allowed_origin" {
    description = "Allowed origin for Access-Control-Allow-Origin header."
    type        = string
    default     = "'*'"
}

variable "s_api_req_params" {
    description = "list of request parameters"
    type        = map(any)
    default     = {}
}

variable "s_api_integration_req_params" {
    description = "list of request parameters"
    type        = map(any)
    default     = {}
}

variable "s_api_resp_models" {
    description = "Response model for the resource"
    type        = map(any)
    default     = {}
}

variable "s_api_cache_key_params" {
    description = "Cache key parameters"
    type        = list(any)
    default     = []
}

variable "s_api_validate_req_body" {
    description = "boolean to validate the request body (POST)"
    type        = bool
    default     = false
}

variable "s_api_validate_req_params" {
    description = "boolean to validate the request params (GET)"
    type        = bool
    default     = false
}
variable "api_resource_id" {
    description = "API resource id"
    type        = string
}

variable "api_parent_id" {
    description = "API root resource id"
    type        = string
}

variable "api_path_part" {
    description = "API path for the resource"
    type        = string
}

variable "api_http_method" {
    description = "HTTP method for the resource"
    type        = string
    default     = "POST"
}

variable "api_authorization" {
    description = "Authorization model for the resource"
    type        = string
    default     = "NONE"
}

# variable "api_authorization_id" {
#     description = "Authorizer ID"
#     type        = string
# }

# variable "api_authorization_scopes" {
#     description = "authorization scopes"
#     type        = list(any)
# }

variable "api_req_models" {
    description = "Request model for the resource"
    type        = map(any)
    default     = { "application/json" = "Empty" }
}

variable "api_integration_http_method" {
    description = "HTTP method for the integration"
    type        = string
    default     = "POST"
}

variable "api_integration_type" {
    description = "API integration type. Lambda, HTTP, Mock, AWS, VPC"
    type        = string
    default     = "AWS"
}

variable "api_integration_uri" {
    description = "URL for the resource"
    type        = string
}

variable "api_integration_role" {
    description = "Role ARN for the resource"
    type        = string
}

variable "api_req_templates" {
    description = "Request template for the resource"
    type        = map(any)
    default     = { "application/json" = "Empty" }
}

variable "api_resp_templates" {
    description = "Response template for the resource"
    type        = map(any)
    default     = { "application/json" = "Empty" }
}

variable "api_passthrough_behavior" {
    description = "Passthrough behavior for the resource. Options are WHEN_NO_MATCH, WHEN_NO_TEMPLATES, NEVER"
    type        = string
    default     = "NEVER"
}

variable "api_integration_allowed_origin" {
    description = "Allowed origin for Access-Control-Allow-Origin header."
    type        = string
    default     = "'*'"
}

variable "api_req_params" {
    description = "list of request parameters"
    type        = map(any)
    default     = {}
}

variable "api_integration_req_params" {
    description = "list of request parameters"
    type        = map(any)
    default     = {}
}

variable "api_resp_models" {
    description = "Response model for the resource"
    type        = map(any)
    default     = {}
}

variable "api_cache_key_params" {
    description = "Cache key parameters"
    type        = list(any)
    default     = []
}

variable "api_validate_req_body" {
    description = "boolean to validate the request body (POST)"
    type        = bool
    default     = false
}

variable "api_validate_req_params" {
    description = "boolean to validate the request params (GET)"
    type        = bool
    default     = false
}
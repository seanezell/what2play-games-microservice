variable "s_status_code" {
    description = "Status code for resource"
    type        = string
    default     = "200"
}

variable "s_response_models" {
    description = "Response model for method"
    type        = map(any)
    default     = { "application/json" = "Empty" }
}

variable "s_integration_allowed_origin" {
    description = "Allowed origin for Access-Control-Allow-Origin header."
    type        = string
    default     = "'*'"
}

variable "s_integration_response_templates" {
    description = "Response templates for method"
    type        = map(any)
    default     = { "application/json" = "" }
}

variable "s_parent_id" {
    description = "Rest API ID"
    type        = string
}

variable "s_resource_id" {
    description = "API Resource ID"
    type        = string
}

variable "s_http_method" {
    description = "API Response HTTP Method"
    type        = string
}

variable "s_selection_pattern" {
    description = "Response Regex for pattern matching the response mapping"
    type        = string
    default     = ""
}
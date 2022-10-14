variable "s_policy_name" {
    description = "Gives a Name to the policy"
    type = string
}

variable "s_role_name" {
    description = "Gives a Name to the IAM Role"
    type = string
}

variable "s_policy" {
    description = "the path to the JSON policy document used to build the policy"

}

variable "s_services_list" {
    description = "List of services for the role to assume"
    default = []
    type = list
}
variable "business" {
  description = "Specify the buisness name"
  type        = string
}

variable "env" {
  description = "Specify the environment for the resource"
  type        = string
}

variable "location" {
  description = "Azure region where the resource group should be created"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to the resource group"
  type        = map(string)
}





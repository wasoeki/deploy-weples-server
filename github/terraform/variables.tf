variable "github_token" {
  description = "The GitHub Personal Access Token."
  type        = string
  sensitive   = true
}

variable "repository_name" {
  description = "The name of the GitHub repository."
  type        = string
  default     = "deploy-weples-server"
}

variable "repository_owner" {
  description = "The owner of the GitHub repository."
  type        = string
  default     = "wasoeki"
}

variable "repository_description" {
  description = "A description for the GitHub repository"
  type        = string
  default     = "Managed by Terraform: deploy-weples-server"
}

variable "visibility" {
  description = "The visibility of the GitHub repository (public or private)."
  type        = string
  default     = "public"
}

# Variable to store the list of collaborators with their respective permissions
variable "collaborators" {
  type = map(string)
  description = "A map of collaborators where the key is the GitHub username and the value is the permission level"
  default     = {}
}
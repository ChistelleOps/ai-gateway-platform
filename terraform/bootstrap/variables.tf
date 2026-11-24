variable "region" {
  description = " AWS region for the state bucket"
  type        = string
  default     = "us-east-1"
}
variable "project" {
  description = "Project name used in the resource name"
  type        = string
  default     = "ai-gateway"
}
variable "budget_alert_emails" {
  description = "emails used for the budget alert"
  type        = list(string)
}

variable "active_color" {
  description = "Which environment is active: blue or green"
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_color)
    error_message = "active_color must be either 'blue' or 'green'."
  }
}

variable "server_list" {
  description = "List of servers that require a pvc, with a value for how much storage they require"
  type        = map(string)
}

variable "server_name" {
  description = "Name of server/network, used in various locations"
  type        = string
}
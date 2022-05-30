variable "luckperms_enabled" {
  description = "If a luckperms database will need to be created, currently only created when a paper server is stood up"
  type        = bool
}

variable "server_list" {
  description = "List of servers that require a pvc, with a value for how much storage they require"
  type        = map(string)
}

variable "namespace" {
  description = "Name of server/network, used in various locations"
  type        = string
}

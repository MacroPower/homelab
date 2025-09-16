variable "doppler_hel_token" {
  type      = string
  sensitive = true
}

variable "public_keys_openssh" {
  type    = map(string)
  default = {}
}

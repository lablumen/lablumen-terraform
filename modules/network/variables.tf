variable "name" { type = string }
variable "cidr" { type = string }
variable "azs" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "database_subnets" {
  type        = list(string)
  description = "CIDR blocks for isolated DB-tier subnets (no NAT/IGW route). One per AZ."
}
variable "cluster_name" { type = string }
variable "tags" { type = map(string) }

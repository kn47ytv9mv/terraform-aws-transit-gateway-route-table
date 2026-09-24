variable "transit_gateway_id" {
  default     = null
  description = "The ID of the transit gateway this route table belongs to."
}

variable "associations" {
  default     = []
  description = "Transit gateway attachment IDs to associate with this route table, replacing whichever route table each was otherwise associated with. For a same-account attachment, prefer transit_gateway_default_route_table_association = false on the attachment (terraform-aws-transit-gateway-vpc-attachment) instead of replace_existing_association — see that variable's description for when it is actually needed."
}

variable "propagations" {
  default     = []
  description = "Transit gateway attachment IDs whose routes propagate into this route table. Independent of associations — an attachment can propagate into a route table it is not itself associated with."
}

variable "replace_existing_association" {
  default     = false
  description = "Whether an attachment listed in associations has its existing route table association removed before being associated with this route table. See the associations description for when this is actually needed."
}

variable "routes" {
  default     = []
  description = "Static routes for this route table. Each entry needs destination_cidr_block and exactly one of transit_gateway_attachment_id or blackhole = true. Routes from propagations are automatic and do not belong here."
  type = list(object({
    destination_cidr_block        = string
    transit_gateway_attachment_id = optional(string)
    blackhole                     = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for r in var.routes : (r.transit_gateway_attachment_id != null) != r.blackhole])
    error_message = "Each route needs exactly one of transit_gateway_attachment_id or blackhole = true."
  }

  validation {
    condition     = length(var.routes) == length(distinct([for r in var.routes : r.destination_cidr_block]))
    error_message = "Each route's destination_cidr_block must be unique."
  }
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the route table."
}

resource "aws_ec2_transit_gateway_route_table" "resource" {
  transit_gateway_id = var.transit_gateway_id

  tags = merge(var.tags, { name = "route-table" })
}

resource "aws_ec2_transit_gateway_route_table_association" "resource" {
  count = length(var.associations)

  transit_gateway_attachment_id  = var.associations[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.resource.id
  replace_existing_association   = var.replace_existing_association
}

resource "aws_ec2_transit_gateway_route_table_propagation" "resource" {
  count = length(var.propagations)

  transit_gateway_attachment_id  = var.propagations[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.resource.id
}

resource "aws_ec2_transit_gateway_route" "resource" {
  for_each = { for r in var.routes : r.destination_cidr_block => r }

  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  blackhole                      = each.value.blackhole
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.resource.id
}

output "id" {
  description = "The ID of the transit gateway route table."
  value       = aws_ec2_transit_gateway_route_table.resource.id
}

output "arn" {
  description = "The ARN of the transit gateway route table."
  value       = aws_ec2_transit_gateway_route_table.resource.arn
}

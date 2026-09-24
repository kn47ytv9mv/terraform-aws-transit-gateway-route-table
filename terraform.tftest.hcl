mock_provider "aws" {
}

run "route_needs_exactly_one_target" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    routes = [{
      destination_cidr_block        = "10.0.0.0/16"
      transit_gateway_attachment_id = "tgw-attach-0123456789abcdef0"
      blackhole                     = true
    }]
  }

  expect_failures = [var.routes]
}

run "route_needs_a_target_at_all" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    routes = [{
      destination_cidr_block = "10.0.0.0/16"
    }]
  }

  expect_failures = [var.routes]
}

run "duplicate_destination_cidr_rejected" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    routes = [
      { destination_cidr_block = "10.0.0.0/16", blackhole = true },
      { destination_cidr_block = "10.0.0.0/16", transit_gateway_attachment_id = "tgw-attach-0123456789abcdef0" },
    ]
  }

  expect_failures = [var.routes]
}

run "route_table_and_routes_created" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    associations       = ["tgw-attach-aaaaaaaaaaaaaaaaa"]
    propagations       = ["tgw-attach-aaaaaaaaaaaaaaaaa", "tgw-attach-bbbbbbbbbbbbbbbbb"]

    routes = [
      { destination_cidr_block = "10.0.0.0/16", transit_gateway_attachment_id = "tgw-attach-aaaaaaaaaaaaaaaaa" },
      { destination_cidr_block = "0.0.0.0/0", blackhole = true },
    ]
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route_table_association.resource) == 1
    error_message = "One association should be created per entry in associations."
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route_table_propagation.resource) == 2
    error_message = "One propagation should be created per entry in propagations."
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route.resource) == 2
    error_message = "One route should be created per entry in routes."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.resource["0.0.0.0/0"].blackhole == true
    error_message = "The blackhole route should be keyed by its own destination_cidr_block, not an index, and should have blackhole = true."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.resource["10.0.0.0/16"].transit_gateway_attachment_id == "tgw-attach-aaaaaaaaaaaaaaaaa"
    error_message = "The attachment route should carry the correct transit_gateway_attachment_id."
  }
}

run "no_associations_or_routes_creates_bare_route_table" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route_table_association.resource) == 0
    error_message = "No associations were given, so none should be created."
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route.resource) == 0
    error_message = "No routes were given, so none should be created."
  }
}

run "readme_default_example" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    associations       = ["tgw-attach-aaaaaaaaaaaaaaaaa"]
    propagations       = ["tgw-attach-aaaaaaaaaaaaaaaaa", "tgw-attach-bbbbbbbbbbbbbbbbb"]
  }
}

run "readme_blackhole_example" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    associations       = ["tgw-attach-aaaaaaaaaaaaaaaaa"]

    routes = [{
      destination_cidr_block = "0.0.0.0/0"
      blackhole              = true
    }]
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.resource["0.0.0.0/0"].blackhole == true
    error_message = "The README's quarantine example should create a blackhole default route."
  }
}

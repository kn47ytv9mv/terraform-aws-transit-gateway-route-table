# terraform-aws-transit-gateway-route-table

Terraform module for a custom transit gateway route table — routing
segmentation across attachments, independent of the transit gateway's own
default route table.

## Cost

Transit gateway route tables carry no charge of their own — cost is
billed per attachment, at the transit gateway level. See
[`terraform-aws-transit-gateway`](https://github.com/kn47ytv9mv/terraform-aws-transit-gateway)'s
Cost section for the resource this module's routing ultimately affects.

## Design

Every transit gateway has one default association route table and one
default propagation route table, both used automatically unless an
attachment opts out. This module exists for when that default is not
enough — segmenting traffic between, say, a production route table and a
non-production one, so a non-production attachment's routes never
propagate anywhere production can reach.

- `associations`: attachment IDs associated with this route table instead
  of whatever they were otherwise associated with.
- `propagations`: attachment IDs whose routes propagate into this route
  table. Independent of `associations` — an attachment can propagate into
  a route table it is not itself associated with, which is exactly what
  lets a "hub" attachment see routes from many "spoke" route tables
  without every spoke being directly associated with the hub's own table.
- `routes`: static routes, each pointing at an attachment or set to
  `blackhole = true` (drop matching traffic instead of routing it
  anywhere) — for routes that are not simply "whatever an attachment
  propagates."

For a same-account attachment, prefer decoupling it from the transit
gateway's default route table at the attachment itself
(`transit_gateway_default_route_table_association = false` on
[`terraform-aws-transit-gateway-vpc-attachment`](https://github.com/kn47ytv9mv/terraform-aws-transit-gateway-vpc-attachment))
rather than via `replace_existing_association` here — see the
`associations` input below for when that argument is actually needed
(a transit gateway shared in from another account).

### Why these are addressed by position

**Associations and propagations are addressed by their position in the list, not by the
attachment ID itself.** Terraform has to know every `for_each` key before it
plans, and an attachment created in the same apply has no ID yet, so keying
on it fails with *"the for_each set includes values derived from resource
attributes that cannot be determined until apply"* — which rules out the
ordinary case of building both together. A list's length is known even
when none of its elements are, so `count` plans cleanly.

The consequence worth knowing: **reordering or removing an entry shifts
every later one's address**, and Terraform will plan to destroy and
recreate them. Append rather than insert, and use `moved` blocks when an
existing deployment has to be reshuffled.

## Usage

```hcl
module "prod_route_table" {
  source = "kn47ytv9mv/transit-gateway-route-table/aws"

  transit_gateway_id = module.transit_gateway.id
  associations       = [module.attachment_prod_us_east_1.id]
  propagations       = [module.attachment_prod_us_east_1.id, module.attachment_prod_eu_west_1.id]
}
```

Or directly from this repository:

```hcl
module "quarantine_route_table" {
  source = "github.com/kn47ytv9mv/terraform-aws-transit-gateway-route-table"

  transit_gateway_id = module.transit_gateway.id
  associations       = [module.attachment_quarantined.id]

  routes = [
    {
      destination_cidr_block = "0.0.0.0/0"
      blackhole              = true
    }
  ]
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3 |
| aws | ~> 6.61 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| transit_gateway_id | The ID of the transit gateway this route table belongs to. | `null` | no |
| associations | Transit gateway attachment IDs to associate with this route table, replacing whichever route table each was otherwise associated with. For a same-account attachment, prefer `transit_gateway_default_route_table_association = false` on the attachment (`terraform-aws-transit-gateway-vpc-attachment`) instead of `replace_existing_association` — see that variable's description for when it is actually needed. | `[]` | no |
| propagations | Transit gateway attachment IDs whose routes propagate into this route table. Independent of `associations` — an attachment can propagate into a route table it is not itself associated with. | `[]` | no |
| replace_existing_association | Whether an attachment listed in `associations` has its existing route table association removed before being associated with this route table. See the `associations` description for when this is actually needed. | `false` | no |
| routes | Static routes for this route table. Each entry needs `destination_cidr_block` and exactly one of `transit_gateway_attachment_id` or `blackhole = true`. Routes from `propagations` are automatic and do not belong here. | `[]` | no |
| tags | A map of tags to assign to the route table. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the transit gateway route table. |
| arn | The ARN of the transit gateway route table. |

## License

MIT — see [LICENSE.md](LICENSE.md).

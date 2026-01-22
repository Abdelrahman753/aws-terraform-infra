resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = var.routes
    content {
      cidr_block     = route.value.cidr_block
      gateway_id     = lookup(route.value, "gateway_id", null)
      nat_gateway_id = lookup(route.value, "nat_gateway_id", null)
    }
  }

  tags = {
    Name = var.name
  }
}

resource "aws_route_table_association" "this" {
  for_each = toset(var.subnet_ids)

  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}

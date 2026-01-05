###################### Route53 Data Lookup ######################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone
data "aws_route53_zone" "hashidemos" {
  name         = "connor-fryar.sbx.hashidemos.io"
  private_zone = false
}

###################### Route53 A Record Definition ######################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "ARecordTestInstance" {
  zone_id = data.aws_route53_zone.hashidemos.zone_id
  name    = local.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_instance.TestInstanceInstance.public_ip]

  depends_on = [aws_instance.TestInstanceInstance]
}

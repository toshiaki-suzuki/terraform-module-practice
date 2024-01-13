# SESドメインアイデンティティの設定
# メール送信のドメイン認証につかうドメインを設定
resource "aws_ses_domain_identity" "this" {
  domain = var.domain_name
}

# SESのドメイン認証確認をしようとするとDKIMの認証に最長72時間かかるため無効化する
# Ref https://docs.aws.amazon.com/ja_jp/ses/latest/DeveloperGuide/troubleshoot-dkim.html
# resource "aws_ses_domain_identity_verification" "this" {
#   domain = var.domain_name

#   depends_on = [aws_route53_record.txt_ses]
# }

# SESドメインDKIMの設定
resource "aws_ses_domain_dkim" "this" {
  domain = var.domain_name
}

# SPFによるメール送信ドメイン認証の設定
resource "aws_ses_domain_mail_from" "this" {
  domain           = var.domain_name
  mail_from_domain = "mail.${var.domain_name}"
}

# Route53のホストゾーン
resource "aws_route53_zone" "this" {
  name = var.domain_name
}

# data "aws_route53_zone" "example_com" {
#   name = var.domain_name
# }

# SES用TXTレコード
# SESドメイン認証に必要なTXTレコードを設定します。
resource "aws_route53_record" "txt_ses" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.this.verification_token]
}

# DKIM用CNAMEレコード
# SESでのDKIM認証に必要なCNAMEレコードを設定します。
resource "aws_route53_record" "cname_dkim" {
  count   = 3
  zone_id = aws_route53_zone.this.zone_id
  name    = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = "1800"
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
  depends_on = [aws_ses_domain_dkim.this]
}

# SPF用MXレコード
# メールの送信元として使用されるドメインのMXレコードを設定します。
resource "aws_route53_record" "mx_mail" {
  zone_id = aws_route53_zone.this.zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.ap-northeast-1.amazonses.com"]
}

# SPF用TXTレコード
# SPF認証用のTXTレコードを設定します。
resource "aws_route53_record" "txt_mail" {
  zone_id = aws_route53_zone.this.zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]
}

# DMARC設定
# DMARC (Domain-based Message Authentication, Reporting & Conformance) は、メールが正当な送信元から来ているかを確認し、フィッシングなどの不正行為を防ぐためのメカニズムです。
resource "aws_route53_record" "txt_dmarc" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1;p=quarantine;pct=25;rua=mailto:dmarcreports@example.com"]
}
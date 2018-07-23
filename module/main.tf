provider "tls" {
  version = "~> 1.1"
}

# ---------------------------------------------------------------------------------------------------------------------
#  CREATE A CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "ca" {
  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = "${tls_private_key.ca.algorithm}"
  private_key_pem   = "${tls_private_key.ca.private_key_pem}"
  is_ca_certificate = true

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.ca_allowed_uses}"]

  subject {
    common_name  = "${var.ca_common_name}"
    organization = "${var.organization_name}"
  }

  # Store the CA public key in a file.
  provisioner "local-exec" {
    command = "echo '${tls_self_signed_cert.ca.cert_pem}' > '${var.ca_public_key_file_path}' && chmod ${var.permissions} '${var.ca_public_key_file_path}' && chown ${var.owner} '${var.ca_public_key_file_path}'"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TLS CERTIFICATE SIGNED USING THE CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "cert" {
  count = "${length(var.domain_prefixes)}"

  algorithm   = "${var.private_key_algorithm}"
  ecdsa_curve = "${var.private_key_ecdsa_curve}"
  rsa_bits    = "${var.private_key_rsa_bits}"

  # Store the certificate's private key in a file.
  provisioner "local-exec" {
    command = "echo '${self.private_key_pem}' > '${var.private_key_file_path}.${element(var.domain_prefixes, count.index)}' && chmod ${var.permissions} '${var.private_key_file_path}.${element(var.domain_prefixes, count.index)}' && chown ${var.owner} '${var.private_key_file_path}.${element(var.domain_prefixes, count.index)}'"
  }
}

resource "tls_cert_request" "cert" {
  count = "${length(var.domain_prefixes)}"

  key_algorithm   = "${element(tls_private_key.cert.*.algorithm, count.index)}"
  private_key_pem = "${element(tls_private_key.cert.*.private_key_pem, count.index)}"

  dns_names    = ["${element(var.domain_prefixes, count.index)}.${var.sub_domain}"]
  ip_addresses = ["${var.ip_addresses}"]

  subject {
    common_name  = "${var.common_name}"
    organization = "${var.organization_name}"
  }
}

resource "tls_locally_signed_cert" "cert" {
  count = "${length(var.domain_prefixes)}"

  cert_request_pem = "${element(tls_cert_request.cert.*.cert_request_pem, count.index)}"

  ca_key_algorithm   = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.allowed_uses}"]

  # Store the certificate's public key in a file.
  provisioner "local-exec" {
    command = "echo '${self.cert_pem}' > '${var.public_key_file_path}.${element(var.domain_prefixes, count.index)}' && chmod ${var.permissions} '${var.public_key_file_path}.${element(var.domain_prefixes, count.index)}' && chown ${var.owner} '${var.public_key_file_path}.${element(var.domain_prefixes, count.index)}'"
  }
}

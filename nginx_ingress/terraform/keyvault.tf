data "azurerm_key_vault" "main" {
  name                = var.keyvault_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id = data.azurerm_key_vault.main.id
  object_id = azurerm_user_assigned_identity.main.principal_id
  tenant_id = azurerm_user_assigned_identity.main.tenant_id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
    "GetIssuers",
    "List",
    "ListIssuers",
  ]
}

resource "azurerm_key_vault_certificate" "main" {
  name         = var.ingress_cert_name
  key_vault_id = data.azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      curve = "P-384"
      key_size   = 384
      key_type   = "EC"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["internal.contoso.com", "domain.hello.world"]
      }

      subject            = "CN=${var.ingress_cert_cn}"
      validity_in_months = 12
    }
  }
}
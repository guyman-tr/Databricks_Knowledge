# Lineage — DWH_dbo.Dim_BillingProtocolMIDSettingsID

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | `etoro.Billing.ProtocolMIDSettings` |
| **Source Server** | etoroDB-REAL |
| **Generic Pipeline ID** | 636 |
| **Copy Strategy** | Override |
| **Frequency** | Daily (every 1440 minutes) |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings.ID | Renamed: `ID AS ProtocolMIDSettingsID` |
| ParameterID | Billing.ProtocolMIDSettings.ParameterID | Passthrough |
| DepotID | Billing.ProtocolMIDSettings.DepotID | Passthrough |
| DepotModeID | Billing.ProtocolMIDSettings.DepotModeID | Passthrough |
| Value | Billing.ProtocolMIDSettings.Value | Passthrough |
| RegulationID | Billing.ProtocolMIDSettings.RegulationID | Passthrough |
| CurrencyID | Billing.ProtocolMIDSettings.CurrencyID | Passthrough |
| Description | Billing.ProtocolMIDSettings.Description | Passthrough |
| SubTypeID | Billing.ProtocolMIDSettings.SubTypeID | Passthrough |
| MerchantAccountID | Billing.ProtocolMIDSettings.MerchantAccountID | Passthrough |
| UpdateDate | — | ETL-generated: `GETDATE()` at load time |

## ETL Chain

```
etoro.Billing.ProtocolMIDSettings (etoroDB-REAL)
  → Generic Pipeline (ID 636, daily, Override)
    → DWH_staging.etoro_Billing_ProtocolMIDSettings
      → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
        → DWH_dbo.Dim_BillingProtocolMIDSettingsID
```

---

*Generated: 2026-03-18*

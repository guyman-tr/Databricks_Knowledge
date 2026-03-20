# Column Lineage: DWH_dbo.Dim_BillingProtocolMIDSettingsID

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_BillingProtocolMIDSettingsID` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Billing.ProtocolMIDSettings` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Billing.ProtocolMIDSettings (etoroDB-REAL, ~1,851 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/etoro/Billing/ProtocolMIDSettings/
  |
  v [staging]
DWH_staging.etoro_Billing_ProtocolMIDSettings
  |
  v [SP_Dictionaries_DL_To_Synapse - TRUNCATE + INSERT]
DWH_dbo.Dim_BillingProtocolMIDSettingsID (~1,851 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **passthrough (renamed)** | Column copied as-is but given a different name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | ID | passthrough (renamed) | Production identity column ID renamed to ProtocolMIDSettingsID in DWH |
| ParameterID | Billing.ProtocolMIDSettings | ParameterID | passthrough | Protocol parameter type (references Billing.Parameter) |
| DepotID | Billing.ProtocolMIDSettings | DepotID | passthrough | Payment depot FK |
| DepotModeID | Billing.ProtocolMIDSettings | DepotModeID | passthrough | 0=General, 1=Live, 2=Demo |
| Value | Billing.ProtocolMIDSettings | Value | passthrough | SENSITIVE: MID/API credentials |
| RegulationID | Billing.ProtocolMIDSettings | RegulationID | passthrough | Regulatory jurisdiction |
| CurrencyID | Billing.ProtocolMIDSettings | CurrencyID | passthrough | 0=any currency |
| Description | Billing.ProtocolMIDSettings | Description | passthrough | Human-readable MID description |
| SubTypeID | Billing.ProtocolMIDSettings | SubTypeID | passthrough | 0=default, 3=alternate routing |
| MerchantAccountID | Billing.ProtocolMIDSettings | MerchantAccountID | passthrough | Merchant account override (nullable) |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 9 |
| **Passthrough (renamed)** | 1 |
| **ETL-computed** | 1 |
| **Total** | 11 |

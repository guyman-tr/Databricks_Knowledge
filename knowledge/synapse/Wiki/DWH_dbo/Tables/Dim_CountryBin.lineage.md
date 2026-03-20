# Column Lineage: DWH_dbo.Dim_CountryBin

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CountryBin` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `etoro.Dictionary.CountryBin6` + `etoro.Dictionary.CountryBin8` (etoro) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None (both BIN sources pre-merged in staging) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.CountryBin6 (6-digit BINs)
etoro.Dictionary.CountryBin8 (8-digit BINs)
  -> [pre-merged / Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_CountryBin (19 cols, HEAP ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, 12 cols)
  -> DWH_dbo.Dim_CountryBin (16.3M rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **type-cast** | Same value, different data type. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CountryID | etoro.Dictionary.CountryBin6/8 | CountryID | passthrough | Card-issuing country FK. |
| BinCode | etoro.Dictionary.CountryBin6/8 | BinCode | passthrough | 6-digit (<10M) or 8-digit (>=10M) BIN. |
| IssuingBank | etoro.Dictionary.CountryBin6/8 | IssuingBank | passthrough | Often NULL in practice. |
| CardTypeID | etoro.Dictionary.CountryBin6/8 | CardTypeID | passthrough | Card network ID. |
| CardSubType | etoro.Dictionary.CountryBin6/8 | CardSubType | passthrough | Card product sub-classification. |
| CardCategory | etoro.Dictionary.CountryBin6/8 | CardCategory | passthrough | Card tier (Standard, Gold, Platinum). |
| BankWebSite | etoro.Dictionary.CountryBin6/8 | BankWebSite | passthrough | Informational. Often NULL. |
| BankInfo | etoro.Dictionary.CountryBin6/8 | BankInfo | passthrough | Informational. Often NULL. |
| ShouldCheck3ds | etoro.Dictionary.CountryBin6/8 | ShouldCheck3ds | type-cast | int (staging) -> tinyint (DWH). 0/1 values preserved. |
| MinAmountFor3ds | etoro.Dictionary.CountryBin6/8 | MinAmountFor3ds | passthrough | Minimum amount triggering 3DS. |
| IsPrepaid | etoro.Dictionary.CountryBin6/8 | IsPrepaid | passthrough | bit in both staging and DWH. |
| UpdateDate | - | - | ETL-computed | GETDATE() on each reload. |

## Dropped Staging Columns

| Staging Column | Type | Not Loaded To DWH |
|--------------|------|-------------------|
| ProductType | nvarchar(max) | Card product type string |
| Category | nvarchar(max) | Card category string (overlaps CardCategory?) |
| ChallengeIndicator3DS | nvarchar(max) | 3DS challenge indicator code |
| SupportsAFT | bit | Account Funding Transaction support |
| IsCFT | int | Card Funding Transaction flag |
| DomesticMoneyTransfer | nvarchar(max) | Domestic money transfer rules |
| CrossBorderMoneyTransfer | nvarchar(max) | Cross-border money transfer rules |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 10 |
| **Type-cast** | 1 |
| **ETL-computed** | 1 |
| **Total** | 12 |
| **Dropped staging columns** | 7 |

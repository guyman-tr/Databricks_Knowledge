# Lineage: BI_DB_dbo.BI_DB_ACH_PWMB_Flag_Report_History

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: BI_DB_ACH_PWMB_Flag_Report_History
**Object Type**: Table — AML/compliance flag report history for ACH/PWMB customers (multi-country IP detection)
**Writer SP**: None identified (no writer SP in SSDT BI_DB_dbo; not registered in OpsDB)
**Production Source**: Unknown — no Generic Pipeline, no External Table, no SSDT SP
**Related Payment Methods**: ACH (FundingTypeID=29), PWMB (FundingTypeID=32) from DWH_dbo.Dim_FundingType
**Backup Note**: `BI_DB_dbo.BI_DB_ACH_PWMB_Flag_Report_History_Backup_20241117` exists (bigint RealCID → int schema change)

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | Unknown (compliance/AML system) | CID | Real customer ID (non-demo); schema change: bigint → int Nov 2024 | Tier 3 |
| 2 | Regulation | Unknown (compliance system) | Regulation | Regulatory jurisdiction (e.g., NYDFS+FINRA, ASIC) | Tier 3 |
| 3 | Age | Unknown | Age | Customer age at report time | Tier 3 |
| 4 | LastMultiIPDaily | Unknown (IP geo-detection system) | — | Last date of multi-country IP login (bigint — likely YYYYMMDD) | Tier 3 |
| 5 | FirstMultiIPDaily | Unknown (IP geo-detection system) | — | First date of multi-country IP login (bigint — likely YYYYMMDD) | Tier 3 |
| 6 | TotalDaysMultiCountry | Unknown | — | Total days customer logged in from multiple countries | Tier 3 |
| 7 | VerifiedPhoneCounty | Unknown (KYC system) | — | Country of verified phone number (note: column spelled "County") | Tier 3 |
| 8 | RegCountry | Unknown (CRM/KYC system) | — | Country of customer registration | Tier 3 |
| 9 | PhoneVerificationDate | Unknown (KYC system) | — | Date phone was verified via KYC | Tier 3 |
| 10 | PhoneNumber | Unknown (KYC system) | — | Customer phone number (bigint) | Tier 3 |
| 11 | FundingType | DWH_dbo.Dim_FundingType | Name | Payment method type name (ACH, PWMB, etc.) | Tier 3 |
| 12 | TotalAccountsConnected | Unknown (compliance system) | — | Total accounts linked to this customer (social graph) | Tier 3 |
| 13 | Opened_New_SameDay | Unknown | — | Count of accounts opened on same day as this customer | Tier 3 |
| 14 | PlayerStatusID | Unknown (CRM system) | — | Customer account status | Tier 3 |
| 15 | IsDepositor | Unknown | — | Binary flag: 1 = customer has deposited, 0 = no deposit | Tier 3 |
| 16 | NumberOfFlags | Unknown (compliance system) | — | Total compliance flags triggered for this customer | Tier 3 |
| 17 | ReportDate | Unknown (compliance system) | — | Date this compliance report was generated; clustered index key | Tier 3 |
| 18 | FirstReported | Unknown | — | Date customer was first flagged for compliance review | Tier 3 |
| 19 | TotalPendingCOForUser | Unknown | — | Total monetary amount pending compliance officer review | Tier 4 |
| 20 | UpdateDate | ETL pipeline | — | ETL load timestamp | Tier 5 |
| 21 | OnlyNonUSLogins60Days | Unknown (IP geo-detection) | — | 1 if all logins in past 60 days were from non-US IPs; related to GEO005 US regulation alert | Tier 3 |
| 22 | FirstMultiIPDayCountries | Unknown (IP geo-detection) | — | Comma-separated countries active on first multi-country IP day | Tier 3 |
| 23 | LastMultiIPDayCountries | Unknown (IP geo-detection) | — | Comma-separated countries active on last multi-country IP day | Tier 3 |

## ETL Pipeline

```
Unknown source (AML/compliance system — external report generator)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_DB_ACH_PWMB_Flag_Report_History (0 rows — empty as of 2026-04-23)

No active UC pipeline. Not in OpsDB. Not in Generic Pipeline mapping.

Related AML context:
  SP_AML_BI_Alerts_New — uses PWMB as FundingType filter for AML_NY001/AML_NY002 alerts
    → DWH_dbo.Dim_FundingType: Name='PWMB' (FundingTypeID=32), Name='ACH' (FundingTypeID=29)
  SP_ChargebackReport — ACH/PWMB SLA tracking (FundingTypeIDs 29/32)
  SP_Operations_Monthly_KPIs_FullData — ACH/PWMB cashout SLA tracking

Schema history:
  BI_DB_ACH_PWMB_Flag_Report_History_Backup_20241117 — backup from Nov 2024
    (RealCID was bigint in backup; current table uses int — schema change 2024-11-17)
```

## Notes

- Table is currently empty (0 rows as of 2026-04-23)
- No writer SP found in SSDT BI_DB_dbo or in broader SSDT scan
- ACH (FundingTypeID=29) and PWMB (FundingTypeID=32) are US-focused bank transfer payment methods
- Schema change: RealCID was bigint in Nov 2024 backup → int in current DDL
- `VerifiedPhoneCounty` is a spelling anomaly in the column name (likely "Country" not "County")
- `LastMultiIPDaily`/`FirstMultiIPDaily` stored as bigint — likely YYYYMMDD integer format matching DWH DateID convention
- Multi-country IP detection relates to GEO005 alert type in SP_AML_BI_Alerts_New

# EXW_dbo.EXW_SimplexChargebacks — Column Lineage

**Generated**: 2026-04-20  
**Object**: EXW_dbo.EXW_SimplexChargebacks  
**Type**: Table  
**Production Source**: Simplex external chargeback report (external feed — not in DB_Schema)  
**ETL Mechanism**: External one-time bulk load (all records loaded 2020-03-15, no subsequent updates)

---

## ETL Pipeline

```
Simplex Chargeback Report (external provider, 2019 data)
  |-- One-time bulk load (2020-03-15) ---|
  v
EXW_dbo.EXW_SimplexChargebacks (5 rows, historical archive, frozen)
  |-- No UC Generic Pipeline mapping found ---|
  v
UC Target: _Not_Migrated
```

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|------------|-------------|---------------|-----------|------|
| 1 | Payment_ID | Simplex chargeback report | Payment_ID | Passthrough (Simplex transaction GUID, matches long_id in EXW_SimplexMapping) | Tier 4 |
| 2 | Transaction_Date | Simplex chargeback report | Transaction_Date | Passthrough (original transaction datetime) | Tier 4 |
| 3 | Chbk_Posting_Date | Simplex chargeback report | Chbk_Posting_Date | Passthrough (chargeback posting date) | Tier 4 |
| 4 | Chbk_AMT ($) | Simplex chargeback report | Chbk_AMT | Passthrough (money type) | Tier 4 |
| 5 | Chargeback_Type | Simplex chargeback report | Chargeback_Type | Passthrough (all = "fraud" in dataset) | Tier 4 |
| 6 | Is_Simplex_Liable | Simplex chargeback report | Is_Simplex_Liable | Passthrough (all = 1 in dataset) | Tier 4 |
| 7 | Final Decision Date | Simplex chargeback report | Final Decision Date | Passthrough | Tier 4 |
| 8 | CB Funds Status | Simplex chargeback report | CB Funds Status | Passthrough (free text settlement narrative) | Tier 4 |
| 9 | ARN | Simplex chargeback report | ARN | Passthrough (Acquirer Reference Number) | Tier 4 |
| 10 | Reason_Code | Simplex chargeback report | Reason_Code | Passthrough (card scheme reason code) | Tier 4 |
| 11 | Reason_Description | Simplex chargeback report | Reason_Description | Passthrough | Tier 4 |
| 12 | Card_Brand | Simplex chargeback report | Card_Brand | Passthrough (lowercase: visa, master) | Tier 4 |
| 13 | Processor_Name | Simplex chargeback report | Processor_Name | Passthrough (all = "ECP" in dataset) | Tier 4 |
| 14 | Simplex_ID | Simplex chargeback report | Simplex_ID | Passthrough (Simplex numeric transaction ID, matches long_id prefix in EXW_SimplexMapping) | Tier 4 |
| 15 | Comments | Simplex chargeback report | Comments | Passthrough (free text, empty in all 5 rows) | Tier 4 |
| 16 | UpdateDate | ETL | — | ETL-managed load timestamp (all rows = 2020-03-15) | Tier 2 |

---

## Notes

- **Micro table**: Only 5 rows, all loaded in a single bulk operation on 2020-03-15
- **Historical archive**: Data covers 2019-02-28 to 2019-05-20; no updates since 2020
- **ECP processor**: All 5 chargebacks were processed through ECP Bank (same provider as EXW_ECPBank)
- **Liability**: All 5 rows show Is_Simplex_Liable = 1 — Simplex bore full liability for these disputes

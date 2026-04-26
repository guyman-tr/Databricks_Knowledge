# Column Lineage — BI_DB_dbo.BI_DB_BO_Generated_Compensations

Generated: 2026-04-23 | Writer SP: SP_BO_Generated_Compensations | ETL Frequency: Daily

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source** | etoro.History.Credit (CreditTypeID=6 only) |
| **Source Layer** | External_etoro_History_Credit_Yesterday (BI_DB_dbo External table) |
| **UC Target** | `general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations` (via view V_BI_DB_BO_Generated_Compensations) |
| **Upstream Wiki** | None — etoro.History.Credit has no wiki in DB_Schema/etoro/Wiki/History/ |

## ETL Pipeline

```
etoro.History.Credit (production, server: etoroDB-REAL)
  |-- SP_Create_External_etoro_History_Credit @Date, 'Yesterday' --|
  v
BI_DB_dbo.External_etoro_History_Credit_Yesterday  (CreditTypeID filter applied)
  |-- JOIN External_etoro_BackOffice_Customer (RegulationID) --|
  |-- JOIN External_etoro_BackOffice_CompensationReason (Category name) --|
  |-- JOIN External_etoro_BackOffice_Manager (Manager name) --|
  |-- JOIN DWH_dbo.Dim_Customer (AffiliateID, PlayerLevelID, CountryID) --|
  |-- JOIN DWH_dbo.Dim_Regulation (Regulation name) --|
  |-- JOIN DWH_dbo.Dim_PlayerLevel (Player Level name) --|
  |-- JOIN DWH_dbo.Dim_Country (Country name) --|
  |-- JOIN DWH_dbo.Dim_MoveMoneyReason (Reason) --|
  |-- SP_BO_Generated_Compensations @Date (daily, P0) --|
  |-- DELETE WHERE Time>=@Date AND <@Date+1 + INSERT --|
  v
BI_DB_dbo.BI_DB_BO_Generated_Compensations (26.8M rows, 2021-01-01 to 2026-04-12)
  |-- View: V_BI_DB_BO_Generated_Compensations (renames space columns) --|
  |-- Generic Pipeline (Gold export, Append, daily) --|
  v
general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations
```

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | CID | External_etoro_History_Credit_Yesterday | CID | Passthrough — customer who received the compensation | Tier 2 |
| 2 | Amount | External_etoro_History_Credit_Yesterday | Payment | CAST(Payment AS DECIMAL(16,2)) — rename and cast | Tier 2 |
| 3 | Type | DWH_dbo.Dim_CreditType | CreditTypeName | Always 'Compensation' (CreditTypeID=6 filter); LTRIM/RTRIM applied | Tier 2 |
| 4 | Time | External_etoro_History_Credit_Yesterday | Occurred | Passthrough — compensation event datetime | Tier 2 |
| 5 | Description | External_etoro_History_Credit_Yesterday | Description | Passthrough — free-text compensation description | Tier 2 |
| 6 | Category | External_etoro_BackOffice_CompensationReason | Name | Resolved via HCRD.CompensationReasonID → BCOR.Name (for CreditTypeID=6) | Tier 2 |
| 7 | Reason | DWH_dbo.Dim_MoveMoneyReason | MoveMoneyReason | Resolved via HCRD.MoveMoneyReasonID → DMMR.MoveMoneyReason; NULL ~87% | Tier 2 |
| 8 | Manager | External_etoro_BackOffice_Manager | FirstName, LastName | CONCAT(FirstName, '', LastName) — no space separator (known bug) | Tier 2 |
| 9 | Affiliate | DWH_dbo.Dim_Customer | AffiliateID | Resolved via HCRD.CID → CCST.AffiliateID | Tier 2 |
| 10 | Player Level | DWH_dbo.Dim_PlayerLevel | Name | Resolved via Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name | Tier 2 |
| 11 | Country (Reg Form) | DWH_dbo.Dim_Country | Name | Resolved via Dim_Customer.CountryID → Dim_Country.Name | Tier 2 |
| 12 | Regulation | DWH_dbo.Dim_Regulation | Name | Resolved via BackOffice_Customer.RegulationID → Dim_Regulation.Name | Tier 2 |
| 13 | UpdateDate | — | — | GETDATE() at INSERT time — ETL metadata | Propagation |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No upstream wiki for etoro.History.Credit |
| Tier 2 | 12 | ETL-derived from History.Credit + DWH dimension lookups |
| Propagation | 1 | UpdateDate |

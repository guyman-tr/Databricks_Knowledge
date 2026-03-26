# BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns traced to SP code (Tier 2).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| BalanceOnlyAccount | DDL says decimal(16,6) — is this the equity value rather than a 0/1 flag? Sample data shows 0.000000. |
| CountryID | DDL says decimal(16,6) but logically a country ID is an integer. Is this a DDL quirk? |
| MifidCategorizationID | DDL says decimal(16,6) — same question as CountryID. |
| TP_External_FTDA | Logic differs from other FTDA columns — it uses MIMO aggregation rather than Dim_Customer. Is this intentional? |

## Structural Questions

- The population waterfall gives priority to TP. If a customer has both TP and IBAN deposits, they appear in TP only. Is this always correct for IBAN-specific metrics?
- FTD coercion logic is applied only for dates ≥ 20250901. Pre-September 2025 FTDs may have timing mismatches between MIMO and Dim_Customer.
- The commented-out `#mimoAllPlatforms` code includes MoneyFarm synthetic deposits. Is this meant to be enabled?

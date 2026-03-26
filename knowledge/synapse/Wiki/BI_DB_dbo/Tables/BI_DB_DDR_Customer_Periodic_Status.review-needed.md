# BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns traced to SP code (Tier 2).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Portfolio_Only_ThisYear / BalanceOnlyAccount_ThisYear | These use `ActiveTraded_ThisQuarter = 0` instead of `ActiveTraded_ThisYear = 0` in the WHERE condition (SP lines 417-418). Is this intentional or a bug? |
| RegulationID_ThisX | SUM is used in the final SELECT, but RegulationID is a lookup ID not a count. Does this produce correct values for the outer GROUP BY? |

## Structural Questions

- The CTE reads all Daily_Status rows from YearStart to @dateID. For Q4 this scans up to 365 days × 6.8M CIDs. Is this causing performance issues?
- Why does this table start from 2015 while Daily_Status starts from 2007? Was there a backfill cutoff?

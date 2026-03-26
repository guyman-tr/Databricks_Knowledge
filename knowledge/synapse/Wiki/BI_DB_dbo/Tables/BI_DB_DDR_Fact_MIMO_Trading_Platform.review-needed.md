# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns traced to SP code (Tier 2).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| IsCryptoToFiat | Always 0 — where is the actual C2F MIMO data tracked? In the eMoney MIMO table? |
| IsRedeem | Is this a billing redeem (bonus-related) or a general withdrawal classification? |
| AmountOrigCurrency | For withdraws, the fallback calc is ROUND(Amount_WithdrawToFunding/ExchangeRate). When does the primary source (BI_DB_DepositWithdrawFee) have data vs NULL? |

## Structural Questions

- The FTD recovery UPDATE only runs for DateID ≥ 20250901. Does this mean pre-September 2025 FTDs might be underreported?
- ActionTypeID 44/45 added May 2025. Should historical data be backfilled, or is the gap accepted?

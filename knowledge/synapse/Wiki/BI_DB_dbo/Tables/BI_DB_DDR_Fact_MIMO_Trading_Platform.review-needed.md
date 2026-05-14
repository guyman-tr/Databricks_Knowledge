# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform — Review Needed

> Tier 4 / structural follow-ups uncovered while regenerating DDR TP MIMO documentation (2026-05-14 pipeline run).

## Reviewer Corrections

| Column / Topic | Current (wrong / thin) | Correction | Scope | Reviewer | Date |
|----------------|------------------------|------------|-------|----------|------|
| _(empty)_ | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **None flagged** (`[UNVERIFIED]` not used).

## Columns Needing Clarification

| Topic | Evidence | Question |
|-------|----------|----------|
| `FundingTypeID` composite | Deposit uses `Fact_BillingDeposit.FundingTypeID` whereas withdraw maps `FundingTypeID_Funding` | Confirm marketing-friendly label when mixing rails in one DDR column (`Dim_FundingType` join ambiguity for analysts?). |
| `IsRedeem` vs `Fact_CustomerAction` §4 | Existing fact wiki ties `IsRedeem` wording to redeem/Dim_Position—differs from transfer-to-coin emphasis here | Harmonize **`Fact_CustomerAction.md`** + position docs so downstream tables inherit unified language. |
| `BI_DB_DepositWithdrawFee` join | Predicate uses `REPLACE(TransactionID,'W','')`; no sibling wiki surfaced | Needs Payments/Finance SME to validate coverage vs missing fee rows (`LEFT JOIN`). |

## Structural Questions

1. OpsDB **`Priority`** for `SB_Daily` shows `60` in dependency rows vs `Main row` excerpt `Priority: 0` — which governs SLA ordering?
2. Unity Catalog MCP could not enumerate `SHOW TABLES LIKE '*mimo_trading_platform*'` in `main.bi_db` — confirm final export table name (**gold vs bronze** prefix drift between synapse-etls SKILL note and stakeholder naming).
3. Should withdraw branch retain `fca.IsFTD` pre-UNION or is forced-zero intentional for DDR contracts only?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
| _(none)_ | | | | |

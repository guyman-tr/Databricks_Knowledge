# dbo Schema - Sodreconciliation

> Default schema containing utility tables, comparison views for the reconciliation UI, a shared price type, and the community monitoring procedure sp_WhoIsActive. Includes two test/scratch tables (Ran, elad) that are likely developer artifacts.

## Metrics

| Metric | Value |
|--------|-------|
| **Total Objects** | 7 |
| **Documented** | 7 (100%) |
| **Pending** | 0 |
| **Last Updated** | 2026-04-11 |

---

## Tables (3)

| Object | Quality | Status |
|--------|---------|--------|
| [dbo.ProcessDateTable](Tables/dbo.ProcessDateTable.md) | 5.0 | Done (Batch 1) |
| [dbo.Ran](Tables/dbo.Ran.md) | 3.0 | Done (Batch 1) |
| [dbo.elad](Tables/dbo.elad.md) | 3.0 | Done (Batch 1) |

## Views (2)

| Object | Quality | Status |
|--------|---------|--------|
| [dbo.PositionComparasionView](Views/dbo.PositionComparasionView.md) | 7.5 | Done (Batch 1) |
| [dbo.TradeComparasionView](Views/dbo.TradeComparasionView.md) | 7.5 | Done (Batch 1) |

## User Defined Types (1)

| Object | Quality | Status |
|--------|---------|--------|
| [dbo.dtPrice](User%20Defined%20Types/dbo.dtPrice.md) | 6.0 | Done (Batch 1) |

## Stored Procedures (1)

| Object | Quality | Status |
|--------|---------|--------|
| [dbo.sp_WhoIsActive](Stored%20Procedures/dbo.sp_WhoIsActive.md) | 6.0 | Done (Batch 1) |

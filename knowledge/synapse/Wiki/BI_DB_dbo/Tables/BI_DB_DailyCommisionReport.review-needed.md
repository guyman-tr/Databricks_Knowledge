# BI_DB_DailyCommisionReport — Review Needed

**Batch**: 20 | **Generated**: 2026-04-21 | **Reviewer**: Pending

## Tier 4 Items (Unverified — need confirmation)

The following 14 columns are documented as Tier 4 (Always NULL / Legacy/Deprecated). This classification is based on the current SP INSERT explicitly setting them to NULL since the 2025-07-16 overhaul, confirmed by live data query on DateID=20260412 (100% NULL). **Please confirm:**

| Column | Classification | Question |
|--------|---------------|----------|
| IsOutlier | Always NULL since 2025-07 | Was this populated by a separate SP prior to the overhaul? Is there historical data (pre-2025-07) where this column has values? |
| Transition | Always NULL | Same question — was this ever populated in production? |
| IsGermanBaFIN | Always NULL | Same question — were German BaFin customers ever flagged here? |
| RegulationIDPrev, RegulationPrev | Always NULL | Were these populated during regulation migration events? Is there historical data to preserve? |
| IsCreditReportValidCBPrev | Always NULL | Same — was this used for US CB reporting transitions? |
| CommissionByUnitsAtClose, UnrealizedCommissionNew, UnrealizedCommissionOldClosing, RealizedCommission | Always NULL in INSERT | These ARE computed in #allMetrics but the INSERT sets them to NULL. Was this intentional (decomposition retired) or a bug introduced in the 2025-07 overhaul? |
| FullCommissionByUnitsAtClose, UnrealizedFullCommissionNew, UnrealizedFullCommissionOldClosing | Always NULL | Same question as above for the "Full" variants. |
| UnealizedFullCommissionChange | Always NULL (+ DDL typo) | Same. Also: is the DDL typo 'UnealizedFullCommissionChange' known and accepted, or should it be corrected? |

## Questions for Domain Expert / Reviewer

1. **RealizedCommission vs. RealizedFullCommission**: `RealizedFullCommission` (column 61) IS populated (non-NULL) — it maps from `#FullComm.RealizedFullCommission = SUM(FullCommissionOnClose)`. But `RealizedCommission` (column 55) is always NULL. Were these intentionally asymmetric, or was the "net" RealizedCommission intended to be populated too?

2. **UnrealizedCommissionChange interpretation**: Column 56 (`UnrealizedCommissionChange`) computes the daily CHANGE in the unrealized spread-embedded commission — it's a delta, not a cumulative stock. Downstream consumers building cumulative unrealized commission series must SUM this column from the earliest date. Is this the intended usage, or is there a separate cumulative-unrealized-commission table?

3. **Commissions vs FullCommissions — which to use for P&L reporting?**: The two commission figures serve different purposes but it's not always obvious which to use in dashboards. For internal eToro P&L, should analysts use `Commissions` (net) or `FullCommissions` (gross)? Is there a documented policy?

4. **Foundation TVF dependency chain**: The SP uses 9 `Function_Revenue_*` TVFs. Are these functions in the same SSDT project and maintained by the same team? If a TVF is changed (e.g., to include a new ActionTypeID), does it automatically propagate to all DDR metrics, or are there separate tests/validations?

5. **BI_DB_Client_Balance_CID_Level_New as population source**: The #pop step uses `BI_DB_Client_Balance_CID_Level_New` for most customer dimensions rather than DWH directly. Is this intermediate table always guaranteed to be populated for @DateID before SP_DailyCommisionReport runs? What is the scheduling dependency?

6. **TradingFees definition (AdminFee + SpotAdjustFee + TicketFee + TicketFeeByPercent)**: Change history says "TradingFee = Ticket Fee + Islamic Fee" (2024-02-25, Artyom Bogomolsky). But the current formula adds 4 components including SpotAdjustFee. Is SpotAdjustFee intentionally included in TradingFees, or was it added later without updating the comment?

## Potential Data Quality Issues

- **COUNT(*) INT overflow**: The table exceeds 2 billion rows. Use `COUNT_BIG(*)` for full-table counts.
- **14 always-NULL legacy columns**: Downstream reports referencing these columns will always see NULL. Any ISNULL fallback or filter on these columns is a no-op.
- **"UnealizedFullCommissionChange" DDL typo**: Must be referenced with the misspelled name `[UnealizedFullCommissionChange]` in all queries. It is always NULL regardless.
- **IsDLTUser NULL for pre-2024-07-30 rows**: Any query joining on IsDLTUser=1 vs IsDLTUser=0 will incorrectly classify pre-July-2024 rows as non-DLT (NULL, not 0). Use ISNULL(IsDLTUser,0) in filters.
- **IsMarginTrade NULL for pre-2025-10-23 rows**: Same issue — ISNULL(IsMarginTrade,0) required for historical date filters.
- **All commission metrics 0 (not NULL) when no activity**: The #final step applies ISNULL(metric, 0) before insert, so customers with no activity in a specific metric have 0, not NULL, for that metric. Filters like `WHERE Commissions > 0` correctly isolate active rows, but `WHERE Commissions IS NULL` will return no rows.

## Correction Log

*(Empty — no corrections yet)*

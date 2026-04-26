---
object: BI_DB_dbo.BI_DB_CryptoDashboardNew
review_generated: 2026-04-23
status: needs_review
---

# Review Notes — BI_DB_CryptoDashboardNew

## Tier 4 Inferences (Reviewer Verification Required)

| Column | Inferred Claim | Confidence | Evidence |
|--------|---------------|------------|----------|
| AUA | SUM(Amount + PositionPnL) represents current market value | High | SP line 442: `SUM(ppnl.Amount + ppnl.PositionPnL)`. PositionPnL is sourced from BI_DB_PositionPnL which uses closing prices. If BI_DB_PositionPnL is not refreshed on the same day as this SP, AUA will reflect yesterday's prices. |
| Revenue | Revenue can be negative | High | Rollover credits can exceed commissions. Observed negative values in sample rows (e.g., -132.82). |
| Active_Hold | Date-level scalar broadcast to all rows | High | SP computes `#activehold` as COUNT DISTINCT CID GROUP BY DateID from BI_DB_PositionPnL, then LEFT JOINs to #final — making it a date-level scalar. Confirmed by sample: all rows on 2026-04-12 show Active_Hold=1,523,400. |
| num_of_FA_Crypto | ActionTypeID=1 = "Open position" first action | Medium | ActionTypeID=1 is the standard open action in Fact_CustomerAction. FirstEver=1 in Fact_FirstCustomerAction confirms first-ever. This claim is high-confidence but ActionTypeID mapping not verified from dictionary. |
| Seniority_daily_FTD_Group | 'No deposits' = FirstDepositDate = 1900-01-01 | High | SP explicit: `WHEN dc1.FirstDepositDate='1900-01-01 00:00:00.000' THEN 'No deposits'`. Sentinel value for customers who registered but have no deposit on record. |
| PlayerLevelID<>4 | ID=4 = Internal/employee accounts | High | Confirmed by Dim_PlayerLevel wiki: ID=4 = Internal (Sort=0). The SP WHERE clause excludes them from the population. |

## Open Questions for Business Reviewer

1. **BI_DB_PositionPnL refresh timing** — AUA, PnL, Open_Positions, and Active_Hold all derive from BI_DB_PositionPnL at DateID=@dateID. If SP_BI_DB_CryptoDashboardNew runs before BI_DB_PositionPnL is refreshed for the same date, these columns will be 0 or stale. Is there an explicit dependency ordering in OpsDB? What is the relative priority?

2. **SP_CryptoDashboard relationship** — There is also a `SP_CryptoDashboard.sql` in the SSDT repo. Does SP_CryptoDashboard write to a different table, or was it the predecessor to SP_BI_DB_CryptoDashboardNew? The "New" suffix suggests a replacement — is the old SP decommissioned?

3. **WeekofMonth computation** — SP line 484: `CONVERT(CHAR(8),YEAR(@date),112)*10000 + MONTH(@date)*100 + SSWeekNumberOfMonth`. CONVERT(CHAR(8), YEAR(@date), 112) converts a 4-digit year using format 112 (yyyymmdd) — this converts e.g. 2026 to '00001' which is nonsensical. This looks like a bug. Actual intent appears to be YEAR(@date)*1000000 or similar. Reviewer should verify expected WeekofMonth values.

4. **FA_Amount_Total is negated** — The SP uses `SUM(-ffca.Amount)`. Is the Amount column in Fact_FirstCustomerAction negative for opens? If so, negation is correct. If Amount is already positive, FA_Amount_Total would be negative. Verify semantics of Fact_FirstCustomerAction.Amount.

5. **Commented-out eMoney_Balance>50** — Both the monthly and daily cross-selling SPs have a commented-out `eMoney_Calculated_Balance` product category. This table also has no equivalent eMoney/balance metric. Was an eMoney feature planned for CryptoDashboard?

## UC Migration Status

- **UC Target**: `_Not_Migrated` — not found in `bronze_opsdb_dbo_vw_unitycatalog_mapping_tables` (based on pattern with sibling crypto tables)
- CLUSTERED INDEX on DateID distinguishes this from HEAP tables — may affect migration strategy
- Action: Verify UC status; if migrating, include ActiveHold scalar semantics in UC documentation

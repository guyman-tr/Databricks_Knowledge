# Review Needed: BI_DB_dbo.BI_DB_Capital_Guarantee

**Generated:** 2026-04-21 | **Batch:** 19 | **Reviewer:** —

## Tier 2 Items (Reviewer Verification Needed)

- [ ] **ActionTypeID=15 meaning**: The SP uses `Fact_CustomerAction WHERE ActionTypeID=15` to build the #Mirror exclusion list. What does ActionTypeID=15 represent? The exclusion logic implies it is a disqualifying event for the popular investor (e.g., exited the program, was removed, or triggered a specific condition). Confirm with CRM/Product team.
- [ ] **ParentCID mapping**: The SP hardcodes `ParentCID IN (4657429, 4657433, 4657444)`. Confirm these map to GainersQtr, ActiveTraders, and SharpTraders respectively. Are these the only three popular investors in the Capital Guarantee program?
- [ ] **Guarantee terms**: What exactly was the Capital Guarantee product — did eToro promise customers full capital recovery, or only partial protection up to a cap? The PnL column tracks negative exposure, but the guarantee payout rules determine the actual liability.
- [ ] **OpenDateID window (20200105–20200131)**: Confirms the guarantee was offered only to customers who started copying in this specific 3-week window. Was this intentional (a launch promotion), and are all qualifying customers captured?
- [ ] **INACTIVE status**: Table last updated 2023-03-12. Has the SP been decommissioned, or was this a deliberate end to data collection? Confirm whether any archival process ran, or if the guarantee simply expired with no further tracking needed.

## Potential Data Quality Issues

- **Mixed open/closed P&L**: The PnL column mixes realized (NetProfit from Dim_Position for closed positions) and mark-to-market (PositionPnL from BI_DB_PositionPnL for open positions). Historical rows from 2020–2022 may have had different position states at the time of capture vs now. Do not rerun the SP against historical dates and expect consistent results.
- **CID can appear multiple times**: One customer following two or more of the three popular investors will have multiple rows per Date (one per MirrorID). Summing PnL by CID without also grouping by MirrorID will double-count.
- **Regulation reflects ETL run date**: Regulation is from BI_DB_CIDFirstDates.RegulationID at time of SP execution, not at the time of the mirror event. For the 2020–2023 data, customer regulatory assignments may have changed.
- **Table is historical/inactive**: Querying this table for "current" data will yield no results after 2023-03-11. Downstream code that does not account for the inactive status may silently return incomplete results.

## Open Questions

1. Was any financial settlement or payout triggered by this table's data? What business process consumed the guarantee exposure numbers?
2. Are there related tables or reports (e.g., BI_DB_Capital_Guarantee_Panel written by SP_Capital_Guarantee_Panel) that extend or complement this data?
3. Why does the date range stop in March 2023? Was the guarantee contractually terminated, or did all affected mirrors close (PnL went non-negative)?
4. Are the 135,660 rows unique CID × MirrorID × Date combinations, or is there any deduplication concern?

## Corrections Log

*No corrections applied.*

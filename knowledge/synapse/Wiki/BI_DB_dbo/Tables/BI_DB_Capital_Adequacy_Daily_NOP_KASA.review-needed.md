# Review Needed: BI_DB_dbo.BI_DB_Capital_Adequacy_Daily_NOP_KASA

**Generated:** 2026-04-21 | **Batch:** 19 | **Reviewer:** —

## Tier 2 Items (Reviewer Verification Needed)

- [ ] **K-ASA definition**: Confirm "K-ASA" is the correct capital metric name for this table's NOP data. The table name suffix "KASA" may refer to a specific regulation, internal code, or abbreviation. What regulatory framework/article defines the NOP capital requirement tracked here?
- [ ] **Real_CFD='Real' semantics**: Confirm the exact meaning of the Real_CFD dimension from Dim_Instrument. Does 'Real' mean live-account CFD positions (vs demo), or real instruments (vs synthetic/exotic)? This affects interpretation of what is excluded from this table.
- [ ] **Manual_Copy values**: What are the exact values in the Manual_Copy column within this table? The DDL shows varchar(6) NOT NULL — confirm observed values and their meaning (e.g., 'Manual' vs 'Copy', or 'Real' vs 'Copy').
- [ ] **Total_NOP computation**: Confirm that Total_NOP represents the NET open position (long minus short) rather than gross. If it is gross NOP, the query advisory warning about negative values needs correction.
- [ ] **Regulation scope**: Unlike Daily_Equity which filters to RegulationID IN(1,2,4,5,10), does Daily_NOP_KASA include all regulations or is there a similar filter? The SP analysis suggests it may include all regulated jurisdictions (not just 5). Confirm.

## Potential Data Quality Issues

- **Real_CFD always 'Real'**: The SP filters Real_CFD='Real', so this column carries no analytic variance within the table. Downstream consumers may assume this means something different or accidentally join on it across tables where the value varies.
- **Historical backfill**: Rows with Date < 2022-02-23 carry UpdateDate = '2022-02-23' (backfill timestamp). Cannot distinguish backfilled from live rows by UpdateDate alone for the period starting 2022-02-23.
- **Total_NOP sign convention**: Negative values expected for net short positions. Downstream consumers must handle negative values explicitly to avoid understating absolute NOP exposure.
- **Regulation is current-time snapshot**: Regulation and Player_Status reflect the ETL run date, not historical assignment. Time-series analysis by Regulation may be misleading.

## Open Questions

1. What downstream capital adequacy reports consume this table? (Not confirmed via Atlassian MCP)
2. How does this table's NOP relate to the hedging P&L reported elsewhere — is Total_NOP the firm-side NOP or the client-side NOP?
3. Are there rows with IsFuture = NULL? If so, what do they represent (instruments with missing metadata in Dim_Instrument)?
4. Is there a coverage gap between what BI_DB_PositionPnL tracks and the firm's actual open positions? Are all instrument types always present?

## Corrections Log

*No corrections applied.*

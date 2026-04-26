# Review Needed: BI_DB_dbo.BI_DB_Capital_Adequacy_Monthly_NOP

**Generated:** 2026-04-21 | **Batch:** 19 | **Reviewer:** —

## Tier 2 Items (Reviewer Verification Needed)

- [ ] **K-AUM definition**: Confirm "K-AUM" is the correct capital metric name for this table. The monthly grain + copy-position filter suggests an Assets Under Management-related capital requirement, but the exact regulatory framework/article should be confirmed.
- [ ] **Manual_Copy='Copy' semantics**: Confirm that 'Copy' in Dim_Instrument.Manual_Copy refers specifically to social/copy-trading positions (followers replicating a popular investor), and not some other instrument classification. What is the full set of Manual_Copy values in Dim_Instrument?
- [ ] **No IsFuture column**: The Monthly_NOP DDL omits IsFuture while both Daily sibling tables include it. Confirm this is intentional — is futures-vs-spot breakdown not required for the monthly copy-position capital report?
- [ ] **Monthly vs daily ETL frequency**: Is SP_Risk_Capital_Adequacy run daily (deleting/reinserting for each @date), or only at month-end for this table? If daily, does each run replace the prior run's data for the same month (via YearMonthID key), or do multiple rows accumulate per month?
- [ ] **Real_CFD values**: What exact values appear in Real_CFD for copy instruments? Sample data showed 'CFD' and 'Real' — confirm these are the only two values and document their meaning in the context of copy trading.

## Potential Data Quality Issues

- **Manual_Copy always 'Copy'**: The SP filters Manual_Copy='Copy', so this column carries no analytic variance within the table. Downstream consumers may not realize all rows are pre-filtered.
- **No IsFuture column**: Unlike the daily sibling tables, futures vs spot NOP cannot be distinguished here. If regulatory requirements change to require this breakdown for copy positions, a DDL change and SP rewrite are needed.
- **Historical backfill**: Rows with Date < 2022-02-23 carry UpdateDate = '2022-02-23' (backfill timestamp). Cannot distinguish backfilled from live rows.
- **Total_NOP sign convention**: Negative values expected for net short positions. Downstream consumers must handle negative values explicitly.
- **YearMonthID as cluster key**: Unlike the daily sibling tables clustered on Date, this table clusters on YearMonthID. Queries filtering on Date rather than YearMonthID will not benefit from the clustered index.

## Open Questions

1. What downstream capital adequacy reports consume this table? (Not confirmed via Atlassian MCP)
2. If the ETL runs daily, does each daily run represent a mid-month snapshot, and are prior snapshots overwritten? Or is only the final month-end run retained?
3. Does the monthly copy-position NOP need to reconcile against the corresponding rows in Daily_NOP_KASA for the same month? Are copy instruments (Manual_Copy='Copy') entirely excluded from Daily_NOP_KASA (Real_CFD='Real')?
4. Is there a scenario where a position has both Manual_Copy='Copy' AND Real_CFD='Real'? If so, would it appear in both this table and Daily_NOP_KASA?

## Corrections Log

*No corrections applied.*

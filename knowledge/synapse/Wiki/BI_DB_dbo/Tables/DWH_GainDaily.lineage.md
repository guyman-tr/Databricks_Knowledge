# BI_DB_dbo.DWH_GainDaily — Column Lineage

## Source Objects

| Source | Schema | Role | Confidence |
|--------|--------|------|------------|
| External_TradeGain_Ranking_Compound_Gain_Completed | BI_DB_dbo (External) | Production TradeGain service compound gain by interval type | Tier 1 — SP code confirmed |
| External_TradeGain_Ranking_Execution | BI_DB_dbo (External) | Execution tracking (completed runs for ObjectID=4) | Tier 1 — SP code confirmed |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| Date | — | @gain_dt SP parameter | passthrough |
| CID | Compound_Gain_Completed | CID | passthrough |
| Gain_w | Compound_Gain_Completed | Gain WHERE IntervalTypeID=7 | pivot (weekly) |
| Gain_m | Compound_Gain_Completed | Gain WHERE IntervalTypeID=106 | pivot (monthly) |
| Gain_q | Compound_Gain_Completed | Gain WHERE IntervalTypeID=108 | pivot (quarterly) |
| Gain_h | Compound_Gain_Completed | Gain WHERE IntervalTypeID=109 | pivot (half-yearly) |
| Gain_y | Compound_Gain_Completed | Gain WHERE IntervalTypeID=110 | pivot (yearly) |
| UpdateDate | — | — | GETDATE() |
| Gain_MTD | Compound_Gain_Completed | Gain WHERE IntervalTypeID=101 | pivot (month-to-date) |
| Gain_YTD | Compound_Gain_Completed | Gain WHERE IntervalTypeID=103 | pivot (year-to-date) |
| Gain_d | Compound_Gain_Completed | Gain WHERE IntervalTypeID=1 | pivot (daily) |
| Gain_QTD | Compound_Gain_Completed | Gain WHERE IntervalTypeID=102 | pivot (quarter-to-date) |
| ExecutionID | Compound_Gain_Completed | ExecutionID | passthrough — latest completed execution |

## Lineage Notes

- All gain columns are from the same source table, pivoted by IntervalTypeID.
- Only Gain <> 0 rows are included (zero gains excluded).
- ExecutionID links to the TradeGain Ranking service execution that computed these gains.
- ObjectID=4 in Ranking_Execution identifies the compound gain calculation type.
- UC Target: _Not_Migrated.

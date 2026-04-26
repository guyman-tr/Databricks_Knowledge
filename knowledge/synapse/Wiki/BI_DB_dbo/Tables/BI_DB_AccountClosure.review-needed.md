# Review Notes — BI_DB_dbo.BI_DB_AccountClosure

**Batch**: 16 | **Generated**: 2026-04-21 | **Reviewer**: CS / Operations Team

---

## Tier 4 Items

None. All columns are Tier 1 (CID via Customer.CustomerStatic) or Tier 2 (SP-computed/join-enriched).

---

## Open Questions for Reviewer

1. **Dim_Regulation join column**: The SP joins `Dim_Regulation` using `p.RegulationID = dr.ID` (not `dr.DWHRegulationID` as used in most other BI_DB SPs). Is `dr.ID` the correct join key? Verify that regulation names are accurately assigned — the distribution (CySEC 64%, FCA 15%) looks plausible but should be confirmed.

2. **INNER JOIN on BI_DB_CID_DailyPanel_FullData**: Customers in closure status who are absent from BI_DB_CID_DailyPanel_FullData for the run DateID are silently excluded. Quantify: how many closure-status customers are missing from DailyPanel? Are there customers who should appear but don't?

3. **PendingClosureChangeDateID semantics**: The description states this is the date the customer "first entered their current closure status." Confirm this interpretation is correct for the CS workflow — the SP's ROW_NUMBER logic picks the first occurrence of each status, then the most recent status's first occurrence. Does CS expect the first-ever assignment date, or the most recent transition date?

4. **Very old PendingClosureChangeDate values**: The sample shows dates as far back as 2021-06-03 (PendingClosureChangeDateID=20210603). These customers have been in closure status for 4+ years without completing the closure. Is this a data quality concern or expected for certain customer segments?

---

## Known Data Quirks

- **Single date only** — all rows have the same Date (run date). No historical retention.
- **CID uniqueness** — DISTINCT guaranteed by ROW_NUMBER logic in SP. No PK constraint enforced.
- **Bronze-heavy** — 97% of closure customers are Bronze tier. Expected for the population but worth noting for CS prioritisation.
- **CLUSTERED INDEX (Date ASC)** — no selectivity since all rows share the same Date value. Effectively a HEAP for query purposes.

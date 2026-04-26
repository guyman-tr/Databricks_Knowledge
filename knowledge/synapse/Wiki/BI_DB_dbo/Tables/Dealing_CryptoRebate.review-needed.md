# Review Needed: BI_DB_dbo.Dealing_CryptoRebate

**Generated**: 2026-04-23
**Pipeline Phase**: Post-11 review sidecar
**Overall Confidence**: HIGH

---

## Data Quality Observations

1. **`UPdatedate` column name typo**: The DDL has `[UPdatedate]` (uppercase UP) instead of the conventional `UpdateDate`. This is a production DDL typo preserved in Synapse. Analysts must use exact case. No fix applied.

2. **TotalVolume double-counts positions**: The SP intentionally calculates `TotalVolume = OpenedVolume + ClosedVolume`, which counts each position twice — once at open rate, once at close rate. This is by rebate program design (turnover-based) but is non-obvious and can confuse analysts comparing to `Dim_Position` volumes.

3. **`BelowMinVolume` computed but not stored**: The SP calculates `BelowMinVolume` (volume ≤ $50K) in `#BracketsVolume` but does NOT insert it into the target table. Members with TotalVolume ≤ $50K appear in the table with all bracket columns = 0 and TotalRebate = 0.

---

## Open Questions

1. **Country exclusion list governance**: The list of excluded countries (Austria, Finland, Greece, Luxembourg, Malta, Portugal, Sweden, UK) is hardcoded in the SP. France was added 2025-10-20. Is there a business/regulatory document that defines the current list?

2. **Bracket tier thresholds**: The $50K/$1M/$5M boundaries and 0.15%/0.25%/0.50% rates are hardcoded. Where is the business definition of these tiers documented?

3. **GuruStatus codes**: The SP excludes GuruStatusID IN (2,3,4,5,6). What do values 0 and 1 represent? (Likely: 0=not a PI, 1=pending/applied — these are included in the rebate.)

---

## Verification Status

| Check | Status | Notes |
|-------|--------|-------|
| DDL read from SSDT | VERIFIED | 19 cols confirmed |
| SP logic traced | VERIFIED | Full SP read, all temp tables traced |
| Live data sampled | VERIFIED | 210K rows, 49 months, Mar 2026 = 5,853 members |
| CID T1 upstream fidelity | VERIFIED | Customer.CustomerStatic verbatim match |
| Club values | VERIFIED | "1 Diamond" and "1 Platinum Plus" confirmed in live data |
| Regulation distribution | VERIFIED | 12 values, CySEC dominant (~62%) |
| UC mapping | CHECKED | Not in generic pipeline mapping — _Not_Migrated |

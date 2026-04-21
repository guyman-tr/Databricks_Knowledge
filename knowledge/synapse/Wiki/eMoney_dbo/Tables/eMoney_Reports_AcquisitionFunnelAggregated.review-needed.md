# Review Needed — eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated

**Generated**: 2026-04-21 | **Batch**: 12 | **Quality**: 9.0/10

---

## Open Questions

1. **FunnelStage string values**: The 9 hardcoded stage labels match column names in AcquisitionFunnel. Are there any additional stages planned? If a new flag is added to AcquisitionFunnel, the SP needs a new UNION ALL block to include it here.
2. **No date column**: This table cannot be used for time-series analysis. Is there a historical version that preserves daily snapshots? If so, it should be documented.
3. **207 country/club combinations**: With 34 countries × 6 clubs = 204 expected. The 3 extra combinations may be from countries that were historically live but rolled back, or from the Country override (eMoney RegCountry vs rollout country). Worth investigating the 3 extra entries.
4. **Cross-validation**: Are there automated checks comparing SUM(FunnelCount) for VerifiedFTD against COUNT(*) from AcquisitionFunnel?

---

## No Tier 1 Columns

All columns are Tier 2 — this is a pure aggregation with no direct production source column passthrough. No upstream wiki comparison required.

---

## No Structural Issues

All 5 elements present. FunnelStage inline values documented (9 distinct values confirmed by live query).

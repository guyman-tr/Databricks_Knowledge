# Review Sidecar: BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts

## Verification Status

| Item | Status | Notes |
|------|--------|-------|
| Writer SP | Verified | `SP_DDR_Fact_Trading_Volumes_And_Amounts` — `#data` from `Function_Trading_Volume_PositionLevel`, GROUP BY + SUM |
| Primary lineage | Verified | Single TVF source for all measures and dimensions |
| Distribution / CCI | Verified | HASH(RealCID), clustered columnstore from DDL |
| QA path | Verified | Optional `BI_DB_VolumeQA` when object exists |
| Downstream consumers | Not found | No references in DataPlatform SSDT repo beyond writer |

## Unverified Items

| Topic | Tier | Issue |
|-------|------|-------|
| `IsOpenedFromIBAN` varchar domain | T4 | Values and semantics (free text vs coded) — align with `Function_Trading_Volume_PositionLevel` |
| Volume unit / scaling | T4 | “Position value” definition lives inside the function — not fully documented here |
| TotalVolume vs VolumeOpen + VolumeClose | T4 | After SUM aggregation, validate reconciliation rules with function |
| NetInvestedAmount sign | T4 | Confirm open minus close interpretation at position level |
| Downstream reports | T4 | Consumers likely outside cloned repo — grep other repos or UC |

## Quality Notes

- **Simpler ETL** than revenue fact — remaining risk is **inside** `Function_Trading_Volume_PositionLevel` (not expanded in this sidecar).
- SP author flagged **timing/QA** issues — use `BI_DB_VolumeQA` when deployed for investigation.

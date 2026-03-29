# Column Lineage — DWH_dbo.V_M2M_Date_DateRange

## Source

| Property | Value |
|----------|-------|
| **Base Tables** | DWH_dbo.Dim_Range, DWH_dbo.Dim_Date |
| **View Type** | Fan-out JOIN (range inequality) |
| **JOIN** | `Dim_Range.FromDateID <= Dim_Date.DateKey AND Dim_Range.ToDateID >= Dim_Date.DateKey` |

## Column Mapping

| # | View Column | Type | Source Table | Source Column | Transform | Upstream Wiki |
|---|------------|------|-------------|---------------|-----------|---------------|
| 1 | DateRangeID | bigint | DWH_dbo.Dim_Range | DateRangeID | Pass-through | [Dim_Range.md](../Tables/Dim_Range.md) — Tier 1 inherited |
| 2 | DateKey | int | DWH_dbo.Dim_Date | DateKey | Pass-through (filtered by range) | No wiki (Dim_Date not yet documented) |
| 3 | FullDate | date | DWH_dbo.Dim_Date | FullDate | Pass-through (filtered by range) | No wiki (Dim_Date not yet documented) |

## Upstream Dependency Graph

```
DWH_dbo.V_M2M_Date_DateRange
├── DWH_dbo.Dim_Range [WIKI: ✓ Dim_Range.md]
│   ├── DateRangeID → V.DateRangeID (pass-through)
│   ├── FromDateID  → JOIN condition only (not output)
│   └── ToDateID    → JOIN condition only (not output)
└── DWH_dbo.Dim_Date [WIKI: ✗ not documented]
    ├── DateKey     → V.DateKey (pass-through, range-filtered)
    └── FullDate    → V.FullDate (pass-through, range-filtered)
```

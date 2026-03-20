# Column Lineage — DWH_dbo.V_Fact_SnapshotEquity

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| DateKey | Dim_Date.DateKey | `BETWEEN Dim_Range.FromDateID AND Dim_Range.ToDateID` — one row per date in range |
| All 33 Fact columns | Fact_SnapshotEquity (a.*) | Direct passthrough |

## Join Path
```
Fact_SnapshotEquity.DateRangeID → Dim_Range.DateRangeID → Dim_Date.DateKey BETWEEN FromDateID AND ToDateID
WHERE DateKey < today
```

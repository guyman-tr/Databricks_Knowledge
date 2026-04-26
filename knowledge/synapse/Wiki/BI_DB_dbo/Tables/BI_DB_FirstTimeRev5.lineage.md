# BI_DB_dbo.BI_DB_FirstTimeRev5 — Column Lineage

## Writer SP
`BI_DB_dbo.SP_FirstTimeRev5`

## Source Tables
| Source Table | Schema | Join/Usage |
|---|---|---|
| DWH_dbo.Dim_Position | DWH_dbo | CID, PositionID, Commission, CommissionOnClose, OpenOccurred, CloseOccurred |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Date | — | — | ETL-computed: `@Yesterday` parameter value |
| Timestamp | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | CASE: if CloseDateID != 0 then CloseOccurred else OpenOccurred — the occurrence datetime of the position event that pushed cumulative commission over $5 |
| CID | DWH_dbo.Dim_Position | CID | Passthrough |
| PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough — the specific position that caused cumulative commission to exceed $5 |
| AggregatedCommission | DWH_dbo.Dim_Position | Commission, CommissionOnClose | ETL-computed: running SUM(CASE WHEN CloseDateID != 0 THEN CommissionOnClose ELSE Commission END) OVER(PARTITION BY CID ORDER BY Occurred) — cumulative commission at the threshold-crossing position |
| DateID | — | — | ETL-computed: CONVERT(VARCHAR(8), @Yesterday, 112) — YYYYMMDD int of the processing date |
| UpdateDate | — | — | ETL metadata: GETDATE() |

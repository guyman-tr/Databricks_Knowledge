# Column Lineage: BI_DB_dbo.BI_DB_M_SB_Fiktive_Table

## Writer SP
`BI_DB_dbo.SP_M_Notifications_by_LifeStage` (stub — prints '1' and exits)

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| tmp_column | N/A | N/A | Placeholder column. The writer SP is a no-op stub (print('1')). No data is written. |

## Source Objects
None — the SP does not read from or write to any tables.

## Notes
This is a **fiktive (placeholder) table** with a single varchar(1) column and 0 rows. It exists as a Service Broker scheduling anchor — the OpsDB configuration maps SP_M_Notifications_by_LifeStage to this table, but the SP itself is a no-op. The table is never populated.

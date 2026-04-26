# BI_DB_dbo.BI_DB_Dummy — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Dummy` — no-op SP (PRINT 'Hello World'). Does not write to the table.

## Source Objects
None — table is never populated.

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| CID | None | N/A | Column exists in DDL but is never populated. SP_Dummy does not INSERT any data. |

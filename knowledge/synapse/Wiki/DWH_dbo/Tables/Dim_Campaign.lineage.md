# Lineage — DWH_dbo.Dim_Campaign

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | Unknown (ETL INSERT is commented out) |
| **Status** | **DEAD** — no active data ingestion |

## ETL Chain

```
(unknown source — ETL commented out)
  → SP_Dictionaries_DL_To_Synapse
    → TRUNCATE TABLE only (INSERT is commented out)
    → Single N/A placeholder row inserted: (0, 'N/A', ...)
      → DWH_dbo.Dim_Campaign (1 row)
```

---

*Generated: 2026-03-18*

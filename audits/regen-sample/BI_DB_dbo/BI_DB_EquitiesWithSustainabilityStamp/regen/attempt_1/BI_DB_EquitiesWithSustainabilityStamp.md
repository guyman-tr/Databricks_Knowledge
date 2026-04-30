# BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp

> 218-row reference table listing equities stamped as EU sustainability-friendly, sourced from a Fivetran-synced Google Sheet joined to DWH_dbo.Dim_Instrument for InstrumentID resolution, loaded via truncate-and-reload by SP_Equities_With_Sustainability_Stamp. Last refreshed 2024-01-30.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Sheet (QSR Sustainability List) via SP_Equities_With_Sustainability_Stamp |
| **Refresh** | On-demand truncate-and-reload via SP_Equities_With_Sustainability_Stamp |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not in Generic Pipeline mapping |

---

## 1. Business Meaning

BI_DB_EquitiesWithSustainabilityStamp is a 218-row reference table that identifies equities stamped as sustainability-friendly under EU regulation. The data originates from a manually maintained Google Sheet synced to Synapse via Fivetran into the external table `BI_DB_dbo.External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp`.

The writer SP (`SP_Equities_With_Sustainability_Stamp`) performs a full truncate-and-reload: it joins the Fivetran external table to `DWH_dbo.Dim_Instrument` on `ISINCode = ISIN` to resolve each equity's InstrumentID. The table contains 178 distinct tickers/ISINs (some equities share the same ticker across different ISINs). All 218 rows carry an identical UpdateDate of 2024-01-30, indicating the table has not been refreshed since that date.

The SP header notes this sustainability stamp will eventually be implemented directly in the production database, but for now the Google Sheet remains the source of truth.

---

## 2. Business Logic

### 2.1 ISIN-to-InstrumentID Resolution

**What**: Maps each sustainability-stamped equity to its eToro platform InstrumentID via ISIN matching.

**Columns Involved**: `ISIN`, `InstrumentID`

**Rules**:
- JOIN condition: `DWH_dbo.Dim_Instrument.ISINCode = External_table.ISIN`
- Only equities present in both the Google Sheet AND Dim_Instrument appear in the output
- Equities in the sheet with no matching ISIN in Dim_Instrument are silently dropped (INNER JOIN)

### 2.2 Truncate-and-Reload Pattern

**What**: Full table replacement on each SP execution.

**Columns Involved**: All

**Rules**:
- TRUNCATE TABLE runs first, then INSERT…SELECT
- No incremental/delta logic — every run replaces all rows
- UpdateDate is set to GETDATE() at execution time (same value for all rows in a load)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with a CLUSTERED INDEX on InstrumentID. For a 218-row table, distribution strategy is immaterial — the entire table fits in a single distribution segment. The clustered index supports efficient point lookups by InstrumentID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is instrument X sustainability-stamped? | `WHERE InstrumentID = @id` — clustered index seek |
| List all sustainability equities by ticker | `SELECT * ORDER BY Ticker` |
| Check if an ISIN is sustainability-stamped | `WHERE ISIN = @isin` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON e.InstrumentID = di.InstrumentID` | Enrich with instrument metadata (exchange, symbol, asset class) |
| BI_DB reporting tables | `ON r.InstrumentID = e.InstrumentID` | Filter reporting to sustainability-stamped equities only |

### 3.4 Gotchas

- **Stale data**: All rows have UpdateDate = 2024-01-30 — the table has not been refreshed since January 2024. Verify with the QSR team whether the Google Sheet is still maintained.
- **INNER JOIN drops unmatched ISINs**: If a sustainability equity exists in the Google Sheet but its ISIN is not in Dim_Instrument, it will not appear here. No orphan tracking.
- **178 distinct tickers for 218 rows**: Some tickers map to multiple ISINs (e.g., dual-listed equities).
- **No Generic Pipeline mapping**: This table is not exported to Unity Catalog.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki — description copied as-is |
| Tier 2 | ETL-computed in SP_Equities_With_Sustainability_Stamp — transform documented from SP code |
| Tier 3 | Source identified but no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Ticker | varchar(100) | YES | Stock ticker symbol from the Fivetran-synced Google Sheet (QSR Sustainability List). Identifies the equity by its exchange ticker (e.g., "AAPL", "GOOG"). 178 distinct values across 218 rows. (Tier 3 — External_Bi_Output_Uploads_QSR_Sustainability_List, no upstream wiki) |
| 2 | ISIN | varchar(100) | YES | International Securities Identification Number from the Fivetran-synced Google Sheet. Used as the JOIN key to resolve InstrumentID via Dim_Instrument.ISINCode (e.g., "US0378331005" for Apple). 178 distinct values. (Tier 3 — External_Bi_Output_Uploads_QSR_Sustainability_List, no upstream wiki) |
| 3 | Name | varchar(100) | YES | Company/equity display name from the Fivetran-synced Google Sheet (e.g., "Apple", "Microsoft"). Human-readable label for the sustainability-stamped equity. (Tier 3 — External_Bi_Output_Uploads_QSR_Sustainability_List, no upstream wiki) |
| 4 | InstrumentID | int | YES | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. Passthrough from Dim_Instrument via JOIN on ISINCode = ISIN. (Tier 1 — Trade.GetInstrument) |
| 5 | UpdateDate | datetime | YES | ETL housekeeping timestamp. Set to GETDATE() at each SP_Equities_With_Sustainability_Stamp run. All rows share the same value per load. (Tier 2 — SP_Equities_With_Sustainability_Stamp) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| Ticker | External_Bi_Output_Uploads_QSR_Sustainability_List (Fivetran Google Sheet) | Ticker | Passthrough |
| ISIN | External_Bi_Output_Uploads_QSR_Sustainability_List (Fivetran Google Sheet) | ISIN | Passthrough |
| Name | External_Bi_Output_Uploads_QSR_Sustainability_List (Fivetran Google Sheet) | Name | Passthrough |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Dim-lookup via ISINCode = ISIN |
| UpdateDate | SP_Equities_With_Sustainability_Stamp | — | GETDATE() |

### 5.2 ETL Pipeline

```
Google Sheet (QSR Sustainability List — EU sustainability-stamped equities)
  |-- Fivetran sync ---|
  v
BI_DB_dbo.External_Bi_Output_Uploads_QSR_Sustainability_List_equities_with_sustainability_stamp
  |                                                          |
  |-- SP_Equities_With_Sustainability_Stamp (truncate-and-reload) ---|
  |   JOIN DWH_dbo.Dim_Instrument ON ISINCode = ISIN                 |
  v                                                                   v
BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp (218 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolved via ISIN match — instrument dimension lookup |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_RBSF | InstrumentID | Sustainability filter for RBSF reporting |
| BI_DB_dbo.SP_Q_QSR_New | InstrumentID | QSR sustainability equity filter |
| BI_DB_dbo.QST | InstrumentID | QST sustainability equity filter |

---

## 7. Sample Queries

### 7.1 List all sustainability-stamped equities
```sql
SELECT Ticker, ISIN, Name, InstrumentID
FROM BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp
ORDER BY Ticker
```

### 7.2 Check if a specific instrument is sustainability-stamped
```sql
SELECT e.Ticker, e.Name, di.InstrumentDisplayName, di.Exchange
FROM BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp e
JOIN DWH_dbo.Dim_Instrument di ON e.InstrumentID = di.InstrumentID
WHERE e.InstrumentID = 1001
```

### 7.3 Find sustainability equities not in the stamp table (gap analysis)
```sql
SELECT di.InstrumentID, di.Symbol, di.ISINCode
FROM DWH_dbo.Dim_Instrument di
WHERE di.InstrumentTypeID = 5  -- Stocks only
  AND di.ISINCode IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp e
    WHERE e.ISIN = di.ISINCode
  )
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 1 T1, 1 T2, 3 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp | Type: Table | Production Source: Fivetran Google Sheet (QSR Sustainability List) via SP_Equities_With_Sustainability_Stamp*

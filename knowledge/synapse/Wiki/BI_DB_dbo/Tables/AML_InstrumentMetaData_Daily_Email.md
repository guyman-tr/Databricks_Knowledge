# BI_DB_dbo.AML_InstrumentMetaData_Daily_Email

> Daily AML reference feed of all currently-tradable instruments that carry a valid ISIN code — the instrument universe monitored by the eToro AML/sanctions team via the daily email process.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.InstrumentMetaData |
| **Refresh** | Daily (OpsDB P0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Writer SP** | SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email |
| | |
| **UC Target** | pending |

---

## 1. Business Meaning

`BI_DB_dbo.AML_InstrumentMetaData_Daily_Email` is the daily snapshot of all eToro instruments that are (a) currently tradable and (b) carry a valid, non-empty ISIN code. It serves as the reference universe for the AML team's daily email process, which monitors instrument-level ISIN data for sanctions screening, trade surveillance, and AML compliance purposes.

The table is rebuilt daily via `SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email` (Author: Eyal Boas, 2025-02-25): the SP applies a strict quality filter to `External_etoro_Trade_InstrumentMetaData` (the Bronze lake mirror of `etoro.Trade.InstrumentMetaData`), retaining only the 12,124 tradable instruments whose ISINs pass six validity checks. This filtered set is then forwarded to the AML email pipeline.

Its sibling table, `AML_InstrumentMetaData_Daily_Email_DayToDay_Changes`, captures instruments whose ISIN changed since the previous day by comparing today's snapshot to yesterday's historical snapshot — enabling the AML team to react promptly when ISIN identifiers are reassigned or corrected.

The ETL pipeline:

```
etoro.Trade.InstrumentMetaData (production SQL Server)
  │  Generic Pipeline (daily, Parquet)
  ▼
Bronze/etoro/Trade/InstrumentMetaData (Azure Data Lake)
  │  External Table reference
  ▼
BI_DB_dbo.External_etoro_Trade_InstrumentMetaData (Synapse External Table)
  │  SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email
  │  Filter: Tradable=1, ISINCode valid (not NULL/empty/'null'/'0'/'na'/'n.a'/'n.a.')
  ▼
BI_DB_dbo.AML_InstrumentMetaData_Daily_Email (TRUNCATE + INSERT daily)
```

---

## 2. Business Logic

### 2.1 ISIN Validity Filter

**What**: Only instruments with a meaningful, parseable ISIN code are retained.

**Rules** (applied in the SP's WHERE clause on the temp table built from `External_etoro_Trade_InstrumentMetaData`):
- `ISINCode IS NOT NULL`
- `TRIM(LOWER(ISINCode)) NOT IN ('', 'null', '0', 'na', 'n.a', 'n.a.')`
- `Tradable = 1` (instrument is currently open for trading)

**Outcome**: As of 2026-04-23, 12,124 instruments pass these filters. All rows in this table have a non-NULL, non-empty ISINCode — despite the column being declared NULLABLE in the DDL.

### 2.2 Shared ISINs

**What**: A single ISIN code can appear across multiple InstrumentIDs (up to 4 per ISIN observed in practice). This occurs for multi-class shares and futures contracts with different expiry months that share a root ISIN.

**Outcome**: 11,384 distinct ISINs across 12,124 rows — 740 "extra" rows are multi-instrument ISIN groups. This means the table is NOT unique by ISINCode; it IS unique by InstrumentID.

### 2.3 TRUNCATE + INSERT Pattern

The SP performs a full TRUNCATE then bulk INSERT on each daily run. No incremental merge or delta logic. The table always reflects the current-day tradable-instrument universe with valid ISINs at the time the SP executes.

---

## 3. Query Advisory

- **ISINCode is never NULL in this table** despite the DDL allowing NULL — the SP filter guarantees it. No NULL guards needed on ISINCode.
- **Table is unique by InstrumentID, not by ISINCode** — multi-instrument ISIN groups mean ISINCode lookups may return up to 4 rows.
- **For current-day ISIN lookup**: query this table directly. For historical ISIN values or yesterday's data, use `AML_InstrumentMetaData_Daily_Email_DayToDay_Changes` or `External_etoro_History_InstrumentMetaData`.
- **ROUND_ROBIN HEAP**: no clustered index. Point lookups by InstrumentID scan the full 12,124 rows. For frequent InstrumentID lookups, join to `DWH_dbo.Dim_Instrument` (REPLICATE, clustered on InstrumentID) which supports fast lookups.
- **12,124 rows is small**: full-table scans are fast and acceptable for ad-hoc queries.

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. In this table: always > 0; SP filter (Tradable=1) excludes the ID=0 sentinel. (Tier 1 — DWH_dbo.Dim_Instrument wiki, originally Trade.Instrument) |
| 2 | InstrumentDisplayName | nvarchar(max) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than the internal Name field (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without InstrumentMetaData entries. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 3 | ISINCode | nvarchar(max) | YES | International Securities Identification Number — 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). Country prefix + national code + check digit. **Never NULL in this table** — the SP filter guarantees Tradable=1 and a valid non-empty ISIN before insertion. 11,384 distinct ISINs across 12,124 rows; up to 4 instruments share a single ISIN (multi-class shares or futures expiries). (Tier 1 — DWH_dbo.Dim_Instrument wiki; AML SP filter note Tier 2) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| InstrumentID | etoro.Trade.InstrumentMetaData | InstrumentID | Passthrough |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData | InstrumentDisplayName | Passthrough |
| ISINCode | etoro.Trade.InstrumentMetaData | ISINCode | Passthrough; SP filter removes NULLs and 6 invalid string patterns |

### 5.2 ETL Pipeline

```
[Production]
etoro.Trade.InstrumentMetaData
    │  Generic Pipeline — daily Parquet export
    ▼
[Data Lake]
Bronze/etoro/Trade/InstrumentMetaData
    │  External Table definition (DATA_SOURCE = internal-sources)
    ▼
[Synapse]
BI_DB_dbo.External_etoro_Trade_InstrumentMetaData (External Table, 37 cols)
    │  SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email
    │  #InstrumentMetaData temp table: WHERE Tradable=1 AND ISINCode valid
    │  TRUNCATE + INSERT
    ▼
BI_DB_dbo.AML_InstrumentMetaData_Daily_Email
(ROUND_ROBIN HEAP — 12,124 rows as of 2026-04-23)
```

---

## 6. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| DWH_dbo.Dim_Instrument | InstrumentID | Full instrument metadata (name, type, exchange, market cap, IsMajor, CUSIP). REPLICATE — no shuffle cost. |
| BI_DB_dbo.AML_InstrumentMetaData_Daily_Email_DayToDay_Changes | InstrumentID | Sibling: records instruments whose ISIN changed since yesterday; compare to detect ISIN mutations |
| BI_DB_dbo.External_etoro_Trade_InstrumentMetaData | InstrumentID | Source external table; superset of this table (includes non-tradable and invalid-ISIN instruments) |

---

## 7. Sample Queries

```sql
-- Full current AML instrument universe
SELECT InstrumentID, InstrumentDisplayName, ISINCode
FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email]
ORDER BY InstrumentID;

-- Enrich with instrument type and exchange via Dim_Instrument
SELECT e.InstrumentID, e.ISINCode, e.InstrumentDisplayName,
       d.InstrumentType, d.Exchange, d.Symbol
FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email] e
JOIN [DWH_dbo].[Dim_Instrument] d ON e.InstrumentID = d.InstrumentID
WHERE d.InstrumentType = 'Stocks'
ORDER BY e.InstrumentID;

-- Instruments with shared ISINs (multi-class / futures expiry groups)
SELECT ISINCode, COUNT(*) AS InstrumentCount
FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email]
GROUP BY ISINCode
HAVING COUNT(*) > 1
ORDER BY InstrumentCount DESC;

-- ISIN lookup (AML sanctions check pattern)
SELECT e.InstrumentID, e.InstrumentDisplayName
FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email] e
WHERE e.ISINCode = 'US0378331005';  -- Apple ISIN
```

---

## 8. Atlassian Sources

No Confluence pages identified for this specific table. Consult the DATA space in Confluence for AML/Sanctions domain documentation and the instrument monitoring email process specifications.

---

*Tier breakdown: InstrumentID (Tier 1 — DWH_dbo.Dim_Instrument wiki) | InstrumentDisplayName (Tier 1 — DWH_dbo.Dim_Instrument wiki) | ISINCode (Tier 1 — DWH_dbo.Dim_Instrument wiki + Tier 2 AML SP filter note)*
*Quality score: 9.0/10 (Phase 16 adversarial evaluation, 2026-04-23)*

# BI_DB_dbo.AML_InstrumentMetaData_Daily_Email_DayToDay_Changes

> Event-driven daily AML feed capturing instruments whose ISIN code changed since the previous day — enabling the AML team to react immediately when ISIN identifiers are reassigned, corrected, or replaced.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.InstrumentMetaData (current) + etoro.Trade.History_InstrumentMetaData (yesterday) |
| **Refresh** | Daily (OpsDB P0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Writer SP** | SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email_DayToDay_Changes |
| | |
| **UC Target** | pending |

---

## 1. Business Meaning

`BI_DB_dbo.AML_InstrumentMetaData_Daily_Email_DayToDay_Changes` is the companion table to `AML_InstrumentMetaData_Daily_Email`. Where the parent table provides the full current-day universe of ISIN-bearing tradable instruments, this table surfaces only the instruments whose ISIN code changed overnight — comparing today's live snapshot against yesterday's historical state.

The table is rebuilt daily by `SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email_DayToDay_Changes` (Author: Eyal Boas, 2025-04-27). The SP constructs two snapshots: `#currentIsins` from `External_etoro_Trade_InstrumentMetaData` (today, Tradable=1, valid ISIN) and `#yesterdayIsins` from `External_etoro_History_InstrumentMetaData` (the earliest yesterday version of each instrument, using `SysEndTime >= yesterday` + row_number window). An INNER JOIN on InstrumentID retains only rows where the ISINCode values differ between the two snapshots.

The result is an AML change-log — typically empty on days with no ISIN mutations and populated when instrument ISINs are corrected, reassigned due to corporate actions (mergers, spinoffs), or updated for regulatory reasons. The AML team uses this to alert on any instruments whose regulatory identifier changed.

The ETL pipeline:

```
[Today's ISINs]
etoro.Trade.InstrumentMetaData (production SQL Server)
    │  Generic Pipeline (daily, Parquet)
    ▼
Bronze/etoro/Trade/InstrumentMetaData (Azure Data Lake)
    │  External Table reference
    ▼
BI_DB_dbo.External_etoro_Trade_InstrumentMetaData
    │  WHERE Tradable=1, ISINCode valid → #currentIsins

[Yesterday's ISINs]
etoro.Trade.History_InstrumentMetaData (production temporal history)
    │  Generic Pipeline (daily, Parquet)
    ▼
Bronze/etoro/Trade/History_InstrumentMetaData (Azure Data Lake)
    │  External Table reference
    ▼
BI_DB_dbo.External_etoro_History_InstrumentMetaData
    │  WHERE SysEndTime >= yesterday
    │  row_number() OVER (PARTITION BY InstrumentID ORDER BY SysEndTime ASC) = 1
    │  → #yesterdayIsins (earliest yesterday record per instrument)

[Change Detection]
INNER JOIN #currentIsins ON #yesterdayIsins ON InstrumentID
WHERE New_ISINCode <> Old_ISINCode
    │  SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email_DayToDay_Changes
    │  TRUNCATE + INSERT
    ▼
BI_DB_dbo.AML_InstrumentMetaData_Daily_Email_DayToDay_Changes
(ROUND_ROBIN HEAP — 0 rows on 2026-04-23; event-driven)
```

---

## 2. Business Logic

### 2.1 Two-Snapshot ISIN Comparison

**What**: The SP compares today's tradable-instrument ISIN universe with yesterday's historical ISIN state to detect changes.

**Current snapshot (#currentIsins)**:
- Source: `External_etoro_Trade_InstrumentMetaData` (today's live data)
- Filter: `Tradable=1`, ISINCode valid (same 6-pattern filter as parent table)

**Yesterday snapshot (#yesterdayIsins)**:
- Source: `External_etoro_History_InstrumentMetaData` (temporal history table)
- Filter: `SysEndTime >= yesterday's date`
- Window: `ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY SysEndTime ASC) = 1` picks the earliest historical record from yesterday — representing the start-of-yesterday state

**Change detection**:
- `INNER JOIN ON InstrumentID WHERE #currentIsins.ISINCode <> #yesterdayIsins.ISINCode`
- Only instruments present in BOTH snapshots with differing ISINs appear in the output
- Instruments newly added or removed from the tradable set do NOT appear here (INNER JOIN)

### 2.2 Event-Driven Population

**What**: The table is empty on most days. An ISIN code change is a rare event triggered by corporate actions, regulatory corrections, or instrument record updates.

**Outcome**: 0 rows on 2026-04-23 (no ISIN changes that day). The table may have 1–50 rows on active days.

### 2.3 TRUNCATE + INSERT Pattern

Full TRUNCATE before INSERT on every daily run. The table always reflects the current-day ISIN change set — not a cumulative history.

---

## 3. Query Advisory

- **Empty on most days**: Do not assume 0 rows means an error — it means no ISIN changes occurred that day. Verify by cross-referencing with the parent table.
- **New_ISINCode and Old_ISINCode are both non-NULL**: Only rows where both values are valid appear (inner join of two filtered sets). Instruments with newly added or removed ISINs are excluded.
- **ROUND_ROBIN HEAP**: No clustered index on 0-row table. When populated (rare), full-scan is fine for small row counts.
- **Not a cumulative history**: Use this table only for yesterday→today changes. For historical ISIN change tracking, query `External_etoro_History_InstrumentMetaData` directly.
- **Join to Dim_Instrument**: InstrumentID joins to `DWH_dbo.Dim_Instrument` for full instrument context.

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 — DWH_dbo.Dim_Instrument wiki, originally Trade.Instrument) |
| 2 | InstrumentDisplayName | nvarchar(max) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than the internal Name field (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without InstrumentMetaData entries. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 3 | SymbolFull | nvarchar(max) | YES | Full ticker symbol (may be longer than Symbol), from Trade.InstrumentMetaData. Used for data provider integrations that require fully qualified symbols. NULL for instruments without metadata. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 4 | New_ISINCode | nvarchar(max) | YES | The current-day ISIN code for the instrument — the new value after the change. Sourced from today's #currentIsins snapshot (External_etoro_Trade_InstrumentMetaData, Tradable=1, valid ISIN). Always non-NULL in practice due to SP validity filter. (Tier 2 — SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email_DayToDay_Changes) |
| 5 | Old_ISINCode | nvarchar(max) | YES | The previous ISIN code for the instrument — the value from yesterday's historical snapshot. Sourced from #yesterdayIsins (External_etoro_History_InstrumentMetaData, earliest SysEndTime record per InstrumentID from yesterday). Always non-NULL in practice. (Tier 2 — SP_AML_Sanctions_Trade_InstrumentMetaData_For_Email_DayToDay_Changes) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| InstrumentID | etoro.Trade.InstrumentMetaData (current) | InstrumentID | INNER JOIN key |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData (current) | InstrumentDisplayName | Passthrough from #currentIsins |
| SymbolFull | etoro.Trade.InstrumentMetaData (current) | SymbolFull | Passthrough from #currentIsins |
| New_ISINCode | etoro.Trade.InstrumentMetaData (current) | ISINCode | Renamed from ISINCode; today's value |
| Old_ISINCode | etoro.Trade.History_InstrumentMetaData (yesterday) | ISINCode | Renamed from ISINCode; yesterday's earliest value per InstrumentID |

### 5.2 ETL Pipeline

```
[Production — Today]                       [Production — Yesterday]
etoro.Trade.InstrumentMetaData             etoro.Trade.History_InstrumentMetaData
    │  Generic Pipeline (Parquet)              │  Generic Pipeline (Parquet)
    ▼                                          ▼
Bronze/etoro/Trade/InstrumentMetaData      Bronze/etoro/Trade/History_InstrumentMetaData
    │  External Table                          │  External Table
    ▼                                          ▼
External_etoro_Trade_InstrumentMetaData    External_etoro_History_InstrumentMetaData
    │  Tradable=1, valid ISIN                  │  SysEndTime >= yesterday, row_num=1
    ▼                                          ▼
            #currentIsins ─────────────── #yesterdayIsins
                          INNER JOIN ON InstrumentID
                          WHERE ISINCode differs
                                │
                                ▼
          AML_InstrumentMetaData_Daily_Email_DayToDay_Changes
          (TRUNCATE + INSERT, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| BI_DB_dbo.AML_InstrumentMetaData_Daily_Email | InstrumentID | Parent: current-day full ISIN universe; instruments in this table are a subset that had ISIN changes |
| DWH_dbo.Dim_Instrument | InstrumentID | Full instrument metadata enrichment (type, exchange, market cap). REPLICATE — no shuffle. |
| BI_DB_dbo.External_etoro_History_InstrumentMetaData | InstrumentID | Direct history source; yesterday's ISINs come from here |

---

## 7. Sample Queries

```sql
-- Today's ISIN changes (empty on most days)
SELECT InstrumentID, InstrumentDisplayName, SymbolFull,
       Old_ISINCode, New_ISINCode
FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email_DayToDay_Changes]
ORDER BY InstrumentDisplayName;

-- Enrich with instrument type for AML review
SELECT c.InstrumentID, c.InstrumentDisplayName, c.SymbolFull,
       c.Old_ISINCode, c.New_ISINCode,
       d.InstrumentType, d.Exchange
FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email_DayToDay_Changes] c
JOIN [DWH_dbo].[Dim_Instrument] d ON c.InstrumentID = d.InstrumentID;

-- Verify parent table has the new ISIN
SELECT e.ISINCode
FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email] e
WHERE e.InstrumentID IN (
    SELECT InstrumentID
    FROM [BI_DB_dbo].[AML_InstrumentMetaData_Daily_Email_DayToDay_Changes]
);
```

---

## 8. Atlassian Sources

No Confluence pages identified for this specific table. Consult the DATA space in Confluence for AML/Sanctions domain documentation and the ISIN change monitoring email process specifications.

---

*Tier breakdown: InstrumentID (Tier 1 — DWH_dbo.Dim_Instrument wiki) | InstrumentDisplayName (Tier 1 — DWH_dbo.Dim_Instrument wiki) | SymbolFull (Tier 1 — DWH_dbo.Dim_Instrument wiki) | New_ISINCode (Tier 2 — SP logic) | Old_ISINCode (Tier 2 — SP logic)*
*Quality score: 9.0/10 (Phase 16 adversarial evaluation, 2026-04-23)*

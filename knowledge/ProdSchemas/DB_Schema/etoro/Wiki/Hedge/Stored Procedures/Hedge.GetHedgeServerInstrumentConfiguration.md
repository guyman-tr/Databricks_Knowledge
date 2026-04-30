# Hedge.GetHedgeServerInstrumentConfiguration

> Full-table read procedure: returns all rows from Hedge.HedgeServerInstrumentConfiguration - the per-server, per-instrument override layer for HBC failover, price source, deal size validation, and IM routing thresholds. No parameters; returns entire config set (currently empty - table is implemented but no rows have been inserted).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHedgeServerInstrumentConfiguration is the reader for the `Hedge.HedgeServerInstrumentConfiguration` table - a per-server, per-instrument override configuration layer that sits above the global `Hedge.InstrumentConfiguration` table. It is called by the hedge engine at startup to load any instrument-specific overrides per server.

The procedure is intentionally simple: no parameters, no joins, no filtering - a full SELECT of all columns. This allows the calling service to load the entire override table into memory and apply it during execution decisions.

**Important operational note**: As of the current environment, the underlying table has 0 rows. All hedge servers use the system defaults for HBC failover, price source, deal size validation, and IM routing thresholds (governed by server-level settings). This table and procedure are production-ready but have not yet been activated with data.

Called externally by HedgeAlertService and the hedge engine; no SQL procedure callers found in the Hedge schema.

---

## 2. Business Logic

### 2.1 Full-Table Read with No Filtering

**What**: Returns all rows from HedgeServerInstrumentConfiguration without any WHERE clause or parameters.

**Rules**:
- SELECT with NOLOCK hint: `FROM Hedge.HedgeServerInstrumentConfiguration with (NOLOCK)`.
- Five columns returned: HedgeServerID, InstrumentID, AllowHBCFailover, PriceSource, AllowClosePositionMaxDealSizeCheck, MinAmountForIM.
- The calling service is responsible for filtering by HedgeServerID after loading.
- Currently returns 0 rows; the procedure executes successfully but produces an empty result set.

### 2.2 Configuration Semantics of Returned Columns

**What**: Each column serves a specific execution override purpose.

**Rules**:
- **AllowHBCFailover**: 1=HBC can fall back to standard execution on failure for this instrument; 0=strict HBC-only (no fallback). Overrides server-level BusinessFlowBehavior.AllowHBCFailover for this specific instrument.
- **PriceSource**: Which price feed to use (smallint, DEFAULT 1 = primary feed). Overrides Trade.HedgeServer.PriceSource per instrument.
- **AllowClosePositionMaxDealSizeCheck**: 1=validate close orders against max deal size; 0=skip validation. DEFAULT 1.
- **MinAmountForIM**: Minimum order size (base currency) to route via Institutional Market (IM) path. Orders below this threshold use standard routing.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (returned resultset - all columns of Hedge.HedgeServerInstrumentConfiguration):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | Part of composite PK. Identifies the hedge server this override applies to. FK to Trade.HedgeServer.HedgeServerID. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Part of composite PK. Identifies the instrument this override applies to. FK to Trade.Instrument.InstrumentID. |
| 3 | AllowHBCFailover | bit | NO | - | CODE-BACKED | Whether HBC can fall back to standard execution for this instrument on this server. 1=failover allowed, 0=strict HBC-only. Instrument-level override of BusinessFlowBehavior.AllowHBCFailover. |
| 4 | PriceSource | smallint | NO | 1 | CODE-BACKED | Price feed selection for this instrument on this server. DEFAULT 1 = primary price source. Instrument-level override of Trade.HedgeServer.PriceSource. |
| 5 | AllowClosePositionMaxDealSizeCheck | bit | NO | 1 | CODE-BACKED | Whether close-position orders are validated against max deal size. 1=validate (default), 0=skip validation. |
| 6 | MinAmountForIM | decimal | YES | - | CODE-BACKED | Minimum order size in base currency to use the IM (Institutional Market) routing path. Orders below this threshold use standard execution routing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Full table read | Hedge.HedgeServerInstrumentConfiguration | Lookup / Read | All rows, all columns. NOLOCK hint. Currently empty. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | Result set | Caller | Loads per-server/instrument overrides at startup for execution decision-making. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHedgeServerInstrumentConfiguration (procedure)
└── Hedge.HedgeServerInstrumentConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerInstrumentConfiguration | Table | Full table read. 5 columns (HedgeServerID, InstrumentID, AllowHBCFailover, PriceSource, AllowClosePositionMaxDealSizeCheck, MinAmountForIM). Currently empty. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine / HedgeAlertService (external) | Application | Configuration load at startup; applies overrides during execution routing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No temp tables. No parameters. Trivial single-table SELECT with NOLOCK. Lightest possible read procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetHedgeServerInstrumentConfiguration;
-- Currently returns 0 rows (table is empty in this environment)
```

### 8.2 Check the underlying table directly

```sql
SELECT COUNT(*) AS RowCount FROM Hedge.HedgeServerInstrumentConfiguration WITH (NOLOCK);
-- Verify row count; 0 = config not yet activated
```

### 8.3 Example of what a populated result would look like

```sql
-- If rows existed, they would look like:
-- HedgeServerID | InstrumentID | AllowHBCFailover | PriceSource | AllowClosePositionMaxDealSizeCheck | MinAmountForIM
-- 1             | 9920         | 0                | 2           | 1                                  | 50000.00
-- (Server 1, Instrument 9920: strict HBC mode, alternate price source 2, IM for orders >= 50k)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Per-server instrument config layer; HBC failover and IM routing thresholds. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHedgeServerInstrumentConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHedgeServerInstrumentConfiguration.sql*

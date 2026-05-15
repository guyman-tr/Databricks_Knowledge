# Dealing_dbo.Dealing_RiskMatrix_V2

> Dealing **NOP (net open position) stress grid** with **48** scenario columns (`UnitsNOP±X%`) plus snapshot pricing, leverage, regulation, and hedge-server slice. **87,642** live rows (2026-05-14 `COUNT(*)`), **one** `PositionsTime` instant (`2024-06-02 08:01:49.697`) and **one** `UpdateDate` instant (`2024-06-02 08:02:49.217`) — strong evidence of a **single bulk load / snapshot**, not an ongoing warehouse ETL tracked in SSDT (no writer SP found). Synapse DDL: `ROUND_ROBIN` **HEAP** (`Dealing_dbo.Dealing_RiskMatrix_V2.sql`).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | **Unknown runtime loader** — SSDT has table DDL + `Dealing_Migration.Dealing_RiskMatrix_V2` migration mirror only; **no** `Stored Procedures/*.sql` reference (repo search 2026-05-14) |
| **Refresh** | **Stale / unknown** — only 2024-06-02 timestamps observed across all rows (live MCP) |
| **Synapse Distribution** | `ROUND_ROBIN` |
| **Synapse Index** | `HEAP` |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2` |
| **UC Format** | delta |
| **UC Partitioned By** | None (from snapshot table semantics) |
| **UC Table Type** | Gold SQL export — `gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2` |
| **Row count (exact)** | 87,642 (`COUNT(*)` Synapse MCP 2026-05-14) |
| **PII** | None identified (instrument symbols are market data, not customer identifiers) |

---

## 1. Business Meaning

This table stores a **vector of stressed NOP outcomes** for each grain row: baseline `UnitsNOP` plus **25** upside moves (`+1%` … `+10%`, then `+15%` … `+100%` by wider steps, plus `+200%`, `+300%`, `+400%`, `+900%`) and **23** downside moves (`−1%` … `−10%`, then `−15%` … `−100%` with `−99%` included). Live `InstrumentType` mixes **Stocks** (dominant), **ETF**, **Currencies**, **Crypto Currencies**, **Commodities**, and **Indices** — so the prior wiki text claiming “Real Stocks and ETFs only” is **incorrect** (flagged SLOPPY in `.review-needed.md`).

`HedgeServerID` partitions the book across **32** hedge/LP server ids. `Regulation` carries CySEC / FCA / ASIC-style buckets. `Region` exists in DDL but is **100% NULL/blank** in the live snapshot — do not use for geography without a refresh.

**Comparison to v1:** there is **no** `Dealing_dbo.Dealing_RiskMatrix` wiki in this repo; continuity is limited to shared naming and migration artifacts.

---

## 2. Business Logic

### 2.1 Grain & snapshot integrity

**What**: Each row is one **positions-time × hedge-server × instrument × side × leverage × regulation × (unused region) × settlement flag** slice.  
**Columns Involved**: `PositionsTime`, `HedgeServerID`, `InstrumentID`, `IsBuy`, `Leverage`, `Regulation`, `Region`, `IsSettled`, pricing + NOP vector.  
**Rules**:
- `PositionsTime` is **constant** across all 87,642 rows in live data.
- `UpdateDate` is **constant** across all 87,642 rows and trails `PositionsTime` by ~1 minute — consistent with “calculation completed then inserted”.

### 2.2 Scenario grid semantics

**What**: For each shock label `X`, `UnitsNOP+X%` / `UnitsNOP-X%` stores the **post-shock NOP** in **instrument units** produced by the (unknown) valuation job.  
**Columns Involved**: `UnitsNOP`, all `UnitsNOP±%` columns.  
**Rules**:
- Column names **require** bracket / backtick quoting in SQL (`[UnitsNOP+1%]`, `` `UnitsNOP-99%` `` in Spark SQL).
- Live check: `UnitsNOP` and `UnitsNOP+1%` have **0 NULLs** across the table (`SUM(CASE WHEN ... IS NULL THEN 1 END) = 0`).

### 2.3 Instrument / dictionary alignment

**What**: `InstrumentID` / `InstrumentName` / `InstrumentType` align with `DWH_dbo.Dim_Instrument` semantics for **join enrichment** (not proven as ETL copy).  
**Columns Involved**: `InstrumentID`, `InstrumentName`, `InstrumentType`.  
**Rules**:
- `InstrumentType` distinct values in live data subset match the CASE labels documented on `Dim_Instrument.InstrumentType`.

---

## 3. Query Advisory

### 3.1 Synapse distribution & index

`ROUND_ROBIN` + **HEAP** implies full scans on large selective filters — keep predicates on `InstrumentID`, `HedgeServerID`, `Regulation`, `Leverage`, `IsBuy` when exploring.

### 3.2 Common query patterns

| Analyst question | Recommended approach |
|------------------|---------------------|
| Map instrument attributes | `JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID = rm.InstrumentID` |
| Compare upside vs downside tail | Pivot or column-wise `ABS([UnitsNOP-100%] - UnitsNOP)` vs upside analog |
| Filter real-money books | ⚠ **`IsSettled` meaning unverified** — confirm with dealing risk owners before trusting |

### 3.3 Common JOINs

| Join to | Join condition | Purpose |
|---------|----------------|---------|
| `DWH_dbo.Dim_Instrument` | `di.InstrumentID = rm.InstrumentID` | Canonical instrument metadata (`Name`, `InstrumentType`, units, flags) |

### 3.4 Gotchas

- **`Region` is_blank for all rows** — not a geography dimension in this snapshot.
- **`IsBuy` is `int`** (`0/1`), not `bit` (DDL + live distinct check).
- **No SSDT loader** — reproducibility gap; treat numbers as **frozen June 2024** unless refreshed.
- **Approximate row-count DMV denied** — use exact `COUNT(*)` if needed (safe at ~88K rows).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| 1 | Production / upstream wiki-verified meaning |
| 2 | Synapse ETL / table evidence without production doc |
| 3 | Inferred from related systems (disclose) |
| 4 | Confluence / Jira-sourced (none this pass) |
| 5 | Expert review required — semantics not proven in repo/Synapse code |

---

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionsTime | datetime | YES | Hedge / NOP snapshot timestamp. Live data shows one instant `2024-06-02 08:01:49.697` covering all rows (`MIN`=`MAX`). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 2 | HedgeServerID | int | YES | Hedge-book / LP server slice key from the snapshot (**32** distinct IDs in live data). Exact server catalog mapping not documented in SSDT. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 3 | InstrumentID | int | YES | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 — Trade.GetInstrument) |
| 4 | InstrumentName | varchar(50) | YES | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). DWH snapshot column `InstrumentName` stores this pattern for the grain row. (Tier 1 — Trade.GetInstrument) |
| 5 | InstrumentType | varchar(50) | YES | ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 — SP_Dim_Instrument) |
| 6 | IsBuy | int | YES | Side flag with live distinct values **0** and **1** only (`SELECT DISTINCT IsBuy`). **1** = buy / long, **0** = sell / short for this snapshot encoding (boolean intent; column is `int`, not `bit`). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 7 | Leverage | int | YES | Leverage tier applied in the NOP shock grid (**11** observed values in live data: `1,2,5,10,20,25,30,50,100,200,400`). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 8 | Regulation | varchar(50) | YES | Regulation / license bucket text (**11** labels in snapshot, e.g. CySEC **24,440** rows / FCA **20,418** / FSA Seychelles **16,425** … “None” **3** rows). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 9 | Region | varchar(50) | YES | **Unused in live snapshot** — **87,642 / 87,642** rows have `NULL` or empty string (`Region IS NULL OR LTRIM(RTRIM(ISNULL(Region,'')))=''` checklist query). DDL placeholder only until populated. (Tier 5 — Expert Review) |
| 10 | Bid | decimal(16,6) | YES | Bid price at snapshot time (`decimal(16,6)` per SSDT DDL). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 11 | Ask | decimal(16,6) | YES | Ask price at snapshot time (`decimal(16,6)` per SSDT DDL). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 12 | ConversionRate | decimal(16,6) | YES | FX rate applied in the scenario engine toward USD (sample shows `1.000000` for USD-quoted names and fractional values for GBX names). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 13 | UnitsNOP | decimal(38,8) | YES | Baseline net-open-position units prior to shocks; **zero NULLs** in live table (`SUM(CASE WHEN UnitsNOP IS NULL THEN 1 END)=0`). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 14 | `UnitsNOP+1%` | decimal(38,8) | YES | NOP after **+1%** price shock; **zero NULLs** in stress spot-check (`SUM(CASE WHEN UnitsNOP+1% IS NULL THEN 1 END)=0`). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 15 | `UnitsNOP+2%` | decimal(38,8) | YES | NOP after **+2%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 16 | `UnitsNOP+3%` | decimal(38,8) | YES | NOP after **+3%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 17 | `UnitsNOP+4%` | decimal(38,8) | YES | NOP after **+4%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 18 | `UnitsNOP+5%` | decimal(38,8) | YES | NOP after **+5%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 19 | `UnitsNOP+6%` | decimal(38,8) | YES | NOP after **+6%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 20 | `UnitsNOP+7%` | decimal(38,8) | YES | NOP after **+7%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 21 | `UnitsNOP+8%` | decimal(38,8) | YES | NOP after **+8%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 22 | `UnitsNOP+9%` | decimal(38,8) | YES | NOP after **+9%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 23 | `UnitsNOP+10%` | decimal(38,8) | YES | NOP after **+10%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 24 | `UnitsNOP+15%` | decimal(38,8) | YES | NOP after **+15%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 25 | `UnitsNOP+20%` | decimal(38,8) | YES | NOP after **+20%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 26 | `UnitsNOP+25%` | decimal(38,8) | YES | NOP after **+25%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 27 | `UnitsNOP+30%` | decimal(38,8) | YES | NOP after **+30%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 28 | `UnitsNOP+40%` | decimal(38,8) | YES | NOP after **+40%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 29 | `UnitsNOP+50%` | decimal(38,8) | YES | NOP after **+50%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 30 | `UnitsNOP+60%` | decimal(38,8) | YES | NOP after **+60%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 31 | `UnitsNOP+70%` | decimal(38,8) | YES | NOP after **+70%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 32 | `UnitsNOP+80%` | decimal(38,8) | YES | NOP after **+80%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 33 | `UnitsNOP+90%` | decimal(38,8) | YES | NOP after **+90%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 34 | `UnitsNOP+100%` | decimal(38,8) | YES | NOP after **+100%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 35 | `UnitsNOP+200%` | decimal(38,8) | YES | NOP after **+200%** price shock (extreme upside tail). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 36 | `UnitsNOP+300%` | decimal(38,8) | YES | NOP after **+300%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 37 | `UnitsNOP+400%` | decimal(38,8) | YES | NOP after **+400%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 38 | `UnitsNOP+900%` | decimal(38,8) | YES | NOP after **+900%** price shock (extreme upside tail). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 39 | `UnitsNOP-1%` | decimal(38,8) | YES | NOP after **−1%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 40 | `UnitsNOP-2%` | decimal(38,8) | YES | NOP after **−2%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 41 | `UnitsNOP-3%` | decimal(38,8) | YES | NOP after **−3%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 42 | `UnitsNOP-4%` | decimal(38,8) | YES | NOP after **−4%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 43 | `UnitsNOP-5%` | decimal(38,8) | YES | NOP after **−5%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 44 | `UnitsNOP-6%` | decimal(38,8) | YES | NOP after **−6%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 45 | `UnitsNOP-7%` | decimal(38,8) | YES | NOP after **−7%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 46 | `UnitsNOP-8%` | decimal(38,8) | YES | NOP after **−8%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 47 | `UnitsNOP-9%` | decimal(38,8) | YES | NOP after **−9%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 48 | `UnitsNOP-10%` | decimal(38,8) | YES | NOP after **−10%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 49 | `UnitsNOP-15%` | decimal(38,8) | YES | NOP after **−15%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 50 | `UnitsNOP-20%` | decimal(38,8) | YES | NOP after **−20%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 51 | `UnitsNOP-25%` | decimal(38,8) | YES | NOP after **−25%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 52 | `UnitsNOP-30%` | decimal(38,8) | YES | NOP after **−30%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 53 | `UnitsNOP-40%` | decimal(38,8) | YES | NOP after **−40%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 54 | `UnitsNOP-50%` | decimal(38,8) | YES | NOP after **−50%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 55 | `UnitsNOP-60%` | decimal(38,8) | YES | NOP after **−60%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 56 | `UnitsNOP-70%` | decimal(38,8) | YES | NOP after **−70%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 57 | `UnitsNOP-80%` | decimal(38,8) | YES | NOP after **−80%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 58 | `UnitsNOP-90%` | decimal(38,8) | YES | NOP after **−90%** price shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 59 | `UnitsNOP-99%` | decimal(38,8) | YES | NOP after **−99%** price shock (**not** the same grid as −100%). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 60 | `UnitsNOP-100%` | decimal(38,8) | YES | NOP after **−100%** (full wipe) shock. (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 61 | UpdateDate | datetime | YES | Load / publish timestamp for the snapshot rows. Live data shows one instant `2024-06-02 08:02:49.217` covering all rows (`MIN`=`MAX`). (Tier 2 — Dealing_dbo.Dealing_RiskMatrix_V2) |
| 62 | IsSettled | int | YES | **`{0,1}` flag only** — meanings such as “real asset vs CFD” were **historical folklore** without SSDT proof. Treat as **unverified categorical** pending dealing risk SMEs. Distinct `{0,1}` (live MCP). (Tier 5 — Expert Review) |

---

## 5. Lineage

### 5.1 Production sources

Because **no SSDT writer** exists, the strict “Synapse Column → Production Column” map is incomplete. Grain-level enrichment is:

| Synapse analyst column | Canonical lookup | Transformation |
|------------------------|-----------------|----------------|
| `InstrumentID` | `Trade.Instrument` via `DWH_dbo.Dim_Instrument` | Interpretation Tier 1 (Dim wiki) |
| `InstrumentName` | `Dim_Instrument.Name` pattern | Verbatim Trade.GetInstrument definition |
| `InstrumentType` | `Dim_Instrument.InstrumentType` CASE | Verbatim `SP_Dim_Instrument` CASE |
| All other columns | **Unknown** | Snapshot job not in repo |

### 5.2 ETL pipeline (evidence-based)

```
[Unknown producer — Python / notebook / external job / one-off script]
        │
        ▼
Dealing_dbo.Dealing_RiskMatrix_V2  (materialized HEAP table, Jun-2024 snapshot)
        │
        ▼
UC Gold: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2
```

**Migration-only clue (not runtime proof):** `Dealing_Migration.Dealing_RiskMatrix_V2` DDL in `NoDbObjectsScripts` mirrors column names for historical load.

### 5.3 UC lineage injection

External UC lineage API registration is **deferred** — no bronze → gold mapping can be asserted without the producer job. See `.lineage.md` “Phase 15” notes.

```text
UPSTREAM SEARCH LOG — Dealing_RiskMatrix_V2:
  Lineage source objects (from .lineage.md):
    1. Dealing_Migration.Dealing_RiskMatrix_V2 (role: migration mirror / historic staging template)
    2. DWH_dbo.Dim_Instrument (role: dimension lookup for InstrumentID / naming semantics)
  For each source:
    Dealing_Migration.Dealing_RiskMatrix_V2
      (a) Local wiki search: knowledge/synapse/Wiki/Dealing_Migration/Tables/Dealing_RiskMatrix_V2.md → NOT_FOUND
          Read tool issued: NO
      (b) Production wiki search: n/a (Synapse migration schema) → NOT_FOUND
          Read tool issued: NO
      Effective upstream: SSDT NoDbObjectsScripts DDL file (read on disk 2026-05-14)
    DWH_dbo.Dim_Instrument
      (a) Local wiki search: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md → FOUND
          Read tool issued: YES
      (b) Production wiki search: (not required — Tier 1 already in local wiki) → NOT_USED
          Read tool issued: NO
      Effective upstream: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md
  Columns expected to inherit Tier 1 verbatim from Dim_Instrument wiki:
    InstrumentID (#1 InstrumentID row)
    InstrumentName (#4 Name row pattern)
  Tier-2 inherited definition:
    InstrumentType (#3 InstrumentType row)
  Tier-1-eligible columns identified: 2 (InstrumentID, InstrumentName) + borrowed Tier 2 text for InstrumentType
```

---

## 6. Relationships

### 6.1 References to (recommended joins)

| Element | Related object | Relationship |
|---------|----------------|----------------|
| `InstrumentID` | `DWH_dbo.Dim_Instrument.InstrumentID` | Many-to-one enrichment |
| Scenario columns | internal | Each shock column mathematically derives from same unknown engine as `UnitsNOP` |

### 6.2 Referenced by

No dependent views/procs found (`sys.sql_modules` LIKE `%Dealing_RiskMatrix_V2%` returned **zero** rows, 2026-05-14).

---

## 7. Sample Queries

### 7.1 Instrument-level shock sensitivity (bracket-quote columns)

```sql
SELECT TOP 20
       InstrumentID,
       InstrumentName,
       Regulation,
       Leverage,
       UnitsNOP AS base_nop,
       [UnitsNOP+100%] AS nop_up_100,
       [UnitsNOP-50%]  AS nop_dn_50
FROM Dealing_dbo.Dealing_RiskMatrix_V2
ORDER BY ABS(UnitsNOP) DESC;
```

### 7.2 Regulation × leverage NOP mass

```sql
SELECT Regulation, Leverage,
       SUM(UnitsNOP) AS sum_nop_units
FROM Dealing_dbo.Dealing_RiskMatrix_V2
GROUP BY Regulation, Leverage
ORDER BY ABS(SUM(UnitsNOP)) DESC;
```

---

## 8. Atlassian knowledge sources

- **Confluence / Jira scan**: deferred — Atlassian MCP CQL helper requires authenticated `cloudId` context not executed in this subagent session. Tracker: rerun `searchConfluenceUsingCql` / JQL with `RiskMatrix`, `NOP stress`, `Dealing_RiskMatrix_V2`.

---

### Phase gate checklist (pipeline)

```text
PHASE GATE CHECK — Dealing_RiskMatrix_V2:
  [x] P1 DDL   [x] P2 Sample   [x] P3 Dist   [x] P4 Lookup
  [x] P5 JOIN  [x] P6 BizLogic [x] P7 Views  [x] P8 SP-scan
  [x] P9 SP-logic [x] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11 (P10 Confluence explicitly deferred)
PHASE 2 GATE: PASSED
  Sample rows: 5
  Row count: 87,642
  Timestamp pattern: historical single instant
  ETL source: inconclusive (no SSDT writer; migration mirror only)
PHASE 1 CHECKPOINT: PASS
PHASE 2 CHECKPOINT: PASS
PHASE 3 CHECKPOINT: PASS
```

---

*Generated: 2026-05-14 | Quality: 7.6/10 | Phases: 14/15 (Atlassian deferred) | Adversarial: prior “26 scenario / stocks-only / bit IsBuy / float prices / wrong shock ladder” doc errors **corrected**; remaining gap = **unattributed producer** + **IsSettled** semantics.*  
*Tiers: 2 T1, 58 T2, 0 T3, 0 T4, 2 T5 | Elements: 62/62, Logic: 7/10, Lookups: partial (Dim_Instrument only), Staleness: high*  
*Object: Dealing_dbo.Dealing_RiskMatrix_V2 | Type: table | Production Source: unknown job (SSDT negative)*

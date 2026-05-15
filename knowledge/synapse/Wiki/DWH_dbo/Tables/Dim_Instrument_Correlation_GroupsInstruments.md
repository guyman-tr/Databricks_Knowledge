# DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments

> 90-row routing table that assigns every tradeable `InstrumentID` to an integer `GroupID`, storing contiguous `[MinInstrumentID, MaxInstrumentID]` spans so the nightly Pearson correlation job can fan out calculations across ~89 manageable shards.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH-computed (derived from active instrument population + correlation pipeline) |
| **Refresh** | Deterministic rebuild whenever `SP_Dim_Instrument_Correlation_Build_GroupsInstruments` executes ahead of `SP_Dim_Instrument_Correlation_*` group-range jobs |
| | |
| **Synapse Distribution** | ROUND_ROBIN (inherits builder defaults; confirm SSDT for bespoke layout) |
| **Synapse Index** | HEAP/CLUSTERED per SSDT (not expanded in this speckit pass) |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments` |
| **UC Format** | delta (expected) |
| **UC Partitioned By** | _Unknown — object not listed in live catalog sample_ |
| **UC Table Type** | Gold export from Synapse builder output |

---

## 1. Business Meaning

The instrument correlation stack materializes an N×N Pearson matrix each day — computationally explosive when N spans the full tradable universe. `SP_Dim_Instrument_Correlation_Build_GroupsInstruments` pre-partitions instruments into roughly **89 groups** so each batch processes a tractable wedge of pair combinations (`Dim_Instrument_Correlation` wiki §2.3). Each row here records `(GroupID, MinInstrumentID, MaxInstrumentID)` which forms an inclusive instrument-id band used by downstream `SP_Dim_Instrument_Correlation_ByGroupRange` orchestration.

`SELECT COUNT(*)` via Synapse MCP returned **90** populated rows (`TOP 10` sample shows contiguous increasing ranges covering early instrument ids). There is **no surrogate row per instrument** — the span should be interpreted as authoritative inclusive bounds emitted by the builder.

---

## 2. Business Logic

### 2.1 Group span semantics

**What**: Each correlation computation shard references one `GroupID` and restricts both `InstrumentID_a` and `InstrumentID_b` to fall within `[MinInstrumentID, MaxInstrumentID]` as emitted by builder logic.

**Columns Involved**: `GroupID`, `MinInstrumentID`, `MaxInstrumentID`

**Rules**:
- Bounds are inclusive on both endpoints (observed contiguous ranges `[1–83], [88–427], …` in MCP sample dated 2026-05-14).
- Ordering is deterministic by ascending `InstrumentID`; regroup triggers when cumulative `(N²)/2` estimates exceed configured budget per `Dim_Instrument_Correlation.md` §2.3 narrative.

**Diagram**:
```
Active instruments sorted by InstrumentID
  -> cumulative pair budget
       -> chunk into ~89 groups
            -> INSERT/UPDATE Dim_Instrument_Correlation_GroupsInstruments
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Low-width dictionary-style table (90 rows) — broadcast-friendly. Always join on `GroupID` or filter `InstrumentID BETWEEN Min AND Max` when emulating builder routing.

### 3.1b UC (Databricks) Storage & Partitioning

Export not verified in available catalog; expect small single-file Delta.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Which group owns instrument 1500? | `WHERE 1500 BETWEEN MinInstrumentID AND MaxInstrumentID` |
| Distinct group count | `SELECT COUNT(*) FROM table` (~90 baseline) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| `Dim_Instrument` | `InstrumentID BETWEEN MinInstrumentID AND MaxInstrumentID` | Attribute instruments to correlation shard |
| Correlation staging tables | `GroupID = @grp` | Match builder outputs |

### 3.4 Gotchas

- **Not grain per instrument**: Never assume one row per `InstrumentID`; always use BETWEEN logic.
- **Dynamic**: Min/Max widen/narrow whenever tradable universe changes — historical comparisons require joining with snapshot timestamps from builder logs (out of scope here).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★☆☆ | Tier 2 | `(Tier 2 — Synapse builders)` | Documented builder intent |
| ★★☆☆☆ | Tier 3 | `(Tier 3 — samples)` | Row counts validated via MCP TOP/COUNT |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GroupID | int | NO | Stable identifier for a correlation shard created by `SP_Dim_Instrument_Correlation_Build_GroupsInstruments`; referenced downstream when routing half-matrix computations. (Tier 2 — SP_Dim_Instrument_Correlation_Build_GroupsInstruments) |
| 2 | MinInstrumentID | int | NO | Inclusive lower bound of InstrumentIDs assigned to the shard; MCP sample shows contiguous chunks beginning at instrument 1 onward. (Tier 3 — live sample BI_DB MCP) |
| 3 | MaxInstrumentID | int | NO | Inclusive upper bound counterpart to `MinInstrumentID`; pairing with MIN defines the routed instrument band for shard `GroupID`. (Tier 3 — live sample BI_DB MCP) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GroupID | Correlation grouping job | sequential id | Assigned in builder SP |
| MinInstrumentID / MaxInstrumentID | Active instrument census | InstrumentID ORDER BY InstrumentID | MIN/MAX aggregates per shard |

Per `Dim_Instrument_Correlation.md` Lines 156-174 (ASCII pipeline), this table feeds `Dim_Instrument_Correlation_UnionedPartitions` via group-range orchestrators.

### 5.2 ETL Pipeline

```
Hourly candles + active instrument pulls
 -> SP_Dim_Instrument_Correlation_Build_GroupsInstruments
     -> Dim_Instrument_Correlation_GroupsInstruments
         -> SP_Dim_Instrument_Correlation_ByGroupRange (+ child procs)
             -> Dim_Instrument_Correlation_Half_Records_*
```

```text
UPSTREAM SEARCH LOG — Dim_Instrument_Correlation_GroupsInstruments:
  Lineage source objects (from .lineage.md):
    1. Active instrument universe (correlation window)
    2. Dim_Instrument_Correlation (consumer context)
  For each source:
    Dim_Instrument_Correlation
      (a) Local wiki: knowledge/synapse/Wiki/DWH_dbo/Views/Dim_Instrument_Correlation.md → FOUND Read tool: YES
      (b) Production wiki: N/A (DWH-only computation)
      Effective upstream: builder narrative sections 2.2-2.3
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| Min/MaxInstrumentID | `DWH_dbo.Dim_Instrument` | Instrument dimension coverage |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| `SP_Dim_Instrument_Correlation_ByGroupRange` | `GroupID` | Shard orchestration |
| `Dim_Instrument_Correlation` view stack | group filters | Matrix reconstruction |

---

## 7. Sample Queries

### 7.1 Resolve group for an instrument
```sql
SELECT *
FROM DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments
WHERE 1500 BETWEEN MinInstrumentID AND MaxInstrumentID;
```

### 7.2 Enumerate shard coverage
```sql
SELECT GroupID, MinInstrumentID, MaxInstrumentID,
       MaxInstrumentID - MinInstrumentID + 1 AS span_width
FROM DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments
ORDER BY GroupID;
```

### 7.3 Join instruments to groups
```sql
SELECT di.InstrumentID, g.GroupID
FROM DWH_dbo.Dim_Instrument di
JOIN DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments g
  ON di.InstrumentID BETWEEN g.MinInstrumentID AND g.MaxInstrumentID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian scan in this speckit pass.

---

*Generated: 2026-05-14 | Quality: 8.4/10 (★★★★☆) | Phases: speckit-condensed*

*Tiers: 0 T1, 1 T2, 2 T3, 0 T4 [UNVERIFIED], 0 T5*

*Object: DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments | Type: Table*

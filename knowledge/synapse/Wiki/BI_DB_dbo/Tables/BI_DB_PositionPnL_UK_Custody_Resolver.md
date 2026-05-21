# BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver

> 20.5M-row de-anonymization resolver mapping real CID and PositionID to both the EU (SHA1) and UK (MD5) hashed PositionID variants used in the custody reconciliation tables. Single-day TRUNCATE+INSERT snapshot refreshed daily via `SP_BI_DB_PositionPnL_EU_Custody`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL` (via #posFCA: stocks/ETFs, settled, CySEC) |
| **Writer SP** | `BI_DB_dbo.SP_BI_DB_PositionPnL_EU_Custody` (Inessa Kontorovich 2025-03-08 addition) |
| **Refresh** | Daily, TRUNCATE+INSERT (single-day snapshot) |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Append, parquet) |

---

## 1. Business Meaning

This table is the **de-anonymization bridge** for the EU/UK custody reconciliation system. While `BI_DB_PositionPnL_EU_Custody` and `BI_DB_PositionPnL_UK_Custody` strip PII (CID→999999999, PositionID→hash), this resolver preserves the real CID and PositionID alongside both hash variants, enabling:

1. **Cross-book matching**: Link an EU_Custody row (SHA1 hash) to its UK_Custody counterpart (MD5 hash) via the shared real PositionID
2. **De-anonymization**: Recover the real CID and PositionID for internal analysis when the anonymized book data is insufficient
3. **Audit trail**: Verify that EU and UK books contain the same positions

Each row represents one open CySEC stock/ETF position. The table holds exactly **one day** at a time (20.5M rows, DateID 20260412) — same row count as EU_Custody and UK_Custody. Added by Inessa Kontorovich on 2025-03-08.

---

## 2. Business Logic

### 2.1 Dual-Hash Resolution

**What**: Maps a single real PositionID to both hash algorithms.
**Columns Involved**: PositionID, PositionID_HashedEU, PositionID_HashedUK
**Rules**:
- PositionID_HashedEU = SHA1(PositionID) — matches `EU_Custody.PositionID_Hashed`
- PositionID_HashedUK = MD5(PositionID) — matches `UK_Custody.PositionID_Hashed`
- One-to-one mapping: each PositionID produces exactly one EU hash and one UK hash

### 2.2 Real CID Preservation

**What**: Retains the actual customer ID (not anonymized).
**Columns Involved**: CID
**Rules**:
- CID here is the REAL customer identifier from BI_DB_PositionPnL (via #posFCA)
- In contrast, EU_Custody and UK_Custody hardcode CID to 999999999
- This table should be treated as **PII-sensitive**

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(PositionID) distribution — optimal for PositionID-based JOINs. CLUSTERED COLUMNSTORE INDEX — efficient for both scan-heavy and point queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Resolve EU hash to real PositionID | `WHERE PositionID_HashedEU = '<hash>'` |
| Match EU and UK rows for same position | JOIN EU_Custody ON HashedEU, JOIN UK_Custody ON HashedUK |
| Find a customer's custody positions | `WHERE CID = <cid>` (real CID available here) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_PositionPnL_EU_Custody | PositionID_HashedEU = PositionID_Hashed | Link resolver to EU book |
| BI_DB_PositionPnL_UK_Custody | PositionID_HashedUK = PositionID_Hashed | Link resolver to UK book |
| DWH_dbo.Dim_Customer | CID = RealCID | Customer details (real CID) |
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Instrument details |

### 3.4 Gotchas

- **Contains real PII** — CID and PositionID are NOT anonymized in this table; apply appropriate access controls
- **Single-day only** — TRUNCATEd daily; no historical resolver data in Synapse (UC Gold Append may accumulate)
- **SHA1 = 40 chars, MD5 = 32 chars** — do not confuse HashedEU and HashedUK lengths

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description from documented upstream wiki (verbatim) |
| Tier 2 | Description from SP code analysis |
| Tier 3 | Description from data sampling / parameter inference |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Real customer identifier (NOT anonymized). From BI_DB_PositionPnL via #posFCA. Use for de-anonymization of EU/UK custody books. (Tier 2 — BI_DB_PositionPnL) |
| 2 | PositionID | bigint | NO | Real position identifier (NOT hashed). Distribution key. From BI_DB_PositionPnL via #posFCA. (Tier 2 — BI_DB_PositionPnL) |
| 3 | PositionID_HashedEU | varchar(100) | YES | SHA1 hash of PositionID. 40-character uppercase hex string. Matches `EU_Custody.PositionID_Hashed`. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody) |
| 4 | PositionID_HashedUK | varchar(100) | YES | MD5 hash of PositionID. 32-character uppercase hex string. Matches `UK_Custody.PositionID_Hashed`. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody) |
| 5 | InstrumentID | int | NO | Traded instrument. Only stocks/ETFs (InstrumentTypeID 5,6). FK to Dim_Instrument. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 6 | Occurred | datetime | NO | Position open timestamp (OpenOccurred). Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 7 | Date | date | YES | Snapshot calendar date @dt. Passthrough from BI_DB_PositionPnL. (Tier 3 — BI_DB_PositionPnL) |
| 8 | DateID | int | NO | Snapshot date as YYYYMMDD. Passthrough from BI_DB_PositionPnL. (Tier 1 — BI_DB_PositionPnL) |
| 9 | UpdateDate | datetime | NO | Row load timestamp. GETDATE() at insert time. (Tier 3 — SP_BI_DB_PositionPnL_EU_Custody, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| CID, PositionID, InstrumentID, Occurred, Date, DateID | BI_DB_PositionPnL (via #posFCA) | Same names | Passthrough |
| PositionID_HashedEU | BI_DB_PositionPnL | PositionID | SHA1 hash |
| PositionID_HashedUK | BI_DB_PositionPnL | PositionID | MD5 hash |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL → filter stocks/ETFs + settled + CySEC → #posFCA
  |-- SP_BI_DB_PositionPnL_EU_Custody @date
  |-- TRUNCATE + INSERT
  |-- Preserves real CID + PositionID
  |-- Computes SHA1 (HashedEU) + MD5 (HashedUK)
  v
BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver (20.5M rows)
  |-- Generic Pipeline (Append, parquet)
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID_HashedEU | BI_DB_PositionPnL_EU_Custody.PositionID_Hashed | Maps to EU book row |
| PositionID_HashedUK | BI_DB_PositionPnL_UK_Custody.PositionID_Hashed | Maps to UK book row |
| InstrumentID | DWH_dbo.Dim_Instrument | FK — instrument details |
| CID | DWH_dbo.Dim_Customer | FK — customer details (real CID) |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| BI_DB_PositionPnL_EU_Custody | JOIN via PositionID_HashedEU for de-anonymization |
| BI_DB_PositionPnL_UK_Custody | JOIN via PositionID_HashedUK for de-anonymization |

---

## 7. Sample Queries

### 7.1 De-anonymize EU Custody Position

```sql
SELECT r.CID, r.PositionID, eu.PositionPnL, eu.NOP, eu.Amount
FROM BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver r
JOIN BI_DB_dbo.BI_DB_PositionPnL_EU_Custody eu
    ON r.PositionID_HashedEU = eu.PositionID_Hashed
WHERE r.CID = 13944640
```

### 7.2 Cross-Book Reconciliation

```sql
SELECT r.PositionID,
    eu.PositionPnL AS EU_PnL, uk.PositionPnL AS UK_PnL,
    eu.NOP AS EU_NOP, uk.NOP AS UK_NOP
FROM BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver r
JOIN BI_DB_dbo.BI_DB_PositionPnL_EU_Custody eu ON r.PositionID_HashedEU = eu.PositionID_Hashed
JOIN BI_DB_dbo.BI_DB_PositionPnL_UK_Custody uk ON r.PositionID_HashedUK = uk.PositionID_Hashed
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 6 T1, 2 T2, 1 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 8/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver | Type: Table | Production Source: BI_DB_PositionPnL via SP_BI_DB_PositionPnL_EU_Custody*

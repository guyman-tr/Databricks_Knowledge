# BI_DB_dbo.BI_DB_PositionPnL_EU_Custody

> 20.5M-row anonymized daily snapshot of CySEC-regulated open stock/ETF custody positions with unrealized P&L, rates, commissions, NOP, and credit-reporting flags. Sourced from `BI_DB_PositionPnL` filtered to InstrumentTypeID 5/6 (stocks/ETFs), settled, RegulationID 2 (CySEC), with CID anonymized and PositionID SHA1-hashed. Refreshed daily via `SP_BI_DB_PositionPnL_EU_Custody` (TRUNCATE+INSERT, single-day snapshot).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL` → `DWH_dbo.Dim_Position` / `Fact_CurrencyPriceWithSplit` (via SP_PositionPnL) |
| **Writer SP** | `BI_DB_dbo.SP_BI_DB_PositionPnL_EU_Custody` (Guy Manova 2023-12-21, Inessa Kontorovich 2025-03-08) |
| **Refresh** | Daily, TRUNCATE+INSERT (single-day snapshot replaces prior content) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_eu_custody` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Append, daily, parquet) |

---

## 1. Business Meaning

This table is a **privacy-anonymized custody reconciliation snapshot** of all CySEC-regulated (EU) open stock and ETF positions. It serves as one half of a daily "EU book vs UK book" reconciliation system — the SP produces both the EU_Custody (this table, SHA1-hashed PositionID) and UK_Custody (MD5-hashed PositionID) tables simultaneously, along with instrument-level aggregations and a resolver mapping.

Each row represents one open position for a single snapshot date. The table holds exactly **one day** of data at any time (TRUNCATE+INSERT pattern) — currently 20.5M rows for DateID 20260412. The source `BI_DB_PositionPnL` is the canonical daily position P&L snapshot (Priority 99, FinanceReportSPS); this table filters it to:
- **InstrumentTypeID IN (5,6)** — stocks and ETFs only (real asset custody instruments)
- **IsSettled = 1** — real-asset settled positions only (not CFDs)
- **RegulationID = 2** ��� CySEC (EU) customers via Fact_SnapshotCustomer date-range lookup

**PII anonymization**: CID is hardcoded to 999999999 for all rows. PositionID is replaced by a SHA1 hash (`PositionID_Hashed`). The UK_Custody_Resolver table maps the real PositionID to both hash variants for internal reconciliation.

**All IsBuy = True**: Real stock custody positions are BUY-only (no short-selling in custody model). 99.96% of rows have IsCreditReportValidCB=1 and IsValidCustomer=1; 7,617 rows (0.04%) have both flags at 0.

---

## 2. Business Logic

### 2.1 CySEC Regulation Filter

**What**: Restricts to EU-regulated customers only.
**Columns Involved**: CID (from BI_DB_PositionPnL), RegulationID (from Fact_SnapshotCustomer)
**Rules**:
- Fact_SnapshotCustomer is joined via Dim_Range date-range lookup (DateRangeID WHERE @dateID BETWEEN FromDateID AND ToDateID)
- Only RegulationID = 2 (CySEC) customers are included
- The UK_Custody companion table uses the same filter (same SP, same #posFCA temp table)

### 2.2 Stock/ETF Custody Filter

**What**: Limits to real asset custody instruments.
**Columns Involved**: InstrumentID, IsSettled
**Rules**:
- JOIN to Dim_Instrument requires InstrumentTypeID IN (5,6) — stocks and ETFs
- IsSettled must be 1 (real asset settlement, not CFD)
- These two conditions isolate the custody book from the broader BI_DB_PositionPnL universe

### 2.3 PII Anonymization

**What**: Removes personally identifiable position and customer data.
**Columns Involved**: CID, PositionID_Hashed
**Rules**:
- CID is replaced with a constant 999999999 for all rows
- PositionID is SHA1-hashed: `CONVERT(NVARCHAR(40), HASHBYTES('SHA1', CONVERT(NVARCHAR(MAX), PositionID)), 2)`
- The UK_Custody table uses MD5 instead of SHA1, producing a different hash for the same PositionID
- The UK_Custody_Resolver table maps real PositionID to both hash variants

### 2.4 Single-Day Snapshot

**What**: Table holds exactly one day of data.
**Columns Involved**: DateID
**Rules**:
- TRUNCATE before INSERT — all prior data is removed
- Only the @date parameter's DateID is loaded
- Currently holds DateID 20260412 (20.5M rows)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no hash key, data spread evenly across distributions. CLUSTERED INDEX on DateID ASC — efficient for DateID-based filters (though only one DateID exists at a time due to TRUNCATE+INSERT pattern).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Total NOP for EU custody book | `SELECT SUM(NOP) FROM BI_DB_PositionPnL_EU_Custody` (no WHERE needed — single day) |
| P&L by instrument | Use the pre-aggregated `BI_DB_PositionPnL_EU_Custody_Instrument_Agg` table instead |
| Resolve hashed PositionID to real ID | JOIN to `BI_DB_PositionPnL_UK_Custody_Resolver` on PositionID_Hashed = PositionID_HashedEU |
| Compare EU vs UK books | JOIN EU_Custody and UK_Custody via the Resolver table |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_PositionPnL_UK_Custody_Resolver | PositionID_Hashed = PositionID_HashedEU | Map anonymized EU position to real PositionID |
| BI_DB_PositionPnL_UK_Custody | via Resolver (HashedEU → PositionID → HashedUK) | Compare EU and UK book views of same position |
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve instrument name, type, symbol |

### 3.4 Gotchas

- **CID is always 999999999** — do not use CID for any customer-level analysis; use the Resolver table to trace back to real CID
- **Single-day only** — no historical data; the table is TRUNCATEd daily. Use BI_DB_PositionPnL for historical snapshots
- **All IsBuy = True** — real stock custody has no short positions; do not filter on IsBuy (it adds no value)
- **IsSettled always 1** — pre-filtered; column is retained from parent schema but carries no variance
- **PositionID_Hashed is SHA1** — UK_Custody uses MD5 for the same PositionID; do NOT compare hashes across tables directly

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description from documented upstream wiki (verbatim) |
| Tier 2 | Description from SP code analysis |
| Tier 3 | Description from data sampling / parameter inference |
| Tier 4 | Best available knowledge (limited confidence) |
| Tier 5 | Expert review needed |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Anonymized customer identifier. Hardcoded to 999999999 for all rows — original CID from BI_DB_PositionPnL is stripped for privacy. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody) |
| 2 | PositionID_Hashed | varchar(100) | NO | SHA1 hash of the original PositionID from BI_DB_PositionPnL. 40-character uppercase hex string. Use UK_Custody_Resolver to map back to real PositionID. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody) |
| 3 | InstrumentID | int | NO | Traded instrument. Only stocks/ETFs (InstrumentTypeID 5,6) appear. FK to Dim_Instrument. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 4 | MirrorID | int | YES | Copy-trading mirror link when applicable. 0 = non-mirror (direct) position. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 5 | Commission | money | NO | Opening commission in dollars. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 6 | InitForexRate | numeric(16,8) | NO | Open rate; split-adjusted in SP when position spans a split. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 7 | SpreadedPipBid | numeric(16,8) | YES | Bid with spread at open. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 8 | SpreadedPipAsk | numeric(16,8) | YES | Ask with spread at open. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 9 | PositionPnL | decimal(16,4) | YES | Unrealized P&L in USD; from PnLInDollars (replaces legacy formula). Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 10 | Price | numeric(38,6) | YES | Per-unit price-move expression x USD conversion factor from #Pre_UnrealizedPnL (bid/ask vs InitForexRate and instrument FX chain). Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 11 | HedgeServerID | int | YES | Hedge server for the position. 16 distinct values. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 12 | Amount | money | NO | Position amount in USD; rewound via Dim_PositionChangeLog when SL/partial-close edits after @dt. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 13 | AmountInUnitsDecimal | numeric(16,6) | YES | Size in instrument units; split-adjusted and rewound from partial-close log when applicable. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 14 | LimitRate | numeric(16,8) | NO | Take-profit rate. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 15 | StopRate | numeric(16,8) | NO | Stop-loss rate; rewound to PreviousStopRate when edited after @dt. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 16 | IsBuy | bit | NO | Long (1) vs short (0). Always 1 (True) in this table — real stock custody is BUY-only. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 17 | Occurred | datetime | NO | Position open timestamp (OpenOccurred). Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 18 | Date | date | YES | Snapshot calendar date @dt. Passthrough from BI_DB_PositionPnL. (Tier 3 — BI_DB_PositionPnL) |
| 19 | DateID | int | NO | Snapshot date as YYYYMMDD; clustered index key. Single value per load (TRUNCATE+INSERT). Passthrough from BI_DB_PositionPnL. (Tier 1 — BI_DB_PositionPnL) |
| 20 | UpdateDate | datetime | YES | Row load timestamp at insert (GETDATE()). Passthrough from BI_DB_PositionPnL. (Tier 1 — BI_DB_PositionPnL) |
| 21 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Always 1 in this table (pre-filtered). Passthrough from BI_DB_PositionPnL. (Tier 5 — BI_DB_PositionPnL) |
| 22 | NOP | money | YES | Net open position in USD from units x pair rate x direction x conversion. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 23 | DailyPnL | decimal(16,4) | YES | Day-over-day change: PositionPnL minus prior day PositionPnL. Passthrough from BI_DB_PositionPnL. (Tier 3 — BI_DB_PositionPnL) |
| 24 | Leverage | int | YES | Position leverage. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 25 | RateBid | numeric(36,12) | YES | EOD bid from latest Fact_CurrencyPriceWithSplit row before @ReportDate, split-adjusted. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 26 | RateAsk | numeric(36,12) | YES | EOD ask from same price row, split-adjusted. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 27 | USD_CR | money | YES | End-of-day conversion rate used with PnL context; from Dim_Position CurrentConversionRate. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 28 | SettlementTypeID | int | YES | Modern settlement type from Dim_Position. 2 distinct values (NULL, 0, 1). Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 29 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, AccountTypeID, LabelID, CountryID. 99.96% = 1. Passthrough from Fact_SnapshotCustomer. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 30 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, LabelID, CountryID. 99.96% = 1. Passthrough from Fact_SnapshotCustomer. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| CID | — | — | Hardcoded 999999999 |
| PositionID_Hashed | BI_DB_PositionPnL | PositionID | SHA1 hash |
| InstrumentID–SettlementTypeID | BI_DB_PositionPnL | Same names | Passthrough (26 columns) |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough via CySEC date-range JOIN |
| IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Passthrough via CySEC date-range JOIN |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position + Fact_CurrencyPriceWithSplit + ...
  |-- SP_PositionPnL @dt (Priority 99, FinanceReportSPS)
  v
BI_DB_dbo.BI_DB_PositionPnL (39 cols, daily partition swap)
  |-- SP_BI_DB_PositionPnL_EU_Custody @date
  |-- Filter: InstrumentTypeID IN (5,6), IsSettled=1
  |-- JOIN Fact_SnapshotCustomer (RegulationID=2, CySEC)
  |-- Anonymize: CID→999999999, PositionID→SHA1
  |-- TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_PositionPnL_EU_Custody (20.5M rows, single day)
  |-- Generic Pipeline (Append, daily, parquet)
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_eu_custody
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK — instrument details, type, symbol |
| PositionID_Hashed | BI_DB_PositionPnL_UK_Custody_Resolver.PositionID_HashedEU | Resolver maps SHA1 hash back to real PositionID |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| BI_DB_PositionPnL_EU_Custody_Instrument_Agg | Aggregated from this table by instrument (same SP, DELETE+INSERT by DateID) |

---

## 7. Sample Queries

### 7.1 Total NOP and PnL for EU Custody Book

```sql
SELECT
    SUM(NOP) AS TotalNOP,
    SUM(PositionPnL) AS TotalPnL,
    COUNT(*) AS PositionCount,
    DateID
FROM BI_DB_dbo.BI_DB_PositionPnL_EU_Custody
GROUP BY DateID
```

### 7.2 Top 10 Instruments by Aggregate NOP

```sql
SELECT TOP 10
    eu.InstrumentID,
    di.SymbolFull,
    SUM(eu.NOP) AS TotalNOP,
    COUNT(*) AS Positions
FROM BI_DB_dbo.BI_DB_PositionPnL_EU_Custody eu
JOIN DWH_dbo.Dim_Instrument di ON eu.InstrumentID = di.InstrumentID
GROUP BY eu.InstrumentID, di.SymbolFull
ORDER BY TotalNOP DESC
```

### 7.3 Resolve Anonymized Position to Real CID

```sql
SELECT r.CID, r.PositionID, eu.*
FROM BI_DB_dbo.BI_DB_PositionPnL_EU_Custody eu
JOIN BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver r
    ON eu.PositionID_Hashed = r.PositionID_HashedEU
WHERE eu.InstrumentID = 1009
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 26 T1, 2 T2, 2 T3, 0 T4, 0 T5 | Elements: 30/30, Logic: 8/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_PositionPnL_EU_Custody | Type: Table | Production Source: BI_DB_PositionPnL via SP_BI_DB_PositionPnL_EU_Custody*

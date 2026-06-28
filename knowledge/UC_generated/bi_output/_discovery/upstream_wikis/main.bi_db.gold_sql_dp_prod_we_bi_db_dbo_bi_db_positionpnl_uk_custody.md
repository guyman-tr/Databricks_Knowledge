# BI_DB_dbo.BI_DB_PositionPnL_UK_Custody

> 20.5M-row anonymized daily snapshot of CySEC-regulated open stock/ETF custody positions — the "UK book" view with MD5-hashed PositionID. Structurally identical to `BI_DB_PositionPnL_EU_Custody` (SHA1 hash) — both represent the same underlying positions with different hash algorithms for EU-vs-UK reconciliation. Sourced from `BI_DB_PositionPnL` via `SP_BI_DB_PositionPnL_EU_Custody` (TRUNCATE+INSERT, single-day snapshot). Refreshed daily.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL` → `DWH_dbo.Dim_Position` / `Fact_CurrencyPriceWithSplit` (via SP_PositionPnL) |
| **Writer SP** | `BI_DB_dbo.SP_BI_DB_PositionPnL_EU_Custody` (Guy Manova 2023-12-21, Inessa Kontorovich 2025-03-08) |
| **Refresh** | Daily, TRUNCATE+INSERT (single-day snapshot replaces prior content) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Append, daily, parquet) |

---

## 1. Business Meaning

This table is the **UK book view** of the anonymized CySEC stock/ETF custody reconciliation system. It contains the exact same positions as `BI_DB_PositionPnL_EU_Custody`, but with PositionID hashed using **MD5** instead of SHA1. The dual-hash design enables independent reconciliation: the EU book uses SHA1, the UK book uses MD5, and the `UK_Custody_Resolver` table maps between them.

Each row represents one open position for a single snapshot date. The table holds exactly **one day** of data at any time (TRUNCATE+INSERT pattern) — currently 20.5M rows for DateID 20260412. The data source chain is identical to EU_Custody: `BI_DB_PositionPnL` → filter stocks/ETFs (InstrumentTypeID 5,6) + settled (IsSettled=1) + CySEC (RegulationID=2) → anonymize.

**PII anonymization**: CID is hardcoded to 999999999. PositionID is replaced by a 32-character MD5 hash. The `UK_Custody_Resolver` table maps the real PositionID to both hash variants.

The SP produces both EU_Custody and UK_Custody from the same temp table (#posFCA) in a single execution, guaranteeing row-level consistency between the two views.

---

## 2. Business Logic

### 2.1 MD5 Hashing (UK Book Variant)

**What**: Uses MD5 instead of SHA1 for the UK book's PositionID hash.
**Columns Involved**: PositionID_Hashed
**Rules**:
- MD5: `CONVERT(NVARCHAR(32), HASHBYTES('MD5', CONVERT(NVARCHAR(MAX), PositionID)), 2)`
- Produces a 32-character uppercase hex string (vs 40-char SHA1 in EU_Custody)
- Same underlying PositionID — different hash algorithm ensures books cannot be trivially cross-referenced without the Resolver

### 2.2 Identical Filters to EU_Custody

**What**: Same source data, same filters, same anonymization.
**Columns Involved**: All
**Rules**:
- InstrumentTypeID IN (5,6) — stocks/ETFs
- IsSettled = 1 — real-asset settled
- RegulationID = 2 — CySEC customers
- CID = 999999999 (anonymized)
- Produced from the same #posFCA temp table as EU_Custody in a single SP execution

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution. CLUSTERED INDEX on DateID ASC. Single-day snapshot — no date range filtering needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| UK book total NOP | `SELECT SUM(NOP) FROM BI_DB_PositionPnL_UK_Custody` |
| Match EU and UK positions | JOIN both tables via UK_Custody_Resolver (HashedEU ↔ HashedUK) |
| Instrument-level UK aggregation | Use `BI_DB_PositionPnL_UK_Instrument_Agg` instead |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_PositionPnL_UK_Custody_Resolver | PositionID_Hashed = PositionID_HashedUK | Map MD5 hash to real PositionID |
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve instrument name/symbol |

### 3.4 Gotchas

- **CID is always 999999999** — anonymized, no customer analysis possible without Resolver
- **Single-day only** — TRUNCATEd daily; use BI_DB_PositionPnL for historical snapshots
- **PositionID_Hashed is MD5 (32 chars)** — EU_Custody uses SHA1 (40 chars); do NOT compare hashes directly
- **Identical row count to EU_Custody** — same source data, same filters; any discrepancy indicates a data issue

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
| 1 | CID | int | YES | Anonymized customer identifier. Hardcoded to 999999999 for all rows — original CID from BI_DB_PositionPnL is stripped for privacy. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody) |
| 2 | PositionID_Hashed | varchar(100) | NO | MD5 hash of the original PositionID from BI_DB_PositionPnL. 32-character uppercase hex string. Use UK_Custody_Resolver to map back to real PositionID. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody) |
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
| 28 | SettlementTypeID | int | YES | Modern settlement type from Dim_Position. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 29 | IsCreditReportValidCB | int | YES | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, AccountTypeID, LabelID, CountryID. Passthrough from Fact_SnapshotCustomer. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 30 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, LabelID, CountryID. Passthrough from Fact_SnapshotCustomer. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| CID | — | — | Hardcoded 999999999 |
| PositionID_Hashed | BI_DB_PositionPnL | PositionID | MD5 hash (32-char hex) |
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
  |-- Anonymize: CID→999999999, PositionID→MD5
  |-- TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_PositionPnL_UK_Custody (20.5M rows, single day)
  |-- Generic Pipeline (Append, daily, parquet)
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK — instrument details, type, symbol |
| PositionID_Hashed | BI_DB_PositionPnL_UK_Custody_Resolver.PositionID_HashedUK | Resolver maps MD5 hash back to real PositionID |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| BI_DB_PositionPnL_UK_Instrument_Agg | Conceptual sibling — aggregated from same #posFCA source by instrument (Entity='UK') |

---

## 7. Sample Queries

### 7.1 Total UK Book NOP and PnL

```sql
SELECT SUM(NOP) AS TotalNOP, SUM(PositionPnL) AS TotalPnL, COUNT(*) AS Positions
FROM BI_DB_dbo.BI_DB_PositionPnL_UK_Custody
```

### 7.2 EU vs UK Reconciliation via Resolver

```sql
SELECT
    eu.PositionPnL AS EU_PnL, uk.PositionPnL AS UK_PnL,
    eu.NOP AS EU_NOP, uk.NOP AS UK_NOP
FROM BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver r
JOIN BI_DB_dbo.BI_DB_PositionPnL_EU_Custody eu ON r.PositionID_HashedEU = eu.PositionID_Hashed
JOIN BI_DB_dbo.BI_DB_PositionPnL_UK_Custody uk ON r.PositionID_HashedUK = uk.PositionID_Hashed
WHERE eu.PositionPnL <> uk.PositionPnL
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 26 T1, 2 T2, 2 T3, 0 T4, 0 T5 | Elements: 30/30, Logic: 8/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_PositionPnL_UK_Custody | Type: Table | Production Source: BI_DB_PositionPnL via SP_BI_DB_PositionPnL_EU_Custody*

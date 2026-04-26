---
schema: BI_DB_dbo
table: BI_DB_eTorian_NetProfit
documented: true
batch: 37
quality_score: 9.2
---

# BI_DB_eTorian_NetProfit

## 1. Business Meaning

Daily realized net profit breakdown for **eToro Popular Investors (eTorians)** — the strategy providers in eToro's copy trading program. Tracks closed position P&L split by asset class (Crypto, Stocks/ETFs, Other FX/CFD) for each PI on each day they close positions.

The eTorian program (PlayerLevelID=4 in eToro's customer hierarchy) is distinct from regular retail customers — Popular Investors earn payments based on their copied assets under management and trading activity. This table enables performance tracking, program payout calculations, and asset-class-level strategy analysis for PI participants.

| Property | Value |
|----------|-------|
| Grain | One row per `CID × CloseDate` |
| Population | Popular Investors (PlayerLevelID=4, AccountTypeID IN 7/13, not banned/deactivated) |
| Date range | 2021-01-01 – 2026-04-12 (1,920 close dates) |
| Total rows | ~358,925 |
| Unique Popular Investors | ~2,979 |
| Distribution | HASH(CID) |
| Index | CLUSTERED (CloseDate ASC) |

---

## 2. Business Logic

### 2.1 ETL Pattern

Written daily by `SP_eTorian_PnL_NetProfit @Date DATE`. The SP:
1. Builds the eTorian population snapshot for `@Date` from `Fact_SnapshotCustomer`
2. Aggregates closed position NetProfit from `Dim_Position WHERE CloseDateID = @DateID` for the PI population
3. Inserts using DELETE-then-INSERT on `CloseDate = @Date`
4. **End-of-month only**: also computes and stores unrealized open-position PnL in the companion table `BI_DB_eTorian_PnL`

### 2.2 eTorian Population

The "eTorian" population = customers with `PlayerLevelID=4` (Popular Investor status) AND specific eTorian account types (`AccountTypeID IN (7, 13)`) AND not deactivated (`AccountStatusID != 2`) AND not banned (`PlayerStatusID != 2`).

This excludes all regular retail customers. Standard analytics tables use `IsValidCustomer=1` (which explicitly excludes `PlayerLevelID=4`). This table is the PI-specific counterpart.

### 2.3 Asset Class Segmentation

NetProfit is split into three mutually exclusive buckets by `InstrumentTypeID`:

| Column | InstrumentTypeIDs | Asset Classes |
|--------|------------------|--------------|
| NetProfit_Crypto | 10 | Crypto Currencies (BTC, ETH, etc.) |
| NetProfit_Stocks_ETFs | 5, 6 | Stocks (real ownership) + ETFs (real ownership) |
| NetProfit_Other | 1, 2, 4 | Currencies (FX) + Commodities + Indices (CFD) |

Instrument types 3, 7, 8, 9 are historically unused gaps — positions with those types would produce 0 in all three buckets. In practice this is not observed.

### 2.4 EOM_CloseDate

`EOM_CloseDate = EOMONTH(CloseDate)` — the last day of the month containing `CloseDate`. This pre-computed column facilitates monthly aggregation without a EOMONTH call in downstream queries.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH on `CID` — queries filtering by `CID` land on a single distribution. CLUSTERED INDEX on `CloseDate` enables efficient date-range scans. For performance, always filter by `CloseDate` (or `EOM_CloseDate`) and optionally by `CID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly P&L by PI | `WHERE EOM_CloseDate = '2026-03-31' GROUP BY CID, UserName, SUM per asset class` |
| Top crypto performers | `WHERE CloseDate BETWEEN @start AND @end ORDER BY NetProfit_Crypto DESC` |
| Total program P&L for a period | `SUM(NetProfit_Crypto + NetProfit_Stocks_ETFs + NetProfit_Other) WHERE CloseDate BETWEEN @start AND @end` |
| PI activity days (how many days they closed positions) | `COUNT(DISTINCT CloseDate) WHERE CID = @cid` |

### 3.3 Gotchas

- **Negative NetProfit is normal.** Positions can close at a loss — all three NetProfit columns can be negative. `SUM(NetProfit_Crypto + NetProfit_Stocks_ETFs + NetProfit_Other)` can be negative (net loss day).
- **Zero means no positions of that type closed that day.** All three columns default to 0 via the CASE/SUM pattern, not NULL. A PI who only traded crypto on a given day will have `NetProfit_Stocks_ETFs = 0` and `NetProfit_Other = 0`.
- **Population is snapshot-based — PIs who lose status don't disappear from history.** The population filter runs on `@Date`'s snapshot. Historical rows reflect whoever was a PI on each specific date.
- **This table does NOT include open position P&L.** Only closed positions (`CloseDateID = @DateID`). For unrealized PnL on open positions at month-end, see `BI_DB_eTorian_PnL`.
- **Only ~2,979 unique CIDs.** This is a small specialist table. Joins to large tables without CID filtering will produce data movement on HASH(CID) distribution.
- **`RealCID=149` is hardcoded.** One system/admin account is permanently included regardless of population filter criteria.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — DWH_dbo wiki verbatim | (Tier 1 — DWH_dbo wiki, `{source}`) |
| Tier 2 — SP ETL code | (Tier 2 — SP_eTorian_PnL_NetProfit) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Popular Investor customer ID. HASH distribution key. Equivalent to `RealCID` in Dim_Customer. Only eTorian accounts (PlayerLevelID=4, AccountTypeID IN 7/13) appear. FK to `DWH_dbo.Dim_Customer.RealCID`. (Tier 2 — SP_eTorian_PnL_NetProfit population filter) |
| 2 | UserName | varchar(max) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Sourced from `DWH_dbo.Dim_Customer.UserName`. (Tier 1 — DWH_dbo wiki, Dim_Customer) |
| 3 | CloseDate | date | YES | Calendar date on which positions were closed. Derived as `CAST(Dim_Position.CloseOccurred AS DATE)`. Indexes this table — always include in WHERE. CLUSTERED INDEX column. (Tier 1 — DWH_dbo wiki, Dim_Position.CloseOccurred: "When close was persisted.") |
| 4 | EOM_CloseDate | date | YES | Last day of the month containing `CloseDate`. Pre-computed as `EOMONTH(CloseDate)`. Facilitates monthly aggregation without EOMONTH calls in downstream queries. (Tier 2 — SP_eTorian_PnL_NetProfit) |
| 5 | NetProfit_Crypto | money | YES | Realized PnL from closed **Crypto** positions (InstrumentTypeID=10) on `CloseDate`. Computed as `SUM(Dim_Position.NetProfit WHERE InstrumentTypeID=10)`. 0 if no crypto positions closed that day. Can be negative (loss). Dim_Position.NetProfit: "Realized PnL. 0 when open; set on close. In position currency." (Tier 2 — SP_eTorian_PnL_NetProfit aggregation of Dim_Position.NetProfit) |
| 6 | NetProfit_Stocks_ETFs | money | YES | Realized PnL from closed **Stocks and ETF** positions (InstrumentTypeID IN 5=Stocks, 6=ETF — real ownership) on `CloseDate`. Computed as `SUM(Dim_Position.NetProfit WHERE InstrumentTypeID IN (5,6))`. 0 if no such positions closed. (Tier 2 — SP_eTorian_PnL_NetProfit aggregation of Dim_Position.NetProfit) |
| 7 | NetProfit_Other | money | YES | Realized PnL from closed **FX/CFD** positions (InstrumentTypeID IN 1=Currencies, 2=Commodities, 4=Indices) on `CloseDate`. Computed as `SUM(Dim_Position.NetProfit WHERE InstrumentTypeID IN (1,2,4))`. 0 if no such positions closed. (Tier 2 — SP_eTorian_PnL_NetProfit aggregation of Dim_Position.NetProfit) |
| 8 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to `GETDATE()` on each daily run. (Tier 2 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | eTorian population filter — PlayerLevelID=4 |
| UserName | DWH_dbo.Dim_Customer | UserName | Passthrough |
| CloseDate | DWH_dbo.Dim_Position | CloseOccurred | CAST to DATE |
| EOM_CloseDate | DWH_dbo.Dim_Position | CloseOccurred | EOMONTH(CAST(...AS DATE)) |
| NetProfit_Crypto | DWH_dbo.Dim_Position | NetProfit | SUM WHERE InstrumentTypeID=10 |
| NetProfit_Stocks_ETFs | DWH_dbo.Dim_Position | NetProfit | SUM WHERE InstrumentTypeID IN (5,6) |
| NetProfit_Other | DWH_dbo.Dim_Position | NetProfit | SUM WHERE InstrumentTypeID IN (1,2,4) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (snapshot for @Date)
  + DWH_dbo.Dim_Customer (UserName)
  WHERE PlayerLevelID=4, AccountTypeID IN (7,13), not banned/deactivated
  → #list (eTorian population: CID × UserName)

DWH_dbo.Dim_Position (CloseDateID = @DateID)
  JOIN #list ON CID
  JOIN DWH_dbo.Dim_Instrument ON InstrumentID
  GROUP BY CID, UserName, CloseDate
  SUM NetProfit by InstrumentTypeID bucket
  → #pos

DELETE + INSERT → BI_DB_dbo.BI_DB_eTorian_NetProfit
```

---

## 6. Relationships

| Related Object | Relationship | Join |
|---------------|-------------|------|
| DWH_dbo.Dim_Customer | Source (UserName, status) | `Dim_Customer.RealCID = CID` |
| DWH_dbo.Dim_Position | Source (closed position NetProfit) | `Dim_Position.CID = CID AND CloseDateID = CloseDate` |
| DWH_dbo.Dim_Instrument | Source (instrument type classification) | `Dim_Instrument.InstrumentID = Dim_Position.InstrumentID` |
| BI_DB_dbo.BI_DB_eTorian_PnL | Companion: unrealized PnL at month-end | Same SP, end-of-month write |

---

## 7. Sample Queries

### Monthly P&L summary per Popular Investor
```sql
SELECT CID,
       UserName,
       EOM_CloseDate,
       SUM(NetProfit_Crypto)      AS Monthly_Crypto,
       SUM(NetProfit_Stocks_ETFs) AS Monthly_Stocks,
       SUM(NetProfit_Other)       AS Monthly_Other,
       SUM(NetProfit_Crypto + NetProfit_Stocks_ETFs + NetProfit_Other) AS TotalNetProfit
FROM BI_DB_dbo.BI_DB_eTorian_NetProfit
WHERE EOM_CloseDate = '2026-03-31'
GROUP BY CID, UserName, EOM_CloseDate
ORDER BY TotalNetProfit DESC;
```

### Top crypto-profit PIs over last quarter
```sql
SELECT CID, UserName,
       SUM(NetProfit_Crypto) AS TotalCryptoProfit
FROM BI_DB_dbo.BI_DB_eTorian_NetProfit
WHERE CloseDate BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY CID, UserName
ORDER BY TotalCryptoProfit DESC;
```

### Active trading days per PI in 2026
```sql
SELECT CID, UserName, COUNT(DISTINCT CloseDate) AS ActiveDays
FROM BI_DB_dbo.BI_DB_eTorian_NetProfit
WHERE CloseDate >= '2026-01-01'
GROUP BY CID, UserName
ORDER BY ActiveDays DESC;
```

---

## 8. Atlassian / External References

No Jira tickets or Confluence pages identified for this table during documentation.

---

*Generated: 2026-04-22 | Batch 37 | Quality: 9.2/10*

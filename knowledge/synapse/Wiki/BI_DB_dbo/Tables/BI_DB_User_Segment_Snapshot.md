---
schema: BI_DB_dbo
table: BI_DB_User_Segment_Snapshot
documented: true
batch: 37
quality_score: 9.1
---

# BI_DB_User_Segment_Snapshot

## 1. Business Meaning

Daily per-customer snapshot of three segmentation dimensions used for risk profiling, product targeting, and regulatory analytics:

1. **Risk segment** — ABC risk model score (RiskIndex 1-10, grouped to A/B/C) based on equity-weighted average portfolio standard deviation across all qualifying dates
2. **Deposit segment** — customer's lifetime deposit tier (ND/Low/Mid/High)
3. **Activity segment** — trading behavior classification (Investor/Trader/Crypto) updated monthly

This is one of eToro's primary customer segmentation tables, populated since 2013. It covers the active trading population: customers with ≥$50 equity and at least one deposit.

| Property | Value |
|----------|-------|
| Grain | One row per `Date × RealCID` |
| Population | Customers with equity+PnL ≥ $50 AND at least one deposit |
| Date range | 20130101 – 20260412 (4,845 dates) |
| Row count per day | ~9.7M (as of 2026-04-12) |
| Distribution | HASH(RealCID) |
| Index | CLUSTERED (Date, RealCID) |

---

## 2. Business Logic

### 2.1 ETL Pattern

Written daily by `SP_User_Segment_Snapshot @Yesterday DateTime`. The SP:
1. Refreshes three intermediate staging tables (`BI_DB_EquitySnapshots`, `BI_DB_STDSnapshots`, `BI_DB_DepositSnapshots`) for `@Date`
2. Computes the ABC risk model across all historical qualifying dates per customer
3. Computes lifetime deposits through `@Date`
4. Inserts new rows (DELETE + INSERT on `Date = @Date`) carrying forward `ActivitySegment` from the previous day
5. **End-of-month only**: runs a second pass to UPDATE `ActivitySegment` based on the last 6 months of commission and equity data

### 2.2 ABC Risk Model (RiskIndex)

The risk model computes a **lifetime equity-weighted average standard deviation** for each customer:

```
AvgSTD = SUM(RealizedEquity × StandardDeviation) / SUM(RealizedEquity)
         (over all dates where equity + PnL >= $50 AND StandardDeviation >= 0)
```

This weighted average is then mapped to a 1–10 RiskIndex:

| RiskIndex | AvgSTD Range | RiskGroup | Description |
|-----------|-------------|-----------|-------------|
| 1 | < 0.0011 | A | Very low risk — minimal portfolio volatility |
| 2 | 0.0011–0.0024 | A | Low risk |
| 3 | 0.0024–0.004 | A | Slightly low risk |
| 4 | 0.004–0.0055 | B | Moderate-low risk |
| 5 | 0.0055–0.0079 | B | Moderate risk |
| 6 | 0.0079–0.0111 | B | Moderate-high risk |
| 7 | 0.0111–0.0158 | B | Above-average risk |
| 8 | 0.0158–0.0316 | C | High risk |
| 9 | 0.0316–0.0475 | C | Very high risk |
| 10 | ≥ 0.0475 | C | Maximum risk |

RiskGroup: A = indices 1–3, B = 4–7, C = 8–10.

Observed distribution for 2026-04-12 (9.7M customers): RiskIndex 5–6 are most common (~4.1M combined). Group B covers ~64% of the population, Group A ~17%, Group C ~15%.

### 2.3 Lifetime Deposit Tier (LTDeposit / DepositGroup)

`LTDeposit` is the cumulative sum of all deposit amounts (ActionTypeID=7 in `Fact_CustomerAction`) from the customer's first deposit through `@Date`. It is **not** the deposit on `@Date` — it is lifetime-to-date.

| DepositGroup | LTDeposit Range | Meaning |
|-------------|-----------------|---------|
| ND | 0 | No deposits (rare — see Population Filter note) |
| Low | 0 < LTDeposit ≤ 500 | Low lifetime depositor |
| Mid | 500 < LTDeposit ≤ 5,000 | Medium lifetime depositor |
| High | LTDeposit > 5,000 | High lifetime depositor |

### 2.4 Activity Segment (Monthly Update)

`ActivitySegment` is updated once per month at end-of-month, using the last 6 months of commission revenue and last month's average equity/positions:

| Segment | Business Rule |
|---------|--------------|
| Crypto | CryptoComm / AllComm ≥ 80%, OR AvgDailyCrypto / SumAllAmount ≥ 60% (when no commission) |
| Trader | FxComm / AllComm ≥ 50% (only when AllComm > 0) |
| Investor | Default for all other active customers |

On non-end-of-month days, `ActivitySegment` carries forward from the previous day's row. Customers with no commission and no equity activity in the month are excluded from the update (their segment stays as the last assigned value or empty string).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH on `RealCID` — queries filtering by `RealCID` avoid data movement. The CLUSTERED INDEX on `(Date, RealCID)` makes date-range queries for a single customer very efficient. Always filter by `Date` to avoid scanning the full 9.7M × 4,845 date history.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's customer risk profile | `WHERE Date = @today GROUP BY RiskGroup, DepositGroup` |
| Risk group trend | `WHERE Date BETWEEN @start AND @end GROUP BY Date, RiskGroup` |
| High-value crypto traders | `WHERE Date = @today AND DepositGroup = 'High' AND ActivitySegment = 'Crypto'` |
| Customer's segment history | `WHERE RealCID = @cid ORDER BY Date` |
| Monthly segment as-of date | Use last day of month — ActivitySegment is authoritative at end-of-month |

### 3.3 Gotchas

- **`ActivitySegment` is only refreshed at end-of-month.** On mid-month dates, `ActivitySegment` is carried forward from the previous day and may reflect last month's classification. Query the last day of any month for the authoritative segment.
- **`ActivitySegment` can be an empty string `''`.** Newer customers or those with no qualifying commission/equity activity in the 6-month window may have `ActivitySegment = ''` rather than NULL. Use `WHERE ActivitySegment = ''` or `ISNULL(ActivitySegment, '') = ''` to catch these.
- **`RiskIndex = 0` means no risk data.** Customers appearing in the table without a valid AvgSTD get `RiskIndex = ISNULL(ri.RiskIndex, 0) = 0`. These are edge cases with deposits but no equity-weighted STD history.
- **Population excludes customers with equity < $50.** Customers whose daily equity drops below $50 on all historical dates will not appear even if they have deposits.
- **`LTDeposit` is cumulative, not daily.** It grows over time and never decreases. Do not use as a same-day deposit metric — use `BI_DB_DepositSnapshots` for that.
- **HASH distribution on RealCID.** Cross-joins to ROUND_ROBIN or other HASH-keyed tables will trigger data movement unless you also filter by RealCID.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 2 — SP ETL code | (Tier 2 — SP_User_Segment_Snapshot) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | int | NOT NULL | Date key in YYYYMMDD integer format. Derived from `@Yesterday` parameter: `CONVERT(VARCHAR, @Yesterday, 112)` cast to INT. Part of CLUSTERED INDEX and DELETE key. (Tier 2 — SP_User_Segment_Snapshot) |
| 2 | RealCID | int | NOT NULL | Real customer ID. The HASH distribution key. Joins to `DWH_dbo.Dim_Customer.RealCID` for customer demographics. Only customers with ≥$50 equity AND deposits appear. (Tier 2 — SP_User_Segment_Snapshot) |
| 3 | RiskIndex | int | NOT NULL | ABC risk model score 1–10 (1=lowest risk, 10=highest). Computed as equity-weighted average portfolio standard deviation (`AvgSTD`) across all historical qualifying dates, then bucketed by threshold. `ISNULL(ri.RiskIndex, 0)` — 0 means no valid risk score. See Section 2.2 for full threshold table. (Tier 2 — SP_User_Segment_Snapshot) |
| 4 | LTDeposit | decimal(38,2) | YES | Cumulative lifetime deposit amount (USD) for this customer through `@Date`. Sourced from `BI_DB_DepositSnapshots` (which aggregates `Fact_CustomerAction.Amount WHERE ActionTypeID=7`). This is a running lifetime total, not a daily deposit amount. (Tier 2 — SP_User_Segment_Snapshot) |
| 5 | RiskGroup | varchar(1) | NOT NULL | Coarse risk bucket derived from RiskIndex. `'A'` = indices 1–3 (low risk); `'B'` = 4–7 (medium risk); `'C'` = 8–10 (high risk). `DEFAULT 'A'` applies when RiskIndex is 0 (ELSE clause maps to 'A'). (Tier 2 — SP_User_Segment_Snapshot) |
| 6 | DepositGroup | varchar(5) | NOT NULL | Lifetime deposit tier derived from LTDeposit. `'ND'` = zero deposits; `'Low'` = ≤$500; `'Mid'` = $501–$5,000; `'High'` > $5,000. In practice 'ND' is extremely rare due to the deposit population filter. (Tier 2 — SP_User_Segment_Snapshot) |
| 7 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last inserted/updated by the ETL pipeline. Set to `GETDATE()` on INSERT; also updated on end-of-month ActivitySegment UPDATE. (Tier 2 — ETL metadata) |
| 8 | ActivitySegment | varchar(50) | YES | Monthly trading behavior classification. Values: `'Investor'` (default, balanced portfolio), `'Trader'` (FX-dominant commissions ≥50%), `'Crypto'` (crypto-dominant ≥80% commission or ≥60% equity). Updated once per month on the last calendar day; carried forward daily otherwise. Can be empty string `''` for unclassified customers. (Tier 2 — SP_User_Segment_Snapshot) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date | ETL parameter @Yesterday | — | CONVERT YYYYMMDD INT |
| RealCID | DWH_dbo.Fact_SnapshotEquity (via BI_DB_EquitySnapshots) | CID | Passthrough — qualifying population only |
| RiskIndex | DWH_dbo.Fact_CustomerUnrealized_PnL (via BI_DB_STDSnapshots) | StandardDeviation | Equity-weighted AvgSTD → threshold buckets |
| LTDeposit | DWH_dbo.Fact_CustomerAction (via BI_DB_DepositSnapshots) | Amount WHERE ActionTypeID=7 | Cumulative SUM through @Date |
| RiskGroup | Derived from RiskIndex | — | CASE buckets A/B/C |
| DepositGroup | Derived from LTDeposit | — | CASE buckets ND/Low/Mid/High |
| ActivitySegment | BI_DB_dbo.BI_DB_DailyCommisionReport + DWH_dbo.Fact_SnapshotEquity + DWH_dbo.Dim_Position | Commissions, AUM, FX positions | End-of-month classification rule |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotEquity → BI_DB_EquitySnapshots (daily snapshot, DATE @Date)
DWH_dbo.Fact_CustomerUnrealized_PnL → BI_DB_STDSnapshots (daily STD, DATE @Date)
DWH_dbo.Fact_CustomerAction (ActionTypeID=7) → BI_DB_DepositSnapshots (daily deposits, DATE @Date)

BI_DB_EquitySnapshots + BI_DB_STDSnapshots (ALL dates WHERE equity+PnL >= 50)
  → #pre2 (qualifying history)
  → #ABCModel (AvgSTD per CID)
  → #ABCModelCID (RiskIndex per CID)

BI_DB_DepositSnapshots (ALL dates <= @Date)
  → #dep (LTDeposit per CID)

#ABCModelCID + #dep
  → DELETE + INSERT → BI_DB_User_Segment_Snapshot

[End-of-month only]
BI_DB_DailyCommisionReport + Fact_SnapshotEquity + Dim_Position
  → #segment (ActivitySegment classification)
  → UPDATE BI_DB_User_Segment_Snapshot SET ActivitySegment
```

---

## 6. Relationships

| Related Object | Relationship | Join |
|---------------|-------------|------|
| DWH_dbo.Dim_Customer | Customer demographics | `Dim_Customer.RealCID = RealCID` |
| BI_DB_dbo.BI_DB_EquitySnapshots | Intermediate equity snapshot (same SP) | `BI_DB_EquitySnapshots.CID = RealCID AND Date = @DateID` |
| BI_DB_dbo.BI_DB_STDSnapshots | Intermediate STD snapshot (same SP) | `BI_DB_STDSnapshots.CID = RealCID AND DateKey = @DateID` |
| BI_DB_dbo.BI_DB_DepositSnapshots | Intermediate deposit snapshot (same SP) | `BI_DB_DepositSnapshots.CID = RealCID AND DateID = @DateID` |
| BI_DB_dbo.BI_DB_DailyCommisionReport | Source for monthly ActivitySegment | `BI_DB_DailyCommisionReport.RealCID = RealCID AND DateID BETWEEN 6-month window` |

---

## 7. Sample Queries

### Customer risk and deposit profile for latest date
```sql
SELECT RiskGroup,
       DepositGroup,
       ActivitySegment,
       COUNT(*) AS Customers
FROM BI_DB_dbo.BI_DB_User_Segment_Snapshot
WHERE Date = 20260412
GROUP BY RiskGroup, DepositGroup, ActivitySegment
ORDER BY RiskGroup, DepositGroup;
```

### High-value crypto customers (today)
```sql
SELECT RealCID, RiskIndex, LTDeposit, ActivitySegment
FROM BI_DB_dbo.BI_DB_User_Segment_Snapshot
WHERE Date = 20260412
  AND DepositGroup = 'High'
  AND ActivitySegment = 'Crypto'
ORDER BY LTDeposit DESC;
```

### Customer segment history
```sql
SELECT Date, RiskIndex, RiskGroup, LTDeposit, DepositGroup, ActivitySegment
FROM BI_DB_dbo.BI_DB_User_Segment_Snapshot
WHERE RealCID = 12345678
ORDER BY Date DESC;
```

### End-of-month segment distribution (authoritative)
```sql
SELECT ActivitySegment, COUNT(*) AS Customers
FROM BI_DB_dbo.BI_DB_User_Segment_Snapshot
WHERE Date = 20260331   -- last day of March 2026
GROUP BY ActivitySegment;
```

---

## 8. Atlassian / External References

No Jira tickets or Confluence pages identified for this table during documentation. Author: Eden L (2017-01-11). Activity segment logic added by Amir (2018-12-16). Parameter changed from Today to Yesterday by Boris (2019-04-01).

---

*Generated: 2026-04-22 | Batch 37 | Quality: 9.1/10*

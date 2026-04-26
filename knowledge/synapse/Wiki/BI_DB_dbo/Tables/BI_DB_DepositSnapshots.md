# BI_DB_DepositSnapshots

> Daily snapshot of total deposit amount per customer. Each row records the sum of all deposit transactions (ActionTypeID=7 from Fact_CustomerAction) for a given customer on a given date. The primary purpose is to feed cumulative deposit aggregation for BI_DB_User_Segment_Snapshot, which classifies customers into DepositGroup tiers (ND / Low / Mid / High) based on $500 and $5,000 thresholds.

**Schema**: BI_DB_dbo | **Object Type**: Table | **Quality**: 9.5/10

---

## Properties

| Property | Value |
|---|---|
| **Distribution** | HASH(CID) |
| **Index** | CLUSTERED INDEX (DateID ASC, CID ASC) |
| **Row Count** | ~38.4M rows (2013-01-01 to 2026-04-12) |
| **Distinct CIDs** | ~5.86M |
| **Distinct Dates** | ~4,845 |
| **Writer SP** | SP_User_Segment_Snapshot |
| **Write Pattern** | DELETE WHERE DateID=@Date + INSERT (daily refresh) |
| **UC Status** | Not Migrated |
| **Co-Written With** | BI_DB_EquitySnapshots, BI_DB_STDSnapshots, BI_DB_User_Segment_Snapshot (same SP run) |

---

## Business Context

`BI_DB_DepositSnapshots` is a daily per-customer deposit total table. It is **not** a running cumulative balance — each row is one day's deposit amount for one customer. The downstream consumer `SP_User_Segment_Snapshot` aggregates it with a SUM (aliased `#dep`) to compute total historical deposits per customer, then applies thresholds to assign a `DepositGroup`:

| DepositGroup | Threshold |
|---|---|
| ND | SUM = 0 (never deposited) |
| Low | 0 < SUM < $500 |
| Mid | $500 ≤ SUM < $5,000 |
| High | SUM ≥ $5,000 |

The HASH(CID) distribution ensures deposit snapshot queries keyed on customer ID are co-located with Dim_Customer (also HASH(RealCID)) without shuffle.

---

## Column Elements

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | DateID | int | YES | Tier 2 | Integer date key in YYYYMMDD format. Matches the @Date parameter passed to SP_User_Segment_Snapshot. Partition anchor — DELETE+INSERT cycles use this key. Clustered index leading key. |
| 2 | CID | int | NO | Tier 1 | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 3 | TotalDeposit | decimal(38,2) | YES | Tier 2 | Total deposit amount in USD for this customer on DateID. Computed as SUM(Amount) from DWH_dbo.Fact_CustomerAction WHERE ActionTypeID=7 AND DateID=@Date, grouped by RealCID. YTD 2026: min=$0.03, max=$10,000,000, avg=$1,332.45. |
| 4 | UpdateDate | datetime | YES | Tier 2 | Timestamp of the SP execution that wrote this row. Set to GETDATE() at INSERT time. Used for operational monitoring of SP_User_Segment_Snapshot run currency. |

---

## ETL Pipeline

```
etoro.History.Credit (CreditTypeID=1 = real deposit transactions)
  → DWH_dbo.Fact_CustomerAction (ActionTypeID=7 rows, Amount in USD)
  |-- SP_User_Segment_Snapshot @Date --|
     DELETE FROM BI_DB_DepositSnapshots WHERE DateID=@Date
     INSERT INTO BI_DB_DepositSnapshots
       SELECT @Date, RealCID, SUM(Amount), GETDATE()
       FROM Fact_CustomerAction
       WHERE ActionTypeID=7 AND DateID=@Date
       GROUP BY RealCID
  v
BI_DB_dbo.BI_DB_DepositSnapshots (38.4M rows, 2013–2026)
  |-- Consumed by SP_User_Segment_Snapshot as #dep for DepositGroup --|
```

---

## Sample Queries

```sql
-- Deposits on a specific date
SELECT CID, TotalDeposit
FROM BI_DB_dbo.BI_DB_DepositSnapshots
WHERE DateID = 20260101
ORDER BY TotalDeposit DESC;
```

```sql
-- Cumulative deposit per customer (mirrors DepositGroup logic)
SELECT CID, SUM(TotalDeposit) AS CumulativeDeposit
FROM BI_DB_dbo.BI_DB_DepositSnapshots
GROUP BY CID
HAVING SUM(TotalDeposit) >= 5000  -- High tier
ORDER BY CumulativeDeposit DESC;
```

```sql
-- Daily deposit volume trend
SELECT DateID, COUNT(*) AS Depositors, SUM(TotalDeposit) AS TotalVolumeUSD
FROM BI_DB_dbo.BI_DB_DepositSnapshots
WHERE DateID BETWEEN 20260101 AND 20261231
GROUP BY DateID
ORDER BY DateID;
```

---

## Relationships

| Related Object | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Enrich with country, regulation, player level |
| DWH_dbo.Fact_CustomerAction | ON CID = RealCID AND DateID = DateID | Source data (ActionTypeID=7) |
| BI_DB_dbo.BI_DB_User_Segment_Snapshot | ON CID = CID (via #dep SUM) | Downstream consumer — DepositGroup classification |
| BI_DB_dbo.BI_DB_EquitySnapshots | Co-written in same SP run | Equity snapshot for same @Date |
| BI_DB_dbo.BI_DB_STDSnapshots | Co-written in same SP run | STD snapshot for same @Date |

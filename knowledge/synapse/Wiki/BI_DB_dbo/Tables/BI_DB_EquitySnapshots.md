# BI_DB_dbo.BI_DB_EquitySnapshots

> 13.37-billion-row daily equity snapshot table capturing each customer's realized equity per date, covering Jan 2013–Apr 2026 (13+ years). One row per (Date × CID) reflecting the active SCD snapshot from `Fact_SnapshotEquity` on that date. Serves as a foundational intermediate table in `SP_User_Segment_Snapshot` — its data feeds the weighted standard deviation risk model that produces `RiskIndex` in `BI_DB_User_Segment_Snapshot`. Written daily by the first block of `SP_User_Segment_Snapshot` via DELETE+INSERT from `DWH_dbo.Fact_SnapshotEquity` filtered through `Dim_Range`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.Fact_SnapshotEquity` — active SCD row for each CID on `@Date` (filtered via `Dim_Range.FromDateID ≤ @Date ≤ ToDateID`) |
| **Refresh** | Daily — DELETE WHERE Date=@Date + INSERT (via `SP_User_Segment_Snapshot`, first block) |
| **OpsDB Priority** | 20 (SB_Daily) — depends on BI_DB_DailyCommisionReport |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_EquitySnapshots` is a **13.37-billion-row daily equity snapshot** that materialises each customer's `RealizedEquity` (from `Fact_SnapshotEquity`) against a flat date key. The underlying `Fact_SnapshotEquity` table uses a Slowly Changing Dimension design — it stores date ranges rather than one row per CID per day. `BI_DB_EquitySnapshots` "explodes" those SCD rows into a simple (Date, CID) grain by joining to `Dim_Range` and filtering on the requested date.

**Why it exists**: The SCD design of `Fact_SnapshotEquity` makes direct historical equity lookups expensive. This table provides an optimised HASH(CID) snapshot for:
1. **Risk model**: The next step in `SP_User_Segment_Snapshot` JOINs this table with `BI_DB_STDSnapshots` to compute weighted average standard deviation per CID, producing the `RiskIndex` classification in `BI_DB_User_Segment_Snapshot`
2. **Historical equity time series**: Any query needing per-CID equity on arbitrary dates benefits from this pre-materialised form

**Size context**: 13.37 billion rows is the cumulative result of 13+ years × ~1–1.5M active customers per day. A comment in the SP code notes "2,298,557,131 rows" for a prior date — the table has grown substantially since that comment was written.

**SCD mechanics**: The Dim_Range JOIN condition `DR.ToDateID >= @Date AND DR.FromDateID <= @Date` picks the one active SCD row per CID whose date range spans the requested date, materialising the point-in-time equity into a single flat row. Dates before a customer's first snapshot will have no row.

---

## 2. Business Logic

### 2.1 Daily DELETE + INSERT from SCD Snapshot

**What**: Each day, the SP deletes the existing row for Date=@Date and inserts a fresh snapshot from the active Fact_SnapshotEquity row.

**Columns Involved**: Date, CID, RealizedEquity, UpdateDate

**Rules**:
- `DELETE FROM BI_DB_EquitySnapshots WHERE Date = @Date` — ensures idempotent refresh
- `INSERT` from `Fact_SnapshotEquity SE INNER JOIN Dim_Range DR ON SE.DateRangeID=DR.DateRangeID WHERE DR.ToDateID>=@Date AND DR.FromDateID<=@Date` — picks the active SCD row
- Exactly one SCD row exists per CID per date (Dim_Range enforces no-overlap ranges)
- `Date` = `CONVERT(VARCHAR,@Yesterday,112)` cast as INT — the ETL parameter is @Yesterday, so this snapshot captures yesterday's equity

### 2.2 Role as Intermediate in User Segment Snapshot

**What**: This table is not a standalone analytics table — it is used as an intermediate store in `SP_User_Segment_Snapshot` to persist the daily equity snapshot before joining to STD data.

**Columns Involved**: Date, CID, RealizedEquity

**Rules**:
- After INSERT, the SP immediately reads back: `SELECT ... FROM BI_DB_EquitySnapshots R INNER JOIN BI_DB_STDSnapshots C ON R.Date=C.DateKey AND R.CID=C.CID WHERE R.Date<=@Date AND C.DateKey<=@Date AND RealizedEquity+PositionPnL >= 50`
- The `>=50` filter (equity ≥ $50) excludes inactive/zero-balance accounts from the risk model
- All historical dates are preserved — the risk model uses the full history (`WHERE R.Date <= @Date AND C.DateKey <= @Date`) to compute the weighted average standard deviation

### 2.3 Equity Accumulation for Risk Weighting

**What**: Historical RealizedEquity values (accumulated across all dates up to today) serve as weights in the risk score calculation.

**Columns Involved**: RealizedEquity

**Rules**:
- `RiskIndex = SUM(RealizedEquity * StandardDeviation) / SUM(RealizedEquity)` (computed in #ABCModel temp table)
- Customers with positive RealizedEquity provide a weighted average STD; zero-equity customers get RiskIndex=0
- This means the table is NOT cleared periodically — full history is retained for the risk weighting algorithm

---

## 3. Query Advisory

### 3.1 Distribution and Index

- **HASH(CID)**: Optimal for CID-specific queries and JOINs on CID (e.g., joining to BI_DB_STDSnapshots or Dim_Customer)
- **Clustered index on (Date, CID)**: Use `WHERE Date=@d` for date-specific slices and `WHERE CID=@cid` for customer history

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer equity on a specific date | `WHERE Date=@d AND CID=@cid` — uses HASH locality + clustered index |
| Most recent equity for a set of CIDs | `WHERE Date=(SELECT MAX(Date) FROM BI_DB_EquitySnapshots)` |
| Customers with equity >= $X on a date | `WHERE Date=@d AND RealizedEquity >= @X` |
| 30-day equity trend for a CID | `WHERE CID=@cid AND Date BETWEEN @start AND @end ORDER BY Date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_STDSnapshots | Date=DateKey AND CID=CID | Risk model — combines equity with position standard deviation |
| DWH_dbo.Dim_Customer | CID=RealCID | Enrich with customer attributes |
| BI_DB_User_Segment_Snapshot | CID=RealCID AND Date=Date | Compare equity snapshot to computed segment |

### 3.4 Gotchas

- **13.37 billion rows** — always filter on Date and/or CID; full table scans are impractical
- **No row before first snapshot date** — a customer with no Fact_SnapshotEquity record for a date has no row here; LEFT JOIN accordingly
- **RealizedEquity=0 is valid** — zero equity rows exist and represent customers with no open positions (fully in cash or withdrawn); do not treat as missing data
- **Date = @Yesterday** — the SP parameter is @Yesterday (previous calendar day), not today; a run on 2026-04-13 inserts Date=20260412
- **NOLOCK hints in SP** — the writer SP uses `WITH (NOLOCK)` on source joins; equity values may reflect uncommitted transactions from Fact_SnapshotEquity

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from DWH_dbo wiki (DWH_dbo wiki is Tier 1 source for BI_DB_dbo per config) |
| Tier 2 | From SP code (`SP_User_Segment_Snapshot`) |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — unverified |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | int | NULL | Date dimension key (YYYYMMDD integer). Identifies the snapshot date. Clustered index key (with CID). Range: 20130101–20260412. (Tier 2 — SP_User_Segment_Snapshot) |
| 2 | CID | int | NOT NULL | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 — DWH_dbo.Fact_SnapshotEquity) |
| 3 | RealizedEquity | money | NOT NULL | Total account value. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise computed as TotalCash + TotalPositionsAmount + InProcessCashouts. Confluence definition: "Unrealized Equity — the total funds in the account, including profit/loss from open positions. The Portfolio value figure represented on the platform is Unrealized equity." (Tier 2 — DWH_dbo.Fact_SnapshotEquity) |
| 4 | UpdateDate | datetime | NULL | ETL timestamp set to GETDATE() at INSERT time. NULL for legacy rows predating UpdateDate column addition (earliest data from 2013). (Tier 2 — SP_User_Segment_Snapshot) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date | SP parameter | @Yesterday | CONVERT(VARCHAR,@Yesterday,112) cast to INT |
| CID | DWH_dbo.Fact_SnapshotEquity | CID | Direct passthrough |
| RealizedEquity | DWH_dbo.Fact_SnapshotEquity | RealizedEquity | Direct passthrough from active SCD row (Dim_Range filter) |
| UpdateDate | ETL | GETDATE() | Set at INSERT time |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotEquity  (SCD equity snapshot — one row per CID per date range)
  |-- INNER JOIN DWH_dbo.Dim_Range ON DateRangeID
  |   Filter: DR.ToDateID >= @Date AND DR.FromDateID <= @Date
  |   (selects the one active SCD row per CID for the requested date)
  |-- SP_User_Segment_Snapshot @Yesterday (first INSERT block, P20 SB_Daily)
  |-- DELETE WHERE Date=@Date
  |-- INSERT (Date, CID, RealizedEquity, GETDATE())
  v
BI_DB_dbo.BI_DB_EquitySnapshots
  (13.37B rows | Jan 2013 – Apr 2026 | HASH(CID), CLUSTERED(Date,CID))
  UC: _Not_Migrated

  Then used immediately as intermediate in same SP:
  BI_DB_EquitySnapshots R
  INNER JOIN BI_DB_STDSnapshots C ON R.Date=C.DateKey AND R.CID=C.CID
  (WHERE RealizedEquity+PositionPnL >= 50)
  → #pre2 → #ABCModel → RiskIndex → BI_DB_User_Segment_Snapshot
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |
| (source) | DWH_dbo.Fact_SnapshotEquity | Primary source — SCD equity snapshots |
| (source) | DWH_dbo.Dim_Range | Date range filter for SCD row selection |

### 6.2 Referenced By

| Object | Column | Usage |
|--------|--------|-------|
| BI_DB_dbo.BI_DB_User_Segment_Snapshot | (intermediate) | Equity snapshot feeds risk model in same SP via #pre2 |
| SP_User_Segment_Snapshot | Date, CID, RealizedEquity | Read back immediately for #pre2 JOIN with BI_DB_STDSnapshots |

---

## 7. Sample Queries

### Customer equity history over time

```sql
SELECT [Date], [RealizedEquity]
FROM [BI_DB_dbo].[BI_DB_EquitySnapshots]
WHERE [CID] = 123456
  AND [Date] BETWEEN 20260101 AND 20260412
ORDER BY [Date]
```

### Average equity for active customers on a given date

```sql
SELECT AVG([RealizedEquity]) AS AvgEquity,
       COUNT(*) AS ActiveCustomers
FROM [BI_DB_dbo].[BI_DB_EquitySnapshots]
WHERE [Date] = 20260412
  AND [RealizedEquity] > 0
```

### Equity snapshot for risk model eligibility (equity + PnL >= $50)

```sql
SELECT E.[CID], E.[RealizedEquity], S.[PositionPnL], S.[StandardDeviation]
FROM [BI_DB_dbo].[BI_DB_EquitySnapshots] E
INNER JOIN [BI_DB_dbo].[BI_DB_STDSnapshots] S ON E.[Date] = S.[DateKey] AND E.[CID] = S.[CID]
WHERE E.[Date] = 20260412
  AND E.[RealizedEquity] + ISNULL(S.[PositionPnL], 0) >= 50
ORDER BY E.[RealizedEquity] DESC
```

---

## 8. Atlassian Knowledge Sources

No dedicated Confluence or Jira pages found. See `Fact_SnapshotEquity` DWH wiki for related Confluence documentation on equity snapshot definitions.

---

*Generated: 2026-04-22 | Quality: 9.0/10 | Phases: 14/14*
*Tiers: 2 T1, 2 T2, 0 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_EquitySnapshots | Type: Table | Production Source: DWH_dbo.Fact_SnapshotEquity*

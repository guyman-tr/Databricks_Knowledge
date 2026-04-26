# BI_DB_dbo.BI_DB_DailyGain_History

> 412.7M-row daily cumulative history of anonymized monthly gain calculations from the Rankings service, tracking per-user portfolio performance (cash, investment, PnL, equity, cash flows, and gain percentage) from February 2013 to present — 6.2M distinct user IDs per month, refreshed daily via SP_DailyGain_History (delete current month + insert today from Bronze Parquet lake source).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Rankings Bronze data lake: `/internal-sources/Bronze/Rankings/History/MonthlyGainAnon/` (Parquet) via SP_Create_Rankings_History_MonthlyGainAnon_Range → DailyGain staging → SP_DailyGain_History |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE current month rows + INSERT today from DailyGain staging |
| **Synapse Distribution** | HASH([ID]) |
| **Synapse Index** | CLUSTERED INDEX([EndPeriod] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_DailyGain_History is the daily cumulative history table for the eToro Rankings service's anonymized monthly gain calculations. Each row represents one user's portfolio performance snapshot for a specific period within a month — capturing the start-of-period and end-of-period financial state (cash, investment, PnL, equity), cash flow movements (deposits and withdrawals), and the computed gain percentage.

The table contains 412.7M rows spanning February 2013 to April 2026, with approximately 6.2M distinct user IDs (GUIDs matching Dim_Customer.ID) per month across 160 distinct EndPeriod dates. The data is monthly in granularity — each StartPeriod is the 1st of the month and EndPeriod advances daily within the month.

The ETL pattern is a daily delete-and-insert: SP_DailyGain_History first calls SP_Create_Rankings_History_MonthlyGainAnon_Range which loads today's Bronze Parquet files from the data lake into the `BI_DB_dbo.DailyGain` staging table via `COPY INTO`. Then SP_DailyGain_History deletes rows for the current month (from the 2nd of the month to @date) and inserts today's snapshot from DailyGain. This means within-month data is overwritten daily with the latest calculation.

The primary downstream consumer is SP_PI_Gain, which joins this table with Dim_Customer (on ID) and Fact_SnapshotCustomer to compute compound monthly/quarterly/yearly gain metrics for Popular Investors and Smart Portfolios, feeding the BI_DB_PI_Gain table used in PI ranking dashboards.

---

## 2. Business Logic

### 2.1 Period Accumulation Pattern

**What**: Each row represents a user's cumulative portfolio state from the 1st of the month to EndPeriod.
**Columns Involved**: StartPeriod, EndPeriod, all Start*/End* columns
**Rules**:
- StartPeriod is always the 1st of the month
- EndPeriod advances daily within the month (e.g., Apr 1 → Apr 2, Apr 1 → Apr 3, etc.)
- Start columns capture the portfolio state at month open; End columns capture state at EndPeriod
- Within-month rows are overwritten daily — only the latest EndPeriod per month is current

### 2.2 Equity Decomposition

**What**: Portfolio equity is decomposed into cash, investment, and PnL components.
**Columns Involved**: StartCash, StartInvestment, StartPnL, StartEquity, EndCash, EndInvestment, EndPnL, EndEquity
**Rules**:
- Equity = Cash + Investment + PnL (when all components are non-null)
- Investment and PnL are NULL for users with no open positions (~57% of rows)
- Cash can be negative (margin/credit scenarios)
- Average equity is approximately $2,540 per user

### 2.3 Gain Calculation

**What**: The Gain column represents the period return percentage, incorporating cash flow adjustments.
**Columns Involved**: Gain, DeltaGain, PositiveCashFlows, NegativeCashFlows, AdjustedCash
**Rules**:
- Gain is a percentage (not decimal) — SP_PI_Gain uses `1 + Gain/100` in compound calculations
- Gain = 0.0 for users with no trading activity (most common case)
- Range: -49,800% to 401,200% (extreme outliers exist)
- DeltaGain represents the daily change in gain
- PositiveCashFlows (deposits) are NULL for ~92% of rows; NegativeCashFlows (withdrawals) NULL for ~99%
- AdjustedCash is the cash balance adjusted for flows, used in gain calculation; never NULL

### 2.4 Trading Activity Flag

**What**: Binary indicator of whether the user had any trading activity in the period.
**Columns Involved**: HasTradingActivity
**Rules**:
- True (~45%), False (~27%), NULL (~28%) in current month
- NULL appears to represent users whose activity status was not evaluated (possibly inactive accounts)
- SP_PI_Gain does not filter on this flag — it uses the Gain value directly

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH([ID]) — optimized for per-user queries and JOINs on ID
- **Clustered Index**: EndPeriod ASC — efficient for date-range filtering
- Always filter by EndPeriod for time-bounded queries to leverage the clustered index

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest gain for a specific user | `WHERE ID = @guid AND EndPeriod = (SELECT MAX(EndPeriod) FROM BI_DB_DailyGain_History)` |
| Monthly gain summary | Filter `WHERE DAY(EndPeriod) = DAY(EOMONTH(EndPeriod))` for end-of-month snapshots |
| Users with positive gains this month | `WHERE EndPeriod >= '2026-04-01' AND Gain > 0` |
| Active traders only | `WHERE HasTradingActivity = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | DailyGain_History.ID = Dim_Customer.ID | Resolve user identity (RealCID, UserName) |
| DWH_dbo.Fact_SnapshotCustomer | Via Dim_Customer.RealCID | Filter by GuruStatus, AccountType, IsValidCustomer |
| BI_DB_dbo.BI_DB_PI_Gain | Downstream — uses this table as source | Compound gain aggregations for PI rankings |

### 3.4 Gotchas

- **ID is a GUID (uniqueidentifier)**, not a CID — use Dim_Customer.ID to resolve to RealCID
- **Gain is a percentage**, not a decimal — 1.15% is stored as `1.15`, not `0.0115`. SP_PI_Gain uses `1 + Gain/100`
- **Within-month data is overwritten daily** — historical mid-month snapshots do not persist. Only end-of-month rows survive
- **Extreme gain values exist** — range from -49,800 to 401,200. Consider filtering outliers for aggregations
- **NULL Investment/PnL** means no open positions, not missing data. ~57% of rows have NULL StartInvestment/StartPnL
- **DailyGain staging table is volatile** — SP_Create_Rankings_History_MonthlyGainAnon_Range drops and recreates it. Do not query DailyGain directly; use DailyGain_History

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest — verified by source system owner |
| Tier 2 | SP code / ETL logic analysis | High — derived from version-controlled code |
| Tier 3 | Live data observation + schema inference | Medium — empirically verified but no code/wiki confirmation |
| Tier 4 | Inferred from naming / context | Lower — best-effort, needs reviewer validation |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard — canonical description for known ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | uniqueidentifier | YES | User identifier (GUID) matching Dim_Customer.ID. Used by SP_PI_Gain to join with Dim_Customer for PI/Portfolio ranking. 6.2M distinct values per month. Not a CID — resolve via Dim_Customer.ID → RealCID. (Tier 3 — Rankings.MonthlyGainAnon) |
| 2 | StartPeriod | datetime2(7) | YES | Start of the gain calculation period. Always the 1st of the month (e.g., 2026-04-01). Combined with EndPeriod defines the accumulation window. (Tier 3 — Rankings.MonthlyGainAnon) |
| 3 | EndPeriod | datetime2(7) | YES | End of the gain calculation period. Advances daily within the month. Used as the clustered index — always filter on this column for date-range queries. Range: 2013-02-01 to present. (Tier 3 — Rankings.MonthlyGainAnon) |
| 4 | StartCash | numeric(19,4) | YES | User's cash balance at the start of the period (1st of month). Can be negative (margin/credit). Part of equity decomposition: Equity = Cash + Investment + PnL. (Tier 3 — Rankings.MonthlyGainAnon) |
| 5 | StartInvestment | numeric(19,4) | YES | User's invested amount at the start of the period. NULL for users with no open positions (~57% of rows). Represents capital allocated to open trades. (Tier 3 — Rankings.MonthlyGainAnon) |
| 6 | StartPnL | numeric(19,4) | YES | User's unrealized profit/loss at the start of the period. NULL for users with no open positions (~57%). Positive = net unrealized gain, negative = net unrealized loss. (Tier 3 — Rankings.MonthlyGainAnon) |
| 7 | StartEquity | numeric(19,4) | YES | User's total equity at the start of the period. Equity = Cash + Investment + PnL. Average ~$2,540. (Tier 3 — Rankings.MonthlyGainAnon) |
| 8 | EndCash | numeric(19,4) | YES | User's cash balance at EndPeriod. Same semantics as StartCash but at the end of the accumulation window. (Tier 3 — Rankings.MonthlyGainAnon) |
| 9 | EndInvestment | numeric(19,4) | YES | User's invested amount at EndPeriod. NULL when no open positions. Same semantics as StartInvestment. (Tier 3 — Rankings.MonthlyGainAnon) |
| 10 | EndPnL | numeric(19,4) | YES | User's unrealized P&L at EndPeriod. NULL when no open positions. Same semantics as StartPnL. (Tier 3 — Rankings.MonthlyGainAnon) |
| 11 | EndEquity | numeric(19,4) | YES | User's total equity at EndPeriod. Equity = Cash + Investment + PnL. Same decomposition as StartEquity. (Tier 3 — Rankings.MonthlyGainAnon) |
| 12 | PositiveCashFlows | numeric(19,4) | YES | Total deposits (positive cash inflows) during the period. NULL for ~92% of rows (no deposits). Used in gain calculation to adjust for external cash movements. (Tier 3 — Rankings.MonthlyGainAnon) |
| 13 | NegativeCashFlows | numeric(19,4) | YES | Total withdrawals (negative cash outflows) during the period. NULL for ~99% of rows (no withdrawals). Used in gain calculation to adjust for external cash movements. (Tier 3 — Rankings.MonthlyGainAnon) |
| 14 | Gain | float | YES | Calculated gain percentage for the period. Stored as percentage (1.15 = 1.15%, not 115%). SP_PI_Gain compounds via `1 + Gain/100`. Range: -49,800 to 401,200 (extreme outliers). 0.0 for users with no activity. (Tier 3 — Rankings.MonthlyGainAnon) |
| 15 | HasTradingActivity | bit | YES | Whether the user had any trading activity during the period. True (~45%), False (~27%), NULL (~28%). NULL likely indicates unevaluated inactive accounts. Not used as a filter by SP_PI_Gain. (Tier 3 — Rankings.MonthlyGainAnon) |
| 16 | DeltaGain | float | YES | Daily change in the gain value. Represents the incremental gain contribution of the most recent day. Range: -100 to 135,500. Most values are 0.0 (no daily change). (Tier 3 — Rankings.MonthlyGainAnon) |
| 17 | AdjustedCash | numeric(19,4) | YES | Cash balance adjusted for cash flow movements during the period. Used in the gain calculation to normalize returns for deposits/withdrawals. Never NULL (0.0000 when no adjustment). (Tier 3 — Rankings.MonthlyGainAnon) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| ID | Rankings.MonthlyGainAnon (Bronze) | ID | Passthrough via DailyGain staging |
| StartPeriod | Rankings.MonthlyGainAnon (Bronze) | StartPeriod | Passthrough |
| EndPeriod | Rankings.MonthlyGainAnon (Bronze) | EndPeriod | Passthrough |
| StartCash | Rankings.MonthlyGainAnon (Bronze) | StartCash | Passthrough |
| StartInvestment | Rankings.MonthlyGainAnon (Bronze) | StartInvestment | Passthrough |
| StartPnL | Rankings.MonthlyGainAnon (Bronze) | StartPnL | Passthrough |
| StartEquity | Rankings.MonthlyGainAnon (Bronze) | StartEquity | Passthrough |
| EndCash | Rankings.MonthlyGainAnon (Bronze) | EndCash | Passthrough |
| EndInvestment | Rankings.MonthlyGainAnon (Bronze) | EndInvestment | Passthrough |
| EndPnL | Rankings.MonthlyGainAnon (Bronze) | EndPnL | Passthrough |
| EndEquity | Rankings.MonthlyGainAnon (Bronze) | EndEquity | Passthrough |
| PositiveCashFlows | Rankings.MonthlyGainAnon (Bronze) | PositiveCashFlows | Passthrough |
| NegativeCashFlows | Rankings.MonthlyGainAnon (Bronze) | NegativeCashFlows | Passthrough |
| Gain | Rankings.MonthlyGainAnon (Bronze) | Gain | Passthrough |
| HasTradingActivity | Rankings.MonthlyGainAnon (Bronze) | HasTradingActivity | Passthrough |
| DeltaGain | Rankings.MonthlyGainAnon (Bronze) | DeltaGain | Passthrough |
| AdjustedCash | Rankings.MonthlyGainAnon (Bronze) | AdjustedCash | Passthrough |

### 5.2 ETL Pipeline

```
Rankings Service (internal computation)
  |-- Bronze export (Parquet) ---|
  v
/internal-sources/Bronze/Rankings/History/MonthlyGainAnon/
  etr_y={year}/etr_ym={month}/etr_ymd={date}
  |-- SP_Create_Rankings_History_MonthlyGainAnon_Range (COPY INTO) ---|
  v
BI_DB_dbo.DailyGain (staging, ROUND_ROBIN HEAP, auto-created)
  |-- SP_DailyGain_History (DELETE month + INSERT @today) ---|
  v
BI_DB_dbo.BI_DB_DailyGain_History (412.7M rows, HASH(ID), CI(EndPeriod))
  |-- SP_PI_Gain (JOIN Dim_Customer, compound gain calc) ---|
  v
BI_DB_dbo.BI_DB_PI_Gain (PI/Portfolio ranking gains)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ID | DWH_dbo.Dim_Customer.ID | User GUID — resolves to RealCID, UserName via Dim_Customer |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| BI_DB_dbo.SP_PI_Gain | JOIN on ID | Reads DailyGain_History to compute compound M/Q/Y gain for PI/Portfolio users → BI_DB_PI_Gain |

---

## 7. Sample Queries

### 7.1 Latest Monthly Gain for a Specific User

```sql
SELECT ID, StartPeriod, EndPeriod, Gain, StartEquity, EndEquity,
       HasTradingActivity, DeltaGain
FROM [BI_DB_dbo].[BI_DB_DailyGain_History]
WHERE ID = 'EC18BA11-EA9E-E411-A16F-0025B500B00D'
  AND EndPeriod >= '2026-04-01'
ORDER BY EndPeriod DESC;
```

### 7.2 End-of-Month Gain Distribution (Active Traders)

```sql
SELECT YEAR(EndPeriod) AS yr, MONTH(EndPeriod) AS mo,
       COUNT(*) AS users,
       AVG(Gain) AS avg_gain,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Gain) OVER() AS median_gain
FROM [BI_DB_dbo].[BI_DB_DailyGain_History]
WHERE HasTradingActivity = 1
  AND EndPeriod = EOMONTH(EndPeriod)
  AND EndPeriod >= '2025-01-01'
GROUP BY YEAR(EndPeriod), MONTH(EndPeriod)
ORDER BY yr, mo;
```

### 7.3 Top Gainers This Month with User Details

```sql
SELECT TOP 100 g.ID, dc.RealCID, dc.UserName,
       g.Gain, g.EndEquity, g.HasTradingActivity
FROM [BI_DB_dbo].[BI_DB_DailyGain_History] g
JOIN [DWH_dbo].[Dim_Customer] dc ON g.ID = dc.ID
WHERE g.EndPeriod = (SELECT MAX(EndPeriod) FROM [BI_DB_dbo].[BI_DB_DailyGain_History])
  AND g.HasTradingActivity = 1
ORDER BY g.Gain DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 0 T1, 0 T2, 17 T3, 0 T4, 0 T5 | Elements: 17/17, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_DailyGain_History | Type: Table | Production Source: Rankings Bronze lake (MonthlyGainAnon)*

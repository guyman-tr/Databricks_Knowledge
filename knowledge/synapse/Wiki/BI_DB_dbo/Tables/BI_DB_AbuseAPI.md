# BI_DB_dbo.BI_DB_AbuseAPI

> **DORMANT TABLE — 0 rows.** Legacy copy of Dealing_dbo.Dealing_AbuseAPI (28,290 rows). The writer SP (Dealing_dbo.SP_AbuseAPI) was migrated from BI_DB_dbo to Dealing_dbo in December 2023 (SR-222941) and now writes exclusively to Dealing_dbo.Dealing_AbuseAPI. This BI_DB_dbo DDL remains in the SSDT repo but receives no data. The table's original purpose was detecting API-speed trading abuse: positions opened 3+ times within 1 second per instrument with daily net profit ≥ $5,000.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | (none active — Dealing_dbo.SP_AbuseAPI writes to Dealing_dbo.Dealing_AbuseAPI instead) |
| **Refresh** | None — table is dormant (0 rows). Active counterpart refreshes daily. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CloseDate ASC) |
| **Row Count** | 0 (empty) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AbuseAPI` was designed to detect **API-speed trading abuse** — clients who exploit low-latency connections to open 3 or more positions within 1 second on the same instrument type, with combined daily net profit exceeding $5,000 on positions that were held for 24 hours or less.

**This table is now EMPTY (0 rows).** The writer SP (`SP_AbuseAPI`) was migrated from the BI_DB scope to `Dealing_dbo` in December 2023 by Gili (SR-222941). The SP now inserts into `Dealing_dbo.Dealing_AbuseAPI` (28,290 rows as of 2026-04-27), which is the active counterpart with identical schema.

The original SP logic (authored by Jenia, 2019-12-09):
1. Finds positions closed on @Date that were open ≤24 hours, non-mirror, non-partial-close, valid customers only
2. Filters to customers with ≥3 positions per (OpenDateID, InstrumentType, CID)
3. Computes millisecond differences between consecutive OpenOccurred timestamps (LAG/LEAD)
4. Identifies 3-position clusters where the total time span ≤1,000ms (1 second)
5. Filters to clusters where DailyNetProfit ≥ $5,000
6. Calculates YTD Zero-PnL and commission for flagged CIDs

**Recommendation**: This DDL may be a candidate for cleanup (DROP from SSDT) since the active table lives in Dealing_dbo.

---

## 2. Business Logic

### 2.1 1-Second 3-Position Detection

**What**: Detects clients who open 3+ positions within 1 second on the same instrument type.
**Columns Involved**: PositionID, CID, InstrumentType, OpenOccurred
**Rules**:
- Uses LAG/LEAD window functions partitioned by (OpenDateID, InstrumentType, CID) ordered by OpenOccurred
- MS_Diff = DATEDIFF(MILLISECOND, LAG(OpenOccurred), OpenOccurred)
- A 3-position cluster is flagged when MS_Diff + MS_Diff2 + MS_Diff3 ≤ 1000ms
- All three positions in a flagged cluster are included (via PositionID, PositionID2, PositionID3)

### 2.2 Daily Net Profit Threshold

**What**: Only clusters with significant daily profit are flagged.
**Columns Involved**: DailyNetProfit, NetProfit
**Rules**:
- DailyNetProfit = SUM(NetProfit) per (OpenDateID, InstrumentType, CID) across all qualifying positions
- Filter: DailyNetProfit ≥ $5,000
- Purpose: eliminates low-profit rapid trading that may be legitimate scalping

### 2.3 YTD Commission and Zero Calculations

**What**: Year-to-date P&L including commission for flagged CIDs.
**Columns Involved**: YTD_Zero, YTD_Commission, Zero
**Rules**:
- Zero = NetProfit + FullCommissionOnClose (position-level gross P&L before commission)
- YTD_Zero = cumulative (NetProfit + Commission) for all positions opened YTD by flagged CIDs, including unrealized P&L from BI_DB_PositionPnL
- YTD_Commission = cumulative commission for YTD positions
- Two computation blocks: (a) positions opened within current year, (b) carry-over positions opened before Jan 1 but still open or closed this year

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CI(CloseDate). **Table is empty — no queries will return data.** For the active table, query `Dealing_dbo.Dealing_AbuseAPI` instead.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current abuse detection results | `SELECT * FROM Dealing_dbo.Dealing_AbuseAPI` (active table) |
| Historical abuse by customer | `WHERE CID = X` on Dealing_dbo.Dealing_AbuseAPI |
| Abuse by instrument type | `GROUP BY InstrumentType` on Dealing_dbo.Dealing_AbuseAPI |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer demographics for abuse investigation |
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Full instrument details |
| Dealing_dbo.Dealing_AbuseAPI | (same schema) | Active counterpart with data |

### 3.4 Gotchas

- **TABLE IS EMPTY**: Do not query this table expecting results. Use `Dealing_dbo.Dealing_AbuseAPI` instead.
- **SP writes to Dealing_dbo**: SP_AbuseAPI (Dealing_dbo) writes to Dealing_dbo.Dealing_AbuseAPI, not this table.
- **Legacy SP comment is misleading**: The SP has a comment "insert into dbo.BI_DB_AbuseAPI" but the code actually inserts into Dealing_dbo.Dealing_AbuseAPI.
- **Column count**: DDL has 18 columns (not 19 as listed in OpsDB — the DDL is authoritative).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CloseDate | date | YES | The date the flagged positions were closed. Set to @Date SP parameter. Clustered index key. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 2 | OpenDate | date | YES | The date the flagged positions were opened. Derived as CAST(Dim_Position.OpenOccurred AS DATE). (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 3 | PositionID | bigint | YES | Unique position identifier from the trading platform. One of three positions in a 1-second abuse cluster. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 4 | CID | int | YES | Customer ID of the flagged trader. Only valid customers (IsValidCustomer=1) are included. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 5 | Country | varchar(50) | YES | Customer's country name. Passthrough from Dim_Country.Name via Dim_Customer.CountryID. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 6 | Region | varchar(50) | YES | Customer's marketing region. Passthrough from Dim_Country.Region via Dim_Customer.CountryID. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 7 | InstrumentID | int | YES | Unique identifier for the traded instrument. FK to Dim_Instrument. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 8 | Instrument | varchar(50) | YES | Instrument display name. Passthrough from Dim_Instrument.Name. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 9 | InstrumentType | varchar(50) | YES | Instrument asset class (e.g., Stocks, Crypto, CFD). Passthrough from Dim_Instrument.InstrumentType. Used as partitioning dimension for the 1-second detection. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 10 | OpenOccurred | datetime | YES | Exact open timestamp of the flagged position. Sub-second precision. Used to compute millisecond gaps between consecutive opens. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 11 | CloseOccurred | datetime | YES | Exact close timestamp of the flagged position. Only positions closed within 24 hours of open are included. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 12 | NetProfit | money | YES | Net profit on the individual position (after spread, before commission). From Dim_Position.NetProfit. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 13 | DailyNetProfit | money | YES | Sum of NetProfit across all qualifying positions for the same (OpenDateID, InstrumentType, CID). Must be ≥ $5,000 for the cluster to be flagged. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 14 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at SP execution time. (Tier 5 — Dealing_dbo.SP_AbuseAPI) |
| 15 | FullCommissionOnClose | money | YES | Full commission charged on position close. From Dim_Position.FullCommissionOnClose. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 16 | Zero | money | YES | Position-level gross P&L: NetProfit + FullCommissionOnClose. "Zero" refers to the P&L before commission deduction (what the client sees as their trading result). (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 17 | YTD_Zero | money | YES | Year-to-date cumulative Zero-PnL for the flagged CID across all positions opened from Jan 1 to @Date, including unrealized PnL from BI_DB_PositionPnL. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |
| 18 | YTD_Commission | money | YES | Year-to-date cumulative commission for the flagged CID across all positions opened from Jan 1 to @Date. (Tier 2 — Dealing_dbo.SP_AbuseAPI) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CloseDate | Dim_Date.FullDate | FullDate | = @Date parameter |
| OpenDate | Dim_Position | OpenOccurred | CAST AS DATE |
| PositionID | Dim_Position | PositionID | Passthrough |
| CID | Dim_Position | CID | Passthrough |
| Country | Dim_Country | Name | Passthrough via Dim_Customer.CountryID |
| Region | Dim_Country | Region | Passthrough via Dim_Customer.CountryID |
| InstrumentID | Dim_Position | InstrumentID | Passthrough |
| Instrument | Dim_Instrument | Name | Passthrough |
| InstrumentType | Dim_Instrument | InstrumentType | Passthrough |
| OpenOccurred | Dim_Position | OpenOccurred | Passthrough |
| CloseOccurred | Dim_Position | CloseOccurred | Passthrough |
| NetProfit | Dim_Position | NetProfit | Passthrough |
| DailyNetProfit | ETL-computed | SUM(NetProfit) by day/type/CID | Aggregation |
| UpdateDate | SP_AbuseAPI | GETDATE() | ETL timestamp |
| FullCommissionOnClose | Dim_Position | FullCommissionOnClose | Passthrough |
| Zero | ETL-computed | NetProfit + FullCommissionOnClose | Computation |
| YTD_Zero | ETL-computed | Complex YTD aggregation | Multi-source (Dim_Position + BI_DB_PositionPnL) |
| YTD_Commission | ETL-computed | Complex YTD aggregation | Multi-source (Dim_Position + BI_DB_PositionPnL) |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position + Dim_Instrument + Dim_Customer + Dim_Country
  |-- Dealing_dbo.SP_AbuseAPI @Date ---|
  |   1-second cluster detection (LAG/LEAD)
  |   DailyNetProfit >= $5,000 filter
  |   YTD P&L from BI_DB_PositionPnL
  v
Dealing_dbo.Dealing_AbuseAPI (28,290 rows — ACTIVE)

BI_DB_dbo.BI_DB_AbuseAPI (0 rows — DORMANT, legacy DDL)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (via RealCID) |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| PositionID | DWH_dbo.Dim_Position | Position dimension |
| (schema sibling) | Dealing_dbo.Dealing_AbuseAPI | Active counterpart with identical schema |

### 6.2 Referenced By (other objects point to this)

No known consumers — table is empty.

---

## 7. Sample Queries

### 7.1 Check Active Counterpart

```sql
-- This table is empty. Query the active Dealing_dbo counterpart:
SELECT TOP 10 *
FROM [Dealing_dbo].[Dealing_AbuseAPI]
ORDER BY CloseDate DESC
```

### 7.2 Abuse Summary by Instrument Type (Active Table)

```sql
SELECT InstrumentType, COUNT(DISTINCT CID) AS flagged_customers, COUNT(*) AS flagged_positions,
       SUM(NetProfit) AS total_net_profit
FROM [Dealing_dbo].[Dealing_AbuseAPI]
GROUP BY InstrumentType
ORDER BY flagged_customers DESC
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence or Jira sources found for BI_DB_AbuseAPI. Migration ticket: SR-222941 (2023-12-19, Gili).

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 0 T1, 16 T2, 0 T3, 0 T4, 1 T5 | Elements: 18/18, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_AbuseAPI | Type: Table | Production Source: (dormant — active in Dealing_dbo)*

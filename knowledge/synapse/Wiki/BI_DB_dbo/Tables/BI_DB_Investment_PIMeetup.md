# BI_DB_dbo.BI_DB_Investment_PIMeetup

> 121.4M-row daily copy-trading financial performance tracker for the PI Meetup initiative — recording each copier's mirror relationship net value, PnL, and money flow (NMI, MoneyIn, MoneyOut) for positions opened on or after the MeetUp anchor date (2025-08-01). One row per CID × MirrorID × DateID for open positions. Date range: Sep 2025 – Apr 2026 (212 daily snapshots). Sources: CopyFromLake.etoro_History_Mirror (money operations), Dim_Position (position equity), Dim_Mirror (mirror allocation). Daily delete-insert via SP_CID_Investment_PIMeetup.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Copy-Trading Analytics — PI Meetup Daily) |
| **Production Source** | Derived — CopyFromLake.etoro_History_Mirror + DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror by SP_CID_Investment_PIMeetup |
| **Refresh** | Daily delete-insert by DateID (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_Investment_PIMeetup` is a **daily snapshot** of copy-trading financial performance designed for the Popular Investor (PI) Meetup initiative. It tracks each copier's relationship-level performance: how much money was invested (NMI), the current net value of the copy (Platform_NetValue), and the PnL relative to invested capital.

The table holds 121.4M rows across 212 daily snapshots from September 2025 to April 2026. Each row represents one CID × MirrorID for a specific date, covering only positions opened on or after 2025-08-01 (the "MeetUpDate" anchor — hardcoded in the SP).

### Financial Framework

- **Calc1**: The mirror's current allocated amount from Dim_Mirror.Amount
- **Calc2**: SUM of (Amount + PnLInDollars) across all open positions in this mirror — the position-level equity
- **Platform_NetValue**: Calc1 + Calc2 — what the copier sees in the platform under "Net Value"
- **NMI** (Net Money Invested): Net of all money operations — MoneyIn minus MoneyOut
- **Platform_Pnl**: Platform_NetValue − NMI — the actual profit/loss on invested capital

### Mirror Operations

From `etoro_History_Mirror`:
- **MirrorOperationID = 1**: Money In (add funds to copy)
- **MirrorOperationID = 2**: Money Out (withdraw from copy, stored as positive → negated)
- **MirrorOperationID = 3**: Adjustment (positive = in, negative = out)

---

## 2. Business Logic

### 2.1 Net Money Invested (NMI)

**What**: Net cash flow into the copy relationship.
**Columns Involved**: NMI, MoneyIn, MoneyOut
**Rules**:
- NMI = SUM(CASE WHEN op=2 THEN -1×Amount ELSE Amount END) for operations 1,2,3
- MoneyIn = SUM where op=1 OR (op=3 AND Amount>0)
- MoneyOut = SUM where op=2 OR (op=3 AND Amount<=0) — stored as positive (already negated)
- NMI = MoneyIn - MoneyOut

### 2.2 Platform Net Value and PnL

**What**: Total value and performance of the copy relationship.
**Columns Involved**: Calc1, Calc2, Platform_NetValue, Platform_Pnl
**Rules**:
- Platform_NetValue = Calc1 + Calc2 (mirror allocation + position equity)
- Platform_Pnl = Platform_NetValue − NMI (profit/loss relative to invested capital)
- Negative Platform_Pnl = copier has lost money on this copy

### 2.3 MeetUp Date Filter

**What**: Only positions opened on or after 2025-08-01 are included.
**Columns Involved**: (filters Dim_Position)
**Rules**:
- `pos.OpenDateID >= 20250801` — hardcoded "MeetUpDate" anchor
- Only open positions: `pos.CloseDateID = 0`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID ASC. Large table (121.4M rows). Always filter on DateID for efficient index seeks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest snapshot for all copiers | `WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_Investment_PIMeetup)` |
| PnL distribution for a PI | `WHERE ParentCID = @pid AND DateID = @latest` |
| Total net value trend | `SELECT DateID, SUM(Platform_NetValue) GROUP BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Mirror | MirrorID (cast) | Full mirror relationship details |
| DWH_dbo.Dim_Customer | CID or ParentCID (cast to int) | Customer details |

### 3.4 Gotchas

- **All ID columns are varchar(8)**: CID, MirrorID, ParentCID, DateID, RunDateID, MirrorOpenID are all varchar despite being numeric IDs. CAST to INT for JOINs with DWH tables
- **Hardcoded MeetUp date**: OpenDateID >= 20250801 is hardcoded — if the MeetUp initiative's anchor date changes, the SP needs updating
- **Large table**: 121.4M rows — always use DateID filter. Without it, queries scan ~600K rows per date × 212 dates
- **13 columns, not 14**: DDL has 13 columns (UpdateDate from the orchestrator list is not present in this DDL)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | varchar(8) | YES | Business date for this snapshot in YYYYMMDD format (yesterday relative to SP run). Clustered index column. Stored as varchar despite being a date integer. (Tier 2 — SP_CID_Investment_PIMeetup) |
| 2 | RunDateID | varchar(8) | YES | SP execution date in YYYYMMDD format (today). Indicates when this snapshot was computed. (Tier 2 — SP_CID_Investment_PIMeetup) |
| 3 | CID | varchar(8) | YES | Copier customer ID — the user who allocates money to copy the ParentCID. Stored as varchar(8). CAST to INT for JOINs with DWH tables. (Tier 2 — SP_CID_Investment_PIMeetup, from Dim_Position) |
| 4 | MirrorID | varchar(8) | YES | Copy relationship identifier from Dim_Mirror. Unique per CID-ParentCID copy instance. Stored as varchar(8). (Tier 2 — SP_CID_Investment_PIMeetup, from Dim_Position/Dim_Mirror) |
| 5 | MirrorOpenID | varchar(8) | YES | Date the copy relationship started, in YYYYMMDD format. From Dim_Mirror.OpenDateID. Stored as varchar(8). (Tier 2 — SP_CID_Investment_PIMeetup, from Dim_Mirror) |
| 6 | ParentCID | varchar(8) | YES | Copied person's customer ID (the Popular Investor or Smart Portfolio). From Dim_Mirror.ParentCID. Stored as varchar(8). (Tier 2 — SP_CID_Investment_PIMeetup, from Dim_Mirror) |
| 7 | Calc1 | decimal(38,2) | YES | Mirror allocation amount from Dim_Mirror.Amount. Represents the initial capital allocated to the copy relationship at time of last rebalance. In USD. (Tier 2 — SP_CID_Investment_PIMeetup, from Dim_Mirror) |
| 8 | Calc2 | decimal(38,2) | YES | Sum of all open position equity (Amount + PnLInDollars) in this mirror relationship. From Dim_Position for positions with CloseDateID=0 and OpenDateID >= 20250801. Calc1 + Calc2 = Platform Net Value. (Tier 2 — SP_CID_Investment_PIMeetup, from Dim_Position) |
| 9 | NMI | decimal(38,2) | YES | Net Money Invested — net of all money-in and money-out operations for this mirror. From etoro_History_Mirror operations 1 (in), 2 (out, negated), 3 (adjustment). NMI = MoneyIn − MoneyOut. (Tier 2 — SP_CID_Investment_PIMeetup, from CopyFromLake.etoro_History_Mirror) |
| 10 | MoneyOut | decimal(38,2) | YES | Total money withdrawn from this copy relationship. Sum of operation 2 amounts (negated to positive) + operation 3 negative amounts. (Tier 2 — SP_CID_Investment_PIMeetup, from CopyFromLake.etoro_History_Mirror) |
| 11 | MoneyIn | decimal(38,2) | YES | Total money deposited into this copy relationship. Sum of operation 1 amounts + operation 3 positive amounts. (Tier 2 — SP_CID_Investment_PIMeetup, from CopyFromLake.etoro_History_Mirror) |
| 12 | Platform_NetValue | decimal(38,2) | YES | Total net value of the copy relationship as displayed on the platform. Computed as SUM(Calc1) + SUM(Calc2). In USD. (Tier 2 — SP_CID_Investment_PIMeetup) |
| 13 | Platform_Pnl | decimal(38,2) | YES | Profit/loss on the copy relationship relative to net invested capital. Computed as Platform_NetValue − NMI. Negative = copier has lost money. In USD. (Tier 2 — SP_CID_Investment_PIMeetup) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID, MirrorID | DWH_dbo.Dim_Position | CID, MirrorID | Passthrough (varchar cast) |
| ParentCID, MirrorOpenID | DWH_dbo.Dim_Mirror | ParentCID, OpenDateID | Passthrough (varchar cast) |
| Calc1 | DWH_dbo.Dim_Mirror | Amount | Passthrough |
| Calc2 | DWH_dbo.Dim_Position | Amount, PnLInDollars | SUM for open positions |
| NMI, MoneyIn, MoneyOut | CopyFromLake.etoro_History_Mirror | Amount, MirrorOperationID | CASE-based aggregation |

### 5.2 ETL Pipeline

```
CopyFromLake.etoro_History_Mirror (mirror operations 1=in, 2=out, 3=adjust)
  + DWH_dbo.Dim_Position (CloseDateID=0, OpenDateID>=20250801)
  + DWH_dbo.Dim_Mirror (mirror allocation amount)
    |-- SP_CID_Investment_PIMeetup @date (daily, delete-insert by DateID) --|
    |   NMI/MoneyIn/MoneyOut from History_Mirror                            |
    |   Calc1 = mirror amount, Calc2 = SUM(Amount + PnL) open positions    |
    |   Platform_NetValue = Calc1+Calc2; Platform_Pnl = NetValue - NMI     |
    v
BI_DB_dbo.BI_DB_Investment_PIMeetup (121.4M rows, daily)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID, MirrorID | DWH_dbo.Dim_Position | Open position data |
| MirrorID, ParentCID | DWH_dbo.Dim_Mirror | Copy relationship |
| NMI, MoneyIn, MoneyOut | CopyFromLake.etoro_History_Mirror | Mirror operations |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Total Copy AUM and PnL (Latest Date)

```sql
SELECT SUM(Platform_NetValue) AS total_aum,
       SUM(Platform_Pnl) AS total_pnl,
       COUNT(DISTINCT CAST(CID AS INT)) AS unique_copiers
FROM [BI_DB_dbo].[BI_DB_Investment_PIMeetup]
WHERE DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_Investment_PIMeetup])
```

### 7.2 PnL Distribution for a Specific PI

```sql
SELECT CAST(CID AS INT) AS copier_cid,
       Platform_NetValue, NMI, Platform_Pnl,
       CASE WHEN NMI > 0 THEN Platform_Pnl / NMI * 100 END AS pnl_pct
FROM [BI_DB_dbo].[BI_DB_Investment_PIMeetup]
WHERE ParentCID = '14111777' AND DateID = '20260412'
ORDER BY Platform_Pnl DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Investment_PIMeetup | Type: Table | Production Source: Derived — etoro_History_Mirror + Dim_Position + Dim_Mirror*

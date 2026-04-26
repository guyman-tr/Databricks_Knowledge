# BI_DB_dbo.BI_DB_AvgHoldingTime

> 300-row monthly snapshot table reporting the average holding time (in days) of eToro CFD and copy-trading positions across five instrument/relationship groups. Covers April 2021 through March 2026 (60 monthly snapshots × 5 groups). Populated once per month on the 2nd of each month by SP_AvgHoldingTime, using a trailing 3-month window of positions (open + closed) from qualified, high-equity customers.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror + DWH_dbo.V_Liabilities via SP_AvgHoldingTime |
| **Refresh** | Monthly (runs on day 2 of each month via SB_Daily, Priority 20). DELETE for CloseDateID + INSERT — each run replaces the prior month's snapshot. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CloseDateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **Row Count** | 300 rows (5 groups × 60 months, Apr 2021–Mar 2026) |

---

## 1. Business Meaning

`BI_DB_AvgHoldingTime` answers the business question: *How long, on average, do eToro customers hold their positions?* It provides a monthly average holding time in days, segmented into five groups covering both direct trading and copy-trading behaviors.

The SP is authored by Bar Arian (2022-05-22) and processes a trailing 3-month window of positions (positions opened or closed within the 3 months ending on the last day of the previous month). The population is restricted to qualified customers: verified depositors, valid accounts, equity > $50 (from V_Liabilities), leverage < 3, and no copy/mirror for direct positions.

**Groups and latest values (March 2026)**:
| Group | AvgHoldingTime (days) | Source |
|-------|-----------------------|--------|
| Crypto | 855 | Direct positions, InstrumentTypeID=10 |
| Copy Trading | 613 | Dim_Mirror, MirrorTypeID IN 1,2 |
| Stocks | 628 | Direct positions, InstrumentTypeID=5 |
| ETF,Indices | 488 | Direct positions, InstrumentTypeID IN 4,6 |
| Copy Portfolio | 460 | Dim_Mirror, MirrorTypeID=4 |

The SP ONLY executes its logic when DATEPART(DAY,@date) = 2 — meaning it is a no-op on any other day of the month. SB_Daily calls it daily but it produces output only on the 2nd of each month.

---

## 2. Business Logic

### 2.1 Monthly Execution Gate

**What**: SP runs daily but only writes data on the 2nd of each month.
**Columns Involved**: All (CloseDateID, UpdateDate)
**Rules**:
- `IF DATEPART(DAY,@date)=2` — only the day-2 call produces output; all other days are no-ops
- @EndDate = last day of the PREVIOUS month (EOMONTH of prior month)
- @StartDate = 3 months before @EndDate (3-month lookback window)
- Reason (SP comment): "actually run only on the second day of month - due to data delays from the source"

### 2.2 Equity Filter for Open Positions

**What**: Direct open positions are additionally filtered to customers with equity > $50.
**Columns Involved**: AvgHoldingTime (open position contribution)
**Rules**:
- `#Days_open` requires V_Liabilities.Liabilities + V_Liabilities.ActualNWA > 50 as of @EndDateID
- This filter applies only to OPEN positions; closed positions (#Days_close) are NOT filtered by equity
- Purpose: exclude near-zero-equity accounts from skewing average holding time upward

### 2.3 Direct Position Groups (Stocks, ETF/Indices, Crypto)

**What**: Average holding time for self-directed positions by instrument type.
**Columns Involved**: Groups, AvgHoldingTime
**Rules**:
- Source: Dim_Position JOIN Dim_Instrument JOIN Dim_Customer JOIN V_Liabilities (for open)
- Filters: Leverage < 3, MirrorID = 0, InstrumentTypeID IN (4=ETF, 5=Stocks, 6=Indices, 10=Crypto), IsPartialCloseChild = 0
- UNION of open positions (OpenDateID ≤ @EndDateID AND CloseDateID=0 or after) + closed positions (CloseDateID in 3-month window)
- Holding time = DATEDIFF(minutes, OpenOccurred, CloseOccurred or @EndDate) / 60 / 24 → integer days

### 2.4 Copy Trading Groups (Copy Trading, Copy Portfolio)

**What**: Average holding time for copy/mirror relationships by mirror type.
**Columns Involved**: Groups, AvgHoldingTime
**Rules**:
- Source: Dim_Mirror JOIN Dim_Customer JOIN V_Liabilities (for open mirrors)
- Filters: MirrorTypeID IN (1=Regular, 2=CopyMe, 4=Fund), IsValidCustomer = 1, IsDepositor = 1
- UNION of open mirrors + closed mirrors (same date window logic as direct positions)
- Copy Trading = MirrorTypeID IN (1,2); Copy Portfolio = MirrorTypeID = 4

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX(CloseDateID ASC). At 300 rows, this is a micro table. Any query pattern is trivially fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| "Latest month's holding time per group?" | `WHERE CloseDateID = (SELECT MAX(CloseDateID) FROM BI_DB_AvgHoldingTime)` |
| "Crypto holding time trend?" | `WHERE Groups = 'Crypto' ORDER BY CloseDateID` |
| "All groups for a specific month?" | `WHERE CloseDateID = 20260331` |
| "Year-over-year comparison?" | Use CloseDate or LEFT(CAST(CloseDateID AS VARCHAR), 4) for year grouping |

### 3.3 Common JOINs

No common downstream JOINs — this is a standalone KPI reporting table. BI tools consume it directly.

### 3.4 Gotchas

- **SP is a day-2-only process** — the table is updated only on the 2nd of each month. Data for the current month appears on day 2 of the following month. There is no "today's data" in this table.
- **AvgHoldingTime is integer days** — the SP computes `AVG(DATEDIFF(minutes,...) / 60 / 24)` which truncates decimals. A value of 460 means ~460 days average (not hours or minutes).
- **3-month trailing window** — AvgHoldingTime is NOT a lifetime average. It reflects positions open or closed in the 3 months prior to @EndDate. Positions held longer than 3 months but still open ARE included (counted from OpenOccurred to @EndDate).
- **Open positions use equity filter, closed positions do not** — this asymmetry means the average can shift based on how many qualifying open-position customers are captured vs. closed.
- **Groups comma in name** — "ETF,Indices" contains a literal comma. If consuming this column in a comma-separated context, be aware.
- **CloseDateID vs CloseDate** — both columns exist. CloseDateID is int YYYYMMDD; CloseDate is datetime. They represent the same date; CloseDateID = CAST(CONVERT(CHAR(8), CloseDate, 112) AS INT).
- **CloseDateID = last day of previous month** — e.g., a run on 2026-04-02 produces CloseDateID = 20260331.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Description copied verbatim from upstream wiki |
| **Tier 2** | Derived from SP code analysis or DWH ETL logic |
| **Tier 3** | Inferred from data patterns; no SP confirmation |
| **Tier 4** | Best available knowledge; limited evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CloseDateID | int | NO | Reporting period end date in YYYYMMDD integer format (e.g., 20260331 = March 31, 2026). Always the last day of the previous calendar month. One CloseDateID has 5 rows (one per Groups value). (Tier 2 — SP_AvgHoldingTime) |
| 2 | Groups | varchar(50) | YES | Instrument or relationship group for the average holding time. Five possible values: Stocks (InstrumentTypeID=5), ETF,Indices (InstrumentTypeID IN 4,6), Crypto (InstrumentTypeID=10), Copy Trading (MirrorTypeID IN 1,2), Copy Portfolio (MirrorTypeID=4). (Tier 2 — SP_AvgHoldingTime) |
| 3 | AvgHoldingTime | int | YES | Average holding time in days for the group in the 3-month reporting window. Computed as AVG(DATEDIFF(minutes, OpenOccurred, CloseOccurred) / 60 / 24) — open positions use @EndDate as the proxy close. Truncated to integer days. March 2026 values: Crypto=855, Stocks=628, Copy Trading=613, ETF,Indices=488, Copy Portfolio=460. (Tier 2 — SP_AvgHoldingTime) |
| 4 | UpdateDate | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. All 5 rows per CloseDateID share the same UpdateDate (batch insert). (Tier 2 — SP_AvgHoldingTime) |
| 5 | CloseDate | datetime | NULL | Last day of the previous calendar month as datetime (e.g., 2026-03-31 00:00:00). Redundant with CloseDateID — both represent the same reporting period end date. (Tier 2 — SP_AvgHoldingTime) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CloseDateID | Computed | @EndDate | CAST(CONVERT(CHAR(8), @EndDate, 112) AS INT) |
| Groups | DWH_dbo.Dim_Instrument / Dim_Mirror | InstrumentTypeID / MirrorTypeID | CASE mapping to 5 group labels |
| AvgHoldingTime | DWH_dbo.Dim_Position / Dim_Mirror | OpenOccurred, CloseOccurred | AVG(DATEDIFF(mi,…)/60/24) → int days |
| UpdateDate | ETL system | GETDATE() | Insert timestamp |
| CloseDate | Computed | @EndDate | Last day of previous month as datetime |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (OpenOccurred, CloseOccurred, OpenDateID, CloseDateID,
                       InstrumentID, Leverage<3, MirrorID=0, IsPartialCloseChild=0)
DWH_dbo.Dim_Instrument (InstrumentType, InstrumentTypeID IN 4,5,6,10)
DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1)
DWH_dbo.V_Liabilities (Liabilities + ActualNWA > $50 equity filter for open positions)
DWH_dbo.Dim_Mirror (MirrorTypeID IN 1,2,4, open+closed in window)
  |
  |-- SP_AvgHoldingTime(@date) — executes ONLY on day 2 of each month ---|
  |   @EndDate = EOMONTH(previous month)
  |   @StartDate = 3 months before @EndDate
  |   Track 1 (direct):
  |     #Days_open (equity-filtered, 3-month window open positions)
  |     #Days_close (3-month window closed positions)
  |     #Days = UNION ALL open + close
  |     #Groups: AVG(minutes→days) per InstrumentType → Stocks/ETF,Indices/Crypto
  |   Track 2 (copy):
  |     #CopyOpen (equity-filtered, open mirrors)
  |     #CopyClose (closed mirrors in 3-month window)
  |     #copy = UNION ALL open + close
  |     #Groups_copy: AVG(minutes→days) per MirrorType → Copy Trading/Copy Portfolio
  |   #Groups_final = UNION ALL groups + copy groups (5 rows)
  |   DELETE WHERE CloseDateID = @EndDateID
  |   INSERT 5 rows
  v
BI_DB_dbo.BI_DB_AvgHoldingTime (300 rows, monthly grain, Apr 2021–Mar 2026)
  |
  |-- UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| (source) | DWH_dbo.Dim_Position | Position open/close timestamps and instrument classification |
| (source) | DWH_dbo.Dim_Instrument | Instrument type for group classification |
| (source) | DWH_dbo.Dim_Customer | Validity and depositor filters |
| (source) | DWH_dbo.V_Liabilities | Equity > $50 filter for open positions |
| (source) | DWH_dbo.Dim_Mirror | Copy/mirror relationship open/close timestamps |

### 6.2 Referenced By

No SPs or views in the SSDT repo reference this table. It is a standalone KPI reporting table consumed directly by BI dashboards.

---

## 7. Sample Queries

### Latest holding time snapshot for all groups

```sql
SELECT Groups, AvgHoldingTime, CloseDate
FROM [BI_DB_dbo].[BI_DB_AvgHoldingTime]
WHERE CloseDateID = (SELECT MAX(CloseDateID) FROM [BI_DB_dbo].[BI_DB_AvgHoldingTime])
ORDER BY AvgHoldingTime DESC;
```

### Crypto holding time trend over time

```sql
SELECT CloseDateID, AvgHoldingTime
FROM [BI_DB_dbo].[BI_DB_AvgHoldingTime]
WHERE Groups = 'Crypto'
ORDER BY CloseDateID;
```

### All groups for the past 12 months

```sql
SELECT CloseDateID, Groups, AvgHoldingTime
FROM [BI_DB_dbo].[BI_DB_AvgHoldingTime]
WHERE CloseDateID >= CAST(CONVERT(CHAR(8), DATEADD(MONTH, -12, GETDATE()), 112) AS INT)
ORDER BY CloseDateID, Groups;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources searched (Phase 10 skipped). The SP header comment (Bar Arian, 2022-05-22) and the day-2 execution rationale ("due to data delays from the source") are the primary design context captured in code.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 12/14 (P7 Views, P10 Jira skipped)*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4 | Elements: 5/5 | Logic: 4 subsections*
*Object: BI_DB_dbo.BI_DB_AvgHoldingTime | Type: Table | Production Source: DWH_dbo.Dim_Position + Dim_Mirror via SP_AvgHoldingTime*

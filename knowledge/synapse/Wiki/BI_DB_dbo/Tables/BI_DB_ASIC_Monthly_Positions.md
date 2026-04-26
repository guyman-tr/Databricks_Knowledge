# BI_DB_dbo.BI_DB_ASIC_Monthly_Positions

> 400-row monthly aggregation table tracking ASIC-regulated position counts and total notional volume for January 2018 through April 2026. Each row represents one ASIC client group (open or closed positions, Australian vs. non-Australian residents) per month. Populated daily by SP_ASIC_Monthly_Positions with a DELETE+INSERT per YearMonth, making each month's data overwritable as late positions are processed.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + DWH_dbo.Fact_SnapshotCustomer via SP_ASIC_Monthly_Positions |
| **Refresh** | Daily (SB_Daily, Priority 20). DELETE for YearMonth + INSERT — one month's data is reprocessed per daily run. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (YearMonth ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **Row Count** | 400 rows (4 rows per month × 100 months, Jan 2018–Apr 2026) |

---

## 1. Business Meaning

`BI_DB_ASIC_Monthly_Positions` is a compact ASIC regulatory reporting table that summarizes the number and total notional volume of CFD positions opened and closed by ASIC-regulated customers each month, split by whether the customer resided in Australia (CountryID=12) or outside Australia.

The table is used to support ASIC regulatory reporting obligations under the Australian Securities and Investments Commission framework. Regulation 4 = ASIC, Regulation 10 = ASIC & GAML. The SP applies both at position-open (RegulationIDOnOpen) and at position-close (snapshot regulation at close date) to handle customers who changed regulation between opening and closing a position.

Four rows per month represent:
- **open_pos_AU** — positions opened by ASIC-regulated Australian residents
- **open_pos_NON_AU** — positions opened by ASIC-regulated non-Australian residents
- **close_pos_AU** — positions closed by ASIC-regulated Australian residents (at close date regulation)
- **close_pos_NON_AU** — positions closed by ASIC-regulated non-Australian residents (at close date regulation)

As of April 2026 (YearMonth=202604): AU open/close = 75,205 positions / ~607M notional; NON_AU open/close = 2,759 positions / ~15.9M notional. March 2026 saw ~632K AU closes — significantly higher, reflecting more complete month data.

The SP takes a @DateFirst parameter (first day of the target month) and processes positions whose OpenDateID falls within that calendar month. The history stretches back to January 2018 (earliest data in OpsDB).

---

## 2. Business Logic

### 2.1 Position Attribution by Regulation

**What**: Assigns positions to ASIC if either RegulationIDOnOpen (at trade entry) or RegulationOnClose (historical snapshot at close date) = 4 or 10.
**Columns Involved**: ASIC_Client_Group, NO.Positions, TotalVolume
**Rules**:
- Dim_Position JOIN Fact_SnapshotCustomer where snapshot DateRange covers the CloseDateID
- RegulationIDOnOpen IN (4=ASIC, 10=ASIC&GAML) OR Fact_SnapshotCustomer.RegulationID IN (4,10) — dual-regulation filter ensures a customer who changed regulation is captured
- Australia detection: Fact_SnapshotCustomer.CountryID = 12

### 2.2 Open vs. Close Position Split

**What**: The final UNION creates separate rows for opened positions and closed positions in the same month, each further split AU/NON_AU.
**Columns Involved**: ASIC_Client_Group, NO.Positions, TotalVolume
**Rules**:
- Open rows: filter WHERE RegulationIDOnOpen IN (4,10), count non-partial-close children, volume = InitialAmountCents/100 × Leverage
- Close rows: filter WHERE RegulationOnClose IN (4,10), count all positions (no partial-close exclusion), volume = Amount × Leverage
- Volume calculation differs: open uses InitialAmount (original investment), close uses Amount (current/close amount at date of calculation)
- IsPartialCloseChild exclusion applies only to open side: `COUNT(CASE WHEN ISNULL(IsPartialCloseChild,0) <> 1 THEN 1 ELSE 0 END)` — partial close children are excluded from open count

### 2.3 Monthly Incremental Pattern

**What**: Each daily SP run processes one month's data (DELETE for that YearMonth + INSERT).
**Columns Involved**: YearMonth, UpdateDate
**Rules**:
- @DateFirst parameter drives which month is reprocessed
- EOMONTH(@DateFirst) gives the last day of the month; all positions opened within @StartDateID–@EndDateID are included
- Running monthly (current month) produces partial data; previous months are stable once fully processed
- Multiple runs for the same month overwrite previous values (idempotent per YearMonth)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX(YearMonth ASC). At 400 rows this table is trivially small — distribution strategy is irrelevant for query performance. ROUND_ROBIN is appropriate for small reporting tables that need full-scan aggregation.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| "ASIC positions for a specific month?" | `WHERE YearMonth = 202603` |
| "Monthly trend for AU open positions?" | `WHERE ASIC_Client_Group = 'open_pos_AU' ORDER BY YearMonth` |
| "Total notional volume per year?" | `GROUP BY LEFT(CAST(YearMonth AS VARCHAR), 4)` |
| "Compare open vs close for same month?" | JOIN on YearMonth, filter group LIKE 'open%' vs 'close%' |
| "Latest month available?" | `SELECT MAX(YearMonth)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| (none — this table is a reporting aggregate, not a dimension) | — | — |

### 3.4 Gotchas

- **YearMonth is int YYYYMM format** — to filter by year: `WHERE YearMonth BETWEEN 202600 AND 202699` or `LEFT(CAST(YearMonth AS VARCHAR), 4) = '2026'`.
- **Volume formula differs: open ≠ close** — open uses `InitialAmountCents/100 × Leverage`; close uses `Amount × Leverage`. These are not directly comparable. Do not sum open + close TotalVolume to get total volume — it would double-count positions that both opened and closed in the same month.
- **Partial close children excluded from open count only** — IsPartialCloseChild exclusion is applied to open positions count but NOT to close positions count, creating asymmetry.
- **Month partial completeness** — the current month's data (YearMonth = current YYYYMM) will show only the positions opened through the most recent @DateFirst run. Wait until month-end for complete data.
- **Dual regulation attribution** — a position can appear in both open_pos_* (RegulationIDOnOpen=ASIC) AND close_pos_* (RegulationOnClose=ASIC) rows if the customer was ASIC at both open and close. This is intentional for regulatory reporting (open/close positions are separate ASIC reporting categories).
- **Column name has a dot**: `[NO.Positions]` — requires square bracket quoting in SQL.

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
| 1 | YearMonth | int | YES | Month of the position open date in YYYYMM integer format (e.g., 202604 = April 2026). Derived as LEFT(Dim_Position.OpenDateID, 6). One YearMonth has 4 rows (one per ASIC_Client_Group). Range: 201801–202604. (Tier 2 — SP_ASIC_Monthly_Positions) |
| 2 | ASIC_Client_Group | varchar(500) | YES | ASIC client segment label. Four possible values: open_pos_AU (positions opened by Australian ASIC-regulated customers), open_pos_NON_AU (positions opened by non-Australian ASIC-regulated customers), close_pos_AU (positions closed by Australian ASIC-regulated customers), close_pos_NON_AU (positions closed by non-Australian ASIC-regulated customers). Australia = CountryID=12 in Fact_SnapshotCustomer. (Tier 2 — SP_ASIC_Monthly_Positions) |
| 3 | NO.Positions | int | YES | Count of positions in this ASIC client group for the month. For open groups: excludes partial close children (IsPartialCloseChild≠1). For close groups: includes all positions. Column name contains a dot — requires square bracket quoting: [NO.Positions]. (Tier 2 — SP_ASIC_Monthly_Positions) |
| 4 | TotalVolume | bigint | YES | Total notional volume for the group. For open positions: SUM(InitialAmountCents/100 × Leverage) — initial investment × leverage. For close positions: SUM(Amount × Leverage) — amount at close × leverage. Units: USD (or base currency), not cents. (Tier 2 — SP_ASIC_Monthly_Positions) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. All rows for a given YearMonth share the same UpdateDate from the most recent SP run for that month. (Tier 2 — SP_ASIC_Monthly_Positions) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| YearMonth | DWH_dbo.Dim_Position | OpenDateID | LEFT(OpenDateID, 6) |
| ASIC_Client_Group | DWH_dbo.Dim_Position + Fact_SnapshotCustomer | RegulationIDOnOpen, RegulationID, CountryID | CASE expression: open/close × AU/NON_AU |
| NO.Positions | DWH_dbo.Dim_Position | PositionID, IsPartialCloseChild | COUNT (with partial-close exclusion for open) |
| TotalVolume | DWH_dbo.Dim_Position | InitialAmountCents, Amount, Leverage | SUM(InitialAmount × Leverage) or SUM(Amount × Leverage) |
| UpdateDate | ETL system | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (CID, PositionID, OpenDateID, CloseDateID, RegulationIDOnOpen,
                       InitialAmountCents, Amount, Leverage, IsPartialCloseChild)
DWH_dbo.Fact_SnapshotCustomer (RealCID, RegulationID [at close date], CountryID, DateRangeID)
DWH_dbo.Dim_Range (DateRangeID, FromDateID, ToDateID)
  |
  |-- SP_ASIC_Monthly_Positions(@DateFirst) ---|
  |   @Date = EOMONTH(@DateFirst)
  |   @StartDateID / @EndDateID = first-last day of month
  |   @YearMonth = LEFT(EOMONTH, 6)
  |   #allpos: Positions opened in month where ASIC regulated (open or close)
  |            + snapshot customer at CloseDateID for CountryID=12 (AU) check
  |   #final:  UNION open_pos_AU, open_pos_NON_AU, close_pos_AU, close_pos_NON_AU
  |   DELETE BI_DB_ASIC_Monthly_Positions WHERE YearMonth = @YearMonth
  |   INSERT 4 rows for the month
  v
BI_DB_dbo.BI_DB_ASIC_Monthly_Positions (400 rows, monthly grain, Jan 2018–Apr 2026)
  |
  |-- UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| (source) | DWH_dbo.Dim_Position | Position-level data for all ASIC-regulated trades |
| (source) | DWH_dbo.Fact_SnapshotCustomer | Historical customer country + regulation at trade close date |
| (source) | DWH_dbo.Dim_Range | Date range dimension for snapshot JOIN |

### 6.2 Referenced By

No SPs or views in the SSDT repo reference this table (leaf reporting table — exported to downstream BI tools directly).

---

## 7. Sample Queries

### Monthly ASIC notional volume trend (AU open positions)

```sql
SELECT YearMonth, [NO.Positions], TotalVolume
FROM [BI_DB_dbo].[BI_DB_ASIC_Monthly_Positions]
WHERE ASIC_Client_Group = 'open_pos_AU'
ORDER BY YearMonth;
```

### Total positions and volume by group for latest full month

```sql
SELECT ASIC_Client_Group, [NO.Positions], TotalVolume
FROM [BI_DB_dbo].[BI_DB_ASIC_Monthly_Positions]
WHERE YearMonth = (SELECT MAX(YearMonth) - 1 FROM [BI_DB_dbo].[BI_DB_ASIC_Monthly_Positions])
ORDER BY ASIC_Client_Group;
```

### Year-over-year comparison for AU open positions

```sql
SELECT LEFT(CAST(YearMonth AS VARCHAR), 4) AS Year,
       SUM([NO.Positions]) AS total_positions,
       SUM(TotalVolume) AS total_volume
FROM [BI_DB_dbo].[BI_DB_ASIC_Monthly_Positions]
WHERE ASIC_Client_Group = 'open_pos_AU'
GROUP BY LEFT(CAST(YearMonth AS VARCHAR), 4)
ORDER BY Year;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources searched (Phase 10 skipped). The table purpose is clearly defined by SP code: ASIC regulatory reporting for position counts and notional volumes, split by Australian vs. non-Australian ASIC-regulated customers.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 13/14 (P10 Jira skipped)*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4 | Elements: 5/5 | Logic: 3 subsections*
*Object: BI_DB_dbo.BI_DB_ASIC_Monthly_Positions | Type: Table | Production Source: DWH_dbo.Dim_Position + Fact_SnapshotCustomer via SP_ASIC_Monthly_Positions*

# BI_DB_dbo.BI_DB_PositionHoldingTime

> 368M-row accumulating daily closed-position holding time log (2022-01-01 to 2026-04-12), tracking calendar-day holding duration in minutes for every position closed on each day — sourced from Dim_Position (regular trades, MirrorID=0) and Dim_Mirror (copy trade/portfolio) via daily DELETE+INSERT upsert per close date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position (MirrorID=0) + DWH_dbo.Dim_Instrument + DWH_dbo.Dim_Mirror |
| **Refresh** | Daily — SP_PositionHoldingTime @Date; DELETE WHERE CloseDate=@Date then INSERT (accumulating since 2022-01-01) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

Daily accumulating log of every position and copy-trade relationship closed on the eToro platform, enriched with a calendar-day holding duration metric. Each row represents one closed position (or copy relationship), recording who held it (CID), what was traded (InstrumentType/InstrumentID), when it was opened and closed, the leverage and investment amount, and how many calendar-day-minutes it was held (HoldingTime).

The table accumulates since 2022-01-01 and is refreshed daily by deleting and re-inserting the target date's data (DELETE+INSERT upsert by CloseDate). It combines two distinct data sources in a UNION ALL:
1. **Regular positions** (Dim_Position WHERE MirrorID=0): Direct, non-copy trades across all instrument types
2. **Copy positions** (Dim_Mirror): Copy Trade and Copy Portfolio relationships

As of 2026-04-12: 368,072,174 rows. Stocks dominate (36.8%), followed by Indices (18.8%), Commodities (17.1%), and Crypto Currencies (16.2%). Leverage=1 (no leverage) is most common at 44.8%. Leverage=0 marks all copy positions.

**CRITICAL: `HoldingTime` is DATEDIFF(mi, CAST(OpenOccurred AS DATE), CAST(CloseOccurred AS DATE)) — it measures the difference between calendar DATES (not datetimes) in minutes. A position opened at 23:50 and closed at 00:05 the next day = 1,440 minutes, not 15. HoldingTime is always a multiple of 1,440 (or 0 for same-day closes).**

**CRITICAL: For Copy Trade and Copy Portfolio rows, `InstrumentID` contains the `ParentCID` (the person being copied), NOT an instrument ID. Do NOT join copy rows to Dim_Instrument on InstrumentID.**

---

## 2. Business Logic

### 2.1 Daily Upsert by Close Date

**What**: The SP re-processes one calendar day at a time, allowing restatement of any given day's closed positions.
**Columns Involved**: CloseDate, all columns
**Rules**:
- `DELETE FROM BI_DB_PositionHoldingTime WHERE CloseDate = @Date` — removes any prior data for that date
- `INSERT ... SELECT` from Dim_Position + Dim_Instrument UNION ALL Dim_Mirror — loads fresh data for that date
- Historical dates (prior to @Date) are not touched; the table accumulates since 2022-01-01
- Only closed positions for the given date are loaded: `WHERE CloseDateID = @DateID` in both branches

### 2.2 Regular vs. Copy Position Branches

**What**: Two fundamentally different data sources are combined via UNION ALL into a single table.
**Columns Involved**: InstrumentType, InstrumentID, PositionID, Leverage
**Rules**:
- **Regular branch** (Dim_Position WHERE MirrorID=0): Only non-mirror positions. PositionID=Dim_Position.PositionID, InstrumentType=Dim_Instrument string (6 values: Stocks/Indices/Commodities/Crypto Currencies/Currencies/ETF), InstrumentID=actual instrument FK, Leverage=actual multiplier (1–400)
- **Copy branch** (Dim_Mirror): All copy relationships (CloseDateID=@DateID). PositionID=Dim_Mirror.MirrorID, InstrumentType=CASE MirrorTypeID: 4→'Copy Portfolio', else→'Copy Trade', InstrumentID=Dim_Mirror.ParentCID (the copied person's CID), Leverage=0 (hardcoded)
- There is no overlap: copy positions are excluded from the Dim_Position branch via `AND dp.MirrorID=0`

### 2.3 HoldingTime Calendar-Day Rounding

**What**: HoldingTime measures holding duration in minutes but rounded to whole calendar days.
**Columns Involved**: HoldingTime, OpenOccurred, CloseOccurred
**Rules**:
- Formula: `DATEDIFF(mi, CAST(OpenOccurred AS DATE), CAST(CloseOccurred AS DATE))`
- CAST to DATE truncates the time component → DATEDIFF operates on calendar dates
- Result is always a multiple of 1,440 (one day = 1,440 minutes) or 0 (same-day close)
- 0 = opened and closed on the same calendar day (regardless of actual elapsed time)
- 1,440 = closed on the day after open (regardless of whether it was 1 hour or 23.5 hours later)
- Maximum observed: 7,133,760 minutes = 4,954 calendar days (~13.6 years, from positions opened before 2022)
- Average: ~118,445 minutes (~82 calendar days)
- Do NOT use HoldingTime for sub-day or precise duration analytics — use DATEDIFF(mi, OpenOccurred, CloseOccurred) from source Dim_Position directly

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP on a 368M-row table with no indexes or partition scheme. Full scans are unavoidable and will be slow without pre-filtering. Always add `WHERE CloseDate BETWEEN x AND y` to limit scan volume. `InstrumentType` filtering also helps after CloseDate pre-filtering.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Average holding time by instrument type | `SELECT InstrumentType, AVG(CAST(HoldingTime AS FLOAT))/1440.0 AS AvgDays FROM ... WHERE CloseDate BETWEEN ... GROUP BY InstrumentType` |
| Holding time distribution for a period | `WHERE CloseDate BETWEEN '2026-01-01' AND '2026-03-31' GROUP BY HoldingTime/1440 ORDER BY ...` |
| Copy trade holding vs. direct holding | `WHERE InstrumentType IN ('Copy Trade', 'Copy Portfolio')` vs `WHERE InstrumentType NOT IN ('Copy Trade', 'Copy Portfolio')` |
| High-leverage positions holding time | `WHERE Leverage >= 50 AND CloseDate BETWEEN ...` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Instrument name/details — **regular positions only; exclude Copy Trade/Portfolio rows** |
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile |
| DWH_dbo.Dim_Position | PositionID = PositionID AND CloseDate match | Full position detail — **regular positions only** |
| DWH_dbo.Dim_Mirror | PositionID = MirrorID | Copy relationship detail — **copy rows only** |

### 3.4 Gotchas

- **HoldingTime is calendar-day granularity, NOT clock time**: It is always a multiple of 1,440 (or 0). Do not use for intra-day analysis. For exact duration, compute from OpenOccurred and CloseOccurred directly.
- **Copy rows: InstrumentID = ParentCID**: For InstrumentType IN ('Copy Trade', 'Copy Portfolio'), InstrumentID holds the CID of the person being copied. A JOIN to Dim_Instrument on this value will return wrong data or no match. Always filter `InstrumentType NOT IN ('Copy Trade', 'Copy Portfolio')` before joining to Dim_Instrument.
- **Copy rows: PositionID = MirrorID**: For copy rows, PositionID holds Dim_Mirror.MirrorID. JOINs to Dim_Position on PositionID will fail for copy rows.
- **Leverage=0 marks all copy positions**: No analytical meaning for leverage filtering — copy positions always have Leverage=0 by SP design.
- **MirrorID=0 filter in Dim_Position**: Only non-copy Dim_Position rows are loaded. Copy positions in Dim_Position (where MirrorID>0) are excluded; they are captured separately from Dim_Mirror.
- **No partition or clustered index**: All 368M rows are HEAP + ROUND_ROBIN. Filter by CloseDate for every query.
- **Daily DELETE+INSERT**: A given CloseDate can be rerun by re-executing the SP — historical dates can be re-processed, so data before the last UpdateDate may have been refreshed multiple times.
- **UpdateDate per day's batch**: UpdateDate reflects GETDATE() at SP execution time. Range: 2022-03-30 to 2026-04-13.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production or DWH wiki |
| Tier 2 | Description derived from SP code analysis |
| Tier 3 | Description inferred from context and data patterns |
| Tier 4 | Description is best-available estimate; low confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CloseDate | date | YES | Calendar date of position close. SP derives as `CAST(CloseOccurred AS DATE)`. Matches the @Date SP parameter. Range: 2022-01-01 to 2026-04-12. DELETE+INSERT upsert key — all rows for a CloseDate are replaced when SP runs for that date. (Tier 2 — SP_PositionHoldingTime) |
| 2 | CID | int | YES | Customer ID. References Customer.Customer. For regular positions: the position owner; for copy positions: the copier (the customer who allocated funds to follow a leader). (Tier 1 — Dim_Position wiki, Trade.PositionTbl) |
| 3 | PositionID | bigint | NO | Position identifier. For regular positions (InstrumentType NOT IN 'Copy Trade','Copy Portfolio'): Dim_Position.PositionID — primary key, allocated by Internal.GetPositionID_Bigint. For copy positions: Dim_Mirror.MirrorID — the copy relationship identifier, NOT a trade position. Do not join copy rows to Dim_Position on this column. (Tier 2 — SP_PositionHoldingTime) |
| 4 | InstrumentType | varchar(50) | NO | Asset class or copy-trade category. For regular positions: Dim_Instrument.InstrumentType text label (8 InstrumentTypeID-driven values: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies). For copy positions: 'Copy Trade' (MirrorTypeID≠4) or 'Copy Portfolio' (MirrorTypeID=4). Distribution: Stocks 36.8%, Indices 18.8%, Commodities 17.1%, Crypto Currencies 16.2%, Currencies 6.1%, ETF 4.0%, Copy Trade 0.8%, Copy Portfolio 0.2%. (Tier 2 — SP_PositionHoldingTime + Dim_Instrument wiki) |
| 5 | InstrumentID | int | NO | Instrument or person identifier. For regular positions: FK to Dim_Instrument (the financial instrument traded). For copy positions (InstrumentType IN 'Copy Trade','Copy Portfolio'): Dim_Mirror.ParentCID — the CID of the person being copied, NOT an InstrumentID. Never join copy rows to Dim_Instrument using this column. (Tier 2 — SP_PositionHoldingTime) |
| 6 | OpenDateID | int | NO | YYYYMMDD integer of the position open date. ETL-computed from OpenOccurred. Used for date-range filtering; use CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE) to convert to date type. (Tier 2 — Dim_Position wiki, SP_Dim_Position_DL_To_Synapse) |
| 7 | OpenOccurred | datetime | NO | When position was opened (mapped from Occurred in production for Dim_Position; from Trade.Mirror.Occurred for Dim_Mirror). Includes milliseconds. (Tier 1 — Dim_Position wiki, Trade.PositionTbl) |
| 8 | CloseDateID | int | YES | YYYYMMDD integer of the position close date. For regular positions: from Dim_Position.CloseDateID (matches @DateID). For copy positions: from Dim_Mirror.CloseDateID. Use CAST(CAST(CloseDateID AS VARCHAR(8)) AS DATE) to convert. (Tier 2 — Dim_Position wiki, SP_Dim_Position_DL_To_Synapse) |
| 9 | CloseOccurred | datetime | NO | When close was persisted. For regular positions: Dim_Position.CloseOccurred (actual close event timestamp, includes milliseconds). For copy positions: Dim_Mirror.CloseOccurred. (Tier 1 — Dim_Position wiki, Trade.PositionTbl) |
| 10 | Leverage | int | NO | Leverage multiplier. For regular positions: from Dim_Position.Leverage (1, 5, 10, 20, 30, 50, 100, 200, 400). For copy positions: hardcoded 0 (copy relationships have no instrument leverage). Determines margin and settlement type. Distribution: 1x=44.8%, 20x=23.5%, 10x=10.4%, 5x=10.3%, 30x=4.5%, 2x=3.3%, others <2%. (Tier 1 — Dim_Position wiki, Trade.PositionTbl) |
| 11 | Amount | money | NO | Position size in currency. Must be >= 0. Stored in dollars for regular positions (Dim_Position.Amount). For copy positions: Dim_Mirror.Amount — the allocation amount credited to the copy relationship. (Tier 1 — Dim_Position wiki, Trade.PositionTbl) |
| 12 | HoldingTime | int | YES | Calendar-day holding duration in minutes. Formula: `DATEDIFF(mi, CAST(OpenOccurred AS DATE), CAST(CloseOccurred AS DATE))`. Always a multiple of 1,440 (one day) or 0 (same calendar day). NOT clock time. Range: 0–7,133,760 min (0–4,954 calendar days; avg ~118,445 min ≈ 82 days). Use only for day-granularity holding analysis. (Tier 2 — SP_PositionHoldingTime) |
| 13 | UpdateDate | datetime | NO | GETDATE() at time of ETL run. One timestamp per daily SP execution. Range: 2022-03-30 to 2026-04-13 (daily). (Tier 2 — SP_PositionHoldingTime) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CloseDate | Dim_Position / Dim_Mirror | CloseOccurred | CAST(… AS DATE) |
| CID | Dim_Position / Dim_Mirror | CID | Direct |
| PositionID | Dim_Position (regular) / Dim_Mirror (copy) | PositionID / MirrorID | Dual-source: position ID for regular, mirror ID for copy |
| InstrumentType | Dim_Instrument (regular) / SP CASE (copy) | InstrumentType / MirrorTypeID | Regular: string passthrough; Copy: CASE expression |
| InstrumentID | Dim_Instrument (regular) / Dim_Mirror (copy) | InstrumentID / ParentCID | Regular: instrument FK; Copy: ParentCID (person being copied) |
| OpenDateID | Dim_Position / Dim_Mirror | OpenDateID | Direct passthrough |
| OpenOccurred | Dim_Position / Dim_Mirror | OpenOccurred | Direct passthrough |
| CloseDateID | Dim_Position / Dim_Mirror | CloseDateID | Direct passthrough |
| CloseOccurred | Dim_Position / Dim_Mirror | CloseOccurred | Direct passthrough |
| Leverage | Dim_Position (regular) / SP literal (copy) | Leverage / 0 | Regular: direct; Copy: hardcoded 0 |
| Amount | Dim_Position / Dim_Mirror | Amount | Direct passthrough |
| HoldingTime | Dim_Position / Dim_Mirror | OpenOccurred, CloseOccurred | DATEDIFF(mi, CAST(Open AS DATE), CAST(Close AS DATE)) |
| UpdateDate | SP-computed | GETDATE() | ETL run timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (MirrorID=0, CloseDateID=@DateID — non-copy closed positions)
DWH_dbo.Dim_Instrument (JOIN ON InstrumentID — instrument type and ID)
  UNION ALL
DWH_dbo.Dim_Mirror (CloseDateID=@DateID — copy trade/portfolio closed)
  |-- SP_PositionHoldingTime @Date (daily run, one date parameter) ---|
  |   DELETE WHERE CloseDate = @Date                                   |
  |   INSERT UNION ALL (regular positions + copy relationships)        |
  v
BI_DB_dbo.BI_DB_PositionHoldingTime (368M rows, accumulates since 2022-01-01)
  |-- UC: Not Migrated ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer profile |
| PositionID (regular) | DWH_dbo.Dim_Position | Source position record |
| PositionID (copy) | DWH_dbo.Dim_Mirror | Source mirror relationship record |
| InstrumentID (regular) | DWH_dbo.Dim_Instrument | Instrument details — regular rows only |
| InstrumentID (copy) | DWH_dbo.Dim_Customer (ParentCID) | Person being copied — copy rows only |

### 6.2 Referenced By

No downstream consumers found in SSDT repo. This is an Operations analytics leaf table.

---

## 7. Sample Queries

### Average Holding Time by Instrument Type (in calendar days)

```sql
SELECT
    InstrumentType,
    COUNT(*) AS Positions,
    AVG(CAST(HoldingTime AS FLOAT)) / 1440.0 AS AvgCalendarDays,
    MIN(HoldingTime) / 1440 AS MinDays,
    MAX(HoldingTime) / 1440 AS MaxDays
FROM [BI_DB_dbo].[BI_DB_PositionHoldingTime]
WHERE CloseDate BETWEEN '2026-01-01' AND '2026-03-31'
    AND InstrumentType NOT IN ('Copy Trade', 'Copy Portfolio')  -- regular instruments only
GROUP BY InstrumentType
ORDER BY AvgCalendarDays DESC;
```

### Same-Day vs. Multi-Day Close Distribution

```sql
SELECT
    CASE WHEN HoldingTime = 0 THEN 'Same Day' ELSE 'Multi Day' END AS HoldingCategory,
    InstrumentType,
    COUNT(*) AS Positions,
    AVG(CAST(Amount AS FLOAT)) AS AvgAmountUSD
FROM [BI_DB_dbo].[BI_DB_PositionHoldingTime]
WHERE CloseDate BETWEEN '2025-10-01' AND '2026-03-31'
GROUP BY CASE WHEN HoldingTime = 0 THEN 'Same Day' ELSE 'Multi Day' END, InstrumentType
ORDER BY InstrumentType, HoldingCategory;
```

### High-Leverage Short-Term Positions

```sql
SELECT TOP 20
    InstrumentType,
    PositionID,
    CID,
    Leverage,
    Amount,
    HoldingTime / 1440 AS HoldingDays,
    OpenOccurred,
    CloseOccurred
FROM [BI_DB_dbo].[BI_DB_PositionHoldingTime]
WHERE Leverage >= 100
    AND HoldingTime = 0  -- same-day close
    AND CloseDate >= '2026-01-01'
ORDER BY Amount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Position holding time analysis context may exist under Analytics or Trading spaces in Confluence (not queried).

---

*Generated: 2026-04-22 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 5 T1, 8 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 9/10*
*Object: BI_DB_dbo.BI_DB_PositionHoldingTime | Type: Table | Production Source: DWH_dbo.Dim_Position (MirrorID=0) + DWH_dbo.Dim_Mirror*

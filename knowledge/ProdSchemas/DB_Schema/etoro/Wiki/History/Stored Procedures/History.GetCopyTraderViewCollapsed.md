# History.GetCopyTraderViewCollapsed

> Returns a customer's closed positions aggregated by CopyTrader leader - one summary row per leader plus a synthetic "Manual" row for non-mirrored trades - with dynamic sorting and date range, used by the CopyTrader history collapsed view UI.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @From/@To date range; result grouped by ParentCID/ParentUserName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the **"collapsed" CopyTrader history view** in the eToro platform UI - the screen that shows a customer's copy trading performance summarized per leader, rather than listing individual positions. It returns one row per leader whose positions the customer copied (sourced from `History.Mirror`), plus a synthetic row with `ParentCID=-1` and `ParentUserName='Manual'` that aggregates all non-mirrored positions (both pure manual trades and CopyPlus/Smart Portfolio positions). Each row contains summed Amount, Units, NetProfit, and computed Gain% for the given date range.

---

## 2. Business Logic

### 2.1 Two-Branch UNION: Copy Trader vs Manual

**What**: A UNION of two SELECT statements distinguishes leader-attributed copy trades from all other positions.

**Branch 1 - Copy Trader** (`HP.MirrorID > 0`):
- Reads `History.Position` filtered by `HP.MirrorID > 0` AND `EndDateTime BETWEEN @From1 AND @To1`
- LEFT JOINs a DISTINCT subquery of `History.Mirror` (columns: CID, MirrorID, ParentUserName, ParentCID) on `HP.MirrorID = HM.MirrorID`
- Filters `HM.CID = @CID` in WHERE to restrict to this customer's mirror relationships
- Groups by `ParentCID, ParentUserName` to produce one row per leader

**Branch 2 - Manual** (`MirrorID = 0`):
- Reads `History.Position` WHERE `CID = @CID` AND `MirrorID = 0` (either `ParentPositionID = 0` or `ParentPositionID <> 0`)
- Assigns `ParentCID = -1`, `ParentUserName = 'Manual'`
- **Includes**: Pure manual trades (MirrorID=0, ParentPositionID=0) AND CopyPlus/Smart Portfolio (MirrorID=0, ParentPositionID>0)
- **Excludes**: The commented-out `(MirrorID <> 0 AND ParentPositionID = 0)` case (detached mirror positions) - these fall into Branch 1 since they still have MirrorID > 0

### 2.2 HAVING SUM(Amount) > 0

**What**: Outer GROUP BY + HAVING filters out any leader groups where total invested amount is zero or less.

**Rules**: Applied after the UNION, grouping by `ParentCID, ParentUserName`. Prevents zero-amount ghost rows from appearing in the UI.

### 2.3 Gain Calculation

**What**: Portfolio-level percentage gain per leader group.

**Formula**: `ISNULL((ISNULL(SUM(NetProfit), 0) / NULLIF(ISNULL(SUM(Amount), 0), 0)), 0) * 100.0`

- NULLIF prevents divide-by-zero when total Amount is 0
- Outer ISNULL converts NULL result to 0
- Multiplied by 100 to express as percentage

### 2.4 Dynamic Sort Order

**What**: Caller controls sort column and direction.

**Supported sort columns**: ParentUserName (case-insensitive via lower()), Amount, NetProfit, Gain, Units.

**Rules**: CASE WHEN @OrderBy = '{column}' AND @SortDirection = 'DESC'/'ASC' THEN {agg} END per column. Both @OrderBy and @SortDirection are case-sensitive. Unknown values fall back to natural result order.

### 2.5 Anti-Parameter-Sniffing

**What**: @From1/@To1 local variable copies prevent SQL Server from sniffing date range parameters for plan caching.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose closed positions are aggregated. Filters both History.Position.CID and History.Mirror.CID. |
| 2 | @From | DATETIME | NO | - | CODE-BACKED | Start of date range filter on History.Position.EndDateTime (close date). |
| 3 | @To | DATETIME | NO | - | CODE-BACKED | End of date range filter on History.Position.EndDateTime. |
| 4 | @OrderBy | VARCHAR(24) | NO | - | CODE-BACKED | Column to sort by. Supported: ParentUserName, Amount, NetProfit, Gain, Units. Case-sensitive. |
| 5 | @SortDirection | VARCHAR(4) | NO | - | CODE-BACKED | Sort direction: 'ASC' or 'DESC'. Case-sensitive. |

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| ParentCID | History.Mirror.ParentCID | Leader's customer ID. -1 for the "Manual" synthetic row. |
| ParentUserName | History.Mirror.ParentUserName | Leader's username. 'Manual' for all non-mirrored positions (pure manual + CopyPlus). |
| Amount | SUM(History.Position.Amount) | Total USD invested across all positions for this leader in the date range. |
| Units | SUM(History.Position.AmountInUnitsDecimal) | Total position size in instrument units. |
| NetProfit | SUM(History.Position.NetProfit) | Total realized PnL in USD for this leader in the date range. |
| Gain | (SUM(NetProfit)/SUM(Amount))*100 | Aggregate percentage return on invested amount for this leader. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary source of closed position data; filtered by MirrorID, CID, EndDateTime. |
| LEFT JOIN | History.Mirror | Read | Lookup for ParentCID and ParentUserName per MirrorID; DISTINCT subquery deduplicates multiple records per CID+MirrorID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| eToro platform API | EXEC | Direct call | CopyTrader history collapsed view UI - leader performance summary screen. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetCopyTraderViewCollapsed (procedure)
├── History.Position (table)
└── History.Mirror (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Primary source; filtered by CID, MirrorID, EndDateTime date range. |
| History.Mirror | Table | LEFT JOIN (as DISTINCT subquery) for ParentCID and ParentUserName; CID filter applied in WHERE. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToro platform (application) | External | CopyTrader history UI - collapsed view showing per-leader performance summary. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| HAVING SUM(Amount) > 0 | Post-aggregate filter | Excludes leader groups where no net amount was invested in the date range. Prevents empty rows. |
| Mirror DISTINCT subquery | Deduplication | DISTINCT on (CID, MirrorID, ParentUserName, ParentCID) prevents duplicate rows from multiple History.Mirror entries per mirror relationship. |
| Manual bucket includes CopyPlus | Design | MirrorID=0 AND ParentPositionID>0 (CopyPlus/Smart Portfolio) is grouped with pure manual trades under ParentUserName='Manual'. CopyPlus positions are NOT attributed to a leader in this view. |
| Detached mirror exclusion | Design | The commented-out `(MirrorID <> 0 AND ParentPositionID = 0)` case is excluded from the Manual branch; detached positions with MirrorID>0 appear in the Copy Trader branch. |
| Anti-sniffing | Date filter | @From1/@To1 local variables used in WHERE clauses prevent parameter sniffing on date range parameters. |

---

## 8. Sample Queries

### 8.1 Get collapsed CopyTrader view sorted by NetProfit descending

```sql
EXEC History.GetCopyTraderViewCollapsed
    @CID = 12345,
    @From = '2024-01-01',
    @To = '2024-12-31',
    @OrderBy = 'NetProfit',
    @SortDirection = 'DESC';
```

### 8.2 Get sorted by leader name ascending

```sql
EXEC History.GetCopyTraderViewCollapsed
    @CID = 12345,
    @From = '2024-01-01',
    @To = '2024-12-31',
    @OrderBy = 'ParentUserName',
    @SortDirection = 'ASC';
```

### 8.3 Verify underlying data for a specific leader

```sql
SELECT
    HM.ParentCID,
    HM.ParentUserName,
    SUM(HP.Amount) AS TotalAmount,
    SUM(HP.NetProfit) AS TotalNetProfit,
    (SUM(HP.NetProfit) / NULLIF(SUM(HP.Amount), 0)) * 100 AS Gain
FROM History.Position HP WITH (NOLOCK)
LEFT JOIN (SELECT DISTINCT CID, MirrorID, ParentUserName, ParentCID FROM History.Mirror WITH (NOLOCK)) HM
    ON HP.MirrorID = HM.MirrorID
WHERE HM.CID = 12345
  AND HP.MirrorID > 0
  AND HP.EndDateTime BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY HM.ParentCID, HM.ParentUserName
HAVING SUM(HP.Amount) > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetCopyTraderViewCollapsed | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetCopyTraderViewCollapsed.sql*

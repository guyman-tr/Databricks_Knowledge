# BI_DB_dbo.BI_DB_ClubChangeLog

> Customer club change event log — 12 columns recording each upgrade, downgrade, and first-club assignment in eToro's loyalty tier system. One row per change event per customer per day. Built daily by SP_ClubChangeLog using equity-threshold rules. First Club (95%) dominates; Upgrades (5%); Downgrades discontinued post-2023.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.V_Liabilities + FiatDwhDB EOD balance (post-2023) |
| **Refresh** | Daily (SP_ClubChangeLog @dd, DELETE by CreateDate >= @dd + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED (CID ASC) |
| | |
| **OpsDB Priority** | 0 (base layer), Daily, SB_Daily |
| **Authors** | Guy Barkat (2019-04-18), Tom Boksenbojm (2019-2023 revisions) |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_ClubChangeLog` is the eToro loyalty club change history table. eToro customers are assigned to club tiers (Bronze → Silver → Gold → Platinum → Platinum Plus → Diamond) based on their non-CFD equity. This table logs every time a customer's club level changes.

**Six club tiers** (2026 distribution of new events):
- **Bronze** (PlayerLevelID=1) — 95% of events: new customers joining the eToro club system
- **Silver** (PlayerLevelID=5) — equity ≥ $5,000
- **Gold** (PlayerLevelID=3) — equity ≥ $10,000
- **Platinum** (PlayerLevelID=2) — equity ≥ $25,000
- **Platinum Plus** (PlayerLevelID=6) — equity ≥ $50,000
- **Diamond** (PlayerLevelID=7) — equity ≥ $250,000

**Important**: PlayerLevelIDs are non-sequential. Use `NewSort`/`CurrentSort` for ordinal ranking (Bronze=1, Silver=2, Gold=3, Platinum=4, Platinum Plus=5, Diamond=6).

**Three event types** (`PLChangeType`):
- **First Club**: Customer's first-ever entry in this table (CurrentLevel IS NULL). ~95.5% of 2026 events.
- **Upgrade**: NewSort > CurrentSort — customer reached a higher tier. ~4.5% of 2026 events.
- **Downgrade**: NewSort < CurrentSort — customer dropped to a lower tier. **Discontinued post-2023-01-01**. Historical records exist pre-2023.

**IsFTC** (First Time Club): 1 = this is the first time the customer has ever reached a non-Bronze club level across their entire history. Useful for identifying milestone events (first deposit milestone, first tier achievement).

**Equity methodology** changed significantly:
- **Pre-2023**: Maximum equity over a 3-month rolling window (peak, not point-in-time). Net deposits also counted pre-2019-07-22.
- **Post-2023**: Point-in-time non-CFD equity on the run date — `RealizedEquityNoCFD = TotalRealStocks + TotalRealCrypto + TotalCash + EODBalanceAmount_USD (eToroMoney) + InProcessCashouts`.

---

## 2. Business Logic

### 2.1 Club Tier Determination (post-2023)

**What**: Each customer's new club tier is computed from their non-CFD realized equity on the run date.

**Rule** (post-2023, effective for CreateDate ≥ 2023-01-01):
```
RealizedEquityNoCFD = V_Liabilities.TotalRealStocks
                    + V_Liabilities.TotalRealCrypto
                    + V_Liabilities.TotalCash
                    + FiatDwhDB.EODBalanceAmount_USD   (eToroMoney balance)
                    + V_Liabilities.InProcessCashouts

ClubTier = CASE
  WHEN RealizedEquityNoCFD >= 250000 → Diamond (7)
  WHEN RealizedEquityNoCFD >= 50000  → Platinum Plus (6)
  WHEN RealizedEquityNoCFD >= 25000  → Platinum (2)
  WHEN RealizedEquityNoCFD >= 10000  → Gold (3)
  WHEN RealizedEquityNoCFD >= 5000   → Silver (5)
  ELSE                               → Bronze (1)
END
```

### 2.2 Equity Methodology — Pre-2023 (Historical)

**Pre-2023-01-01**: Club tier was based on the MAX realized equity over the past 3 months (not point-in-time). Sources: `MAX(BI_DB_CustomerDTDAggregatedData.LastRealizedEquity)` OR `MAX(Fact_SnapshotEquity.RealizedEquity)` over the trailing window — whichever was higher (FULL OUTER JOIN, MAX comparison).

**Pre-2019-07-22**: Net Deposits (ActionTypeID 7 minus 8) over 3 months ALSO counted toward tier eligibility — `MAX(equity OR net_deposit)`.

### 2.3 Change Type Logic

**Upgrade** (inserted daily): `WHERE NewSort > CurrentSort`

**Downgrade** (pre-2023 only, inserted only on last day of month):
- `WHERE NewSort < CurrentSort`
- `IF EOMONTH(@dd) = @dd` — only executes on the last calendar day of each month

**First Club**: `WHERE CurrentLevel IS NULL` — customer has no prior entry in BI_DB_ClubChangeLog

**Note**: Post-2023, downgrades are not recorded. Any customer who drops below their prior tier will simply not get an upgrade event; no downgrade row is inserted. This is a deliberate product decision per the SP change history.

### 2.4 IsFTC — First Time (to) Club

**What**: Marks whether this is the first time ever the customer has been at a non-Bronze club tier.

**Rule**:
```
IsFTC = CASE
  WHEN COUNT(rows WHERE NewLevel > 1) OVER (PARTITION BY CID ORDER BY CreateDate) = 1
       → 1   (first time reaching non-Bronze)
  ELSE → 0
END
```
Applied at INSERT time for Upgrade events (IsFTC is initially NULL, then backfilled via UPDATE). For First Club events: `IsFTC = CASE WHEN NewLevel = 1 THEN 0 ELSE 1 END`.

### 2.5 Self-Reference Pattern

**What**: The SP reads from BI_DB_ClubChangeLog itself to establish the "Current" state.

**Rule**: `#CurrentClub` = `SELECT TOP 1 ... FROM BI_DB_ClubChangeLog WHERE CreateDate <= @dd ORDER BY CreateDate DESC` partitioned by CID. This is the customer's most recent club as of the run date.

**Implication**: The table maintains its own state and the SP is a forward-only accumulator. Re-running a date range requires careful handling (DELETE WHERE CreateDate >= @dd before re-running).

---

## 3. Query Advisory

### 3.1 Distribution and Index

ROUND_ROBIN distribution. Clustered index on `CID` makes per-customer queries efficient.

### 3.2 Club Tier Ordering

**Never use PlayerLevelID (NewLevel/CurrentLevel) for club rank ordering** — the IDs are non-sequential (Bronze=1, Platinum=2, Gold=3, Silver=5, Platinum+=6, Diamond=7). Always use `NewSort`/`CurrentSort` for ordinal comparisons.

### 3.3 Downgrade Gap (Post-2023)

Post-2023 data has no Downgrade rows. If a customer drops from Gold to Bronze, the log will show: last row = 'Upgrade' to Gold (whenever they got there), with no subsequent downgrade. Analysts computing "current club from the log" should be aware they may be reading a stale club level for customers who have since lost equity.

Use `DWH_dbo.Fact_SnapshotCustomer.PlayerLevelID` or recompute from current equity for the current tier.

### 3.4 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All club upgrades this month | WHERE PLChangeType='Upgrade' AND CreateDate >= DATEADD(day,-30,GETDATE()) |
| First-time tier achievers | WHERE IsFTC=1 AND PLChangeType='Upgrade' |
| New Bronze registrations | WHERE PLChangeType='First Club' AND NewClub='Bronze' |
| High-value customer upgrades to Diamond | WHERE NewClub='Diamond' AND PLChangeType IN ('Upgrade','First Club') |
| Customer's current club (pre-2023 reliable) | SELECT TOP 1 ... ORDER BY CreateDate DESC per CID |

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 2 — SP_ClubChangeLog ETL logic | (Tier 2 — SP_ClubChangeLog) |
| Tier 2 — ETL metadata | (Tier 2 — ETL metadata) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NULL | Customer ID. References DWH_dbo.Dim_Customer / Fact_SnapshotCustomer.RealCID. (Tier 2 — SP_ClubChangeLog) |
| 2 | CreateDate | datetime | NULL | Date of the club change event. Set to the SP run parameter @dd. Used as the primary event timestamp. (Tier 2 — SP_ClubChangeLog) |
| 3 | CurrentLevel | int | NULL | PlayerLevelID of the customer's club BEFORE this change. NULL for 'First Club' events (customer has no prior history). Non-sequential IDs: 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum+, 7=Diamond. Use CurrentSort for ordering. (Tier 2 — SP_ClubChangeLog) |
| 4 | NewLevel | int | NULL | PlayerLevelID of the customer's club AFTER this change. Non-sequential IDs — see CurrentLevel. (Tier 2 — SP_ClubChangeLog) |
| 5 | PLChangeType | varchar(?) | NULL | Change event type. Values: 'Upgrade' (NewSort > CurrentSort, daily), 'Downgrade' (NewSort < CurrentSort, pre-2023 month-end only), 'First Club' (no prior history). Post-2023: only 'Upgrade' and 'First Club' are produced. (Tier 2 — SP_ClubChangeLog) |
| 6 | CurrentClub | varchar(50) | NULL | Club name BEFORE this change. Resolved from Dim_PlayerLevel.Name via CurrentLevel. NULL for 'First Club' events. Values: 'Bronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'. (Tier 2 — SP_ClubChangeLog) |
| 7 | NewClub | varchar(50) | NULL | Club name AFTER this change. Resolved from Dim_PlayerLevel.Name via new computed tier. Same value set as CurrentClub. (Tier 2 — SP_ClubChangeLog) |
| 8 | CurrentSort | int | NULL | Ordinal rank of club BEFORE change: Bronze=1, Silver=2, Gold=3, Platinum=4, Platinum Plus=5, Diamond=6. NULL for 'First Club'. Use this column (not PlayerLevelID) for club rank comparisons. (Tier 2 — SP_ClubChangeLog) |
| 9 | NewSort | int | NULL | Ordinal rank of club AFTER change. Same scale as CurrentSort. (Tier 2 — SP_ClubChangeLog) |
| 10 | IsDepositor | int | NULL | Whether the customer has ever made a successful deposit as of the run date. Sourced from DWH_dbo.Fact_SnapshotCustomer.IsDepositor. 1=yes, 0=no. (Tier 2 — SP_ClubChangeLog) |
| 11 | UpdateDate | datetime | NULL | ETL load timestamp. GETDATE() at INSERT; updated again on IsFTC backfill pass. (Tier 2 — ETL metadata) |
| 12 | IsFTC | int | NULL | First Time (reaching this) Club flag. 1=first time customer has ever been at a non-Bronze club level (NewLevel>1, COUNT of prior such events = 1). 0=previously achieved a non-Bronze level. For 'First Club' at Bronze: always 0. (Tier 2 — SP_ClubChangeLog) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Role | Notes |
|--------|------|-------|
| DWH_dbo.Fact_SnapshotCustomer | Customer roster | RealCID, IsDepositor, GCID (post-2023), IsValidCustomer filter |
| DWH_dbo.V_Liabilities | Non-CFD equity | TotalRealStocks, TotalRealCrypto, TotalCash, InProcessCashouts |
| BI_DB_dbo.External_Gold_DE_FiatDwhDB_CustomerEODBalance_ClubChange | eToroMoney EOD balance | EODBalanceAmount_USD — created by SP_Create_External_Gold_DE_FiatDwhDB_CustomerEODBalance @dd, 'ClubChange' |
| DWH_dbo.Dim_PlayerLevel | Club name + sort order | PlayerLevelID → Name + Sort |
| BI_DB_dbo.BI_DB_ClubChangeLog (self-ref) | Current club state | #CurrentClub = latest club per CID from existing log |
| BI_DB_dbo.BI_DB_CustomerDTDAggregatedData | Pre-2023: max equity window | LastRealizedEquity over 3-month window |
| DWH_dbo.Fact_SnapshotEquity | Pre-2023: max equity window | RealizedEquity over 3-month window |
| DWH_dbo.Fact_CustomerAction | Pre-2019-07-22: net deposits | ActionTypeID 7 (deposits) minus 8 (withdrawals) |
| DWH_dbo.Dim_Range | Pre-2023 date range mapping | DateRangeID → FromDateID/ToDateID |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (all valid customers)
  + DWH_dbo.V_Liabilities (non-CFD equity)
  + External_Gold_DE_FiatDwhDB_CustomerEODBalance_ClubChange (eToroMoney balance)
  → RealizedEquityNoCFD computation
  → ClubTier CASE (Diamond/Platinum+/Platinum/Gold/Silver/Bronze)
  + DWH_dbo.Dim_PlayerLevel (club names, sort orders)
  + BI_DB_ClubChangeLog self-reference (#CurrentClub — prior state)
  |
  v [SP_ClubChangeLog @dd — Priority 0, Daily, SB_Daily]
    1. DELETE WHERE CreateDate >= @dd
    2. #CurrentClub = most recent club per CID from existing log
    3. Compute new club tier (equity-based CASE)
    4. INSERT Upgrades (NewSort > CurrentSort)
    5. INSERT First Club (CurrentLevel IS NULL)
    6. (Month-end only, pre-2023): INSERT Downgrades
    7. UPDATE IsFTC for newly inserted rows
BI_DB_dbo.BI_DB_ClubChangeLog (ROUND_ROBIN, CLUSTERED CID)
```

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID, IsDepositor | DWH_dbo.Fact_SnapshotCustomer | Customer roster + depositor status |
| RealizedEquityNoCFD | DWH_dbo.V_Liabilities | Non-CFD equity breakdown |
| EODBalanceAmount_USD | BI_DB_dbo.External_Gold_DE_FiatDwhDB_CustomerEODBalance_ClubChange | eToroMoney balance |
| NewLevel, NewSort, NewClub | DWH_dbo.Dim_PlayerLevel | Club tier name and rank |
| CurrentLevel, CurrentSort, CurrentClub | BI_DB_dbo.BI_DB_ClubChangeLog (self) | Prior club state via self-reference |
| (pre-2023) MaxEqy | BI_DB_dbo.BI_DB_CustomerDTDAggregatedData | 3-month max equity |
| (pre-2023) MaxEqy | DWH_dbo.Fact_SnapshotEquity | 3-month max realized equity |

### 6.2 Referenced By (downstream objects)

| Source Object | Description |
|--------------|-------------|
| BI_DB_dbo.BI_DB_ClubChangeLogProduct | SP_ClubChangeLogProduct (P20) enriches with product-level data |
| BI_DB_dbo.BI_DB_CID_DailyPanel_Club | Daily panel data for club analytics |
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Full daily panel uses club history |
| BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | Monthly panel aggregation |

---

## 7. Sample Queries

### 7.1 Recent upgrade events by club tier

```sql
SELECT
    NewClub,
    COUNT(*) AS Upgrades,
    SUM(IsFTC) AS FirstTimeAchievers,
    SUM(IsDepositor) AS DepositorUpgrades
FROM [BI_DB_dbo].[BI_DB_ClubChangeLog]
WHERE PLChangeType = 'Upgrade'
  AND CreateDate >= DATEADD(month, -1, GETDATE())
GROUP BY NewClub
ORDER BY NewSort DESC
```

### 7.2 New Bronze club members (first-timers today)

```sql
SELECT COUNT(*) AS NewBronzeToday
FROM [BI_DB_dbo].[BI_DB_ClubChangeLog]
WHERE PLChangeType = 'First Club'
  AND NewClub = 'Bronze'
  AND CAST(CreateDate AS DATE) = CAST(GETDATE()-1 AS DATE)
```

### 7.3 Customer's full club history

```sql
SELECT
    CID, CreateDate, PLChangeType,
    CurrentClub, NewClub, CurrentSort, NewSort,
    IsFTC, IsDepositor
FROM [BI_DB_dbo].[BI_DB_ClubChangeLog]
WHERE CID = 12345678
ORDER BY CreateDate ASC
```

---

## 8. Atlassian Knowledge Sources

No Confluence pages identified. Club tier definitions and business rules may exist in eToro Product documentation.

---

*Generated: 2026-04-23 | Quality: 9.2/10 | Batch: 63 | Object: 3/4*
*Tiers: 0 T1, 12 T2 | Elements: 9.0/10, Logic: 9.5/10, Lineage: 9.0/10, Relationships: 9.0/10*
*Object: BI_DB_dbo.BI_DB_ClubChangeLog | Type: Table | Production Source: DWH_dbo.Fact_SnapshotCustomer + V_Liabilities + FiatDwhDB*

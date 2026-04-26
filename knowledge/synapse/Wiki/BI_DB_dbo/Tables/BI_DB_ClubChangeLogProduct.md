# BI_DB_dbo.BI_DB_ClubChangeLogProduct

> 49.4M-row append-only event log capturing every eToro Club loyalty tier change for 46.4M customers from 2007-08-22 to 2026-04-12. Each row records one club event: initial assignment (FirstClub), promotion (Upgrade), or demotion (Downgrade), with the customer's old and new tier, club name, and sort rank. The IsFTC flag identifies a customer's first-ever promotion above Bronze. Updated daily by SP_ClubChangeLogProduct via DELETE-then-append (idempotent replay from @Date).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer × Dim_PlayerLevel × Dim_Range (via SP_ClubChangeLogProduct) |
| **Refresh** | Daily — DELETE WHERE Date >= @Date + INSERT (append-only, idempotent per-date) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_ClubChangeLogProduct is the master audit trail for eToro Club loyalty tier changes. It stores every tier transition event for every customer since the platform's earliest records (2007-08-22). With 49.4M rows across 46.4M distinct customers, the vast majority of customers (94.6%) have exactly one row — their initial Bronze assignment (PLChangeType='FirstClub'/'First Club'). The 2.2M upgrade events and 695K downgrade events represent customers who moved between the six tiers: Bronze → Silver → Gold → Platinum → Platinum Plus → Diamond.

The table feeds daily customer panel tables: SP_CID_DailyPanel_FullData, SP_CID_MonthlyPanel_FullData, and SP_CID_DailyPanel_Club use it to track current-tier and tier-change history for CRM segmentation.

**Key caveat — PLChangeType dual naming**: The column contains two spellings for the initial assignment event: `'First Club'` (31.5M rows, legacy SP) and `'FirstClub'` (14.9M rows, current SP). Consumers must use `IN ('FirstClub', 'First Club')` or `LIKE 'First%Club'` — filtering on a single spelling silently misses ~68% or ~32% of first-club events.

The IsFTC (First Time Club) flag marks a customer's first-ever transition to a tier above Bronze (CurrentTier > 1), identified by the cumulative rank = 1 window. As of April 2026, 1.1M customers have IsFTC=1.

---

## 2. Business Logic

### 2.1 Club Change Detection

**What**: SP compares today's snapshot tier (Fact_SnapshotCustomer) with the customer's most-recent prior entry in this table.

**Columns Involved**: OldTier, OldSort, CurrentTier, CurrentSort, PLChangeType

**Rules**:
- If `CurrentSort < OldSort` → PLChangeType = 'Downgrade'
- If `CurrentSort > OldSort` → PLChangeType = 'Upgrade'
- If no prior entry in the table → PLChangeType = 'FirstClub', OldTier/OldClub/OldSort = NULL
- Comparison is on PlayerLevelID (not Sort): `c.CurrentTier != cc.CurrentTier` triggers the change logic
- **Sort semantics**: Sort 1=Bronze (lowest), Sort 6=Diamond (highest). A decrease in Sort = Downgrade.

### 2.2 IsFTC — First Time Club

**What**: Identifies customers who receive their first-ever promotion to a tier above Bronze.

**Columns Involved**: IsFTC, CurrentTier

**Rules**:
- Applies only to rows where CurrentTier > 1 (i.e., not Bronze)
- Window: `COUNT(CID) OVER (PARTITION BY CID ORDER BY Date) = 1` → that is the first-ever non-Bronze assignment for that CID
- IsFTC = 1 for that row, 0 for all other rows (including Bronze first assignments and subsequent tier changes)
- IsFTC is updated post-INSERT via a separate UPDATE statement; rows from the current run with NULL IsFTC are processed
- As of 2026-04-12: IsFTC=1 → 1.1M rows (2.3%), IsFTC=0 → 48.2M rows (97.7%)

### 2.3 Idempotent Append Pattern

**What**: The table accumulates all history; replaying the SP for a past date is safe.

**Columns Involved**: Date, UpdateDate

**Rules**:
- DELETE WHERE Date >= @Date removes all rows from @Date forward
- Then inserts only the changes detected for @Date
- Because the detection logic reads the table itself (self-join for "prior state"), replaying a day also re-derives the change type for that day
- Historical rows (before @Date) are untouched

### 2.4 Club Tier Mapping

**What**: PlayerLevelID values are non-sequential — use Sort for ordering.

**Columns Involved**: CurrentTier, CurrentClub, CurrentSort

**Rules**:
- CurrentTier = Dim_PlayerLevel.PlayerLevelID (FK): 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond
- CurrentSort = Dim_PlayerLevel.Sort: 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond
- **Do not order by CurrentTier** — the IDs are non-sequential. Always use CurrentSort for tier rank ordering.
- OldTier/OldSort follow the same mapping for the previous tier.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**Distribution**: ROUND_ROBIN — no distribution skew but JOIN-intensive queries (e.g., joining to Dim_Customer on CID) will trigger data movement. For CID-level joins, consider adding a WHERE filter on Date to reduce the broadcast.

**Index**: CLUSTERED INDEX (Date ASC) — optimized for date-range scans (e.g., all changes this month). CID-level lookups (find a customer's tier history) do not benefit from the clustered index and may require full-table scans on large ranges.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many customers changed tiers today? | `WHERE Date = @today AND PLChangeType IN ('Upgrade','Downgrade')` |
| Customer's full club history | `WHERE CID = @cid ORDER BY Date ASC` |
| All upgrades to Diamond | `WHERE CurrentClub = 'Diamond' AND PLChangeType = 'Upgrade'` |
| First-time non-Bronze customers | `WHERE IsFTC = 1` |
| Monthly tier change volume | `GROUP BY YEAR(Date), MONTH(Date), PLChangeType` |
| Current tier per customer | Use `BI_DB_CID_DailyPanel_FullData` — this table is a log, not a snapshot |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_PlayerLevel | ON ccl.CurrentTier = dpl.PlayerLevelID | Resolve tier name (though CurrentClub is already denormalized) |
| DWH_dbo.Dim_Customer | ON ccl.CID = dc.RealCID | Customer attributes at query time |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON ccl.CID = fd.CID | Customer milestone dates |

### 3.4 Gotchas

- **PLChangeType dual naming**: `'FirstClub'` and `'First Club'` are the same event type — use `IN ('FirstClub', 'First Club')` not equality.
- **CurrentTier is NOT in rank order**: PlayerLevelID 1=Bronze, 2=Platinum, 3=Gold (not sequential). Always use CurrentSort for ordering tiers.
- **Not a snapshot table**: Does NOT show a customer's current tier. Contains only change events. For current tier, join to Dim_Customer or query BI_DB_CID_DailyPanel_FullData.
- **Bronze first-assignments dominate**: 95% of rows are first-club Bronze events, many with OldTier/OldClub/OldSort = NULL. WHERE OldTier IS NOT NULL filters to actual tier-change events only.
- **IsFTC NULL during SP run**: The IsFTC column is temporarily NULL for new rows until the post-INSERT UPDATE runs. If querying immediately after INSERT (before UPDATE completes), new rows may show NULL.
- **Date range vs UpdateDate**: Date = business event date (@Date parameter). UpdateDate = SYSUTCDATETIME() at INSERT/UPDATE time (always next-day UTC).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 — upstream wiki verbatim | (Tier 1 — Customer.CustomerStatic) |
| *** | Tier 2 — SP code / ETL logic | (Tier 2 — SP_ClubChangeLogProduct) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | Date | date | NO | Business event date — the SP run date (@Date parameter) on which the club change was detected. Clustered index key. Use this column for date-range scans. (Tier 2 — SP_ClubChangeLogProduct) |
| 3 | OldTier | int | YES | Previous loyalty tier PlayerLevelID before this change. NULL for FirstClub/First Club events (no prior tier). FK to Dim_PlayerLevel. Not in rank order — use OldSort for ordering. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. (Tier 2 — SP_ClubChangeLogProduct) |
| 4 | OldClub | varchar(50) | YES | Previous club name resolved from Dim_PlayerLevel.Name at the time of the last prior event. NULL for FirstClub events. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 — SP_ClubChangeLogProduct) |
| 5 | OldSort | int | YES | Previous tier sort order from Dim_PlayerLevel.Sort. NULL for FirstClub events. 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use this column (not OldTier) for rank ordering. (Tier 2 — SP_ClubChangeLogProduct) |
| 6 | CurrentTier | int | NO | Current loyalty tier PlayerLevelID from Fact_SnapshotCustomer on the event date. FK to Dim_PlayerLevel. Non-sequential: 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. Use CurrentSort for ordering. (Tier 2 — SP_ClubChangeLogProduct) |
| 7 | CurrentClub | varchar(50) | NO | Current club name resolved from Dim_PlayerLevel.Name at ETL time. Denormalized — no JOIN needed for display. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 — SP_ClubChangeLogProduct) |
| 8 | CurrentSort | int | NO | Current tier sort order from Dim_PlayerLevel.Sort. 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use this column for correct tier rank ordering. (Tier 2 — SP_ClubChangeLogProduct) |
| 9 | PLChangeType | varchar(50) | NO | Club event type. IMPORTANT — dual naming: 'FirstClub' (current SP, 14.9M rows) and 'First Club' (legacy SP, 31.5M rows) both indicate initial tier assignment. 'Upgrade' (2.2M): Sort improved. 'Downgrade' (695K): Sort decreased. Always use IN or LIKE when filtering on first-assignment events. (Tier 2 — SP_ClubChangeLogProduct) |
| 10 | UpdateDate | datetime2(7) | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to SYSUTCDATETIME() at INSERT and again at IsFTC UPDATE. (Tier 2 — SP_ClubChangeLogProduct) |
| 11 | IsFTC | int | YES | First Time Club flag. 1 = this is the customer's first-ever promotion to a tier above Bronze (CurrentTier > 1 AND cumulative rank = 1 by Date). 0 = all other events, including Bronze first-assignments and subsequent tier changes. (Tier 2 — SP_ClubChangeLogProduct) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Rename via relay: Fact_SnapshotCustomer.RealCID → CID |
| Date | ETL parameter | @Date | Set to SP run date parameter |
| OldTier | BI_DB_ClubChangeLogProduct (self) | CurrentTier | Last prior row per CID (ROW_NUMBER OVER PARTITION BY CID ORDER BY Date DESC) |
| OldClub | BI_DB_ClubChangeLogProduct (self) | CurrentClub | Last prior row per CID |
| OldSort | BI_DB_ClubChangeLogProduct (self) | CurrentSort | Last prior row per CID |
| CurrentTier | Fact_SnapshotCustomer | PlayerLevelID | Passthrough from today's snapshot |
| CurrentClub | Dim_PlayerLevel | Name | JOIN on PlayerLevelID at ETL time |
| CurrentSort | Dim_PlayerLevel | Sort | JOIN on PlayerLevelID at ETL time |
| PLChangeType | ETL | CASE logic | 'Downgrade' if CurrentSort < OldSort; 'Upgrade' otherwise; 'FirstClub' if no prior row |
| UpdateDate | ETL | SYSUTCDATETIME() | Set at INSERT and IsFTC UPDATE |
| IsFTC | ETL | Window function | COUNT OVER PARTITION BY CID ORDER BY Date = 1 AND CurrentTier > 1 |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic (etoroDB-REAL)
  |-- Generic Pipeline (daily) ---|
  v
DWH_dbo.Fact_SnapshotCustomer (RealCID, PlayerLevelID, IsValidCustomer, DateRangeID)
  |
  +-- DWH_dbo.Dim_Range (DateRangeID → FromDateID/ToDateID)
  +-- DWH_dbo.Dim_PlayerLevel (PlayerLevelID → Name, Sort)
  |
  |-- SP_ClubChangeLogProduct (@Date) ---|
  |   Step 1: #cid = today's snapshot (Fact_SnapshotCustomer × Dim_Range × Dim_PlayerLevel)
  |   Step 2: #CurrentClub = most-recent prior row per CID (self-read)
  |   Step 3: INSERT Upgrade/Downgrade (#UpDown: today != prior)
  |   Step 4: INSERT FirstClub (#new: no prior entry)
  |   Step 5: UPDATE IsFTC (window function, CurrentTier > 1)
  v
BI_DB_dbo.BI_DB_ClubChangeLogProduct (49.4M rows, 2007–2026)
  |-- UC: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |
| CurrentTier / OldTier | DWH_dbo.Dim_PlayerLevel.PlayerLevelID | Loyalty tier dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_CID_DailyPanel_FullData | ClubChangeLogProduct | Current club tier for daily panel snapshot |
| SP_CID_MonthlyPanel_FullData | ClubChangeLogProduct | Current club tier for monthly panel |
| SP_CID_DailyPanel_Club | ClubChangeLogProduct | Club-level daily analytics |
| SP_CID_DailyPanel_FullData_ofir | ClubChangeLogProduct | Alternate daily panel variant |

---

## 7. Sample Queries

### 7.1 Recent tier changes (last 7 days)

```sql
SELECT CID,
       Date,
       OldClub,
       CurrentClub,
       PLChangeType
FROM   [BI_DB_dbo].[BI_DB_ClubChangeLogProduct]
WHERE  Date >= DATEADD(day, -7, CAST(GETDATE() AS date))
  AND  PLChangeType IN ('Upgrade', 'Downgrade')
ORDER BY Date DESC;
```

### 7.2 First-time non-Bronze customers by month

```sql
SELECT YEAR(Date)  AS Year,
       MONTH(Date) AS Month,
       CurrentClub,
       COUNT(*)    AS NewMembers
FROM   [BI_DB_dbo].[BI_DB_ClubChangeLogProduct]
WHERE  IsFTC = 1
GROUP BY YEAR(Date), MONTH(Date), CurrentClub
ORDER BY Year DESC, Month DESC, CurrentSort;
```

### 7.3 Customer's full club history (handle dual PLChangeType spelling)

```sql
SELECT CID,
       Date,
       COALESCE(OldClub, 'None')  AS PreviousTier,
       CurrentClub                AS NewTier,
       PLChangeType,
       IsFTC
FROM   [BI_DB_dbo].[BI_DB_ClubChangeLogProduct]
WHERE  CID = @cid
ORDER BY Date ASC;
-- Note: PLChangeType 'First Club' and 'FirstClub' are both initial-assignment events
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 14/14*
*Tiers: 1 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 11/11, Logic: 10/10, Relationships: 9/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_ClubChangeLogProduct | Type: Table | Production Source: DWH_dbo.Fact_SnapshotCustomer via SP_ClubChangeLogProduct*

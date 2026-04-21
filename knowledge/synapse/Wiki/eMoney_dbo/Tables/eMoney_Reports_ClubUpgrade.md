# eMoney_dbo.eMoney_Reports_ClubUpgrade

> Club loyalty tier upgrade event log for eToro Money-eligible customers. 1,178,170 upgrade events spanning 2023-01-01 to 2026-04-11, tracking each customer's progression from a lower club tier to a higher one (Bronze → Silver → Gold → Platinum → Platinum Plus → Diamond), with geographic segmentation (UK/EU) and eToro Money account flags. Refreshed daily via TRUNCATE + INSERT by SP_eMoney_Reports_Daily.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | SP_eMoney_Reports_Daily (Steps 8-11); sources DWH_dbo.Dim_Customer, Fact_SnapshotCustomer, Dim_PlayerLevel, eMoney_Dim_Account |
| **Refresh** | Daily TRUNCATE + INSERT (full rebuild each run) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Reports_ClubUpgrade` records every eToro Club tier upgrade event for customers eligible for eToro Money, starting from 2023-01-01. Each row represents a single upgrade event for a single customer — the moment when their club tier moved upward (e.g., Bronze to Silver, Silver to Gold). Upgrades-only: tier downgrades or lateral moves are excluded (`WHERE sort_current > sort_previous`).

The table contains 1,178,170 upgrade events across ~1.178M records. The distribution shows Silver as the most common upgrade destination (371K), followed by Bronze-entry (first tier assignment, 296K), Gold (284K), Platinum (144K), Platinum Plus (75K), and Diamond (7.5K). UK accounts represent ~24% (281K), EU ~76% (897K).

**Customer eligibility filter**: Only depositors who are valid customers, fully KYC-verified (VerificationLevelID=3), and whose PlayerStatusID is not in (2=Internal, 4=Blocked, 14=Pending Delete, 15=Deleted) are included. This means the table captures the eToro Club upgrade lifecycle specifically for eligible active retail customers.

**Is_eTM flag**: 1 if the customer had a valid eToro Money account (IsValidETM=1, GCID_Unique_Count=1 in eMoney_Dim_Account), 0 otherwise. This allows downstream analysis to distinguish "native" eToro Money users (74.5%) from non-eTM customers who still meet the club upgrade criteria (25.5%).

The table rebuilds fully each day via TRUNCATE + INSERT; the historical window begins at 2023-01-01 (hardcoded in the SP WHERE clause: `dr.FromDateID >= 20230101`) and grows forward as new upgrades occur.

---

## 2. Business Logic

### 2.1 Upgrade Detection Logic

**What**: Upgrade events are detected using a LAG window function on the historical club snapshot.

**Columns Involved**: `Club_ID`, `Previous_ClubID`, `Club_Upgrade_Date`, `Club`, `Previous_Club`

**Rules**:
- Source: `DWH_dbo.Fact_SnapshotCustomer` (one row per customer per date range, capturing PlayerLevelID at each point in time)
- Previous level: `LAG(PlayerLevelID,1,0) OVER(PARTITION BY RealCID ORDER BY FromDateID ASC)` — default 0 (N/A) for first entry
- Upgrade condition: `Dim_PlayerLevel.Sort_current > Dim_PlayerLevel.Sort_previous` — only ascending moves
- `Club_Upgrade_Date` = the start date of the snapshot period where the upgrade occurred (from `DWH_dbo.Dim_Range.FromDateID` → `Dim_Date.FullDate`)
- Previous_ClubID=0 with Previous_Club='N/A' indicates the first club assignment (no prior level)

### 2.2 Club Tier ID Mapping

**What**: Club_ID (and Previous_ClubID) are PlayerLevelIDs from DWH_dbo.Dim_PlayerLevel.

**Columns Involved**: `Club_ID`, `Previous_ClubID`, `Club`, `Previous_Club`

**Rules**:
- 0 = N/A (DWH-only sentinel for first-time entries; no previous club)
- 1 = Bronze (Sort rank 1 — entry level)
- 2 = Platinum (Sort rank 4)
- 3 = Gold (Sort rank 3)
- 5 = Silver (Sort rank 2)
- 6 = Platinum Plus (Sort rank 5)
- 7 = Diamond (Sort rank 6 — top tier)
- Note: IDs are NOT sequential by rank — use `Sort` from Dim_PlayerLevel for ordered comparisons

### 2.3 eToro Money Segmentation Flags

**What**: Binary flags classify each upgrade event by geography and eToro Money account status.

**Columns Involved**: `Is_eTM`, `UK/EU`

**Rules**:
- `Is_eTM=1`: customer had a valid unique eToro Money account at SP execution time (74.5% of events)
- `Is_eTM=0`: customer met upgrade eligibility but had no active eTM account (25.5%)
- `UK/EU='UK'`: Dim_Customer.CountryID = 218 (United Kingdom); all others → 'EU'
- Note: 'EU' is a label encompassing all non-UK eToro Money rollout countries (see eMoney_Dim_Country_Rollout), not strictly EU regulatory countries

### 2.4 AccountProgram and AccountSubProgram Nullability

**What**: Program fields are NULL for Is_eTM=0 customers (no eTM account to look up).

**Columns Involved**: `AccountProgram`, `AccountSubProgram`

**Rules**:
- Populated via LEFT JOIN to eMoney_Dim_Account WHERE IsValidETM=1 AND GCID_Unique_Count=1
- NULL when Is_eTM=0 (customer has no eTM account or has multiple GCIDs)
- Program values: 'card' (debit card product), 'iban' (IBAN banking product)
- Sub-programs: e.g., 'IBAN EU Green', 'IBAN Standard UK', 'Card Standard UK', 'Card Black EU', 'Card Premium UK', 'IBAN Green AUS' (see eMoney_Dictionary_AccountSubProgram)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution ensures customer-level queries are single-node. Queries joining to DWH_dbo.Dim_Customer (HASH on RealCID) will be co-located. HEAP is appropriate for a daily-rebuilt analytical table. No clustered index → sequential scans are efficient for full-table aggregations.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Club upgrade velocity by month | GROUP BY DATETRUNC(month, Club_Upgrade_Date), Club, [UK/EU] |
| Which customers upgraded to Gold this week? | WHERE Club='Gold' AND Club_Upgrade_Date >= DATEADD(day,-7,GETDATE()) |
| eTM vs non-eTM upgrade rates by club | GROUP BY Club, Is_eTM |
| AccountProgram distribution among upgrades | WHERE Is_eTM=1 GROUP BY AccountProgram, AccountSubProgram, Club |
| Diamond tier attainment by country | WHERE Club='Diamond' GROUP BY Country, [UK/EU] |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | ON rc.CID = dc.RealCID | Extend with full customer profile |
| DWH_dbo.Dim_PlayerLevel | ON cu.Club_ID = pl.PlayerLevelID | Get Sort rank for upgrade ordering |
| eMoney_dbo.eMoney_Dim_Account | ON cu.GCID = mda.GCID | Get current eTM account details |
| eMoney_dbo.eMoney_Panel_FirstDates | ON cu.GCID = fd.GCID | Add FMI/FMO dates to upgrade context |

### 3.4 Gotchas

- **Previous_ClubID=0, Previous_Club='N/A'**: First tier assignment; customer had no prior club. Do NOT join these to Dim_PlayerLevel expecting a valid record — ID=0 is a DWH-only sentinel.
- **Historical window fixed at 2023-01-01**: Upgrades before 2023-01-01 are not tracked. Pre-2023 data gap is by SP design (hardcoded WHERE clause), not a data quality issue.
- **Full rebuild daily**: UpdateDate reflects when the SP ran, NOT when the upgrade occurred. Use `Club_Upgrade_Date` for event timing; `UpdateDate` only for ETL freshness checks.
- **Is_eTM is point-in-time**: Reflects eTM account status AT SP execution (i.e., today), not at the time of the upgrade. A customer who upgraded to Gold in 2023 but opened eTM in 2025 will show Is_eTM=1 even though they were not eTM at upgrade time.
- **UK/EU='EU' ≠ EU regulatory**: 'EU' here means "not UK" — includes Norway, Denmark, Australia, etc.
- **AccountProgram/AccountSubProgram NULL for Is_eTM=0**: Always filter `WHERE Is_eTM=1` before aggregating on program fields.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream wiki (DB_Schema/DWH wiki); original source confirmed |
| Tier 2 | Derived from SP code analysis, DDL, and live data sampling — no upstream wiki with this column |
| Tier 3 | Inferred from column name, type, and context; no code-level confirmation |
| Tier 4 | Best-available guess; requires reviewer verification |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. DWH note: column renamed from RealCID (Dim_Customer) for eMoney context; joins back via CID=RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | Club | nvarchar(50) | YES | Current club tier name after the upgrade event (e.g., 'Bronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'). Resolved from DWH_dbo.Dim_PlayerLevel.Name using the current PlayerLevelID. (Tier 2 — SP_eMoney_Reports_Daily) |
| 4 | Previous_Club | nvarchar(50) | YES | Club tier name immediately before the upgrade event (e.g., 'N/A', 'Bronze', 'Silver', 'Gold'). 'N/A' indicates the customer's first tier assignment (Previous_ClubID=0). Resolved from Dim_PlayerLevel.Name using the LAG-computed Previous_PlayerLevelID. (Tier 2 — SP_eMoney_Reports_Daily) |
| 5 | Club_ID | int | YES | PlayerLevelID of the upgraded-to tier: 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. FK to DWH_dbo.Dim_PlayerLevel. Note: IDs are NOT in rank order — use Dim_PlayerLevel.Sort for ranking. (Tier 2 — SP_eMoney_Reports_Daily) |
| 6 | Previous_ClubID | int | YES | PlayerLevelID of the tier before the upgrade: 0=N/A (first assignment), 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. ETL-computed via LAG window function on Fact_SnapshotCustomer. (Tier 2 — SP_eMoney_Reports_Daily) |
| 7 | Club_Upgrade_Date | date | YES | Calendar date when the club upgrade event occurred, derived from DWH_dbo.Dim_Date.FullDate. Corresponds to the FromDate of the Fact_SnapshotCustomer period where the tier change was detected. Range: 2023-01-01 to present (SP hardcodes 20230101 lower bound). (Tier 2 — SP_eMoney_Reports_Daily) |
| 8 | Is_eTM | int | YES | Binary flag: 1 if the customer has an active valid eToro Money account at SP execution time (eMoney_Dim_Account.IsValidETM=1 AND GCID_Unique_Count=1), 0 otherwise. 74.5% = 1; 25.5% = 0. Not the eTM status at time of upgrade — reflects current account state. (Tier 2 — SP_eMoney_Reports_Daily) |
| 9 | UK/EU | nvarchar(15) | YES | Geographic segment: 'UK' if DWH_dbo.Dim_Customer.CountryID = 218 (United Kingdom), 'EU' for all other eToro Money rollout countries (including Norway, Denmark, Australia). Not a strict EU regulatory classification. Distribution: EU=76%, UK=24%. (Tier 2 — SP_eMoney_Reports_Daily) |
| 10 | Country | nvarchar(50) | YES | Country name for the customer at upgrade time, from eMoney_dbo.eMoney_Dim_Country_Rollout.CountryName. Only eToro Money rollout countries are included (inner join scope). Examples: 'Spain', 'France', 'Germany', 'United Kingdom'. (Tier 2 — SP_eMoney_Reports_Daily) |
| 11 | AccountProgram | nvarchar(50) | YES | eToro Money product type for the customer's account: 'card' (debit card) or 'iban' (IBAN banking). Passthrough from eMoney_Dim_Account.AccountProgram (IsValidETM=1, GCID_Unique_Count=1 filter). NULL if Is_eTM=0 (no qualifying eTM account). (Tier 2 — SP_eMoney_Reports_Daily) |
| 12 | AccountSubProgram | nvarchar(50) | YES | Specific sub-program variant for the customer's eTM account (e.g., 'IBAN EU Green', 'IBAN Standard UK', 'Card Standard UK', 'Card Black EU', 'Card Premium UK'). Passthrough from eMoney_Dim_Account.AccountSubProgram. NULL if Is_eTM=0. (Tier 2 — SP_eMoney_Reports_Daily) |
| 13 | UpdateDate | datetime | YES | ETL execution timestamp set to GETDATE() when SP_eMoney_Reports_Daily ran. Reflects data freshness, not event timing. Use Club_Upgrade_Date for when the upgrade occurred. (Tier 2 — SP_eMoney_Reports_Daily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Intermediate Source | Source Column | Transform |
|---------------|---------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Renamed passthrough (CID = RealCID in DWH) |
| GCID | DWH_dbo.Dim_Customer | GCID | Direct passthrough |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on current PlayerLevelID from Fact_SnapshotCustomer |
| Previous_Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on LAG-computed Previous_PlayerLevelID |
| Club_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Current tier ID from snapshot |
| Previous_ClubID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | LAG(PlayerLevelID,1,0) window function |
| Club_Upgrade_Date | DWH_dbo.Dim_Date | FullDate | FromDateID → Dim_Date lookup |
| Is_eTM | eMoney_dbo.eMoney_Dim_Account | GCID | CASE WHEN GCID IS NOT NULL THEN 1 ELSE 0 |
| UK/EU | DWH_dbo.Dim_Customer | CountryID | CASE WHEN CountryID=218 THEN 'UK' ELSE 'EU' |
| Country | eMoney_dbo.eMoney_Dim_Country_Rollout | CountryName | Direct passthrough |
| AccountProgram | eMoney_dbo.eMoney_Dim_Account | AccountProgram | LEFT JOIN passthrough (IsValidETM=1 filter) |
| AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | LEFT JOIN passthrough (same filter) |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.Dim_Customer

etoro.Dictionary.PlayerLevel (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.Dim_PlayerLevel

DWH_dbo.Fact_SnapshotCustomer (daily club tier snapshot)
DWH_dbo.Dim_Date, Dim_Range (date dimensions)
eMoney_dbo.eMoney_Dim_Account (eTM account status)
eMoney_dbo.eMoney_Dim_Country_Rollout (country names)
  |-- SP_eMoney_Reports_Daily (Steps 8-11):  ---|
  |     Step 8: #pop (eligible customers with eTM flag, geography, programs)
  |     Step 9: #club_upgrade (LAG window detects upgrades from 2023-01-01)
  |     Step 10: #final (join #club_upgrade + #pop for full context)
  |     Step 11: TRUNCATE + INSERT → eMoney_Reports_ClubUpgrade
  v
eMoney_dbo.eMoney_Reports_ClubUpgrade (1,178,170 rows, daily refresh)
  |-- Generic Pipeline (Gold export) ---|
  v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer identity; CID = Dim_Customer.RealCID |
| GCID | DWH_dbo.Dim_Customer.GCID | Group customer identity |
| Club_ID / Previous_ClubID | DWH_dbo.Dim_PlayerLevel.PlayerLevelID | Club tier lookup |
| Country | eMoney_dbo.eMoney_Dim_Country_Rollout.CountryName | Country reference |
| AccountProgram / AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | eTM account program context |

### 6.2 Referenced By (other objects point to this)

| Object | Reference Type | Notes |
|--------|---------------|-------|
| BI reporting dashboards | Analytical consumer | Club upgrade funnel and cohort analysis |
| eMoney_Reports_AcquisitionFunnel | Sibling table | Same SP (SP_eMoney_Reports_Daily); shares customer eligibility base (#dimcustomer) |

---

## 7. Sample Queries

### Club Upgrade Funnel by Tier and Month

```sql
SELECT
    DATETRUNC(month, Club_Upgrade_Date)   AS UpgradeMonth,
    Club                                   AS ToClub,
    Previous_Club                          AS FromClub,
    [UK/EU]                                AS Region,
    COUNT(DISTINCT CID)                    AS UniqueCIDs,
    SUM(CASE WHEN Is_eTM = 1 THEN 1 ELSE 0 END) AS eTM_Upgraders
FROM [eMoney_dbo].[eMoney_Reports_ClubUpgrade]
WHERE Club_Upgrade_Date >= DATEADD(month, -3, GETDATE())
GROUP BY
    DATETRUNC(month, Club_Upgrade_Date),
    Club, Previous_Club, [UK/EU]
ORDER BY UpgradeMonth DESC, ToClub;
```

### Diamond Attainment Analysis by Country and Program

```sql
SELECT
    Country,
    AccountProgram,
    AccountSubProgram,
    COUNT(*) AS DiamondUpgrades,
    MIN(Club_Upgrade_Date) AS FirstDiamondDate,
    MAX(Club_Upgrade_Date) AS LatestDiamondDate
FROM [eMoney_dbo].[eMoney_Reports_ClubUpgrade]
WHERE Club = 'Diamond'
  AND Is_eTM = 1
GROUP BY Country, AccountProgram, AccountSubProgram
ORDER BY DiamondUpgrades DESC;
```

### Customers Who Upgraded Multiple Times

```sql
SELECT
    CID,
    GCID,
    COUNT(*) AS UpgradeCount,
    MIN(Club_Upgrade_Date) AS FirstUpgrade,
    MAX(Club_Upgrade_Date) AS LatestUpgrade,
    MAX(Club) AS CurrentMaxClub
FROM [eMoney_dbo].[eMoney_Reports_ClubUpgrade]
GROUP BY CID, GCID
HAVING COUNT(*) > 1
ORDER BY UpgradeCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table during documentation.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 2 T1, 11 T2, 0 T3, 0 T4 | Elements: 13/13, Logic: 9/10, ETL: 9/10*
*Object: eMoney_dbo.eMoney_Reports_ClubUpgrade | Type: Table | Production Source: SP_eMoney_Reports_Daily*

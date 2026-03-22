# DWH_dbo.Dim_PlayerLevel

> Lookup table defining the 7 eToro Club loyalty tiers (Bronze through Diamond plus Internal) with tier-specific cashout wait times and display sort order. NOTE: DWH drops the primary equity qualification thresholds (RealizedEquityFrom/To, DaysInRiskBeforeDowngrade) present in production.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerLevel |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PlayerLevel defines the eToro Club loyalty program tiers that segment customers by their realized equity (account value). Each tier grants progressively better benefits: faster cashout processing, higher service priority, and dedicated account management. The tiers in ascending rank are: Bronze -> Silver -> Gold -> Platinum -> Platinum Plus -> Diamond, plus a special Internal tier for employee/test accounts.

The data originates from `etoro.Dictionary.PlayerLevel` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/PlayerLevel/` in the data lake. Production has 7 active tier rows (IDs 1-7); DWH adds a synthetic ID=0 N/A placeholder.

**CRITICAL SCHEMA DRIFT**: The DWH ETL loads only 8 of the production's 13 columns. The following production columns are DROPPED and not available in DWH: `RealizedEquityFrom`, `RealizedEquityTo` (the primary tier qualification thresholds), `IsWalletRedeemAllowed`, `ThresholdPercentToCurrentLevel`, and `DaysInRiskBeforeDowngrade`. For tier qualification logic, query the upstream `etoro.Dictionary.PlayerLevel` directly or the upstream wiki. The DWH table is suitable only for resolving tier names and cashout hours -- not for equity-based tier evaluation.

Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from staging, followed by a separate INSERT VALUES for the ID=0 N/A sentinel using `@ddate` (midnight timestamp). Refreshes daily.

---

## 2. Business Logic

### 2.1 Tier Hierarchy and Rank Order

**What**: Six customer-facing loyalty tiers plus one internal tier, ranked by realized equity.

**Columns Involved**: `PlayerLevelID`, `Name`, `Sort`

**Rules**:
- IDs are NOT in rank order -- use `Sort` column for display ordering.
- Sort order: 0=Internal (excluded), 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond.
- Internal (ID=4) is excluded from customer-facing reports: `WHERE PlayerLevelID <> 4`.
- ID=0 (N/A) is a DWH-only ETL placeholder for NULL FK safety. Not in production.

**Diagram**:
```
Tier Hierarchy (by Sort/Rank):
  Sort 1 = Bronze     (ID=1) -- entry level
  Sort 2 = Silver     (ID=5)
  Sort 3 = Gold       (ID=3)
  Sort 4 = Platinum   (ID=2)
  Sort 5 = Platinum + (ID=6)
  Sort 6 = Diamond    (ID=7) -- top tier
  Sort 0 = Internal   (ID=4) -- excluded
  (ID=0  = N/A       -- DWH ETL placeholder)
```

### 2.2 Cashout Processing Speed by Tier

**What**: Higher tiers receive priority cashout processing as a loyalty benefit.

**Columns Involved**: `CashoutPendingHours`

**Rules**:
- **120 hours (5 days)**: Bronze (1), Silver (5), Internal (4), N/A (0)
- **72 hours (3 days)**: Gold (3)
- **24 hours (1 day)**: Platinum (2), Platinum Plus (6), Diamond (7)
- This is one of the most impactful benefits of upper tier membership.

### 2.3 Legacy Lot/Deposit Thresholds (Deprecated)

**What**: Historical tier qualification fields -- superseded by RealizedEquity (not in DWH).

**Columns Involved**: `FromSumLotCount`, `ToSumLotCount`, `FromSumDeposit`, `ToSumDeposit`

**Rules**:
- All set to `-1` for Platinum (2), Platinum Plus (6), Diamond (7) -- meaning "disabled/not applicable".
- Bronze (1) has 1-3000 lots, $0-$999 deposit; Silver (5) has 3001-20000 lots, $1000-$4999; Gold (3) has 20001-100000 lots, $5000-$19999.
- These columns are legacy artifacts. The current tier system uses `RealizedEquityFrom/To` which are NOT loaded into DWH.
- Value -1 = "threshold disabled -- upper tier, equity-based qualification only".

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP index. HEAP (no clustering) is unusual for dimension tables -- most Dim_ tables use CLUSTERED INDEX. With only 8 rows, HEAP is not a concern for performance but means scans are unordered. Always use `ORDER BY Sort` for consistent tier display.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`. With 8 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What tier is a customer in? | JOIN Dim_Customer ON PlayerLevelID for Name |
| Tier distribution of customer base | GROUP BY PlayerLevelID, exclude Internal (ID=4) |
| Display tiers in rank order | ORDER BY Sort ASC, exclude ID=0 and ID=4 |
| Cashout processing time for a tier | SELECT CashoutPendingHours WHERE PlayerLevelID = X |
| What are the equity thresholds? | NOT available in DWH -- use upstream wiki or prod data |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerLevelID = dpl.PlayerLevelID | Resolve tier name per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerLevelID = dpl.PlayerLevelID | View-level tier resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerLevelID = dpl.PlayerLevelID | Tier in daily snapshots |

### 3.4 Gotchas

- **IDs are NOT in rank order**: PlayerLevelID 2=Platinum, 3=Gold, 5=Silver. Always use `Sort` for ordering tiers. Filtering `PlayerLevelID > 3` does NOT mean "higher than Gold".
- **Internal tier (ID=4)**: Must be excluded in most customer analytics: `WHERE PlayerLevelID <> 4` or `WHERE PlayerLevelID NOT IN (0, 4)`.
- **-1 in range columns means disabled**: For Platinum/Platinum Plus/Diamond, FromSumLotCount=-1 and ToSumLotCount=-1 indicate the legacy lot-count threshold is not used. Do NOT interpret -1 as a valid lot count.
- **Critical columns missing from DWH**: `RealizedEquityFrom`, `RealizedEquityTo`, `DaysInRiskBeforeDowngrade`, `ThresholdPercentToCurrentLevel`, and `IsWalletRedeemAllowed` are ALL in production but NOT in DWH. For equity-tier evaluation, use the upstream source.
- **HEAP index**: Unlike most DWH Dim_ tables, this uses HEAP (no CCI). Row order is not guaranteed without explicit ORDER BY.
- **ID=0 midnight timestamp**: The N/A placeholder (ID=0) has midnight InsertDate/UpdateDate from `@ddate = CAST(GETDATE() AS DATE)`, while production rows have full timestamps from GETDATE().

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerLevelID | int | NO | Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 2 | Name | varchar(50) | NO | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 3 | CashoutPendingHours | int | NO | Maximum hours a cashout request waits before processing. 24=1 day (Platinum/Platinum Plus/Diamond), 72=3 days (Gold), 120=5 days (Bronze/Silver/Internal). Key loyalty benefit -- higher tiers get faster withdrawals. 0 for N/A placeholder. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 4 | FromSumLotCount | int | NO | Legacy: minimum cumulative lot count for tier qualification. Set to -1 for upper tiers (Platinum/Platinum Plus/Diamond -- threshold disabled). Superseded by RealizedEquityFrom (not loaded in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 5 | ToSumLotCount | int | NO | Legacy: maximum cumulative lot count for tier qualification. Set to -1 for upper tiers (threshold disabled). Superseded by RealizedEquityTo (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 6 | FromSumDeposit | int | NO | Legacy: minimum cumulative deposit (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquityFrom (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 7 | ToSumDeposit | int | NO | Legacy: maximum cumulative deposit (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquityTo (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 8 | Sort | int | NO | Display order for tier hierarchy. 0=Internal/N/A, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use ASC sort on this column for correct tier rank ordering. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 9 | DWHPlayerLevelID | int | NO | DWH surrogate key -- always equals PlayerLevelID (redundant copy). Set by ETL: SELECT [PlayerLevelID] AS [DWHPlayerLevelID]. 0 for ID=0 sentinel. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 10 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() for production rows; set to @ddate (midnight) for the ID=0 N/A sentinel. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 11 | InsertDate | datetime | NO | ETL load timestamp -- set to GETDATE() for production rows; set to @ddate (midnight) for the ID=0 N/A sentinel. Does not reflect production insert time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 12 | StatusID | tinyint | NO | Hardcoded to 1 (active) for all rows by the ETL. Not derived from production source. DWH ETL convention for dictionary tables loaded by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerLevelID | Dictionary.PlayerLevel | PlayerLevelID | passthrough |
| Name | Dictionary.PlayerLevel | Name | passthrough |
| CashoutPendingHours | Dictionary.PlayerLevel | CashoutPendingHours | passthrough |
| FromSumLotCount | Dictionary.PlayerLevel | FromSumLotCount | passthrough |
| ToSumLotCount | Dictionary.PlayerLevel | ToSumLotCount | passthrough |
| FromSumDeposit | Dictionary.PlayerLevel | FromSumDeposit | passthrough |
| ToSumDeposit | Dictionary.PlayerLevel | ToSumDeposit | passthrough |
| Sort | Dictionary.PlayerLevel | Sort | passthrough |
| DWHPlayerLevelID | -- | -- | ETL-computed: = PlayerLevelID (redundant surrogate) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() (or @ddate for ID=0 sentinel) |
| InsertDate | -- | -- | ETL-computed: GETDATE() (or @ddate for ID=0 sentinel) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |

**Dropped from production (schema drift)**: IsWalletRedeemAllowed, RealizedEquityFrom, RealizedEquityTo, ThresholdPercentToCurrentLevel, DaysInRiskBeforeDowngrade.

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerLevel.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerLevel
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerLevel/
  -> DWH_staging.etoro_Dictionary_PlayerLevel
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  -> DWH_dbo.Dim_PlayerLevel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerLevel | Production tier dictionary (etoroDB-REAL) -- 13 cols, 7 rows |
| Lake | Bronze/etoro/Dictionary/PlayerLevel/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerLevel | Raw staging import -- 8 passthrough cols only |
| ETL step 1 | SP_Dictionaries_DL_To_Synapse (line ~931) | TRUNCATE + INSERT SELECT; adds 4 computed cols; drops 5 production cols |
| ETL step 2 | SP_Dictionaries_DL_To_Synapse (line ~1538) | INSERT VALUES for ID=0 N/A sentinel using @ddate (midnight) |
| Target | DWH_dbo.Dim_PlayerLevel | 8 rows, 12 cols, REPLICATE + HEAP |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerLevelID | Customer's current loyalty tier |
| DWH_dbo.V_Dim_Customer | PlayerLevelID | View exposing tier for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Daily snapshot of customer tier |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerLevelID | Year-end snapshot tier |

---

## 7. Sample Queries

### 7.1 List all tiers in rank order

```sql
SELECT PlayerLevelID,
       Name,
       Sort,
       CashoutPendingHours
FROM   [DWH_dbo].[Dim_PlayerLevel]
WHERE  PlayerLevelID NOT IN (0, 4)   -- exclude N/A and Internal
ORDER BY Sort ASC;
```

### 7.2 Count customers by tier (excluding internal)

```sql
SELECT  dpl.Name             AS Tier,
        dpl.Sort,
        COUNT(*)             AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerLevel] dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.PlayerLevelID NOT IN (0, 4)
GROUP BY dpl.Name, dpl.Sort
ORDER BY dpl.Sort;
```

### 7.3 Identify customers in premium tiers (24h cashout)

```sql
SELECT  dc.CID,
        dpl.Name  AS Tier,
        dpl.CashoutPendingHours
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerLevel] dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.CashoutPendingHours = 24   -- Platinum, Platinum Plus, Diamond
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (*****) | Phases: 11/14*
*Tiers: 8 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerLevel | Type: Table | Production Source: etoro.Dictionary.PlayerLevel*

# DWH_dbo.Dim_ActionType

> 45-row static dimension table enumerating all customer action types in the trading platform — covering position opens/closes, deposits, cashouts, bonuses, chargebacks, mirror operations, user engagement, and registration events. Each action type is grouped into a Category with a CategoryID. Loaded daily via Generic Pipeline (Override). Production source unknown (no writer SP, no upstream wiki).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP; loaded via Generic Pipeline from DWH_Migration staging |
| **Refresh** | Daily (1440 min), Override copy strategy |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ActionTypeID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override) |

---

## 1. Business Meaning

Dim_ActionType is a small, static lookup table (45 rows) that defines every type of customer action tracked by the platform's Fact_CustomerAction fact table and related objects. Action types range from trading operations (ManualPositionOpen=1, CopyPositionClose=5) to financial transactions (Deposit=7, Cashout=8, Bonus=9) to social/engagement events (Publish Post=21, Publish Comment=22) to administrative actions (Open CRM Case=31, Customer Registration=41).

Each action type carries a Category (human-readable grouping, 30 distinct values) and CategoryID (integer grouping, 29 distinct values). The Category groups related actions — e.g., ActionTypeIDs 1-3 and 39 all map to Category="PositionOpen" (CategoryID=18), while ActionTypeIDs 4-6, 28, and 40 map to "PositionClose" (CategoryID=17).

Row 0 is the sentinel/unknown row (Name="N/A", Category="N/A", CategoryID=0). ActionTypeID 33 is absent (gap in the sequence).

The table has no writer SP — it is loaded via the Generic Pipeline from a DWH_Migration staging table. Timestamps (UpdateDate, InsertDate) suggest the original data was seeded in July 2013 with row 0 added in February 2014. The table is essentially static; new action types are added rarely.

---

## 2. Business Logic

### 2.1 Action Type Categorization

**What**: Each action type belongs to exactly one category, identified by both a string name (Category) and an integer ID (CategoryID).
**Columns Involved**: ActionTypeID, Name, Category, CategoryID
**Rules**:
- Multiple ActionTypeIDs can share the same Category/CategoryID (e.g., 5 action types map to PositionClose)
- CategoryID values are not sequential — they range from 0 to 28 with gaps
- The N/A sentinel (ActionTypeID=0) has Category="N/A" and CategoryID=0

### 2.2 Trading Action Groups

**What**: Position lifecycle actions are grouped into PositionOpen (CategoryID=18) and PositionClose (CategoryID=17).
**Columns Involved**: ActionTypeID, Category, CategoryID
**Rules**:
- PositionOpen includes Manual (1), Copy (2), CopyPlus (3), and Unknown (39)
- PositionClose includes Manual (4), Copy (5), CopyPlus (6), Detached (28), and Unknown (40)
- These categories are used by SP_Validation_Cycle_Gap_DL_To_Synapse for financial reconciliation (CategoryID=17 triggers NetProfit logic)

### 2.3 Financial Action Groups

**What**: Monetary actions are categorized for cashflow tracking.
**Columns Involved**: ActionTypeID, Category, CategoryID
**Rules**:
- Deposit actions: Deposit (7), Affiliate Deposit (38), InternalDeposit (44) — all CategoryID=8
- Cashout actions: Cashout (8) uses CategoryID=4; Cashout request (10) uses CategoryID=5; Processed Cashout (30) uses CategoryID=19
- InternalWithdraw (45) uses Category="Withdraw" with CategoryID=4 (same as Cashout)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution — the entire 45-row table is copied to every compute node. Ideal for a small dimension used in frequent JOINs. CLUSTERED INDEX on ActionTypeID provides fast point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What category does an action type belong to? | `SELECT * FROM DWH_dbo.Dim_ActionType WHERE ActionTypeID = @id` |
| List all position-open action types | `SELECT * FROM DWH_dbo.Dim_ActionType WHERE Category = 'PositionOpen'` |
| Get all action types in a category group | `SELECT * FROM DWH_dbo.Dim_ActionType WHERE CategoryID = @catId` |
| Full lookup dump | `SELECT * FROM DWH_dbo.Dim_ActionType ORDER BY ActionTypeID` (only 45 rows) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_CustomerAction | `fca.ActionTypeID = dat.ActionTypeID` | Resolve action type name/category for customer action records |
| DWH_dbo.Fact_FirstCustomerAction | `ffca.ActionTypeID = dat.ActionTypeID` | Resolve action type for first-action-per-customer records |
| DWH_dbo.Fact_History_Cost | `fhc.ActionTypeID = dat.ActionTypeID` | Resolve action type for historical cost entries |

### 3.4 Gotchas

- **ActionTypeID=0 is sentinel**: Name="N/A", Category="N/A" — filter or handle explicitly in reports
- **ActionTypeID=33 is missing**: The sequence 0-45 has a gap at 33 — do not assume contiguous IDs
- **Category vs CategoryID is not 1:1**: 30 distinct Category strings map to 29 distinct CategoryIDs — Cashout (8) and InternalWithdraw (45) share CategoryID=4 but have different Category strings ("Cashout" vs "Withdraw")
- **Double spaces in some Name values**: "Unregister  mirror", "Publish  Post", etc. contain double spaces — be careful with string matching
- **Typos in data**: "Recived" (sic) instead of "Received" in WallEngagement entries (IDs 24-26)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP/ETL code |
| Tier 3 | Grounded in DDL + live data, no upstream wiki or SP code available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ActionTypeID | smallint | YES | Primary key identifying a specific customer action type. Integer codes 0-45 (gap at 33) where 0=N/A sentinel. Used as FK in Fact_CustomerAction, Fact_FirstCustomerAction, Fact_History_Cost, and numerous BI_DB/EXW/eMoney reporting SPs. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 2 | Name | varchar(100) | YES | Human-readable name of the action type. Values include ManualPositionOpen, CopyPositionClose, Deposit, Cashout, Bonus, Chargeback, LoggedIn, Customer Registration, etc. (45 distinct values). (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 3 | UpdateDate | datetime | YES | Timestamp of the last update to this action type row. Most rows show 2013-07-17 (original seed); row 0 shows 2014-02-24. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 4 | InsertDate | datetime | YES | Timestamp when this action type row was first inserted. Same pattern as UpdateDate — bulk seeded 2013-07-17, sentinel added 2014-02-24. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 5 | Category | varchar(50) | YES | Category grouping for the action type. 30 distinct values: PositionOpen, PositionClose, Deposit, Cashout, Bonus, Chargeback, UserEngagement, WallEngagement, DetachPosition, etc. Multiple ActionTypeIDs can share one Category. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 6 | CategoryID | int | YES | Integer code grouping multiple action types into business categories (values 0–28). Used in SP_Validation_Cycle_Gap_DL_To_Synapse MINO filter: CategoryID IN (2,4,6,7,8,12,17,20,21,19) — note that 23 (Reverse cashout) is commented out in the current SP code. |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| ActionTypeID | Unknown (external) | — | Direct load via Generic Pipeline |
| Name | Unknown (external) | — | Direct load via Generic Pipeline |
| UpdateDate | Unknown (external) | — | Direct load via Generic Pipeline |
| InsertDate | Unknown (external) | — | Direct load via Generic Pipeline |
| Category | Unknown (external) | — | Direct load via Generic Pipeline |
| CategoryID | Unknown (external) | — | Direct load via Generic Pipeline |

### 5.2 ETL Pipeline

```
Unknown production source (trading platform lookup table)
  |-- Generic Pipeline (Bronze export, parquet) ---|
  v
DWH_Migration.Dim_ActionType (staging, varchar types, ROUND_ROBIN)
  |-- Generic Pipeline (type cast + Override load) ---|
  v
DWH_dbo.Dim_ActionType (45 rows, REPLICATE)
  |-- Generic Pipeline (Override, delta, daily) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None — Dim_ActionType is a root dimension with no outgoing FKs.

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ActionTypeID | DWH_dbo.Fact_CustomerAction | FK lookup for action type on customer action records |
| ActionTypeID | DWH_dbo.Fact_FirstCustomerAction | FK lookup for first customer action |
| ActionTypeID | DWH_dbo.Fact_History_Cost | FK lookup for historical cost action type |
| CategoryID | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse | Used for financial reconciliation category filtering |
| ActionTypeID | BI_DB_dbo.SP_DDR_Fact_Revenue_Generating_Actions | Revenue action classification |
| ActionTypeID | BI_DB_dbo.SP_DDR_Fact_Non_Revenue_Generating_Actions | Non-revenue action classification |
| ActionTypeID | BI_DB_dbo.SP_Client_Balance_New | Client balance computation |
| ActionTypeID | EXW_dbo.SP_EXW_C2F_E2E | Customer-to-fund end-to-end reporting |

---

## 7. Sample Queries

### 7.1 List All Action Types with Categories

```sql
SELECT ActionTypeID, Name, Category, CategoryID
FROM DWH_dbo.Dim_ActionType
ORDER BY ActionTypeID;
```

### 7.2 Find All Position-Related Action Types

```sql
SELECT ActionTypeID, Name, Category
FROM DWH_dbo.Dim_ActionType
WHERE Category IN ('PositionOpen', 'PositionClose')
ORDER BY Category, ActionTypeID;
```

### 7.3 Count Customer Actions by Category

```sql
SELECT dat.Category, dat.CategoryID, COUNT(*) AS action_count
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_ActionType dat ON fca.ActionTypeID = dat.ActionTypeID
WHERE fca.DateID >= 20260101
GROUP BY dat.Category, dat.CategoryID
ORDER BY action_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (regen harness mode — Jira scan skipped).

---

*Generated: 2026-04-28 | Quality: 7.5/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 6 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 7/10, Lineage: 6/10*
*Object: DWH_dbo.Dim_ActionType | Type: Table | Production Source: Unknown (dormant/external)*

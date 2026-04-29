# DWH_dbo.Dim_ActionType

> DWH-specific financial customer action type dimension with 45 entries classifying every monetary and platform event in Fact_CustomerAction into named types and business categories.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Legacy DWH SQL Server (DWH_Migration.Dim_ActionType) |
| **Refresh** | Occasional manual inserts (no active ETL SP; 2 rows added 2024-04-03) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ActionTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

DWH_dbo.Dim_ActionType is the master lookup for all customer financial and platform action types recorded in Fact_CustomerAction. It defines 45 distinct action types across 29 business categories covering position trading (open/close), deposits, withdrawals, bonuses, chargebacks, mirror/copy-trade operations, engagement events, and administrative actions.

This table originates from the legacy DWH SQL Server (migrated via DWH_Migration.Dim_ActionType) and is NOT sourced from the production etoro.Dictionary.ActionType — which is a separate, smaller table covering only session and registration events. The DWH version was created specifically to classify the rich set of financial customer actions tracked in the Fact_CustomerAction fact table.

New action types are added infrequently (45 rows since initial 2013 migration; 2 new types added in 2024). The table is effectively stable — changes require a coordinated insert across the legacy origin and DWH. The `UpdateDate` and `InsertDate` columns carry production timestamps from the legacy system, not ETL load timestamps.

---

## 2. Business Logic

### 2.1 Category Grouping

**What**: Each action type belongs to a business category that groups related types for financial and operational analytics.

**Columns Involved**: `ActionTypeID`, `Name`, `Category`, `CategoryID`

**Rules**:
- `CategoryID` is a business grouping code; `Category` is its text label
- Multiple ActionTypeIDs share the same CategoryID (many-to-one)
- CategoryID 0 / Category "N/A" = placeholder for unknown or inapplicable types
- Key financial categories: 8=Deposit, 4=Cashout/Withdraw, 17=PositionClose, 18=PositionOpen, 23=Reverse cashout, 28=Reverse Deposit, 20=Refund, 6=Chargeback
- SP_Validation_Cycle_Gap filters CategoryID IN (2,4,6,7,8,12,17,19,20,21,23) for "MINO movements" — money-in/money-out events

**Diagram**:
```
ActionTypeID -> Name -> CategoryID -> Category
    1          ManualPositionOpen    18   PositionOpen
    2          CopyPositionOpen      18   PositionOpen
    3          CopyPlusPositionOpen  18   PositionOpen
   39          PositionOpenTypeUnknown 18 PositionOpen
    4          ManualPositionClose   17   PositionClose
    5          CopyPositionClose     17   PositionClose
    6          CopyPlusPositionClose 17   PositionClose
   28          DetachedPositionClose 17   PositionClose
   40          PositionCloseTypeUnknown 17 PositionClose
    7          Deposit               8    Deposit
   38          Affiliate Deposit     8    Deposit
   44          InternalDeposit       8    Deposit
    8          Cashout               4    Cashout
   45          InternalWithdraw      4    Withdraw  [note: Category="Withdraw", CategoryID=4]
   43          Reverse Deposit       28   Reverse Deposit
   37          Reverse cashout       23   Reverse cashout
   12          Refund                20   Refund
   13          Refund As ChargeBack  21   Refund As ChargeBack
   11          Chargeback            6    Chargeback
   42          Cashout Rollback      6    Chargeback
    9          Bonus                 2    Bonus
   36          Compensation          7    Compensation
```

### 2.2 N/A Placeholder Row

**What**: The ActionTypeID=0 row serves as a JOIN-safe default for facts with unknown or inapplicable action types.

**Columns Involved**: `ActionTypeID`, `Name`, `Category`, `CategoryID`

**Rules**:
- ActionTypeID=0, Name="N/A", Category="N/A", CategoryID=0
- Inserted 2014-02-24 as the null-safe join target
- When Fact_CustomerAction has an unrecognized or null action type, it joins to ID=0

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `ActionTypeID ASC`. REPLICATE means a full copy exists on every compute node — ideal for small lookup tables like this (45 rows). JOINs from Fact_CustomerAction on `ActionTypeID` are fully local with zero data movement. No performance concern for any join pattern.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table will be stored as Delta (MANAGED) with no partitioning (45 rows). Direct full scan is always optimal at this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode ActionTypeID in Fact_CustomerAction | JOIN DWH_dbo.Dim_ActionType ON ActionTypeID for Name and Category |
| Filter for all deposit events | WHERE CategoryID = 8 (covers Deposit, Affiliate Deposit, InternalDeposit) |
| Filter for all position open events | WHERE CategoryID = 18 |
| Filter MINO movements (money in/out) | WHERE CategoryID IN (2,4,6,7,8,12,17,19,20,21,23) |
| Get all types in a category | SELECT * FROM Dim_ActionType WHERE CategoryID = @CategoryID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_CustomerAction | ON a.ActionTypeID = d.ActionTypeID | Decode action type for customer ledger events |

### 3.4 Gotchas

- **NOT the same as etoro.Dictionary.ActionType**: The production `Dictionary.ActionType` table (16 rows, session/registration events) is a completely different dimension. DWH_dbo.Dim_ActionType is a DWH-specific financial events table from the legacy DWH.
- **Category vs CategoryID inconsistency**: ActionTypeID=45 (InternalWithdraw) has CategoryID=4 but Category="Withdraw" instead of "Cashout". Filter by CategoryID (integer), not Category (string), for reliable grouping.
- **No NOT NULL constraints**: All 6 columns are nullable despite containing no NULLs in practice. Do not rely on NULLability for business logic.
- **UpdateDate = InsertDate**: Both columns carry the original production timestamp from the legacy DWH SQL Server, not ETL load times. They cannot be used to detect ETL refresh.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Description |
|-------|------|-----|-------------|
| **5 stars** | Tier 5 | `(Tier 5 - domain expert)` | Domain expert confirmed |
| **4 stars** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Upstream production wiki verbatim |
| **3 stars** | Tier 2 | `(Tier 2 - ...)` | Synapse SP code or migration DDL |
| **2 stars** | Tier 3 | `(Tier 3 - ...)` | Live data sampling or DDL structure |
| **1 star** | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ActionTypeID | smallint | YES | Primary key. Integer identifier for the customer action type. Values 1-45 active; 0 = N/A placeholder. Referenced by Fact_CustomerAction.ActionTypeID. DWH note: smallint in DWH vs int in legacy DWH_Migration DDL (type narrowed during migration). (Tier 2 - DWH_Migration.Dim_ActionType) |
| 2 | Name | varchar(100) | YES | Human-readable name of the action type. Key values: 1=ManualPositionOpen, 2=CopyPositionOpen, 3=CopyPlusPositionOpen, 4=ManualPositionClose, 5=CopyPositionClose, 6=CopyPlusPositionClose, 7=Deposit, 8=Cashout, 9=Bonus, 10=Cashout request, 11=Chargeback, 12=Refund, 13=Refund As ChargeBack, 14=LoggedIn, 15=Account balance to mirror, 16=Mirror balance to account, 17=Register new mirror, 18=Unregister mirror, 19=Detach position from mirror, 20=Detach Stock From Mirror, 21=Publish Post, 22=Publish Comment, 23=Publish Like, 24=Recived Post On Wall, 25=Recived Comment On Wall, 26=Recived Like On Wall, 27=DepositAttempt, 28=DetachedPositionClose, 29=Cashier Loggin, 30=Processed Cashout, 31=Open CRM Case, 32=Edit StopLoss, 34=Open Stock Order, 35=End Of The Week Fee, 36=Compensation, 37=Reverse cashout, 38=Affiliate Deposit, 39=PositionOpenTypeUnknown, 40=PositionCloseTypeUnknown, 41=Customer Registration, 42=Cashout Rollback, 43=Reverse Deposit, 44=InternalDeposit, 45=InternalWithdraw. (Tier 3 - live data, DWH_dbo.Dim_ActionType) |
| 3 | UpdateDate | datetime | YES | Production UpdateDate from legacy DWH SQL Server - passthrough, not ETL load time. Represents when the action type was last updated in the source system. Most rows = 2013-07-17 (initial migration); newer rows reflect when they were added. (Tier 2 - DWH_Migration.Dim_ActionType) |
| 4 | InsertDate | datetime | YES | Production InsertDate from legacy DWH SQL Server - passthrough, not ETL load time. Represents when the action type was first inserted in the source system. Equals UpdateDate for most rows. (Tier 2 - DWH_Migration.Dim_ActionType) |
| 5 | Category | varchar(50) | YES | Business category text label for grouping action types. Values: N/A, Account balance to mirror, Bonus, Cashier Loggin, Cashout, Chargeback, Compensation, Deposit, DepositAttempt, DetachPosition, Edit StopLoss, End Of The Week Fee, LoggedIn, Mirror balance to account, Open CRM Case, Open Stock Order, PositionClose, PositionOpen, Processed Cashout, Refund, Refund As ChargeBack, Register new mirror, Reverse cashout, Unregister mirror, UserEngagement, WallEngagement, Customer Registration, Reverse Deposit, Withdraw. DWH note: Use CategoryID (integer) for filtering - more reliable than Category string (see Gotchas). (Tier 3 - live data, DWH_dbo.Dim_ActionType) |
| 6 | CategoryID | int | YES | Business category integer code grouping multiple action types. Values: 0=N/A, 1=Account balance to mirror, 2=Bonus, 3=Cashier Loggin, 4=Cashout/Withdraw, 5=Cashout request, 6=Chargeback, 7=Compensation, 8=Deposit, 9=DepositAttempt, 10=DetachPosition, 11=Edit StopLoss, 12=End Of The Week Fee, 13=LoggedIn, 14=Mirror balance to account, 15=Open CRM Case, 16=Open Stock Order, 17=PositionClose, 18=PositionOpen, 19=Processed Cashout, 20=Refund, 21=Refund As ChargeBack, 22=Register new mirror, 23=Reverse cashout, 24=Unregister mirror, 25=UserEngagement, 26=WallEngagement, 27=Customer Registration, 28=Reverse Deposit. Used in SP_Validation_Cycle_Gap MINO filter: CategoryID IN (2,4,6,7,8,12,17,19,20,21,23). (Tier 3 - live data, DWH_dbo.Dim_ActionType) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ActionTypeID | DWH SQL Server (legacy) via DWH_Migration.Dim_ActionType | ActionTypeID | Cast: varchar(10) -> smallint |
| Name | DWH SQL Server (legacy) via DWH_Migration.Dim_ActionType | Name | varchar(100) passthrough |
| UpdateDate | DWH SQL Server (legacy) via DWH_Migration.Dim_ActionType | Updatedate | varchar(50) -> datetime in ETL |
| InsertDate | DWH SQL Server (legacy) via DWH_Migration.Dim_ActionType | InsertDate | varchar(50) -> datetime in ETL |
| Category | DWH SQL Server (legacy) — DWH-specific grouping column | Category | varchar(50) passthrough |
| CategoryID | DWH SQL Server (legacy) — DWH-specific grouping code | CategoryID | int passthrough |

Note: etoro.Dictionary.ActionType (production) is a DIFFERENT table (session/registration events). The DWH dimension is a legacy financial action type classification not present in current production systems.

### 5.2 ETL Pipeline

```
Legacy DWH SQL Server (DWH_Migration.Dim_ActionType)
  -> One-time migration (2013-09-16 via NoDbObjectsScripts)
  -> DWH_dbo.Dim_ActionType
  -> Manual inserts for new types (no automated ETL SP)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Legacy DWH SQL Server | DWH-specific financial action type dimension |
| Migration | DWH_Migration.Dim_ActionType | NoDbObjectsScripts/2024_09_16_17_31_03 staging DDL |
| Target | DWH_dbo.Dim_ActionType | Current DWH dimension (REPLICATE, 45 rows) |
| Ongoing | Manual inserts only | No automated ETL SP identified in SSDT repo |

---

## 6. Relationships

### 6.1 References To (this object points to)

No foreign key references - this is a leaf dimension with no DWH dependencies.

| Element | Related Object | Description |
|---------|---------------|-------------|
| (none) | - | - |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_CustomerAction | ActionTypeID | Primary fact table: every customer ledger event references this dimension |
| DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse | CategoryID | Validation SP: filters MINO movements using CategoryID IN (2,4,6,7,8,12,17,19,20,21,23) |

---

## 7. Sample Queries

### 7.1 Decode action types in Fact_CustomerAction
```sql
SELECT
    fca.CID,
    fca.DateID,
    fca.Amount,
    dat.Name AS ActionTypeName,
    dat.Category,
    dat.CategoryID
FROM [DWH_dbo].[Fact_CustomerAction] fca
JOIN [DWH_dbo].[Dim_ActionType] dat ON fca.ActionTypeID = dat.ActionTypeID
WHERE fca.DateID = '20240101'
ORDER BY fca.CID, fca.DateID;
```

### 7.2 Summarize customer deposits by action type
```sql
SELECT
    dat.Name AS ActionTypeName,
    COUNT(*) AS EventCount,
    SUM(fca.Amount) AS TotalAmount
FROM [DWH_dbo].[Fact_CustomerAction] fca
JOIN [DWH_dbo].[Dim_ActionType] dat ON fca.ActionTypeID = dat.ActionTypeID
WHERE dat.CategoryID = 8  -- Deposit category
GROUP BY dat.Name
ORDER BY TotalAmount DESC;
```

### 7.3 List all action types by business category
```sql
SELECT
    dat.CategoryID,
    dat.Category,
    dat.ActionTypeID,
    dat.Name,
    dat.InsertDate
FROM [DWH_dbo].[Dim_ActionType] dat
WHERE dat.ActionTypeID > 0  -- exclude N/A placeholder
ORDER BY dat.CategoryID, dat.ActionTypeID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP unavailable this session.)

---

*Generated: 2026-03-18 | Quality: 7.7/10 (★★★★☆) | Phases: 11/14*
*Tiers: 0 T1, 3 T2, 3 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Dim_ActionType | Type: Table | Production Source: Legacy DWH SQL Server (DWH_Migration.Dim_ActionType)*

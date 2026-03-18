# DWH_dbo.Dim_ActionType

> Lookup table classifying all customer activity types tracked in Fact_CustomerAction — trades, deposits, cashouts, social interactions, and copy-trade operations.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Legacy DWH SQL Server (via DWH_Migration, Sept 2024) |
| **Refresh** | None — frozen since migration. New rows added manually as needed. |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ActionTypeID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dim_ActionType classifies every customer activity event tracked by the DWH. Each row represents a type of action that can appear in Fact_CustomerAction — the central fact table recording all customer interactions with the platform: position opens, position closes, deposits, cashouts, bonuses, chargebacks, compensations, logins, social posts, copy-trade operations, and more.

This is a DWH-internal dictionary that originated from the legacy on-premises DWH SQL Server. It was migrated to Synapse via `DWH_Migration.Dim_ActionType` in September 2024. It is NOT sourced from production `Dictionary.ActionType` (which is a completely different table tracking registrations and game sessions from the platform's early social gaming era). The DWH Dim_ActionType includes Category and CategoryID columns that group the 45 action types into logical families (PositionOpen, PositionClose, Deposit, Cashout, etc.).

There is no active ETL for this table. The original timestamps (2013-2024) are preserved from the legacy DWH. New action types are added manually as the business introduces them — most recently InternalDeposit and InternalWithdraw in April 2024. The table is referenced by 10+ SPs across DWH_dbo, BI_DB_dbo, EXW_dbo, and eMoney_dbo for revenue reporting, AML monitoring, and compliance analytics.

---

## 2. Business Logic

### 2.1 Action Type Categories

**What**: Action types are grouped into categories that define the nature of the customer activity.

**Columns Involved**: `ActionTypeID`, `Name`, `Category`, `CategoryID`

**Rules**:
- **Position Opens** (CategoryID=18): ManualPositionOpen (1), CopyPositionOpen (2), CopyPlusPositionOpen (3), PositionOpenTypeUnknown (39)
- **Position Closes** (CategoryID=17): ManualPositionClose (4), CopyPositionClose (5), CopyPlusPositionClose (6), DetachedPositionClose (28), PositionCloseTypeUnknown (40)
- **Deposits** (CategoryID=8): Deposit (7), Affiliate Deposit (38), InternalDeposit (44)
- **Cashouts** (CategoryID=4/5/19): Cashout (8), Cashout request (10), Processed Cashout (30), InternalWithdraw (45)
- **Financial adjustments**: Bonus (9, CategoryID=2), Chargeback (11, CategoryID=6), Refund (12, CategoryID=20), Refund As ChargeBack (13, CategoryID=21), Compensation (36, CategoryID=7), Reverse cashout (37, CategoryID=23), Cashout Rollback (42, CategoryID=6), Reverse Deposit (43, CategoryID=28)
- **Copy-trade operations**: Account balance to mirror (15, CategoryID=1), Mirror balance to account (16, CategoryID=14), Register new mirror (17, CategoryID=22), Unregister mirror (18, CategoryID=24), Detach position from mirror (19, CategoryID=10), Detach Stock From Mirror (20, CategoryID=10)
- **Social engagement**: Publish Post (21), Publish Comment (22), Publish Like (23) — all CategoryID=25 (UserEngagement); Received Post/Comment/Like On Wall (24-26) — all CategoryID=26 (WallEngagement)
- **Session/Registration**: LoggedIn (14, CategoryID=13), Customer Registration (41, CategoryID=27)
- **Fees**: End Of The Week Fee (35, CategoryID=12), Edit StopLoss (32, CategoryID=11), Open Stock Order (34, CategoryID=16)
- **Other**: DepositAttempt (27, CategoryID=9), Cashier Loggin (29, CategoryID=3), Open CRM Case (31, CategoryID=15)

**Diagram**:
```
Dim_ActionType (45 action types, 28 categories)
├── Financial Actions
│   ├── Deposit (7, 38, 44)
│   ├── Cashout (8, 10, 30, 45)
│   ├── Bonus (9)
│   ├── Chargeback (11, 42)
│   ├── Refund (12, 13)
│   ├── Compensation (36)
│   ├── Reverse (37, 43)
│   └── Fees (32, 34, 35)
├── Trading Actions
│   ├── PositionOpen (1, 2, 3, 39)
│   └── PositionClose (4, 5, 6, 28, 40)
├── Copy-Trade Operations
│   ├── Mirror management (15, 16, 17, 18)
│   └── Position detach (19, 20)
├── Social Engagement
│   ├── UserEngagement (21, 22, 23)
│   └── WallEngagement (24, 25, 26)
└── Other
    ├── Login (14)
    ├── Registration (41)
    ├── DepositAttempt (27)
    ├── CashierLoggin (29)
    └── OpenCRMCase (31)
```

### 2.2 Copy-Trade Position Type Identification

**What**: Action type distinguishes between manual, copy-trade, and detached positions.

**Columns Involved**: `ActionTypeID`

**Rules**:
- ActionTypeID IN (1, 4) → Manual trades (user-initiated)
- ActionTypeID IN (2, 5) → Copy trades (opened/closed by copy-trade engine)
- ActionTypeID IN (3, 6) → CopyPlus trades (legacy variant)
- ActionTypeID = 28 → Detached position close (position was detached from mirror before closing)
- ActionTypeID IN (39, 40) → Unknown type (legacy data where open/close type was not recorded)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on ActionTypeID. As a replicated table with 45 rows, it is cached on every compute node — JOINs are always local and fast. The clustered index provides direct lookup by ActionTypeID.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All deposits for a customer | `WHERE ActionTypeID IN (7, 38, 44)` or `WHERE Category = 'Deposit'` |
| All position opens | `WHERE CategoryID = 18` |
| All position closes | `WHERE CategoryID = 17` |
| Revenue-generating actions | `WHERE ActionTypeID IN (1,2,3,4,5,6,7,8,35)` (per BI_DB SPs) |
| Logins only | `WHERE ActionTypeID = 14` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_CustomerAction | ON FCA.ActionTypeID = Dim_ActionType.ActionTypeID | Resolve action type name and category for customer events |
| DWH_dbo.Fact_FirstCustomerAction | ON FFCA.ActionTypeID = Dim_ActionType.ActionTypeID | Resolve action type for first-action tracking |

### 3.4 Gotchas

- **NOT production Dictionary.ActionType**: The production `Dictionary.ActionType` tracks registrations and game sessions (16 rows). This DWH table tracks trading/financial actions (45 rows). They are completely different tables with no shared rows.
- **Frozen data with manual updates**: No active ETL. Original timestamps from 2013-2024 are preserved. New rows (like InternalDeposit=44 from April 2024) are inserted manually.
- **CategoryID is self-contained**: Category and CategoryID are columns within THIS table, not FK references to another table. No separate "Dim_Category" exists.
- **ID=0 is "N/A"**: Placeholder for unclassified actions.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★ (3) | Tier 2b | DWH_Migration DDL — verified from migration script |
| ★★ (2) | Tier 3 | Live data sampling — observed from actual Synapse data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ActionTypeID | smallint | YES | Identifier for the customer action type. 45 distinct values (0-45 with gaps at 33). Used as JOIN key to Fact_CustomerAction. 0=N/A placeholder. See full value map in Section 2.1. (Tier 3 — live data sampling) |
| 2 | Name | varchar(100) | YES | Human-readable name of the action type. E.g., "ManualPositionOpen", "Deposit", "CopyPositionClose". Used in BI reports and compliance analytics. (Tier 3 — live data sampling) |
| 3 | UpdateDate | datetime | YES | Original timestamp from the legacy DWH SQL Server. Represents when this action type was last modified in the old system. NOT set by GETDATE() — preserved historical values spanning 2013-2024. (Tier 2b — DWH_Migration DDL) |
| 4 | InsertDate | datetime | YES | Original timestamp from the legacy DWH SQL Server. Represents when this action type was first inserted in the old system. NOT set by GETDATE() — preserved historical values. (Tier 2b — DWH_Migration DDL) |
| 5 | Category | varchar(50) | YES | Logical grouping of action types. E.g., "PositionOpen" (IDs 1,2,3,39), "Deposit" (IDs 7,38,44), "Cashout" (IDs 8,45). Used by BI SPs to aggregate actions into business-meaningful groups. 28 distinct categories. (Tier 3 — live data sampling) |
| 6 | CategoryID | int | YES | Numeric identifier for the Category grouping. Self-contained within this table — not an FK to another table. Used by SPs that filter by category numerically rather than by string. (Tier 3 — live data sampling) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ActionTypeID | Legacy DWH SQL Server | ActionTypeID | Migrated via DWH_Migration (Sept 2024). Type narrowed from varchar(10) to smallint. |
| Name | Legacy DWH SQL Server | Name | Passthrough |
| UpdateDate | Legacy DWH SQL Server | Updatedate | Migrated. Type changed from varchar(50) to datetime. |
| InsertDate | Legacy DWH SQL Server | InsertDate | Migrated. Type changed from varchar(50) to datetime. |
| Category | Legacy DWH SQL Server | Category | Passthrough |
| CategoryID | Legacy DWH SQL Server | CategoryID | Passthrough |

**Note**: This table is NOT sourced from production `etoro.Dictionary.ActionType`. The production table tracks registrations and game sessions (16 rows) and has no Category/CategoryID columns. The DWH version tracks trading/financial actions (45 rows) and originated from the legacy on-premises DWH.

### 5.2 ETL Pipeline

```
Legacy DWH SQL Server → One-time migration → DWH_Migration.Dim_ActionType → Manual copy → DWH_dbo.Dim_ActionType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Legacy DWH SQL Server | On-premises DWH action type dictionary |
| Migration | DWH_Migration.Dim_ActionType | Migration staging table (Sept 2024) |
| Target | DWH_dbo.Dim_ActionType | Final DWH dimension table. No active ETL. |

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_CustomerAction | ActionTypeID | Central fact table — classifies every customer action event |
| DWH_dbo.Fact_FirstCustomerAction | ActionTypeID | First occurrence of each action type per customer |
| BI_DB_dbo.SP_DDR_Fact_Revenue_Generating_Actions | ActionTypeID | Revenue-generating action classification for DDR reporting |
| BI_DB_dbo.SP_DDR_Fact_Non_Revenue_Generating_Actions | ActionTypeID | Non-revenue action classification for DDR reporting |
| BI_DB_dbo.SP_Client_Balance_New | ActionTypeID | Client balance computation filters by action type |
| BI_DB_dbo.SP_BI_AMLPeriodicReview | ActionTypeID | AML periodic review filters on action types |
| BI_DB_dbo.SP_Compensation_Activity_Data | ActionTypeID | Compensation activity reporting |
| BI_DB_dbo.SP_CID_DailyPanel_FullData | ActionTypeID | Daily customer panel data includes action type |
| EXW_dbo.SP_EXW_C2F_E2E | ActionTypeID | eToroX wallet-to-fund flow classification |
| eMoney_dbo.SP_eMoney_Daily_MIMO | ActionTypeID | eMoney daily money-in/money-out classification |
| DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse | ActionTypeID | Validation cycle gap analysis |

---

## 7. Sample Queries

### 7.1 List all action types with categories
```sql
SELECT  ActionTypeID,
        Name,
        Category,
        CategoryID
FROM    [DWH_dbo].[Dim_ActionType]
WHERE   ActionTypeID > 0
ORDER BY CategoryID, ActionTypeID;
```

### 7.2 Count customer actions by category
```sql
SELECT  dat.Category,
        COUNT(*) AS ActionCount
FROM    [DWH_dbo].[Fact_CustomerAction] fca
JOIN    [DWH_dbo].[Dim_ActionType] dat
        ON fca.ActionTypeID = dat.ActionTypeID
GROUP BY dat.Category
ORDER BY ActionCount DESC;
```

### 7.3 Find all deposit-type actions for a customer
```sql
SELECT  fca.*,
        dat.Name AS ActionTypeName,
        dat.Category
FROM    [DWH_dbo].[Fact_CustomerAction] fca
JOIN    [DWH_dbo].[Dim_ActionType] dat
        ON fca.ActionTypeID = dat.ActionTypeID
WHERE   dat.Category = 'Deposit'
        AND fca.CID = @CID
ORDER BY fca.ActionDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found specific to DWH_dbo.Dim_ActionType. This is a DWH-internal dictionary migrated from the legacy system. Business meaning derived from live data and consumer SP analysis.

---

*Generated: 2026-03-18 | Quality: 7.9/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 2 T2b, 4 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10*
*Object: DWH_dbo.Dim_ActionType | Type: Table | Production Source: Legacy DWH SQL Server (DWH_Migration)*

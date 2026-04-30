# Trade.CIDsInLiquidation

> Registry of customer accounts (CIDs) currently in liquidation; records whether each liquidation was triggered manually (BackOffice) or automatically (BSL).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID |
| **Partition** | No |
| **Indexes** | 1 (PK) |

---

## 1. Business Meaning

**WHAT:** Trade.CIDsInLiquidation is a small lookup table that holds the set of customer IDs (CIDs) whose accounts are currently being liquidated. Each row represents one customer in liquidation, with a timestamp and the type of liquidation trigger (Manual or BSL). When a liquidation completes, the row is removed and archived to History.CIDsInLiquidation.

**WHY:** The platform needs a fast way to check whether a customer is in liquidation. Procedures like Trade.InsertBSLMessagesIntoQueue and Trade.SendUnBlockMessage use this table to exclude or handle CIDs in liquidation differently. The liquidation workflow (GetAccountAssetsForLiquidation, GetCIDAccountAssetsForLiquidation, GetAllAccountAssetsForLiquidation) operates on CIDs that are in this table.

**HOW:** Trade.CIDsInLiquidationAdd inserts a row when liquidation starts; Trade.CIDsInLiquidationRemove deletes the row, fixes balance data via Customer.SetBalanceDataFix, and archives to History.CIDsInLiquidation. Trade.IsCIDInLiquidation performs an EXISTS check. The AccountLiquidationAcionTypeID (note typo in column name) references Dictionary.AccountLiquidationActionType: 1=Manual (BackOffice triggered), 2=BSL (Business Safety Layer automated).

---

## 2. Business Logic

### 2.1 Add and Remove Lifecycle

When liquidation is initiated, Trade.CIDsInLiquidationAdd is called with @CID and @LiquidationActionTypeID. It inserts a row with StartTime=GETUTCDATE() and AccountLiquidationAcionTypeID. When liquidation completes, Trade.CIDsInLiquidationRemove runs: it reads Customer.CustomerMoney (Credit, RealizedEquity, TotalCash, BonusCredit), calls Customer.SetBalanceDataFix to restore balances, deletes from Trade.CIDsInLiquidation, and OUTPUTs into History.CIDsInLiquidation.

### 2.2 Liquidation Type (AccountLiquidationActionType)

AccountLiquidationActionTypeID 1 = Manual: triggered by BackOffice staff for compliance, regulatory, or dispute actions. AccountLiquidationActionTypeID 2 = BSL: triggered automatically by the Business Safety Layer when risk thresholds (margin call, negative balance) are breached. The FK ensures only valid types are stored.

### 2.3 Exclusion and Workflow Usage

Trade.InsertBSLMessagesIntoQueue and Trade.SendUnBlockMessage LEFT JOIN Trade.CIDsInLiquidation to exclude or flag CIDs in liquidation. The Get*AccountAssetsForLiquidation procedures are used by the liquidation engine to gather positions, orders, and mirrors for CIDs in liquidation.

---

## 3. Data Overview

| CID | StartTime | AccountLiquidationAcionTypeID | Meaning |
|-----|-----------|------------------------------|---------|
| 1 | 2026-01-15 10:00:00 | 1 | Customer in Manual liquidation (BackOffice) |
| 2 | 2026-01-15 10:05:00 | 2 | Customer in BSL liquidation (automated) |
| - | - | - | Table often empty when no liquidations in progress |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Primary key; customer ID from Customer.CustomerStatic. Unique per row. |
| 2 | StartTime | datetime | NO | - | CODE-BACKED | When liquidation was initiated (GETUTCDATE at add). |
| 3 | AccountLiquidationAcionTypeID | int | NO | - | VERIFIED | FK to Dictionary.AccountLiquidationActionType. 1=Manual (BackOffice), 2=BSL (Business Safety Layer). Note: column name has typo "Acion". |

---

## 5. Relationships

### 5.1 References To

| Column | Target | Relationship |
|--------|--------|---------------|
| CID | Customer.CustomerStatic | FK (explicit) |
| AccountLiquidationAcionTypeID | Dictionary.AccountLiquidationActionType | FK (explicit) |

### 5.2 Referenced By

- Trade.CIDsInLiquidationAdd (INSERT)
- Trade.CIDsInLiquidationRemove (DELETE, OUTPUT to History.CIDsInLiquidation)
- Trade.IsCIDInLiquidation (EXISTS check)
- Trade.InsertBSLMessagesIntoQueue (LEFT JOIN to exclude CIDs in liquidation)
- Trade.SendUnBlockMessage (LEFT JOIN)
- Trade.GetAccountAssetsForLiquidation, Trade.GetCIDAccountAssetsForLiquidation, Trade.GetAllAccountAssetsForLiquidation (liquidation workflow - receive CID, used when CID is in this table)

---

## 6. Dependencies

### 6.0 Dependency Chain

CIDsInLiquidation -> Customer.CustomerStatic (CID), Dictionary.AccountLiquidationActionType (AccountLiquidationAcionTypeID). History.CIDsInLiquidation (archive target).

### 6.1 Objects This Depends On

- Customer.CustomerStatic (FK)
- Dictionary.AccountLiquidationActionType (FK)

### 6.2 Objects That Depend On This

- History.CIDsInLiquidation (archive target)
- Trade.CIDsInLiquidationAdd, Trade.CIDsInLiquidationRemove, Trade.IsCIDInLiquidation
- Trade.InsertBSLMessagesIntoQueue, Trade.SendUnBlockMessage

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns | Notes |
|------------|------|---------|-------|
| PK_CIDsInLiquidation | CLUSTERED PK | CID ASC | Primary key; FILLFACTOR 95. |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_CIDsInLiquidation | PRIMARY KEY | CID ASC |
| FK_CIDsInLiquidation_AccountLiquidationActionType | FK | AccountLiquidationAcionTypeID -> Dictionary.AccountLiquidationActionType(ActionTypeID) |
| FK_CIDsInLiquidation_CID | FK | CID -> Customer.CustomerStatic(CID) |

---

## 8. Sample Queries

```sql
SELECT TOP 5 CID, StartTime, AccountLiquidationAcionTypeID
FROM   Trade.CIDsInLiquidation WITH (NOLOCK);
```

```sql
SELECT cil.CID, cil.StartTime, alat.ActionTypeID, alat.Name
FROM   Trade.CIDsInLiquidation cil WITH (NOLOCK)
JOIN   Dictionary.AccountLiquidationActionType alat WITH (NOLOCK)
       ON cil.AccountLiquidationAcionTypeID = alat.ActionTypeID;
```

```sql
SELECT *
FROM   Dictionary.AccountLiquidationActionType WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.5/10 | Sources: DDL, Trade.CIDsInLiquidationAdd/Remove/IsCIDInLiquidation, InsertBSLMessagesIntoQueue, SendUnBlockMessage, Dictionary.AccountLiquidationActionType*

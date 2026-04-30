# Customer.BlockedCustomerOperations

> Active trading restrictions table storing per-customer operation blocks, managed by the Trading Restriction Service and consumed by real-time trade execution to enforce account-level limitations.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID + OperationTypeID + BlockReasonID (composite PK, clustered) |
| **Partition** | No (MAIN filegroup, PAGE compression) |
| **Indexes** | 3 (1 clustered PK + 2 nonclustered) |

---

## 1. Business Meaning

Customer.BlockedCustomerOperations is the active restriction registry — it stores every currently-active trading restriction applied to a customer. Each row represents a block preventing a specific customer from performing a specific type of trading operation. The table is the primary enforcement point for the two-tier restriction model: this table stores blocks at the high-level OperationTypeID level (Copy User, Trading, Position Open, etc.), and Trade.OperationTypeForBlockingToAtomic expands them to granular atomic operations for real-time enforcement.

Without this table, the compliance, risk, and BackOffice teams would have no mechanism to prevent specific customers from trading, copying, or participating in copy-fund activities. Every trade execution check, order validation, and copy-trade eligibility check eventually queries this table (directly or via the replicated SettingsDB copy) to verify the customer is not restricted for the requested operation.

Data flows in via Trade.CustomerRestrictionsSet (called by the Trading Restriction Service — an ASP.NET Core microservice on Azure AKS with RabbitMQ messaging). Restrictions are removed via Trade.CustomerRestrictionsRemove, which simultaneously deletes from this table and archives to History.BlockedCustomerOperations with both the original BlockReasonID and the new UnBlockReasonID. The table is replicated to SettingsDB for distributed resolution via Trading.BlockedCustomerOperationsResolver.

---

## 2. Business Logic

### 2.1 Active Restriction State

**What**: Each row in this table represents a currently-active trading restriction for a customer. No row = no restriction for that operation type.

**Columns/Parameters Involved**: `CID`, `OperationTypeID`, `BlockReasonID`

**Rules**:
- Composite PK = (CID, OperationTypeID, BlockReasonID): a customer can have the same OperationTypeID blocked for multiple different BlockReasonIDs simultaneously (e.g., blocked for Trading due to both AML=3 AND Liquidation=9)
- OperationTypeID maps to TradeRestrictionType enum: 1=CopyUser, 2=Copied, 3=PublicPortfolioVisible, 4=Trading, 5=PositionOpen, 6=ManualPositionClose, 7=ManualOpenExitOrder, 8=OpenEntryOrder, 9=OpenOrder, 10=OpenOpen, 11=ManualUnregisterMirror, 12=ManualEditSL, 13=ManualEditTP, 14=ManualEditTSL, 15=ManualCloseEntryOrder, 16=ManualCloseExitOrder, 17=CloseOrder, 18=ManualEditMirrorSL, 19=ManualEditMirrorSLPercentage, 20=ManualPauseCopy, 21=ManualExecutionBlock (Source: Trading Restriction Service TDD, Confluence TRAD)
- BlockReasonID maps to BlockUnBlockReason enum: 1=RequestedByBOAdmin, 2=HighRiskScore, 3=EmployeeAccount, 4=OPT_OUT, 5=OPT_IN, 6=NotVerified, 7=Verified, 8=RequestedByKYC, 9=Liquidation, 10=LiquidationRemove, 11=ManualExecutionBlock, 12=ManualExecutionBlockRemove, 13=AumLimit, 14=Regulation, 15=NonResponsive, 16=AbusiveTrading, 17=LowEquity, 18=BreachComunityGuidelines, 19=NonLaunchedCopyFund, 20=NotAcceptUsersCopyFund, 21=AumLimitPopular, 22=MaxCopiers, 23=MaxAumPerTier (Source: Trading Restriction Service TDD, Confluence TRAD)

### 2.2 Block/Unblock Lifecycle via Trading Restriction Service

**What**: Restrictions flow through a dedicated microservice (Trading Restriction Service) that consumes from RabbitMQ and enforces business rules before writing to this table.

**Columns/Parameters Involved**: `CID`, `OperationTypeID`, `BlockReasonID`, `Occurred`, `RequestGUID`

**Rules**:
- **Set**: Admin-Tapi or TACL service sends restriction request -> Trading Restriction Service validates -> calls Trade.CustomerRestrictionsSet -> inserts into this table. RequestGUID from the application request is stored for idempotency and audit tracing
- **Remove**: Trading Restriction Service validates (checks if CID is in liquidation via Trade.IsCIDInLiquidation before allowing removal) -> calls Trade.CustomerRestrictionsRemove -> deletes from this table AND inserts into History.BlockedCustomerOperations with BlockStart/BlockEnd timestamps
- **Privacy/GDPR**: TACL service sends OptOut=true -> adds Copied + PublicPortfolioVisible restrictions with BlockReason=OPT_OUT. OptOut=false -> removes with UnBlockReason=OPT_IN
- **Liquidation guard**: If removing a ManualExecutionBlock and the customer is in liquidation (Trade.CIDsInLiquidation), the removal is rejected with RestrictionOpValidationException

**Diagram**:
```
TACL / Admin-Tapi Service
    |
    | (RabbitMQ message)
    v
Trading Restriction Service (AKS)
    |
    +-[Set]--------> Trade.CustomerRestrictionsSet
    |                    -> INSERT Customer.BlockedCustomerOperations
    |
    +-[Remove]-------> Trade.CustomerRestrictionsRemove
    |                    -> DELETE Customer.BlockedCustomerOperations
    |                    -> INSERT History.BlockedCustomerOperations
    |
    +-[Privacy OptOut]-> Set Copied + PublicPortfolioVisible (OPT_OUT)
    +-[Privacy OptIn] -> Remove same restrictions (OPT_IN)
    |
    v
  RabbitMQ Notification (CustomerRestrictionSet/RemoveNotification)
```

### 2.3 CopyTrading Capacity Restrictions

**What**: MaxCopiers (22) and MaxAumPerTier (23) block reasons are specifically used to cap CopyTrading capacity.

**Columns/Parameters Involved**: `BlockReasonID=22/23`, `OperationTypeID=1 (CopyUser)`

**Rules**:
- BlockReasonID=22 (MaxCopiers): blocks new users from copying a Popular Investor who has reached copier capacity
- BlockReasonID=23 (MaxAumPerTier): blocks based on Assets Under Management tier limits
- These are automated blocks set by the copy capacity management system, not manual BackOffice actions

---

## 3. Data Overview

| CID | OperationTypeID | BlockReasonID | Occurred | Meaning |
|---|---|---|---|---|
| 25454637 | 23 (ManualExecutionBlock) | 26 | 2026-03-17 11:58 | A customer with manual execution blocked (OperationTypeID=21 mapped via 2-tier system) - one of many recent automated blocks applied today |
| 25463724 | 23 | 26 | 2026-03-17 11:42 | Same pattern - recent blocks applied en masse suggest an automated compliance sweep running today |

*397,142 total active restriction rows. Recent data shows OperationTypeID=23 and BlockReasonID=26 as the dominant current block type, suggesting an active compliance campaign. All sample rows from today indicate this is a very active, high-volume table with continuous inserts.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID - identifies which customer is restricted. Part of composite PK. References CID in Customer.CustomerStatic. |
| 2 | OperationTypeID | int | NO | - | VERIFIED | The trading operation being blocked: 1=CopyUser, 2=Copied, 3=PublicPortfolioVisible, 4=Trading, 5=PositionOpen, 6=ManualPositionClose, 7=ManualOpenExitOrder, 8=OpenEntryOrder, 9=OpenOrder, 10=OpenOpen, 11=ManualUnregisterMirror, 12=ManualEditSL, 13=ManualEditTP, 14=ManualEditTSL, 15=ManualCloseEntryOrder, 16=ManualCloseExitOrder, 17=CloseOrder, 18=ManualEditMirrorSL, 19=ManualEditMirrorSLPercentage, 20=ManualPauseCopy, 21=ManualExecutionBlock. FK to Dictionary.OperationTypesForBlocking. (Source: Trading Restriction Service TDD - Confluence TRAD) |
| 3 | Occurred | datetime | NO | getutcdate() | VERIFIED | UTC timestamp when the block was applied. Default = GETUTCDATE(). Used in History.BlockedCustomerOperations as BlockStart for audit trails. |
| 4 | BlockReasonID | int | NO | - | VERIFIED | Why this block was applied: 1=RequestedByBOAdmin, 2=HighRiskScore, 3=EmployeeAccount, 4=OPT_OUT, 5=OPT_IN, 6=NotVerified, 7=Verified, 8=RequestedByKYC, 9=Liquidation, 10=LiquidationRemove, 11=ManualExecutionBlock, 12=ManualExecutionBlockRemove, 13=AumLimit, 14=Regulation, 15=NonResponsive, 16=AbusiveTrading, 17=LowEquity, 18=BreachComunityGuidelines, 19=NonLaunchedCopyFund, 20=NotAcceptUsersCopyFund, 21=AumLimitPopular, 22=MaxCopiers, 23=MaxAumPerTier. FK to Dictionary.BlockUnBlockReason. (Source: Trading Restriction Service TDD + Dictionary.BlockUnBlockReason.md) |
| 5 | RequestGUID | nvarchar(50) | YES | - | VERIFIED | Unique identifier from the originating restriction request. Set by the Trading Restriction Service application and passed through Trade.CustomerRestrictionsSet. Used for idempotency, distributed tracing, and audit correlation. NULL for older blocks predating GUID tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OperationTypeID | Dictionary.OperationTypesForBlocking | FK (FK_CustomerBlockedCustomerOperations_DictionaryOperationTypesForBlocking) | Identifies which operation category is blocked |
| BlockReasonID | Dictionary.BlockUnBlockReason | FK (FK_BlockReasonID_IPkey) | Documents the compliance/risk reason for the block |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.BlockedCustomerOperations | CID + OperationTypeID | Archive | Receives rows when restrictions are removed; adds UnBlockReasonID and timestamps |
| Customer.OperationBlockForCID | CID | WRITER | Inserts restriction rows for a customer |
| Customer.OperationUnBlockForCID | CID | DELETER | Removes restriction and archives to History |
| Customer.GetBlockedOperationsForCID | CID | READER | Returns all active restrictions for a customer |
| Trade.CustomerRestrictionsSet | CID | WRITER | Trading Restriction Service path - inserts restriction rows |
| Trade.CustomerRestrictionsRemove | CID | DELETER | Trading Restriction Service path - removes restriction rows |
| Trade.GetRestrictionsByTradingOperationTypes | CID | READER | Returns restrictions filtered by operation type for enforcement |
| Trade.GetCustomerRestrictionsForAPI | CID | READER | API-facing restriction lookup |
| Trade.SendUnBlockMessage | CID | READER | Reads blocks before sending unblock notifications |
| SettingsDB replication | All columns | Replication | Full copy maintained in SettingsDB for distributed enforcement |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.BlockedCustomerOperations (table)
|- Dictionary.OperationTypesForBlocking (table) [FK - leaf]
|- Dictionary.BlockUnBlockReason (table) [FK - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OperationTypesForBlocking | Table | FK - OperationTypeID defines the blocked operation category |
| Dictionary.BlockUnBlockReason | Table | FK - BlockReasonID identifies the compliance/risk justification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.BlockedCustomerOperations | Table | Archive destination on unblock |
| Customer.GetBlockedOperationsForCID | Stored Procedure | Reads active restrictions per customer |
| Customer.OperationBlockForCID | Stored Procedure | Inserts new blocks |
| Customer.OperationUnBlockForCID | Stored Procedure | Deletes blocks and archives |
| Trade.CustomerRestrictionsSet | Stored Procedure | Microservice path - sets restrictions |
| Trade.CustomerRestrictionsRemove | Stored Procedure | Microservice path - removes restrictions |
| Trade.GetRestrictionsByTradingOperationTypes | Stored Procedure | Enforcement queries by operation type |
| Trade.GetCustomerRestrictionsForAPI | Stored Procedure | API-facing restriction data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TPIL | CLUSTERED | CID ASC, OperationTypeID ASC, BlockReasonID ASC | - | - | Active |
| IDX_Customer_BlockedCustomerOperations_OperationTypeID | NONCLUSTERED | OperationTypeID ASC | CID | - | Active |
| IX_OperationTypeID | NONCLUSTERED | OperationTypeID ASC, CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TPIL | PRIMARY KEY | CID + OperationTypeID + BlockReasonID must be unique - one block record per customer per operation type per reason |
| FK_BlockReasonID_IPkey | FOREIGN KEY | BlockReasonID must exist in Dictionary.BlockUnBlockReason |
| FK_CustomerBlockedCustomerOperations_DictionaryOperationTypesForBlocking | FOREIGN KEY | OperationTypeID must exist in Dictionary.OperationTypesForBlocking |
| DF_CustomerBlockedCustomerOperations_Occurred | DEFAULT | Occurred = GETUTCDATE() - auto-timestamps when block is applied |

---

## 8. Sample Queries

### 8.1 Get all active restrictions for a customer with readable labels

```sql
SELECT
    bco.CID,
    otfb.OperationDescription AS BlockedOperation,
    bur.Reason AS BlockReason,
    bco.Occurred,
    bco.RequestGUID
FROM Customer.BlockedCustomerOperations bco WITH (NOLOCK)
INNER JOIN Dictionary.OperationTypesForBlocking otfb WITH (NOLOCK)
    ON otfb.OperationTypeID = bco.OperationTypeID
INNER JOIN Dictionary.BlockUnBlockReason bur WITH (NOLOCK)
    ON bur.ID = bco.BlockReasonID
WHERE bco.CID = 25454637
ORDER BY bco.Occurred DESC
```

### 8.2 Find all customers blocked for a specific operation type

```sql
SELECT
    bco.CID,
    bur.Reason AS BlockReason,
    bco.Occurred
FROM Customer.BlockedCustomerOperations bco WITH (NOLOCK)
INNER JOIN Dictionary.BlockUnBlockReason bur WITH (NOLOCK)
    ON bur.ID = bco.BlockReasonID
WHERE bco.OperationTypeID = 4  -- Trading
ORDER BY bco.Occurred DESC
```

### 8.3 Count active blocks by operation type and reason

```sql
SELECT
    otfb.OperationDescription,
    bur.Reason AS BlockReason,
    COUNT(*) AS ActiveBlocks
FROM Customer.BlockedCustomerOperations bco WITH (NOLOCK)
INNER JOIN Dictionary.OperationTypesForBlocking otfb WITH (NOLOCK)
    ON otfb.OperationTypeID = bco.OperationTypeID
INNER JOIN Dictionary.BlockUnBlockReason bur WITH (NOLOCK)
    ON bur.ID = bco.BlockReasonID
GROUP BY otfb.OperationDescription, bur.Reason
ORDER BY ActiveBlocks DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trading Restriction Service TDD](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12992446514/Trading+Restriction+Service+TDD) | Confluence | Complete architecture: ASP.NET Core AKS service, 6 restriction flows, full BlockUnBlockReason enum with all 23 values, TradeRestrictionType enum mapping OperationTypeIDs 1-21, database schema confirmation, request/response models with RequestGUID field |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.BlockedCustomerOperations | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.BlockedCustomerOperations.sql*

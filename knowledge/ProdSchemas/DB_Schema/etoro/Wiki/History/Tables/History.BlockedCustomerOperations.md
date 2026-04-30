# History.BlockedCustomerOperations

> Completed-block archive: each row records one trading restriction that was lifted, capturing the full block interval (start, end), the operation restricted, and the reason it was applied.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CID, OperationTypeID, BlockStart) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BlockedCustomerOperations is the historical archive of resolved trading restrictions for eToro customers. When a customer is blocked from performing a specific trading operation (copying others, being copied, trading, opening positions, etc.) and that block is subsequently lifted, the completed restriction interval is written here. It answers: "Was this customer ever blocked from operation X? When, why, and for how long?"

The active/current state of all live blocks lives in Customer.BlockedCustomerOperations (the "live" counterpart). History.BlockedCustomerOperations only receives rows when a block ends - it is an immutable record of what happened, not what is happening now. Without this table, there would be no audit trail of past restrictions to support compliance queries, fraud investigations, regulatory reporting, or support escalations.

Data flows exclusively from Customer.OperationUnBlockForCID: when a block is lifted, that procedure copies the active Customer.BlockedCustomerOperations row into this table with BlockEnd set to GETUTCDATE(), then deletes it from the active table. The row transition is atomic within a transaction. Rows are never updated or deleted from History.BlockedCustomerOperations after insertion.

---

## 2. Business Logic

### 2.1 Block Lifecycle - Active to Historical

**What**: The two-table pattern (Customer + History) captures the full lifecycle: a block is born in Customer.BlockedCustomerOperations and dies (archived) here.

**Columns/Parameters Involved**: `BlockStart`, `BlockEnd`, `CID`, `OperationTypeID`, `BlockReasonID`

**Rules**:
- A block is CREATED by Customer.OperationBlockForCID: inserts into Customer.BlockedCustomerOperations with BlockStart = GETUTCDATE()
- A block is LIFTED by Customer.OperationUnBlockForCID: copies the Customer row to History.BlockedCustomerOperations with BlockEnd = GETUTCDATE(), then deletes from Customer
- History rows always have BlockEnd > BlockStart (full interval captured)
- The PK (CID, OperationTypeID, BlockStart) means a customer can be blocked and unblocked multiple times for the same operation - each cycle produces one History row with a distinct BlockStart

**Diagram**:
```
Block lifecycle:
  [Block Applied]
    Customer.OperationBlockForCID(@CID, @OperationTypeID, @BlockReasonID)
      -> INSERT Customer.BlockedCustomerOperations
           CID=@CID, OperationTypeID=@OperationTypeID, BlockReasonID=@BlockReasonID
           BlockStart=GETUTCDATE()

  [Block Lifted]
    Customer.OperationUnBlockForCID(@CID, @OperationTypeID)
      -> INSERT History.BlockedCustomerOperations  (this table)
           CID, OperationTypeID, BlockStart   <- from Customer row
           BlockEnd = GETUTCDATE()
           BlockReasonID, UnBlockReasonID = BlockReasonID  (see Section 2.2)
      -> DELETE Customer.BlockedCustomerOperations WHERE CID=@CID AND OperationTypeID=@OperationTypeID
```

### 2.2 UnBlockReasonID - Known Data Quality Issue

**What**: The UnBlockReasonID column was intended to record why a block was removed, but it always contains a copy of BlockReasonID.

**Columns/Parameters Involved**: `UnBlockReasonID`, `BlockReasonID`

**Rules**:
- Customer.OperationUnBlockForCID copies BlockReasonID into UnBlockReasonID on every insert
- Code comment in the procedure: "because no have data in Customer.BlockedCustomerOperations at field UnBlockReasonID then I put BlockReasonID!"
- Customer.BlockedCustomerOperations stores only the BlockReasonID at block creation; no unblock reason is captured there
- Result: UnBlockReasonID in History is always the same value as BlockReasonID - it does NOT tell you why the block was lifted, only why it was applied
- The BlockRequestGUID and UnBlockRequestGUID fields were added to support external system correlation

**Diagram**:
```
Intended: BlockReasonID = "why blocked", UnBlockReasonID = "why unblocked"
Actual:   BlockReasonID = "why blocked", UnBlockReasonID = BlockReasonID (same value)
```

### 2.3 Operation Type Distribution in History

**What**: Not all 24 operation types appear in history equally - the most blocked operations reveal regulatory and product enforcement patterns.

**Columns/Parameters Involved**: `OperationTypeID`

**Rules**:
- OperationTypeID=23 (SmartCopyUnblock) dominates with ~61% of history rows - automated copy restriction enforcement
- OperationTypeID=21 (Manual Execution Block) is second at ~23% - compliance/risk team manual interventions
- OperationTypeID=2 (Copied / being copied by others) is third at ~16% - copy acceptance restrictions
- Other types (Copy User, Public Portfolio Visible, Manual Unregister Mirror) appear rarely

---

## 3. Data Overview

| CID | OperationTypeID | BlockStart | BlockEnd | BlockReasonID | Meaning |
|---|---|---|---|---|---|
| 28 | 1 | 2016-09-28 06:57 | 2016-09-28 07:07 | 1 | Customer 28 blocked from copying others (Copy User) for 10 minutes; Requested by BO Admin; unblocked same day |
| 28 | 1 | 2016-09-28 11:24 | 2016-09-28 11:24 | 1 | Second brief Copy User block for same customer - pattern suggests automated or test scenario |
| 28 | 1 | 2016-09-28 12:56 | 2016-09-28 12:57 | 1 | Third Copy User block in same day; 1-minute duration suggests rapid toggle |
| 28 | 1 | 2016-09-28 12:58 | 2016-09-28 13:05 | 8 | Copy User block with BlockReasonID=8 (Requested by KYC) - compliance-initiated restriction |
| 28 | 1 | 2016-09-28 13:04 | 2016-09-28 13:05 | 1 | Fifth block for same customer; composite PK allows multiple rows per (CID, OperationType) with distinct BlockStart |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID of the customer whose operation was blocked. Implicit FK to Customer.Customer. PK component - with OperationTypeID and BlockStart, uniquely identifies one block interval. |
| 2 | OperationTypeID | int | NO | - | VERIFIED | The trading operation that was blocked. FK to Dictionary.OperationTypesForBlocking(OperationTypeID). Values in production history: 1=Copy User, 2=Copied, 3=Public Portfolio Visible, 11=Manual Unregister Mirror, 21=Manual Execution Block, 23=SmartCopyUnblock. Full lookup: 1=Copy User, 2=Copied, 3=Public Portfolio Visible, 4=Trading, 5=Position Open, 6=Manual Position Close, 7=Manual Open Exit Order, 8=Open Entry Order, 9=Open Order, 10=Open Open, 11=Manual Unregister Mirror, 12=Manual Edit SL, 13=Manual Edit TP, 14=Manual Edit TSL, 15=Manual Close Entry Order, 16=Manual Close Exit Order, 17=Order Close, 18=Manual Edit Mirror SL, 19=Manual Edit Mirror SL Percentage, 20=Manual Pause Copy, 21=Manual Execution Block, 22=Internal Instruments Allowed, 23=SmartCopyUnblock, 24=Detach Position. PK component. |
| 3 | BlockStart | datetime | NO | - | CODE-BACKED | UTC timestamp when the block was first applied. Copied from Customer.BlockedCustomerOperations.Occurred when the block is lifted. PK component. |
| 4 | BlockEnd | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the block was lifted. Set to GETUTCDATE() by Customer.OperationUnBlockForCID at the moment of unblocking. Duration of restriction = BlockEnd - BlockStart. Default value in DDL is getutcdate() but in practice always set explicitly by the unblock procedure. |
| 5 | BlockReasonID | int | NO | - | VERIFIED | The reason the block was applied. FK to Dictionary.BlockUnBlockReason(ID). 26 possible values: 1=Requested by BO Admin, 2=High Risk Score, 3=Employee Account, 4=OPT OUT, 5=OPT IN, 6=Not Verified, 7=Verified, 8=Requested by KYC, 9=Liquidation, 10=Liquidation Remove, 11=Manual Execution Block, 12=Manual Execution Block Remove, 13=AUM Limit, 14=Regulation, 15=Non-responsive, 16=Abusive trading, 17=Low Equity, 18=Breach of community Guidelines, 19=Non-launched CopyFund, 20=CopyFund not accepting new investors, 21=Max ($30M AUM) Popular Investors, 22=Max copiers / investors reached, 23=Max AUM per tier, 24=UkCryptoAllowed, 25=CfdAllowed, 26=GermanyCryptoAllowed. (Dictionary.BlockUnBlockReason) |
| 6 | UnBlockReasonID | int | NO | - | CODE-BACKED | Intended to capture why the block was lifted, but always equals BlockReasonID due to a known data quality issue in Customer.OperationUnBlockForCID: "because no have data in Customer.BlockedCustomerOperations at field UnBlockReasonID then I put BlockReasonID!" Do not rely on this field to understand unblock reason - it mirrors BlockReasonID. FK to Dictionary.BlockUnBlockReason(ID). |
| 7 | BlockRequestGUID | nvarchar(50) | YES | - | NAME-INFERRED | GUID correlating this block event to an external system request (e.g., a risk service call or back-office action that triggered the block). Nullable - not all blocks originate from external GUID-tracked requests. |
| 8 | UnBlockRequestGUID | nvarchar(50) | YES | - | NAME-INFERRED | GUID correlating the unblock event to the external system request that triggered it. Nullable - populated only when the unblock was initiated by an external system that provided a request GUID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Identifies the customer whose restriction history is recorded |
| OperationTypeID | Dictionary.OperationTypesForBlocking | Lookup | Classifies which trading operation was restricted |
| BlockReasonID | Dictionary.BlockUnBlockReason | FK | The reason the block was applied (26 values from compliance/risk categories) |
| UnBlockReasonID | Dictionary.BlockUnBlockReason | FK | Intended unblock reason; in practice always equals BlockReasonID due to data quality issue |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.OperationUnBlockForCID | CID, OperationTypeID | Writer | Primary writer - inserts here when a block is lifted |
| Customer.GetBlockedOperationsForCID | CID | Reader | Queries Customer.BlockedCustomerOperations (active); History is the archive counterpart |
| Trade.CustomerRestrictionSet | CID, OperationTypeID | Related | Sets restrictions in Customer table; History captures the completed cycles |
| Trade.CustomerRestrictionRemove | CID, OperationTypeID | Related | Removes restrictions; triggers the move to History |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BlockedCustomerOperations (table)
```

Tables are always leaf nodes - no code-level dependencies.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.BlockUnBlockReason | Table | FK target for both BlockReasonID and UnBlockReasonID |
| Dictionary.OperationTypesForBlocking | Table | Implicit FK - OperationTypeID values sourced from this lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.OperationUnBlockForCID | Stored Procedure | Writer - inserts completed block intervals on block removal |
| Trade.GetRestrictionsByTradingOperationTypes | Stored Procedure | Reader - queries historical restrictions |
| Trade.GetUserTradeStatusData | Stored Procedure | Reader - includes historical block data in user status |
| Trade.GetUserInfo | Stored Procedure | Reader - user info includes restriction history |
| Trade.TAPI_GetPublicFlatCreditHistoryByCID | Stored Procedure | Reader - credit history includes restriction context |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TPIL | CLUSTERED PK | CID ASC, OperationTypeID ASC, BlockStart ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TPIL | PRIMARY KEY | (CID, OperationTypeID, BlockStart) - allows multiple block intervals per customer per operation type |
| FK_BlockReasonID_IPkey | FOREIGN KEY | BlockReasonID -> Dictionary.BlockUnBlockReason(ID) |
| FK_UnBlockReasonID_IPkey | FOREIGN KEY | UnBlockReasonID -> Dictionary.BlockUnBlockReason(ID) |
| DF_HistoryBlockedCustomerOperations_BlockEnd | DEFAULT | BlockEnd = getutcdate() |

---

## 8. Sample Queries

### 8.1 Get full block history for a customer with operation and reason descriptions
```sql
SELECT
    hb.CID,
    op.OperationDescription,
    hb.BlockStart,
    hb.BlockEnd,
    DATEDIFF(MINUTE, hb.BlockStart, hb.BlockEnd) AS DurationMinutes,
    reason.Reason AS BlockReason,
    hb.BlockRequestGUID,
    hb.UnBlockRequestGUID
FROM [History].[BlockedCustomerOperations] hb WITH (NOLOCK)
JOIN [Dictionary].[OperationTypesForBlocking] op WITH (NOLOCK) ON hb.OperationTypeID = op.OperationTypeID
JOIN [Dictionary].[BlockUnBlockReason] reason WITH (NOLOCK) ON hb.BlockReasonID = reason.ID
WHERE hb.CID = @CID
ORDER BY hb.BlockStart DESC
```

### 8.2 Find most common block operations in history
```sql
SELECT
    op.OperationDescription,
    COUNT(*) AS BlockCount,
    AVG(DATEDIFF(MINUTE, hb.BlockStart, hb.BlockEnd)) AS AvgDurationMinutes
FROM [History].[BlockedCustomerOperations] hb WITH (NOLOCK)
JOIN [Dictionary].[OperationTypesForBlocking] op WITH (NOLOCK) ON hb.OperationTypeID = op.OperationTypeID
GROUP BY hb.OperationTypeID, op.OperationDescription
ORDER BY BlockCount DESC
```

### 8.3 Check if a customer currently has active blocks (joins live + history)
```sql
-- Active blocks (current state)
SELECT CID, OperationTypeID, Occurred AS BlockStart, NULL AS BlockEnd, 'Active' AS Status
FROM [Customer].[BlockedCustomerOperations] WITH (NOLOCK)
WHERE CID = @CID
UNION ALL
-- Historical blocks (lifted)
SELECT CID, OperationTypeID, BlockStart, BlockEnd, 'Completed' AS Status
FROM [History].[BlockedCustomerOperations] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY BlockStart DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trading Restriction Service TDD](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12992446514) | Confluence | Technical design document for the trading restriction service; page content unavailable (access error) |
| [Trading Restriction Service TDD](https://etoro-jira.atlassian.net/wiki/spaces/NOC1/pages/13503792392) | Confluence | Mirror/copy of trading restriction TDD in NOC1 space |
| [Trade.GetUserWithRestirctions](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13794476062) | Confluence | Procedure documentation referencing BlockedCustomerOperations as restriction data source |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BlockedCustomerOperations | Type: Table | Source: etoro/etoro/History/Tables/History.BlockedCustomerOperations.sql*

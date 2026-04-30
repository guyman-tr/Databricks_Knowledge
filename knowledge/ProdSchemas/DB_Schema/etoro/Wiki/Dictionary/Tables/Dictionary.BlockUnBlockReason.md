# Dictionary.BlockUnBlockReason

> Lookup table defining the reasons recorded when a customer's trading operations are blocked or unblocked. Critical for compliance audit trails — every restriction or lift must have a documented reason.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY(1,1), PK CLUSTERED) |
| **Filegroup** | PRIMARY |
| **Indexes** | 1 active (PK only) |
| **Special** | IDENTITY NOT FOR REPLICATION — replicated from master source |

---

## 1. Business Meaning

Dictionary.BlockUnBlockReason defines the catalog of reasons why a customer's trading operations were blocked or unblocked. When compliance, risk, or BackOffice restricts a customer's ability to trade (e.g., due to AML concerns, fraud investigation, KYC failures, regulatory requirements), the blocking reason is recorded in Customer.BlockedCustomerOperations via BlockReasonID. When the block is lifted, the unblock reason is similarly recorded in History.BlockedCustomerOperations via UnBlockReasonID. This creates a full audit trail for regulators and internal controls.

The IDENTITY(1,1) NOT FOR REPLICATION attribute indicates this table is replicated from a master/source database; subscriber databases do not generate their own IDs to avoid conflicts in merge/replication scenarios. Reason values are exposed to APIs via Trade.GetCustomerBlockUnBlockReasonsForAPI and used in CopyTrading restrictions (Trade.GetSmartCopyRestrictions) to indicate which block reasons can be removed for settlement restrictions.

Typical reasons inferred from usage include risk events, compliance holds, AML alerts, fraud investigation, voluntary self-exclusion, regulatory requirements, and BackOffice manual actions. Exact live values are environment-specific; the table is configuration-driven.

---

## 2. Business Logic

### 2.1 Block/Unblock Lifecycle

**What**: How block and unblock reasons are recorded in the customer restriction lifecycle.

**Columns/Parameters Involved**: `ID`, `Reason`

**Rules**:
- **Block**: Customer.OperationBlockForCID and related procs insert into Customer.BlockedCustomerOperations with BlockReasonID referencing this table. The reason explains why the block was applied.
- **Unblock**: Customer.OperationUnBlockForCID removes from BlockedCustomerOperations and inserts into History.BlockedCustomerOperations with both BlockReasonID (original) and UnBlockReasonID (why it was lifted).
- **Audit**: History.BlockedCustomerOperations preserves the full block/unblock timeline with both reasons for compliance and incident review.
- **API**: Trade.GetCustomerBlockUnBlockReasonsForAPI returns all reasons for client display (e.g., "Your account is restricted due to: Risk").

**Diagram**:
```
Block Applied:
  BlockReasonID ──► Dictionary.BlockUnBlockReason (e.g., "AML", "Fraud")
  Customer.BlockedCustomerOperations

Unblock Applied:
  UnBlockReasonID ──► Dictionary.BlockUnBlockReason (e.g., "Cleared", "Manual Override")
  History.BlockedCustomerOperations (audit)
```

### 2.2 CopyTrading Settlement Restrictions

**What**: How block reasons relate to CopyTrading settlement restrictions.

**Columns/Parameters Involved**: `ID`, `Reason`

**Rules**:
- Trade.CopyTradeSettlementRestrictions has UnblockReasonId — which BlockUnBlockReason must be applied to remove the restriction.
- Trade.GetSmartCopyRestrictions joins restriction.UnblockReasonId = reasons.ID and returns reasons.Reason AS RemovableByReason — indicating what action clears the restriction.

---

## 3. Data Overview

| ID | Reason | Meaning |
|---|---|---|
| 1 | Requested by BO Admin | BackOffice administrator manually blocked or unblocked a customer's operations — general-purpose override for compliance or operational reasons. |
| 2 | High Risk Score | Automated block triggered by the risk scoring engine when a customer's risk score exceeds thresholds. |
| 9 | Liquidation | Operations blocked as part of an account liquidation process — all positions being closed. Paired with ID 10 (Liquidation Remove) to unblock after completion. |
| 11 | Manual Execution Block | Execution explicitly blocked by operations — prevents order execution while allowing other operations. Paired with ID 12 (Manual Execution Block Remove). |
| 22 | Max copiers / investors reached | CopyTrading/CopyFund capacity limit reached — blocks new copiers from joining. |

*MCP-verified live data. 26 rows total. Additional reasons include: Employee Account (3), OPT OUT/IN (4-5), Not Verified/Verified (6-7), Requested by KYC (8), AUM Limit (13), Regulation (14), Non-responsive (15), Abusive trading (16), Low Equity (17), Breach of community Guidelines (18), Non-launched CopyFund (19), CopyFund not accepting new investors (20), Max ($30M AUM) Popular Investors (21), Max AUM per tier (23), UkCryptoAllowed (24), CfdAllowed (25), GermanyCryptoAllowed (26).*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | HIGH | Primary key; unique identifier. NOT FOR REPLICATION — IDs come from master in replication. Referenced by Customer.BlockedCustomerOperations.BlockReasonID, History.BlockedCustomerOperations.BlockReasonID/UnBlockReasonID. |
| 2 | Reason | nvarchar(50) | NO | - | CODE-BACKED | Human-readable reason label (e.g., "Risk", "Compliance"). Returned by Trade.GetCustomerBlockUnBlockReasonsForAPI. Used in Trade.GetSmartCopyRestrictions as RemovableByReason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.BlockedCustomerOperations | BlockReasonID | Explicit FK | Reason for block when restricting operations |
| History.BlockedCustomerOperations | BlockReasonID | Explicit FK | Original block reason in audit |
| History.BlockedCustomerOperations | UnBlockReasonID | Explicit FK | Reason for unblock in audit |
| Trade.CopyTradeSettlementRestrictions | UnblockReasonId | Reference | Which reason removes the restriction |
| Trade.GetCustomerBlockUnBlockReasonsForAPI | - | SELECT | Returns full reason catalog for API |
| Trade.GetSmartCopyRestrictions | reasons.ID | JOIN | Resolves RemovableByReason for CopyTrading restrictions |
| Customer.OperationBlockForCID | BlockReasonID | INSERT | Sets block reason when blocking |
| Customer.OperationUnBlockForCID | UnBlockReasonID | INSERT | Sets unblock reason in history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.BlockUnBlockReason (table)
  └── referenced by Customer.BlockedCustomerOperations (FK BlockReasonID)
  └── referenced by History.BlockedCustomerOperations (FK BlockReasonID, UnBlockReasonID)
  └── consumed by Trade.GetCustomerBlockUnBlockReasonsForAPI, GetSmartCopyRestrictions
  └── used by Customer.OperationBlockForCID, OperationUnBlockForCID
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | FK BlockReasonID |
| History.BlockedCustomerOperations | Table | FK BlockReasonID, UnBlockReasonID |
| Trade.GetCustomerBlockUnBlockReasonsForAPI | Stored Procedure | SELECT all reasons |
| Trade.GetSmartCopyRestrictions | Stored Procedure | JOIN for RemovableByReason |
| Customer.OperationBlockForCID | Stored Procedure | Block reason on insert |
| Customer.OperationUnBlockForCID | Stored Procedure | Unblock reason in history |
| Trade.UpdateEtorianUsersCopiedBlockRestriction | Stored Procedure | BlockReasonID on insert |
| Trade.CustomerRestrictionSet | Stored Procedure | BlockReasonID on insert |
| Trade.CustomerRestrictionRemove | Stored Procedure | UnBlockReasonID in history insert |
| SettingsDB replication procs | Stored Procedures | Merge/replication of BlockedCustomerOperations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictBlockUnBlockReason | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|------------------------|
| PK_DictBlockUnBlockReason | PRIMARY KEY | Unique reason identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all block/unblock reasons
```sql
SELECT  ID,
        Reason
FROM    Dictionary.BlockUnBlockReason WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count blocks by reason (current active blocks)
```sql
SELECT  br.Reason,
        COUNT(*) AS BlockCount
FROM    Customer.BlockedCustomerOperations bco WITH (NOLOCK)
JOIN    Dictionary.BlockUnBlockReason br WITH (NOLOCK)
        ON bco.BlockReasonID = br.ID
GROUP BY br.Reason
ORDER BY BlockCount DESC;
```

### 8.3 Recent block/unblock audit with reasons
```sql
SELECT  TOP 100
        hbco.CID,
        hbco.OperationTypeID,
        hbco.BlockStart,
        hbco.BlockEnd,
        block_reason.Reason AS BlockReason,
        unblock_reason.Reason AS UnBlockReason
FROM    History.BlockedCustomerOperations hbco WITH (NOLOCK)
LEFT JOIN Dictionary.BlockUnBlockReason block_reason WITH (NOLOCK)
        ON hbco.BlockReasonID = block_reason.ID
LEFT JOIN Dictionary.BlockUnBlockReason unblock_reason WITH (NOLOCK)
        ON hbco.UnBlockReasonID = unblock_reason.ID
ORDER BY hbco.BlockStart DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from codebase analysis: Customer.BlockedCustomerOperations, History.BlockedCustomerOperations, Customer.OperationBlockForCID, Customer.OperationUnBlockForCID, Trade.GetCustomerBlockUnBlockReasonsForAPI, Trade.GetSmartCopyRestrictions. No live data available; typical reason values inferred from domain (Risk, Compliance, AML, Fraud).

---

*Generated: 2026-03-13 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 VERIFIED, 1 CODE-BACKED, 1 HIGH, 0 ATLASSIAN-ONLY | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10+ analyzed | Live Data: Not available | Corrections: 0 applied*
*Object: Dictionary.BlockUnBlockReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BlockUnBlockReason.sql*

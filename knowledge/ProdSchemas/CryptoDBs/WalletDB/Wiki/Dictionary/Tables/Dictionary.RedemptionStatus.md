# Dictionary.RedemptionStatus

> Lookup table defining the lifecycle statuses for crypto redemption (sell/withdraw) requests, tracking progress from submission through execution to settlement.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the statuses that a cryptocurrency redemption request passes through. A redemption is when a customer sells or withdraws their crypto, converting it back to fiat or sending it to an external wallet. The five statuses track the request from initial persistence through blockchain execution to final settlement or failure.

Redemption is one of the most critical flows in the wallet system - it involves moving real customer assets. Status tracking is essential for customer support, stuck transaction detection, and compliance auditing. The table is consumed by 15+ stored procedures covering the full redemption lifecycle.

The table is FK-referenced by `Wallet.Redemptions`.

---

## 2. Business Logic

### 2.1 Redemption Lifecycle

**What**: Five-state lifecycle for redemption requests.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Persisted` (0): Redemption request saved to database but not yet picked up for processing
- `Retrieved` (1): Processing system has picked up the request from the queue
- `SentToExecuter` (2): Request sent to the blockchain execution engine for sending the transaction
- `SuccessReported` (3): Blockchain confirmed the transaction - funds successfully sent
- `FailureReported` (4): Execution failed - transaction could not be sent or was rejected by the blockchain

**Diagram**:
```
Persisted (0) --> Retrieved (1) --> SentToExecuter (2)
                                        |
                            +-----------+-----------+
                            |                       |
                    SuccessReported (3)      FailureReported (4)
                    [Funds sent]            [Retry or refund]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | Persisted | Redemption request recorded in the database. Awaiting pickup by the processing service. The customer has initiated the sell/withdraw but no execution has begun. |
| 1 | Retrieved | Processing service picked up the request. Validation checks (balance, limits, AML) are being performed before blockchain submission. |
| 2 | SentToExecuter | Request passed validation and was forwarded to the blockchain execution engine. The crypto send transaction is being constructed and signed. |
| 3 | SuccessReported | Blockchain confirmed the transaction. Customer funds have been successfully sent to the destination. Terminal success state. |
| 4 | FailureReported | Execution failed at some stage. The transaction could not be completed - possibly due to insufficient gas, blockchain congestion, or provider error. May be retried or require manual investigation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the redemption status. Values: 0=Persisted, 1=Retrieved, 2=SentToExecuter, 3=SuccessReported, 4=FailureReported. FK target for Wallet.Redemptions.RedemptionStatusId. Note: starts at 0, not 1. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Label for the redemption state. Used in customer transaction history, operations dashboards, and stuck-transaction monitoring alerts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.Redemptions | RedemptionStatusId | FK | Current status of each redemption request |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | FK on RedemptionStatusId |
| Wallet.AddNewRedemptionRequest | Stored Procedure | Sets initial status (Persisted) |
| Wallet.GetPendingRedemptionRequests | Stored Procedure | Filters for pending statuses |
| Wallet.StuckPendingRedemptions | Stored Procedure | Detects stuck pending redemptions |
| Wallet.StuckInProcessRedeems | Stored Procedure | Detects stuck in-process redeems |
| Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds | Stored Procedure | Updates redemption statuses |
| Wallet.GetDoubleSpendRedeems | Stored Procedure | Detects double-spend attempts |
| Wallet.GetExceededRedemptions | Stored Procedure | Finds redemptions exceeding limits |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RedemptionStatus | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all redemption statuses
```sql
SELECT Id, Name FROM Dictionary.RedemptionStatus WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find stuck redemptions (sent but not confirmed)
```sql
SELECT r.RedemptionId, rs.Name AS Status, r.Created
FROM Wallet.Redemptions r WITH (NOLOCK)
JOIN Dictionary.RedemptionStatus rs WITH (NOLOCK) ON r.RedemptionStatusId = rs.Id
WHERE rs.Id = 2 AND r.Created < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY r.Created
```

### 8.3 Redemption success rate
```sql
SELECT rs.Name, COUNT(*) AS Count
FROM Wallet.Redemptions r WITH (NOLOCK)
JOIN Dictionary.RedemptionStatus rs WITH (NOLOCK) ON r.RedemptionStatusId = rs.Id
GROUP BY rs.Name ORDER BY Count DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RedemptionStatus | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.RedemptionStatus.sql*

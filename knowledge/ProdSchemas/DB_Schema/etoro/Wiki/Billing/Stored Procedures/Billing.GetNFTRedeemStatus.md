# Billing.GetNFTRedeemStatus

> Returns the current status of an NFT redemption operation by customer and operation GUID - a lightweight status-polling endpoint for the crypto withdrawal pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @OperationID - returns current status of the NFT redemption |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetNFTRedeemStatus` is the status-polling procedure for NFT crypto withdrawals. After a customer submits an NFT redemption request, the service periodically calls this procedure to monitor whether the redemption has progressed through its state machine (New -> PositionPending -> Approved -> ReadyToRedeem -> PositionClosing -> PositionClosed -> TransactionInProcess -> TransactionDone -> Terminated).

The procedure returns the minimal set of fields needed for status reporting: the customer's identity, the crypto asset and quantity, the associated trade position, the current status, any termination reason, and when the record was last updated. It is scoped to `RedeemTypeID=1` (NFT/crypto) and uses the application-level `OperationID` GUID as the lookup key (the correlation ID used end-to-end in the withdrawal flow).

Created by Alexei B. (PTL-95).

---

## 2. Business Logic

### 2.1 NFT Status Lookup

**What**: Returns the current status fields for the NFT redemption matching the customer and operation.

**Columns/Parameters Involved**: `@CID`, `@OperationID`, `RedeemTypeID=1`, `RedeemStatusID`, `RedeemReasonID`, `LastModificationDate`

**Rules**:
- `WHERE CID = @CID AND OperationID = @OperationID AND RedeemTypeID = 1`
- CID ownership check prevents cross-customer exposure
- `WITH(NOLOCK)` - read uncommitted; optimized for high-frequency polling
- Returns at most one row per (CID, OperationID, RedeemTypeID=1) combination
- `RedeemStatusID`: current state in the redemption lifecycle (see Billing.Redeem state machine)
- `RedeemReasonID`: set only when redemption terminates; explains failure/cancellation reason

**Key status values** (from Billing.Redeem state machine):
```
100 = New
1   = PositionPending (main queue state)
3   = Approved
4   = ReadyToRedeem
5   = PositionClosing
6   = PositionClosed
7   = TransactionInProcess
9   = TransactionDone
20  = Terminated (terminal state, ~60% of records)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Ownership scope - only returns the redemption if it belongs to this customer. |
| 2 | @OperationID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Application-level GUID identifying the NFT withdrawal operation. The end-to-end correlation key across systems. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID (echoed from input). |
| 4 | Units | decimal | YES | NULL | CODE-BACKED | Quantity of the crypto asset being redeemed. |
| 5 | PositionID | int | YES | NULL | CODE-BACKED | FK to Trade.Position - the crypto position being liquidated. |
| 6 | InstrumentID | int | YES | NULL | CODE-BACKED | FK to Trade.Instrument - the crypto asset (e.g., BTC, ETH). |
| 7 | RedeemID | int | NO | - | CODE-BACKED | The redemption request PK. Can be used to call GetNFDetailsByRedeemID or GetNFTRedeemDetailsByOperationID for full details. |
| 8 | RedeemStatusID | int | NO | - | CODE-BACKED | Current state in the redemption lifecycle. Key values: 1=PositionPending, 3=Approved, 5=PositionClosing, 6=PositionClosed, 7=TransactionInProcess, 9=TransactionDone, 20=Terminated. |
| 9 | RedeemReasonID | int | YES | NULL | CODE-BACKED | Termination reason (set only when RedeemStatusID=20). Explains why the redemption failed or was cancelled (e.g., RejectedByOps, CanceledByUser, FailedByTrading). |
| 10 | LastModificationDate | datetime | NO | - | CODE-BACKED | Timestamp of the most recent status change. Used to detect staleness or track how long the redemption has been in the current state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Billing.Redeem | Direct Read | NFT redemption status record (CID + OperationID + RedeemTypeID=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers. Called from the NFT withdrawal service for status polling. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetNFTRedeemStatus (procedure)
└── Billing.Redeem (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | FROM - reads current NFT redemption status for (CID, OperationID, RedeemTypeID=1) |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check the status of an NFT withdrawal

```sql
EXEC Billing.GetNFTRedeemStatus
    @CID       = 12345678,
    @OperationID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
-- Returns: CID, Units, PositionID, InstrumentID, RedeemID, RedeemStatusID, RedeemReasonID, LastModificationDate
-- Empty if operation not found or belongs to a different customer
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT CID, Units, PositionID, InstrumentID, RedeemID,
       RedeemStatusID, RedeemReasonID, LastModificationDate
FROM Billing.Redeem WITH (NOLOCK)
WHERE CID = 12345678
  AND OperationID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
  AND RedeemTypeID = 1
```

### 8.3 Monitor all pending NFT redemptions

```sql
SELECT CID, RedeemID, RedeemStatusID, LastModificationDate,
       DATEDIFF(HOUR, LastModificationDate, GETDATE()) AS HoursInCurrentStatus
FROM Billing.Redeem WITH (NOLOCK)
WHERE RedeemTypeID = 1
  AND RedeemStatusID NOT IN (20, 9)  -- Not terminated and not done
ORDER BY LastModificationDate ASC
```

---

## 9. Atlassian Knowledge Sources

PTL-95 (Alexei B.): Created to support NFT redemption status polling in the crypto withdrawal pipeline.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetNFTRedeemStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetNFTRedeemStatus.sql*

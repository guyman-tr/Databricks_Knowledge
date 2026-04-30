# Wallet.GetRedemptionByPositionId

> Retrieves full redemption record details for a specific trading position, returning all columns needed for redemption processing and status tracking.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns redemption records for a position ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the complete redemption record(s) associated with a specific eToro trading position. When a customer closes a crypto position on the eToro trading platform, the system creates a redemption record that triggers the actual crypto withdrawal from the wallet. This procedure allows the redemption pipeline to look up the full details needed to process or track a redemption by its originating position.

Without this procedure, the system could not efficiently cross-reference between the trading platform's position lifecycle and the wallet system's redemption workflow. It bridges the trading domain (PositionId) with the wallet domain (redemption records).

Data comes from `Wallet.Redemptions` filtered by PositionId, using NOLOCK for non-blocking reads. May return multiple rows if a position has multiple redemption attempts (e.g., retry after failure).

---

## 2. Business Logic

### 2.1 Position-to-Redemption Lookup

**What**: Maps a trading position to its wallet redemption record(s).

**Columns/Parameters Involved**: `@PositionId`, `Redemptions.PositionId`

**Rules**:
- Direct lookup on Redemptions.PositionId
- May return multiple rows (e.g., partial redemptions, retries)
- Returns all key fields needed for redemption processing: correlation IDs, amounts, fees, status, billing references

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionId | bigint | NO | - | CODE-BACKED | The eToro trading position ID to look up redemptions for. Matches Redemptions.PositionId. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Redemption record identity. PK of Wallet.Redemptions. |
| 2 | OriginalRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Original request GUID from the trading platform that initiated this redemption. |
| 3 | SendRequestCorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID linking to the send request in the wallet pipeline (Wallet.Requests). |
| 4 | PositionId | bigint | NO | - | CODE-BACKED | eToro trading position ID (echoed from input). Links the wallet redemption to the trading position. |
| 5 | RequestingGcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the customer who owns the position and is receiving the redemption. |
| 6 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency being redeemed. FK to Wallet.CryptoTypes. |
| 7 | RequestedAmount | decimal | NO | - | CODE-BACKED | Total amount of crypto requested for redemption (before fee deduction). |
| 8 | eToroFeeAmount | decimal | NO | - | CODE-BACKED | eToro's fee deducted from the redemption. Net amount to customer = RequestedAmount - eToroFeeAmount. |
| 9 | RedemptionStatus | tinyint | NO | - | CODE-BACKED | Current redemption status: 0=Pending, 1=Processing, 2=WasSent. |
| 10 | BillingTransId | bigint | YES | - | CODE-BACKED | Billing system transaction ID for this redemption. Links to the billing/accounting system. |
| 11 | BillingRedeemId | bigint | YES | - | CODE-BACKED | Billing system redeem record ID. Used for billing reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.Redemptions | FROM | Main data source for redemption records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SQL callers found) | - | - | Called from trading/redemption application layer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetRedemptionByPositionId (procedure)
└── Wallet.Redemptions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | SELECT with NOLOCK - lookup by PositionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found in SQL) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hint | Read isolation | Non-blocking read on Redemptions |

---

## 8. Sample Queries

### 8.1 Look up redemption for a specific position
```sql
EXEC Wallet.GetRedemptionByPositionId @PositionId = 123456789;
```

### 8.2 Find all redemptions with their send request status
```sql
SELECT r.Id, r.PositionId, r.RequestedAmount, r.eToroFeeAmount, r.RedemptionStatus,
    rs.RequestStatusId AS SendRequestStatus
FROM Wallet.Redemptions r WITH (NOLOCK)
    LEFT JOIN Wallet.Requests req WITH (NOLOCK) ON req.CorrelationId = r.SendRequestCorrelationId
    OUTER APPLY (
        SELECT TOP 1 RequestStatusId FROM Wallet.RequestStatuses WITH (NOLOCK)
        WHERE RequestId = req.Id ORDER BY Id DESC
    ) rs
WHERE r.PositionId = 123456789;
```

### 8.3 Check if a position has multiple redemption attempts
```sql
SELECT PositionId, COUNT(*) AS AttemptCount
FROM Wallet.Redemptions WITH (NOLOCK)
WHERE PositionId = 123456789
GROUP BY PositionId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetRedemptionByPositionId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetRedemptionByPositionId.sql*

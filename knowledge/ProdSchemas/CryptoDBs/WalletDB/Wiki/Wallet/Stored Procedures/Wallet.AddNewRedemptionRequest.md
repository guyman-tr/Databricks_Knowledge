# Wallet.AddNewRedemptionRequest

> Creates a new crypto redemption (withdrawal) request, recording the position, requested amount, eToro fee, and billing references with an initial status of 0 (Pending).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.Redemptions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure initiates a crypto redemption (sell/withdraw) request. When a customer wants to convert their crypto position back to fiat or transfer crypto out, a redemption is created. Each redemption is tied to a specific trading position (PositionId) and captures the requested withdrawal amount, eToro's fee, and billing system references for reconciliation.

Without this procedure, the system could not accept customer redemption requests, effectively blocking the crypto sell/withdrawal flow. Redemptions are a core part of the crypto lifecycle: buy (position open) -> hold -> redeem (position close/withdrawal).

The procedure is called from the trading/billing service when a customer initiates a crypto redemption. It creates the record with RedemptionStatus=0 (Pending), after which downstream processes handle blockchain execution, fee deduction, and status progression.

---

## 2. Business Logic

### 2.1 Initial Status Assignment

**What**: All new redemptions start with RedemptionStatus = 0 (Pending).

**Columns/Parameters Involved**: `RedemptionStatus` (hardcoded to 0)

**Rules**:
- Hardcoded to 0 in the INSERT - no parameter for initial status
- Subsequent status changes are handled by other procedures (e.g., UpdateStatusOfRedeemRequestsByRedemptionIds)
- Status flow: 0 (Pending) -> processing -> completed/failed

### 2.2 Billing System Integration

**What**: Links the crypto redemption to the billing/trading platform via BillingTransId and BillingRedeemId.

**Columns/Parameters Involved**: `@BillingTransId`, `@BillingRedeemId`

**Rules**:
- BillingTransId references the billing system transaction
- BillingRedeemId references the billing system's redemption record
- These IDs enable reconciliation between the crypto wallet system and the trading/billing platform

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OriginalRequestGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique identifier for this redemption request, used for idempotency and correlation across systems. |
| 2 | @PositionId | bigint | NO | - | CODE-BACKED | The trading position being redeemed. Links to the position in the trading platform that holds the crypto asset. |
| 3 | @RequestingGcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the user requesting the redemption. |
| 4 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency being redeemed. Maps to Wallet.CryptoTypes.CryptoID (e.g., 1=BTC, 2=ETH). |
| 5 | @RequestedAmount | decimal(38,18) | NO | - | CODE-BACKED | The gross amount of crypto the customer wants to redeem, in the cryptocurrency's native units. High precision (18 decimals) supports fractional crypto amounts. |
| 6 | @eToroFeeAmount | decimal(38,18) | NO | - | CODE-BACKED | eToro's fee for processing this redemption, in the same crypto units. Deducted from the gross amount to determine the net transfer. |
| 7 | @BillingTransId | bigint | NO | - | CODE-BACKED | Reference to the billing system transaction record for financial reconciliation between the wallet and billing platforms. |
| 8 | @BillingRedeemId | bigint | NO | - | CODE-BACKED | Reference to the billing system's redemption record. Used for cross-system reconciliation and audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CryptoId | Wallet.CryptoTypes | Implicit | Cryptocurrency being redeemed |
| INSERT target | Wallet.Redemptions | Writer | Creates the redemption record |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application trading/billing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddNewRedemptionRequest (procedure)
  └── Wallet.Redemptions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | INSERT target |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None at the procedure level. Target table constraints apply (e.g., PK on Redemptions).

---

## 8. Sample Queries

### 8.1 View recent pending redemptions
```sql
SELECT TOP 20 Id, OriginalRequestGuid, RequestingGCID, CryptoID,
       RequestedAmount, eToroFeeAmount, RedemptionStatus, BeginDate
FROM Wallet.Redemptions WITH (NOLOCK)
WHERE RedemptionStatus = 0
ORDER BY Id DESC
```

### 8.2 Find redemptions for a customer
```sql
SELECT r.Id, r.PositionID, ct.CryptoName, r.RequestedAmount, r.eToroFeeAmount,
       r.RequestedAmount - r.eToroFeeAmount AS NetAmount, r.RedemptionStatus
FROM Wallet.Redemptions r WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = r.CryptoID
WHERE r.RequestingGCID = 12345678
ORDER BY r.Id DESC
```

### 8.3 Redemption summary by crypto and status
```sql
SELECT ct.CryptoName, r.RedemptionStatus, COUNT(*) AS Cnt,
       SUM(r.RequestedAmount) AS TotalRequested
FROM Wallet.Redemptions r WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = r.CryptoID
GROUP BY ct.CryptoName, r.RedemptionStatus
ORDER BY ct.CryptoName, r.RedemptionStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddNewRedemptionRequest | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddNewRedemptionRequest.sql*

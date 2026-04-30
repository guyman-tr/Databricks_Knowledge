# Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds

> Bulk-updates redemption status and associated fields (correlation ID, fees, source wallet, transaction type) for a set of redemption IDs, with guard against overwriting existing correlation IDs.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Wallet.Redemptions by TVP of RedemptionIds |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure transitions redemptions to a new status in bulk. The back-office API, billing notification, and redeem scheduler services call this to advance redemptions through their lifecycle (e.g., Persisted -> Retrieved -> SentToExecuter). It optionally sets the SendRequestCorrelationId (only if not already set), estimated blockchain fee, initial fee amount, source wallet, and transaction type. RAISERRORs if no rows are updated (safety check).

---

## 2. Business Logic

### 2.1 Conditional Field Updates with Safety Guard

**What**: Updates status and optional fields, protecting existing correlation IDs.

**Columns/Parameters Involved**: `@NewStatus`, `@NewRedeemRequestGuid`, `SendRequestCorrelationId`

**Rules**:
- UPDATE WHERE Id IN (@RedemptionIds)
- SendRequestCorrelationId: only set if @NewRedeemRequestGuid IS NULL OR existing is NULL
- Other fields use ISNULL pattern (only update if parameter provided)
- SourceWalletId and TransactionTypeId: ISNULL(existing, @new) - only set if currently NULL
- @@rowcount = 0 -> RAISERROR "Redemptions were not updated"

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedemptionIds | Wallet.RedemptionIds | NO | - | VERIFIED | TVP of redemption IDs to update. |
| 2 | @NewStatus | tinyint | NO | - | VERIFIED | New RedemptionStatus value. See [Redemption Status](../../_glossary.md#redemption-status). |
| 3 | @NewRedeemRequestGuid | uniqueidentifier | YES | NULL | VERIFIED | New SendRequestCorrelationId (only set if not already assigned). |
| 4 | @EstimatedBlockchainFee | decimal(36,18) | YES | NULL | CODE-BACKED | Estimated network fee. |
| 5 | @InitialFeeAmount | decimal(36,18) | YES | NULL | CODE-BACKED | Initial fee amount. |
| 6 | @SourceWalletId | uniqueidentifier | YES | NULL | CODE-BACKED | Source wallet for the redemption send (only if not already set). |
| 7 | @TransactionTypeId | tinyint | YES | NULL | CODE-BACKED | Transaction type (only if not already set). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RedemptionIds | Wallet.Redemptions | UPDATE | Bulk status transition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Admin status management |
| BillingNotificationUser | - | EXECUTE | Billing status updates |
| RedeemSchedulerUser | - | EXECUTE | Redemption lifecycle progression |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds (procedure)
+-- Wallet.Redemptions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | Bulk UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, BillingNotificationUser, RedeemSchedulerUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Transition redemptions to SentToExecuter
```sql
DECLARE @ids Wallet.RedemptionIds;
INSERT INTO @ids VALUES (100), (101);
EXEC Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds @RedemptionIds=@ids, @NewStatus=2, @NewRedeemRequestGuid='SEND-GUID';
```

### 8.2 Update with fees
```sql
DECLARE @ids Wallet.RedemptionIds;
INSERT INTO @ids VALUES (100);
EXEC Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds @RedemptionIds=@ids, @NewStatus=2, @EstimatedBlockchainFee=0.0001, @InitialFeeAmount=0.001;
```

### 8.3 Check redemption status
```sql
SELECT Id, RedemptionStatus, SendRequestCorrelationId FROM Wallet.Redemptions WITH (NOLOCK) WHERE Id IN (100, 101);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds.sql*

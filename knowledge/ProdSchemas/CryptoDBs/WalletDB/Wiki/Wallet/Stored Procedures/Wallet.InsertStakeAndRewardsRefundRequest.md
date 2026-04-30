# Wallet.InsertStakeAndRewardsRefundRequest

> Creates a staking rewards refund request, generating a new CorrelationId and marking it as active for processing by the staking refund pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.StakeAndRewardsRefunds |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a new staking rewards refund request. When staking rewards need to be returned to a customer (e.g., unstaking, corrections, or refunds), this SP inserts a record with IsActive=1 and a system-generated CorrelationId (NEWID()). The staking refund background process picks up active refund requests for blockchain execution.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct INSERT with auto-generated CorrelationId and IsActive=1.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer receiving the refund. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency being refunded. FK to Wallet.CryptoTypes. |
| 3 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Destination wallet for the refund. |
| 4 | @Amount | decimal(36,18) | NO | - | CODE-BACKED | Refund amount in crypto. |
| 5 | @Comment | nvarchar(256) | NO | - | CODE-BACKED | Reason/description for the refund. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.StakeAndRewardsRefunds | INSERT | Creates refund request |

### 5.2 Referenced By (other objects point to this)

No direct EXECUTE grants found. Likely called through admin/operations interfaces.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertStakeAndRewardsRefundRequest (procedure)
+-- Wallet.StakeAndRewardsRefunds (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StakeAndRewardsRefunds | Table | INSERT target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a refund request
```sql
EXEC Wallet.InsertStakeAndRewardsRefundRequest @Gcid=30351701, @CryptoId=1, @WalletId='WALLET-GUID', @Amount=0.001, @Comment='Staking rewards correction';
```

### 8.2 Check pending refunds
```sql
SELECT * FROM Wallet.StakeAndRewardsRefunds WITH (NOLOCK) WHERE IsActive = 1 ORDER BY Id DESC;
```

### 8.3 Check refunds for a customer
```sql
SELECT * FROM Wallet.StakeAndRewardsRefunds WITH (NOLOCK) WHERE Gcid = 30351701;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertStakeAndRewardsRefundRequest | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertStakeAndRewardsRefundRequest.sql*

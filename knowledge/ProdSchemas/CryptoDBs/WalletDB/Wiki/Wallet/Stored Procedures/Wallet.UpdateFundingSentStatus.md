# Wallet.UpdateFundingSentStatus

> Transitions pool wallets to FundingSent status by inserting a new WalletPoolStatuses record, with idempotency to prevent duplicate status entries, used by the redeem scheduler during funding operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into WalletPoolStatuses with idempotency |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure marks pool wallets as having their funding transaction sent. The redeem scheduler calls this after submitting blockchain funding transactions. It creates FundingSent status records for specified WalletPoolStatuses IDs with the given CorrelationId. Idempotent: LEFT JOIN + IS NULL prevents duplicate FundingSent entries.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Idempotent INSERT into WalletPoolStatuses with FundingSent status resolved from Dictionary.WalletPoolStatuses WHERE Name='FundingSent'.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletPoolStatusIds | Wallet.BigintListType | NO | - | VERIFIED | TVP of WalletPoolStatuses IDs to transition. |
| 2 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Funding request correlation ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletPoolStatusIds | Wallet.WalletPoolStatuses | JOIN + INSERT | Status transition |
| - | Dictionary.WalletPoolStatuses | JOIN | FundingSent status resolution |
| - | Wallet.PromotionTags | JOIN | CryptoId context |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemSchedulerUser | - | EXECUTE | Funding status update |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateFundingSentStatus (procedure)
+-- Wallet.WalletPoolStatuses (table)
+-- Dictionary.WalletPoolStatuses (table)
+-- Wallet.PromotionTags (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPoolStatuses | Table | JOIN source + INSERT target |
| Dictionary.WalletPoolStatuses | Table | Status name resolution |
| Wallet.PromotionTags | Table | CryptoId context |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemSchedulerUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Mark pool wallets as funding sent
```sql
DECLARE @ids Wallet.BigintListType;
INSERT INTO @ids VALUES (12345), (12346);
EXEC Wallet.UpdateFundingSentStatus @WalletPoolStatusIds = @ids, @CorrelationId = 'FUNDING-GUID';
```

### 8.2 Check funding status
```sql
SELECT wps.*, dps.Name FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
    JOIN Dictionary.WalletPoolStatuses dps WITH (NOLOCK) ON dps.Id = wps.WalletPoolStatusId
WHERE dps.Name = 'FundingSent';
```

### 8.3 Funding lifecycle
```sql
-- 1. GetFundingPendingWallets -> finds wallets needing funding
-- 2. UpdateFundingSentStatus (this SP) -> marks as FundingSent
-- 3. SyncFundedWalletStatusesAsync -> syncs to FundingVerified/FundingFailed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateFundingSentStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.UpdateFundingSentStatus.sql*

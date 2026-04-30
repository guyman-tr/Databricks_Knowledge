# Wallet.RollbackFundingPendingWallets

> Resets the Processed flag on specified wallet pool status records, allowing funding operations to be retried by the redeem scheduler service.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE WalletPoolStatuses SET Processed=0 by ID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure rolls back funding operations that are stuck or need retry. When pool wallet funding operations fail or need reprocessing, the redeem scheduler calls this to reset the Processed flag to 0 on the specified WalletPoolStatuses records. This allows the funding pipeline to pick them up again in the next cycle.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple UPDATE SET Processed=0 for specified WalletPoolStatuses IDs via TVP.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletPoolStatusIds | Wallet.BigintListType | NO | - | VERIFIED | TVP of WalletPoolStatuses IDs to reset. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletPoolStatusIds | Wallet.WalletPoolStatuses.Id | UPDATE | Resets Processed flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemSchedulerUser | - | EXECUTE | Funding retry |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.RollbackFundingPendingWallets (procedure)
+-- Wallet.WalletPoolStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPoolStatuses | Table | UPDATE target |

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

### 8.1 Rollback funding statuses
```sql
DECLARE @ids Wallet.BigintListType;
INSERT INTO @ids VALUES (12345), (12346);
EXEC Wallet.RollbackFundingPendingWallets @WalletPoolStatusIds = @ids;
```

### 8.2 Check processed status
```sql
SELECT Id, WalletPoolId, WalletPoolStatusId, Processed FROM Wallet.WalletPoolStatuses WITH (NOLOCK) WHERE Id IN (12345, 12346);
```

### 8.3 Find stuck funding operations
```sql
SELECT * FROM Wallet.WalletPoolStatuses WITH (NOLOCK) WHERE Processed = 1 AND WalletPoolStatusId = 5 ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.RollbackFundingPendingWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.RollbackFundingPendingWallets.sql*

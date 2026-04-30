# Wallet.GetWalletPoolForChecksumsValidation

> Retrieves assigned or funded pool wallets eligible for checksum validation, with pagination, filtering to wallets in WalletPoolStatusId 2 (Assigned) or 6 (Funded) by latest status.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated WalletPool rows for status 2 or 6 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns pool wallets that are eligible for checksum validation - specifically those whose latest status is either 2 (Assigned to a customer) or 6 (Funded). These are the pool wallets that hold real value and need integrity verification. Unassigned/free pool wallets (status 1) are excluded since they haven't been funded yet.

The executer service uses this to determine which pool wallets need checksum recalculation. The procedure supports OFFSET/FETCH pagination for processing large sets in batches.

---

## 2. Business Logic

### 2.1 Status-Based Eligibility

**What**: Filters pool wallets by their latest status using a correlated subquery.

**Columns/Parameters Involved**: `WalletPoolStatuses.WalletPoolStatusId`

**Rules**:
- Correlated subquery: SELECT TOP 1 WalletPoolStatusId ORDER BY Id DESC
- Only wallets with latest status IN (2, 6) are returned
- Status 2 = Assigned (wallet given to a customer)
- Status 6 = Funded (wallet has been pre-funded)
- OFFSET @SkipRecords ROWS FETCH NEXT @MaxRecords ROWS ONLY for pagination

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SkipRecords | int | NO | - | VERIFIED | Number of records to skip for pagination. |
| 2 | @MaxRecords | int | NO | - | VERIFIED | Maximum records to return per page. |
| 3 | Id (output) | bigint | NO | - | CODE-BACKED | WalletPool record ID. |
| 4 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Pool wallet GUID. |
| 5 | BlockchainCryptoId (output) | int | NO | - | CODE-BACKED | Base-chain crypto. |
| 6 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 7 | PublicAddress (output) | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address. |
| 8 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Wallet provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletPool | Source | Pool wallet records |
| - | Wallet.WalletPoolStatuses | Subquery | Latest status filter (IN 2, 6) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Determines which pool wallets need checksum validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletPoolForChecksumsValidation (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletPoolStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | Pool wallet records |
| Wallet.WalletPoolStatuses | Table | Correlated subquery for latest status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get first page
```sql
EXEC Wallet.GetWalletPoolForChecksumsValidation @SkipRecords = 0, @MaxRecords = 1000;
```

### 8.2 Get second page
```sql
EXEC Wallet.GetWalletPoolForChecksumsValidation @SkipRecords = 1000, @MaxRecords = 1000;
```

### 8.3 Direct equivalent
```sql
SELECT wp.Id, wp.WalletId, wp.BlockchainCryptoId, wp.ProviderWalletId, wp.PublicAddress, wp.WalletProviderId
FROM Wallet.WalletPool wp WITH (NOLOCK)
WHERE (SELECT TOP 1 wps.WalletPoolStatusId FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK) WHERE wps.WalletPoolId = wp.Id ORDER BY wps.Id DESC) IN (2, 6)
ORDER BY wp.Id OFFSET 0 ROWS FETCH NEXT 1000 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletPoolForChecksumsValidation | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletPoolForChecksumsValidation.sql*

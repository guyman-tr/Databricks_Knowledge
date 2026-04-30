# Wallet.GetEtoroExternalAddressByAddress

> Looks up an active eToro external address by its blockchain address string, cryptocurrency, and address type - used to identify if a given address belongs to eToro.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns matching active EtoroExternalAddresses row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure determines whether a blockchain address is owned by eToro. When processing incoming or outgoing transactions, the system checks if the counterparty address is one of eToro's own addresses. This classification affects AML screening, transaction categorization (internal transfer vs external), and fee calculation. Only active (IsActive=1) addresses are matched.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Three-column filtered SELECT with IsActive=1 filter.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Address | nvarchar(512) | NO | - | CODE-BACKED | The blockchain address to look up. |
| 2 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency to match (addresses are crypto-specific). |
| 3 | @ExternalAddressTypeId | tinyint | NO | - | CODE-BACKED | Address type to match (e.g., hot wallet, cold storage). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.EtoroExternalAddresses | Reader | Source of address data |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetEtoroExternalAddressByAddress (procedure)
  └── Wallet.EtoroExternalAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.EtoroExternalAddresses | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hint, SET NOCOUNT ON
- Filters on IsActive = 1

---

## 8. Sample Queries

### 8.1 Check if an address is eToro-owned
```sql
EXEC Wallet.GetEtoroExternalAddressByAddress
    @Address = 'bc1qexample123',
    @CryptoId = 1,
    @ExternalAddressTypeId = 1
```

### 8.2 All active addresses for a crypto
```sql
SELECT Address, Comment, ExternalAddressTypeId
FROM Wallet.EtoroExternalAddresses WITH (NOLOCK)
WHERE CryptoId = 1 AND IsActive = 1
```

### 8.3 Search by address prefix
```sql
SELECT Id, Address, CryptoId, ExternalAddressTypeId, Comment
FROM Wallet.EtoroExternalAddresses WITH (NOLOCK)
WHERE Address LIKE 'bc1q%' AND IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetEtoroExternalAddressByAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetEtoroExternalAddressByAddress.sql*

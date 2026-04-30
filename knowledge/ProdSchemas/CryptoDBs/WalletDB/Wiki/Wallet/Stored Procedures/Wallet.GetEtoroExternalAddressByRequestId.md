# Wallet.GetEtoroExternalAddressByRequestId

> Retrieves the eToro external address associated with a manual out-transaction request, resolving the address through the ManualOutTransactions table.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns EtoroExternalAddresses via ManualOutTransactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the eToro external address that was the destination of a manual out-transaction. Manual out-transactions are administrative operations that move crypto from customer wallets to eToro-controlled addresses (e.g., consolidation, fee collection, compliance holds). This procedure traces from the manual out-transaction request back to the destination address.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Two-table JOIN resolving request to address.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestId | int | NO | - | CODE-BACKED | ManualOutTransactions.Id to look up the associated external address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ManualOutTransactions | Reader | Resolves request to external address ID |
| - | Wallet.EtoroExternalAddresses | Reader | Source of address details |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetEtoroExternalAddressByRequestId (procedure)
  ├── Wallet.ManualOutTransactions (table)
  └── Wallet.EtoroExternalAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualOutTransactions | Table | JOIN to resolve request |
| Wallet.EtoroExternalAddresses | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hints, SET NOCOUNT ON

---

## 8. Sample Queries

### 8.1 Get address for a manual out request
```sql
EXEC Wallet.GetEtoroExternalAddressByRequestId @RequestId = 123
```

### 8.2 View manual out transactions with addresses
```sql
SELECT mot.Id, mot.EtoroExternalAddressId, eea.Address, eea.Comment, eea.CryptoId
FROM Wallet.ManualOutTransactions mot WITH (NOLOCK)
JOIN Wallet.EtoroExternalAddresses eea WITH (NOLOCK) ON eea.Id = mot.EtoroExternalAddressId
ORDER BY mot.Id DESC
```

### 8.3 Recent manual out transactions
```sql
SELECT TOP 20 Id, EtoroExternalAddressId FROM Wallet.ManualOutTransactions WITH (NOLOCK) ORDER BY Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetEtoroExternalAddressByRequestId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetEtoroExternalAddressByRequestId.sql*

# Wallet.GetEtoroExternalAddress

> Retrieves a single eToro external address record by its internal ID.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns EtoroExternalAddresses row by Id |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a specific eToro-owned external address record by ID. eToro external addresses are blockchain addresses controlled by eToro (hot wallets, cold storage, omnibus addresses) that the system must recognize. This getter is used when the application already knows the address record ID and needs to fetch its details.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple PK lookup.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | int | NO | - | CODE-BACKED | Internal ID of the eToro external address record to retrieve. |

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
Wallet.GetEtoroExternalAddress (procedure)
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

---

## 8. Sample Queries

### 8.1 Get address by ID
```sql
EXEC Wallet.GetEtoroExternalAddress @Id = 1
```

### 8.2 List all active external addresses
```sql
SELECT Id, Address, Comment, CryptoId, ExternalAddressTypeId FROM Wallet.EtoroExternalAddresses WITH (NOLOCK) WHERE IsActive = 1
```

### 8.3 External addresses by crypto
```sql
SELECT CryptoId, COUNT(*) AS Cnt FROM Wallet.EtoroExternalAddresses WITH (NOLOCK) WHERE IsActive = 1 GROUP BY CryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetEtoroExternalAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetEtoroExternalAddress.sql*

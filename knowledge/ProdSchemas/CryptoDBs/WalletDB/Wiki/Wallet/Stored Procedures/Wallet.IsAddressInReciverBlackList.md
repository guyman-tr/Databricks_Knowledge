# Wallet.IsAddressInReciverBlackList

> Checks if a blockchain address appears in the AML receiver blacklist, returning 1 if blacklisted, used by the AML service to block incoming transactions from sanctioned addresses.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 if address is in AmlBlackList.ReciverAddress |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks whether a blockchain address appears on the AML receiver blacklist. When the platform receives a transaction or needs to validate a destination address, the AML service calls this to determine if the address is sanctioned or flagged. Returns SELECT 1 if found, or no result set if not found. Note: the column name 'ReciverAddress' contains a legacy typo (should be 'ReceiverAddress').

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple EXISTS check on AmlBlackList.ReciverAddress.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Address | nvarchar(512) | NO | - | VERIFIED | Blockchain address to check against the receiver blacklist. |
| 2 | Result (output) | int | YES | - | CODE-BACKED | 1 if address is blacklisted. No result set if not blacklisted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Address | Wallet.AmlBlackList.ReciverAddress | EXISTS check | Blacklist lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | AML receiver address screening |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.IsAddressInReciverBlackList (procedure)
+-- Wallet.AmlBlackList (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlBlackList | Table | EXISTS check on ReciverAddress |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if address is blacklisted
```sql
EXEC Wallet.IsAddressInReciverBlackList @Address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
```

### 8.2 Check sender blacklist too
```sql
EXEC Wallet.IsAddressInSenderBlackList @Address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
```

### 8.3 Direct equivalent
```sql
IF EXISTS (SELECT TOP 1 ReciverAddress FROM Wallet.AmlBlackList WHERE ReciverAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa') SELECT 1 AS Result;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.IsAddressInReciverBlackList | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.IsAddressInReciverBlackList.sql*

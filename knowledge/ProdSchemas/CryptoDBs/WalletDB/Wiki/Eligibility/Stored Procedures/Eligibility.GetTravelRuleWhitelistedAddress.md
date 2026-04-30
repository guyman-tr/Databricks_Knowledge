# Eligibility.GetTravelRuleWhitelistedAddress

> Checks if a blockchain address is in the travel rule whitelist and returns the owning customer's details.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1 whitelist record for a given address |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the lookup endpoint for the travel rule whitelist. When an incoming cryptocurrency transaction is detected, the system checks whether the sender address is whitelisted by calling this procedure. If a match is found, the transaction can bypass manual travel rule approval because the customer has already proven ownership of the sending address.

The procedure returns the most recent whitelist entry (TOP 1 ORDER BY Id DESC) for the given address, providing the owning customer's Gcid, the blockchain network, and when the whitelist entry was created.

---

## 2. Business Logic

### 2.1 Address Lookup

**What**: Single-address lookup returning the most recent whitelist entry.

**Columns/Parameters Involved**: `@Address`

**Rules**:
- Filters by exact address match (case-sensitive for blockchain addresses)
- Returns TOP 1 ordered by Id DESC (most recent entry for that address)
- Uses NOLOCK for performance
- If no match: empty result set (address is not whitelisted)
- The IX_TravelRuleWhitelistedAddresses_Address index supports fast lookup

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Address | NVARCHAR(512) (IN) | NO | - | CODE-BACKED | The blockchain address to look up in the whitelist. Must be an exact match. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID who owns this whitelisted address. |
| 2 | BlockchainCryptoId | int | NO | - | CODE-BACKED | Blockchain network identifier for the address. |
| 3 | Created | datetime2 | NO | - | CODE-BACKED | When the whitelist entry was created. |
| 4 | Address | nvarchar(512) | NO | - | CODE-BACKED | The whitelisted address (echoed back for confirmation). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT FROM | Eligibility.TravelRuleWhitelistedAddresses | READER | Address lookup in the whitelist table |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT project. Called by the Eligibility Service during incoming transaction processing.

---

## 6. Dependencies

```
Eligibility.GetTravelRuleWhitelistedAddress (procedure)
+-- Eligibility.TravelRuleWhitelistedAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.TravelRuleWhitelistedAddresses | Table | Lookup source for whitelisted addresses |

### 6.2 Objects That Depend On This

No callers found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if an address is whitelisted
```sql
EXEC Eligibility.GetTravelRuleWhitelistedAddress @Address = '0xABC123...'
```

### 8.2 Direct equivalent query
```sql
SELECT TOP 1 Gcid, BlockchainCryptoId, Created, Address
FROM Eligibility.TravelRuleWhitelistedAddresses WITH (NOLOCK)
WHERE Address = '0xABC123...' ORDER BY Id DESC
```

### 8.3 Find all whitelisted addresses matching a pattern
```sql
SELECT Address, Gcid, BlockchainCryptoId
FROM Eligibility.TravelRuleWhitelistedAddresses WITH (NOLOCK)
WHERE Address LIKE '0x%' ORDER BY Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.GetTravelRuleWhitelistedAddress | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.GetTravelRuleWhitelistedAddress.sql*

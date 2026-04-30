# Monitoring.GetDuplicateWhitelistedAddresses

> Detects duplicate travel rule whitelisted addresses for the same customer and blockchain crypto combination within a configurable time window, flagging potential data integrity issues in the whitelisting process.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns duplicate address entries grouped by customer/crypto/address |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetDuplicateWhitelistedAddresses identifies cases where the same blockchain address has been whitelisted more than once for the same customer (Gcid) and crypto type (BlockchainCryptoId). Travel rule whitelisted addresses are used to pre-approve recipient addresses for crypto transfers, bypassing repeated travel rule verification. Duplicates may indicate a bug in the whitelisting flow or race conditions in concurrent whitelist requests.

Without this procedure, duplicate whitelist entries would silently accumulate, potentially causing issues in address lookup logic or inflating the whitelist unnecessarily.

The procedure groups by Gcid, BlockchainCryptoId, and Address within the specified time window and returns groups with COUNT > 1.

---

## 2. Business Logic

### 2.1 Duplicate Detection

**What**: Finds addresses whitelisted more than once per customer/crypto combination.

**Columns/Parameters Involved**: `Gcid`, `BlockchainCryptoId`, `Address`, `@MonthsBack`

**Rules**:
- Groups by (Gcid, BlockchainCryptoId, Address) within the lookback window
- HAVING COUNT(*) > 1 filters to only duplicate entries
- Returns DuplicateCount, FirstEntry, and LastEntry timestamps for investigation
- Default window of 6 months covers recent whitelisting activity

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MonthsBack | INT | NO | 6 | CODE-BACKED | Lookback window in months. Default 6 months covers recent whitelisting activity. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Gcid | INT | NO | - | CODE-BACKED | Customer ID who whitelisted the address multiple times. |
| 2 | BlockchainCryptoId | INT | NO | - | CODE-BACKED | Blockchain crypto type for the duplicate address. |
| 3 | Address | NVARCHAR | NO | - | CODE-BACKED | The blockchain address that was whitelisted more than once. |
| 4 | DuplicateCount | INT | NO | - | CODE-BACKED | Number of times this address was whitelisted for this customer/crypto. |
| 5 | FirstEntry | DATETIME2 | NO | - | CODE-BACKED | Timestamp of the first whitelist entry for this combination. |
| 6 | LastEntry | DATETIME2 | NO | - | CODE-BACKED | Timestamp of the most recent duplicate whitelist entry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Eligibility.TravelRuleWhitelistedAddresses | FROM (read) | Source of whitelisted address records |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetDuplicateWhitelistedAddresses (procedure)
  └── Eligibility.TravelRuleWhitelistedAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.TravelRuleWhitelistedAddresses | Table | FROM - whitelisted address records |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check for duplicates in last 6 months (default)
```sql
EXEC Monitoring.GetDuplicateWhitelistedAddresses;
```

### 8.2 Check full history
```sql
EXEC Monitoring.GetDuplicateWhitelistedAddresses @MonthsBack = 120;
```

### 8.3 View all whitelist entries for a specific address
```sql
SELECT * FROM Eligibility.TravelRuleWhitelistedAddresses WITH (NOLOCK)
WHERE Address = '0x1234...' ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetDuplicateWhitelistedAddresses | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetDuplicateWhitelistedAddresses.sql*

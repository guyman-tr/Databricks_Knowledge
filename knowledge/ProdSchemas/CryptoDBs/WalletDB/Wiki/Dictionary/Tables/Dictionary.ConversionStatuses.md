# Dictionary.ConversionStatuses

> Lookup table defining the lifecycle statuses of cryptocurrency conversion (swap) operations within the wallet system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the possible states of a cryptocurrency conversion (swap) operation. A conversion is when a customer exchanges one cryptocurrency for another (e.g., BTC to ETH) within the platform. Each conversion passes through these statuses as it progresses from initiation to completion or failure.

Conversion status tracking is essential for both customer experience (showing progress) and operational monitoring (identifying stuck or failed conversions). The finance team uses these statuses for reconciliation of crypto-to-crypto swaps.

The table is FK-referenced by `Wallet.ConversionStatuses` and consumed by conversion transaction list functions (`GetConversionTransactionList`, `GetConversionTransactionListV2`, `GetConversionTransactionList_temp`).

---

## 2. Business Logic

### 2.1 Conversion Lifecycle States

**What**: Three-state lifecycle model for crypto-to-crypto conversions.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Pending` (1): Conversion has been initiated but not yet executed. The system is awaiting exchange rate confirmation, liquidity, or blockchain settlement of prerequisite steps.
- `Failed` (2): Conversion could not be completed. Possible causes: insufficient funds, exchange rate moved beyond acceptable slippage, provider error, or timeout. Customer funds are returned to the source cryptocurrency.
- `Completed` (3): Conversion successfully executed. The source cryptocurrency has been debited and the target cryptocurrency has been credited to the customer's wallet.

**Diagram**:
```
Conversion Initiated
    |
    v
Pending (1) --success--> Completed (3)
    |
    +------failure------> Failed (2)
                          [Funds returned to source]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Pending | Conversion is in progress. The swap has been initiated but the underlying transactions (debit source crypto, credit target crypto) are not yet finalized. Customer sees "processing" in their transaction history. |
| 2 | Failed | Conversion could not be completed due to an error (insufficient balance, rate slippage, provider failure). The customer's source cryptocurrency is returned. Requires investigation if failures are systematic. |
| 3 | Completed | Conversion successfully finished. Both legs of the swap are settled - source crypto debited, target crypto credited. The customer can now use the converted funds. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the conversion status. Values: 1=Pending, 2=Failed, 3=Completed. FK target for Wallet.ConversionStatuses and referenced in conversion transaction queries. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Human-readable status label. Displayed in customer transaction history and used in operational monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.ConversionStatuses | ConversionStatusId | FK | Links conversion records to their current lifecycle status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ConversionStatuses | Table | FK on ConversionStatusId |
| Wallet.GetConversionTransactionList | Function | JOINs for conversion transaction reporting |
| Wallet.GetConversionTransactionListV2 | Function | JOINs for conversion transaction reporting (v2) |
| Wallet.GetConversionTransactionList_temp | Function | JOINs for conversion transaction reporting (temp) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ConversionStatuses | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all conversion statuses
```sql
SELECT Id, Name FROM Dictionary.ConversionStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count conversions by status
```sql
SELECT cs.Name, COUNT(c.ConversionId) AS ConversionCount
FROM Dictionary.ConversionStatuses cs WITH (NOLOCK)
LEFT JOIN Wallet.Conversions c WITH (NOLOCK) ON c.ConversionStatusId = cs.Id
GROUP BY cs.Name ORDER BY cs.Name
```

### 8.3 Find stuck pending conversions
```sql
SELECT c.ConversionId, cs.Name AS Status, c.Created
FROM Wallet.Conversions c WITH (NOLOCK)
JOIN Dictionary.ConversionStatuses cs WITH (NOLOCK) ON c.ConversionStatusId = cs.Id
WHERE cs.Id = 1 AND c.Created < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY c.Created
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ConversionStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ConversionStatuses.sql*

# Dictionary.InternalTransactionErrorCodes

> Lookup table defining platform-internal error codes for cryptocurrency transaction failures, used to classify errors beyond provider-specific codes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines error codes that are internal to the eToro platform, as distinct from error codes returned by external providers (like BitGo). When a transaction fails due to a condition the platform itself detects (rather than an external provider returning an error), the failure is classified using these internal codes.

Currently only one internal error code exists (`InsufficientFunds`), which is the most common pre-flight check failure - the system verifies the customer has enough balance before submitting a transaction to the blockchain provider.

The table is FK-referenced by `Dictionary.TransactionErrorCodes` which maintains the complete error code catalog across all sources.

---

## 2. Business Logic

### 2.1 Pre-Flight Validation Errors

**What**: Internal error codes represent platform-detected failures before or during transaction processing.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `InsufficientFunds` (1): The customer's wallet balance is insufficient to cover the requested transaction amount plus estimated fees. This check happens before the transaction is submitted to the blockchain provider, saving gas costs and preventing unnecessary blockchain interactions.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | InsufficientFunds | The customer does not have enough cryptocurrency balance to complete the requested operation. Checked before submitting to the blockchain provider. Covers both the transaction amount and estimated network fees. The most common transaction failure reason across all crypto platforms. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the internal error code. Currently: 1=InsufficientFunds. FK target for Dictionary.TransactionErrorCodes.InternalTransactionErrorCodeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Descriptive label for the error condition. Used in error messages shown to customers and in operational monitoring. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.TransactionErrorCodes | InternalTransactionErrorCodeId | FK (nullable) | Maps external error codes to their internal equivalent when applicable |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TransactionErrorCodes | Table | FK on InternalTransactionErrorCodeId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InternalTransactionErrorCodes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all internal error codes
```sql
SELECT Id, Name FROM Dictionary.InternalTransactionErrorCodes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find external error codes mapped to InsufficientFunds
```sql
SELECT tec.Id, es.Name AS Source, tec.ErrorCode, tec.ErrorMessage
FROM Dictionary.TransactionErrorCodes tec WITH (NOLOCK)
JOIN Dictionary.InternalTransactionErrorCodes itec WITH (NOLOCK) ON tec.InternalTransactionErrorCodeId = itec.Id
JOIN Dictionary.ErrorSources es WITH (NOLOCK) ON tec.ErrorSourceId = es.Id
WHERE itec.Id = 1
```

### 8.3 All internal codes with their external mappings
```sql
SELECT itec.Name AS InternalCode, COUNT(tec.Id) AS MappedExternalCodes
FROM Dictionary.InternalTransactionErrorCodes itec WITH (NOLOCK)
LEFT JOIN Dictionary.TransactionErrorCodes tec WITH (NOLOCK) ON tec.InternalTransactionErrorCodeId = itec.Id
GROUP BY itec.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InternalTransactionErrorCodes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.InternalTransactionErrorCodes.sql*

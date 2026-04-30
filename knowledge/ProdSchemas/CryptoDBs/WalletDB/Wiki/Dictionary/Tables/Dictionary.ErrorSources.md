# Dictionary.ErrorSources

> Lookup table identifying the system components that originate transaction errors, enabling error routing and troubleshooting.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table identifies the technical source systems that can generate transaction errors in the wallet platform. When a cryptocurrency transaction fails, the error is tagged with a source ID to indicate which layer of the stack produced the error. This enables operations teams to route error investigation to the correct team.

Error source attribution is critical for incident response. A Bitgo error (blockchain provider issue) requires different investigation and remediation than a SQL error (database-level failure) or a General error (application logic failure).

The table is FK-referenced by `Dictionary.TransactionErrorCodes` (which maps specific error codes to their source) and consumed by `Wallet.GetErrorSources` stored procedure.

---

## 2. Business Logic

### 2.1 Error Source Routing

**What**: Three error source categories direct troubleshooting to the correct team.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Bitgo` (1): Error originated from the BitGo blockchain custody provider. Indicates a blockchain-level or custody-level failure (e.g., insufficient hot wallet balance, blockchain congestion, signing failure).
- `SQL` (2): Error originated from the database layer. Indicates a data integrity issue, constraint violation, or stored procedure failure within the WalletDB.
- `General` (3): Error originated from the application layer or cannot be attributed to a specific source. Catch-all for business logic failures, timeout errors, or unclassified issues.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Bitgo | Error from the BitGo blockchain custody provider. BitGo handles key management, transaction signing, and blockchain interaction. Errors here indicate infrastructure or blockchain network issues outside eToro's direct control. Escalated to the crypto infrastructure team. |
| 2 | SQL | Error from the database layer (WalletDB). Indicates stored procedure failures, constraint violations, deadlocks, or data integrity issues. Escalated to the database/back-end engineering team. |
| 3 | General | Application-layer error or unclassified source. Covers business logic failures, API timeout errors, configuration issues, or errors that span multiple systems. First-line investigation by the wallet operations team. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the error source. Values: 1=Bitgo, 2=SQL, 3=General. FK target for Dictionary.TransactionErrorCodes.ErrorSourceId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Name of the source system. Used in error monitoring dashboards, alerting rules, and incident reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.TransactionErrorCodes | ErrorSourceId | FK | Each error code is tagged with its originating source system |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TransactionErrorCodes | Table | FK on ErrorSourceId |
| Wallet.GetErrorSources | Stored Procedure | Reads all error sources |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ErrorSources | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all error sources
```sql
SELECT Id, Name FROM Dictionary.ErrorSources WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count transaction errors by source
```sql
SELECT es.Name AS Source, COUNT(tec.Id) AS ErrorCodeCount
FROM Dictionary.ErrorSources es WITH (NOLOCK)
LEFT JOIN Dictionary.TransactionErrorCodes tec WITH (NOLOCK) ON tec.ErrorSourceId = es.Id
GROUP BY es.Name ORDER BY ErrorCodeCount DESC
```

### 8.3 List error codes with their source system
```sql
SELECT es.Name AS Source, tec.ErrorCode, tec.ErrorMessage
FROM Dictionary.TransactionErrorCodes tec WITH (NOLOCK)
JOIN Dictionary.ErrorSources es WITH (NOLOCK) ON tec.ErrorSourceId = es.Id
ORDER BY es.Name, tec.ErrorCode
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ErrorSources | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ErrorSources.sql*

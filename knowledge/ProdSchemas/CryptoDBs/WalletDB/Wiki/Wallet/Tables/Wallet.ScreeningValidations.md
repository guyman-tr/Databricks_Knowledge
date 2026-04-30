# Wallet.ScreeningValidations

> Records compliance screening results from the transaction screening provider (distinct from Chainalysis AML), capturing the case ID, screening outcome, and beneficiary information for regulatory compliance.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active NC (1 unique constraint) + 1 clustered PK |

---

## 1. Business Meaning

This table records results from a secondary compliance screening system (separate from Chainalysis-based AML in Wallet.AmlValidations). Each row represents a screening case evaluation for a transaction, capturing the screening provider's case ID, result, and whether the decision was positive (transaction approved). With 6,496 rows, this is used for a subset of transactions requiring additional compliance checks.

The screening captures personally identifiable information (FirstName, LastName) of the beneficiary for regulatory reporting. The `IsSend` flag indicates direction (outbound screening for send transactions, inbound for receives). The `FinalStatus` flag indicates whether this is the final screening decision or an interim check.

Rows are created by `Wallet.InsertScreeningValidation`.

---

## 2. Business Logic

### 2.1 Screening Decision Flow

**What**: Each screening produces a decision that gates transaction execution.

**Columns/Parameters Involved**: `IsPositiveDecision`, `FinalStatus`, `ScreeningResult`

**Rules**:
- IsPositiveDecision=1 + FinalStatus=1: Screening complete, transaction approved
- IsPositiveDecision=0 + FinalStatus=1: Screening complete, transaction blocked
- FinalStatus=0: Interim result, final decision pending
- ScreeningResult contains the provider's detailed outcome string (e.g., "Passed", "Failed")

---

## 3. Data Overview

N/A for compliance screening table. Contains PII-adjacent data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | ScreeningCaseId | nvarchar(255) | YES | - | CODE-BACKED | Screening provider's case/ticket identifier. Used for reconciliation with the screening provider's system. |
| 3 | ScreeningResult | nvarchar(50) | YES | - | CODE-BACKED | Provider's screening outcome string (e.g., "Passed", "Failed", "PendingReview"). |
| 4 | IsPositiveDecision | bit | NO | - | CODE-BACKED | Final compliance decision: 1=approved, 0=rejected. Gates transaction execution. |
| 5 | FinalStatus | bit | NO | 0 | CODE-BACKED | Whether this is the final screening decision: 1=final, 0=interim (may be updated). |
| 6 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links to the parent request. Unique constraint ensures one screening per request. |
| 7 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the user being screened. |
| 8 | IsSend | bit | NO | 1 | CODE-BACKED | Direction: 1=outbound (send screening), 0=inbound (receive screening). Default send. |
| 9 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of screening. |
| 10 | FirstName | nvarchar(255) | YES | - | CODE-BACKED | Beneficiary first name for compliance reporting. May be NULL for self-transfers. |
| 11 | LastName | nvarchar(255) | YES | - | CODE-BACKED | Beneficiary last name for compliance reporting. |
| 12 | BlockchainTransactionId | nvarchar(500) | YES | - | CODE-BACKED | Blockchain transaction hash if available at screening time. |
| 13 | ErrorMessage | nvarchar(max) | YES | - | CODE-BACKED | Error details if the screening failed technically (provider timeout, etc.). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertScreeningValidation | - | Writer | Creates screening records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertScreeningValidation | Stored Procedure | Inserts screening records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | Id ASC | - | - | Active |
| IX_ScreeningValidations_CorrelationId | NC UNIQUE | CorrelationId ASC | - | - | Active |
| IX_ScreeningValidations_Created | NC | Created ASC | - | - | Active |
| IX_ScreeningValidations_Gcid | NC | Gcid ASC | - | - | Active |
| IX_ScreeningValidations_ScreeningCaseId | NC | ScreeningCaseId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (FinalStatus) | DEFAULT | 0 - interim until finalized |
| DF (IsSend) | DEFAULT | 1 - defaults to send screening |
| DF (Created) | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Get screening result for a request
```sql
SELECT ScreeningCaseId, ScreeningResult, IsPositiveDecision, FinalStatus
FROM Wallet.ScreeningValidations WITH (NOLOCK)
WHERE CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

### 8.2 Recent failed screenings
```sql
SELECT TOP 20 Id, Gcid, ScreeningResult, Created
FROM Wallet.ScreeningValidations WITH (NOLOCK)
WHERE IsPositiveDecision = 0 AND FinalStatus = 1
ORDER BY Created DESC
```

### 8.3 Screening volume by result
```sql
SELECT ScreeningResult, COUNT(*) AS Cnt
FROM Wallet.ScreeningValidations WITH (NOLOCK)
WHERE FinalStatus = 1
GROUP BY ScreeningResult
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ScreeningValidations | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ScreeningValidations.sql*

# Dictionary.ConversionToFiatStatuses

> Lookup table defining the four possible lifecycle states for crypto-to-fiat conversion operations, used as the FK target for C2F.ConversionStatuses.StatusId.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ConversionToFiatStatuses defines the complete set of lifecycle states for crypto-to-fiat conversion operations. Each C2F conversion tracks its progress through these states in the C2F.ConversionStatuses table, which has an explicit FK to this lookup table. The four states represent the possible outcomes of a conversion request: waiting for processing, successfully completed, failed due to an error, or rejected before execution.

Without this table, there would be no canonical definition of what each status integer means. It serves as the single source of truth for conversion status values, referenced by the C2F.ConversionStatuses FK constraint and by the glossary for consistent terminology across all documentation.

The table is read-only in normal operations - values are seeded during deployment and not modified by application procedures. The Monitoring.GetOpenConversionsForLongTime procedure references this table directly.

---

## 2. Business Logic

### 2.1 Conversion Lifecycle States

**What**: Four states representing the complete outcome space for a conversion request.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- **Pending (1)**: Conversion submitted, awaiting pipeline execution. Active state.
- **Failed (2)**: Pipeline error during execution (e.g., "Crypto Transaction Failed"). Terminal state.
- **Completed (3)**: All pipeline steps succeeded, fiat credited to customer. Terminal state.
- **Rejected (4)**: Pre-execution validation failure (limit breach, compliance block). Terminal state. Zero occurrences in live data.
- InsertConversion always creates initial status as 1 (Pending)
- InsertConversionStatus transitions to 2 (Failed) or 3 (Completed)
- Query SPs filter for StatusId IN (1, 3) to find active/successful conversions
- See [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status) for glossary entry

---

## 3. Data Overview

| Id | Name | Meaning |
|----|------|---------|
| 1 | Pending | Conversion request submitted and awaiting processing. The saga pipeline is executing. Only active (non-terminal) state. 17,038 occurrences in ConversionStatuses. |
| 2 | Failed | Conversion encountered an error during execution. Common cause: "Crypto Transaction Failed" (blockchain step failure). 919 occurrences (5.4% of conversions). |
| 3 | Completed | Conversion fully executed - crypto debited from wallet, fiat credited to customer's target platform. 16,111 occurrences (94.6% success rate). |
| 4 | Rejected | Conversion rejected before execution, typically by validation (limit checks, compliance). Zero occurrences in live data - either very rare or handled at application layer before reaching DB. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int IDENTITY(1,1) | NO | IDENTITY | VERIFIED | Primary key identifying the conversion status type. Referenced by C2F.ConversionStatuses.StatusId via explicit FK. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status). |
| 2 | Name | varchar(64) | NO | - | VERIFIED | Human-readable label for the status. Maps 1:1 with Id values. Used in application code for display and logging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| C2F.ConversionStatuses | StatusId | Explicit FK | Lifecycle status for each conversion status transition |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| C2F.ConversionStatuses | Table | StatusId FK target |
| C2F.InsertConversion | Stored Procedure | Inserts StatusId=1 into ConversionStatuses |
| C2F.InsertConversionStatus | Stored Procedure | Inserts status transitions |
| C2F.GetConversionAmounts | Stored Procedure | Filters StatusId IN (1, 3) |
| C2F.GetConversionsUsdSum | Stored Procedure | Filters StatusId IN (1, 3) |
| Monitoring.GetOpenConversionsForLongTime | Stored Procedure | References this table directly |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ConversionToFiatStatuses_Id | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ConversionToFiatStatuses_Id | PRIMARY KEY | Identity PK. DATA_COMPRESSION = PAGE. |

---

## 8. Sample Queries

### 8.1 List all conversion statuses
```sql
SELECT Id, Name FROM Dictionary.ConversionToFiatStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Conversion count by status
```sql
SELECT ds.Id, ds.Name, COUNT(cs.Id) AS StatusCount
FROM Dictionary.ConversionToFiatStatuses ds WITH (NOLOCK)
LEFT JOIN C2F.ConversionStatuses cs WITH (NOLOCK) ON cs.StatusId = ds.Id
GROUP BY ds.Id, ds.Name
ORDER BY ds.Id
```

### 8.3 Find the current status for a conversion with status name
```sql
SELECT TOP 1 ds.Id, ds.Name AS Status, cs.DetailsJson, cs.Occurred
FROM C2F.ConversionStatuses cs WITH (NOLOCK)
INNER JOIN Dictionary.ConversionToFiatStatuses ds WITH (NOLOCK) ON ds.Id = cs.StatusId
WHERE cs.ConversionId = @ConversionId
ORDER BY cs.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ConversionToFiatStatuses | Type: Table | Source: WalletConversionDB/Dictionary/Tables/Dictionary.ConversionToFiatStatuses.sql*

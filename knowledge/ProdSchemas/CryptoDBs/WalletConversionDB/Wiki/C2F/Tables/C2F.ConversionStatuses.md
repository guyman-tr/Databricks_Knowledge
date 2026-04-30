# C2F.ConversionStatuses

> Append-only status history for crypto-to-fiat conversions, recording each lifecycle transition with optional error details for audit and debugging.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (PK + 3 NC) |

---

## 1. Business Meaning

C2F.ConversionStatuses records the lifecycle progression of each conversion. While the current status could be inferred from the most recent entry, this table preserves the full timeline - when the conversion started (Pending), when it completed or failed, and any error details. This provides the audit trail needed for compliance, debugging, and operational monitoring.

Without this table, there would be no status tracking for conversions. The query procedures (GetConversionAmounts, GetConversionsUsdSum) use this table to filter for active/successful conversions (StatusId IN (1, 3) - Pending or Completed) and get the most recent status via correlated subquery.

The initial Pending (1) status is created by `C2F.InsertConversion` atomically with the conversion record. Subsequent transitions are performed by `C2F.InsertConversionStatus`, which includes deduplication - it only inserts if the new status differs from the last status. The DetailsJson column captures error information for failed conversions.

---

## 2. Business Logic

### 2.1 Conversion Lifecycle States

**What**: Each conversion progresses through a simple lifecycle tracked by StatusId.

**Columns/Parameters Involved**: `StatusId`, `ConversionId`, `DetailsJson`

**Rules**:
- Every conversion starts as Pending (1) - created by InsertConversion
- Successful conversions transition to Completed (3) - 94.6% of conversions
- Failed conversions transition to Failed (2) - 5.4% of conversions (DetailsJson contains error: e.g., "Crypto Transaction Failed")
- Rejected (4) status exists in Dictionary but has 0 occurrences in live data
- Distribution: 17,038 Pending + 16,111 Completed + 919 Failed = 34,068 rows
- See [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status) for full status definitions

### 2.2 Dedup-Protected Status Transitions

**What**: InsertConversionStatus only inserts if the new status differs from the last recorded status.

**Columns/Parameters Involved**: `StatusId`, `ConversionId`

**Rules**:
- Queries the last StatusId for the conversion (ORDER BY Occurred DESC)
- Only inserts if @StatusId != @LastStatus
- Returns @@rowcount on success, -1 if status is unchanged (idempotent)
- Prevents duplicate status entries from retry scenarios

### 2.3 Most-Recent-Status Pattern in Queries

**What**: Query SPs use a correlated subquery pattern to get the current (latest) status for each conversion.

**Columns/Parameters Involved**: `Id`, `ConversionId`, `StatusId`

**Rules**:
- Pattern: `cs.Id = (SELECT TOP 1 cs2.Id FROM ConversionStatuses cs2 WHERE cs.ConversionId = cs2.ConversionId ORDER BY cs2.Id DESC)`
- Used by GetConversionAmounts and GetConversionsUsdSum to filter for active conversions
- Filters for StatusId IN (1, 3) - Pending or Completed (excludes Failed and Rejected)

---

## 3. Data Overview

| Id | ConversionId | StatusId | Details | Occurred | Meaning |
|----|-------------|----------|---------|----------|---------|
| 34067 | 17039 | 1 (Pending) | NULL | 2026-04-15 09:02:19 | Conversion 17039 initiated. Every conversion starts with this Pending entry. |
| 34068 | 17039 | 3 (Completed) | NULL | 2026-04-15 09:06:01 | Conversion 17039 completed ~4 minutes after creation. Crypto sold, fiat routed. |
| 34066 | 17038 | 2 (Failed) | {"ErrorMessage":"Crypto Transaction Failed"} | 2026-04-15 08:58:39 | Conversion 17038 failed - the blockchain transaction could not be completed. DetailsJson captures the error message. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | VERIFIED | Auto-incrementing PK. Used in correlated subqueries to find the most recent status (ORDER BY Id DESC). Higher Id = more recent transition. |
| 2 | ConversionId | bigint | NO | - | VERIFIED | FK to C2F.Conversions.Id. Links each status entry to its parent conversion. Multiple rows per ConversionId (one per transition, typically 2). Indexed for efficient history lookups. |
| 3 | StatusId | int | NO | - | VERIFIED | FK to Dictionary.ConversionToFiatStatuses. Current status in this transition. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status). Included in NC index on ConversionId for covering queries. |
| 4 | DetailsJson | varchar(max) | YES | - | VERIFIED | JSON payload with additional context for this transition. Populated for Failed statuses with error details (e.g., `{"ErrorMessage":"Crypto Transaction Failed"}`). NULL for Pending and Completed transitions. Set by InsertConversionStatus; empty strings converted to NULL. |
| 5 | Occurred | datetime2(7) | NO | GETUTCDATE() | VERIFIED | UTC timestamp of the status transition. Default constraint auto-sets on insert. Indexed DESC for recency queries. Used by InsertConversionStatus to find the last status (ORDER BY Occurred DESC). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConversionId | C2F.Conversions | Explicit FK | Links status entry to parent conversion |
| StatusId | Dictionary.ConversionToFiatStatuses | Explicit FK | Status value definition (Pending, Failed, Completed, Rejected) |

### 5.2 Referenced By (other objects point to this)

No other tables reference this table directly. Query SPs JOIN to it for status filtering.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| C2F.InsertConversion | Stored Procedure | WRITER - creates initial Pending status |
| C2F.InsertConversionStatus | Stored Procedure | WRITER - creates subsequent status transitions |
| C2F.GetConversionAmounts | Stored Procedure | READER - JOIN for status filtering |
| C2F.GetConversionSummary | Stored Procedure | READER - subquery for current status |
| C2F.GetConversionsUsdSum | Stored Procedure | READER - JOIN for status filtering |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ConversionStatuses_Id | CLUSTERED | Id ASC | - | - | Active |
| IX_C2F_ConversionStatuses_ConversionId_Inc | NC | ConversionId ASC | StatusId | - | Active |
| IX_ConversionStatuses_ConversionId | NC | ConversionId ASC | - | - | Active |
| IX_ConversionStatuses_Occurred | NC | Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ConversionStatuses_Id | PRIMARY KEY | Identity PK for chronological ordering |
| FK_C2F_ConversionStatuses_ConversionId_C2F_Conversions_Id | FOREIGN KEY | ConversionId -> C2F.Conversions.Id |
| FK_C2F_ConversionStatuses_StatusId_Dictionary_ConversionToFiatStatuses_Id | FOREIGN KEY | StatusId -> Dictionary.ConversionToFiatStatuses.Id |
| Conversion_ConversionStatuses_Occurred | DEFAULT | GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get full status history for a conversion
```sql
SELECT cs.Id, ds.Name AS Status, cs.DetailsJson, cs.Occurred
FROM C2F.ConversionStatuses cs WITH (NOLOCK)
INNER JOIN Dictionary.ConversionToFiatStatuses ds WITH (NOLOCK) ON ds.Id = cs.StatusId
WHERE cs.ConversionId = @ConversionId
ORDER BY cs.Occurred ASC
```

### 8.2 Get current status for a conversion (most recent)
```sql
SELECT TOP 1 cs.StatusId, ds.Name AS Status, cs.DetailsJson, cs.Occurred
FROM C2F.ConversionStatuses cs WITH (NOLOCK)
INNER JOIN Dictionary.ConversionToFiatStatuses ds WITH (NOLOCK) ON ds.Id = cs.StatusId
WHERE cs.ConversionId = @ConversionId
ORDER BY cs.Id DESC
```

### 8.3 Find all failed conversions with error details
```sql
SELECT c.Id, c.Gcid, c.CorrelationId, cs.DetailsJson, cs.Occurred
FROM C2F.ConversionStatuses cs WITH (NOLOCK)
INNER JOIN C2F.Conversions c WITH (NOLOCK) ON c.Id = cs.ConversionId
WHERE cs.StatusId = 2
ORDER BY cs.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.ConversionStatuses | Type: Table | Source: WalletConversionDB/C2F/Tables/C2F.ConversionStatuses.sql*

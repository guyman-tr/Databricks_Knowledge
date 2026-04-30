# History.ManualOperationPositionClose_Crisis

> Synonym providing local-schema access to DB_Logs.History.ManualOperationPositionClose_Crisis - the audit log table for manual/emergency "crisis" position close operations initiated by operators, capturing who initiated the operation and why.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | Alias: DB_Logs.History.ManualOperationPositionClose_Crisis |
| **Partition** | N/A (resolves to target in DB_Logs) |
| **Indexes** | N/A (resolves to target in DB_Logs) |

---

## 1. Business Meaning

`History.ManualOperationPositionClose_Crisis` is a cross-database synonym pointing to `DB_Logs.History.ManualOperationPositionClose_Crisis`. The underlying table is an audit log for manual/emergency "crisis" operations - scenarios where operators must force-close positions outside the normal automated trading flow (e.g., during market dislocations, system incidents, or regulatory interventions).

From `History.InsertManualOperationPositionClose_Crisis` usage, each log row captures: an auto-generated OperationID (IDENTITY, returned to callers as @@IDENTITY), the operator's username (UserName), the reason code for the manual operation (ManualOperationReasonID, mapped from @AuditClosePositionReasonID), and a free-text description of what was done (OperationDescription).

The "ManualOperation" prefix distinguishes this from `History.ManualPositionClose_Crisis` (which logs individual position records). This table logs the *operation* (the top-level admin action), while ManualPositionClose_Crisis likely logs the *positions* closed within each operation.

---

## 2. Business Logic

### 2.1 Crisis Operation Audit

**What**: Each INSERT records one manual crisis close operation initiated by an operator, with the reason and description.

**Columns/Parameters Involved**: OperationID (IDENTITY), UserName, ManualOperationReasonID, OperationDescription

**Rules**:
- WrittenVia History.InsertManualOperationPositionClose_Crisis
- OperationID is IDENTITY-generated and returned to the caller (@@IDENTITY) to link individual positions in ManualPositionClose_Crisis to this operation record
- ManualOperationReasonID (mapped from @AuditClosePositionReasonID) provides a structured reason code; -1 is the default value for unspecified reason
- OperationDescription provides free-text context for the operation

---

## 3. Data Overview

N/A for Synonym (target table is in DB_Logs).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym) | - | - | - | CODE-BACKED | Synonym resolves to DB_Logs.History.ManualOperationPositionClose_Crisis. Target columns inferred from History.InsertManualOperationPositionClose_Crisis: OperationID (IDENTITY, returned as @@IDENTITY), UserName (varchar(255)), ManualOperationReasonID (int, from @AuditClosePositionReasonID), OperationDescription (varchar(2000)). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.History.ManualOperationPositionClose_Crisis | Synonym | All operations redirect to this target in DB_Logs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.InsertManualOperationPositionClose_Crisis | INSERT | Writer | Inserts one record per crisis close operation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ManualOperationPositionClose_Crisis (synonym)
└── DB_Logs.History.ManualOperationPositionClose_Crisis (table - external database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.ManualOperationPositionClose_Crisis | Table (external DB) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.InsertManualOperationPositionClose_Crisis | Procedure | Writes crisis operation audit entries |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Show recent crisis close operations

```sql
SELECT TOP 20 *
FROM History.ManualOperationPositionClose_Crisis WITH (NOLOCK)
ORDER BY OperationID DESC
```

### 8.2 Find operations by a specific user

```sql
SELECT *
FROM History.ManualOperationPositionClose_Crisis WITH (NOLOCK)
WHERE UserName = 'admin_user'
ORDER BY OperationID DESC
```

### 8.3 Find operations with a specific reason code

```sql
SELECT *
FROM History.ManualOperationPositionClose_Crisis WITH (NOLOCK)
WHERE ManualOperationReasonID = 5
ORDER BY OperationID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/6 applicable (synonym)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.ManualOperationPositionClose_Crisis | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.ManualOperationPositionClose_Crisis.sql*

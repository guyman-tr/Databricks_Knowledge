# Dictionary.ReopenType

> Lookup table defining CopyTrading mirror reopen operation types — used by Trade.ReopenOperation and Trade.MirrorsReopen to classify how copy positions are reopened after disruptions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (TINYINT, PK) |
| **Partition** | DICTIONARY filegroup (PAGE compressed) |
| **Indexes** | 1 active (PK clustered, page-compressed) |

---

## 1. Business Meaning

Dictionary.ReopenType classifies the types of reopen operations in the CopyTrading system. When a copy relationship is disrupted (e.g., by a system event, settlement change, or corporate action), the copied positions may need to be reopened. This table defines the categories of such reopen operations.

Referenced by Trade.ReopenOperation and Trade.MirrorToReopen tables, consumed by Trade.MirrorsReopen and Trade.ReopenOperationAdd stored procedures. No live data was queryable (table may be empty or contain minimal configuration data).

---

## 2. Business Logic

### 2.1 Reopen Operation Categories

**What**: Each type classifies the reason/method for reopening a copy position.

**Columns/Parameters Involved**: `ID`, `ReopenType`

**Rules**:
- The ReopenType column uses varchar(15), suggesting short descriptive labels.
- Reopen operations are triggered by Trade.MirrorsReopen procedure.
- Each reopen record in Trade.ReopenOperation stores the type for audit and processing logic.

---

## 3. Data Overview

Live data query returned no results or was unavailable. Table structure exists in SSDT for extensibility.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | tinyint | NO | - | VERIFIED | Primary key. Small integer for reopen operation type classification. |
| 2 | ReopenType | varchar(15) | NO | - | VERIFIED | Short label for the reopen operation category. Used in Trade.ReopenOperation for classification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ReopenOperation | ReopenTypeID | Implicit | Stores reopen type per operation |
| Trade.MirrorToReopen | ReopenTypeID | Implicit | Queued mirrors pending reopen |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReopenOperation | Table | Stores reopen type per operation |
| Trade.MirrorToReopen | Table | Pending reopen queue |
| Trade.MirrorsReopen | Stored Procedure | Processes mirror reopens |
| Trade.ReopenOperationAdd | Stored Procedure | Writer — creates reopen records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ReopenType | CLUSTERED PK | ID ASC | - | - | Active (FF=95, PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_ReopenType | PRIMARY KEY | Unique reopen type identifier |

---

## 8. Sample Queries

### 8.1 List all reopen types
```sql
SELECT  ID,
        ReopenType
FROM    [Dictionary].[ReopenType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find reopen operations by type
```sql
SELECT  ro.*, rt.ReopenType
FROM    [Trade].[ReopenOperation] ro WITH (NOLOCK)
JOIN    [Dictionary].[ReopenType] rt WITH (NOLOCK) ON ro.ReopenTypeID = rt.ID;
```

### 8.3 Count pending reopens by type
```sql
SELECT  rt.ReopenType,
        COUNT(*) AS PendingCount
FROM    [Trade].[MirrorToReopen] mtr WITH (NOLOCK)
JOIN    [Dictionary].[ReopenType] rt WITH (NOLOCK) ON mtr.ReopenTypeID = rt.ID
GROUP BY rt.ReopenType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ReopenType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ReopenType.sql*

# dbo.__RefactorLog

> SSDT internal table tracking applied refactoring operations (renames, moves) to prevent duplicate application during deployment.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | OperationKey (UNIQUEIDENTIFIER, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.__RefactorLog is an SSDT (SQL Server Data Tools) infrastructure table that tracks which refactoring operations have been applied to the database. Each refactoring operation (e.g., column rename, table move) generates a unique GUID. This table prevents the same operation from being applied twice during incremental deployments.

---

## 2. Business Logic

No business logic. SSDT deployment infrastructure.

---

## 3. Data Overview

N/A - deployment metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationKey | uniqueidentifier | NO | - | CODE-BACKED | Primary key. GUID identifying a specific refactoring operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed - SSDT infrastructure.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

SSDT deployment engine reads this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | OperationKey | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View applied refactorings
```sql
SELECT OperationKey FROM dbo.__RefactorLog WITH (NOLOCK)
```

### 8.2 Count operations
```sql
SELECT COUNT(*) AS RefactorCount FROM dbo.__RefactorLog WITH (NOLOCK)
```

### 8.3 Check if operation was applied
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.__RefactorLog WHERE OperationKey = @OpKey) THEN 1 ELSE 0 END AS Applied
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.__RefactorLog | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.__RefactorLog.sql*

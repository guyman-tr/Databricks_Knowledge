# Trade.AlertSplitTreeEndedWithErrorDemo

> Sends an email alert listing copy-trading trees that failed during a stock split operation, identified by SplitID. Companion to AlertSplitPositionEndedWithError for tree-level errors.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID (INT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure reports tree-level (copy-trading hierarchy) failures during stock split operations. While `Trade.AlertSplitPositionEndedWithError` reports individual position failures, this procedure reports failures at the copy-trading tree level from `History.TreeSplitError`. A tree failure means the split operation could not propagate correctly through a copy-trading hierarchy (leader -> copiers).

The "Demo" suffix suggests this may be an experimental or staging version, but it exists in the production SSDT project.

The procedure reads all tree errors for the given SplitID, formats them as HTML (TreeID, SplitID, InsertDate, ErrorMessage), and emails to the address from Maintenance.Feature (FeatureID=116). Structure is nearly identical to AlertSplitPositionEndedWithError.

---

## 2. Business Logic

### 2.1 Tree Split Error Notification

**What**: Reports copy-trading trees that failed during a split.

**Rules**:
- Reads from History.TreeSplitError WHERE SplitID = @SplitID with OPTION(RECOMPILE)
- Email sent if HTML differs from empty template
- Recipient from Maintenance.Feature FeatureID=116
- Uses default mail profile

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | CODE-BACKED | The stock split operation identifier. Maps to History.TreeSplitError.SplitID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.TreeSplitError | READER | Tree-level split errors for the given SplitID |
| SELECT | Maintenance.Feature | READER | Email address (FeatureID=116) |
| EXEC | msdb.dbo.sp_send_dbmail | System call | HTML email alert |

### 5.2 Referenced By (other objects point to this)

Called by stock split orchestration procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertSplitTreeEndedWithErrorDemo (procedure)
+-- History.TreeSplitError (table)
+-- Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.TreeSplitError | Table | READER - tree-level split errors |
| Maintenance.Feature | Table | READER - email config |

### 6.2 Objects That Depend On This

Called by split orchestration procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check recent tree split errors

```sql
SELECT  SplitID, TreeID, InsertDate, ErrorMessage
FROM    History.TreeSplitError WITH (NOLOCK)
ORDER BY InsertDate DESC;
```

### 8.2 Run the alert for a specific split

```sql
EXEC Trade.AlertSplitTreeEndedWithErrorDemo @SplitID = 42;
```

### 8.3 Compare position vs tree split errors for same split

```sql
SELECT  'Position' AS ErrorLevel, COUNT(*) AS ErrorCount FROM History.PositionSplitError WITH (NOLOCK) WHERE SplitID = 42
UNION ALL
SELECT  'Tree', COUNT(*) FROM History.TreeSplitError WITH (NOLOCK) WHERE SplitID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertSplitTreeEndedWithErrorDemo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertSplitTreeEndedWithErrorDemo.sql*

# BackOffice.V_AuditAction

> Wraps the BackOffice.AuditAction synonym (DB_Logs audit table) and adds an extracted XML Comments field for convenient querying of audit action parameters.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | All columns from BackOffice.AuditAction + Comments |
| **Partition** | N/A |
| **Indexes** | N/A (defined on target table in DB_Logs) |

---

## 1. Business Meaning

`BackOffice.V_AuditAction` is a read-friendly wrapper over `BackOffice.AuditAction` (the synonym for `DB_Logs.BackOffice.AuditAction`). It passes through all columns with `SELECT *` and appends a `Comments` column extracted via XQuery from the `AuditActionParameters` XML field.

This view was created by Geri Reshef on 12/06/2019 for regulatory risk scoring work (RD-7582, RD-8873: "Risk scoring - Cysec Audit Jul 2019"). The CySEC audit required accessing structured audit trail data including the Comments embedded in the XML parameters. Rather than requiring every analyst or procedure to write XQuery inline, the view surfaces the Comments field as a flat column.

`BackOffice.AuditAction` is the primary audit trail for all back-office manager actions - cashout approvals, customer status changes, document reviews, and more. `V_AuditAction` makes this data more accessible for compliance queries and reporting by pre-extracting the most commonly needed XML element.

The underlying data lives in `DB_Logs.BackOffice.AuditAction` (inaccessible via current MCP credentials).

---

## 2. Business Logic

### 2.1 XML Comments Extraction

**What**: Extracts the Comments text from the structured XML in `AuditActionParameters` for convenient flat-column access.

**Columns/Parameters Involved**: `AuditActionParameters`, `Comments`

**Rules**:
- XQuery expression: `AuditActionParameters.value('(AuditParameters/Comments/text())[1]', 'varchar(max)')`
- Extracts the first `Comments` element from the `<AuditParameters><Comments>` XML path
- Returns NULL if `AuditActionParameters` is NULL, the XML has no `<Comments>` node, or the XML is malformed
- The `[1]` ensures only the first Comments node is extracted (prevents error on multi-value XML)
- Created for CySEC regulatory audit reporting (2019) - compliance reporting frequently needs audit comments

**Diagram**:
```
AuditActionParameters (XML):
  <AuditParameters>
    <Comments>Customer requested escalation to senior agent</Comments>
    ...other parameters...
  </AuditParameters>
          |
    XQuery extraction
          |
          v
  Comments = "Customer requested escalation to senior agent"
```

---

## 3. Data Overview

*Live data not available - BackOffice.AuditAction synonym targets DB_Logs database, not accessible in current environment.*

| (all AuditAction columns) | ... | AuditActionParameters | Comments |
|--------------------------|-----|----------------------|---------|
| (example row) | ... | `<AuditParameters><Comments>Approved per policy</Comments></AuditParameters>` | Approved per policy |
| (example row) | ... | `<AuditParameters><Comments></Comments></AuditParameters>` | (empty string) |
| (example row) | ... | NULL | NULL |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-N | (all columns from BackOffice.AuditAction) | (various) | (various) | - | CODE-BACKED | All columns pass through via `SELECT *` from `BackOffice.AuditAction` (NOLOCK). Key columns include: ActionTime (when the action occurred), ManagerID (who performed it), AuditActionTypeID (what type of action), AuditActionParameters (XML with action details), CID/GCID (affected customer). See [BackOffice.AuditAction](../Synonyms/BackOffice.AuditAction.md) for full column documentation. |
| N+1 | Comments | VARCHAR(MAX) (computed) | YES | - | VERIFIED | Free-text comments extracted from the `AuditActionParameters` XML field. XQuery: `AuditActionParameters.value('(AuditParameters/Comments/text())[1]','varchar(max)')`. Contains the narrative explanation for the audit action (e.g., reason for approval, notes from the reviewing manager). NULL when AuditActionParameters is NULL or contains no Comments node. Added for CySEC audit regulatory reporting (RD-7582/8873, June 2019). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns + Comments | BackOffice.AuditAction | Source (Synonym -> DB_Logs.BackOffice.AuditAction, NOLOCK) | All data originates from this synonym which maps to the audit trail table in the DB_Logs database. |

### 5.2 Referenced By (other objects point to this)

No active dependents found in the BackOffice schema (CySEC compliance queries likely run directly from BI tools or ad-hoc SQL).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.V_AuditAction (view)
└── BackOffice.AuditAction (synonym)
      └── DB_Logs.BackOffice.AuditAction (table - separate database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AuditAction | Synonym | FROM clause (NOLOCK, alias A) - all columns pass through; XQuery applied to AuditActionParameters |

### 6.2 Objects That Depend On This

No active dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Indexes are on `DB_Logs.BackOffice.AuditAction`.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get recent audit actions with comments for a specific customer

```sql
SELECT ActionTime, ManagerID, AuditActionTypeID, Comments
FROM BackOffice.V_AuditAction WITH (NOLOCK)
WHERE CID = 123456
  AND Comments IS NOT NULL
ORDER BY ActionTime DESC
```

### 8.2 Find all audit actions with non-empty comments

```sql
SELECT TOP 100 ActionTime, ManagerID, CID, Comments
FROM BackOffice.V_AuditAction WITH (NOLOCK)
WHERE Comments IS NOT NULL
  AND LEN(Comments) > 0
ORDER BY ActionTime DESC
```

### 8.3 Count audit actions by type for compliance reporting

```sql
SELECT AuditActionTypeID, COUNT(*) AS ActionCount,
       SUM(CASE WHEN Comments IS NOT NULL THEN 1 ELSE 0 END) AS WithComments
FROM BackOffice.V_AuditAction WITH (NOLOCK)
GROUP BY AuditActionTypeID
ORDER BY ActionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7 (Phase 2 blocked - DB_Logs access)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.V_AuditAction | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.V_AuditAction.sql*

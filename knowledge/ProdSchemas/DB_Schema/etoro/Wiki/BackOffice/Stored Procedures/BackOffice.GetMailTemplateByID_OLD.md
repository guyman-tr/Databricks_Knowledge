# BackOffice.GetMailTemplateByID_OLD

> Returns the MailTemplateID for a given BackOffice template identifier by joining MailTemplates to the Dictionary. Superseded by GetMailTemplateIDByBackofficeTemplateID - marked OLD since 2014.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BackofficeTemplateID - the BackOffice template to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves a BackOffice template ID to its corresponding mail template ID by querying `BackOffice.MailTemplates` with an additional inner join to `Dictionary.BackofficeTemplates`. It answers: "What is the email template ID that corresponds to this BackOffice notification template?"

The procedure was created in August 2014 and is marked `_OLD`, indicating it was superseded by `BackOffice.GetMailTemplateIDByBackofficeTemplateID`, which performs the same lookup without the now-unnecessary `Dictionary.BackofficeTemplates` join. The key difference is that this version uses an INNER JOIN to the dictionary table (meaning it only returns a result if the template ID exists in both tables), while the newer version queries `BackOffice.MailTemplates` directly.

**Status**: No EXECUTE grants found in permissions files - only VIEW DEFINITION (for BI admin inspection). This procedure is not actively called by any service.

---

## 2. Business Logic

### 2.1 Two-Table Join vs Direct Lookup

**What**: The INNER JOIN to `Dictionary.BackofficeTemplates` adds a validation step that the newer SP removed.

**Columns/Parameters Involved**: `@BackofficeTemplateID`, `BackofficeTemplateID` in both tables

**Rules**:
- Returns NULL / no rows if the `@BackofficeTemplateID` exists in `BackOffice.MailTemplates` but NOT in `Dictionary.BackofficeTemplates`.
- The newer `GetMailTemplateIDByBackofficeTemplateID` skips this join, returning results even for templates not in the dictionary.
- This behavior difference is why the OLD version was deprecated - the dictionary join was causing missing results.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BackofficeTemplateID | INTEGER | NO | - | CODE-BACKED | Input parameter. The BackOffice notification template identifier. Used to find the corresponding mail system template ID in `BackOffice.MailTemplates`. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MailTemplateID | INT | YES | - | CODE-BACKED | The mail system template identifier associated with the given BackOffice template. Used by the email sending infrastructure to load the correct email template content. NULL/no rows if BackofficeTemplateID not found in both MailTemplates and Dictionary.BackofficeTemplates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BackofficeTemplateID | BackOffice.MailTemplates | Lookup (READ) | Primary source - maps BackofficeTemplateID to MailTemplateID |
| BackofficeTemplateID | Dictionary.BackofficeTemplates | Lookup (validation) | INNER JOIN validates that the template exists in the dictionary |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No EXECUTE grants - procedure not actively used. Superseded by BackOffice.GetMailTemplateIDByBackofficeTemplateID.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetMailTemplateByID_OLD (procedure)
├── BackOffice.MailTemplates (table)
└── Dictionary.BackofficeTemplates (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.MailTemplates | Table | FROM clause; source of MailTemplateID |
| Dictionary.BackofficeTemplates | Table | INNER JOIN on BackofficeTemplateID; validation that template is in dictionary |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | Superseded by BackOffice.GetMailTemplateIDByBackofficeTemplateID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN | Business filter | Only returns results when BackofficeTemplateID exists in BOTH MailTemplates and Dictionary.BackofficeTemplates |

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC BackOffice.GetMailTemplateByID_OLD @BackofficeTemplateID = 5
```

### 8.2 Equivalent direct query (preferred - use newer SP instead)

```sql
SELECT MailTemplateID
FROM BackOffice.MailTemplates WITH (NOLOCK)
WHERE BackofficeTemplateID = 5;
```

### 8.3 Verify which BackOffice templates have mail template mappings

```sql
SELECT BOMT.BackofficeTemplateID,
       BOMT.MailTemplateID,
       DBOT.Name AS TemplateName
FROM BackOffice.MailTemplates BOMT WITH (NOLOCK)
INNER JOIN Dictionary.BackofficeTemplates DBOT WITH (NOLOCK)
    ON BOMT.BackofficeTemplateID = DBOT.BackofficeTemplateID
ORDER BY BOMT.BackofficeTemplateID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetMailTemplateByID_OLD | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetMailTemplateByID_OLD.sql*

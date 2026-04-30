# AffiliateAdmin.DeleteLanguages

> Hard-deletes one or more languages that have no assigned banners, returning both deleted and skipped languages with reasons.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns deleted language IDs + skipped languages with blocking banners |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.DeleteLanguages removes language definitions from the affiliate system. Languages are used to tag banners for localization - each banner is assigned a language so affiliates can filter creative assets by their target market's language. Languages that still have banners assigned cannot be deleted.

This procedure exists because language deletion must preserve the integrity of banner-to-language relationships. The delete-if-empty pattern is identical to DeleteCategory, protecting banners from losing their language assignment.

Data flow: Admin sends LanguageIDs via `dbo.IDTableType`. The procedure identifies languages with assigned banners via JOIN to dbo.tblaff_Banners.LanguageID, deletes only unused languages from dbo.tblaff_Languages using OUTPUT, creates audit entries (SectionID=8, ActionID=3), and returns two result sets.

---

## 2. Business Logic

### 2.1 Delete-If-Empty Pattern

**What**: Only languages with no assigned banners can be deleted.

**Columns/Parameters Involved**: `@LanguageIDsToDelete`, tblaff_Languages.LanguageID, tblaff_Banners.LanguageID

**Rules**:
- Languages with banners captured in @NotDeletedLanguages
- DELETE uses OUTPUT clause for deleted LanguageIDs
- Blocked languages returned with blocking BannerIDs

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | nvarchar(250) | NO | - | CODE-BACKED | Email of the admin user. Written to AuditLog.UserEmail. |
| 2 | @LanguageIDsToDelete | dbo.IDTableType | READONLY | - | CODE-BACKED | Table-valued parameter containing LanguageIDs to delete from dbo.tblaff_Languages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | dbo.tblaff_Languages | Write | Deletes languages without banners |
| SELECT | dbo.tblaff_Banners | Read | Checks for assigned banners (deletion guard) |
| INSERT INTO | dbo.AuditLog | Write | Logs deletion with SectionID=8, ActionID=3 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.DeleteLanguages (procedure)
+-- dbo.tblaff_Languages (table)
+-- dbo.tblaff_Banners (table)
+-- dbo.AuditLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Languages | Table | DELETE target |
| dbo.tblaff_Banners | Table | JOIN to check for assigned banners |
| dbo.AuditLog | Table | INSERT for audit trail |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Delete languages
```sql
DECLARE @Langs dbo.IDTableType;
INSERT INTO @Langs (ID) VALUES (15), (16);
EXEC AffiliateAdmin.DeleteLanguages @UserEmail = 'admin@company.com', @LanguageIDsToDelete = @Langs;
```

### 8.2 Find unused languages safe to delete
```sql
SELECT l.LanguageID, l.LanguageName
FROM dbo.tblaff_Languages l WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Banners b WITH (NOLOCK) ON b.LanguageID = l.LanguageID
WHERE b.BannerID IS NULL;
```

### 8.3 View language deletion audit
```sql
SELECT ChangedOnDate, UserEmail, ReasonOfChange, ReferencedChangedID
FROM dbo.AuditLog WITH (NOLOCK)
WHERE ChangedSectionID = 8 AND ActionID = 3
ORDER BY ChangedOnDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4222 (Gil, 23/4/25).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.DeleteLanguages | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.DeleteLanguages.sql*

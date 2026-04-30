# AffiliateAdmin.UpdateInsertLanguage

> Upserts a language record with multiple fields and code uniqueness validation, returning status codes (0=code exists, 1=ID not found, -1=success) with field-level audit logging.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Return value: 0 (code exists), 1 (ID not found), -1 (success) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertLanguage upserts a language record in `tblaff_Languages` with validation of the Code field for uniqueness. The procedure manages multiple language attributes including the display name, natural name, communication flag, TLD URL, landing pages, and language code. It returns status codes indicating success or the type of validation failure, and creates field-level audit log entries for each changed attribute.

**WHY:** Languages in the affiliate system control content localization, landing page routing, and communication preferences. Each language has a unique code (e.g., "en", "de", "fr") that is used across the system for URL routing and content selection. The uniqueness validation prevents duplicate language codes that would cause routing conflicts. The detailed return codes enable the application to display specific error messages rather than generic failures.

**HOW:** The procedure first checks if the provided @Code already exists for a different language record. If so, it returns 0 (code exists) without making changes. For updates, it verifies that @LanguageID exists; if not, it returns 1 (ID not found). When validation passes, it performs the INSERT or UPDATE on `tblaff_Languages`, creates field-level audit entries for each changed field, and returns -1 (success). The audit entries capture old and new values for every modified attribute.

---

## 2. Business Logic

### 2.1 Code Uniqueness Validation
The @Code parameter (nvarchar(10)) must be unique across all language records. The procedure checks for existing records with the same code (excluding the current record on UPDATE). If a duplicate is found, return value 0 is set and the procedure exits.

### 2.2 ID Existence Validation (Update Only)
For UPDATE operations (@LanguageID > 0), the procedure verifies that the specified LanguageID exists in `tblaff_Languages`. If not found, return value 1 is set and the procedure exits.

### 2.3 Return Value Codes
- **0:** Code already exists for a different language (validation failure)
- **1:** LanguageID not found (validation failure, UPDATE only)
- **-1:** Operation completed successfully

### 2.4 Language Attribute Management
The language record includes:
- **LanguageName:** Internal/system name
- **LanguageNaturalName:** Human-readable name in the native language
- **Code:** Short code (e.g., "en", "de", "fr") for URL routing
- **IsCommunicationLanguage:** Whether this language is available for affiliate communications
- **TLDURL:** Top-level domain URL for this language
- **DefaultLandingPage:** Default landing page URL
- **TierTwoLandingPage:** Secondary/tier-two landing page URL

### 2.5 Field-Level Audit Logging
On UPDATE, each field is individually compared. Changed fields generate separate audit log entries with old value, new value, field name, user email, and reason of change. The @ReferencedChangedID and @ActionID parameters provide additional audit context.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 2 | @LanguageID | INT | No | 0 | CODE-BACKED | 0 for INSERT, >0 for UPDATE |
| 3 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 4 | @ReferencedChangedID | INT | Yes | NULL | CODE-BACKED | Referenced entity ID for audit context |
| 5 | @LanguageName | NVARCHAR(250) | Yes | NULL | CODE-BACKED | Internal/system language name |
| 6 | @IsCommunicationLanguage | BIT | Yes | NULL | CODE-BACKED | Whether available for affiliate communications |
| 7 | @ActionID | INT | Yes | NULL | CODE-BACKED | Action ID for audit context |
| 8 | @LanguageNaturalName | NVARCHAR(250) | Yes | NULL | CODE-BACKED | Native/natural language name |
| 9 | @TLDURL | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Top-level domain URL for this language |
| 10 | @DefaultLandingPage | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Default landing page URL |
| 11 | @TierTwoLandingPage | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Tier-two landing page URL |
| 12 | @Code | NVARCHAR(10) | Yes | NULL | CODE-BACKED | Unique language code (e.g., "en", "de") |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Languages` | Table | INSERT or UPDATE language record; validate Code uniqueness |
| `dbo.AuditLog` | Table | INSERT field-level audit entries |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Language management screen | Application | Create or edit languages |
| Localization configuration | Application | Language setup for content routing |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertLanguage` -> validate Code uniqueness -> validate LanguageID exists -> INSERT or UPDATE `tblaff_Languages` -> `AuditLog` (INSERT per changed field) -> RETURN status code

### 6.1 Depends On
- `dbo.tblaff_Languages` - Language record storage and uniqueness validation
- `dbo.AuditLog` - Audit trail storage

### 6.2 Depend On This
No known database dependencies. Called from application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Create a new language
DECLARE @Result INT;
EXEC @Result = AffiliateAdmin.UpdateInsertLanguage
    @UserEmail = N'admin@company.com',
    @LanguageID = 0,
    @ReasonOfChange = N'Adding Spanish language support',
    @LanguageName = N'Spanish',
    @LanguageNaturalName = N'Espanol',
    @Code = N'es',
    @IsCommunicationLanguage = 1,
    @TLDURL = N'https://es.example.com',
    @DefaultLandingPage = N'/es/welcome',
    @TierTwoLandingPage = N'/es/signup';
SELECT CASE @Result WHEN -1 THEN 'Success' WHEN 0 THEN 'Code exists' WHEN 1 THEN 'ID not found' END AS Status;
```

```sql
-- 2. Update language landing page URLs
DECLARE @Result INT;
EXEC @Result = AffiliateAdmin.UpdateInsertLanguage
    @UserEmail = N'marketing@company.com',
    @LanguageID = 5,
    @ReasonOfChange = N'Updated landing pages for Q3 campaign',
    @DefaultLandingPage = N'/de/summer-campaign',
    @TierTwoLandingPage = N'/de/summer-signup';
SELECT @Result AS ReturnCode;
```

```sql
-- 3. Attempt to create with duplicate code (expect return 0)
DECLARE @Result INT;
EXEC @Result = AffiliateAdmin.UpdateInsertLanguage
    @UserEmail = N'admin@company.com',
    @LanguageID = 0,
    @LanguageName = N'English UK',
    @Code = N'en',  -- likely already exists
    @IsCommunicationLanguage = 1;
IF @Result = 0 PRINT 'Code already exists for another language';
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4222.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertLanguage | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertLanguage.sql*

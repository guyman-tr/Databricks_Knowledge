# Apex.Form

> Version-controlled repository of JSON form schemas used in the Apex Clearing account application process, including new account forms, agreement forms, and trusted contact forms.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 unique constraint (FormName + Version) |

---

## 1. Business Meaning

Apex.Form stores the JSON schema definitions for regulatory and compliance forms that must be submitted as part of the Apex Clearing account application process. Each form has a name, version number, content hash (for integrity verification), and the full JSON body containing the form schema/definition. Multiple versions of the same form can coexist, enabling form evolution while maintaining backward compatibility.

This table is critical for the account onboarding process because Apex Clearing requires specific forms to be submitted with each account application (new account forms, margin agreements, FPSL agreements, trusted contact forms). The form schemas define what data must be collected from the user. When Apex updates their form requirements, a new version is saved here, and the application uses the latest version for new submissions while older in-progress applications may still reference earlier versions.

Data flows in through Apex.SaveForm which upserts forms by FormName+Version (returning the ID). Forms are retrieved via Apex.GetForm (by name+version for specific lookups) and Apex.GetLatestForms (which returns the most recent version of each form type using a CTE with MAX(ID) grouping). The validation error codes FormVersionMismatch, FormVersionNotWhiteListed, and FormSchemaHashWrong in Dictionary.ApexValidationError relate to form integrity checks against this table.

---

## 2. Business Logic

### 2.1 Form Version Management

**What**: Forms are versioned by name+version pair, allowing multiple versions to coexist for backward compatibility during rolling updates.

**Columns/Parameters Involved**: `FormName`, `Version`, `Hash`, `JsonBody`

**Rules**:
- The UNIQUE constraint on (FormName, Version) prevents duplicate versions of the same form
- SaveForm upserts: if FormName+Version exists, it updates the Hash and JsonBody; if new, it inserts
- GetLatestForms uses MAX(ID) per FormName to find the latest version, not MAX(Version) - assumes higher ID = later addition
- The Hash column stores a Base64-encoded SHA-256 hash of the form schema for integrity verification
- If a submitted form's hash doesn't match the stored hash, validation error FormSchemaHashWrong (ID=10) is raised

**Diagram**:
```
Form versions:
  new_account_form v5 (ID=1) -- historical
  new_account_form v6 (ID=5) -- previous
  new_account_form v7 (ID=6) -- current (returned by GetLatestForms)
  
  trusted_contact_form v1 (ID=3) -- current
  
  limited_purpose_margin_agreement_form v1 (ID=2) -- current
  
  fully_paid_securities_50_ib_50_apex_no_payment_form v2 (ID=4) -- current
```

---

## 3. Data Overview

| ID | FormName | Version | JsonBodyLen | Meaning |
|----|----------|---------|-------------|---------|
| 6 | new_account_form | 7 | 60,971 chars | Latest version of the primary account application form. The largest and most complex form - contains all fields needed to create a new Apex brokerage account (personal data, employment, disclosures, beneficiaries). |
| 4 | fully_paid_securities_50_ib_50_apex_no_payment_form | 2 | 62,149 chars | FPSL (Fully Paid Securities Lending) agreement form with 50/50 split between introducing broker and Apex. Largest form by body size. Required for FPSL program enrolment. |
| 2 | limited_purpose_margin_agreement_form | 1 | 15,426 chars | Margin agreement form for limited-purpose margin accounts. Smaller than account forms as it only covers margin-specific terms and disclosures. |
| 3 | trusted_contact_form | 1 | 3,140 chars | FINRA-required trusted contact person form. Smallest form - captures emergency contact details for regulatory compliance (SEC Rule 2165). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Used by GetLatestForms to determine the most recent version of each form (MAX(ID) per FormName). Higher ID = more recently added, even if version numbers are not strictly sequential. |
| 2 | FormName | varchar(250) | NO | - | VERIFIED | The form type identifier. Known values: "new_account_form" (primary account application), "limited_purpose_margin_agreement_form" (margin agreement), "trusted_contact_form" (FINRA trusted contact), "fully_paid_securities_50_ib_50_apex_no_payment_form" (FPSL agreement). Part of the UNIQUE constraint with Version. Used as lookup key by GetForm and SaveForm. |
| 3 | Hash | varchar(250) | YES | - | CODE-BACKED | Base64-encoded cryptographic hash of the form schema content. Used for integrity verification when forms are submitted - if the hash of the submitted form doesn't match this stored hash, validation error FormSchemaHashWrong (ID=10) or FormHashWrongInvalidHashAlgorithm (ID=11) is raised. NULL is allowed for forms that haven't been hash-verified yet. |
| 4 | JsonBody | nvarchar(max) | YES | - | CODE-BACKED | The complete JSON form schema/definition. Contains the full form structure including field definitions, validation rules, and display instructions. Sizes range from ~3KB (trusted contact) to ~62KB (FPSL agreement). Stored as NVARCHAR(MAX) to accommodate Unicode characters in form labels and descriptions. NULL is allowed but should not occur for active forms. |
| 5 | Version | int | NO | - | CODE-BACKED | The form version number. Combined with FormName in the UNIQUE constraint to allow multiple versions of the same form. The application retrieves forms by name+version for specific submissions, or uses GetLatestForms to get the current version. Version numbers may have gaps (e.g., new_account_form jumps from v5 to v7 if versions are stored selectively). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveForm | @FormName, @Version | Writer | Upserts form definitions, returns the ID |
| Apex.GetForm | @FormName, @Version | Reader | Retrieves a specific form by name and version |
| Apex.GetLatestForms | - | Reader | Retrieves the latest version of each form type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveForm | Stored Procedure | Writer - upserts form by name+version |
| Apex.GetForm | Stored Procedure | Reader - retrieves specific form version |
| Apex.GetLatestForms | Stored Procedure | Reader - gets latest version of each form |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Form | CLUSTERED PK | ID ASC | - | - | Active |
| UC_Form | NC UNIQUE | FormName ASC, Version ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Form | PRIMARY KEY | Clustered on ID - surrogate key |
| UC_Form | UNIQUE | (FormName, Version) - each form name+version combination is unique |

---

## 8. Sample Queries

### 8.1 Get the latest version of each form

```sql
;WITH LatestForms AS (
    SELECT FormName, MAX(ID) AS ID
    FROM Apex.Form WITH (NOLOCK)
    GROUP BY FormName
)
SELECT f.ID, f.FormName, f.Version, f.Hash, LEN(f.JsonBody) AS JsonBodyLength
FROM Apex.Form f WITH (NOLOCK)
INNER JOIN LatestForms lf ON f.ID = lf.ID
ORDER BY f.FormName;
```

### 8.2 Get version history for a specific form

```sql
SELECT ID, FormName, Version, Hash, LEN(JsonBody) AS JsonBodyLength
FROM Apex.Form WITH (NOLOCK)
WHERE FormName = 'new_account_form'
ORDER BY Version DESC;
```

### 8.3 Retrieve a specific form with its JSON body

```sql
SELECT ID, FormName, Version, Hash, JsonBody
FROM Apex.Form WITH (NOLOCK)
WHERE FormName = 'new_account_form' AND Version = 7;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.Form | Type: Table | Source: USABroker/Apex/Tables/Apex.Form.sql*

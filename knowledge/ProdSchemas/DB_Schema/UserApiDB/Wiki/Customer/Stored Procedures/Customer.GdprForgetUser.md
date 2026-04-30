# Customer.GdprForgetUser

> Implements the GDPR "right to be forgotten" by masking all personally identifiable information (PII) across 11 tables - current data, history, extended fields, publications, and KYC answers - replacing real values with anonymized placeholders tagged by execution ID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (user to forget) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GdprForgetUser implements the EU General Data Protection Regulation (GDPR) Article 17 "right to erasure" for the UserApiDB database. When a user requests to be forgotten, this procedure systematically masks all personally identifiable information (PII) across every table that stores user data - including both current and historical records.

This procedure is legally required for GDPR compliance. Without it, eToro could not honor user data erasure requests, exposing the company to regulatory penalties. The procedure must be thorough - it covers 11 tables across 4 schemas (Customer, History, KYC, dbo) to ensure no PII remains accessible.

The procedure is called with a GCID (user identifier) and an ExecutionID (GDPR batch tracking number). It first resolves the legacy CID from Customer.CustomerIdentification, then systematically updates: Customer.BasicUserInfo and its history (name, username, birth date), Customer.ContactUserInfo and its history (phone, email, address, city, zip, fax, mobile), Customer.UserSettings (privacy policy), dbo.GlobalCustomer (username, email), Customer.ExtendedUserField and its history (free-form values), dbo.Publications (user bio/sticky posts), and KYC.CustomerAnswers and its history (free-text answers). The masking pattern uses `Del{FieldName}_{ExecutionID}` for traceability.

---

## 2. Business Logic

### 2.1 PII Masking Strategy

**What**: Each PII field is replaced with a deterministic anonymized placeholder, not deleted, to maintain referential integrity.

**Columns/Parameters Involved**: `@ExecutionID`, all PII columns across 11 tables

**Rules**:
- Text fields are replaced with `CONCAT('Del{FieldName}_', @ExecutionID)` - e.g., `DelUserName_42`, `DelEmail_42`
- BirthDate is truncated to the first of its month via `DATEADD(m, DATEDIFF(m, 0, BirthDate), 0)` - preserves month/year for regulatory age verification while removing the exact date
- PhonePrefix and PhoneBody are set to '0' (fixed value, not execution-tagged)
- Publications Sticky and AboutMe are set to empty string (not tagged)
- The ExecutionID suffix enables audit trail - each GDPR batch can be traced back

### 2.2 Cross-Table Coverage (11 Tables, 4 Schemas)

**What**: GDPR erasure must cover ALL locations where user PII is stored - current data AND historical snapshots.

**Columns/Parameters Involved**: `@GCID`, `@CID`

**Rules**:
- Identity data (name, username, DOB): masked in Customer.BasicUserInfo AND History.BasicUserInfo
- Contact data (phone, email, address): masked in Customer.ContactUserInfo AND History.ContactUserInfo
- Extended fields (free-form user data): masked in Customer.ExtendedUserField AND Customer.ExtendedUserField_History
- KYC free-text answers: masked in KYC.CustomerAnswers AND History.CustomerAnswers
- Global customer record: masked in dbo.GlobalCustomer
- User publications/bio: cleared in dbo.Publications
- Privacy policy: updated in Customer.UserSettings (PrivacyPolicyID = 2)

**Diagram**:
```
[Customer.GdprForgetUser] (@GCID, @ExecutionID)
    |
    +--> Resolve CID from Customer.CustomerIdentification
    |
    +--> CURRENT DATA:
    |    +-- Customer.BasicUserInfo      (UserName, FirstName, LastName, MiddleName, BirthDate)
    |    +-- Customer.ContactUserInfo    (Phone, Fax, Address, Zip, City, Email, Mobile, BuildingNumber, PhonePrefix, PhoneBody)
    |    +-- Customer.UserSettings       (PrivacyPolicyID = 2)
    |    +-- Customer.ExtendedUserField  (Value)
    |    +-- dbo.GlobalCustomer          (UserName, Email)
    |    +-- dbo.Publications            (Sticky, AboutMe)
    |
    +--> HISTORICAL DATA:
    |    +-- History.BasicUserInfo        (same fields as current)
    |    +-- History.ContactUserInfo      (same fields as current)
    |    +-- Customer.ExtendedUserField_History (Value)
    |    +-- KYC.CustomerAnswers          (FreeText)
    |    +-- History.CustomerAnswers      (FreeText)
```

### 2.3 CID Resolution

**What**: Some legacy tables use CID instead of GCID, requiring a lookup.

**Columns/Parameters Involved**: `@GCID`, `@CID`

**Rules**:
- CID is resolved from Customer.CustomerIdentification WHERE GCID = @GCID
- CID is used only for dbo.Publications (which uses the legacy CID key)
- All other tables use GCID directly

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID of the user requesting GDPR erasure. Used to locate all PII records across 11 tables. |
| 2 | @ExecutionID | int | NO | - | CODE-BACKED | GDPR execution batch identifier. Appended to all masked values as a suffix (e.g., 'DelUserName_42') for audit traceability. Each GDPR processing run gets a unique ID so masked data can be traced back to the specific erasure request. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | SELECT (CID lookup) | Resolves legacy CID from GCID for tables using old key |
| (body) | Customer.BasicUserInfo | UPDATE (MODIFIER) | Masks name, username, birth date |
| (body) | Customer.ContactUserInfo | UPDATE (MODIFIER) | Masks phone, email, address, city, zip, fax, mobile |
| (body) | Customer.UserSettings | UPDATE (MODIFIER) | Sets PrivacyPolicyID = 2 |
| (body) | Customer.ExtendedUserField | UPDATE (MODIFIER) | Masks free-form field values |
| (body) | Customer.ExtendedUserField_History | UPDATE (MODIFIER) | Masks historical free-form values |
| (body) | History.BasicUserInfo | UPDATE (MODIFIER) | Masks historical name, username, birth date |
| (body) | History.ContactUserInfo | UPDATE (MODIFIER) | Masks historical phone, email, address |
| (body) | dbo.GlobalCustomer | UPDATE (MODIFIER) | Masks username and email |
| (body) | dbo.Publications | UPDATE (MODIFIER) | Clears user bio and sticky posts |
| (body) | KYC.CustomerAnswers | UPDATE (MODIFIER) | Masks KYC free-text answers |
| (body) | History.CustomerAnswers | UPDATE (MODIFIER) | Masks historical KYC free-text answers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by GDPR compliance service when processing erasure requests |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GdprForgetUser (procedure)
+-- Customer.CustomerIdentification (table) - CID lookup
+-- Customer.BasicUserInfo (table) - PII masking
+-- Customer.ContactUserInfo (table) - PII masking
+-- Customer.UserSettings (table) - privacy policy update
+-- Customer.ExtendedUserField (table) - PII masking
+-- Customer.ExtendedUserField_History (table) - PII masking
+-- History.BasicUserInfo (table) - historical PII masking
+-- History.ContactUserInfo (table) - historical PII masking
+-- dbo.GlobalCustomer (table) - PII masking
+-- dbo.Publications (table) - bio clearing
+-- KYC.CustomerAnswers (table) - PII masking
+-- History.CustomerAnswers (table) - historical PII masking
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | SELECT - resolves CID from GCID |
| Customer.BasicUserInfo | Table | UPDATE - masks name, username, birth date |
| Customer.ContactUserInfo | Table | UPDATE - masks contact information |
| Customer.UserSettings | Table | UPDATE - sets PrivacyPolicyID = 2 |
| Customer.ExtendedUserField | Table | UPDATE - masks free-form values |
| Customer.ExtendedUserField_History | Table | UPDATE - masks historical values |
| History.BasicUserInfo | Table | UPDATE - masks historical identity data |
| History.ContactUserInfo | Table | UPDATE - masks historical contact data |
| dbo.GlobalCustomer | Table | UPDATE - masks username and email |
| dbo.Publications | Table | UPDATE - clears bio content |
| KYC.CustomerAnswers | Table | UPDATE - masks free-text answers |
| History.CustomerAnswers | Table | UPDATE - masks historical answers |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from GDPR compliance application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages for the 11 UPDATE statements |

---

## 8. Sample Queries

### 8.1 Forget a single user
```sql
EXEC Customer.GdprForgetUser @GCID = 12345, @ExecutionID = 42
```

### 8.2 Verify GDPR masking was applied
```sql
SELECT GCID, UserName, FirstName, LastName, BirthDate
FROM Customer.BasicUserInfo WITH (NOLOCK)
WHERE GCID = 12345
-- Expected: UserName='DelUserName_42', FirstName='DelFirstName_42', BirthDate=first of month
```

### 8.3 Find all users processed in a GDPR execution batch
```sql
SELECT GCID, UserName
FROM Customer.BasicUserInfo WITH (NOLOCK)
WHERE UserName LIKE 'DelUserName_%'
ORDER BY GCID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Sequence GDPR](https://etoro-jira.atlassian.net/wiki/plugins/servlet/ac/com.mxgraph.confluence.plugins.diagramly/customContentViewer?content.id=11266064385) | Confluence | GDPR processing sequence diagram showing the erasure flow |
| [HLD: COAIL-3148: Make sure GDPR doesn't run duplicate work on the same users](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/11265900545) | Confluence | Architecture decision to prevent duplicate GDPR processing on the same user |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GdprForgetUser | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GdprForgetUser.sql*

# fiktivo.ValidateAffiliate

> Validates affiliate credentials (username + password) and returns the AffiliateID if valid.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID (OUTPUT - returns matched affiliate ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ValidateAffiliate authenticates affiliate partners during login to the affiliate portal. It looks up the affiliate by matching the provided username and password against the tblaff_Affiliates table, cross-referenced with tblaff_AffiliateTypes to ensure the affiliate type is valid. If a match is found, the AffiliateID is returned; otherwise, the output parameter is set to 0.

This procedure serves as the primary authentication gate for affiliate users. Unlike the CheckPassword procedure which uses encrypted password storage with symmetric keys, ValidateAffiliate performs a plaintext password comparison (LoginPassword = @Password). This represents an older authentication pattern that was likely implemented before the encrypted password infrastructure was added.

The procedure was authored by Amir Moualem on 11/01/2012 and has remained in use as part of the affiliate authentication flow.

---

## 2. Business Logic

### 2.1 Credential Validation

**What**: Validates affiliate login credentials by matching username and plaintext password, returning the AffiliateID if found.

**Columns/Parameters Involved**: @UserName, @Password, @AffiliateID, LoginName, LoginPassword, AffiliateTypeID

**Rules**:
- SELECT TOP 1 AffiliateID FROM dbo.tblaff_Affiliates, dbo.tblaff_AffiliateTypes
- WHERE tblaff_Affiliates.AffiliateTypeID = tblaff_AffiliateTypes.AffiliateTypeID (implicit join on affiliate type)
- AND LoginName = @UserName
- AND LoginPassword = @Password (plaintext comparison, not encrypted)
- If the SELECT returns NULL (no match), sets @AffiliateID = 0
- Note: Uses plaintext password comparison unlike CheckPassword which uses DecryptByKey

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | NVARCHAR(100) (IN) | NO | - | CODE-BACKED | The affiliate's login username. Matched against LoginName in tblaff_Affiliates. |
| 2 | @Password | NVARCHAR(100) (IN) | NO | - | CODE-BACKED | The affiliate's plaintext password. Matched against LoginPassword in tblaff_Affiliates (not encrypted). |
| 3 | @AffiliateID | INT (OUTPUT) | NO | 0 | CODE-BACKED | Returns the matched AffiliateID if credentials are valid. Set to 0 if no matching affiliate is found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserName, @Password | dbo.tblaff_Affiliates | SELECT | Reads LoginName, LoginPassword, and AffiliateID for credential validation |
| - | dbo.tblaff_AffiliateTypes | JOIN | Implicit join to verify affiliate type exists |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.ValidateAffiliate (procedure)
├── dbo.tblaff_Affiliates (table, cross-schema)
└── dbo.tblaff_AffiliateTypes (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table (cross-schema) | SELECT for credential matching and AffiliateID retrieval |
| dbo.tblaff_AffiliateTypes | Table (cross-schema) | JOIN to validate affiliate type exists |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Validate affiliate credentials and retrieve AffiliateID
```sql
DECLARE @AffiliateID INT
EXEC fiktivo.ValidateAffiliate
    @UserName = 'affiliate_user',
    @Password = 'affiliate_pass',
    @AffiliateID = @AffiliateID OUTPUT
SELECT @AffiliateID AS ValidatedAffiliateID
```

### 8.2 Check if an affiliate login name exists in the system
```sql
SELECT
    a.AffiliateID,
    a.LoginName,
    at.AffiliateTypeID
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
INNER JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK)
    ON a.AffiliateTypeID = at.AffiliateTypeID
WHERE a.LoginName = 'affiliate_user'
```

### 8.3 List all affiliates with their types for troubleshooting authentication
```sql
SELECT TOP 100
    a.AffiliateID,
    a.LoginName,
    at.AffiliateTypeID
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
INNER JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK)
    ON a.AffiliateTypeID = at.AffiliateTypeID
ORDER BY a.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 7.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.ValidateAffiliate | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.ValidateAffiliate.sql*

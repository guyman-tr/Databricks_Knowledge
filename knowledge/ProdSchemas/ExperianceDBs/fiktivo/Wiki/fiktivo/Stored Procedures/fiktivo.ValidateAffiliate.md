# fiktivo.ValidateAffiliate

> Authenticates an affiliate by validating their login name and password against the affiliate record, returning their AffiliateID on success.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure authenticates affiliates (not admin users - that is CheckPassword's role). Given a username and plaintext password, it queries tblaff_Affiliates JOINed to tblaff_AffiliateTypes to find a matching record. If found, it returns the AffiliateID; if not, it returns 0.

Created by Amir Moualem (11/01/2012). The JOIN to tblaff_AffiliateTypes ensures only affiliates with a valid type can authenticate. Note: this uses plaintext password comparison (LoginPassword), unlike CheckPassword which uses encrypted passwords.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple credential lookup against tblaff_Affiliates + tblaff_AffiliateTypes.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName (IN) | NVARCHAR(100) | NO | - | CODE-BACKED | Affiliate login name. Matched against tblaff_Affiliates.LoginName. |
| 2 | @Password (IN) | NVARCHAR(100) | NO | - | CODE-BACKED | Plaintext password. Matched against tblaff_Affiliates.LoginPassword. |
| 3 | @AffiliateID (OUT) | INT | NO | 0 | CODE-BACKED | Authenticated affiliate's ID. Returns 0 if authentication fails (no match found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | dbo.tblaff_Affiliates | Table read | Credential lookup by LoginName + LoginPassword. |
| (JOIN) | dbo.tblaff_AffiliateTypes | Table read | Ensures affiliate has a valid type assignment. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.ValidateAffiliate (procedure)
    ├── dbo.tblaff_Affiliates (table)
    └── dbo.tblaff_AffiliateTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | SELECT for credential verification |
| dbo.tblaff_AffiliateTypes | Table | JOIN to validate affiliate type exists |

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

### 8.1 Validate affiliate credentials
```sql
DECLARE @affId INT
EXEC fiktivo.ValidateAffiliate @UserName = N'myaffiliate', @Password = N'pass123', @AffiliateID = @affId OUTPUT
SELECT CASE WHEN @affId > 0 THEN 'Authenticated: ' + CAST(@affId AS VARCHAR) ELSE 'Failed' END
```

### 8.2 Check affiliate with type info
```sql
SELECT a.AffiliateID, a.LoginName, t.AffiliateTypeName
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes t WITH (NOLOCK) ON a.AffiliateTypeID = t.AffiliateTypeID
WHERE a.LoginName = 'myaffiliate'
```

### 8.3 Find affiliates without a valid type
```sql
SELECT a.AffiliateID, a.LoginName, a.AffiliateTypeID
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
LEFT JOIN dbo.tblaff_AffiliateTypes t WITH (NOLOCK) ON a.AffiliateTypeID = t.AffiliateTypeID
WHERE t.AffiliateTypeID IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.ValidateAffiliate | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.ValidateAffiliate.sql*

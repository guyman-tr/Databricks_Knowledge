# Customer.IsNetworkUserIDExists

> Returns a BIT output parameter indicating whether a given network UserID exists in Customer.PrivacyUniqueIdentity - checks if an external/social network identity is already registered.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserID -> @Result (OUTPUT BIT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.IsNetworkUserIDExists checks whether a network UserID (an external identity from a social network, OAuth provider, or similar) is already stored in Customer.PrivacyUniqueIdentity. Customer.PrivacyUniqueIdentity stores unique external identifiers used for duplicate account detection and social login mapping - by verifying existence before registration, the system prevents the same external identity from being linked to multiple eToro accounts.

The UserID field is an NVARCHAR(510) to accommodate the long identifiers used by social networks (Facebook, Apple, Google, etc.). The procedure was labeled "Modified" in its header comment, suggesting it was updated from an earlier version.

---

## 2. Business Logic

No complex multi-column business logic detected. See element descriptions in Section 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserID | nvarchar(510) | NO | - | VERIFIED | External/social network user identifier to check. Wide NVARCHAR(510) to accommodate OAuth and social network IDs which can be long and contain Unicode characters. Checked against Customer.PrivacyUniqueIdentity.UserID. |
| 2 | @Result | bit (OUTPUT) | NO | 0 | VERIFIED | Output parameter: 1 = this UserID already exists in Customer.PrivacyUniqueIdentity (external identity is already registered); 0 = not found (safe to register). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserID | Customer.PrivacyUniqueIdentity | Reader (EXISTS) | Checks for the presence of the external UserID to prevent duplicate registrations |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by the registration/social login service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsNetworkUserIDExists (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | EXISTS check - returns BIT result based on UserID presence |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: no SET NOCOUNT ON and no BEGIN...END block.

---

## 8. Sample Queries

### 8.1 Check if a social network UserID is already registered
```sql
DECLARE @exists BIT = 0;
EXEC Customer.IsNetworkUserIDExists
    @UserID = N'facebook_1234567890',
    @Result = @exists OUTPUT;
SELECT @exists AS NetworkUserIDExists;
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
    WHERE UserID = N'facebook_1234567890'
) THEN 1 ELSE 0 END AS NetworkUserIDExists;
```

### 8.3 Find an existing registration for a network UserID
```sql
SELECT CID, GCID, NetworkTypeID, UserID
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE UserID = N'facebook_1234567890';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsNetworkUserIDExists | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.IsNetworkUserIDExists.sql*

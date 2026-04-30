# Customer.GetUsersPrivacyPoliciesByUserNames

> Accepts a table-valued parameter of usernames and returns the CID, PrivacyPolicyID, and UserName for each matching customer using case-insensitive username matching - a batch privacy policy lookup by username.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserNames (TVP of usernames) -> CID, PrivacyPolicyID, UserName from Customer.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUsersPrivacyPoliciesByUserNames is the username-based counterpart to Customer.GetUsersPrivacyPoliciesByCIDs. Written by guy mansano on 14.07.2014, it accepts a table-valued parameter of type dbo.Typ_UserName (a TVP containing a list of username strings) and returns the CID, PrivacyPolicyID, and UserName for all matching customers. Matching is case-insensitive: the procedure uses LOWER(@UserName) compared against the Customer.Customer.UserName_LOWER column, which is the pre-lowercased copy of UserName maintained for efficient case-insensitive lookups.

This procedure is used when a list of usernames (rather than CIDs) is available - for example, when receiving a list of usernames from a third-party data source, a compliance report, or a UI-based search where users type usernames. It allows bulk privacy policy status checks without requiring a prior CID resolution step.

Data flows: Customer.CustomerStatic stores both UserName and UserName_LOWER (a persisted lowercase copy). PrivacyPolicyID comes from CustomerStatic. Both are surfaced via Customer.Customer. The procedure is read-only.

---

## 2. Business Logic

### 2.1 Case-Insensitive Username Matching via UserName_LOWER

**What**: Username lookups use a pre-lowercased column to ensure case-insensitive matching without runtime LOWER() on the column (which would prevent index use).

**Columns/Parameters Involved**: `Customer.Customer.UserName_LOWER`, `@UserNames`

**Rules**:
- The subquery applies LOWER() to each input UserName from the TVP: `LOWER(UserName)` from @UserNames
- This is compared against `UserName_LOWER` (stored lowercase) in Customer.Customer
- Example: input "JohnDoe", "JOHNDOE", "johndoe" all match the same customer whose UserName_LOWER = "johndoe"
- UserName_LOWER is a computed/stored column in Customer.CustomerStatic maintained by triggers/default - it is the index-friendly version for case-insensitive searches
- Customers whose input username does not match any UserName_LOWER are silently excluded from results

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserNames | dbo.Typ_UserName (TVP) | NO | - | CODE-BACKED | Table-Valued Parameter containing the list of usernames to look up. dbo.Typ_UserName is a user-defined table type in the dbo schema containing a single UserName (varchar/nvarchar) column. READONLY prevents modifications. The procedure applies LOWER() to each input value before matching against UserName_LOWER. |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Internal eToro Customer ID for the matched customer. Returned so the caller can link the privacy policy result back to the internal identifier for further processing. |
| 2 | PrivacyPolicyID | int | YES | - | VERIFIED | The ID of the privacy policy version the customer has accepted. NULL for customers who have not explicitly accepted a versioned policy. See Customer.GetPrivacyPolicyID for single-customer lookup and Customer.SetPrivacyPolicyID for how this is updated. |
| 3 | UserName | varchar | NO | - | VERIFIED | The customer's original-case username (not lowercased). Returned so the caller can verify which input username matched, preserving the display casing of the username as stored. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserNames -> UserName_LOWER | Customer.Customer | Reader (SELECT) | Batch case-insensitive username lookup returning PrivacyPolicyID and CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use for privacy policy compliance checks starting from usernames |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUsersPrivacyPoliciesByUserNames (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT source - filtered by UserName_LOWER IN (LOWER inputs from @UserNames), returns CID, PrivacyPolicyID, UserName |
| dbo.Typ_UserName | User Defined Type | TVP parameter type - table of UserName string values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Service account | Privacy policy compliance checks by username list |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up privacy policy for a list of usernames using TVP
```sql
DECLARE @usernames dbo.Typ_UserName;
INSERT @usernames VALUES ('johndoe'), ('JaneSmith'), ('ALICE123');
EXEC Customer.GetUsersPrivacyPoliciesByUserNames @UserNames = @usernames;
```

### 8.2 Direct equivalent query for debugging (case-insensitive)
```sql
SELECT CID, PrivacyPolicyID, UserName
FROM Customer.Customer WITH (NOLOCK)
WHERE UserName_LOWER IN ('johndoe', 'janesmith', 'alice123');
```

### 8.3 Check which input usernames had no match
```sql
-- Compare input list against results to find non-matching usernames
DECLARE @usernames dbo.Typ_UserName;
INSERT @usernames VALUES ('johndoe'), ('nonexistentuser'), ('alice123');

SELECT u.UserName AS InputUserName, c.CID, c.PrivacyPolicyID
FROM @usernames u
LEFT JOIN Customer.Customer c WITH (NOLOCK)
    ON c.UserName_LOWER = LOWER(u.UserName);
-- Rows with NULL CID = username not found in the system
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetUsersPrivacyPoliciesByUserNames | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetUsersPrivacyPoliciesByUserNames.sql*

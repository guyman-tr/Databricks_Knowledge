# Customer.GetPrivacyUniqueIdentitiesByUserIDS

> Batch-retrieves full social network identity records (including tokens and expiry) for a list of social platform UserIDs provided as XML.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserIDS XML; returns UserName, Email, GCID, CID, Token, PrivacyRecipientID, UserID, TokenExpiry |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivacyUniqueIdentitiesByUserIDS performs a batch lookup of eToro customer records by their social network UserIDs. Given an XML list of social platform identifiers (Facebook UIDs, Google sub values, etc.), it returns the full eToro identity context for each matching customer including their OAuth tokens.

The procedure is used when an external system (e.g., social login flow, fraud detection pipeline) has a set of social UserIDs and needs to resolve them to eToro customer accounts. The full output includes sensitive data: Email, Token, TokenExpiry - making this a privileged operation appropriate only for authenticated internal services.

Compared to GetPrivacyUniqueIdentitiesByUserIDSNew (the "New" variant), this version returns more complete data including GCID, Email, Token, and TokenExpiry. The "New" variant returns only UserName, CID, PrivacyRecipientID, UserID.

---

## 2. Business Logic

### 2.1 XML UserID List Parsing and Join

**What**: Shreds XML social UserIDs into a temp table and joins to PrivacyUniqueIdentity for batch resolution.

**Columns/Parameters Involved**: `@UserIDS`, `#UserIDS.UserID`, `p.UserID`

**Rules**:
- XML structure: `<Root><Identifier>1234567890</Identifier>...</Root>`
- Uses `.nodes('/Root/Identifier')` to shred - note: element name is "Identifier" not "UserID"
- UserIDs are cast to VARCHAR(MAX) in the temp table
- JOIN condition: `#UserIDS.UserID = p.UserID` - exact match on social platform UserID
- No authorization filter (no IsAuthorized=1 check) - returns all matching rows including revoked connections
- No NOLOCK on #UserIDS join (temp table - already in session scope)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserIDS | XML | NO | - | CODE-BACKED | Input: XML list of social platform UserIDs to look up. Structure: `<Root><Identifier>userId1</Identifier>...</Root>`. Note: element name is "Identifier" not "UserID". |
| 2 | UserName | varchar(20) (output) | NO | - | VERIFIED | eToro username of the customer. From Customer.Customer.UserName. |
| 3 | Email | varchar(50) (output) | YES | - | VERIFIED | Customer email address. From Customer.Customer.Email. Dynamic Data Masking may apply. Included in this variant but NOT in the New variant. |
| 4 | GCID | int (output) | YES | - | VERIFIED | Group Customer ID. From Customer.Customer.GCID. Included in this variant but NOT in the New variant. |
| 5 | CID | int (output) | NO | - | VERIFIED | Internal customer ID. From Customer.Customer.CID. |
| 6 | Token | varchar(255) (output) | YES | - | VERIFIED | OAuth access token from the social platform. From Customer.PrivacyUniqueIdentity.Token. Included in this variant but NOT in the New variant. Sensitive - restricted to privileged callers. |
| 7 | PrivacyRecipientID | int (output) | NO | - | VERIFIED | Social platform ID: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. From Customer.PrivacyUniqueIdentity. |
| 8 | UserID | varchar(255) (output) | YES | - | VERIFIED | Social platform UserID (the value used for the lookup). From Customer.PrivacyUniqueIdentity.UserID. |
| 9 | TokenExpiry | datetime (output) | YES | - | CODE-BACKED | OAuth token expiry. From Customer.PrivacyUniqueIdentity.TokenExpiry. Included in this variant but NOT in the New variant. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID join | Customer.Customer | FROM + INNER JOIN | Source of UserName, Email, GCID, CID |
| UserID match | Customer.PrivacyUniqueIdentity | INNER JOIN on p.UserID | Source of Token, PrivacyRecipientID, UserID, TokenExpiry |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivacyUniqueIdentitiesByUserIDS (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM - source of UserName, Email, GCID, CID |
| Customer.PrivacyUniqueIdentity | Table | INNER JOIN on GCID=GCID, then filtered by #UserIDS.UserID = p.UserID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No IsAuthorized filter | Behavior | Returns all matching connections including revoked (IsAuthorized=0) - unlike GetNetworkDataByCID which filters IsAuthorized=1 |

---

## 8. Sample Queries

### 8.1 Lookup eToro customers by Facebook UIDs
```sql
DECLARE @xml XML = '<Root>
  <Identifier>1234567890</Identifier>
  <Identifier>9876543210</Identifier>
</Root>'
EXEC Customer.GetPrivacyUniqueIdentitiesByUserIDS @UserIDS = @xml;
```

### 8.2 Direct query equivalent
```sql
SELECT c.UserName, c.Email, c.GCID, c.CID, p.Token, p.PrivacyRecipientID, p.UserID, p.TokenExpiry
FROM Customer.Customer c WITH (NOLOCK)
INNER JOIN Customer.PrivacyUniqueIdentity p WITH (NOLOCK) ON c.GCID = p.GCID
WHERE p.UserID IN ('1234567890', '9876543210');
```

### 8.3 Compare with New variant (reduced output)
```sql
-- Full output variant:
EXEC Customer.GetPrivacyUniqueIdentitiesByUserIDS @UserIDS = @xml;
-- Returns: UserName, Email, GCID, CID, Token, PrivacyRecipientID, UserID, TokenExpiry

-- Reduced output variant (no Email, GCID, Token, TokenExpiry):
EXEC Customer.GetPrivacyUniqueIdentitiesByUserIDSNew @UserIDS = @xml;
-- Returns: UserName, CID, PrivacyRecipientID, UserID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related SP compared | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetPrivacyUniqueIdentitiesByUserIDS | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetPrivacyUniqueIdentitiesByUserIDS.sql*

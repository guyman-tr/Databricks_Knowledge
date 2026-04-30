# Customer.GetPrivacyUniqueIdentitiesByUserIDSNew

> Reduced-output batch lookup of eToro customers by social platform UserIDs (XML list), returning only UserName, CID, PrivacyRecipientID, and UserID - no sensitive tokens or email.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserIDS XML; returns UserName, CID, PrivacyRecipientID, UserID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivacyUniqueIdentitiesByUserIDSNew is a security-hardened variant of GetPrivacyUniqueIdentitiesByUserIDS. Both procedures accept the same XML input (list of social platform UserIDs), but this "New" version deliberately omits sensitive fields: Email, GCID, Token, and TokenExpiry are not returned.

The reduced output makes this procedure safer for use in contexts where the caller needs to resolve social UserIDs to eToro accounts but does not require full identity details - for example, duplicate-detection flows that only need to know a username and CID, not the OAuth token.

The "New" naming convention indicates this replaced or supplements the older variant with a stricter data exposure policy.

---

## 2. Business Logic

### 2.1 XML UserID Batch Lookup (Reduced Output)

**What**: Resolves a list of social UserIDs to eToro customer identities, with minimal data exposure.

**Columns/Parameters Involved**: `@UserIDS`, `#UserIDS.UserID`, `p.UserID`

**Rules**:
- Identical XML parsing to GetPrivacyUniqueIdentitiesByUserIDS: `<Root><Identifier>uid</Identifier>...</Root>`
- JOIN: Customer.Customer (c) INNER JOIN Customer.PrivacyUniqueIdentity (p) on c.GCID = p.GCID
- JOIN: #UserIDS (uids) on uids.UserID = p.UserID
- No IsAuthorized filter - includes revoked connections
- No NOLOCK on PrivacyUniqueIdentity join (unlike the original variant which has WITH NOLOCK) - may take shared locks
- Output restricted to: UserName, CID, PrivacyRecipientID, UserID only

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserIDS | XML | NO | - | CODE-BACKED | Input: XML list of social platform UserIDs. Structure: `<Root><Identifier>userId</Identifier>...</Root>`. Same format as the original variant. |
| 2 | UserName | varchar(20) (output) | NO | - | VERIFIED | eToro username of the matching customer. From Customer.Customer.UserName. |
| 3 | CID | int (output) | NO | - | VERIFIED | Internal customer ID. From Customer.Customer.CID. |
| 4 | PrivacyRecipientID | int (output) | NO | - | VERIFIED | Social platform: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. From Customer.PrivacyUniqueIdentity. |
| 5 | UserID | varchar(255) (output) | YES | - | VERIFIED | Social platform UserID (the value used as lookup key). From Customer.PrivacyUniqueIdentity.UserID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID join | Customer.Customer | FROM + INNER JOIN | Source of UserName, CID |
| UserID match | Customer.PrivacyUniqueIdentity | INNER JOIN on UserID | Source of PrivacyRecipientID, UserID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivacyUniqueIdentitiesByUserIDSNew (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM - source of UserName, CID |
| Customer.PrivacyUniqueIdentity | Table | INNER JOIN on GCID then UserID - no NOLOCK hint on this table |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK on PrivacyUniqueIdentity | Locking | Unlike the original variant, this version does not apply WITH (NOLOCK) on the PrivacyUniqueIdentity join - may acquire shared locks. |
| Reduced output | Data minimization | Omits Email, GCID, Token, TokenExpiry vs. the original variant - by design for lower data exposure. |

---

## 8. Sample Queries

### 8.1 Resolve social UserIDs to eToro accounts (reduced output)
```sql
DECLARE @xml XML = '<Root>
  <Identifier>1234567890</Identifier>
  <Identifier>9876543210</Identifier>
</Root>'
EXEC Customer.GetPrivacyUniqueIdentitiesByUserIDSNew @UserIDS = @xml;
```

### 8.2 Direct query equivalent
```sql
SELECT c.UserName, c.CID, p.PrivacyRecipientID, p.UserID
FROM Customer.Customer c WITH (NOLOCK)
INNER JOIN Customer.PrivacyUniqueIdentity p ON c.GCID = p.GCID
WHERE p.UserID IN ('1234567890', '9876543210');
```

### 8.3 Use when only account ID resolution needed (not token data)
```sql
-- When caller only needs to know: "does this social UserID belong to an eToro account?"
DECLARE @xml XML = '<Root><Identifier>someUserId</Identifier></Root>'
EXEC Customer.GetPrivacyUniqueIdentitiesByUserIDSNew @UserIDS = @xml;
-- If returns rows: social account is already linked to an eToro customer
-- If empty: social account not yet linked
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related SP compared | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetPrivacyUniqueIdentitiesByUserIDSNew | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetPrivacyUniqueIdentitiesByUserIDSNew.sql*

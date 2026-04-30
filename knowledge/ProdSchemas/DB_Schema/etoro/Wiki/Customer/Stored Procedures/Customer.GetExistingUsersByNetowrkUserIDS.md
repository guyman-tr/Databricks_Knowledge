# Customer.GetExistingUsersByNetowrkUserIDS

> Batch-resolves a list of social network UserID + NetworkID pairs to eToro customer accounts via PrivacyUniqueIdentity; handles Facebook legacy URL normalization; effectively limited to Facebook connections (PrivacyRecipientID=2).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserAndNetorkIDS (XML batch of UserID+NetworkID pairs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetExistingUsersByNetowrkUserIDS (note: "Netowrk" is a typo carried from procedure creation) resolves a batch of social network user ID and network ID pairs to eToro customer accounts. It is used during social login or user discovery to find which eToro customers are linked to a given set of social platform identities.

The procedure returns customer identity fields (UserName, Email, GCID, CID) along with the matched PrivacyUniqueIdentity row. Despite the generic naming, the WHERE clause restricts results to Facebook connections only (PrivacyRecipientID = 2) with two matching modes: UserID-based for Facebook inputs, and Token-based for non-Facebook inputs that reference PrivacyRecipientID=2 records.

---

## 2. Business Logic

### 2.1 XML Shredding and Batch Resolution

**What**: Parses XML pairs of (UserID, NetworkID), then resolves them to eToro accounts via PrivacyUniqueIdentity.

**Columns/Parameters Involved**: `@UserAndNetorkIDS`, `UserID`, `NetworkID`, `PrivacyRecipientID`, `Token`

**Rules**:
- XML format: `<Root><Item><UserID>string</UserID><NetworkID>int</NetworkID></Item>...</Root>`
- Shredded into temp table #Items (UserID nvarchar(510), NetworkID INT)
- INNER JOIN to PrivacyUniqueIdentity: i.UserID = p.UserID AND i.NetworkID = p.PrivacyRecipientID
- WHERE adds two additional match modes (both restricted to PrivacyRecipientID=2):
  - Mode 1 (Facebook input, NetworkID=2): UserID match OR legacy URL match ('http://www.facebook.com/profile.php?id=' + UserID)
  - Mode 2 (non-Facebook input NetworkID != 2, but PrivacyRecipientID=2 stored): p.Token = i.UserID (treats input UserID as a Token lookup for Facebook records)
- Net effect: only Facebook PrivacyUniqueIdentity rows are returned regardless of input NetworkID
- ORDER BY ConnectDate DESC

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserAndNetorkIDS | XML | NO | - | CODE-BACKED | XML batch input. Format: `<Root><Item><UserID>{string}</UserID><NetworkID>{int}</NetworkID></Item>...</Root>`. Each item contains a social network user ID and its network code. Only Facebook (NetworkID=2) results are returned due to the WHERE logic. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| UserName | Customer.Customer.UserName | eToro username of the matched customer |
| Email | Customer.Customer.Email | Email address (PII) |
| GCID | Customer.Customer.GCID | Global Customer ID |
| CID | Customer.Customer.CID | Integer Customer ID |
| PrivacyRecipientID | Customer.PrivacyUniqueIdentity.PrivacyRecipientID | Social network code for the matched connection (will be 2=Facebook due to WHERE constraint) |
| UserID | Customer.PrivacyUniqueIdentity.UserID | The social network UserID as stored (may be legacy URL format for old Facebook records) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UserID, NetworkID | Customer.PrivacyUniqueIdentity | INNER JOIN + WHERE | Matches social identity pairs to registered customer connections |
| GCID | Customer.Customer | INNER JOIN (read) | Returns customer identity fields for matched customers |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called by social login flows).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetExistingUsersByNetowrkUserIDS (procedure)
├── Customer.PrivacyUniqueIdentity (table)
└── Customer.Customer (view)
      └── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | Social identity lookup by UserID and NetworkID |
| Customer.Customer | View | Returns customer identity fields for matched GCIDs |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Facebook-only WHERE | Scope restriction | Both OR conditions require p.PrivacyRecipientID = 2; only Facebook connections are returned |
| Legacy URL normalization | Backward compatibility | 'http://www.facebook.com/profile.php?id=' + UserID handles old stored format |
| Typo in name | Code quality | "Netowrk" typo in both procedure name and parameter name |
| ORDER BY ConnectDate DESC | Ordering | Most recently connected accounts appear first |

---

## 8. Sample Queries

### 8.1 Find eToro accounts for a batch of Facebook user IDs

```sql
EXEC Customer.GetExistingUsersByNetowrkUserIDS
    @UserAndNetorkIDS = '<Root><Item><UserID>123456789</UserID><NetworkID>2</NetworkID></Item></Root>'
```

### 8.2 Check PrivacyUniqueIdentity for a Facebook UserID

```sql
SELECT CID, GCID, UserID, Token, IsAuthorized
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE UserID = '123456789' AND PrivacyRecipientID = 2
```

### 8.3 View Facebook connection counts

```sql
SELECT COUNT(*) AS FacebookConnections, COUNT(CASE WHEN IsAuthorized=1 THEN 1 END) AS ActiveConnections
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE PrivacyRecipientID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetExistingUsersByNetowrkUserIDS | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetExistingUsersByNetowrkUserIDS.sql*

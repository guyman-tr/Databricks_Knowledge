# Customer.GetOtherUsersWithSameTokens

> Batch fraud detection procedure: given an XML list of (UserID, NetworkID) pairs, finds all other eToro customers sharing any of those social identities, applying Facebook-specific vs. generic matching logic.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (exclude self), @UserAndNetorkIDS XML; returns UserName, Email, GCID, CID, PrivacyRecipientID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetOtherUsersWithSameTokens is a batch variant of the social identity duplicate detection family. While GetOtherUsersWithSameIdentifiers checks a single token, this procedure accepts an XML batch of (UserID, NetworkID) pairs and returns ALL other eToro customers who share any of those social identities.

The procedure is used to perform a comprehensive social identity collision check: when a customer links multiple social accounts at once (or when a batch registration check is needed), this SP detects any pre-existing eToro accounts that use the same social identities.

A key business rule distinguishes Facebook from other networks: for Facebook (NetworkID=2), the match is against PrivacyUniqueIdentity.UserID (the stable Facebook UID); for all other networks, the match is against PrivacyUniqueIdentity.Token (the OAuth token). This reflects that Facebook UIDs are stable identity anchors, while other networks' UIDs may change across sessions, making token comparison more reliable.

---

## 2. Business Logic

### 2.1 XML Batch Identity Parsing

**What**: Shreds the XML input into a temp table of (UserID, NetworkID) pairs for batch processing.

**Columns/Parameters Involved**: `@UserAndNetorkIDS`, `#Items.UserID`, `#Items.NetworkID`

**Rules**:
- XML structure: `<Root><Item><UserID>12345</UserID><NetworkID>2</NetworkID></Item>...</Root>`
- Each `<Item>` node becomes one row in #Items
- UserID is nvarchar(510) in the temp table (generous for any social platform ID)
- NetworkID is INT (maps to PrivacyRecipientID)

### 2.2 Facebook vs. Non-Facebook Matching Logic

**What**: Applies platform-specific matching rules because Facebook UIDs and other network tokens have different stability characteristics.

**Columns/Parameters Involved**: `PrivacyRecipientID`, `UserID`, `Token`

**Rules**:
- Facebook (NetworkID=2): `p.PrivacyRecipientID = i.NetworkID AND i.NetworkID = 2 AND p.UserID = i.UserID`
  - Matches on stable UserID (Facebook UID does not change per session)
- Other networks (NetworkID != 2): `p.PrivacyRecipientID = i.NetworkID AND i.NetworkID != 2 AND p.Token = i.UserID`
  - Matches on Token, but the "UserID" field from the XML is compared against the stored Token column
  - This means for non-Facebook networks, the caller puts the token value in the UserID XML element
- Self-exclusion: c.GCID != @GCID prevents matching the calling customer's own accounts
- Result: all other customers sharing any identity in the batch, ordered by ConnectDate DESC

**Diagram**:
```
@UserAndNetorkIDS XML
        |
        v
#Items (UserID, NetworkID) - parsed batch
        |
        +--[NetworkID=2 (Facebook)]--> match on p.UserID = i.UserID
        |
        +--[NetworkID!=2 (others)]--> match on p.Token = i.UserID
        |
        v
Duplicates: UserName, Email, GCID, CID, PrivacyRecipientID
(WHERE c.GCID != @GCID)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Input: GCID of the current customer to exclude. Prevents self-matching in the duplicate check. |
| 2 | @UserAndNetorkIDS | XML | NO | - | CODE-BACKED | Input: XML batch of social identity pairs. Structure: `<Root><Item><UserID>...</UserID><NetworkID>2</NetworkID></Item>...</Root>`. For Facebook, UserID = Facebook UID. For other networks, UserID = OAuth token. |
| 3 | UserName | varchar(20) (output) | NO | - | VERIFIED | eToro username of a customer sharing a social identity. From Customer.Customer.UserName. |
| 4 | Email | varchar(50) (output) | YES | - | VERIFIED | Email of the matching customer. From Customer.Customer.Email. |
| 5 | GCID | int (output) | YES | - | VERIFIED | GCID of the matching customer. Used for cross-product identity tracing. |
| 6 | CID | int (output) | NO | - | VERIFIED | Internal customer ID of the matching customer. From Customer.Customer.CID. |
| 7 | PrivacyRecipientID | int (output) | NO | - | VERIFIED | Social platform of the matched identity: 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. Indicates which platform caused the duplicate detection match. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID join | Customer.Customer | FROM + WHERE c.GCID != @GCID | Source of customer identity data |
| UserID / Token matching | Customer.PrivacyUniqueIdentity | INNER JOIN (two conditions) | Duplicate social identity detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (DB role) | - | GRANT EXECUTE | BI admin access for fraud investigation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetOtherUsersWithSameTokens (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM alias 'c' - source of UserName, Email, GCID, CID |
| Customer.PrivacyUniqueIdentity | Table | INNER JOIN for social identity matching (UserID for Facebook, Token for others) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | DB Role/User | EXECUTE permission granted |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check for duplicates across Facebook and Google accounts
```sql
DECLARE @xml XML = '<Root>
  <Item><UserID>1234567890</UserID><NetworkID>2</NetworkID></Item>
  <Item><UserID>google_oauth_token_here</UserID><NetworkID>5</NetworkID></Item>
</Root>'
EXEC Customer.GetOtherUsersWithSameTokens @GCID = 1983785, @UserAndNetorkIDS = @xml;
```

### 8.2 Direct query equivalent for Facebook only
```sql
SELECT c.UserName, c.Email, c.GCID, c.CID, p.PrivacyRecipientID
FROM Customer.Customer c WITH (NOLOCK)
INNER JOIN Customer.PrivacyUniqueIdentity p ON c.GCID = p.GCID
WHERE c.GCID != 1983785
  AND p.PrivacyRecipientID = 2
  AND p.UserID = '1234567890'
ORDER BY p.ConnectDate DESC;
```

### 8.3 Find all users with duplicate social identities (any network)
```sql
SELECT p.PrivacyRecipientID, p.UserID, p.Token,
       COUNT(DISTINCT p.GCID) AS SharedByAccounts
FROM Customer.PrivacyUniqueIdentity p WITH (NOLOCK)
GROUP BY p.PrivacyRecipientID, p.UserID, p.Token
HAVING COUNT(DISTINCT p.GCID) > 1
ORDER BY SharedByAccounts DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetOtherUsersWithSameTokens | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetOtherUsersWithSameTokens.sql*

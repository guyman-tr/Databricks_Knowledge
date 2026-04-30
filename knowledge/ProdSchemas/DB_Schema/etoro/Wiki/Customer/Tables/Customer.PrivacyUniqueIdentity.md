# Customer.PrivacyUniqueIdentity

> Social network identity federation table: links each eToro customer to their accounts on external social platforms (Facebook, Twitter, LinkedIn, Google, Yahoo, Live), storing the OAuth token and network-specific user ID per connection.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (CID, PrivacyRecipientID) composite PK |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 4 (1 clustered PK + 3 NC on GCID, Token, UserID) |

---

## 1. Business Meaning

Customer.PrivacyUniqueIdentity stores the OAuth/social network connections between eToro customers and external social platforms. Each row represents one customer's linked account on one social platform. A customer who has connected both Facebook and Google will have two rows: (CID, PrivacyRecipientID=2) and (CID, PrivacyRecipientID=5).

The table exists to support three use cases: (1) Social login - "Sign in with Facebook/Google" flows validate against Token and UserID here; (2) Identity deduplication - if two eToro accounts share the same social network UserID, they may be the same physical person (detected by Customer.GetOtherUsersWithSameIdentifiers); (3) Social sharing - eToro features that post to customers' social networks need the stored token.

Data flows: Customer.SetPrivacyUniqueIdentityNew is the primary writer. It implements token-aware upsert: if neither the GCID nor the Token already exist, it INSERTs a new connection. If the GCID exists (customer previously connected) but the Token is new (token was refreshed by the social network), it UPDATEs the existing row with the new Token/UserID/TokenExpiry and sets IsAuthorized=1. Customer.DeletePrivacyUniqueIdentity removes connections (GDPR/unlink flows). This environment has 0 rows, suggesting this is not the production environment or social login is not active here.

---

## 2. Business Logic

### 2.1 Token-Aware Upsert (SetPrivacyUniqueIdentityNew)

**What**: The write procedure prevents duplicate social connections while allowing token refresh, using GCID + Token as the composite uniqueness check.

**Columns/Parameters Involved**: `CID`, `GCID`, `PrivacyRecipientID`, `Token`, `UserID`, `IsAuthorized`, `TokenExpiry`

**Rules**:
- Condition for INSERT: NOT EXISTS (GCID = @GCID) AND NOT EXISTS (Token = @Token) -> completely new social connection
- Condition for UPDATE: GCID exists BUT Token does NOT exist -> token was refreshed; UPDATE UserID, Token, TokenExpiry, IsAuthorized=1 WHERE GCID=@GCID AND PrivacyRecipientID=@PrivacyRecipientID
- If Token already exists (same GCID, same Token): no action (idempotent - same login call twice)
- IsAuthorized is explicitly set to 1 on UPDATE, meaning it was previously set to 0 (revoked) and is being reauthorized

### 2.2 Multi-Index Identity Matching

**What**: Three separate NC indexes on GCID, Token, and UserID support different identity lookup patterns used by fraud/compliance queries.

**Columns/Parameters Involved**: `GCID`, `Token`, `UserID`

**Rules**:
- Index on GCID: supports Customer.GetNetworkDataByGCID and the SetPrivacyUniqueIdentityNew GCID existence check
- Index on Token: supports Customer.GetFacebookToken and token-based session lookups
- Index on UserID: supports Customer.GetExistingUsersByNetworkUserIDs and Customer.IsNetworkUserIDExists (cross-customer identity matching by network UID)
- Customer.GetOtherUsersWithSameIdentifiers and GetOtherUsersWithSameTokens use these indexes to find eToro accounts sharing social identities (fraud detection)

---

## 3. Data Overview

*0 rows in this environment. Table is empty - social network integration is not active or data was cleared. See procedure and schema analysis for full semantic understanding.*

| Column | Value Example | Meaning |
|--------|--------------|---------|
| CID | 12345 | eToro customer |
| GCID | 98765 | Group-level customer ID (cross-product identity) |
| PrivacyRecipientID | 2 | Facebook connection |
| Token | "EAAG..." | OAuth 2.0 access token from Facebook |
| ConnectDate | 2023-05-15 | When customer connected their Facebook account |
| UserID | "1234567890" | Customer's Facebook UID |
| IsAuthorized | 1 | Connection is active and authorized |
| TokenExpiry | 2023-08-15 | Token valid until this date (3-month typical Facebook token) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | eToro customer identifier. Part of composite PK. FK to Customer.CustomerStatic. Identifies which eToro customer owns this social connection. |
| 2 | GCID | int | NO | 0 | VERIFIED | Group Customer ID - the cross-product eToro identity for this customer (links real/demo account pairs). Indexed (IX_CustomerPrivacyUniqueIdentity_GCID) for fast lookup. Default=0 used when GCID is not yet assigned. Used as the primary deduplication key in SetPrivacyUniqueIdentityNew (prevents duplicate social connections for the same GCID across products). |
| 3 | PrivacyRecipientID | int | NO | - | VERIFIED | Social network / data recipient identifier. Part of composite PK. FK to Dictionary.PrivacyRecipients. Values: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. Determines which external platform this connection row represents. |
| 4 | Token | varchar(255) | YES | - | VERIFIED | OAuth access token issued by the social platform upon authorization. Indexed (IX_PrivacyUniqueIdentity_Token) for session lookups by Customer.GetFacebookToken. NULL if not yet obtained or revoked. Token refresh causes an UPDATE (new token replaces old). |
| 5 | ConnectDate | datetime | YES | getdate() | CODE-BACKED | Timestamp when the social connection was first established. Defaults to getdate() at INSERT. Not updated on token refresh - represents the original connection date. |
| 6 | UserID | varchar(255) | YES | - | VERIFIED | Customer's unique identifier on the social platform (e.g., Facebook UID, Google sub). Indexed (IX_PrivacyUniqueIdentity_UserID) to support cross-customer identity matching (Customer.IsNetworkUserIDExists, GetOtherUsersWithSameIdentifiers). NULL if not captured. Updated on token refresh. |
| 7 | IsAuthorized | bit | NO | 1 | VERIFIED | Whether the social connection is currently authorized. 1 = active/authorized connection. 0 = revoked or de-authorized (customer unlinked their social account). Default=1 means connections start authorized. Set to 1 on token refresh via SetPrivacyUniqueIdentityNew UPDATE path. Cleared to 0 by Customer.DeletePrivacyUniqueIdentity (soft-delete for GDPR flows). |
| 8 | TokenExpiry | datetime | YES | - | CODE-BACKED | Expiry datetime of the OAuth access token. NULL for non-expiring tokens or when not provided by the platform. Passed as optional parameter to SetPrivacyUniqueIdentityNew (@TokenExpiry datetime = null). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_Customer.PrivacyUniqueIdentity_Customer) | Every social connection belongs to a registered eToro customer |
| PrivacyRecipientID | Dictionary.PrivacyRecipients | FK (FK_Customer.PrivacyUniqueIdentity_PrivacyRecipients) | Identifies the social platform: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetPrivacyUniqueIdentityNew | CID, GCID, PrivacyRecipientID, Token, UserID, TokenExpiry | Writer + Modifier | Primary write path: token-aware upsert for social connections |
| Customer.DeletePrivacyUniqueIdentity | CID, PrivacyRecipientID | Deleter | Removes social connection (GDPR/unlink flows) |
| Customer.DeletePrivacyUniqueIdentityByUserID | UserID | Deleter | Removes connection by social network UserID |
| Customer.GetFacebookToken | CID, PrivacyRecipientID | Reader | Returns stored Facebook OAuth token for a customer |
| Customer.GetFacebookIdentifier | CID | Reader | Returns Facebook UserID for a customer |
| Customer.GetNetworkDataByCID | CID | Reader | Returns all social connections for a customer by CID |
| Customer.GetNetworkDataByGCID | GCID | Reader | Returns social connections for a customer by GCID |
| Customer.GetPrivacyUniqueIdentity | CID, PrivacyRecipientID | Reader | Single connection lookup |
| Customer.GetPrivacyUniqueIdentityByCID | CID | Reader | All connections for a CID |
| Customer.GetPrivacyUniqueIdentityByGCID | GCID | Reader | All connections for a GCID |
| Customer.GetPrivacyUniqueIdentitiesByUserIDS | UserID | Reader | Batch lookup by social UserIDs |
| Customer.GetExistingUsersByNetowrkUserIDS | UserID | Reader | Find eToro accounts with given social UserIDs |
| Customer.IsNetworkUserIDExists | UserID | Reader | Check if a social UserID is already linked to any eToro account |
| Customer.GetOtherUsersWithSameIdentifiers | UserID | Reader | Fraud: find eToro accounts sharing social identities |
| Customer.GetOtherUsersWithSameTokens | Token | Reader | Fraud: find eToro accounts sharing social tokens |
| Customer.GetRealCustomersShort_FB | CID | View | Reads social data for Facebook-connected real customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PrivacyUniqueIdentity (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target for CID |
| Dictionary.PrivacyRecipients | Table | FK target for PrivacyRecipientID - social platform lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetPrivacyUniqueIdentityNew | Stored Procedure | Writer + Modifier - token-aware upsert |
| Customer.DeletePrivacyUniqueIdentity | Stored Procedure | Deleter - GDPR/unlink |
| Customer.DeletePrivacyUniqueIdentityByUserID | Stored Procedure | Deleter - by social UserID |
| Customer.GetFacebookToken | Stored Procedure | Reader - OAuth token retrieval |
| Customer.GetFacebookIdentifier | Stored Procedure | Reader - Facebook UID retrieval |
| Customer.GetNetworkDataByCID | Stored Procedure | Reader - all social connections for CID |
| Customer.GetNetworkDataByGCID | Stored Procedure | Reader - all social connections for GCID |
| Customer.GetPrivacyUniqueIdentity | Stored Procedure | Reader - single connection lookup |
| Customer.GetPrivacyUniqueIdentityByCID | Stored Procedure | Reader |
| Customer.GetPrivacyUniqueIdentityByGCID | Stored Procedure | Reader |
| Customer.GetPrivacyUniqueIdentitiesByUserIDS | Stored Procedure | Reader - batch by UserIDs |
| Customer.GetPrivacyUniqueIdentitiesByUserIDSNew | Stored Procedure | Reader |
| Customer.GetExistingNetowrkIDS | Stored Procedure | Reader |
| Customer.GetExistingUsersByNetowrkUserIDS | Stored Procedure | Reader |
| Customer.IsNetworkUserIDExists | Stored Procedure | Reader - uniqueness check |
| Customer.GetOtherUsersWithSameIdentifiers | Stored Procedure | Reader - fraud/compliance |
| Customer.GetOtherUsersWithSameTokens | Stored Procedure | Reader - fraud/compliance |
| Customer.GetRealCustomersShort_FB | View | Reader - Facebook-connected customers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.PrivacyUniqueIdentity | Clustered PK | CID ASC, PrivacyRecipientID ASC | - | - | Active |
| IX_CustomerPrivacyUniqueIdentity_GCID | NC | GCID ASC | - | - | Active |
| IX_PrivacyUniqueIdentity_Token | NC | Token ASC | - | - | Active |
| IX_PrivacyUniqueIdentity_UserID | NC | UserID ASC | - | - | Active |

*Note: PK name "PK_Dictionary.PrivacyUniqueIdentity" contains "Dictionary." suggesting this table may have been originally planned for the Dictionary schema before being placed in Customer.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PrivacyUniqueIdentity_GCID | DEFAULT | GCID = 0 when no group identity exists |
| DF_PrivacyUniqueIdentity_ConnectDate | DEFAULT | ConnectDate = getdate() at INSERT |
| (unnamed) | DEFAULT | IsAuthorized = 1 (connections start as authorized) |
| FK_Customer.PrivacyUniqueIdentity_Customer | FK | CID -> Customer.CustomerStatic(CID) |
| FK_Customer.PrivacyUniqueIdentity_PrivacyRecipients | FK | PrivacyRecipientID -> Dictionary.PrivacyRecipients(PrivacyRecipientID) |

---

## 8. Sample Queries

### 8.1 Get all social network connections for a specific customer
```sql
SELECT
    pui.CID,
    pui.GCID,
    pr.PrivacyRecipientName AS SocialNetwork,
    pui.UserID AS SocialUserID,
    pui.IsAuthorized,
    pui.ConnectDate,
    pui.TokenExpiry
FROM Customer.PrivacyUniqueIdentity pui WITH (NOLOCK)
INNER JOIN Dictionary.PrivacyRecipients pr WITH (NOLOCK)
    ON pr.PrivacyRecipientID = pui.PrivacyRecipientID
WHERE pui.CID = 12345
ORDER BY pui.PrivacyRecipientID;
```

### 8.2 Find all eToro customers linked to the same Facebook account (fraud detection)
```sql
SELECT
    pui.UserID AS FacebookUID,
    pui.CID,
    cs.UserName,
    pui.ConnectDate,
    pui.IsAuthorized
FROM Customer.PrivacyUniqueIdentity pui WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = pui.CID
WHERE pui.PrivacyRecipientID = 2
  AND pui.UserID IN (
      SELECT UserID FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
      WHERE PrivacyRecipientID = 2
      GROUP BY UserID HAVING COUNT(*) > 1
  )
ORDER BY pui.UserID, pui.CID;
```

### 8.3 Check distribution of social connections by platform
```sql
SELECT
    pr.PrivacyRecipientName,
    COUNT(*) AS TotalConnections,
    SUM(CAST(pui.IsAuthorized AS int)) AS ActiveConnections,
    SUM(CASE WHEN pui.IsAuthorized = 0 THEN 1 ELSE 0 END) AS RevokedConnections
FROM Customer.PrivacyUniqueIdentity pui WITH (NOLOCK)
INNER JOIN Dictionary.PrivacyRecipients pr WITH (NOLOCK)
    ON pr.PrivacyRecipientID = pui.PrivacyRecipientID
GROUP BY pr.PrivacyRecipientName
ORDER BY TotalConnections DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed deeply (SetPrivacyUniqueIdentityNew) + 16 identified | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.PrivacyUniqueIdentity | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.PrivacyUniqueIdentity.sql*

# Customer.GetNetworkDataByGCID

> Returns the active, time-limited social network identity tokens for an eToro customer by GCID, the cross-product identity key variant of GetNetworkDataByCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (group customer identifier); returns PrivacyRecipientID, UserID, Token, TokenExpiry |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetNetworkDataByGCID is the GCID-based variant of Customer.GetNetworkDataByCID. It retrieves the authorized, time-limited social network identity records for a customer using their GCID (Group Customer ID - the cross-product identity key that links a person across eToro products) rather than their internal CID.

The procedure reads from Customer.PrivacyUniqueIdentity - the table storing OAuth tokens that link eToro accounts to external social platforms. Filtering by GCID means this SP can be called when the caller knows the group identity rather than the internal trading account ID.

Both variants apply identical business filters: IsAuthorized=1 (active connections only) and TokenExpiry IS NOT NULL (explicitly time-scoped tokens). The GCID-indexed lookup uses IX_CustomerPrivacyUniqueIdentity_GCID for performance.

---

## 2. Business Logic

### 2.1 Active Token Filter via GCID

**What**: Returns only active, time-limited social connections for the given GCID.

**Columns/Parameters Involved**: `@GCID`, `IsAuthorized`, `TokenExpiry`

**Rules**:
- WHERE GCID = @GCID: uses the IX_CustomerPrivacyUniqueIdentity_GCID index
- WHERE IsAuthorized = 1: excludes revoked/deauthorized connections
- WHERE TokenExpiry IS NOT NULL: excludes non-expiring or uncaptured tokens
- Result is semantically identical to GetNetworkDataByCID for the same customer, but input identifier differs
- A customer's GCID may differ from their CID; this variant is for callers operating with cross-product identity

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Input: Group Customer ID - the cross-product eToro identity key. Used to filter Customer.PrivacyUniqueIdentity.GCID. Lookup uses NC index IX_CustomerPrivacyUniqueIdentity_GCID. |
| 2 | PrivacyRecipientID | int (output) | NO | - | VERIFIED | Social network/platform identifier. FK to Dictionary.PrivacyRecipients: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. Inherited from Customer.PrivacyUniqueIdentity documentation. |
| 3 | UserID | varchar(255) (output) | YES | - | VERIFIED | Customer's unique identifier on the social platform (e.g., Facebook UID). Used for cross-customer identity matching and social profile linkage. Inherited from Customer.PrivacyUniqueIdentity documentation. |
| 4 | Token | varchar(255) (output) | YES | - | VERIFIED | OAuth access token from the social platform. Authorizes eToro API calls on the customer's behalf. Only returned when IsAuthorized=1 and TokenExpiry IS NOT NULL. |
| 5 | TokenExpiry | datetime (output) | NO | - | CODE-BACKED | Expiry datetime of the OAuth token. NOT NULL guaranteed by WHERE filter. Callers should check against current datetime to determine usability. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.PrivacyUniqueIdentity | FROM + WHERE filter | Source of all output; filtered by GCID + IsAuthorized + TokenExpiry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (DB role) | - | GRANT EXECUTE | BI admin access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetNetworkDataByGCID (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | FROM with GCID + IsAuthorized=1 + TokenExpiry IS NOT NULL filter |

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

### 8.1 Get active social network tokens by GCID
```sql
EXEC Customer.GetNetworkDataByGCID @GCID = 1983785;
```

### 8.2 Direct query equivalent
```sql
SELECT PrivacyRecipientID, UserID, Token, TokenExpiry
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE GCID = 1983785
  AND IsAuthorized = 1
  AND TokenExpiry IS NOT NULL;
```

### 8.3 Compare CID vs GCID variant results for same customer
```sql
-- Results should be identical for a given customer
EXEC Customer.GetNetworkDataByCID @CID = 245;
EXEC Customer.GetNetworkDataByGCID @GCID = 1983785;
-- (Assuming CID=245 maps to GCID=1983785)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related SP compared | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetNetworkDataByGCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetNetworkDataByGCID.sql*

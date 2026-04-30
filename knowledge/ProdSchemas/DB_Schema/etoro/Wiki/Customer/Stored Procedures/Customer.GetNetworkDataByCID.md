# Customer.GetNetworkDataByCID

> Returns the active, time-limited social network identity tokens for an eToro customer by CID, used to retrieve authorized OAuth connections for social login or API integrations.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer identifier); returns PrivacyRecipientID, UserID, Token, TokenExpiry |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetNetworkDataByCID retrieves the social network identity records for a customer, filtered to only active and time-limited connections. It reads from Customer.PrivacyUniqueIdentity - the table that stores OAuth tokens linking eToro accounts to external social platforms (Facebook, Google, Twitter, LinkedIn, Yahoo, Live, Community).

The procedure is used when the caller needs to know what social accounts a customer has currently authorized, and specifically wants only connections with an explicit token expiry (i.e., time-limited OAuth tokens as opposed to long-lived or non-expiring ones). This is the CID-based variant; Customer.GetNetworkDataByGCID provides the same data by GCID.

PROD_BIadmins have execute access, indicating this is also used for analytics and compliance reporting on social login adoption.

---

## 2. Business Logic

### 2.1 Active Token Filter

**What**: Returns only social connections that are both authorized and have a defined expiry.

**Columns/Parameters Involved**: `IsAuthorized`, `TokenExpiry`

**Rules**:
- WHERE IsAuthorized = 1: excludes revoked or deauthorized connections (IsAuthorized=0)
- WHERE TokenExpiry IS NOT NULL: excludes connections where no expiry was stored (non-expiring or not captured)
- Together, these filters identify "currently active, time-scoped OAuth tokens" - the tokens the platform can use for API calls right now
- Tokens past their TokenExpiry date are still returned by this SP; the caller is responsible for expiry validation

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Input: eToro internal customer ID. Used to filter Customer.PrivacyUniqueIdentity.CID. |
| 2 | PrivacyRecipientID | int (output) | NO | - | VERIFIED | Social network/platform identifier. FK to Dictionary.PrivacyRecipients: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. Identifies which external platform the token belongs to. Inherited from Customer.PrivacyUniqueIdentity documentation. |
| 3 | UserID | varchar(255) (output) | YES | - | VERIFIED | Customer's unique identifier on the social platform (e.g., Facebook UID, Google sub). Used for cross-customer identity matching and social profile lookups. Inherited from Customer.PrivacyUniqueIdentity documentation. |
| 4 | Token | varchar(255) (output) | YES | - | VERIFIED | OAuth access token issued by the social platform. Authorizes eToro to make API calls on the customer's behalf (e.g., social sharing). Only returned when IsAuthorized=1 and TokenExpiry IS NOT NULL. |
| 5 | TokenExpiry | datetime (output) | NO | - | CODE-BACKED | Expiry datetime of the OAuth token. NOT NULL guaranteed by the WHERE clause filter. Callers should validate against current datetime to check if the token is still usable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.PrivacyUniqueIdentity | FROM + WHERE filter | Source of all output columns, filtered by CID + IsAuthorized + TokenExpiry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (DB role) | - | GRANT EXECUTE | BI admin access for analytics/reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetNetworkDataByCID (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | FROM with CID + IsAuthorized=1 + TokenExpiry IS NOT NULL filter |

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

### 8.1 Get active social network tokens for a customer
```sql
EXEC Customer.GetNetworkDataByCID @CID = 12345;
```

### 8.2 Direct query equivalent
```sql
SELECT PrivacyRecipientID, UserID, Token, TokenExpiry
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE CID = 12345
  AND IsAuthorized = 1
  AND TokenExpiry IS NOT NULL;
```

### 8.3 Check if any tokens are expired (post-execution validation)
```sql
SELECT PrivacyRecipientID, UserID, Token, TokenExpiry,
       CASE WHEN TokenExpiry < GETDATE() THEN 'EXPIRED' ELSE 'VALID' END AS TokenStatus
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE CID = 12345
  AND IsAuthorized = 1
  AND TokenExpiry IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetNetworkDataByCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetNetworkDataByCID.sql*

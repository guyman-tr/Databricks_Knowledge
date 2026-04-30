# Customer.GetFacebookToken

> Returns the OAuth Token, its expiry date, and social UserID for a customer's authorized social network connection that has a non-null token expiry; used to check if a valid, non-expired social token is available.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer whose token to retrieve) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetFacebookToken retrieves the OAuth access token, expiry date, and network UserID for a customer's authorized social network connection. It is the result-set counterpart to Customer.GetFacebookIdentifier: both read from PrivacyUniqueIdentity, but GetFacebookToken returns a richer result set and additionally requires TokenExpiry IS NOT NULL, making it suitable for callers that need to check whether a token is time-bounded (and therefore may need refresh).

Despite the "Facebook" name, there is no network filter - it returns authorized connections from any social network that has a non-null TokenExpiry. The addition of TokenExpiry IS NOT NULL distinguishes connections with known expiry (e.g., standard OAuth 2.0 tokens) from those with no expiry set (e.g., legacy or non-expiring tokens returned by GetFacebookIdentifier).

---

## 2. Business Logic

### 2.1 Token with Expiry Retrieval

**What**: Returns OAuth token data only for connections with a known expiry date.

**Columns/Parameters Involved**: `@CID`, `Token`, `TokenExpiry`, `UserID`, `IsAuthorized`

**Rules**:
- WHERE CID = @CID AND IsAuthorized = 1 AND TokenExpiry IS NOT NULL
- IsAuthorized=1: only active/authorized connections
- TokenExpiry IS NOT NULL: only returns connections where expiry is known (excludes legacy non-expiring tokens)
- No PrivacyRecipientID filter: may return multiple rows for customers with multiple networks
- Callers should check TokenExpiry against current time to determine if the token needs refreshing

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose social network token to retrieve. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| Token | Customer.PrivacyUniqueIdentity.Token | OAuth access token issued by the social platform. Used to make API calls to the social platform on behalf of the customer. varchar(255). |
| TokenExpiry | Customer.PrivacyUniqueIdentity.TokenExpiry | Expiry datetime of the OAuth token. NULL rows excluded by WHERE. Callers compare this to current datetime to determine if the token is still valid. |
| UserID | Customer.PrivacyUniqueIdentity.UserID | Customer's unique identifier on the social platform (e.g., Facebook UID, Google sub). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.PrivacyUniqueIdentity | Read | Retrieves Token, TokenExpiry, UserID for authorized connections with known expiry |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetFacebookToken (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | Source of Token, TokenExpiry, UserID filtered by CID, IsAuthorized=1, TokenExpiry IS NOT NULL |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TokenExpiry IS NOT NULL | Filter | Excludes legacy/non-expiring tokens; only returns connections with known expiry |
| IsAuthorized=1 | Business rule | Only active authorized connections; revoked tokens excluded |
| No network filter | Scope | Returns all qualifying networks; may return multiple rows |

---

## 8. Sample Queries

### 8.1 Get the OAuth token and expiry for a customer

```sql
EXEC Customer.GetFacebookToken @CID = 12345678
-- Returns Token, TokenExpiry, UserID for authorized connections with non-null expiry
```

### 8.2 Check if token is still valid

```sql
CREATE TABLE #Tokens (Token VARCHAR(255), TokenExpiry DATETIME, UserID VARCHAR(255))
INSERT INTO #Tokens EXEC Customer.GetFacebookToken @CID = 12345678
SELECT Token, TokenExpiry, UserID,
    CASE WHEN TokenExpiry > GETDATE() THEN 'Valid' ELSE 'Expired' END AS Status
FROM #Tokens WITH (NOLOCK)
DROP TABLE #Tokens
```

### 8.3 Find customers with expiring social tokens

```sql
SELECT CID, GCID, PrivacyRecipientID, TokenExpiry
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE IsAuthorized = 1 AND TokenExpiry IS NOT NULL AND TokenExpiry < DATEADD(DAY, 7, GETDATE())
ORDER BY TokenExpiry
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetFacebookToken | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetFacebookToken.sql*

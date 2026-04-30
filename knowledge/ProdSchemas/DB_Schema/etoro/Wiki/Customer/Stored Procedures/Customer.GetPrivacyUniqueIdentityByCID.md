# Customer.GetPrivacyUniqueIdentityByCID

> Returns all social network connections (platform IDs and OAuth tokens) for a customer by CID, without authorization or expiry filtering.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID; returns PrivacyRecipientID, Token for all connections |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivacyUniqueIdentityByCID retrieves all social network connections for a specific customer, identified by their internal CID. It returns the platform identifier and OAuth token for every linked social account, regardless of whether the connection is currently authorized or the token has expired.

Unlike GetNetworkDataByCID (which filters IsAuthorized=1 and TokenExpiry IS NOT NULL), this procedure returns the complete connection history including revoked and expired tokens. This makes it suitable for administrative views, GDPR data export requests, and auditing use cases where the full connection history is needed.

---

## 2. Business Logic

### 2.1 Unfiltered Social Connection Retrieval

**What**: Returns ALL social connections for a CID, including inactive ones.

**Columns/Parameters Involved**: `@CID`, `PrivacyRecipientID`, `Token`

**Rules**:
- No IsAuthorized filter: returns both authorized (1) and revoked (0) connections
- No TokenExpiry filter: returns connections with NULL or past expiry
- Result may include connections that are no longer usable for authentication
- Useful for: GDPR data export, full audit trails, admin views

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Input: Internal customer ID. Used to filter Customer.PrivacyUniqueIdentity.CID. |
| 2 | PrivacyRecipientID | int (output) | NO | - | VERIFIED | Social platform: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. From Customer.PrivacyUniqueIdentity. |
| 3 | Token | varchar(255) (output) | YES | - | VERIFIED | OAuth access token for this social connection. NULL for connections without a token. May be expired or revoked. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.PrivacyUniqueIdentity | FROM + WHERE filter | Source of all social connection data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivacyUniqueIdentityByCID (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | FROM + WHERE CID = @CID (no authorization filter) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all social connections for a customer (including revoked)
```sql
EXEC Customer.GetPrivacyUniqueIdentityByCID @CID = 12345;
```

### 8.2 Direct query equivalent
```sql
SELECT PrivacyRecipientID, Token
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Compare: all connections vs. active connections only
```sql
-- All connections (this SP):
SELECT PrivacyRecipientID, Token FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK) WHERE CID = 12345;

-- Active connections only (GetNetworkDataByCID equivalent):
SELECT PrivacyRecipientID, UserID, Token, TokenExpiry
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE CID = 12345 AND IsAuthorized = 1 AND TokenExpiry IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetPrivacyUniqueIdentityByCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetPrivacyUniqueIdentityByCID.sql*

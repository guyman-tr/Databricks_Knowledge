# Customer.GetFacebookIdentifier

> Returns the OAuth Token for a customer's authorized social network connection via an OUTPUT parameter; used to retrieve the stored access token for API calls to the connected social platform.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer whose token to retrieve) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetFacebookIdentifier retrieves the social network OAuth Token for a customer's authorized connection from Customer.PrivacyUniqueIdentity. Despite the "Facebook" name, the procedure has no network filter - it returns the Token for any authorized PrivacyUniqueIdentity row matching the CID. The Token is the OAuth access token issued by the social platform when the customer connected their account.

The procedure delivers its result via an OUTPUT parameter (@Token) rather than a result set, which is the older SQL Server pattern for single-value retrieval. This design is typical of legacy procedures where the caller captures the output value in a local variable.

---

## 2. Business Logic

### 2.1 Token Retrieval for Authorized Social Connections

**What**: Retrieves the OAuth token for an authorized social connection.

**Columns/Parameters Involved**: `@CID`, `@Token`, `IsAuthorized`, `Token`

**Rules**:
- WHERE CID = @CID AND IsAuthorized = 1: only authorized (active) connections
- No PrivacyRecipientID filter: if a customer has multiple social connections, the SET @Token assignment may return any one of them (non-deterministic)
- @Token OUTPUT parameter receives the value; NULL if no authorized connection exists
- No explicit network scoping - callers expecting Facebook-specific tokens should verify against PrivacyRecipientID=2 separately

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose social network token to retrieve. |
| 2 | @Token | VARCHAR(255) | YES | - | CODE-BACKED | OUTPUT parameter. Receives the OAuth access token from the customer's authorized PrivacyUniqueIdentity row. NULL if no authorized connection exists for the CID. Non-deterministic if multiple authorized connections exist (no network filter). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.PrivacyUniqueIdentity | Read | Retrieves Token where CID matches and IsAuthorized=1 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetFacebookIdentifier (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | Source of Token for authorized connections by CID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OUTPUT parameter | Design | Returns single value via @Token OUTPUT; caller must declare @Token variable and pass it |
| No network filter | Scope | All authorized social connections regardless of PrivacyRecipientID; non-deterministic for multi-network customers |
| IsAuthorized=1 filter | Business rule | Only returns active/authorized connections; revoked connections (IsAuthorized=0) are excluded |

---

## 8. Sample Queries

### 8.1 Get the social OAuth token for a customer

```sql
DECLARE @Token VARCHAR(255)
EXEC Customer.GetFacebookIdentifier @CID = 12345678, @Token = @Token OUTPUT
SELECT @Token AS Token
```

### 8.2 Compare with GetFacebookToken (result-set variant with expiry)

```sql
-- OUTPUT parameter variant (this procedure):
DECLARE @Token VARCHAR(255)
EXEC Customer.GetFacebookIdentifier @CID = 12345678, @Token = @Token OUTPUT
-- Result-set variant with expiry info:
EXEC Customer.GetFacebookToken @CID = 12345678
```

### 8.3 Check social connections for a customer

```sql
SELECT PrivacyRecipientID, Token, UserID, IsAuthorized, TokenExpiry
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE CID = 12345678 AND IsAuthorized = 1
-- 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetFacebookIdentifier | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetFacebookIdentifier.sql*

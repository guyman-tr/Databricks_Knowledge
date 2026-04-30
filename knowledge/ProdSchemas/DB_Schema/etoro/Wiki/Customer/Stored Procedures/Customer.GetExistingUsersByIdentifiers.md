# Customer.GetExistingUsersByIdentifiers

> Finds the most recently connected eToro customer whose social network Token matches a given identifier for a specific network; used to resolve social login tokens to eToro customer accounts.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NetworkId + @Identifier (network + token pair) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetExistingUsersByIdentifiers resolves a social network token (@Identifier) and network ID (@NetworkId) to an eToro customer account. It is used by the social login flow: when a user authenticates via a social platform and the platform returns an OAuth token or user identifier, this procedure looks up which eToro customer owns that social connection.

The procedure matches on PrivacyUniqueIdentity.Token (the OAuth access token stored when the customer connected their social account) and PrivacyRecipientID (the social network ID). ORDER BY ConnectDate DESC with TOP 1 ensures the most recently established connection is returned in the rare case of duplicate social connections.

---

## 2. Business Logic

### 2.1 Social Login Token Resolution

**What**: Maps a network-specific identifier (Token) to an eToro customer.

**Columns/Parameters Involved**: `@NetworkId`, `@Identifier`, `PrivacyRecipientID`, `Token`

**Rules**:
- WHERE p.PrivacyRecipientID = @NetworkId: filter to the specified social network (e.g., 2=Facebook, 5=Google)
- AND p.Token = @Identifier: match the OAuth token or platform-issued identifier
- IsAuthorized is NOT filtered: returns both active and revoked connections (callers should check if the account is still authorized)
- TOP 1 with ORDER BY ConnectDate DESC: returns the most recent connection if duplicates exist
- Returns 0 rows if no customer has this token on the specified network

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NetworkId | INT | NO | - | CODE-BACKED | Social network identifier. Maps to PrivacyUniqueIdentity.PrivacyRecipientID: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. |
| 2 | @Identifier | NVARCHAR(200) | NO | - | CODE-BACKED | The network-specific token or identifier. Matched against PrivacyUniqueIdentity.Token (OAuth access token). Up to 200 chars (Token column is varchar(255)). |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| UserName | Customer.Customer.UserName | eToro username of the matched customer |
| Email | Customer.Customer.Email | Email address (PII) |
| GCID | Customer.Customer.GCID | Global Customer ID |
| CID | Customer.Customer.CID | Integer Customer ID |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NetworkId, @Identifier | Customer.PrivacyUniqueIdentity | Read (WHERE filter) | Matches social network token to a customer record |
| GCID | Customer.Customer | INNER JOIN (read) | Returns customer identity fields for matched GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called by social login authentication flow).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetExistingUsersByIdentifiers (procedure)
├── Customer.PrivacyUniqueIdentity (table)
└── Customer.Customer (view)
      └── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | Token + NetworkID lookup to find linked customer GCID |
| Customer.Customer | View | Returns UserName, Email, GCID, CID for the matched GCID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 1 | Result cap | Returns single row; ORDER BY ConnectDate DESC returns most recent connection |
| No IsAuthorized filter | Design | Returns both authorized and revoked connections; caller handles authorization check |

---

## 8. Sample Queries

### 8.1 Look up a customer by Facebook token

```sql
EXEC Customer.GetExistingUsersByIdentifiers @NetworkId = 2, @Identifier = 'EAAG...'
```

### 8.2 Look up by Google token

```sql
EXEC Customer.GetExistingUsersByIdentifiers @NetworkId = 5, @Identifier = 'ya29...'
```

### 8.3 Check PrivacyUniqueIdentity network IDs

```sql
SELECT PrivacyRecipientID, COUNT(*) AS ConnectionCount
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
GROUP BY PrivacyRecipientID
ORDER BY PrivacyRecipientID
-- 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetExistingUsersByIdentifiers | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetExistingUsersByIdentifiers.sql*

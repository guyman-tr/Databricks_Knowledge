# Customer.GetPrivacyUniqueIdentity

> Looks up eToro customer identities by a batch of social OAuth tokens (passed as XML), returning full customer context including UserName, Email, GCID, CID, and network identifier.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @URLXML (XML batch of tokens); returns UserName, Email, GCID, CID, Token, PrivacyRecipientID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivacyUniqueIdentity resolves a batch of OAuth tokens to eToro customer identities. The caller provides an XML list of social platform token values, and the procedure returns the eToro accounts associated with each token.

Despite the parameter being named `@URLXML` with XML element `<URL>`, the values are OAuth tokens (not URLs). This is a legacy naming artifact - at some earlier point, the OAuth tokens or social profile URLs may have been used interchangeably. The actual match is against `PrivacyUniqueIdentity.Token`.

The procedure is used in social login flows where the token is known but the associated eToro account needs to be identified. It returns sensitive data (Email, Token) making it a privileged operation.

---

## 2. Business Logic

### 2.1 Token Batch Lookup

**What**: Resolves a set of OAuth tokens to eToro customer accounts.

**Columns/Parameters Involved**: `@URLXML`, `Token`

**Rules**:
- XML structure: `<Root><URL>tokenValue1</URL><URL>tokenValue2</URL>...</Root>`
- XML element name is "URL" but values are OAuth tokens - legacy naming
- Shreds into #URLs temp table; joins WHERE p.Token IN (SELECT URL FROM #URLs)
- No IsAuthorized filter - matches any token regardless of authorization status
- Returns all matches (no TOP N limit)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @URLXML | XML | NO | - | CODE-BACKED | Input: XML batch of OAuth token values to look up. Structure: `<Root><URL>tokenValue</URL>...</Root>`. Despite "URL" element name, values are OAuth tokens (legacy naming artifact). |
| 2 | UserName | varchar(20) (output) | NO | - | VERIFIED | eToro username of the matching customer. From Customer.Customer.UserName. |
| 3 | Email | varchar(50) (output) | YES | - | VERIFIED | Customer email. From Customer.Customer.Email. Sensitive - Dynamic Data Masking may apply. |
| 4 | GCID | int (output) | YES | - | VERIFIED | Group Customer ID. From Customer.Customer.GCID. |
| 5 | CID | int (output) | NO | - | VERIFIED | Internal customer ID. From Customer.Customer.CID. |
| 6 | Token | varchar(255) (output) | YES | - | VERIFIED | The OAuth token that matched (echoed back from input). From Customer.PrivacyUniqueIdentity.Token. |
| 7 | PrivacyRecipientID | int (output) | NO | - | VERIFIED | Social platform: 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. From Customer.PrivacyUniqueIdentity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID join | Customer.Customer | FROM | Source of UserName, Email, GCID, CID |
| Token lookup | Customer.PrivacyUniqueIdentity | INNER JOIN on GCID + Token IN | Token-based identity resolution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivacyUniqueIdentity (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM - source of UserName, Email, GCID, CID |
| Customer.PrivacyUniqueIdentity | Table | INNER JOIN on c.GCID=p.GCID; filtered WHERE p.Token IN (#URLs) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Legacy @URLXML naming | Naming artifact | Parameter and XML element named "URL" but values are OAuth tokens |
| No NOLOCK on PrivacyUniqueIdentity | Locking | Unlike sibling procedures, no NOLOCK hint on this JOIN |

---

## 8. Sample Queries

### 8.1 Resolve tokens to eToro accounts
```sql
DECLARE @xml XML = '<Root><URL>EAAGm0oW...</URL><URL>ya29.A0AfH6...</URL></Root>'
EXEC Customer.GetPrivacyUniqueIdentity @URLXML = @xml;
```

### 8.2 Direct query equivalent
```sql
SELECT c.UserName, c.Email, c.GCID, c.CID, p.Token, p.PrivacyRecipientID
FROM Customer.Customer c WITH (NOLOCK)
INNER JOIN Customer.PrivacyUniqueIdentity p ON c.GCID = p.GCID
WHERE p.Token IN ('EAAGm0oW...', 'ya29.A0AfH6...');
```

### 8.3 Find token for a specific customer to test lookup
```sql
SELECT CID, GCID, PrivacyRecipientID, Token
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE CID = 12345 AND Token IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetPrivacyUniqueIdentity | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetPrivacyUniqueIdentity.sql*

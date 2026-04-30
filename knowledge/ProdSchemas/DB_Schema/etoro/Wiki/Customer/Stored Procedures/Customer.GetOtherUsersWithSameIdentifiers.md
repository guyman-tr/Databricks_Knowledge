# Customer.GetOtherUsersWithSameIdentifiers

> Fraud detection procedure: finds the most recent other eToro customer who shares the same social network token for a given platform, used to detect duplicate or shared social identity connections.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (exclude self), @NetworkId (platform), @Identifier (token); returns TOP 1 UserName, Email, GCID, CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetOtherUsersWithSameIdentifiers is a fraud and duplicate-account detection procedure. It checks whether the same social network token (@Identifier) is already linked to another eToro account on the same social platform (@NetworkId), excluding the current customer (@GCID).

The procedure exists to prevent customers from creating multiple eToro accounts by sharing or reusing the same social login. If someone connects Facebook account "XYZ" to eToro account A, and then tries to connect the same Facebook token to a new eToro account B, this procedure will find account A - signaling a potential duplicate account or token reuse situation.

It returns at most one match (SELECT TOP 1) ordered by ConnectDate DESC - the most recently connected duplicate is surfaced. The returned data (UserName, Email, GCID, CID) gives compliance/fraud teams enough context to investigate.

---

## 2. Business Logic

### 2.1 Duplicate Social Token Detection

**What**: Identifies another eToro customer who has the same social platform token linked to their account.

**Columns/Parameters Involved**: `@GCID`, `@NetworkId`, `@Identifier`, `Token`

**Rules**:
- JOIN Customer.Customer (c) with Customer.PrivacyUniqueIdentity (p) on c.GCID = p.GCID
- WHERE c.GCID != @GCID: excludes the current customer (self-exclusion)
- WHERE p.PrivacyRecipientID = @NetworkId: restricts to the same social platform
- WHERE p.Token = @Identifier: matches on the OAuth token value (the "Identifier")
- SELECT TOP 1 ... ORDER BY ConnectDate DESC: returns the most recently connected duplicate
- Empty result set: no duplicate found for this token - safe to proceed with connection
- Non-empty result set: another customer already uses this token - flag for review

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Input: GCID of the current customer to exclude from results. Prevents matching against the customer whose identity is being checked. |
| 2 | @NetworkId | INT | NO | - | CODE-BACKED | Input: Social network/platform identifier. Maps to PrivacyUniqueIdentity.PrivacyRecipientID: 2=Facebook, 5=Google, 3=Twitter, 4=LinkedIn, 6=Yahoo, 7=Live. |
| 3 | @Identifier | NVARCHAR(200) | NO | - | CODE-BACKED | Input: The social network OAuth token to search for. Matched against PrivacyUniqueIdentity.Token. If another eToro customer has this exact token for @NetworkId, a match is returned. |
| 4 | UserName | varchar(20) (output) | NO | - | VERIFIED | eToro username of the customer who already has this social token linked. From Customer.Customer.UserName. |
| 5 | Email | varchar(50) (output) | YES | - | VERIFIED | Email address of the matching customer. From Customer.Customer.Email. Dynamic Data Masking may apply. |
| 6 | GCID | int (output) | YES | - | VERIFIED | Group Customer ID of the matching duplicate. Useful for cross-product identity tracing. From Customer.Customer.GCID. |
| 7 | CID | int (output) | NO | - | VERIFIED | Internal customer ID of the matching duplicate. From Customer.Customer.CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID exclusion | Customer.Customer | FROM + WHERE c.GCID != @GCID | Source of customer identity data |
| Token matching | Customer.PrivacyUniqueIdentity | INNER JOIN on GCID + Token + PrivacyRecipientID | Source of social network token data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (DB role) | - | GRANT EXECUTE | BI admin access for fraud investigation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetOtherUsersWithSameIdentifiers (procedure)
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
| Customer.PrivacyUniqueIdentity | Table | INNER JOIN on c.GCID=p.GCID - source of Token and PrivacyRecipientID for matching |

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

### 8.1 Check if a Facebook token is already used by another customer
```sql
EXEC Customer.GetOtherUsersWithSameIdentifiers
    @GCID = 1983785,       -- current customer to exclude
    @NetworkId = 2,        -- 2 = Facebook
    @Identifier = 'EAAGm0...'; -- OAuth token to check
-- Empty result = token is unique, safe to link
-- Non-empty result = duplicate account detected
```

### 8.2 Direct query equivalent
```sql
SELECT TOP 1 c.UserName, c.Email, c.GCID, c.CID
FROM Customer.Customer c WITH (NOLOCK)
INNER JOIN Customer.PrivacyUniqueIdentity p WITH (NOLOCK) ON c.GCID = p.GCID
WHERE c.GCID != 1983785
  AND p.PrivacyRecipientID = 2
  AND p.Token = 'EAAGm0...'
ORDER BY p.ConnectDate DESC;
```

### 8.3 Find all social platform duplicates for a customer (all networks)
```sql
SELECT c.UserName, c.Email, c.GCID, c.CID, p.PrivacyRecipientID, p.Token, p.ConnectDate
FROM Customer.Customer c WITH (NOLOCK)
INNER JOIN Customer.PrivacyUniqueIdentity p WITH (NOLOCK) ON c.GCID = p.GCID
WHERE p.Token IN (
    SELECT Token FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
    WHERE GCID = 1983785
)
AND c.GCID != 1983785
ORDER BY p.ConnectDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetOtherUsersWithSameIdentifiers | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetOtherUsersWithSameIdentifiers.sql*

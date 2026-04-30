# Customer.EmailVerificationTokens

> Stores email verification tokens issued to users during the email confirmation process.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID + Token (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.EmailVerificationTokens stores the tokens generated when users need to verify their email address. A verification link containing the token is sent to the user's email. When they click it, the system validates the token against this table to confirm email ownership. Multiple tokens can exist per user (composite PK) - for example, if they request re-verification.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Part of composite PK. Global Customer ID. |
| 2 | Token | varchar(50) | NO | - | CODE-BACKED | Part of composite PK. The verification token sent in the email link. Unique per issuance. |
| 3 | IssuedOn | datetime | NO | - | CODE-BACKED | When the token was generated. Used for expiry checks (tokens expire after a configured duration). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.InsertEmailVerificationToken | GCID | SP writes | Creates verification tokens |
| Customer.GetVerificationTokenIssuedTime | Token | SP reads | Validates token and returns issued time |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.InsertEmailVerificationToken | Stored Procedure | Inserts tokens |
| Customer.GetVerificationTokenIssuedTime | Stored Procedure | Reads tokens |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EmailVerificationTokens | CLUSTERED PK | GCID, Token | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get tokens for a user
```sql
SELECT Token, IssuedOn FROM Customer.EmailVerificationTokens WITH (NOLOCK) WHERE GCID = @GCID ORDER BY IssuedOn DESC
```

### 8.2 Validate a token
```sql
SELECT GCID, IssuedOn FROM Customer.EmailVerificationTokens WITH (NOLOCK) WHERE Token = @Token
```

### 8.3 Find expired tokens
```sql
SELECT GCID, Token, IssuedOn FROM Customer.EmailVerificationTokens WITH (NOLOCK) WHERE IssuedOn < DATEADD(HOUR, -24, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.EmailVerificationTokens | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.EmailVerificationTokens.sql*

# Customer.GetMirrorValidationValuesByUserNameAndPassword

> Legacy credential-based mirror validation: returns copy-trading validation values for a customer authenticated by username and plaintext password - a deprecated pattern superseded by token-based authentication.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Inline TVF |
| **Key Identifier** | @UserName + @Password (credential pair; returns 0 or 1 rows) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetMirrorValidationValuesByUserNameAndPassword is the credential-based variant of the mirror validation function family. It accepts @UserName and @Password directly and returns the same mirror validation values as GetMirrorValidationValuesByCID (GCID, CID, Credit, NumberOfActiveMirrors, RealizedEquity) - the lookup is performed by `WHERE UserName = @UserName AND Password = @Password`.

The function represents an early/legacy authentication pattern where the caller already held the customer's plaintext password. This approach has been superseded by token-based and session-based authentication. The Password column in Customer.CustomerStatic stores a password hash or value that this function compares directly, making this a credential-validation-plus-data-fetch operation in a single call.

**Security note**: Passing plaintext passwords through SQL function calls is a legacy anti-pattern. Modern systems should not use this function - use CID or GCID keyed variants with authenticated sessions instead. This function should be treated as deprecated.

---

## 2. Business Logic

### 2.1 Credential-Based Lookup

**What**: Authenticates the customer by matching UserName and Password against Customer.CustomerStatic, then returns financial data for the matched account.

**Columns/Parameters Involved**: `@UserName`, `@Password`

**Rules**:
- `WHERE CCST.UserName = @UserName AND CCST.Password = @Password`
- Returns 0 rows if credentials don't match (authentication failure implicit in empty result set)
- Returns 1 row if credentials match (authentication success)
- No explicit error or output for authentication failure - caller must check row count

### 2.2 Mirror-Aware Equity (Same as ByCID/ByGCID)

**What**: Same real-time equity calculation as the other mirror validation functions.

**Columns/Parameters Involved**: `RealizedEquity`

**Rules**:
- `RealizedEquity = ISNULL(Credit,0) + SUM(Trade.Position.Amount WHERE CID=@CID) + SUM(Trade.Mirror.Amount WHERE CID=@CID)`
- Identical to GetMirrorValidationValuesByCID formula

---

## 3. Data Overview

N/A for Inline TVF.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | varchar(20) | NO | - | VERIFIED | Customer login username. Matched against Customer.CustomerStatic.UserName (case-sensitive collation). |
| 2 | @Password | varchar(20) | NO | - | VERIFIED | Customer password. Matched directly against Customer.CustomerStatic.Password. Legacy authentication pattern - plaintext password passed through SQL function. Modern callers should use CID/GCID variants with pre-authenticated sessions. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID. From Customer.Customer (CustomerStatic). |
| 2 | CID | int | NO | - | VERIFIED | Customer ID. From Customer.Customer (CustomerStatic). |
| 3 | Credit | money | YES | - | VERIFIED | Current liquid cash balance (USD). From Customer.Customer (CustomerMoney). |
| 4 | NumberOfActiveMirrors | int | NO | - | CODE-BACKED | Count of active copy-trading relationships: COUNT(*) from Trade.Mirror WHERE CID=CCST.CID AND IsActive=1. |
| 5 | RealizedEquity | money | NO | - | CODE-BACKED | Computed equity: ISNULL(Credit,0) + SUM(Trade.Position.Amount) + SUM(Trade.Mirror.Amount) WHERE CID=CCST.CID. Real-time calculation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, CID, Credit | Customer.Customer | FROM (CCST alias) WHERE UserName=@UserName AND Password=@Password | Credential-based customer lookup |
| NumberOfActiveMirrors | Trade.Mirror | Correlated subquery COUNT IsActive=1 by CCST.CID | Active copy count |
| RealizedEquity (positions) | Trade.Position | Correlated subquery SUM(Amount) by CCST.CID | Open trade values |
| RealizedEquity (mirrors) | Trade.Mirror | Correlated subquery SUM(Amount) by CCST.CID | Mirror allocation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Legacy credential-based callers. See Customer.P_GetMirrorValidationValuesByUserNameAndPassword (stored procedure wrapper for this function).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetMirrorValidationValuesByUserNameAndPassword (function)
|-  Customer.Customer (view)
|     |-  Customer.CustomerStatic (table)
|     `-  Customer.CustomerMoney (table)
|-  Trade.Mirror (table) [cross-schema, x2: IsActive count + Amount sum]
`-  Trade.Position (table) [cross-schema, Amount sum]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (CCST alias) WHERE UserName=@UserName AND Password=@Password |
| Trade.Mirror | Table (cross-schema) | COUNT IsActive=1 and SUM(Amount) by CCST.CID |
| Trade.Position | Table (cross-schema) | SUM(Amount) by CCST.CID |

### 6.2 Objects That Depend On This

Not analyzed in this phase. Known: Customer.P_GetMirrorValidationValuesByUserNameAndPassword (stored procedure that wraps this function).

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE UserName=@UserName AND Password=@Password | Authentication filter | Acts as implicit credential validation; empty result = invalid credentials |
| Password in WHERE clause | Security concern | Passes password value through SQL function call; legacy pattern |

---

## 8. Sample Queries

### 8.1 Legacy credential-based mirror validation (for reference only)

```sql
-- NOT RECOMMENDED: Use CID/GCID variants with pre-authenticated sessions instead
SELECT GCID, CID, Credit, NumberOfActiveMirrors, RealizedEquity
FROM Customer.GetMirrorValidationValuesByUserNameAndPassword('john.doe', 'hashed_pw') WITH (NOLOCK);
```

### 8.2 Preferred modern alternative using pre-authenticated CID

```sql
-- Preferred: authenticate first via session, then use CID-keyed function
SELECT GCID, Credit, NumberOfActiveMirrors, RealizedEquity
FROM Customer.GetMirrorValidationValuesByCID(12345) WITH (NOLOCK);
```

### 8.3 Check if credentials are valid (0 rows = invalid, 1 row = valid)

```sql
DECLARE @IsValid BIT = 0;
IF EXISTS (
    SELECT 1 FROM Customer.GetMirrorValidationValuesByUserNameAndPassword('john.doe', 'hashed_pw') WITH (NOLOCK)
)
    SET @IsValid = 1;
SELECT @IsValid AS CredentialsValid;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 6.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetMirrorValidationValuesByUserNameAndPassword | Type: Inline TVF | Source: etoro/etoro/Customer/Functions/Customer.GetMirrorValidationValuesByUserNameAndPassword.sql*

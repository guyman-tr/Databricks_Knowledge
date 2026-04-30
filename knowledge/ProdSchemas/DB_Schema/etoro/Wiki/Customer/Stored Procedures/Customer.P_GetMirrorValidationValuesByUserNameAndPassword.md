# Customer.P_GetMirrorValidationValuesByUserNameAndPassword

> Validates a username/password pair via STS authentication functions and returns the customer's GCID, CID, Credit, active mirror count, and computed RealizedEquity - or an empty result set if credentials are invalid.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserName + @Password -> GCID, CID, Credit, NumberOfActiveMirrors, RealizedEquity |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.P_GetMirrorValidationValuesByUserNameAndPassword is the authentication + financial snapshot procedure for validating a customer's credentials and returning their copy-trading (Mirror/CopyTrader) account state in a single round-trip. It is used by services that need to:
1. Authenticate a customer by username/password
2. Retrieve their current financial position for mirror/copy trading validation

The procedure uses the STS (Security Token Service) authentication layer to validate credentials - it does NOT directly compare passwords against the Customer table. This is important: even if Customer.Password stores a value, the actual password verification logic lives in `dbo.STS_P_ValidatePasswordByGcid`. The GCID lookup is handled by `STS.F_GetCustomerGcidByUsername`.

On valid credentials: returns one row with GCID, CID, Credit, active mirror count, and computed equity.
On invalid credentials: returns an empty result set (WHERE 1=0 pattern) - same column structure but zero rows. This allows callers to always expect the same schema.

**Naming convention**: The `P_` prefix indicates this is a "primary" or "public" interface procedure (legacy eToro naming convention).

---

## 2. Business Logic

### 2.1 STS-Based Credential Validation

**What**: Validates username/password through the STS authentication layer before returning any data.

**Columns/Parameters Involved**: `@UserName`, `@Password`

**Rules**:
- Step 1: `DECLARE @GCID = STS.F_GetCustomerGcidByUsername(@UserName)` - resolves username to GCID via STS function
- Step 2: `DECLARE @B BIT; EXEC dbo.STS_P_ValidatePasswordByGcid @GCID, @Password, @B OUTPUT`
  - @B = 1: password valid for this GCID
  - @B = 0: password invalid (wrong password, account locked, etc.)
- If @B = 0: SELECT with WHERE 1=0 -> returns empty result set (zero rows, same schema)
- If @B = 1: proceeds to financial data SELECT (see 2.2)
- The STS layer handles all password hashing/comparison details - this procedure never touches raw password comparison

### 2.2 Financial Snapshot for Mirror/Copy Trading

**What**: Computes the customer's current copy-trading equity snapshot when credentials are valid.

**Columns/Parameters Involved**: `Customer.Customer.GCID`, `Customer.Customer.CID`, `Customer.Customer.Credit`, `Trade.Mirror`, `Trade.Position`

**Rules**:
- Joins Customer.Customer (WHERE GCID=@GCID) to get CID and Credit
- NumberOfActiveMirrors = COUNT(*) FROM Trade.Mirror WHERE CID=CCST.CID AND IsActive=1
  - Counts currently active copy relationships (not closed mirrors)
- RealizedEquity = ISNULL(Credit, 0) + ISNULL(SUM(Trade.Position.Amount), 0) + ISNULL(SUM(Trade.Mirror.Amount), 0)
  - Computed as: Credit balance + open position equity + mirror equity
  - This is NOT the same as AccountBalance or AvailableBalance - it is a specific equity computation for mirror validation purposes
  - ISNULL guards against NULL Credit or no positions/mirrors (SUM of empty set returns NULL in SQL)
- The SELECT uses aliases: `CCST` for Customer.Customer subquery

### 2.3 RealizedEquity Computation Detail

**What**: The equity formula used for mirror validation differs from standard account equity.

**Rules**:
- Credit: from Customer.Customer.Credit (CustomerMoney.Credit) - the bonus/credit component
- SUM(Trade.Position.Amount): aggregate of all open position amounts for this CID
- SUM(Trade.Mirror.Amount): aggregate of all mirror/copy amounts for this CID
- The combination Credit + Position amounts + Mirror amounts represents the total economic exposure
- "RealizedEquity" in this context may be a legacy label - it is closer to "total allocated funds" than standard "realized P&L"

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | varchar(20) | NO | - | VERIFIED | Customer username for authentication. Passed to STS.F_GetCustomerGcidByUsername to resolve to a GCID before password validation. Maximum 20 characters matching Customer.CustomerStatic.UserName constraint. |
| 2 | @Password | varchar(20) | NO | - | VERIFIED | Customer password for authentication. Passed to dbo.STS_P_ValidatePasswordByGcid along with the resolved GCID. The STS layer handles all hashing/comparison. Maximum 20 characters. |

**Output columns** (result set - one row if valid, zero rows if invalid):

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | GCID | int | NO | VERIFIED | Global Customer ID (network-level identifier). From Customer.Customer WHERE GCID=@resolved_GCID. |
| 2 | CID | int | NO | VERIFIED | Internal Customer ID (platform-specific). From Customer.Customer, resolved via GCID. |
| 3 | Credit | decimal | YES | VERIFIED | Bonus/credit balance for the customer. From Customer.CustomerMoney.Credit via Customer.Customer view. NULL if no credit assigned. |
| 4 | NumberOfActiveMirrors | int | NO | VERIFIED | Count of currently active copy-trading relationships where this customer is the copier. COUNT(*) FROM Trade.Mirror WHERE CID=CID AND IsActive=1. |
| 5 | RealizedEquity | decimal | YES | VERIFIED | Computed equity: ISNULL(Credit,0) + ISNULL(SUM(Trade.Position.Amount),0) + ISNULL(SUM(Trade.Mirror.Amount),0). Represents total allocated funds across credit, positions, and mirrors. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserName | STS.F_GetCustomerGcidByUsername | Caller (SELECT function) | Resolves username to GCID via STS authentication layer |
| @GCID + @Password | dbo.STS_P_ValidatePasswordByGcid | Caller (EXEC) | Validates password for the resolved GCID; returns BIT result |
| GCID | Customer.Customer | Reader (SELECT) | Retrieves CID and Credit for the authenticated customer |
| CID | Trade.Mirror | Reader (COUNT) | Counts active mirrors (IsActive=1) for the customer |
| CID | Trade.Position | Reader (SUM) | Sums open position amounts for RealizedEquity computation |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by copy-trading validation services or legacy API authentication flows that need combined auth + financial snapshot.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.P_GetMirrorValidationValuesByUserNameAndPassword (procedure)
├── STS.F_GetCustomerGcidByUsername (function) [cross-schema - STS auth layer]
├── dbo.STS_P_ValidatePasswordByGcid (procedure) [cross-schema - STS auth layer]
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── Trade.Mirror (table) [cross-schema]
└── Trade.Position (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| STS.F_GetCustomerGcidByUsername | Function (cross-schema) | Username-to-GCID resolution via STS authentication layer |
| dbo.STS_P_ValidatePasswordByGcid | Procedure (cross-schema) | Password validation for the resolved GCID; returns BIT |
| Customer.Customer | View | SELECT GCID, CID, Credit WHERE GCID=@GCID (after auth success) |
| Trade.Mirror | Table (cross-schema) | COUNT active mirrors WHERE CID=CID AND IsActive=1 |
| Trade.Position | Table (cross-schema) | SUM(Amount) for all open positions WHERE CID=CID |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Uses STS.F_GetCustomerGcidByUsername (cross-schema function dependency)
- Uses dbo.STS_P_ValidatePasswordByGcid (cross-schema procedure dependency)
- The WHERE 1=0 pattern for invalid credentials ensures callers always receive consistent column schema regardless of auth outcome

---

## 8. Sample Queries

### 8.1 Validate credentials and get mirror state
```sql
EXEC Customer.P_GetMirrorValidationValuesByUserNameAndPassword
    @UserName = 'johndoe',
    @Password = 'secret123';
-- Returns: GCID, CID, Credit, NumberOfActiveMirrors, RealizedEquity
-- OR: empty result set (0 rows) if credentials invalid
```

### 8.2 Caller pattern to distinguish valid vs invalid
```sql
CREATE TABLE #AuthResult (
    GCID INT, CID INT, Credit DECIMAL(18,2),
    NumberOfActiveMirrors INT, RealizedEquity DECIMAL(18,2)
);
INSERT INTO #AuthResult
EXEC Customer.P_GetMirrorValidationValuesByUserNameAndPassword
    @UserName = 'johndoe', @Password = 'secret123';

IF EXISTS (SELECT 1 FROM #AuthResult)
    SELECT * FROM #AuthResult;  -- auth success
ELSE
    PRINT 'Authentication failed';

DROP TABLE #AuthResult;
```

### 8.3 Direct equivalent for debugging (after auth is confirmed externally)
```sql
-- Equivalent of the data SELECT portion only (assumes @GCID already resolved):
SELECT
    CCST.GCID,
    CCST.CID,
    CCST.Credit,
    (SELECT COUNT(*) FROM Trade.Mirror WITH (NOLOCK) WHERE CID = CCST.CID AND IsActive = 1) AS NumberOfActiveMirrors,
    ISNULL(CCST.Credit, 0)
        + ISNULL((SELECT SUM(Amount) FROM Trade.Position WITH (NOLOCK) WHERE CID = CCST.CID), 0)
        + ISNULL((SELECT SUM(Amount) FROM Trade.Mirror WITH (NOLOCK) WHERE CID = CCST.CID), 0)
    AS RealizedEquity
FROM Customer.Customer CCST WITH (NOLOCK)
WHERE CCST.GCID = 12345;  -- replace with actual @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.P_GetMirrorValidationValuesByUserNameAndPassword | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.P_GetMirrorValidationValuesByUserNameAndPassword.sql*

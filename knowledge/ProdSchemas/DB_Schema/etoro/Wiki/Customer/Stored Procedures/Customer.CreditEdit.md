# Customer.CreditEdit

> Returns a customer's trading credit (in cents) and active game bet total (in cents) as OUTPUT parameters, with a LoginServer bypass that returns 0 immediately without populating outputs.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to query) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.CreditEdit retrieves two credit-related values for a single customer and returns them as OUTPUT parameters: the customer's trading credit balance (converted from dollar money type to integer cents), and the sum of their active game bets (also in cents, computed via Internal.GetGameBetInCents from Game.ForexResult).

This procedure exists as the OUTPUT-parameter equivalent of the Customer.GetUserCredit view. Where the view returns a result set, this procedure directly populates caller variables - a pattern used by legacy VB/COM application layers that consumed OUTPUT parameters rather than result sets. The UserCredit calculation is identical to the view: CAST(Credit * 100 AS INTEGER) converts the money-typed Credit field to integer cents.

The LoginServer bypass (`if app_name() = 'LoginServer Application' return 0`) is a hard-coded guard that prevents the LoginServer from accidentally triggering credit reads - when called from LoginServer, the procedure returns 0 immediately without executing any SQL or populating the OUTPUT parameters. This leaves @UserCredit and @GameCredit at whatever values the caller initialized them to. Application code calling this from LoginServer must not rely on the OUTPUT values.

---

## 2. Business Logic

### 2.1 Credit to Cents Conversion

**What**: UserCredit is the customer's Credit balance converted from the money type (dollars) to integer cents.

**Columns/Parameters Involved**: `@CID`, `@UserCredit`, `Customer.Customer.Credit`

**Rules**:
- SELECT @UserCredit = CAST(Credit * 100 AS INTEGER) from Customer.Customer WHERE CID = @CID
- Credit is a money type in dollars (up to 4 decimal places); multiplied by 100 and cast to INTEGER
- Example: Credit = 1500.75 -> @UserCredit = 150075 (cents)
- Identical to the UserCredit column in Customer.GetUserCredit view

### 2.2 Game Credit Accumulation

**What**: GameCredit is the sum of active game bet values in cents for the customer.

**Columns/Parameters Involved**: `@GameCredit`, `Game.ForexResult`, `Internal.GetGameBetInCents`

**Rules**:
- @GameCredit initialized to 0 before the SUM query
- SUM(Internal.GetGameBetInCents(GFXR.ForexResultID)) over Game.ForexResult rows for the CID
- If no game rows exist, @GameCredit stays at 0 (initialized before SELECT with no rows returned)
- Game.ForexResult is the legacy game system's position/bet table
- Note: Customer.GetUserCredit view has this logic commented out and hardcoded to 0 - the SP still executes the real calculation

### 2.3 LoginServer Bypass

**What**: Hard-coded early return when called from the LoginServer application.

**Rules**:
- If `app_name() = 'LoginServer Application'`: RETURN 0 immediately - no SQL executed
- @UserCredit and @GameCredit remain at caller-initialized values (typically undefined/0)
- All other callers proceed to the full SQL logic
- Business reason: prevents LoginServer from inadvertently triggering credit reads during authentication flows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to look up. Drives all queries. Must exist in Customer.Customer for outputs to be populated (no validation - if CID not found, @UserCredit stays NULL). |
| 2 | @UserCredit | INTEGER OUTPUT | YES | - | VERIFIED | The customer's trading credit balance in integer cents. Computed as CAST(Credit * 100 AS INTEGER) from Customer.Customer. NULL if no row found for @CID. 0 if LoginServer bypass fires. |
| 3 | @GameCredit | INTEGER OUTPUT | NO | 0 | VERIFIED | Sum of active game bet values in cents, computed via Internal.GetGameBetInCents over Game.ForexResult. Initialized to 0 before the SUM query - remains 0 if no game bets exist. 0 if LoginServer bypass fires. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | JOIN (read) | Retrieves Credit balance for the @UserCredit output |
| @CID = GFXR.CID | Game.ForexResult | JOIN (read) | Retrieves game bet records for @GameCredit SUM |
| GFXR.ForexResultID | Internal.GetGameBetInCents | Function call | Converts each ForexResult row to cents |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in the SSDT repo - called directly from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CreditEdit (procedure)
├── Customer.Customer (view)
└── Game.ForexResult (table - cross-schema)
      └── Internal.GetGameBetInCents (function - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Read - retrieves Credit for @UserCredit output |
| Game.ForexResult | Table | Read - game bet records JOINed on CID for @GameCredit SUM |
| Internal.GetGameBetInCents | Function | Called per ForexResult row to convert bet value to cents |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from application code directly. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| `if app_name() = 'LoginServer Application'` | Guard / Bypass | Early RETURN 0 when called from LoginServer - no outputs populated |
| `SET NOCOUNT ON` | Setting | Suppresses row count messages - legacy pattern for OUTPUT-parameter callers |
| RETURN 0 | Return code | Always returns 0 (success). No error-specific return codes. |

---

## 8. Sample Queries

### 8.1 Execute and retrieve both output values

```sql
DECLARE @UserCredit INT
DECLARE @GameCredit INT
EXEC Customer.CreditEdit @CID = 12345678, @UserCredit = @UserCredit OUTPUT, @GameCredit = @GameCredit OUTPUT
SELECT @UserCredit AS UserCreditCents, @GameCredit AS GameCreditCents,
       @UserCredit / 100.0 AS UserCreditDollars
```

### 8.2 Replicate the UserCredit logic without the SP

```sql
SELECT
    CID,
    CAST(Credit * 100 AS INT) AS UserCreditCents,
    Credit AS UserCreditDollars
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.3 Replicate the GameCredit logic inline

```sql
SELECT
    cc.CID,
    SUM(Internal.GetGameBetInCents(gfxr.ForexResultID)) AS GameCreditCents
FROM Customer.Customer cc WITH (NOLOCK)
INNER JOIN Game.ForexResult gfxr WITH (NOLOCK) ON cc.CID = gfxr.CID
WHERE cc.CID = 12345678
GROUP BY cc.CID, cc.Credit
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CreditEdit | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.CreditEdit.sql*

# Billing.NetellerAdd

> Registers a new Neteller e-wallet account in the platform by inserting its credentials into Billing.Neteller and returning the newly assigned internal NetellerID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NetellerID (OUTPUT - new identity from Billing.Neteller) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.NetellerAdd` is the sole write entry point for the `Billing.Neteller` table. It is called when a customer links a Neteller e-wallet account to their eToro account for use as a payment method (deposits or withdrawals). The procedure stores the two Neteller credentials that identify and authenticate the account: the customer's public Neteller account number (`AccountID`) and their 6-digit Neteller security code (`SecureID`).

The procedure exists because Neteller accounts require their own identity separate from the general payment instrument tables. An internal `NetellerID` is generated on insert (via SCOPE_IDENTITY) and returned to the caller as an OUTPUT parameter, allowing the caller to link the Neteller account to a payment or withdrawal record.

When a customer registers a Neteller account, the application calls this procedure, receives the `@NetellerID`, and then records the association in `Billing.NetellerToPayment` or `Billing.NetellerToCashout`. The `@@ERROR` return code is propagated to the caller for error handling - in particular, a UNIQUE constraint violation on `AccountID` signals that the Neteller account is already registered.

---

## 2. Business Logic

### 2.1 Neteller Account Registration - Uniqueness Guard

**What**: Inserts a new Neteller account credential pair; enforces one registration per Neteller account number.

**Parameters Involved**: `@SecureID`, `@AccountID`, `@NetellerID`

**Rules**:
- Inserts `(SecureID, AccountID)` into `Billing.Neteller`
- `AccountID` has a UNIQUE constraint (BNET_ACCOUNT index) - attempting to register the same Neteller account number twice raises a constraint violation; @@ERROR is returned to the caller for handling
- Returns the new `NetellerID` (IDENTITY value) via OUTPUT parameter
- Returns `@@ERROR` as the RETURN value (0 = success; non-zero = SQL error code)
- `SecureID` is Neteller's authentication PIN - stored alongside AccountID so that cashout processing (`Billing.CashoutProcessToNeteller`) can pass it directly to the Neteller payment API

**Diagram**:
```
Caller (application)
    |
    |-- @SecureID, @AccountID
    v
Billing.NetellerAdd
    |
    |--> INSERT INTO Billing.Neteller (SecureID, AccountID)
    |        UNIQUE constraint on AccountID
    |        (error if already registered)
    |
    |<-- @NetellerID = SCOPE_IDENTITY()
    |<-- RETURN @@ERROR (0 = success)
    |
    v
Caller links @NetellerID to Billing.NetellerToPayment
or Billing.NetellerToCashout
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NetellerID | INTEGER | NO | - | CODE-BACKED | OUTPUT parameter. Returns the newly assigned internal etoro identifier for this Neteller account (SCOPE_IDENTITY from Billing.Neteller). Caller uses this to link the account in Billing.NetellerToPayment or Billing.NetellerToCashout. |
| 2 | @SecureID | NUMERIC(6,0) | NO | - | CODE-BACKED | The 6-digit Neteller security PIN for this account. A Neteller-assigned authentication credential required to authorize fund movements. Stored in Billing.Neteller and retrieved by Billing.CashoutProcessToNeteller when processing withdrawals. |
| 3 | @AccountID | NUMERIC(12,0) | NO | - | CODE-BACKED | The customer's public Neteller account number (up to 12 digits). Enforced unique in Billing.Neteller - one registration per Neteller account. A duplicate raises a constraint violation returned via @@ERROR. |
| 4 | RETURN value | INTEGER | - | - | CODE-BACKED | Returns @@ERROR immediately after the INSERT. 0 = success; any non-zero value is a SQL Server error code (e.g., unique constraint violation = 2627). Caller must check this before using @NetellerID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | [Billing.Neteller](../Tables/Billing.Neteller.md) | WRITER | Inserts new Neteller account credentials |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [Billing.PaymentByNetellerAdd](Billing.PaymentByNetellerAdd.md) | @SecureID, @AccountID | EXEC caller | Calls NetellerAdd as part of the full Neteller deposit registration flow |
| [Billing.BlockNetellerAdd](../Stored Procedures/Billing.BlockNetellerAdd.md) | - | EXEC caller | References NetellerAdd for blocked Neteller account handling |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.NetellerAdd (procedure)
└── Billing.Neteller (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Neteller](../Tables/Billing.Neteller.md) | Table | INSERT target - stores SecureID and AccountID, generates NetellerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PaymentByNetellerAdd](Billing.PaymentByNetellerAdd.md) | Procedure | Calls this procedure to register Neteller credentials as part of deposit creation |
| [Billing.BlockNetellerAdd](Billing.BlockNetellerAdd.md) | Procedure | References NetellerAdd in blocked account flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Register a new Neteller account and retrieve its internal ID

```sql
DECLARE @NewNetellerID INTEGER;
DECLARE @Err INTEGER;
EXEC @Err = Billing.NetellerAdd
    @NetellerID = @NewNetellerID OUTPUT,
    @SecureID   = 123456,
    @AccountID  = 453245789012;
SELECT @NewNetellerID AS NewNetellerID, @Err AS ErrorCode;
```

### 8.2 Look up a Neteller account by AccountID after registration

```sql
SELECT
    n.NetellerID,
    n.AccountID,
    n.SecureID
FROM Billing.Neteller n WITH (NOLOCK)
WHERE n.AccountID = 453245789012;
```

### 8.3 Find all payments associated with a specific Neteller account

```sql
SELECT
    n.NetellerID,
    n.AccountID,
    ntp.PaymentID
FROM Billing.Neteller n WITH (NOLOCK)
INNER JOIN Billing.NetellerToPayment ntp WITH (NOLOCK) ON ntp.NetellerID = n.NetellerID
WHERE n.AccountID = 453245789012;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.NetellerAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.NetellerAdd.sql*

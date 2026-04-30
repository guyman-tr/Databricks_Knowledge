# Billing.GetDepositByExTransactionID

> Looks up an existing deposit by the payment provider's external transaction ID, customer, and deposit type; returns the DepositID (or 0 if not found), used for idempotency checks to prevent duplicate deposit creation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar: DepositID (INT), 0 if no match found |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositByExTransactionID` checks whether a deposit already exists for a given external transaction ID, customer, and deposit type. `ExTransactionID` is the payment provider's own reference for the transaction (e.g., the card processor's authorization code or the provider's transaction reference number). By looking up this ID before creating a new deposit, the calling service can detect duplicate payment notifications and avoid creating duplicate deposit records.

The procedure returns 0 (initialized default) if no match is found, allowing callers to use a simple `IF @DepositID = 0` pattern to decide whether to proceed with deposit creation.

It does not apply `WITH (NOLOCK)`, suggesting it is intended to read committed data - important for idempotency checking where reading an uncommitted, in-flight insert could produce false "not found" results.

Called by the `DepositUser` service account during deposit processing flows.

---

## 2. Business Logic

### 2.1 Idempotency Check Pattern

**What**: Payment providers may send duplicate payment notifications (callbacks/webhooks). This procedure is the gate check that prevents duplicate deposit records for the same external transaction.

**Columns/Parameters Involved**: `@CID`, `@ExTransactionID`, `@DepositTypeID`, `Billing.Deposit.ExTransactionID`, `Billing.Deposit.DepositTypeID`

**Rules**:
- Returns 0 (DECLARE @DepositID INT = 0) if no matching deposit exists -> safe to create a new deposit
- Returns the existing DepositID if found -> caller treats this as a duplicate and skips creation
- `SELECT TOP(1)` - takes first match; the combination (CID, ExTransactionID, DepositTypeID) should be unique in practice but TOP(1) guards against edge cases
- No `WITH (NOLOCK)` - reads committed data only, preventing the race condition where two concurrent inserts both see "not found" and both proceed

**Diagram**:
```
@CID + @ExTransactionID + @DepositTypeID
  |
  v
Billing.Deposit WHERE CID=@CID AND ExTransactionID=@ExTransactionID AND DepositTypeID=@DepositTypeID
  |
  +-- Found -> @DepositID = existing DepositID (e.g., 987654)
  +-- Not found -> @DepositID = 0 (default)
  |
  v
SELECT @DepositID  -> caller: 0 = not found (safe to insert), >0 = duplicate (skip)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters Billing.Deposit.CID to scope the external transaction ID lookup to the specific customer. Prevents cross-customer false matches on shared ExTransactionID values. |
| 2 | @ExTransactionID | VARCHAR(50) | NO | - | CODE-BACKED | The payment provider's external transaction reference ID. Maps to Billing.Deposit.ExTransactionID. Used by the payment provider to identify the transaction on their side (authorization code, gateway reference, etc.). |
| 3 | @DepositTypeID | INT | NO | - | CODE-BACKED | Deposit type filter. Maps to Billing.Deposit.DepositTypeID (e.g., 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment). Scopes the lookup to the specific deposit type being processed. |
| 4 | (return value) | INT | NO | - | CODE-BACKED | The DepositID of the matching deposit if found, or 0 if no matching deposit exists. Caller uses 0 as the "not found" sentinel: proceed with creation. Any positive value means the external transaction was already processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | Scopes the search to deposits for a specific customer |
| @ExTransactionID | Billing.Deposit.ExTransactionID | Lookup | Matches the payment provider's transaction reference |
| @DepositTypeID | Billing.Deposit.DepositTypeID | Lookup | Scopes to a specific deposit type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser | GRANT EXECUTE | Permission | Called during deposit processing to detect duplicate payment notifications |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositByExTransactionID (procedure)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ (no NOLOCK) - searches for existing deposit matching (CID, ExTransactionID, DepositTypeID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositUser (deposit service) | DB User | Calls to check for duplicate deposits before inserting a new deposit record |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No WITH (NOLOCK) | Design | Reads committed data only - prevents false "not found" on in-flight concurrent inserts (important for idempotency) |
| SELECT TOP(1) | Safety | Returns at most one DepositID; guards against edge cases where multiple rows match |
| @DepositID INT = 0 | Sentinel | Default value of 0 serves as the "not found" indicator; callers check for 0 |

---

## 8. Sample Queries

### 8.1 Check if an external transaction was already processed

```sql
EXEC Billing.GetDepositByExTransactionID
    @CID = 12345,
    @ExTransactionID = 'TXN-ABC123',
    @DepositTypeID = 1;  -- 1=Regular
-- Returns 0 if not found, DepositID if found
```

### 8.2 Inline equivalent lookup

```sql
SELECT TOP(1) DepositID
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = 12345
  AND ExTransactionID = 'TXN-ABC123'
  AND DepositTypeID = 1;
```

### 8.3 Find all deposits with a given external transaction ID (cross-customer diagnostic)

```sql
SELECT DepositID, CID, DepositTypeID, PaymentStatusID, ExTransactionID, PaymentDate
FROM Billing.Deposit WITH (NOLOCK)
WHERE ExTransactionID = 'TXN-ABC123'
ORDER BY DepositID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.3/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (DepositUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositByExTransactionID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositByExTransactionID.sql*

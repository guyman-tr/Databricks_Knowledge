# Billing.PayoutProcess_IsDepositID

> Validates that a DepositID belongs to a specific external transaction, confirming the deposit-to-payment association is correct before processing a credit card approved payment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1 DepositID if valid, empty if not |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_IsDepositID` is a lightweight validation procedure used during credit card payout processing. When the payout service or SecurePay integration needs to verify that a specific DepositID genuinely corresponds to a given ExTransactionID (the external payment provider's transaction identifier), it calls this procedure. The procedure returns the DepositID if the match is confirmed, or no rows if the combination is invalid.

The procedure prevents "deposit ID spoofing" - a scenario where a malicious or erroneous caller could submit a DepositID that doesn't match the external transaction being processed. By confirming the pairing exists in `Billing.Deposit`, the payout pipeline ensures the refund is going to the correct original deposit.

Data flow: Caller provides a DepositID and an ExTransactionID. The procedure queries `Billing.Deposit` (the authoritative ledger of all deposit transactions) to confirm both fields match the same record. A non-empty result means the ID pair is valid; an empty result means the association is wrong and processing should be blocked.

Created April 2017 by Geri Reshef (ticket 44868, "DB - SP Billing.PayoutProcess_IsDepositID").

---

## 2. Business Logic

### 2.1 Deposit-to-ExTransaction Identity Validation

**What**: Confirms that a DepositID and ExTransactionID refer to the same deposit record.

**Parameters Involved**: `@DepositID`, `@ExTransactionID`, `Billing.Deposit.ExTransactionID`

**Rules**:
- Queries `Billing.Deposit WHERE ExTransactionID = @ExTransactionID AND DepositID = @DepositID`.
- Returns TOP 1 DepositID - either the valid DepositID (match confirmed) or empty (no match).
- The TOP 1 guard handles any edge case where multiple Deposit rows could theoretically match (though the PK on DepositID makes this impossible for the DepositID match; TOP 1 is defensive).
- No error is thrown on mismatch - the caller is expected to check for rows in the result set.

**Diagram**:
```
Caller: "Is DepositID=@DepositID the correct deposit for ExTransactionID=@ExTransactionID?"
  |
  SELECT TOP 1 DepositID FROM Billing.Deposit
    WHERE ExTransactionID = @ExTransactionID AND DepositID = @DepositID
  |
  Row returned?    No row returned?
    YES                NO
  "Valid - proceed"  "Invalid - block processing"
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | int | NO | - | CODE-BACKED | The deposit record identifier to validate. Matched against `Billing.Deposit.DepositID`. If this ID does not exist in Deposit with the provided ExTransactionID, the result is empty (validation fails). |
| 2 | @ExTransactionID | varchar(50) | NO | - | CODE-BACKED | The external payment provider's transaction identifier. Matched against `Billing.Deposit.ExTransactionID`. This is the provider's reference code for the original deposit (e.g., the card network transaction ID). |

**Result Set**: Returns `DepositID` (int) - the matched DepositID if valid, or empty result set if invalid.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID + @ExTransactionID | [Billing.Deposit](../Tables/Billing.Deposit.md) | Lookup (SELECT) | Validates the (DepositID, ExTransactionID) combination against the deposit ledger. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout service / SecurePay (application) | - | EXEC | Called during CC approved payment processing to validate the deposit association. No SQL-layer callers found (GRANT VIEW DEFINITION to BIadmins only - not executable by known DB roles). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_IsDepositID (procedure)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Deposit](../Tables/Billing.Deposit.md) | Table | SELECT TOP 1 to validate (DepositID, ExTransactionID) pair. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout service (application code) | Application | Calls during CC payment approval to confirm deposit identity. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

`Billing.Deposit` has an index on `ExTransactionID` - the query WHERE ExTransactionID = @ExTransactionID filters efficiently. The additional AND DepositID = @DepositID uses the PK as a secondary filter.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if a DepositID matches an external transaction

```sql
EXEC Billing.PayoutProcess_IsDepositID
    @DepositID       = 987654,
    @ExTransactionID = 'EXTXN-ABC123456';
-- Returns DepositID=987654 if valid, empty if not
```

### 8.2 Direct query equivalent (for debugging)

```sql
SELECT TOP 1 d.DepositID
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.ExTransactionID = 'EXTXN-ABC123456'
  AND d.DepositID = 987654;
```

### 8.3 Find all deposits for an ExTransactionID (pre-validation check)

```sql
SELECT d.DepositID, d.CID, d.Amount, d.CashoutStatusID, d.ExTransactionID
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.ExTransactionID = 'EXTXN-ABC123456';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayoutProcess_IsDepositID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_IsDepositID.sql*

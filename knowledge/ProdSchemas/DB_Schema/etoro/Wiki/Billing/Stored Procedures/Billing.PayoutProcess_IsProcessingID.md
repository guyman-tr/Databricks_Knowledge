# Billing.PayoutProcess_IsProcessingID

> Validates that a WithdrawToFundingID has the expected external reference code in PayoutProcess, confirming the payout record identity before processing a credit card refund.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1 WithdrawToFundingID if valid, empty if not |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_IsProcessingID` is the withdrawal-side counterpart to `Billing.PayoutProcess_IsDepositID`. While `IsDepositID` validates that a DepositID matches an external transaction (for deposit refunds), `IsProcessingID` validates that a WithdrawToFundingID has been finalized with the expected external reference code from the payment provider (for credit card refunds/cashouts).

When the payout service or SecurePay integration needs to confirm that a payout it previously submitted (and assigned an ExtReferenceCode) is the same one it's now receiving a callback for, it calls this procedure. A returned row confirms the (WithdrawToFundingID, ExtReferenceCode) pair matches - the callback legitimately corresponds to this payout record. An empty result signals a mismatch.

Data flow: Caller provides a WithdrawToFundingID and the external reference code the provider sent back. The procedure checks `Billing.PayoutProcess` to confirm this ExtReferenceCode was stored against that WithdrawToFundingID. Created April 2017 by Geri Reshef (ticket 44917, "DB - SP Billing.PayoutProcess_IsProcessingID").

---

## 2. Business Logic

### 2.1 Payout-to-ExtReference Identity Validation

**What**: Confirms a payout record has the expected external reference code, guarding against callback spoofing.

**Parameters Involved**: `@WithdrawToFundingID`, `@ExtReferenceCode`, `Billing.PayoutProcess.ExtReferenceCode`

**Rules**:
- Queries `Billing.PayoutProcess WHERE ExtReferenceCode = @ExtReferenceCode AND WithdrawToFundingID = @WithdrawToFundingID`.
- Returns TOP 1 WithdrawToFundingID if the pair matches, empty result if not.
- ExtReferenceCode is set on the PayoutProcess record during finalization (`PayoutProcess_FinalizeRequest` or `PayoutProcess_UpdateStatus`). This procedure verifies that code back to the provider's callback.
- The UNIQUE NC index on WithdrawToFundingID makes this a single-seek operation.

**Diagram**:
```
Provider callback: "ExtReferenceCode=@ExtReferenceCode for WithdrawToFundingID=@WithdrawToFundingID"
  |
  SELECT TOP 1 WithdrawToFundingID FROM Billing.PayoutProcess
    WHERE ExtReferenceCode = @ExtReferenceCode AND WithdrawToFundingID = @WithdrawToFundingID
  |
  Row returned?     No row returned?
    YES                 NO
  "Valid callback"  "Mismatch - reject"
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | CODE-BACKED | The payout record identifier. Matched against `Billing.PayoutProcess.WithdrawToFundingID`. This is the primary key of the payment leg being validated. |
| 2 | @ExtReferenceCode | varchar(50) | NO | - | CODE-BACKED | The external payment provider's reference code for this transaction. Matched against `Billing.PayoutProcess.ExtReferenceCode`. This code is assigned by the provider when the payout is submitted and stored in PayoutProcess by `PayoutProcess_FinalizeRequest` or `PayoutProcess_UpdateStatus`. |

**Result Set**: Returns `WithdrawToFundingID` (int) - the matched ID if valid, or empty result set if invalid.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID + @ExtReferenceCode | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Lookup (SELECT) | Validates the (WithdrawToFundingID, ExtReferenceCode) pair against the payout processing ledger. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout service / SecurePay (application) | - | EXEC | Called during CC refund callback processing to confirm the payout identity. No SQL-layer callers found (GRANT VIEW DEFINITION to BIadmins only). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_IsProcessingID (procedure)
└── Billing.PayoutProcess (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | SELECT TOP 1 to validate (WithdrawToFundingID, ExtReferenceCode) pair. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout service / SecurePay (application code) | Application | Validates payout callback during CC refund processing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The query uses `WHERE ExtReferenceCode = @ExtReferenceCode AND WithdrawToFundingID = @WithdrawToFundingID`. The UNIQUE NC index `IX_BillingPayoutProcess_WithdrawToFundingID` covers WithdrawToFundingID, making the ID lookup fast. ExtReferenceCode is used as an additional filter to verify the value matches.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Validate a payout callback from the payment provider

```sql
EXEC Billing.PayoutProcess_IsProcessingID
    @WithdrawToFundingID = 12345678,
    @ExtReferenceCode    = 'PROVREF-XYZ789';
-- Returns WithdrawToFundingID=12345678 if valid, empty if mismatch
```

### 8.2 Direct query equivalent

```sql
SELECT TOP 1 WithdrawToFundingID
FROM Billing.PayoutProcess WITH (NOLOCK)
WHERE ExtReferenceCode = 'PROVREF-XYZ789'
  AND WithdrawToFundingID = 12345678;
```

### 8.3 Find all PayoutProcess records with a given ExtReferenceCode

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.ExtReferenceCode,
    pp.CashoutStatusID,
    pp.PayoutProcessStatusDate
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.ExtReferenceCode = 'PROVREF-XYZ789';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayoutProcess_IsProcessingID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_IsProcessingID.sql*

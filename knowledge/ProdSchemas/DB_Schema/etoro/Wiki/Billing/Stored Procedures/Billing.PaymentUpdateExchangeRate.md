# Billing.PaymentUpdateExchangeRate

> Updates the ExchangeRate field on a single Billing.Payment record; a minimal, single-column patcher for post-insert FX rate corrections on the legacy payment table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentUpdateExchangeRate` is a micro-procedure that patches the `ExchangeRate` column of a single `Billing.Payment` row. It exists to allow post-insert correction of the FX rate recorded against a legacy payment - for example when the rate used at payment creation time was provisional and needs to be replaced by the confirmed settlement rate.

The procedure is intentionally minimal: no transaction wrapper, no audit trail (no `History.Payment` insert), and no status-change logic. It assumes the caller already holds an appropriate lock or transaction context, and that logging is handled externally if needed.

`Billing.Payment` was frozen in January 2011 after the platform migrated to `Billing.Deposit`/`Billing.Funding`. Calls to this procedure therefore apply only to the historical pre-2011 payment dataset.

---

## 2. Business Logic

### 2.1 Single-Column Exchange Rate Patch

**What**: Overwrites the ExchangeRate on one payment row.

**Parameters Involved**: `@PaymentID`, `@ExchangeRate`

**Rules**:
- `UPDATE Billing.Payment SET ExchangeRate = @ExchangeRate WHERE PaymentID = @PaymentID`
- No guard on current ExchangeRate value - unconditional overwrite
- If `@PaymentID` does not exist, `@@ROWCOUNT` = 0 but no error is raised - silent no-op
- No History.Payment audit entry is written - this update is invisible to the status-transition audit trail
- No transaction wrapping - caller is responsible for transaction context

### 2.2 ExchangeRate Precision

**What**: The @ExchangeRate parameter uses the `dbo.dtPrice` user-defined type.

**Rules**:
- `dbo.dtPrice` = `decimal(16, 8)` - supports 8 decimal places, suitable for FX cross rates (e.g., 0.00123456)
- Stored in `Billing.Payment.ExchangeRate` which is also typed as `dtPrice` / `decimal(16, 8)`
- Caller is responsible for supplying a valid, confirmed rate

### 2.3 Error Propagation

**Rules**:
- Returns `@@ERROR` directly (0 = success, non-zero = SQL error code)
- No TRY/CATCH, no RAISERROR - raw error code returned to caller

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | PK of the Billing.Payment row to update. Must exist - if not found, UPDATE is a silent no-op (0 rows affected, no error). |
| 2 | @ExchangeRate | dbo.dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | New FX exchange rate to store against the payment. Overwrites any existing value unconditionally. 8 decimal precision supports any currency pair. |
| 3 | RETURN value | INTEGER | - | - | CODE-BACKED | @@ERROR: 0 = success. Non-zero = SQL error code from the UPDATE statement. No TRY/CATCH - raw error propagated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | [Billing.Payment](../Tables/Billing.Payment.md) | MODIFIER | Sets ExchangeRate on the target payment row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External caller (application / back-office) | @PaymentID | EXEC caller | Called to correct or finalize the FX rate on a legacy payment; no SQL-level callers found in repo |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentUpdateExchangeRate (procedure)
└── Billing.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | UPDATE - patches ExchangeRate column |
| dbo.dtPrice | User Defined Type | Parameter type - decimal(16,8) precision for FX rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in repo | - | Phase 8 scan found no EXEC references |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No transaction wrapper. No audit trail. Silent no-op if @PaymentID not found (@@ROWCOUNT = 0, no error). Target table (Billing.Payment) has been frozen since 2011-01-16.

---

## 8. Sample Queries

### 8.1 Update the exchange rate for a legacy payment

```sql
DECLARE @Err INTEGER;
EXEC @Err = Billing.PaymentUpdateExchangeRate
    @PaymentID    = 12345,
    @ExchangeRate = 1.08500000;  -- decimal(16,8)
SELECT @Err AS ErrorCode;
```

### 8.2 Verify the updated rate

```sql
SELECT
    bp.PaymentID,
    bp.ExchangeRate,
    bp.ModificationDate,
    ps.Name AS CurrentStatus
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = bp.PaymentStatusID
WHERE bp.PaymentID = 12345;
```

### 8.3 Find legacy payments with no exchange rate set

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount,
    bp.PaymentDate,
    bp.ExchangeRate
FROM Billing.Payment bp WITH (NOLOCK)
WHERE bp.ExchangeRate IS NULL OR bp.ExchangeRate = 0
ORDER BY bp.PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentUpdateExchangeRate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentUpdateExchangeRate.sql*

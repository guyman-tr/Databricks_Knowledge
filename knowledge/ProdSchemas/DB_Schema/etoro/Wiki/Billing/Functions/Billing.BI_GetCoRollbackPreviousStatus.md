# Billing.BI_GetCoRollbackPreviousStatus

> Scalar function that retrieves the cashout status a WithdrawToFunding record held immediately before a cashout rollback event, used in BI reports to show the pre-rollback state.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(50) - prior CashoutStatus name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.BI_GetCoRollbackPreviousStatus answers the question: "What status was this withdrawal-to-funding record in BEFORE the rollback occurred?" For BI analysis of cashout rollback events, it is not enough to know the current post-rollback state - analysts also need to know what state the record was in immediately prior. This function looks backward in the `History.WithdrawToFundingAction` audit trail to find the last status before the rollback's modification date.

This function exists to enable before/after analysis in BI rollback reports. Without it, BI reports would need to join to the history table and implement the chronological lookback logic inline, per row. By encapsulating the lookup in a scalar function, the BI procedure can call it once per rollback record.

Data is read from `History.WithdrawToFundingAction` (the audit log for `Billing.WithdrawToFunding` status changes) filtered by `BW2F_ID` (the WithdrawToFunding record ID) and a cutoff timestamp. The function uses a cross-schema dependency on the History schema.

---

## 2. Business Logic

### 2.1 Prior Status Lookup Algorithm

**What**: Finds the most recent CashoutStatusID in the history table that predates the rollback event.

**Columns/Parameters Involved**: `@RollbackWPID`, `@RollbackModificationDate`

**Rules**:
- Queries `History.WithdrawToFundingAction WHERE BW2F_ID = @RollbackWPID AND ModificationDate < @RollbackModificationDate ORDER BY 1 DESC` - note: `ORDER BY 1` orders by CashoutStatusID (the first SELECT column), not by ModificationDate. This is a known quirk - the intent appears to be to get the highest-numbered CashoutStatusID before the cutoff, not necessarily the most recent one chronologically.
- COALESCE wraps the subquery result with 0 as default, then looks up the CashoutStatus name for that ID.
- If no history records exist before @RollbackModificationDate, returns 'N/A' (the COALESCE(name, 'N/A') fallback, since CashoutStatusID=0 likely has no matching name).
- The function queries History schema (cross-schema dependency on History.WithdrawToFundingAction).

**Diagram**:
```
@RollbackWPID + @RollbackModificationDate
    |
History.WithdrawToFundingAction
    WHERE BW2F_ID = @RollbackWPID
    AND ModificationDate < @RollbackModificationDate
    ORDER BY CashoutStatusID DESC (TOP 1)
    |
-> CashoutStatusID (or 0 if none)
    |
Dictionary.CashoutStatus -> Name
    |
-> Name (or 'N/A' if no match / CashoutStatusID=0)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RollbackWPID | int | NO | - | CODE-BACKED | The BW2F_ID (WithdrawToFunding record ID) from History.WithdrawToFundingAction. Identifies which withdrawal-to-funding record's history to look back into. Corresponds to the WithdrawToFunding record that was rolled back. |
| 2 | @RollbackModificationDate | datetime | NO | - | CODE-BACKED | The timestamp of the rollback event. The function retrieves history records with ModificationDate strictly before this date, finding the state the record was in just before the rollback. |
| RETURN | varchar(50) | - | NO | - | CODE-BACKED | The CashoutStatus name from Dictionary.CashoutStatus representing the pre-rollback state. Returns 'N/A' if no history records exist before the given date or if the looked-up status ID has no matching name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RollbackWPID | History.WithdrawToFundingAction (BW2F_ID) | Lookup (cross-schema) | Reads the action history log for the WithdrawToFunding record to find prior status. |
| CashoutStatusID | Dictionary.CashoutStatus | Lookup | Resolves the looked-up CashoutStatusID to its display name. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_Deposit_State_Report | RollbackWPID, ModificationDate | Caller | BI report procedure that calls this function to populate the "previous status" column for cashout rollback rows. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_GetCoRollbackPreviousStatus (function)
├── History.WithdrawToFundingAction (table - cross-schema)
└── Dictionary.CashoutStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.WithdrawToFundingAction | Table (cross-schema) | Reads prior CashoutStatusID for the given BW2F_ID before the rollback date. |
| Dictionary.CashoutStatus | Table | Resolves CashoutStatusID to its display name. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_Deposit_State_Report | Stored Procedure | Calls this function to show pre-rollback cashout status in BI reports. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | Function is NOT schema-bound. |
| Known quirk | Logic | `ORDER BY 1 DESC` in the subquery orders by CashoutStatusID (column 1 of the SELECT), not by ModificationDate. This returns the highest-numbered CashoutStatusID before the cutoff rather than the most recent chronologically. If the intent was chronological ordering, this is a latent bug. |

---

## 8. Sample Queries

### 8.1 Get prior cashout status for a specific rollback

```sql
SELECT Billing.BI_GetCoRollbackPreviousStatus(12345, '2026-01-15 10:30:00') AS PreviousStatus;
```

### 8.2 Verify the function against the history table directly

```sql
-- Direct history lookup equivalent to what the function does
SELECT TOP 1
    CashoutStatusID,
    ModificationDate
FROM History.WithdrawToFundingAction WITH (NOLOCK)
WHERE BW2F_ID = 12345
  AND ModificationDate < '2026-01-15 10:30:00'
ORDER BY CashoutStatusID DESC;
```

### 8.3 Rollback before/after status analysis for a date range

```sql
SELECT TOP 50
    wf.BillingWithdraw2FundingID,
    cs_current.Name AS CurrentStatus,
    Billing.BI_GetCoRollbackPreviousStatus(
        wf.BillingWithdraw2FundingID,
        wf.ModificationDate
    ) AS PreviousStatus
FROM Billing.WithdrawToFunding wf WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs_current WITH (NOLOCK) ON cs_current.CashoutStatusID = wf.CashoutStatusID
ORDER BY wf.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.BI_GetCoRollbackPreviousStatus | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.BI_GetCoRollbackPreviousStatus.sql*

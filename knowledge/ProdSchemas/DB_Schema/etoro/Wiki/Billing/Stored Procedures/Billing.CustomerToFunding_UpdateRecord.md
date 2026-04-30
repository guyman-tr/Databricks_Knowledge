# Billing.CustomerToFunding_UpdateRecord

> Updates `DepositTypeID`, `ReasonID`, `LastUsedDate`, and `CustomerFundingStatusID` on a customer-funding link within a transaction; archives pre-update state to history via an explicit INSERT-then-UPDATE pattern.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (composite PK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_UpdateRecord` provides a full record reclassification for a customer-funding link - changing its deposit type, reason, status, and refreshing the last-used date in a single atomic operation. It differs from other Update procedures in this family by using an explicit `INSERT INTO History` + `UPDATE` pattern within `BEGIN TRAN / COMMIT TRAN / TRY-CATCH`, rather than the OUTPUT clause pattern.

The IsVerified column was added to history archival in January 2023 (PAYIL-5743, Shay Oren).

---

## 2. Business Logic

### 2.1 Explicit History + Update Pattern

**What**: Saves the current row to history first, then updates the live record.

**Transaction flow**:
```
BEGIN TRAN
  1. INSERT INTO History.ActiveCustomerToFunding (SELECT current row WHERE CID+FundingID)
  2. UPDATE Billing.CustomerToFunding
       SET DepositTypeID=@DepositTypeID, ReasonID=@ReasonID,
           LastUsedDate=GETUTCDATE(), CustomerFundingStatusID=@CustomerFundingStatusID
       WHERE CID=@CID AND FundingID=@FundingID
COMMIT TRAN
```

**Rules**:
- History INSERT uses `SELECT ... FROM Billing.CustomerToFunding WHERE CID+FundingID` (explicit SELECT, not OUTPUT clause)
- `LastUsedDate` is always set to `GETUTCDATE()` (not from parameter)
- TRY-CATCH handles errors: if `@@TRANCOUNT = 1` -> ROLLBACK; if `@@TRANCOUNT > 1` (nested) -> COMMIT; then `THROW` rethrows the error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID of the link to update. |
| 2 | @FundingID | INT | NO | - | VERIFIED | Payment instrument ID of the link to update. |
| 3 | @DepositTypeID | INT | NO | - | CODE-BACKED | New deposit type classification. FK to Billing.DepositType. Values: 1=Regular, 2=Instant, 3=RecurringDeposit. |
| 4 | @ReasonID | INT | NO | - | CODE-BACKED | New reason code for this link's classification. FK to Billing.Reason. |
| 5 | @CustomerFundingStatusID | INT | NO | - | VERIFIED | New status for this link. Values: 0=Deactivated, 1=Active, 3=RemovedFromDeposit, 4=Extended-Active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT + UPDATE | Billing.CustomerToFunding | Read + Write | Reads current state for history, then updates type/reason/status |
| INSERT INTO | History.ActiveCustomerToFunding | Write | Explicit history archive of pre-update state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment classification service | All params | Caller | Reclassifies a payment instrument link type, reason, and status |

---

## 6. Dependencies

```
Billing.CustomerToFunding_UpdateRecord (procedure)
+-- Billing.CustomerToFunding (table) [SELECT source + UPDATE target]
+-- History.ActiveCustomerToFunding (table) [explicit INSERT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Read current state + UPDATE target |
| History.ActiveCustomerToFunding | Table | Explicit history INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment service reclassification flows | External | Full link reclassification |

---

## 7. Technical Details

**Explicit SELECT + INSERT vs OUTPUT clause**: All other Update procedures in this family use `OUTPUT DELETED.* INTO History`. This procedure uses an explicit `SELECT ... INSERT INTO History` before the UPDATE. The archived row is the state read at the start of the transaction, which may differ from the DELETED pseudo-table state if a concurrent update occurs (though PK-level row locking makes this unlikely in practice).

**Nested transaction handling**: CATCH block checks `@@TRANCOUNT`: `= 1` (outermost) -> ROLLBACK; `> 1` (nested/savepoint) -> COMMIT then THROW. This is the standard eToro nested transaction pattern.

---

## 8. Sample Queries

```sql
EXEC Billing.CustomerToFunding_UpdateRecord
    @CID = 24186018,
    @FundingID = 12345,
    @DepositTypeID = 2,             -- Instant
    @ReasonID = 6,                  -- ByUser
    @CustomerFundingStatusID = 1    -- Active
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_UpdateRecord | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_UpdateRecord.sql*

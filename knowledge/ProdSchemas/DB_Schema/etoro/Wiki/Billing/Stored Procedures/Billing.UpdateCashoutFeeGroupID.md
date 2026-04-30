# Billing.UpdateCashoutFeeGroupID

> Assigns a customer to a specific cashout fee group, overriding the default withdrawal fee schedule applied to that customer's future cashouts.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - targets BackOffice.Customer.CashoutFeeGroupID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateCashoutFeeGroupID` is the administrative procedure for manually assigning or changing a customer's withdrawal fee tier. The `CashoutFeeGroupID` on `BackOffice.Customer` is a FK to `Dictionary.CashoutFeeGroup` that determines which fee schedule applies when the customer requests a cashout (withdrawal). By calling this procedure, operations or compliance staff can override the customer's current fee group assignment - for example, to apply a VIP fee waiver, assign a promotional fee tier, or correct a miscategorization.

The procedure is a single-statement UPDATE with no guard logic - it unconditionally sets the fee group. Validation of valid `CashoutFeeGroupID` values is enforced by the WITH CHECK constraint `BCDC` on the FK to `Dictionary.CashoutFeeGroup`, which prevents invalid group IDs from being set.

A Confluence design document titled "Cashout Fee Groups Auto Assignment Design" (2020) suggests that fee group assignment also has an automated path. This procedure covers the manual override case.

---

## 2. Business Logic

### 2.1 Cashout Fee Group Assignment

**What**: Updates the customer's withdrawal fee tier in BackOffice.Customer to the specified group.

**Columns/Parameters Involved**: `@CID`, `@CashoutFeeGroupID`, `BackOffice.Customer.CashoutFeeGroupID`

**Rules**:
- `UPDATE BackOffice.Customer SET CashoutFeeGroupID = @CashoutFeeGroupID WHERE CID = @CID`
- No prior-state check or conditional logic - unconditional assignment
- FK constraint (WITH CHECK) on `CashoutFeeGroupID -> Dictionary.CashoutFeeGroup` enforces referential integrity at the database level; invalid `@CashoutFeeGroupID` values cause constraint violation
- If `@CID` does not exist, the UPDATE affects 0 rows silently (no error raised)
- `NULL` is a valid value for `CashoutFeeGroupID` (nullable column) - passing `NULL` resets the customer to the default fee group

**Diagram**:
```
Caller: operations/compliance tool
  |
  EXEC UpdateCashoutFeeGroupID @CID=12345, @CashoutFeeGroupID=3
    |
    UPDATE BackOffice.Customer
    SET CashoutFeeGroupID = 3
    WHERE CID = 12345
      |
      -> Dictionary.CashoutFeeGroup FK (WITH CHECK) validates CashoutFeeGroupID=3 exists
      -> Customer's future cashouts now priced per fee group 3's schedule
      -> Previous CashoutFeeGroupID value discarded (no audit trail in this procedure)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID identifying which customer's fee group to update. Maps to `BackOffice.Customer.CID`. If the CID does not exist, the UPDATE silently affects 0 rows. |
| 2 | @CashoutFeeGroupID | INT | YES | - | CODE-BACKED | The fee group to assign to the customer. FK to `Dictionary.CashoutFeeGroup` (WITH CHECK constraint BCDC enforces validity). Determines which withdrawal fee schedule applies to this customer's cashouts. NULL resets to the default fee group. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE CID | BackOffice.Customer | UPDATE (cross-schema) | Target table; sets CashoutFeeGroupID for the specified customer |
| @CashoutFeeGroupID (FK) | Dictionary.CashoutFeeGroup | FK constraint (WITH CHECK) | Enforces referential integrity on the fee group assignment |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No SQL dependents found in SSDT. | - | - | Called externally by operations/compliance tools managing customer fee tier assignments. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateCashoutFeeGroupID (procedure)
└── BackOffice.Customer (table) - UPDATE target
    └── Dictionary.CashoutFeeGroup (table) - FK constraint enforces valid CashoutFeeGroupID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE - sets CashoutFeeGroupID WHERE CID=@CID (cross-schema write) |
| Dictionary.CashoutFeeGroup | Table | Referenced via FK constraint WITH CHECK on BackOffice.Customer.CashoutFeeGroupID; validates @CashoutFeeGroupID at constraint level |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by operations/compliance tooling (manual fee tier assignment). Automated fee group assignment is handled by a separate pathway (Cashout Fee Groups Auto Assignment). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: The FK constraint `BCDC` (WITH CHECK) on `BackOffice.Customer.CashoutFeeGroupID -> Dictionary.CashoutFeeGroup` is the only validation guard. The procedure itself performs no input validation - constraint violations propagate to the caller as errors.

---

## 8. Sample Queries

### 8.1 Execute the procedure to assign a fee group
```sql
-- Assign customer 12345 to cashout fee group 3
EXEC Billing.UpdateCashoutFeeGroupID @CID = 12345, @CashoutFeeGroupID = 3;
```

### 8.2 Verify the current fee group assignment for a customer
```sql
SELECT CID, CashoutFeeGroupID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Look up available cashout fee groups
```sql
SELECT *
FROM Dictionary.CashoutFeeGroup WITH (NOLOCK)
ORDER BY CashoutFeeGroupID;
```

### 8.4 Reset a customer to the default fee group (NULL)
```sql
-- Remove specific fee group assignment, revert to default
EXEC Billing.UpdateCashoutFeeGroupID @CID = 12345, @CashoutFeeGroupID = NULL;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| "Cashout Fee Groups Auto Assignment Design" (Confluence, 2020) | Confluence | Confirms automated fee group assignment logic exists; this SP covers the manual override case. Page body was inaccessible via API. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 1 Confluence (inaccessible) + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateCashoutFeeGroupID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateCashoutFeeGroupID.sql*

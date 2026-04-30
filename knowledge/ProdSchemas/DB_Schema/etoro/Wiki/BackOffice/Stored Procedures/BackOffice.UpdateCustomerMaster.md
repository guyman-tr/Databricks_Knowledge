# BackOffice.UpdateCustomerMaster

> Updates master account linkage, manager permission level, and third-party manager comment for a customer's back-office record, with validation of referenced entities before applying changes.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - targets BackOffice.Customer.CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateCustomerMaster` manages three back-office governance fields on a customer record: the master account link for multi-account hierarchies, the manager permission level, and a free-text comment about third-party account management. These fields control how back-office managers interact with the customer's account.

The procedure exists because all three fields require validation before update - linking to a non-existent master account or an invalid permission level would produce orphaned references. The ISNULL-based partial-update pattern allows callers to update only the fields they need without needing to pass all values every time.

Error 60000 is raised and returned in three failure scenarios: master account CID not found in Customer.Customer, ManagerPermitID not found in Dictionary.ManagerPermit, or the target CID not found in BackOffice.Customer. The procedure is silent on success (no SELECT output).

---

## 2. Business Logic

### 2.1 Partial Update via ISNULL Pattern

**What**: Only the parameters passed with non-NULL values are written to the database; NULL parameters leave the existing column values unchanged.

**Columns/Parameters Involved**: `@MasterAccountCID`, `@ManagerPermitID`, `@ThirdPartyManagerComment`

**Rules**:
- `SET col = ISNULL(@param, col)` - if `@param` is NULL, the column retains its current value.
- Callers can update one or all three fields in a single call without overwriting untouched columns.
- `@MasterAccountCID = NULL` leaves `MasterAccountCID` unchanged; pass `0` to clear the master account link (0 means standalone).

### 2.2 Validation Before Update

**What**: Referential integrity is enforced in application logic since there are no FK constraints on these columns in BackOffice.Customer.

**Columns/Parameters Involved**: `@MasterAccountCID`, `@ManagerPermitID`, `@CID`

**Rules**:
- `@MasterAccountCID > 0`: the customer must exist in `Customer.Customer`. If not, RAISERROR 60000 and RETURN 60000.
- `@ManagerPermitID IS NOT NULL`: the permit must exist in `Dictionary.ManagerPermit`. If not, RAISERROR 60000 and RETURN 60000.
- After UPDATE: if `@@rowcount = 0` (CID not in BackOffice.Customer), RAISERROR 60000 and RETURN 60000.
- Returns no explicit value on success (RETURN 0 implied).

**Diagram**:
```
@MasterAccountCID > 0?
  -> EXISTS in Customer.Customer? NO  -> RAISERROR(60000), RETURN 60000
  -> YES, continue

@ManagerPermitID NOT NULL?
  -> EXISTS in Dictionary.ManagerPermit? NO  -> RAISERROR(60000), RETURN 60000
  -> YES, continue

UPDATE BackOffice.Customer SET ... WHERE CID=@CID
  @@rowcount=0? -> RAISERROR(60000), RETURN 60000
  @@rowcount>0? -> success (implicit RETURN 0)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID of the BackOffice.Customer record to update. Must exist in BackOffice.Customer (@@rowcount=0 check). Primary key of the UPDATE target. |
| 2 | @MasterAccountCID | int | YES | NULL | CODE-BACKED | CID of the master/parent account for multi-account hierarchies (from BackOffice.Customer.MasterAccountCID: "For sub-accounts: the CID of the master/parent account. NULL for standalone accounts"). When NULL, leaves the existing MasterAccountCID unchanged. When > 0, validated to exist in Customer.Customer. Pass 0 to designate this as a standalone account (no master). |
| 3 | @ManagerPermitID | int | YES | NULL | CODE-BACKED | Permission level for the manager assigned to this customer's account (from BackOffice.Customer.ManagerPermitID: "Permission level governing what the assigned manager can do with this customer account. DEFAULT=1"). When NULL, leaves existing ManagerPermitID unchanged. When non-null, validated against Dictionary.ManagerPermit. |
| 4 | @ThirdPartyManagerComment | varchar(255) | YES | NULL | CODE-BACKED | Free-text note about the customer's third-party account management arrangement (from BackOffice.Customer.ThirdPartyManagerComment: "Free-text note about managed account arrangement. Visible in GetCustomerHeader"). When NULL, leaves existing comment unchanged. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | [BackOffice.Customer](../Tables/BackOffice.Customer.md) | UPDATE target | Target customer record to update |
| @MasterAccountCID | Customer.Customer.CID | Validation check | Verifies master account exists before linking |
| @ManagerPermitID | Dictionary.ManagerPermit.ManagerPermitID | Validation check | Verifies permit level exists before assigning |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from back-office application for multi-account and managed-account configuration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateCustomerMaster (procedure)
+-- BackOffice.Customer (table) [UPDATE target]
+-- Customer.Customer (view) [validation: EXISTS check on MasterAccountCID]
+-- Dictionary.ManagerPermit (table) [validation: EXISTS check on ManagerPermitID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.Customer](../Tables/BackOffice.Customer.md) | Table | UPDATE target for MasterAccountCID, ManagerPermitID, ThirdPartyManagerComment |
| Customer.Customer | View | Validation: MasterAccountCID must exist (EXISTS subquery) |
| Dictionary.ManagerPermit | Table | Validation: ManagerPermitID must exist (EXISTS subquery) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from application layer for account hierarchy and permission management. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Application-level validation replaces FK constraints on BackOffice.Customer for these columns.

---

## 8. Sample Queries

### 8.1 Link a customer as a sub-account under a master account

```sql
EXEC BackOffice.UpdateCustomerMaster
    @CID             = 99999,
    @MasterAccountCID = 11111,  -- master account CID (must exist in Customer.Customer)
    @ManagerPermitID = NULL,    -- leave unchanged
    @ThirdPartyManagerComment = NULL;  -- leave unchanged
```

### 8.2 Update only the manager permission level

```sql
EXEC BackOffice.UpdateCustomerMaster
    @CID              = 99999,
    @MasterAccountCID = NULL,  -- leave master account unchanged
    @ManagerPermitID  = 3;     -- set new permit level (must exist in Dictionary.ManagerPermit)
```

### 8.3 Verify the resulting state

```sql
SELECT CID, MasterAccountCID, ManagerPermitID, ThirdPartyManagerComment
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 99999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateCustomerMaster | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateCustomerMaster.sql*

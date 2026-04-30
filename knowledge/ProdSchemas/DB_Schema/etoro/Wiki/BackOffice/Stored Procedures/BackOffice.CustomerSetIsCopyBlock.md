# BackOffice.CustomerSetIsCopyBlock

> Sets the copy-block flag on a customer account, preventing that customer from being copied by other traders on the CopyTrader platform.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID - global customer identifier (resolved to CID for the update) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerSetIsCopyBlock is an administrative procedure that enables compliance and operations teams to block a specific customer from being copied on the eToro CopyTrader feature. When a customer is "copy-blocked", other users cannot start copying their trading activity. This is typically used as a risk management or compliance action - for example, when a customer's trading activity is under review or when regulatory obligations require restricting their public influence on the platform.

The procedure accepts a Global Customer ID (GCID), resolves it to an internal CID via `Customer.CustomerStatic`, and then toggles the `IsCopyBlocked` flag in `BackOffice.Customer`. Because the flag is a BIT, the same procedure serves both to apply and to remove the copy-block (passing 1 blocks, passing 0 unblocks).

Data flows from BackOffice tooling (compliance/operations user action) through this procedure into `BackOffice.Customer.IsCopyBlocked`. The flag is subsequently read by trading-layer procedures (e.g., `Trade.GetUserTradeStatusData`, `Trade.GetCustomersDataWithCopyRestirctions`) and exposed in the regulation reporting view `dbo.V_Regulation_JunkNoga240325` to enforce the block during order-open context checks.

---

## 2. Business Logic

### 2.1 GCID-to-CID Resolution

**What**: eToro's public-facing identifier for a customer is the GCID (Global Customer ID). Internally, many tables are keyed on CID (Customer ID). This procedure bridges the gap.

**Columns/Parameters Involved**: `@GCID`, `@CID` (local variable), `Customer.CustomerStatic.GCID`, `Customer.CustomerStatic.CID`

**Rules**:
- `@GCID` is resolved to `@CID` via `SELECT @CID = CID FROM Customer.CustomerStatic WITH(NOLOCK) WHERE GCID = @GCID`.
- If `@GCID` does not exist in `Customer.CustomerStatic`, `@CID` remains NULL and the subsequent `UPDATE` affects 0 rows (silent no-op - no error is raised).
- The procedure returns `@@ERROR` after the UPDATE - if the UPDATE itself fails (e.g., lock timeout), the error code is propagated to the caller.

**Diagram**:
```
Application (BackOffice UI/API)
  |
  | EXEC BackOffice.CustomerSetIsCopyBlock @GCID=..., @IsCopyBlock=1
  v
Customer.CustomerStatic --[GCID -> CID]--> BackOffice.Customer.IsCopyBlocked = 1
```

### 2.2 Copy-Block Toggle (Apply / Remove)

**What**: A single procedure handles both blocking and unblocking by design.

**Columns/Parameters Involved**: `@IsCopyBlock`, `BackOffice.Customer.IsCopyBlocked`

**Rules**:
- `@IsCopyBlock = 1`: blocks the customer from being copied.
- `@IsCopyBlock = 0`: removes the copy-block, allowing copying again.
- No guard condition checks the current state before writing - the UPDATE always fires regardless of the current value of `IsCopyBlocked`.
- No audit record is written by this procedure directly; any history is captured by the trigger on `BackOffice.Customer` (CustomerHistoryUpdate -> History.BackOfficeCustomer).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INTEGER | NO | - | CODE-BACKED | Global Customer ID - the external/public identifier for the customer. Resolved to internal CID via Customer.CustomerStatic before the update. |
| 2 | @IsCopyBlock | BIT | NO | - | CODE-BACKED | The desired copy-block state to apply: 1 = block the customer from being copied by others, 0 = remove the block and allow copying again. Mapped directly to BackOffice.Customer.IsCopyBlocked. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerStatic | Lookup | Resolves @GCID to internal CID via SELECT. Customer.CustomerStatic is the identity-mapping table for all customers. |
| @CID (resolved) | BackOffice.Customer | Modifier | UPDATE target - sets IsCopyBlocked on the customer's operational profile row. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application (BackOffice UI/service) | GCID, IsCopyBlock flag | EXEC | Called from BackOffice tooling when a compliance/operations agent applies or removes a copy-block on a customer account. No SQL-layer callers discovered. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetIsCopyBlock (procedure)
├── Customer.CustomerStatic (table) - GCID-to-CID lookup
└── BackOffice.Customer (table) - UPDATE target for IsCopyBlocked flag
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT to resolve @GCID to internal @CID |
| BackOffice.Customer | Table | UPDATE - sets IsCopyBlocked = @IsCopyBlock WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application (BackOffice service) | External | Calls this procedure to apply/remove copy-block on a customer |
| Trade.GetUserTradeStatusData | Procedure | Reads IsCopyBlocked (via CBO join) to determine if copy is blocked at trade time |
| Trade.GetCustomersDataWithCopyRestirctions | Procedure | Reads IsCopyBlocked as part of customer data result set |
| dbo.V_Regulation_JunkNoga240325 | View | Exposes IsCopyBlocked from BackOffice.Customer for regulation reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @@ERROR return | Convention | Returns the SQL error code of the UPDATE. 0 = success. Caller responsible for checking the return value. |
| Silent no-op on unknown GCID | Behavior | If @GCID is not found in Customer.CustomerStatic, @CID is NULL and the UPDATE affects 0 rows without raising an error. |

---

## 8. Sample Queries

### 8.1 Block a customer from being copied (by GCID)
```sql
EXEC BackOffice.CustomerSetIsCopyBlock @GCID = 123456789, @IsCopyBlock = 1
```

### 8.2 Remove the copy-block for a customer
```sql
EXEC BackOffice.CustomerSetIsCopyBlock @GCID = 123456789, @IsCopyBlock = 0
```

### 8.3 Verify the current copy-block state for a customer
```sql
SELECT
    cs.GCID,
    cs.CID,
    bc.IsCopyBlocked,
    cs.UserName
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID = cs.CID
WHERE cs.GCID = 123456789
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSetIsCopyBlock | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetIsCopyBlock.sql*

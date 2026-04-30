# BackOffice.CustomerSetCashoutFeeGroup

> Sets CashoutFeeGroupID on BackOffice.Customer for a single customer. Single-row counterpart to BackOffice.CashoutFeeGroupBulkUpdate. Returns @@ERROR for backward compatibility.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure sets the cashout fee group for a single customer by updating `BackOffice.Customer.CashoutFeeGroupID`. It is the single-customer counterpart to `BackOffice.CashoutFeeGroupBulkUpdate` (which handles batch TVP updates).

`CashoutFeeGroupID` controls the fee rate applied when a customer withdraws (cashouts) funds. Customers in higher tiers (Popular Investors with high Guru Status, Club members) may be in an Exempt group (no cashout fee), while standard users are in the Default group. See `BackOffice.CashoutFeeGroupBulkUpdate` for full business context on fee group assignment.

The `@CalledFromDynamics BIT=0` parameter is present but contains no conditional logic - it is not used in any branching within the procedure. This suggests the parameter was added for a planned integration or backwards-compatibility shim that was never implemented.

The comment notes this was originally a version that returned @@ERROR after the Customer update, and that behavior is preserved for backwards compatibility.

---

## 2. Business Logic

### 2.1 Simple Update with Legacy Error Return

**What**: Updates CashoutFeeGroupID with no validation. Returns @@ERROR for backward compatibility.

**Rules**:
- UPDATE BackOffice.Customer SET CashoutFeeGroupID=@CashoutFeeGroupID WHERE CID=@CID
- SET @Err = @@ERROR
- RETURN @Err: 0=success, non-zero=SQL error (no validation of CashoutFeeGroupID value)
- SET NOCOUNT ON: no row count messages
- No CID existence check: silent no-op if CID not found
- No CashoutFeeGroupID validation: no check against Dictionary.CashoutFeeGroup
- @CalledFromDynamics parameter: declared but never used in any conditional logic

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. No existence validation - silent no-op if not found in BackOffice.Customer. |
| 2 | @CashoutFeeGroupID | INT | NO | - | CODE-BACKED | Cashout fee group to assign. No validation against Dictionary.CashoutFeeGroup - caller is responsible for correct values. See BackOffice.CashoutFeeGroupBulkUpdate for valid values (Default, Exempt, intermediate tiers). |
| 3 | @CalledFromDynamics | BIT | YES | 0 | CODE-BACKED | Unused flag. Present for backward compatibility or planned future use. Has no effect on procedure behavior. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 4 | RETURN | INT | @@ERROR value after UPDATE. 0=success. Non-zero=SQL error code. Legacy pattern retained for backward compatibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | UPDATE | Sets CashoutFeeGroupID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Cashout fee group assignment workflows | External | Direct call | Single-customer fee group update (vs bulk TVP path in CashoutFeeGroupBulkUpdate) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetCashoutFeeGroup (procedure)
|- BackOffice.Customer (table) [UPDATE: CashoutFeeGroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: CashoutFeeGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Cashout fee group assignment service | External | Single-row updates (bulk updates handled by CashoutFeeGroupBulkUpdate) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @@ERROR | Design | Legacy error-return pattern retained for backward compatibility |
| No validation | Design | No CashoutFeeGroupID check against Dictionary.CashoutFeeGroup; caller validates |
| @CalledFromDynamics unused | Code quality | Parameter present but has no effect on behavior |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Set cashout fee group for a customer

```sql
DECLARE @Ret INT;
EXEC @Ret = BackOffice.CustomerSetCashoutFeeGroup
    @CID = 12345,
    @CashoutFeeGroupID = 1,   -- e.g., Default
    @CalledFromDynamics = 0;
SELECT @Ret AS ReturnCode; -- 0 = success
```

### 8.2 Check valid fee group values

```sql
SELECT CashoutFeeGroupID, Name
FROM Dictionary.CashoutFeeGroup WITH (NOLOCK)
ORDER BY CashoutFeeGroupID;
```

### 8.3 Compare with bulk update path

```sql
-- Single update: EXEC BackOffice.CustomerSetCashoutFeeGroup
-- Bulk update:   EXEC BackOffice.CashoutFeeGroupBulkUpdate @tbl = (TVP of CID+FeeGroupID pairs)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Cashout Fee Groups Auto Assignment Design](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1242726429) | Confluence | Fee group values, assignment rules by Club Group and Guru Status (see BackOffice.CashoutFeeGroupBulkUpdate for full context) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerSetCashoutFeeGroup | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetCashoutFeeGroup.sql*

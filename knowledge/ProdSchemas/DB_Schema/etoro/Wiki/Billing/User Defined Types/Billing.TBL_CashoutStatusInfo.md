# Billing.TBL_CashoutStatusInfo

> Table-valued parameter type carrying cashout record status update data, used to pass bulk cashout status changes to `Billing.UpsertWithdraw` within cashout lifecycle procedures.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | ID (PRIMARY KEY CLUSTERED, IGNORE_DUP_KEY) |
| **Partition** | N/A |
| **Indexes** | 1 - PRIMARY KEY CLUSTERED on ID |

---

## 1. Business Meaning

`Billing.TBL_CashoutStatusInfo` is a table-valued parameter (TVP) type that carries cashout (withdrawal) record data for status updates. Each row contains a cashout record identifier, the manager performing the action, a remark, and the current and new cashout status values. It is used as an intermediate staging type within cashout lifecycle stored procedures that call `Billing.UpsertWithdraw`.

This type exists as part of a refactoring pattern (DBA-648, Shay Oren 23/09/2021) that replaced direct `UPDATE Billing.Withdraw` and `UPDATE Billing.WithdrawToFunding` statements with TVP-based upsert procedures. This allows the upsert logic to be centralized and ensures history logging occurs consistently. `TBL_CashoutStatusInfo` is used specifically in `Billing.CashoutRequestUpdate` to stage the status transition data before calling `Billing.UpsertWithdraw`.

Data flows within stored procedures: a procedure declares a local variable of this type, inserts the current/new status values into it, then passes it to `Billing.UpsertWithdraw` which performs the actual `UPDATE` on `Billing.Withdraw`.

---

## 2. Business Logic

### 2.1 Cashout Status Transition Staging

**What**: Carries the before/after cashout status pair for a single cashout record, enabling the upsert procedure to track state transitions and write history.

**Columns/Parameters Involved**: `ID`, `CashoutStatusID`, `NewCashoutStatusID`, `ManagerID`, `Remark`

**Rules**:
- `ID` is the `WithdrawID` from `Billing.Withdraw` - the PRIMARY KEY ensures no duplicate rows
- `CashoutStatusID` holds the current (pre-update) status for history logging
- `NewCashoutStatusID` holds the target status to transition to
- `ManagerID` identifies the BackOffice manager authorizing or processing the status change (NULL for system-initiated changes)
- `Remark` carries an optional note explaining the status transition

**Diagram**:
```
CashoutRequestUpdate procedure:
  1. Verifies Withdraw is in Pending (CashoutStatusID=1) state
  2. Declares @Info [Billing].[TBL_CashoutStatusInfo]
  3. Inserts: ID=@CashoutID, CashoutStatusID=1(current), NewCashoutStatusID=2(InProcess)
  4. EXEC Billing.UpsertWithdraw @Info
     -> updates Billing.Withdraw.CashoutStatusID = 2 (InProcess)
     -> writes to History.WithdrawAction
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key of the cashout record - maps to `Billing.Withdraw.WithdrawID`. CLUSTERED PRIMARY KEY with IGNORE_DUP_KEY ensures one row per cashout in the TVP. |
| 2 | ManagerID | int | YES | NULL | CODE-BACKED | BackOffice manager ID performing the status change. References `BackOffice.Manager` (implicit). NULL for system-initiated transitions. |
| 3 | Remark | varchar(255) | YES | NULL | CODE-BACKED | Optional note describing the reason for the status transition. Stored as a comment on the status change in history. Collation: Latin1_General_BIN. |
| 4 | CashoutStatusID | int | YES | NULL | CODE-BACKED | Current (pre-update) cashout status, for history logging purposes. See [Cashout Status](_glossary.md#cashout-status) for values (e.g., 1=Pending, 2=InProcess). |
| 5 | NewCashoutStatusID | int | YES | NULL | CODE-BACKED | Target cashout status to transition to. See [Cashout Status](_glossary.md#cashout-status) for values. The upsert procedure applies this as the new `CashoutStatusID` on the `Billing.Withdraw` record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | Billing.Withdraw | Implicit | Maps to Billing.Withdraw.WithdrawID |
| ManagerID | BackOffice.Manager | Implicit | Manager performing the status change |
| CashoutStatusID | Dictionary.CashoutStatus | Lookup | Current cashout lifecycle state |
| NewCashoutStatusID | Dictionary.CashoutStatus | Lookup | Target cashout lifecycle state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CashoutRequestUpdate | @Info (local variable) | TVP (local) | Declared locally, populated with status transition data, passed to UpsertWithdraw |
| Billing.UpsertWithdraw | @Info parameter | TVP Parameter | Receives this type to perform the actual Withdraw table update and history logging |
| Billing.WithdrawToFundingUpdateCashoutStatusForBatch | @tbl parameter | TVP Parameter | Batch update of WTF CashoutStatusID via this type; iterates each row calling WithdrawToFundingUpdateCashoutStatus |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutRequestUpdate | Stored Procedure | Declares local variable of this type; stages status transition data; passes to UpsertWithdraw |
| Billing.UpsertWithdraw | Stored Procedure | Accepts this type (or TBL_Withdraw) to perform the actual UPDATE on Billing.Withdraw |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY CLUSTERED (ID) | PRIMARY KEY | Ensures one row per cashout record (WithdrawID) in the TVP. IGNORE_DUP_KEY=OFF means duplicate inserts will error. |

---

## 8. Sample Queries

### 8.1 Inspect type column definitions

```sql
SELECT c.name, t.name AS type_name, c.max_length, c.is_nullable
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name = 'TBL_CashoutStatusInfo'
ORDER BY c.column_id
```

### 8.2 View pending cashout requests ready for status transition

```sql
SELECT TOP 20
    w.WithdrawID,
    w.CID,
    w.CashoutStatusID,
    cs.Name AS StatusName,
    w.Amount,
    w.RequestDate,
    w.ModificationDate
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = w.CashoutStatusID
WHERE w.CashoutStatusID = 1  -- Pending
ORDER BY w.RequestDate ASC
```

### 8.3 Track recent cashout status transitions in history

```sql
SELECT TOP 20
    wa.WithdrawID,
    cs_old.Name AS OldStatus,
    cs_new.Name AS NewStatus,
    wa.ManagerID,
    wa.ModificationDate,
    wa.Comment AS Remark
FROM History.WithdrawAction wa WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs_old WITH (NOLOCK) ON cs_old.CashoutStatusID = wa.CashoutStatusID
LEFT JOIN Dictionary.CashoutStatus cs_new WITH (NOLOCK)
    ON cs_new.CashoutStatusID = LEAD(wa.CashoutStatusID) OVER (PARTITION BY wa.WithdrawID ORDER BY wa.ModificationDate)
ORDER BY wa.ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.TBL_CashoutStatusInfo | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.TBL_CashoutStatusInfo.sql*

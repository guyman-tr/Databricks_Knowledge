# Dictionary.RedeemStatus

> Lookup table defining the 7 lifecycle states of a copy-trading fund redemption (stop-copy with funds return).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RedeemStatusID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.RedeemStatus tracks the lifecycle of a "redeem" operation — the process of stopping a copy-trading relationship and returning funds to the copier. When a user stops copying another trader, all mirrored positions must be closed, PnL must be calculated, and the remaining equity must be returned to the copier's available balance.

This is a complex financial operation involving position closure, fee calculations, and fund transfer. The status tracks each step to ensure completeness and enable error recovery. The IsCancelable flag indicates whether the user can still abort the redemption.

RedeemStatusID is stored in copy-trading redeem request records and checked by Trade procedures managing the redemption workflow.

---

## 2. Business Logic

### 2.1 Redeem Lifecycle

**What**: Redemption flows through processing states with clear cancel/no-cancel boundaries.

**Columns/Parameters Involved**: `RedeemStatusID`, `Name`, `IsCancelable`

**Rules**:
- Initial submission → IsCancelable=1 (user can still abort)
- Once positions start closing → IsCancelable=0 (point of no return)
- Processing involves: closing all mirrored positions, calculating PnL, deducting fees, returning remaining equity
- Final states: Completed (success), Failed (error requiring manual intervention)

---

## 3. Data Overview

| RedeemStatusID | Name | DisplayName | IsCancelable | Meaning |
|---|---|---|---|---|
| 1 | Pending | Pending | 1 | Redeem request submitted. Positions have not started closing. User can still cancel. |
| 2 | InProcess | In Process | 0 | Positions are being closed. Cannot be canceled — the system is actively unwinding the mirrored portfolio. |
| 3 | Completed | Completed | 0 | All positions closed, PnL calculated, funds returned to copier's balance. Terminal success state. |
| 5 | Failed | Failed | 0 | Redemption encountered an error during processing. Requires manual intervention by operations team. |
| 6 | CompletedPartially | Partially Completed | 0 | Some positions were closed but the full redemption couldn't complete. Partial funds returned. Needs manual review. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedeemStatusID | int | NO | - | CODE-BACKED | Primary key identifying the redeem lifecycle state. See [Redeem Status](_glossary.md#redeem-status). (Dictionary.RedeemStatus) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Internal code name used in procedures and API responses. |
| 3 | DisplayName | varchar(50) | NO | - | CODE-BACKED | User-facing display label. More readable than the internal Name. Shown in copy-trading UI and notifications. |
| 4 | IsCancelable | bit | NO | (0) | CODE-BACKED | Whether the user can still cancel the redeem request at this stage. 1=cancellable (Pending), 0=committed (InProcess, Completed, Failed). The cancel boundary is the point when positions start closing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade redeem tables | RedeemStatusID | Implicit Lookup | Tracks redemption progress |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RedeemStatus | CLUSTERED PK | RedeemStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_DictionaryRedeemStatus_IsCalcelable | DEFAULT | IsCancelable defaults to 0 (note: original constraint name has typo "Calcelable") |

---

## 8. Sample Queries

### 8.1 List all redeem statuses
```sql
SELECT RedeemStatusID, Name, DisplayName, IsCancelable
FROM [Dictionary].[RedeemStatus] WITH (NOLOCK) ORDER BY RedeemStatusID;
```

### 8.2 Find in-progress redemptions
```sql
SELECT r.*, rs.DisplayName
FROM [Trade].[Redeem] r WITH (NOLOCK)
JOIN [Dictionary].[RedeemStatus] rs WITH (NOLOCK) ON r.RedeemStatusID = rs.RedeemStatusID
WHERE rs.IsCancelable = 0 AND rs.RedeemStatusID NOT IN (3, 5);
```

---

*Generated: 2026-03-13 | Quality: 8.0/10*
*Object: Dictionary.RedeemStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RedeemStatus.sql*

# MoneyBus.WithdrawUpdate

> Updates a withdrawal record's status, financial details, and error information as it progresses through the hold-authorize-payout pipeline, using ISNULL to only modify provided fields.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Withdrawals row by ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawUpdate is called at each step of the withdrawal pipeline to advance the withdrawal's state. As the withdrawal progresses from Created through Hold, Authorize, Payout (or Abort), this procedure updates the StatusID, StatusReasonID, and any associated data (exchange rates, USD amounts, error descriptions, provider references).

The procedure uses the ISNULL pattern: each column is updated as `SET Col = ISNULL(@Param, Col)`, meaning only non-NULL parameters actually change the value. This allows the caller to update only the fields that changed at each pipeline step without affecting others. Modified is always set to GETDATE() on every update.

---

## 2. Business Logic

### 2.1 Selective Column Update Pattern

**What**: Only non-NULL parameters modify their respective columns, enabling incremental state updates.

**Columns/Parameters Involved**: All optional parameters

**Rules**:
- Each field uses `ISNULL(@Param, CurrentValue)` - NULL params preserve existing values
- Modified is always set to GETDATE() (not optional)
- This enables pipeline steps to update only their relevant fields:
  - Hold step: updates StatusID, StatusReasonID
  - Payout step: additionally updates ExchangeRate, AmountInUsd
  - Error step: additionally updates StatusReasonDescription, ErrorDescription
- @@ROWCOUNT is returned as UpdatedCount for caller verification

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint | NO | - | CODE-BACKED | The Withdrawals.ID to update. PK lookup. |
| 2 | @StatusID | int | YES | NULL | CODE-BACKED | New high-level status. NULL preserves current value. See [Withdraw Status](../../_glossary.md#withdraw-status). |
| 3 | @StatusReasonID | int | YES | NULL | CODE-BACKED | New detail status reason. NULL preserves current value. See [Withdraw Status Reason](../../_glossary.md#withdraw-status-reason). |
| 4 | @ReferenceID | nvarchar(500) | YES | NULL | CODE-BACKED | Updated external reference. NULL preserves current value. |
| 5 | @ApprovalID | int | YES | NULL | CODE-BACKED | Updated approval reference. NULL preserves current value. |
| 6 | @ExtID | nvarchar(200) | YES | NULL | CODE-BACKED | Updated external provider ID. NULL preserves current value. |
| 7 | @CorrelationID | varchar(200) | YES | NULL | CODE-BACKED | Updated correlation ID. NULL preserves current value. |
| 8 | @ExtraData | nvarchar(4000) | YES | NULL | CODE-BACKED | Updated JSON metadata. NULL preserves current value. |
| 9 | @ManagerID | int | YES | NULL | CODE-BACKED | Manager ID for back-office actions. NULL preserves current value. |
| 10 | @ExchangeRate | decimal(18,6) | YES | NULL | CODE-BACKED | Exchange rate applied during payout. NULL preserves current value. Set during payout step. |
| 11 | @AmountInUsd | decimal(18,6) | YES | NULL | CODE-BACKED | USD equivalent of withdrawal amount. NULL preserves current value. Calculated as Amount * ExchangeRate. |
| 12 | @StatusReasonDescription | nvarchar(4000) | YES | NULL | CODE-BACKED | Human-readable status description or risk review JSON. NULL preserves current value. |
| 13 | @ErrorDescription | nvarchar(4000) | YES | NULL | CODE-BACKED | Provider error message. NULL preserves current value. Set when a pipeline step fails. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE target) | MoneyBus.Withdrawals | Modifier | Updates withdrawal as it progresses through pipeline |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawUpdate (procedure)
└── MoneyBus.Withdrawals (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | UPDATE - modifies withdrawal state |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update status to PayoutApproved (success)
```sql
EXEC MoneyBus.WithdrawUpdate @ID = 773487,
    @StatusID = 2, @StatusReasonID = 10,
    @ExchangeRate = 1.35560, @AmountInUsd = 1220.04;
```

### 8.2 Update with error (abort)
```sql
EXEC MoneyBus.WithdrawUpdate @ID = 773480,
    @StatusID = 5, @StatusReasonID = 13,
    @StatusReasonDescription = 'Withdraw cancel request initiated by Aborted',
    @ErrorDescription = 'Account suspended';
```

### 8.3 Update only status reason (pipeline step advance)
```sql
EXEC MoneyBus.WithdrawUpdate @ID = 773459,
    @StatusReasonID = 4; -- HoldApproved
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawUpdate | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawUpdate.sql*

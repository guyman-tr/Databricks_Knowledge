# Trade.SetMirrorStopLossPercentage

> Updates the stop-loss percentage and corresponding dollar amount for an active copy-trade mirror, logging the change to Trade.PostDetachOperation, as called by the MOE (Mirror Operation Engine) service.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure changes the stop-loss percentage protection level on a copy-trade mirror. Copy-trade followers can set a maximum loss percentage (e.g., 50%) at which the entire mirror automatically closes to protect their invested capital. This procedure is how that setting is updated when a follower edits their stop-loss protection.

Without this procedure, there would be no safe, audited way to change a mirror's stop-loss. The PostDetachOperation log entry (with MirrorOperationID=9 "Set Percentages") ensures that every SL percentage change is traceable for compliance and debugging.

The procedure is called by the MOE (Mirror Operation Engine) service's `MirrorOperationRepository`, via the `MirrorEditStopLossPercentageRequestProcessor` which processes `MirrorPauseCopyRequest` messages from RabbitMQ. The processor validates the new percentage and feasibility before calling this procedure (Per Confluence: Moe - Mirror Operation Engine). Relevant error codes: MIRROR_SET_SL_FAILURE, MIRROR_STOP_LOSS_PERCENTAGE_DELTA_INVALID, MIRROR_TYPE_STOP_LOSS_PERCENTAGE_OUT_OF_RANGE.

The procedure checks that the mirror is still active (IsActive=1) before updating. If the mirror is not active or not found, the transaction is committed with no rows changed and the procedure returns without setting @Success=1.

---

## 2. Business Logic

### 2.1 Active-Mirror Guard

**What**: Ensures stop-loss can only be changed on mirrors that are currently active (not already closing or stopped).

**Columns/Parameters Involved**: `Trade.Mirror.IsActive`, `@MirrorID`, `@Success`

**Rules**:
- UPDATE only executes WHERE MirrorID = @MirrorID AND IsActive = 1
- If @@ROWCOUNT = 0 (mirror inactive or not found), COMMIT and RETURN immediately with @Success still = 0
- @Success is set to 1 only after a successful UPDATE + INSERT

**Diagram**:
```
UPDATE Trade.Mirror WHERE MirrorID=@MirrorID AND IsActive=1
  |
  +-- @@ROWCOUNT = 0 --> COMMIT, RETURN (@Success=0 - mirror inactive)
  |
  +-- @@ROWCOUNT > 0 --> INSERT PostDetachOperation, SET @Success=1
```

### 2.2 Dual-Value SL Update (Percentage + Amount)

**What**: The stop-loss is tracked as both a percentage of invested amount and a calculated dollar amount; both must be updated together for consistency.

**Columns/Parameters Involved**: `@Percentage`, `@NewSLAmount`, `Trade.Mirror.MirrorSLPercentage`, `Trade.Mirror.MirrorSL`

**Rules**:
- MirrorSLPercentage stores the percentage (e.g., 0.50 for 50%)
- MirrorSL stores the dollar amount at the time of update (pre-calculated by the caller from equity data)
- Both are always updated atomically in the same UPDATE statement
- The caller (MOE EquityCalculator) computes @NewSLAmount based on current portfolio equity and the desired percentage

### 2.3 PostDetachOperation Log Entry

**What**: Every SL percentage change is recorded in Trade.PostDetachOperation with MirrorOperationID=9 ("Set Percentages") for audit and history.

**Columns/Parameters Involved**: `Trade.PostDetachOperation.H_M_MirrorOperationID`, `Trade.PostDetachOperation.H_M_MirrorOprationDB`, `Trade.PostDetachOperation.StatusID`

**Rules**:
- MirrorOperationID = 9 (hardcoded constant = "Set Percentages" per inline code comment)
- H_M_MirrorOprationDB = 'SetMirrorStopLossPercentage' (source procedure identifier)
- StatusID = 0 (initial state for the PostDetach log entry)
- All current Trade.Mirror field values are copied into the corresponding H_M_* prefixed columns

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | Unique identifier of the copy-trade mirror whose stop-loss is being updated. Used in WHERE clause for both the UPDATE and the PostDetachOperation INSERT. |
| 2 | @Percentage | MONEY | NO | - | CODE-BACKED | New stop-loss percentage value (e.g., 0.50 = 50%). Stored in Trade.Mirror.MirrorSLPercentage. Validated by MOE caller to be within type-specific allowed range (error: MIRROR_TYPE_STOP_LOSS_PERCENTAGE_OUT_OF_RANGE). |
| 3 | @NewSLAmount | MONEY | NO | - | CODE-BACKED | Calculated dollar amount corresponding to the stop-loss percentage, computed by the MOE EquityCalculator based on current mirror equity. Stored in Trade.Mirror.MirrorSL. |
| 4 | @Success | BIT | NO | OUTPUT | CODE-BACKED | OUTPUT parameter: 1 = update succeeded (mirror was active and updated), 0 = update skipped (mirror was not found or inactive). Initialized to 0 on entry. |
| 5 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session identifier from the calling service for end-to-end request tracing. Written to PostDetachOperation H_M_SessionID column. |
| 6 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client-side request GUID for distributed tracing. Written to PostDetachOperation H_M_ClientRequestGuid column. Added per ticket 51445 (2018-06-28) per inline code comment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Modifier | Updates MirrorSLPercentage and MirrorSL; also read for the PostDetachOperation INSERT |
| MirrorOperationID=9 | Trade.PostDetachOperation | Writer | Appends "Set Percentages" audit record capturing the full mirror state at time of change |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MOE MirrorOperationRepository | MirrorEditStopLossPercentageRequestProcessor | CALLER | Called by MOE service when processing MirrorPauseCopyRequest messages for SL percentage edits (Per Confluence: Moe - Mirror Operation Engine) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetMirrorStopLossPercentage (procedure)
├── Trade.Mirror (table) [read for PostDetach INSERT + updated MirrorSLPercentage/MirrorSL]
└── Trade.PostDetachOperation (table) [log entry with MirrorOperationID=9 (Set Percentages)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Read for current row values (all columns for PostDetach INSERT) and updated (MirrorSLPercentage, MirrorSL) |
| Trade.PostDetachOperation | Table | Inserted into: audit record of the SL percentage change with MirrorOperationID=9 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MOE - Mirror Operation Engine (AKS service) | External service | Calls via MirrorEditStopLossPercentageRequestProcessor for SL percentage updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsActive = 1 guard | Business validation | UPDATE only runs on active mirrors; inactive mirrors silently skip with @Success=0 |
| MirrorOperationID = 9 | Hardcoded constant | "Set Percentages" operation type in PostDetachOperation log |
| Transaction safety | Implementation | ROLLBACK if @@TRANCOUNT=1, COMMIT if @@TRANCOUNT>1 (nested transaction support) |

---

## 8. Sample Queries

### 8.1 Update stop-loss percentage to 50% for a mirror

```sql
DECLARE @Success BIT;
EXEC Trade.SetMirrorStopLossPercentage
    @MirrorID = 67890,
    @Percentage = 0.50,
    @NewSLAmount = 500.00,  -- pre-calculated dollar amount
    @Success = @Success OUTPUT,
    @SessionID = 9999999,
    @ClientRequestGuid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
SELECT @Success AS WasUpdated;
```

### 8.2 Check current SL percentage for a mirror

```sql
SELECT MirrorID, IsActive, MirrorSLPercentage, MirrorSL, Amount
FROM Trade.Mirror WITH (NOLOCK)
WHERE MirrorID = 67890;
```

### 8.3 Review SL percentage change history

```sql
SELECT TOP 10
    H_M_MirrorID, H_M_MirrorOperationID, H_M_MirrorSLPercentage, H_M_MirrorSL,
    H_M_MirrorOprationDB, StatusID
FROM Trade.PostDetachOperation WITH (NOLOCK)
WHERE H_M_MirrorID = 67890
AND H_M_MirrorOperationID = 9 -- Set Percentages
ORDER BY H_M_Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Moe - Mirror Operation Engine](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12857836033/Moe+-+Mirror+Operation+Engine) | Confluence | SetMirrorStopLossPercentage is in MirrorOperationRepository; called by MirrorEditStopLossPercentageRequestProcessor; validates percentage feasibility using EquityCalculator; error codes: MIRROR_SET_SL_FAILURE, MIRROR_STOP_LOSS_PERCENTAGE_DELTA_INVALID, MIRROR_TYPE_STOP_LOSS_PERCENTAGE_OUT_OF_RANGE |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller (MOE service) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetMirrorStopLossPercentage | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetMirrorStopLossPercentage.sql*

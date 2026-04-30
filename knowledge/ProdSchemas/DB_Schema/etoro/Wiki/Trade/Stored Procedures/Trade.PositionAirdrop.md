# Trade.PositionAirdrop

> Opens a new position as a corporate action airdrop - compensating the customer's balance, calling Trade.PositionOpen, and marking the airdrop record as executed in Trade.PositionAirdropLog.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AirdropID + @TerminalID (the airdrop event and program) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Position airdrops are corporate actions where a company distributes instrument positions (shares, units) to existing holders - as distinct from cash airdrops (which pay cash). For example, a company may airdrop 1 unit of a new token to every holder of their existing instrument.

This procedure is the execution unit for a single position airdrop: given all the parameters needed to open a position, it:
1. Compensates the customer's balance (to fund the position)
2. Opens the position at zero-profit via Trade.PositionOpen
3. Marks the airdrop record as successfully executed

The `@TerminalID` identifies the airdrop program. The procedure resolves the `CompensationReasonID` and `OpenPositionActionType` from the `Dictionary.CorporateAction` table (joined via `Trade.TerminalIDToCorporateAction`). The action type distinguishes "Stock Dividend" airdrops (OpenPositionActionType=4) from other airdrop types (OpenPositionActionType=5).

Created for the US project (Jira: TRADCD-753, August 2021). The `@PositionID` is an OUTPUT parameter - the new position's ID is assigned by Trade.PositionOpen and returned to the caller.

---

## 2. Business Logic

### 2.1 Corporate Action Type Resolution

**What**: Resolves the compensation reason and position action type from the terminal ID.

**Columns/Parameters Involved**: `Dictionary.CorporateAction.CompensationReasonID`, `Dictionary.CorporateAction.Description`, `Trade.TerminalIDToCorporateAction.TerminalID`

**Rules**:
- SELECT CompensationReasonID, CASE WHEN Description='Stock Dividend' THEN 4 ELSE 5 END AS OpenPositionActionType
- FROM Dictionary.CorporateAction JOIN Trade.TerminalIDToCorporateAction ON CorporateActionTypeID
- WHERE b.TerminalID = @TerminalID
- IF @CompensationReasonID IS NULL OR @OpenPositionActionType IS NULL: RAISERROR and stop
- This lookup ties the @TerminalID string to the correct accounting category and position open action type

**Diagram**:
```
@TerminalID -> TerminalIDToCorporateAction -> CorporateActionTypeID -> Dictionary.CorporateAction
  Description='Stock Dividend' -> OpenPositionActionType=4
  Description=other -> OpenPositionActionType=5
  -> CompensationReasonID (airdrop-specific reason code)
```

### 2.2 Balance Compensation (Pre-Position Open)

**What**: Credits the customer's balance to fund the position before opening it.

**Columns/Parameters Involved**: `@CompensationReasonID`, `@InitialPositionAmount`, `Customer.SetBalanceCompensation`

**Rules**:
- EXEC Customer.SetBalanceCompensation
  - @CID = @CID
  - @Payment = @InitialPositionAmount (the seed amount for the position in the appropriate unit)
  - @Description = 'Promotion' (hardcoded description for all airdrops)
  - @ManagerID = resolved from BackOffice.Customer WHERE CID=@CID
  - @CompensationReasonID = resolved from TerminalID lookup (airdrop-specific reason)
  - @MoveMoneyReasonID = NULL
- This runs BEFORE Trade.PositionOpen within the same transaction
- @InitialPositionAmount is also passed to PositionOpen as-is

### 2.3 Position Open

**What**: Opens the airdropped position with the caller-provided market parameters.

**Columns/Parameters Involved**: `@PositionID OUTPUT`, `@OpenPositionActionType`, `Trade.PositionOpen`

**Rules**:
- EXEC Trade.PositionOpen: @OpenActionType=@OpenPositionActionType (4 or 5, from lookup)
- @PositionID is OUTPUT - the new PositionID is assigned by PositionOpen and returned to caller
- All standard PositionOpen parameters are passed through (@InitForexRate, @InstrumentID, @Leverage, @Amount, @AmountInUnitsDecimal, etc.)
- @CloseOnEndOfWeek = 0 (hardcoded - airdrop positions are not closed at end of week)
- @ValidateUserBalance = 1 (default - validate balance is sufficient)

### 2.4 Airdrop Log Completion

**What**: Marks the airdrop record as successfully executed.

**Columns/Parameters Involved**: `Trade.PositionAirdropLog.PositionID`, `Trade.PositionAirdropLog.Result`, `Trade.PositionAirdropLog.ExecutionOccurred`

**Rules**:
- UPDATE Trade.PositionAirdropLog SET PositionID=@PositionID, Result=1, ExecutionOccurred=@InitDateTime WHERE AirdropID=@AirdropID
- Result=1 = success (allows retry detection: Result=0 or missing means not yet executed)
- @PositionID is the new position's ID (output from PositionOpen)
- All within the same transaction (atomicity: if PositionOpen fails, log remains unset)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT OUTPUT | YES | - | CODE-BACKED | OUTPUT: The new position ID created by Trade.PositionOpen. Must be declared by caller before call. Returned for caller to use in downstream processing. |
| 2 | @AirdropID | INT | NO | - | CODE-BACKED | The airdrop event ID from Trade.PositionAirdropLog. Used to mark the airdrop record as executed (Result=1) after successful position open. |
| 3 | @TerminalID | VARCHAR(100) | NO | - | CODE-BACKED | Identifies the airdrop program. Resolved via Trade.TerminalIDToCorporateAction to get CorporateActionTypeID -> CompensationReasonID and OpenPositionActionType. Must have an entry in the mapping table or RAISERROR fires. |
| 4 | @CID | INT | NO | - | CODE-BACKED | Customer ID receiving the airdrop position. Used for SetBalanceCompensation, PositionOpen, and BackOffice.Customer ManagerID lookup. |
| 5 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument for the airdropped position. Passed to Trade.PositionOpen. |
| 6 | @InitForexRate | dtPrice | NO | - | CODE-BACKED | The opening exchange rate for the position. Passed to Trade.PositionOpen. |
| 7 | @InitDateTime | DATETIME | NO | - | CODE-BACKED | The execution timestamp. Used as @InitDateTime in PositionOpen and as ExecutionOccurred in PositionAirdropLog update. |
| 8 | @Amount | MONEY | NO | - | CODE-BACKED | Position size in monetary terms (cents). Passed to Trade.PositionOpen. |
| 9 | @AmountInUnitsDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in instrument units. Passed to Trade.PositionOpen. |
| 10 | @InitialPositionAmount | INT | YES | 0 | CODE-BACKED | The seed amount for the compensation payment (funds the position). Passed to SetBalanceCompensation as @Payment and to PositionOpen as @InitialPositionAmount. |
| 11 | @OpenPositionActionType | INT OUTPUT | NO | - | CODE-BACKED | OUTPUT: The resolved action type for the open event (4=Stock Dividend, 5=other airdrop). Resolved from Dictionary.CorporateAction via TerminalID lookup. Returned to caller. |
| 12 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key from the originating airdrop request. Passed to Trade.PositionOpen. |
| 13 | @HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server to assign the position to. Passed to Trade.PositionOpen. |
| 14 | @MirrorID | INT | YES | 0 | CODE-BACKED | Mirror portfolio ID (0 if direct customer position). Passed to Trade.PositionOpen. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TerminalID | Trade.TerminalIDToCorporateAction | READ | Maps TerminalID to CorporateActionTypeID |
| @TerminalID | Dictionary.CorporateAction | READ | Resolves CompensationReasonID and OpenPositionActionType from CorporateActionTypeID |
| @CID | BackOffice.Customer | READ | Reads ManagerID for compensation call |
| @CID | Customer.SetBalanceCompensation | EXEC (CALL) | Credits customer balance before position open (Description='Promotion') |
| Internal | Trade.PositionOpen | EXEC (CALL) | Opens the airdropped position with resolved OpenPositionActionType |
| @AirdropID | Trade.PositionAirdropLog | UPDATE (WRITE) | Marks airdrop as executed: PositionID, Result=1, ExecutionOccurred |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionAirdrop (procedure)
+-- Trade.TerminalIDToCorporateAction (table) [READ - TerminalID to CorporateActionTypeID mapping]
+-- Dictionary.CorporateAction (table) [READ - CompensationReasonID and Description for action type]
+-- BackOffice.Customer (table) [READ - ManagerID for compensation]
+-- Customer.SetBalanceCompensation (procedure) [EXEC - balance credit before position open]
+-- Trade.PositionOpen (procedure) [EXEC - creates the airdropped position]
+-- Trade.PositionAirdropLog (table) [UPDATE - marks airdrop as executed with new PositionID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TerminalIDToCorporateAction | Table | Maps @TerminalID to CorporateActionTypeID for further resolution |
| Dictionary.CorporateAction | Table | Provides CompensationReasonID and Description (for action type determination) |
| BackOffice.Customer | Table | Reads ManagerID for the Customer.SetBalanceCompensation call |
| Customer.SetBalanceCompensation | Stored Procedure | Credits the position seed amount to the customer (CompensationReasonID from lookup, Description='Promotion') |
| Trade.PositionOpen | Stored Procedure | Opens the new position; returns @PositionID OUTPUT |
| Trade.PositionAirdropLog | Table | Updated on success: PositionID=new position, Result=1, ExecutionOccurred=@InitDateTime |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @CompensationReasonID NULL check | Business guard | TerminalID must be registered in TerminalIDToCorporateAction or RAISERROR fires |
| OpenPositionActionType: 4 vs 5 | Business rule | Description='Stock Dividend' -> 4; all other airdrop types -> 5 |
| @CloseOnEndOfWeek=0 | Design constant | Airdrop positions are not subject to end-of-week automatic closure |
| @ValidateUserBalance=1 | Design constant | Balance validation is always on for airdrop position opens |
| Compensation BEFORE PositionOpen | Design | Balance must be credited before position is created to ensure sufficient funds |
| @@TRANCOUNT checks in CATCH | Design | @@TRANCOUNT=1 -> ROLLBACK; >1 -> COMMIT (same pattern as PositionAdjustment) |
| Created for US project TRADCD-753 | History | Per code comment: created by Ran Ovadia, 16-08-2021 for US project |

---

## 8. Sample Queries

### 8.1 Check the airdrop log for a specific airdrop event
```sql
SELECT
    AirdropID,
    PositionID,
    Result,
    ExecutionOccurred
FROM Trade.PositionAirdropLog WITH (NOLOCK)
WHERE AirdropID = 9876
ORDER BY AirdropID;
```

### 8.2 Find terminal ID to corporate action mappings
```sql
SELECT
    t.TerminalID,
    t.CorporateActionTypeID,
    c.Description,
    c.CompensationReasonID
FROM Trade.TerminalIDToCorporateAction t WITH (NOLOCK)
JOIN Dictionary.CorporateAction c WITH (NOLOCK)
    ON c.CorporateActionTypeID = t.CorporateActionTypeID
ORDER BY t.TerminalID;
```

### 8.3 Find recently executed airdrop positions
```sql
SELECT TOP 20
    al.AirdropID,
    al.PositionID,
    al.Result,
    al.ExecutionOccurred,
    pt.CID,
    pt.InstrumentID,
    pt.Amount
FROM Trade.PositionAirdropLog al WITH (NOLOCK)
JOIN Trade.PositionTbl pt WITH (NOLOCK)
    ON pt.PositionID = al.PositionID
    AND pt.PositionID%50 = pt.PartitionCol
WHERE al.Result = 1
  AND al.ExecutionOccurred >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY al.ExecutionOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [TRADCD-753](https://etoro-jira.atlassian.net/browse/TRADCD-753) | Jira | US project ticket for which Trade.PositionAirdrop was created (Aug 2021) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 2 analyzed (SetBalanceCompensation, PositionOpen) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionAirdrop | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionAirdrop.sql*

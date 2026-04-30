# Trade.UnRegisterMirrorForMoe

> Manually unregisters (force-stops) a copy mirror for an operations user ("Moe"), performing validation, balance credit (CreditTypeID=21), and atomic DELETE Trade.Mirror OUTPUT into Trade.PostDetachOperation. Returns country and parent PI details.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @MirrorID INT (manual mirror unregister, transactional, PostDetach staging) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a manual, operations-side way to stop a copy relationship (mirror). It is named "ForMoe" - indicating it was created for a specific operations person (Moe) who needed a safe, validated way to forcibly stop a copy session that could not be stopped through normal user flows.

The standard copier unregister flow deactivates the mirror (sets IsActive=0) and then calls UnRegisterMirror. This "ForMoe" variant adds additional safety checks and handles the case where an ops user needs to directly remove a mirror that is already deactivated but hasn't been cleaned up.

The procedure performs the following steps:
1. Validates no open positions exist for the mirror (prevents stranded positions)
2. Checks the `Trade.FunUnRegisterMirrorMot` function for additional business validation
3. Credits the copier's balance for the mirror amount (CreditTypeID=21 = Unregister Mirror)
4. DELETEs the mirror from Trade.Mirror, OUTPUTting to Trade.PostDetachOperation (the staging table for History.Mirror population)
5. Returns CountryID, ParentUserName, ParentCID, and Occurred for the caller

The procedure runs inside a transaction with `XACT_ABORT ON` for atomic execution.

---

## 2. Business Logic

### 2.1 Pre-Transaction Validation

**Check 1 - No Open Positions**:
```sql
IF EXISTS (SELECT * FROM Trade.PositionTbl WHERE MirrorID = @MirrorID AND MirrorID > 0 AND StatusID=1)
    RAISERROR(60067, 16, 1)
```
- Error 60067: Cannot perform action while mirror has open positions
- Must close all positions first before unregistering

**Check 2 - Business Function Validation**:
```sql
IF (SELECT Trade.FunUnRegisterMirrorMot(@CID, @MirrorID)) = 1
    RAISERROR(60067, 16, 1)
```
- Delegates additional validation logic to `Trade.FunUnRegisterMirrorMot`

### 2.2 Transaction - Mirror Details Lookup

```sql
SELECT @CIDInTable = tm.CID, @AmountInCents = Amount*100, @IsActive = IsActive,
       @ParentCID = ParentCID, @ParentUserName = ParentUserName,
       @CountryID = ccs.CountryID, @Occurred = GETDATE()
FROM Trade.Mirror tm
JOIN Customer.CustomerStatic ccs ON tm.CID = ccs.CID
WHERE tm.MirrorID = @MirrorID
```
- Error 60050 if MirrorID not found
- Error 60064 if @CIDInTable <> @CID (CID mismatch)
- Error 60063 if IsActive=1 (mirror is still active - cannot unregister an active mirror)

### 2.3 Transaction - Balance Credit

```sql
EXEC @Answer = Customer.SetBalance
    @CID = @CID,
    @Payment = @AmountInCents,  -- mirror amount * 100 (converted to cents)
    @CreditTypeID = 21,          -- "Unregister mirror"
    @Description = 'Unregister mirror',
    @MirrorID = @MirrorID
```
- Returns mirror amount to copier's balance
- CreditTypeID=21 = Unregister mirror credit type

### 2.4 Transaction - DELETE Mirror with OUTPUT

```sql
DELETE Trade.Mirror
OUTPUT Deleted.MirrorID, Deleted.CID, ..., 2 /*MirrorOperationID*/, ...
INTO Trade.PostDetachOperation (H_M_MirrorID, H_M_CID, H_M_ParentCID, ...)
WHERE MirrorID = @MirrorID
```
- `MirrorOperationID = 2` hardcoded (= unregister) in the OUTPUT
- Output goes to `Trade.PostDetachOperation` staging table which feeds History.Mirror population
- Error 60050 if DELETE affected 0 rows (race condition guard, comment says "can be deleted - ask Hersko")

### 2.5 Output Row

Returns: `CountryID, ParentUserName, ParentCID, Occurred`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The copier's customer ID. Must match Trade.Mirror.CID for the given MirrorID. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | The copy session ID to unregister. Must exist in Trade.Mirror. |
| 3 | @SessionID | BIGINT | YES | -1 | CODE-BACKED | Session identifier for audit trail. Written to Trade.PostDetachOperation.H_M_SessionID. Default -1 = no session. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | INT | NO | - | CODE-BACKED | Copier's country ID (from Customer.CustomerStatic). Used by callers to determine country-specific routing. |
| 2 | ParentUserName | VARCHAR | NO | - | CODE-BACKED | The Popular Investor's username (from Trade.Mirror). Returned for caller context. |
| 3 | ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's CID (from Trade.Mirror). |
| 4 | Occurred | DATETIME | NO | - | CODE-BACKED | GETDATE() at time of unregister. Timestamp of this operation. |

### Error Codes

| Error | Meaning |
|-------|---------|
| 60067 | Cannot unregister: mirror has open positions OR FunUnRegisterMirrorMot returned 1 |
| 60050 | Mirror not found (MirrorID does not exist in Trade.Mirror) |
| 60064 | CID mismatch: @CID does not match Trade.Mirror.CID for this MirrorID |
| 60063 | Cannot unregister an active mirror (IsActive=1) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID, StatusID | Trade.PositionTbl | Lookup (READ) | Pre-validation: checks for open positions (StatusID=1) on this mirror. |
| @CID, @MirrorID | Trade.FunUnRegisterMirrorMot | Function Call | Business validation function - returns 1 if unregister is blocked. |
| MirrorID, CID, Amount, IsActive, ParentCID | Trade.Mirror | Lookup + WRITE (DELETE) | Source of mirror data; deleted from here after validation. |
| CID, CountryID | Customer.CustomerStatic | Lookup (READ) | Copier's country for return value. |
| @CID, @Payment, CreditTypeID=21 | Customer.SetBalance | Procedure Call | Credits mirror amount back to copier's balance. |
| (all mirror columns) | Trade.PostDetachOperation | WRITE (OUTPUT INTO) | Staging table for History.Mirror population; receives the deleted mirror row via OUTPUT. |

### 5.2 Referenced By

Not analyzed in this phase. Called by operations tooling for manual mirror management ("ForMoe" scope).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UnRegisterMirrorForMoe (procedure)
+-- Trade.PositionTbl (table) - open positions check
+-- Trade.FunUnRegisterMirrorMot (function) - business validation
+-- Trade.Mirror (table) - mirror details + DELETE
+-- Customer.CustomerStatic (table - cross-schema) - country
+-- Customer.SetBalance (procedure - cross-schema) - balance credit
+-- Trade.PostDetachOperation (table) - OUTPUT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Pre-validation: must have no open positions. |
| Trade.FunUnRegisterMirrorMot | Function | Business validation gating unregister. |
| Trade.Mirror | Table | Source of mirror data; deleted atomically. |
| Customer.CustomerStatic | Table | Copier CountryID for return value. |
| Customer.SetBalance | Procedure | Balance credit (CreditTypeID=21) for mirror amount return. |
| Trade.PostDetachOperation | Table | OUTPUT destination; staging for History.Mirror. |

### 6.2 Objects That Depend On This

Not analyzed. Called by operations tooling.

---

## 7. Technical Details

### 7.1 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XACT_ABORT ON | Safety | Any error auto-rolls back the transaction, preventing partial state. |
| IsActive=0 requirement | Business Rule | Error 60063 if mirror IsActive=1. Mirror must be deactivated before unregistering. |
| No open positions | Business Rule | Error 60067 if any PositionTbl rows with StatusID=1 exist for the mirror. |
| Amount*100 conversion | NOTE | Trade.Mirror.Amount is in dollars; multiplied by 100 to get "cents" for SetBalance @Payment. |
| Post-DELETE race condition guard | NOTE | Comment in code (added 11/11/2024, "ask Hersko") suggests the 0-row-DELETE check may be redundant but is left in for safety. |

---

## 8. Sample Queries

### 8.1 Unregister a specific mirror (ops use only)

```sql
EXEC Trade.UnRegisterMirrorForMoe
    @CID = 12345,
    @MirrorID = 98765,
    @SessionID = -1
-- Returns: CountryID, ParentUserName, ParentCID, Occurred
```

### 8.2 Pre-check: verify mirror is safe to unregister

```sql
SELECT tm.MirrorID, tm.CID, tm.IsActive,
       (SELECT COUNT(*) FROM Trade.PositionTbl WHERE MirrorID = tm.MirrorID AND StatusID = 1) AS OpenPositions
FROM Trade.Mirror tm WITH (NOLOCK)
WHERE tm.MirrorID = 98765
-- IsActive must be 0, OpenPositions must be 0 before calling UnRegisterMirrorForMoe
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UnRegisterMirrorForMoe | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UnRegisterMirrorForMoe.sql*

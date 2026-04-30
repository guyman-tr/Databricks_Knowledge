# Billing.WithdrawToFundingMatch

> Batch-updates the MatchStatusID on a set of WithdrawToFunding records and clones their latest history action with the new match status, returning the updated rows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WTFIdList (batch of WTF IDs as comma-separated string) + @MatchStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFundingMatch` is the reconciliation write procedure for `Billing.WithdrawToFunding`. The match status (`MatchStatusID`) indicates whether a withdrawal payment leg has been matched to a corresponding incoming payment or deposit record - a key step in financial reconciliation where outgoing payments are verified against provider settlement reports or bank statements.

The procedure accepts a batch of WTF IDs via a comma-separated string (older eToro pattern using `Internal.ConvertListToTable`), validates the target match status, and applies it to all specified payment legs simultaneously. This batch design is appropriate for reconciliation processes that process groups of payments together (e.g., "all payments in today's settlement file matched to status 3").

The history logging strategy is noteworthy: rather than constructing a new history record from scratch, the procedure clones the **most recent** `History.WithdrawToFundingAction` record for each WTF ID and inserts a new row with the match status overridden. This preserves the full payment context (CashoutStatusID, Amount, ProcessCurrencyID, WithdrawData, etc.) in the new history entry without requiring all fields to be re-supplied by the caller.

Note: This procedure does NOT use the `Billing.UpdateWithdraw2Funding` TVP delegation pattern (DBA-648). It uses direct UPDATE + INSERT, likely because it predates the DBA-648 refactor or because `MatchStatusID` is not part of the history OUTPUT clause in `UpdateWithdraw2Funding`.

---

## 2. Business Logic

### 2.1 String-List-to-Table Conversion

**What**: The WTF ID batch is passed as a comma-separated NVARCHAR string, converted to a table via a utility function.

**Columns/Parameters Involved**: `@WTFIdList`, `@WtfIDs` (table variable)

**Rules**:
- `Internal.ConvertListToTable(@WTFIdList)` returns rows with a `Parameter` column for each delimited value
- Results are inserted into `@WtfIDs TABLE (ID VarChar(max))`
- The IDs are then used in `WHERE ID IN (SELECT ID FROM @WtfIDs)` for both the UPDATE and the history INSERT
- This is an older eToro pattern; newer procedures use `dbo.IdIntList` TVPs instead

### 2.2 MatchStatusID Validation

**What**: Validates the requested match status exists in the dictionary before applying any changes.

**Columns/Parameters Involved**: `@MatchStatusID`, `Dictionary.MatchStatus`

**Rules**:
- `IF NOT EXISTS (SELECT 1 FROM Dictionary.MatchStatus WHERE MatchStatusID = @MatchStatusID)` -> RAISERROR 'Wrong Match Status ID' (severity 16)
- Validation occurs INSIDE the transaction - the RAISERROR will cause the CATCH block to rollback
- No pre-validation of the @WTFIdList (invalid IDs are silently skipped - WHERE clause simply matches zero rows)

### 2.3 Batch MatchStatusID Update

**What**: Sets the new MatchStatusID on all specified WithdrawToFunding records in one UPDATE statement.

**Columns/Parameters Involved**: `MatchStatusID`, `@MatchStatusID`, `@WtfIDs`

**Rules**:
- `UPDATE Billing.WithdrawToFunding SET MatchStatusID = @MatchStatusID WHERE ID IN (SELECT ID FROM @WtfIDs)`
- No CashoutStatusID guard - any payment leg regardless of its lifecycle status can have its match status updated
- WTF IDs in @WtfIDs that do not exist in Billing.WithdrawToFunding are silently ignored (no error)

### 2.4 History Clone Pattern

**What**: Creates a new audit record for each updated WTF by cloning its most recent history entry with the new match status applied.

**Columns/Parameters Involved**: `History.WithdrawToFundingAction`, `BW2F_ID`, `MatchStatusID`, `@Now`, `@ManagerID`, `@Remark`

**Rules**:
- Subquery finds the latest `History.WithdrawToFundingAction` row per WTF ID: `SELECT MAX(WithdrawToFundingActionID) AS LastActionID, BW2F_ID GROUP BY BW2F_ID`
- Inner join brings back the full latest-action row for each WTF
- New history row inherits: WithdrawID, FundingID, CashoutStatusID, CashoutActionStatusID, ProcessCurrencyID, Amount, WithdrawData from the source row
- New history row overrides: ManagerID=@ManagerID, ModificationDate=@Now, Remark=@Remark, MatchStatusID=@MatchStatusID
- This means the history snapshot reflects the payment's current state (last known CashoutStatusID, Amount, etc.) at the time of matching
- WTF IDs with NO history records in `History.WithdrawToFundingAction` will produce no history row (the JOIN yields no rows for that ID)

**Diagram**:
```
@WTFIdList "101,102,103"
    -> Internal.ConvertListToTable -> @WtfIDs {101, 102, 103}

BEGIN TRAN
    Validate: Dictionary.MatchStatus has @MatchStatusID
    UPDATE Billing.WithdrawToFunding SET MatchStatusID=@MatchStatusID WHERE ID IN @WtfIDs

    History INSERT for each WTF:
        For each ID in @WtfIDs:
            Find: MAX(WithdrawToFundingActionID) in History.WithdrawToFundingAction WHERE BW2F_ID=ID
            Clone that row -> new row with:
                ManagerID      = @ManagerID
                ModificationDate = @Now
                Remark         = @Remark
                MatchStatusID  = @MatchStatusID
                (all other fields copied from the source row)

    SELECT ID, MatchStatusID FROM Billing.WithdrawToFunding WHERE ID IN @WtfIDs
COMMIT
```

### 2.5 Result Set Return

**What**: Returns the updated WTF rows so the caller can confirm which records were actually updated.

**Rules**:
- `SELECT ID, MatchStatusID FROM Billing.WithdrawToFunding WITH (NOLOCK) WHERE ID IN (SELECT ID FROM @WtfIDs)`
- Returns one row per WTF ID that exists in `Billing.WithdrawToFunding`
- IDs in @WTFIdList that don't exist are absent from the result set
- The NOLOCK hint is used on the SELECT (safe: records were just committed in this transaction)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WTFIdList | nvarchar(MAX) | NO | - | CODE-BACKED | Required. Comma-separated list of `Billing.WithdrawToFunding.ID` values to update. Parsed via `Internal.ConvertListToTable`. IDs that do not exist in WithdrawToFunding are silently skipped. |
| 2 | @MatchStatusID | int | NO | - | CODE-BACKED | Required. The new match status to apply to all specified WTF records. Must exist in `Dictionary.MatchStatus` or RAISERROR is raised. |
| 3 | @ManagerID | int | NO | - | CODE-BACKED | Required. Manager performing the reconciliation/matching operation. Written to the new `History.WithdrawToFundingAction` rows as the audit operator. |
| 4 | @Remark | varchar(255) | NO | - | CODE-BACKED | Required. Free-text audit comment for this matching operation. Written to the new history rows alongside the match status change. |

### Output

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | ID | int | NO | CODE-BACKED | PK of `Billing.WithdrawToFunding`. Each row corresponds to one WTF record in @WTFIdList that was found and updated. |
| 2 | MatchStatusID | int | YES | CODE-BACKED | The new MatchStatusID now applied to this WTF record. Should equal @MatchStatusID for all returned rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MatchStatusID | Dictionary.MatchStatus | Validation | Validates the match status value exists in the dictionary |
| @WTFIdList | Billing.WithdrawToFunding | UPDATE + Reader | Batch-updates MatchStatusID; reads back updated rows |
| (history) | History.WithdrawToFundingAction | INSERT + Reader | Reads latest action per WTF to clone; inserts new match status action rows |
| @WTFIdList | Internal.ConvertListToTable | Function Call | Parses the comma-separated ID string into a result set |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Reconciliation service (application) | @WTFIdList, @MatchStatusID | Caller | Called during payment reconciliation to batch-mark matched/unmatched payment legs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingMatch (procedure)
├── Dictionary.MatchStatus (table) [validation]
├── Billing.WithdrawToFunding (table) [UPDATE + SELECT]
├── History.WithdrawToFundingAction (table) [SELECT latest + INSERT]
└── Internal.ConvertListToTable (function) [parses @WTFIdList]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MatchStatus | Table | Validates @MatchStatusID exists |
| Billing.WithdrawToFunding | Table | UPDATE target; result set source |
| History.WithdrawToFundingAction | Table | Reads latest action for each WTF to clone; INSERT target for new match status history rows |
| Internal.ConvertListToTable | Function | Converts comma-separated ID string to rowset |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Reconciliation/matching application service | External application | Caller - batch match status updates after settlement reconciliation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRY/CATCH with transaction | Design | COMMIT on success; ROLLBACK if @@TRANCOUNT=1; COMMIT (preserve outer) if @@TRANCOUNT>1; RAISERROR 60000 re-raised to caller |
| Dictionary validation inside transaction | Design | MatchStatusID validated after BEGIN TRAN; if invalid, CATCH block rolls back |
| No CashoutStatusID guard | Design | Unlike ChangePaymentStatus, no lifecycle state check - any WTF can be match-status-updated regardless of payment state |
| String list parameter (legacy) | Design | Uses NVARCHAR(MAX) string + Internal.ConvertListToTable rather than a TVP. Older pattern predating dbo.IdIntList adoption. |
| Direct UPDATE (not via UpdateWithdraw2Funding) | Architecture | Does NOT use the DBA-648 TVP delegation pattern. MatchStatusID is updated directly on Billing.WithdrawToFunding. |
| History clone from latest action | Design | New history row is cloned from MAX(WithdrawToFundingActionID) for each WTF, not from live WTF columns. WTFs with no history records get no history entry. |

---

## 8. Sample Queries

### 8.1 Match a batch of WTF records to status 3

```sql
EXEC Billing.WithdrawToFundingMatch
    @WTFIdList = '101001,101002,101003,101004',
    @MatchStatusID = 3,
    @ManagerID = 99,
    @Remark = 'Matched to settlement file 2026-03-18';
-- Returns: ID, MatchStatusID for each updated WTF record
```

### 8.2 Check MatchStatus dictionary values

```sql
SELECT
    ms.MatchStatusID,
    ms.Name,
    ms.Description
FROM Dictionary.MatchStatus ms WITH (NOLOCK)
ORDER BY ms.MatchStatusID;
```

### 8.3 Verify MatchStatusID was updated on a WTF

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.CashoutStatusID,
    wtf.MatchStatusID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.ID IN (101001, 101002, 101003, 101004);
```

### 8.4 Inspect history records created by the match operation

```sql
SELECT TOP 10
    wfa.WithdrawToFundingActionID,
    wfa.BW2F_ID AS WTF_ID,
    wfa.CashoutStatusID,
    wfa.MatchStatusID,
    wfa.ManagerID,
    wfa.Remark,
    wfa.ModificationDate
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.BW2F_ID IN (101001, 101002, 101003, 101004)
ORDER BY wfa.WithdrawToFundingActionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found in SSDT (called from application) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingMatch | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingMatch.sql*

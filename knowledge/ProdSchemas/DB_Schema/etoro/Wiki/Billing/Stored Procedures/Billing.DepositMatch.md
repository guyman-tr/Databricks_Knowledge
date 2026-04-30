# Billing.DepositMatch

> Bulk-updates the match status of one or more deposits and appends the change to the deposit action history - the back-office reconciliation tool for linking deposits to banking records.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit.MatchStatusID + INSERT History.DepositAction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositMatch` is the back-office procedure for reconciling deposits against bank statements. It updates the `MatchStatusID` on one or more deposits simultaneously and creates a corresponding audit record in `History.DepositAction` for each changed deposit, preserving the full action history.

The typical use case is a back-office reconciliation workflow: a manager receives a bank statement showing which deposits have cleared, and uses this procedure to mark those deposits as "Matched" (or another `Dictionary.MatchStatus` value). The `@Remark` field captures the reason or reference for the status change.

The procedure accepts a comma-separated list of deposit IDs via `Internal.ConvertListToTable`, enabling bulk operations. It validates that the requested status exists in `Dictionary.MatchStatus` before making any changes, and wraps the entire operation in a transaction with TRY/CATCH error handling.

Access is granted to MatchUser, BO_User, and BOUserUSReadWrite database users, confirming this is a back-office/operations tool.

---

## 2. Business Logic

### 2.1 Bulk Match Status Update

**What**: Updates MatchStatusID on multiple deposits in a single transaction.

**Columns/Parameters Involved**: `@DepositIdList`, `@MatchStatusID`, `Billing.Deposit.MatchStatusID`

**Rules**:
- `@DepositIdList` is a comma-separated string of deposit IDs (e.g., `'123,456,789'`). Parsed by `Internal.ConvertListToTable`.
- Validates: `IF NOT EXISTS (SELECT 1 FROM Dictionary.MatchStatus WHERE MatchStatusID = @MatchStatusID)` -> RAISERROR('Wrong Match Status ID', 16, 1).
- Updates ALL deposits in the list to the same MatchStatusID in one UPDATE statement.
- No per-deposit validation - if one deposit ID doesn't exist, it is silently skipped.

### 2.2 Audit Trail via History.DepositAction

**What**: For each changed deposit, inserts a new action row into History.DepositAction by copying the current latest action and overriding the match-related fields.

**Columns/Parameters Involved**: `@ManagerID`, `@Remark`, `@MatchStatusID`, `History.DepositAction.ModificationDate`

**Rules**:
- Finds the latest DepositAction for each deposit: `MAX(DepositActionID)` per DepositID.
- Copies all fields from that latest action EXCEPT: ManagerID (replaced with @ManagerID), ModificationDate (set to @Now = GETUTCDATE()), MatchStatusID (set to @MatchStatusID), and Remark (set to @Remark).
- SessionID is preserved from the existing latest action (added 20/10/2015).
- This creates a complete audit trail: each match status change is a new row in the action history.

```
@DepositIdList = '100,101,102'
  -> Parse into table var: {100, 101, 102}
  -> Validate @MatchStatusID exists in Dictionary.MatchStatus
  -> UPDATE Billing.Deposit SET MatchStatusID = @MatchStatusID WHERE DepositID IN (100,101,102)
  -> INSERT History.DepositAction (copy latest action per deposit, override ManagerID/Date/MatchStatusID/Remark)
  -> SELECT DepositID, MatchStatusID for changed deposits (confirmation result set)
```

### 2.3 Transaction and Error Handling

**What**: Full transaction with TRY/CATCH ensures atomicity.

**Columns/Parameters Involved**: N/A

**Rules**:
- Wraps everything in BEGIN TRANSACTION / COMMIT.
- CATCH block: if @@TRANCOUNT = 1, ROLLBACK; if > 1 (nested), COMMIT (unusual pattern - preserves outer transaction).
- Error re-raised as: `RAISERROR(60000, 16, 1, 'Billing.DepositMatch', @@ERROR)`.
- Returns 0 on success, @@ERROR on failure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositIdList | NVARCHAR(MAX) | NO | - | CODE-BACKED | Comma-separated list of Billing.Deposit.DepositID values to update (e.g., '12345,12346,12347'). Parsed by Internal.ConvertListToTable. All listed deposits will receive the same new MatchStatusID. Non-existent IDs are silently ignored. |
| 2 | @MatchStatusID | INT | NO | - | CODE-BACKED | Target match status for all listed deposits. Validated against Dictionary.MatchStatus before any updates. Common values defined by the Dictionary.MatchStatus lookup. RAISERROR fired if invalid. |
| 3 | @ManagerID | INT | NO | - | CODE-BACKED | ID of the back-office manager or system user performing the match. Written to History.DepositAction.ManagerID for each audit row. Identifies who authorized the reconciliation. |
| 4 | @Remark | VARCHAR(255) | NO | - | CODE-BACKED | Free-text reason or reference for the match status change (e.g., bank reference number, wire transfer ID). Written to History.DepositAction.Remark. Supports audit and dispute resolution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MatchStatusID | Dictionary.MatchStatus | Lookup / Validation | Validates the requested status exists before updating. Implicit FK on Billing.Deposit.MatchStatusID. |
| @DepositIdList -> DepositID | Billing.Deposit | MODIFIER (UPDATE) | Updates MatchStatusID on all listed deposits. |
| DepositID | History.DepositAction | WRITER (INSERT) | Creates new action audit rows for each updated deposit. Copies the latest existing action and overrides manager/date/status/remark. |
| @DepositIdList | Internal.ConvertListToTable | Function call | Parses the comma-separated ID string into a table of deposit IDs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office application (MatchUser, BO_User, BOUserUSReadWrite DB roles) | - | EXEC | Called by back-office users during deposit reconciliation against bank statements. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositMatch (procedure)
├── Billing.Deposit (table)
├── History.DepositAction (table) [cross-schema]
├── Dictionary.MatchStatus (table) [cross-schema, validation]
└── Internal.ConvertListToTable (function) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE target - sets MatchStatusID. Also read (SELECT confirmation at end). |
| History.DepositAction | Table (cross-schema) | READ to find latest action per deposit; INSERT new audit rows. |
| Dictionary.MatchStatus | Table (cross-schema) | Validation - EXISTS check before processing. |
| Internal.ConvertListToTable | Function (cross-schema) | Parses @DepositIdList string into a table of IDs. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office application | External | EXEC via MatchUser / BO_User permissions. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Error codes**:
- `RAISERROR('Wrong Match Status ID', 16, 1)` - @MatchStatusID not found in Dictionary.MatchStatus.
- `RAISERROR(60000, 16, 1, 'Billing.DepositMatch', @@ERROR)` - generic error wrapper for unexpected failures.

---

## 8. Sample Queries

### 8.1 Mark two deposits as matched (MatchStatusID=2)

```sql
EXEC [Billing].[DepositMatch]
    @DepositIdList = '12345,12346',
    @MatchStatusID = 2,
    @ManagerID = 999,
    @Remark = 'Matched against SWIFT MT103 ref #XYZ20260318';
```

### 8.2 Verify current match status of deposits

```sql
SELECT DepositID, MatchStatusID, ModificationDate, CID, Amount
FROM [Billing].[Deposit] WITH (NOLOCK)
WHERE DepositID IN (12345, 12346);
```

### 8.3 View match status history in DepositAction

```sql
SELECT TOP 20 DepositActionID, DepositID, MatchStatusID, ManagerID, Remark, ModificationDate
FROM [History].[DepositAction] WITH (NOLOCK)
WHERE DepositID IN (12345, 12346)
  AND MatchStatusID IS NOT NULL
ORDER BY DepositActionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositMatch | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositMatch.sql*

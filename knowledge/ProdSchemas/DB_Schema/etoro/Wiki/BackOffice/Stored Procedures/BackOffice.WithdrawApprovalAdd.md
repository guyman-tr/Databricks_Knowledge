# BackOffice.WithdrawApprovalAdd

> Records one back-office group's approval or rejection of a withdrawal request, mirrors the old value to History.WithdrawApproval, and automatically calls WithdrawRequestApprove when all required groups have approved.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @UserGroupID - uniquely identifies the approval row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.WithdrawApprovalAdd` is the primary write procedure for the withdrawal approval workflow. When a back-office agent submits a decision on a customer's cashout request, this SP handles the full lifecycle:

1. **Validates** the withdrawal is still pending (not already approved, not canceled).
2. **Upserts** the group's decision into `BackOffice.WithdrawApproval` (one row per group per withdrawal).
3. **Mirrors** the previous row values to `History.WithdrawApproval` for a complete audit trail.
4. **Checks** whether all required groups have now approved, using amount-based thresholds from `Maintenance.Feature`. If all conditions are met, it automatically calls `BackOffice.WithdrawRequestApprove` to finalize the withdrawal.

This SP is the gating mechanism for all cashout processing. Without it recording approvals, withdrawals cannot be released for payment. The SP returns `IsWithdrawApprove = 1` when all groups have approved in this call, and `0` when the withdrawal still awaits further approvals.

**Historical changes (from DDL comments)**:
- 2016 (Geri Reshef, ticket 40914): Disallowed approval of canceled cashouts
- 2020 (Avraham Lachmi): Added SELECT/RETURN of the answer to the caller
- 2020 (Adi Cohn): Rewrote the transaction management (original was "very poorly written")

---

## 2. Business Logic

### 2.1 Pre-Validation Before Transaction

**What**: Guards against approving already-finalized or canceled withdrawal requests.

**Columns/Parameters Involved**: `@WithdrawID`, `@Approved`

**Rules**:
- Read `Amount`, `CID`, `Approved`, `CashoutStatusID` from `Billing.Withdraw WHERE WithdrawID = @WithdrawID`
- If `Approved = 1` (already fully approved): RAISERROR(60025, 16, 1, 'Withdraw Request Already Approved'), RETURN 60025
- If `CashoutStatusID = (SELECT CashoutStatusID FROM Dictionary.CashoutStatus WHERE Name='Canceled')`: RAISERROR(60025, 16, 1, 'Can not approve because WithdrawID is in Cancel cashout status'), RETURN 60025
- These checks run OUTSIDE the transaction - if they fail, no history rows are written and no rollback is needed

**Diagram**:
```
@WithdrawID
    |
    +--> Billing.Withdraw: read Amount, CID, Approved, CashoutStatusID
    |
    +--> Approved=1?  YES -> RAISERROR 60025 (already approved)
    |                NO  -> continue
    |
    +--> Status=Canceled? YES -> RAISERROR 60025 (canceled)
                          NO  -> enter transaction
```

### 2.2 Upsert Pattern with History Mirroring

**What**: Either updates an existing group approval row or inserts a new one, then mirrors the old row to History.

**Columns/Parameters Involved**: All parameters map to `BackOffice.WithdrawApproval` columns

**Rules**:
- IF EXISTS a row for (WithdrawID, UserGroupID): UPDATE with OUTPUT old row into @Info table variable
- ELSE: INSERT new row, @Info table variable remains empty (no history row for first-time inserts)
- Note: new INSERT rows are NOT written to History (the SELECT from @Info at the INSERT path will be empty)
- After DML: check @@Error - if non-zero: ROLLBACK, RAISERROR(60000, 16, 1, 'BackOffice.WithdrawApprovalAdd', @LocalError)
- INSERT History.WithdrawApproval SELECT * FROM @Info - mirrors the old values before the UPDATE
- After History INSERT: check @@Error again - if non-zero: ROLLBACK, RAISERROR 60000
- Transaction uses BEGIN TRY/BEGIN CATCH, with @@TRANCOUNT=1 -> ROLLBACK, @@TRANCOUNT>1 -> COMMIT (nested SP safety)

### 2.3 Multi-Group Amount-Threshold Auto-Approval Check

**What**: After recording this group's decision, checks if all required groups have now approved. If so, automatically finalizes the withdrawal.

**Columns/Parameters Involved**: `@Approved`, `@Amount`, `@CID`, `@WithdrawID`, `@UserGroupID`

**Rules**: Only runs when `@Approved=1`. All four conditions must pass simultaneously:

| Group | Condition |
|-------|-----------|
| **Admin (UserGroupID=1)** | Amount < `Maintenance.Feature.XMLValue('/Settings/Accounting/WithdrawAdminApprovalFrom')` OR EXISTS approval row with UserGroupID=1 AND Approved=1 |
| **Risk (UserGroupID=3)** | Amount < `WithdrawRiskApprovalFrom` threshold OR EXISTS approval row with UserGroupID=3 AND Approved=1 |
| **Marketing (UserGroupID=4)** | Amount < `WithdrawMarketingApprovalFrom` threshold OR EXISTS approval row with UserGroupID=4 AND Approved=1 OR EXISTS BackOffice.Customer WHERE CID=@CID AND IsAffiliate=0 (non-affiliates skip Marketing) |
| **Trading (UserGroupID=6)** | Amount < `WithdrawTradingApprovalFrom` threshold OR EXISTS approval row with UserGroupID=6 AND Approved=1 |

When all four conditions pass:
- EXEC @Answer = BackOffice.WithdrawRequestApprove @WithdrawID
- If @Answer != 0: RAISERROR 'Error in proc BackOffice.WithdrawRequestApprove. Return value was {N}'
- If @Answer = 0: SET @Answer = 1

**Key insight**: The Marketing check waives the group approval requirement for non-affiliate customers (`IsAffiliate=0`). Affiliate customers require explicit Marketing group sign-off above the threshold.

**Diagram**:
```
@Approved=1?
    |
    NO -> skip auto-finalize
    YES ->
        [Admin OK?] AND [Risk OK?] AND [Marketing OK?] AND [Trading OK?]
            |
            YES -> EXEC WithdrawRequestApprove -> SET Approved=1 on Billing.Withdraw
            NO  -> wait for remaining groups
```

### 2.4 Return Value

**What**: Signals to the caller whether the withdrawal was fully approved in this call.

**Rules**:
- `@Answer = 0` (default): Approval recorded but more groups still required
- `@Answer = 1`: All groups approved; `WithdrawRequestApprove` was called successfully
- `SELECT @Answer AS IsWithdrawApprove` + `RETURN @Answer` at end of TRY block
- On CATCH: RETURN @Answer (may be 0)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | integer | NO | - | CODE-BACKED | PK of the withdrawal request being approved. FK to Billing.Withdraw.WithdrawID. Pre-validated against Billing.Withdraw to check Approved state and CashoutStatusID before the transaction begins. |
| 2 | @UserGroupID | integer | NO | - | CODE-BACKED | Which back-office group is submitting this decision. Used with @WithdrawID as the composite key for the upsert. Known values: 1=Admin, 3=Risk, 4=Marketing, 6=Trading. See BackOffice.WithdrawApproval.UserGroupID. |
| 3 | @ManagerID | integer | NO | - | CODE-BACKED | The manager submitting this group's decision. Stored in BackOffice.WithdrawApproval.ManagerID. ManagerID=0 indicates an automated/system-generated approval. FK to BackOffice.Manager. |
| 4 | @WithdrawApprovalReasonID | integer | NO | - | CODE-BACKED | Classification of the reason for this decision. FK to Dictionary.WithdrawApprovalReason. 7=Other (bulk/automated), 1-6 and 8-16 indicate specific compliance or documentation reasons. See BackOffice.WithdrawApproval Section 2.4 for full value map. |
| 5 | @Approved | bit | NO | - | CODE-BACKED | 1=This group approves the withdrawal. 0=This group rejects/holds it. Only when @Approved=1 does the auto-finalize check run. If any required group has Approved=0, the withdrawal remains pending and WithdrawRequestApprove is not called. |
| 6 | @Comment | varchar(max) | NO | - | CODE-BACKED | Free-text note from the approving/rejecting manager. Written to BackOffice.WithdrawApproval.Comment. Also used by WithdrawRequestApprove's comment-selection logic to prefer non-"Auto Approval" comments for the final Billing.Withdraw.Comment. |

**Return value**:
| Element | Type | Description |
|---------|------|-------------|
| IsWithdrawApprove | integer (SELECT output) | 1 = all required groups approved in this call and WithdrawRequestApprove succeeded; 0 = approval recorded but more groups required or rejection |
| RETURN code | integer | Same value as IsWithdrawApprove |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | SELECT (pre-validation read) | Reads Amount, CID, Approved, CashoutStatusID to validate state |
| CashoutStatusID | Dictionary.CashoutStatus | SELECT (lookup) | Checks if current status is 'Canceled' - rejected cashouts cannot be approved |
| @WithdrawID + @UserGroupID | [BackOffice.WithdrawApproval](../Tables/BackOffice.WithdrawApproval.md) | UPDATE or INSERT (upsert) | The primary approval record for this (withdrawal, group) pair |
| Deleted.* | History.WithdrawApproval | INSERT (mirror) | Old row values written here on UPDATE for audit trail |
| Amount thresholds | Maintenance.Feature | SELECT (XML config) | WithdrawAdminApprovalFrom, WithdrawRiskApprovalFrom, WithdrawMarketingApprovalFrom, WithdrawTradingApprovalFrom |
| @CID + IsAffiliate | BackOffice.Customer | EXISTS check | Marketing group requirement is waived for non-affiliate (IsAffiliate=0) customers |
| @WithdrawID | [BackOffice.WithdrawRequestApprove](BackOffice.WithdrawRequestApprove.md) | EXEC (auto-finalize) | Called when all required groups have approved; marks Billing.Withdraw.Approved=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office application | API call | Consumer | Called by the BO web application when a manager submits a withdrawal approval decision |
| BackOffice.WithdrawApprovalGet | SELECT | Related reader | Reads the same BackOffice.WithdrawApproval table to retrieve current approval status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.WithdrawApprovalAdd (procedure)
+-- Billing.Withdraw (table) [SELECT: pre-validate state]
+-- Dictionary.CashoutStatus (table) [SELECT: 'Canceled' status ID lookup]
+-- BackOffice.WithdrawApproval (table) [UPDATE + INSERT: upsert target]
+-- History.WithdrawApproval (table) [INSERT: audit mirror]
+-- Maintenance.Feature (table) [SELECT XML: approval amount thresholds]
+-- BackOffice.Customer (table) [EXISTS: IsAffiliate check for Marketing waiver]
+-- BackOffice.WithdrawRequestApprove (procedure) [EXEC: final approval when all groups OK]
      +-- Billing.Withdraw (table) [SELECT: validate state]
      +-- BackOffice.WithdrawApproval (table) [SELECT TOP 1: best comment]
      +-- Billing.UpsertWithdraw (procedure) [EXEC: set Approved=1]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT before transaction: Amount, CID, Approved, CashoutStatusID for pre-validation |
| Dictionary.CashoutStatus | Table | SELECT: lookup CashoutStatusID for 'Canceled' name-to-ID resolution |
| BackOffice.WithdrawApproval | Table | Upsert target: IF EXISTS UPDATE WITH OUTPUT ELSE INSERT |
| History.WithdrawApproval | Table | INSERT: receives old row values captured via OUTPUT clause |
| Maintenance.Feature | Table | SELECT MIN(XMLValue): four approval threshold amounts |
| BackOffice.Customer | Table | EXISTS check: IsAffiliate=0 waives Marketing approval requirement |
| BackOffice.WithdrawRequestApprove | Procedure | EXEC when all groups satisfied: marks withdrawal as fully approved |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office application | External | Primary consumer - called when managers submit withdrawal decisions |
| BackOffice.WithdrawApprovalUpsert | Procedure | Alternative write path for the same table |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NoCount ON` - suppresses row-count messages
- Pre-validation runs OUTSIDE the transaction - no rollback needed if validation fails
- Transaction uses `BEGIN TRY / BEGIN CATCH` with THROW re-raise
- CATCH block logic: `@@TRANCOUNT=1` -> ROLLBACK; `@@TRANCOUNT>1` -> COMMIT (handles nested SP scenarios)
- `@@Error` checked manually at two points within the TRY block (legacy pattern before THROW was standard)
- Error code 60025: withdrawal already approved or in canceled status
- Error code 60000: SQL DML error within the transaction
- The @Info table variable is declared for history mirroring: `(ApprovedWithdrawID, WithdrawID, UserGroupID, ManagerID, WithdrawApprovalReasonID, Approved, Occurred, Comment)` - matches BackOffice.WithdrawApproval structure for SELECT * mirroring

---

## 8. Sample Queries

### 8.1 Submit Admin group approval for a withdrawal

```sql
-- Approve withdrawal 1734869 from Admin group (manager 780, reason Other)
EXEC BackOffice.WithdrawApprovalAdd
    @WithdrawID = 1734869,
    @UserGroupID = 1,    -- Admin
    @ManagerID = 780,
    @WithdrawApprovalReasonID = 7,  -- Other
    @Approved = 1,
    @Comment = 'Admin approval';
-- Returns IsWithdrawApprove: 1 if all groups approved, 0 if still pending
```

### 8.2 Check current approval state for a withdrawal before calling

```sql
SELECT
    w.WithdrawID, w.Amount, w.Approved, cs.Name AS CashoutStatus,
    wa.UserGroupID, ug.Name AS GroupName, wa.Approved AS GroupApproved,
    wa.ManagerID, wa.Occurred
FROM Billing.Withdraw w WITH (NOLOCK)
LEFT JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = w.CashoutStatusID
LEFT JOIN BackOffice.WithdrawApproval wa WITH (NOLOCK) ON wa.WithdrawID = w.WithdrawID
LEFT JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON ug.UserGroupID = wa.UserGroupID
WHERE w.WithdrawID = 1734869;
```

### 8.3 Check current approval amount thresholds from Maintenance.Feature

```sql
SELECT
    MIN(XMLValue.value('/Settings[1]/Accounting[1]/WithdrawAdminApprovalFrom[1]', 'Money')) AS AdminThreshold,
    MIN(XMLValue.value('/Settings[1]/Accounting[1]/WithdrawRiskApprovalFrom[1]', 'Money')) AS RiskThreshold,
    MIN(XMLValue.value('/Settings[1]/Accounting[1]/WithdrawMarketingApprovalFrom[1]', 'Money')) AS MarketingThreshold,
    MIN(XMLValue.value('/Settings[1]/Accounting[1]/WithdrawTradingApprovalFrom[1]', 'Money')) AS TradingThreshold
FROM Maintenance.Feature WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Initial Design Of Approval Service](https://etoro-jira.atlassian.net/wiki/spaces/OG/pages/11898683534) | Confluence (OG space, 2023) | Initial design of approval service - page found but not accessible |
| [MIMOPSB-929 - Approval dependencies on etoro db](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11702501687) | Confluence (MG space, 2022) | Documents approval dependencies in etoro DB - page found but not accessible |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 2 Confluence found (not accessible) + 0 Jira | Procedures: 2 callees analyzed (WithdrawRequestApprove, UpsertWithdraw chain) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.WithdrawApprovalAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.WithdrawApprovalAdd.sql*

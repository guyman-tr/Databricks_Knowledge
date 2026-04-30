# Billing.AmountAddBonus

> Complex bonus-award procedure that validates a 6-stage campaign gate, acquires a session-scoped application lock, calls Customer.SetBalance with CreditTypeID=7 (Bonus), and tracks the award in BackOffice.Bonus, BackOffice.Campaign aggregates, History.Position_Extra (for P&L-type bonuses), and BackOffice.BonusOnlyCustomers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CheckResult OUTPUT (0=success, 1-6=failure/campaign edge case); RETURN 0 (success) or -1 (exception) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AmountAddBonus` is the dedicated bonus-award entry point in the Billing schema. Unlike `Billing.AmountAdd` (which handles general credits), this procedure enforces campaign integrity rules before crediting. When a customer qualifies for a bonus - whether from a deposit campaign, championship, refer-a-friend program, or manual award - this procedure runs through a validation gate that checks:

- Is the campaign still active?
- Has this customer already received this specific bonus?
- Has the campaign reached its maximum participant count?
- Has the campaign exhausted its maximum bonus budget?

If any check fails, the bonus is not awarded and @CheckResult is set to a non-zero code that the caller can inspect. Importantly, edge cases 5 and 6 (user count or budget just exceeded by THIS bonus) still result in the bonus being awarded to the current customer - they are the "last" recipient who triggers campaign deactivation. The campaign is deactivated but the customer still gets their bonus.

The procedure uses a session-scoped application lock (`sp_getapplock 'AmountAddBonus'`) to serialize concurrent bonus awards - preventing a race condition where two simultaneous requests could both pass the duplicate-bonus check and both credit the same bonus.

VIP customers (PlayerLevelID=4) bypass all campaign checks - they always receive the bonus regardless of campaign status or limits.

---

## 2. Business Logic

### 2.1 Pre-Transaction PlayerLevel Read and Optimistic Duplicate Check

**What**: Before opening a transaction, the procedure reads the customer's player level and performs an optimistic duplicate-bonus check.

**Parameters/Columns Involved**: `@CID`, `@BonusTypeID`, `@CampaignID`, `@PlayerLevelID`, `@existFlag`

**Rules**:
- `SELECT @PlayerLevelID = ISNULL(PlayerLevelID, 0) FROM Customer.CustomerStatic WITH(NOLOCK) WHERE CID = @CID`.
- If `@PlayerLevelID = 4` (VIP): all campaign validation blocks are skipped entirely.
- Duplicate check (outside transaction, optimistic): checks both `History.Credit` and `History.ActiveCreditRecentMemoryBucket` for existing records with `CreditTypeID IN (2,5,7)` AND `CID=@CID` AND `BonusTypeID=@BonusTypeID` AND `CampaignID=@CampaignID`.
- `@existFlag = 1` if found in either source; `@existFlag = 0` if not found.
- This is a pre-lock optimistic read. A second identical request could concurrently also see @existFlag=0. The definitive check is repeated inside the application lock (section 2.4).

### 2.2 Campaign Validation Gate (Skipped for PlayerLevelID=4)

**What**: A 4-stage sequential check that validates the campaign has capacity before awarding the bonus. Executed only when `@CampaignID IS NOT NULL AND @PlayerLevelID <> 4`.

**Parameters/Columns Involved**: `@CampaignID`, `@CheckResult`, `BackOffice.Campaign`, `Billing.Deposit`

**Stage 1 - Campaign Active Check** (@CheckResult=1):
- `IF EXISTS (SELECT * FROM BackOffice.Campaign WHERE CampaignID=@CampaignID AND IsActive=0)`: campaign is already inactive.
- Action: SET @CheckResult=1, update Billing.Deposit with CampaignCodeID, BonusStatusID=2, BonusErrorCode=1, COMMIT, RETURN 0.
- Bonus NOT awarded.

**Stage 2 - Duplicate Bonus Check** (@CheckResult=2):
- `IF @existFlag = 1`: customer already received this bonus.
- Action: SET @CheckResult=2, update Billing.Deposit, COMMIT, RETURN 0.
- Bonus NOT awarded.

**Stage 3 - Max Users Check** (@CheckResult=3):
- `IF EXISTS (SELECT * FROM BackOffice.Campaign WHERE CampaignID=@CampaignID AND ParticipatedUsers>=MaxNumberOfUsers)`: campaign at user capacity.
- Action: SET @CheckResult=3, set Campaign.IsActive=0, call `Billing.P_EMail_BackOffice_Campaign_IsActive0`, update Billing.Deposit, COMMIT, RETURN 0.
- Bonus NOT awarded. Campaign deactivated and notification sent.

**Stage 4 - Max Amount Check** (@CheckResult=4):
- Reads `MaxBonusAmount` and `CurrentBonusAmount` from `BackOffice.Campaign`.
- `IF @BonusAmount >= @MaxBonusAmount`: campaign has exhausted its budget.
- Action: SET @CheckResult=4, update Billing.Deposit, set Campaign.IsActive=0, call email proc, COMMIT, RETURN 0.
- Bonus NOT awarded. Campaign deactivated.

### 2.3 Campaign Counters Update and Edge Cases 5 & 6

**What**: After the 4 hard-stop checks pass, increments campaign user count and checks for budget-final-unit conditions. Unlike stages 1-4, stages 5 and 6 still award the bonus.

**Parameters/Columns Involved**: `@CheckResult`, `BackOffice.Campaign.ParticipatedUsers`, `BackOffice.Campaign.CurrentBonusAmount`

**Stage 5 - Users Just Maxed** (@CheckResult=5):
- `UPDATE BackOffice.Campaign SET ParticipatedUsers = ParticipatedUsers + 1 OUTPUT ... INTO @CampaignInfo`.
- If the result `UsersDelta <= 0`: campaign is now full. Action: set IsActive=0, @CheckResult=5, call email. Bonus IS STILL AWARDED (execution continues past this block).

**Stage 6 - Budget Just Maxed** (@CheckResult=6):
- `IF @BonusAmount + CAST(@Amount AS MONEY)/100 >= @MaxBonusAmount`: this bonus will exhaust or exceed the budget. Action: @CheckResult=6, update Billing.Deposit, set IsActive=0, call email. Bonus IS STILL AWARDED.
- ELSE (budget still has room): `UPDATE BackOffice.Campaign SET CurrentBonusAmount += CAST(@Amount AS MONEY)/100`.

### 2.4 Application Lock and Definitive Duplicate Check

**What**: Acquires an exclusive session-scoped application lock to serialize concurrent bonus awards and performs the definitive duplicate check.

**Parameters/Columns Involved**: `sp_getapplock`, `@existFlag`

**Rules**:
- `EXEC sp_getapplock 'AmountAddBonus', 'Exclusive', 'Session'` - blocks other sessions that also call AmountAddBonus until this lock is released.
- Lock acquired AFTER the BackOffice.Bonus INSERT (section 2.5) but BEFORE Customer.SetBalance.
- Second duplicate check: `IF @existFlag = 1` - if the optimistic pre-check found a duplicate, now inside the lock: ROLLBACK, release lock, SET @CheckResult=2, RETURN 0.
- This double-check pattern catches the race condition where two concurrent requests both passed the optimistic check but only one should proceed.
- Lock released with `EXEC sp_releaseapplock 'AmountAddBonus', 'Session'` after SetBalance completes.
- CATCH block checks `APPLOCK_MODE(...)` and releases the lock if still held on error.

### 2.5 BackOffice.Bonus Insert

**What**: Records every bonus award attempt (including cancelled ones) in BackOffice.Bonus.

**Parameters/Columns Involved**: All parameters mapped to BackOffice.Bonus columns

**Rules**:
- Executed BEFORE the application lock and BEFORE Customer.SetBalance.
- `@CampaignID=0` special case: converted to `(-1 * @BonusTypeID)` - synthetic negative CampaignID for non-campaign bonuses, enabling linking by BonusTypeID without mixing with real campaign IDs.
- @DepositID IS NULL hotfix: handled with `NULLIF(@DepositID, 0)` at line 273 - converts DepositID=0 to NULL before SetBalance (but the BackOffice.Bonus insert uses the raw @DepositID value).
- Note: the insert happens before the in-lock duplicate re-check. If the re-check rolls back, the BackOffice.Bonus row is rolled back too (same transaction).

### 2.6 Billing.Withdraw Update for Withdraw-Linked Bonuses

**What**: For bonuses linked to a withdrawal (chargeback compensation, withdrawal bonus), records the bonus deduction amount on the withdrawal record.

**Parameters/Columns Involved**: `@WithdrawID`, `Billing.Withdraw.ActualBonusDeductionAmount`

**Rules**:
- Condition: `@WithdrawID IS NOT NULL`.
- `UPDATE Billing.Withdraw SET ActualBonusDeductionAmount = CAST(@Amount AS MONEY) / 100 WHERE WithdrawID = @WithdrawID`.
- Division by 100: @Amount is MONEY but Billing.Withdraw stores amounts in standard currency units.

### 2.7 Customer.SetBalance Delegation

**What**: The actual balance credit is delegated to Customer.SetBalance with hardcoded CreditTypeID=7 (Bonus).

**Parameters/Columns Involved**: All context params

**Rules**:
- `EXECUTE @Answer = Customer.SetBalance ... @CreditTypeID = 7`.
- CreditTypeID is HARDCODED to 7 regardless of @AccountUpdateTypeID or @BonusTypeID.
- `@DepositID_HotFix = NULLIF(@DepositID, 0)` - DepositID=0 passed as NULL to avoid FK issues in SetBalance.
- @CurrencyID and @AccountUpdateTypeID are NOT forwarded to SetBalance (accepted as parameters but unused).
- IF @Answer != 0: RETURN @Answer (does not commit).

### 2.8 Championship Player PayOff Update

**What**: For championship-type bonuses, records the payout on the championship player record.

**Parameters/Columns Involved**: `@ChampionshipID`, `History.ChampionshipPlayer`

**Rules**:
- Condition: `@ChampionshipID IS NOT NULL`.
- `UPDATE History.ChampionshipPlayer SET PayOff = CAST(@Amount AS MONEY) / 100 WHERE ChampionshipID = @ChampionshipID AND EXISTS (SELECT * FROM Customer.Customer WHERE CID = History.ChampionshipPlayer.CID)`.

### 2.9 P&L Adjustment Bonus Tracking (BonusTypeID=39)

**What**: For P&L-adjustment bonuses, records the compensation in History.Position_Extra and excludes the position from statistics.

**Parameters/Columns Involved**: `@BonusTypeID`, `@PositionID`, `@Amount`, `History.PositionSlim`, `History.Position_Extra`

**Rules**:
- Condition: `@BonusTypeID = 39`.
- Validates position exists in `History.PositionSlim` (uses PositionSlim, not Position_Active as in AmountAdd).
- UPSERT into History.Position_Extra: INSERT if no existing record; UPDATE TotalCompensation += @Amount/100.0, ExcludeFromStatistics=1 if exists.
- If @PositionID IS NULL or position not in PositionSlim: RAISERROR(60000) - error path.

### 2.10 BonusOnlyCustomers Tracking

**What**: Tracks customers who have received bonuses but have never made a real deposit.

**Parameters/Columns Involved**: `@CID`, `BackOffice.BonusOnlyCustomers`, `BackOffice.CustomerAllTimeAggregatedData`

**Rules**:
- Condition: Customer NOT in BackOffice.BonusOnlyCustomers AND NOT in BackOffice.CustomerAllTimeAggregatedData with `TotalDeposit <> 0 OR ABS(TotalCompensation) >= 100`.
- If condition met: INSERT @CID into BackOffice.BonusOnlyCustomers.
- Identifies bonus-only accounts for fraud detection and reporting purposes.

### 2.11 Deposit Bonus Status Update (Success Path)

**What**: Updates the deposit record with campaign association and success status on the happy path.

**Parameters/Columns Involved**: `@CheckResult`, `@CampaignID`, `@DepositID`, `Billing.Deposit`

**Rules**:
- Condition: `@CheckResult NOT IN (1,2,3,4,5,6)` - i.e., @CheckResult=0 (no issue, or non-campaign bonus).
- `UPDATE Billing.Deposit SET CampaignCodeID=@CampaignID, BonusStatusID=1 WHERE DepositID=@DepositID`.
- BonusStatusID=1 = bonus successfully applied (vs 2 = bonus failed/rejected).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | Customer ID receiving the bonus. Passed to Customer.SetBalance. FK to Customer.Customer.CID. |
| 2 | @CurrencyID | INTEGER | NO | - | VERIFIED | Account currency. Accepted but NOT used in any active code path (legacy parameter, like in AmountAdd). Implicit FK to Dictionary.Currency. |
| 3 | @AccountUpdateTypeID | INTEGER | NO | - | VERIFIED | Business operation type. Accepted but NOT forwarded to Customer.SetBalance - CreditTypeID is hardcoded to 7 (Bonus) regardless of this value. |
| 4 | @Amount | MONEY | NO | - | VERIFIED | Bonus amount. Unlike AmountAdd which uses INTEGER cents, this uses MONEY type (direct currency units). Passed to Customer.SetBalance as @Payment. Divided by 100.0 when writing to Position_Extra/Withdraw fields (possible double-conversion on those paths - caller behavior). |
| 5 | @BonusTypeID | INTEGER | NO | - | VERIFIED | Type of bonus. Controls P&L compensation path (=39). Also used as synthetic CampaignID (when @CampaignID=0: stored as -1*@BonusTypeID). Passed to BackOffice.Bonus and Customer.SetBalance. |
| 6 | @CheckResult | INTEGER | YES | - | VERIFIED | OUTPUT parameter. Set by the procedure to indicate outcome: 0=success (bonus awarded), 1=campaign inactive, 2=customer already got bonus, 3=max users exceeded (campaign deactivated), 4=max amount exceeded (campaign deactivated), 5=max users just reached (bonus awarded, campaign deactivated), 6=max amount just reached (bonus awarded, campaign deactivated). Note: 3 and 4 do NOT award the bonus; 5 and 6 DO award the bonus. |
| 7 | @ManagerID | INTEGER | YES | NULL | VERIFIED | Back-office manager ID authorizing the bonus. Passed to Customer.SetBalance for audit. NULL for automated/system awards. |
| 8 | @Description | VARCHAR(255) | YES | NULL | VERIFIED | Free-text description of the bonus. Stored in BackOffice.Bonus.Description and passed to Customer.SetBalance. |
| 9 | @ChampionshipID | INTEGER | YES | NULL | VERIFIED | Championship ID for championship-related bonuses. Triggers History.ChampionshipPlayer.PayOff update. Passed to Customer.SetBalance. NULL for non-championship bonuses. |
| 10 | @CampaignID | INTEGER | YES | NULL | VERIFIED | Marketing campaign ID. NULL = no campaign (full validation bypass). 0 = converted to (-1 * @BonusTypeID) as a synthetic non-campaign ID. Positive value = validated against BackOffice.Campaign rules. |
| 11 | @UsedCampaignCode | VARCHAR(50) | YES | NULL | VERIFIED | Coupon/promo code the customer used to trigger this campaign bonus. Stored in BackOffice.Bonus.UsedCampaignCode. |
| 12 | @DepositID | INTEGER | YES | NULL | VERIFIED | Deposit that triggered this bonus. Value 0 treated as NULL (NULLIF hotfix from Dec 2014). Used to update Billing.Deposit bonus status columns. |
| 13 | @BonusStatusID | INTEGER | NO | - | VERIFIED | Initial bonus status written to BackOffice.Bonus. On success, Billing.Deposit.BonusStatusID is updated to 1. Common values: 1=Active/Awarded, 2=Rejected/Cancelled. |
| 14 | @PositionID | BIGINT | YES | NULL | VERIFIED | Position ID for P&L-type bonuses. Used for History.Position_Extra upsert when @BonusTypeID=39. Passed to Customer.SetBalance. |
| 15 | @MoveMoneyReasonID | INTEGER | YES | NULL | VERIFIED | Reason code for money movement. Passed to Customer.SetBalance and stored in BackOffice.Bonus. |
| 16 | @WithdrawID | INTEGER | YES | NULL | VERIFIED | Withdrawal ID when bonus is linked to a cashout (e.g., withdrawal deduction reversal). Triggers update of Billing.Withdraw.ActualBonusDeductionAmount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | READER | SELECT PlayerLevelID pre-transaction to determine if VIP bypass applies. |
| @CampaignID | BackOffice.Campaign | READER + WRITER | Reads IsActive, MaxNumberOfUsers, ParticipatedUsers, MaxBonusAmount, CurrentBonusAmount. Updates ParticipatedUsers+1, IsActive=0, CurrentBonusAmount on relevant conditions. |
| @CID, @BonusTypeID, @CampaignID | History.Credit | READER | Pre-transaction duplicate bonus check (CreditTypeID IN 2,5,7). |
| @CID, @BonusTypeID, @CampaignID | History.ActiveCreditRecentMemoryBucket | READER | In-memory recent credits check for duplicate detection. |
| @CID, @BonusTypeID | BackOffice.Bonus | WRITER (INSERT) | Inserts bonus award record for all award attempts. |
| @WithdrawID | Billing.Withdraw | WRITER (UPDATE) | Updates ActualBonusDeductionAmount for withdraw-linked bonuses. |
| @DepositID | Billing.Deposit | WRITER (UPDATE) | Updates CampaignCodeID, BonusStatusID, BonusAmount, BonusErrorCode on deposit record. |
| @CampaignID | Billing.P_EMail_BackOffice_Campaign_IsActive0 | EXEC | Sends deactivation notification when campaign reaches user or budget limits. |
| All params | Customer.SetBalance | EXEC (cross-schema) | Core balance credit delegation with hardcoded CreditTypeID=7. |
| @ChampionshipID | History.ChampionshipPlayer | WRITER (UPDATE) | Sets PayOff = @Amount/100 for championship bonuses. |
| @PositionID | History.PositionSlim | READER | EXISTS check to validate position before P&L compensation write (BonusTypeID=39). |
| @PositionID | History.Position_Extra | WRITER (INSERT/UPDATE) | Upserts TotalCompensation and ExcludeFromStatistics=1 for BonusTypeID=39. |
| @CID | BackOffice.BonusOnlyCustomers | WRITER (INSERT) | Tracks bonus-only customers (no real deposits). |
| @CID | BackOffice.CustomerAllTimeAggregatedData | READER | EXISTS check used in BonusOnlyCustomers decision. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from campaign management, deposit processing, and manual bonus award workflows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AmountAddBonus (procedure)
|- Customer.CustomerStatic (table)                 [SELECT - PlayerLevelID VIP bypass]
|- History.Credit (table)                          [SELECT - pre-tx duplicate check]
|- History.ActiveCreditRecentMemoryBucket (table)  [SELECT - in-memory duplicate check]
|- BackOffice.Campaign (table)                     [READ/WRITE - campaign validation + counters]
|- BackOffice.Bonus (table)                        [INSERT - bonus award record]
|- Billing.Withdraw (table)                        [UPDATE - withdrawal bonus deduction]
|- Billing.Deposit (table)                         [UPDATE - deposit bonus status]
|- Billing.P_EMail_BackOffice_Campaign_IsActive0 (proc) [EXEC - campaign deactivation email]
|- Customer.SetBalance (proc cross-schema)         [EXEC - core balance credit]
|- History.ChampionshipPlayer (table)              [UPDATE - championship payoff]
|- History.PositionSlim (table)                    [SELECT - P&L bonus position validation]
|- History.Position_Extra (table)                  [INSERT/UPDATE - P&L compensation tracking]
|- BackOffice.BonusOnlyCustomers (table)           [INSERT - deposit-free customer tracking]
+- BackOffice.CustomerAllTimeAggregatedData (table)[SELECT - used in BonusOnlyCustomers decision]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Stored Procedure (cross-schema) | Core balance credit with CreditTypeID=7 (Bonus) |
| BackOffice.Campaign | Table | Campaign validity and budget checks; incremented ParticipatedUsers; deactivated on limits |
| BackOffice.Bonus | Table | INSERT for every bonus award attempt |
| Billing.Deposit | Table | UPDATE bonus status/codes on the triggering deposit |
| Billing.Withdraw | Table | UPDATE ActualBonusDeductionAmount for withdraw-linked bonuses |
| Customer.CustomerStatic | Table | SELECT PlayerLevelID for VIP bypass check |
| History.Credit | Table | Pre-transaction duplicate bonus check |
| History.ActiveCreditRecentMemoryBucket | Table | In-memory recent credits for duplicate detection |
| History.Position_Extra | Table | INSERT/UPDATE TotalCompensation for BonusTypeID=39 |
| History.PositionSlim | Table | EXISTS validation for P&L bonus position |
| History.ChampionshipPlayer | Table | UPDATE PayOff for championship bonuses |
| BackOffice.BonusOnlyCustomers | Table | INSERT for customers with no real deposits |
| BackOffice.CustomerAllTimeAggregatedData | Table | EXISTS check for BonusOnlyCustomers decision |
| Billing.P_EMail_BackOffice_Campaign_IsActive0 | Stored Procedure | Campaign deactivation notification |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from campaign and payment processing systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **@Amount is MONEY not INTEGER**: Unlike Billing.AmountAdd (which uses INTEGER cents), this procedure accepts MONEY type. However, when updating Billing.Withdraw or History.Position_Extra, it divides by 100 (`CAST(@Amount AS MONEY)/100`) - this suggests the caller may be passing cents as a MONEY value, or the division is legacy code from when the type was different.
- **CreditTypeID hardcoded to 7**: The @AccountUpdateTypeID parameter is accepted but never used. CreditTypeID=7 (Bonus) is always passed to Customer.SetBalance.
- **Double duplicate check**: An optimistic pre-transaction check and a definitive in-lock check. The gap between the two is a design choice - the BackOffice.Bonus INSERT happens between them (inside the transaction but before the lock). If the in-lock check rolls back, the Bonus INSERT is also rolled back.
- **CATCH uses PRINT not THROW**: Unlike Billing.AmountAdd which re-throws with THROW 60000, this procedure uses PRINT (which writes to the messages buffer but doesn't propagate as an error) and RETURN -1. Callers checking only the return code would detect failure; callers using try-catch may not surface the full error.
- **Transaction structure**: BEGIN TRANSACTION inside BEGIN TRY (after the pre-transaction reads). Early exits (CheckResult 1-4) all include explicit COMMIT TRANSACTION.

---

## 8. Sample Queries

### 8.1 Award a campaign bonus on deposit
```sql
DECLARE @CheckResult INT;
EXEC Billing.AmountAddBonus
    @CID                 = 12345,
    @CurrencyID          = 1,
    @AccountUpdateTypeID = 3,
    @Amount              = 5000,       -- $50.00 (MONEY type)
    @BonusTypeID         = 15,
    @CheckResult         = @CheckResult OUTPUT,
    @CampaignID          = 987,
    @DepositID           = 99887766,
    @BonusStatusID       = 1,
    @Description         = 'Welcome deposit bonus';
SELECT @CheckResult AS Result;
-- 0 = success; 1 = campaign inactive; 2 = already got bonus; 3-6 = edge cases
```

### 8.2 Award a non-campaign bonus (no campaign validation)
```sql
DECLARE @CheckResult INT;
EXEC Billing.AmountAddBonus
    @CID                 = 12345,
    @CurrencyID          = 1,
    @AccountUpdateTypeID = 3,
    @Amount              = 10000,
    @BonusTypeID         = 5,
    @CheckResult         = @CheckResult OUTPUT,
    @CampaignID          = NULL,       -- NULL = skip campaign checks
    @BonusStatusID       = 1,
    @ManagerID           = 999,
    @Description         = 'Goodwill bonus - manual';
SELECT @CheckResult AS Result;  -- Always 0 for non-campaign bonuses
```

### 8.3 Inspect campaign state after bonus awards
```sql
SELECT  CampaignID,
        IsActive,
        ParticipatedUsers,
        MaxNumberOfUsers,
        CurrentBonusAmount,
        MaxBonusAmount
FROM    BackOffice.Campaign WITH (NOLOCK)
WHERE   CampaignID = 987;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 16 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AmountAddBonus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AmountAddBonus.sql*

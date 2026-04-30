# Billing.CheckMemberLimit

> Validates a proposed deposit amount against the customer's player-level deposit velocity limits from Billing.MemberLimit, returning @CheckResult=0 if within all limits or 1-6 for the first violated limit; mirrors CheckFundingTypeLimit but segments by PlayerLevelID instead of FundingTypeID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CheckResult OUTPUT: 0=OK, 1=MonthlyTxnCount, 2=MonthlyAmount, 3=WeeklyTxnCount, 4=WeeklyAmount, 5=DailyTxnCount, 6=DailyAmount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckMemberLimit` enforces deposit velocity limits segmented by the customer's player (member) level. Different player levels can have different deposit caps - for example, Bronze-tier customers may have lower limits than higher-tier customers. This allows eToro to implement tiered deposit controls as part of player classification and responsible gambling/AML compliance.

The procedure checks the same six limit dimensions as `Billing.CheckFundingTypeLimit` (monthly/weekly/daily transaction count and amount), but looks up limits from `Billing.MemberLimit` by @PlayerLevelID rather than by @FundingTypeID.

Currently, `Billing.MemberLimit` contains only one active tier record (PlayerLevelID=1, Bronze), with amounts stored in cents. All other player levels effectively have no limits.

**Key difference from CheckFundingTypeLimit**: CheckMemberLimit uses >= for comparisons (the limit value is the maximum EXCLUSIVE bound), while CheckFundingTypeLimit uses > (limit value is inclusive). This is a subtle but important behavioral distinction.

---

## 2. Business Logic

### 2.1 Member Limit Enforcement Flow

**What**: Loads current period deposit totals for the customer and compares against the player-level limits.

**Columns/Parameters Involved**: `@CID`, `@PlayerLevelID`, `@Amount`, `@CheckResult`

**Rules**:
1. **Load history**: Queries `Billing.Deposit` and `Billing.Payment` for the customer's approved deposits in the current month, week (Monday-based), and day.
2. **Load limits**: Reads from `Billing.MemberLimit` for @PlayerLevelID. If no row exists, limits default to NULL and all checks pass.
3. **Monthly transaction count**: If (existing monthly count + 1) >= MonthlyTransactionLimit -> @CheckResult=1, RETURN.
4. **Monthly amount**: If (existing monthly amount + @Amount) >= MonthlyAmountLimit -> @CheckResult=2, RETURN.
5. **Weekly transaction count**: If (existing weekly count + 1) >= WeeklyTransactionLimit -> @CheckResult=3, RETURN.
6. **Weekly amount**: If (existing weekly amount + @Amount) >= WeeklyAmountLimit -> @CheckResult=4, RETURN.
7. **Daily transaction count**: If (existing daily count + 1) >= DailyTransactionLimit -> @CheckResult=5, RETURN.
8. **Daily amount**: If (existing daily amount + @Amount) >= DailyAmountLimit -> @CheckResult=6, RETURN.
9. **All pass**: @CheckResult=0, RETURN.

**@CheckResult Values**:
| Value | Violation | Description |
|-------|-----------|-------------|
| 0 | None | All limits passed - deposit is within bounds |
| 1 | MonthlyTxnCount | Transaction count this calendar month has reached the limit |
| 2 | MonthlyAmount | Cumulative amount this calendar month has reached the limit |
| 3 | WeeklyTxnCount | Transaction count this week has reached the limit |
| 4 | WeeklyAmount | Cumulative amount this week has reached the limit |
| 5 | DailyTxnCount | Transaction count today has reached the limit |
| 6 | DailyAmount | Cumulative amount today has reached the limit |

**Note on Amounts**: Billing.MemberLimit stores amounts in cents (not dollars). The comparison must account for unit alignment with @Amount.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose deposit history is aggregated. Used to query Billing.Deposit and Billing.Payment for prior transactions in the current periods. |
| 2 | @PlayerLevelID | INTEGER | NO | - | CODE-BACKED | The customer's player/member level. Used to look up the corresponding limit record in Billing.MemberLimit (1=Bronze is the only active level; others have no limits configured). |
| 3 | @Amount | MONEY | NO | - | CODE-BACKED | The proposed deposit amount to add to running period totals for cumulative amount limit checks (@CheckResult=2, 4, 6). |
| 4 | @CheckResult | INTEGER | YES | - | CODE-BACKED | OUTPUT parameter. Returns 0 if all limits pass, or 1-6 indicating the first limit reached. Set to 0 on entry; only changed if a limit is hit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit | READER | Loads monthly/weekly/daily deposit counts and amounts for this customer |
| @CID | Billing.Payment | READER | Loads payment history for same period aggregations |
| @PlayerLevelID | Billing.MemberLimit | READER | Reads the configured limits by player tier (currently only PlayerLevelID=1 Bronze has data) |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from payment authorization application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckMemberLimit (procedure)
+-- Billing.Deposit (table)          [READ - period deposit count/amount aggregation]
+-- Billing.Payment (table)          [READ - period payment count/amount aggregation]
+-- Billing.MemberLimit (table)      [READ - player-level limits (only Bronze/level 1 configured)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ - aggregates deposit count and amount by day/week/month for this CID |
| Billing.Payment | Table | READ - aggregates payment count and amount for same periods |
| Billing.MemberLimit | Table | READ - loads configured transaction and amount limits per PlayerLevelID |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **>= not >**: Unlike `CheckFundingTypeLimit` which uses strict greater-than (`>`), this procedure uses `>=`. If the limit is 3 transactions, the 3rd transaction FAILS (count=3 >= 3). The limit value is exclusive: MemberLimit.DailyTransactionLimit=3 means at most 2 transactions per day are allowed.
- **Amounts in cents**: Billing.MemberLimit stores amounts in cents. If @Amount is in dollars, unit alignment is needed. For example, a $100 limit is stored as 10000 in MemberLimit.
- **Only Bronze active**: Currently Billing.MemberLimit has data only for PlayerLevelID=1 (Bronze). All other player levels pass all checks (NULL >= anything = NULL = false, no violation).
- **Monday-based week**: Week aggregation uses Monday as the week start day, consistent with Billing.MemberLimit's WeeklyAmountLimit semantics as documented in the table wiki.
- **Parallel to CheckFundingTypeLimit**: Same six-check structure, same @CheckResult codes, same Deposit+Payment history sources. Only differs in lookup table (MemberLimit vs FundingTypeLimit) and comparison operator (>= vs >).

---

## 8. Sample Queries

### 8.1 Check member limit for a deposit
```sql
DECLARE @CheckResult INT;
EXEC Billing.CheckMemberLimit
    @CID          = 100001,
    @PlayerLevelID = 1,       -- Bronze
    @Amount        = 200.00,
    @CheckResult   = @CheckResult OUTPUT;
SELECT @CheckResult AS CheckResult,
    CASE @CheckResult
        WHEN 0 THEN 'OK - within all limits'
        WHEN 1 THEN 'Monthly transaction count reached'
        WHEN 2 THEN 'Monthly amount reached'
        WHEN 3 THEN 'Weekly transaction count reached'
        WHEN 4 THEN 'Weekly amount reached'
        WHEN 5 THEN 'Daily transaction count reached'
        WHEN 6 THEN 'Daily amount reached'
    END AS Description;
```

### 8.2 View configured member limits
```sql
SELECT PlayerLevelID,
       DailyTransactionLimit, DailyAmountLimit,
       WeeklyTransactionLimit, WeeklyAmountLimit,
       MonthlyTransactionLimit, MonthlyAmountLimit
FROM Billing.MemberLimit WITH (NOLOCK);
-- Currently returns 1 row: PlayerLevelID=1 (Bronze), amounts in cents
```

### 8.3 Check recent deposits for a customer
```sql
SELECT CID, Amount, CreationDate, PaymentStatusID
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = 100001
  AND PaymentStatusID = 2  -- Approved
  AND CreationDate >= CAST(GETDATE() AS DATE)
ORDER BY CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckMemberLimit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckMemberLimit.sql*

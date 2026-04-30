# Billing.MemberLimit

> Configuration table defining the maximum number and total value of deposit transactions allowed per customer per day/week/month, keyed by loyalty tier - currently only a Bronze tier limit is configured.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | MemberLimitID (INT IDENTITY, PK NONCLUSTERED) |
| **Partition** | MAIN filegroup |
| **Indexes** | 2 active (PK NC on MemberLimitID + NC on PlayerLevelID) |

---

## 1. Business Meaning

Billing.MemberLimit defines deposit velocity limits per eToro Club loyalty tier. For each tier, the table stores the maximum number of approved deposits (transaction count) and the maximum total deposit value (in cents) that a customer may accumulate within a day, week, and month. Before a deposit is approved, Billing.CheckMemberLimit compares the customer's recent deposit history against the limits for their PlayerLevelID.

This table exists as a fraud prevention and AML (Anti-Money Laundering) control. Unlimited deposit velocity from a single account would be a red flag for suspicious activity. The tier-based design allows higher-value customers (Diamond, Platinum) to have higher or no limits, reflecting their legitimacy and importance, while Bronze-tier customers (who are unverified or low-balance) face stricter controls.

Currently only one row exists (Bronze / PlayerLevelID=1), meaning limits are only enforced for Bronze-tier customers. All higher tiers (Silver=5, Gold=3, Platinum=2, Platinum Plus=6, Diamond=7) have no configured limits, so Billing.CheckMemberLimit returns @CheckResult=0 (pass) for them unconditionally (no matching row found in the WHERE clause returns NULL, which fails the >= comparison). The large configured amounts ($30,000 per day/week/month at ~DailyAmount=3,000,000 cents) serve as a ceiling more than a practical daily limit.

---

## 2. Business Logic

### 2.1 Deposit Velocity Check Algorithm

**What**: Billing.CheckMemberLimit enforces the limits using a 6-way check against recent approved deposit totals.

**Columns/Parameters Involved**: `DailyTransaction`, `DailyAmount`, `WeeklyTransaction`, `WeeklyAmount`, `MonthlyTransaction`, `MonthlyAmount`, `PlayerLevelID`

**Rules**:
- Billing.CheckMemberLimit aggregates approved deposits from Billing.Payment (PaymentTypeID=1, StatusID=2) and Billing.Deposit (StatusID=2) for the current calendar period.
- Returns @CheckResult OUTPUT:
  - 0 = All checks passed (deposit allowed)
  - 1 = Monthly transaction count >= MonthlyTransaction limit
  - 2 = Monthly amount sum >= MonthlyAmount limit
  - 3 = Weekly transaction count >= WeeklyTransaction limit
  - 4 = Weekly amount sum >= WeeklyAmount limit
  - 5 = Daily transaction count >= DailyTransaction limit
  - 6 = Daily amount sum >= DailyAmount limit
- Checks run in order: monthly first, then weekly, then daily. First violation stops checking.
- **Amount units**: Billing.Deposit.Amount is in dollars and is multiplied by 100 before summing. MemberLimit amounts are therefore in **cents** (DailyAmount=3,000,000 = $30,000 USD).
- Period boundaries: Monthly = calendar month start, Weekly = Monday of current week (DATEFIRST=1), Daily = midnight of current date. All use GETDATE() (server local time, not UTC).

### 2.2 Single Active Row

**What**: Only Bronze-tier limits are currently configured - all other tiers bypass the limit check.

**Columns/Parameters Involved**: `PlayerLevelID`, `MemberLimitID`

**Rules**:
- Only row: MemberLimitID=1, PlayerLevelID=1 (Bronze): Daily=100 transactions / $30,000; Weekly=1,000 / $30,000; Monthly=5,000 / $30,000.
- For PlayerLevelID 2-7: no matching row exists, so Billing.CheckMemberLimit finds no limits and returns @CheckResult=0 unconditionally.
- The table schema supports per-tier limits (FK to Dictionary.PlayerLevel), but higher tiers are intentionally unlimited or the rows haven't been populated.
- NOT FOR REPLICATION on the identity indicates this table was historically replicated.

---

## 3. Data Overview

| MemberLimitID | PlayerLevel | DailyTransaction | DailyAmount | WeeklyTransaction | WeeklyAmount | MonthlyTransaction | MonthlyAmount | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | Bronze (1) | 100 | 3,000,000 | 1,000 | 3,000,000 | 5,000 | 3,000,000 | Bronze customers may make up to 100 deposits per day and up to $30,000 in total deposits per day (all periods). The generous $30,000 daily cap functions as a fraud ceiling rather than a practical limit, while the 100-transaction-per-day count prevents high-frequency micro-deposit abuse. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MemberLimitID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate primary key. NOT FOR REPLICATION flag indicates this was historically part of a replicated topology. NONCLUSTERED PK - the MAIN filegroup hosts the table. |
| 2 | PlayerLevelID | int | NO | - | VERIFIED | eToro Club loyalty tier this limit row applies to. Explicit FK to Dictionary.PlayerLevel. Currently only PlayerLevelID=1 (Bronze) has a configured limit. Higher tiers have no row and are effectively unlimited. |
| 3 | DailyTransaction | int | NO | - | VERIFIED | Maximum number of approved deposits a customer at this tier may make within a calendar day. Bronze limit: 100. Enforced by Billing.CheckMemberLimit (@CheckResult=5 when exceeded). |
| 4 | DailyAmount | int | NO | - | VERIFIED | Maximum total approved deposit value in a calendar day, stored in **cents** (divide by 100 for USD). Bronze limit: 3,000,000 cents = $30,000 USD. Enforced by Billing.CheckMemberLimit (@CheckResult=6 when exceeded). Billing.Deposit.Amount (in dollars) is multiplied by 100 before comparison. |
| 5 | WeeklyTransaction | int | NO | - | VERIFIED | Maximum number of approved deposits within the current calendar week (Monday-Sunday, DATEFIRST=1). Bronze limit: 1,000. @CheckResult=3 when exceeded. |
| 6 | WeeklyAmount | int | NO | - | VERIFIED | Maximum total approved deposit value within the current calendar week, in cents. Bronze: 3,000,000 = $30,000. @CheckResult=4 when exceeded. |
| 7 | MonthlyTransaction | int | NO | - | VERIFIED | Maximum number of approved deposits within the current calendar month. Bronze limit: 5,000. @CheckResult=1 when exceeded. Checked first before weekly and daily limits. |
| 8 | MonthlyAmount | int | NO | - | VERIFIED | Maximum total approved deposit value within the current calendar month, in cents. Bronze: 3,000,000 = $30,000. @CheckResult=2 when exceeded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerLevelID | Dictionary.PlayerLevel | FK (explicit FK_DPLL_BMML) | References the loyalty tier this limit applies to. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CheckMemberLimit | PlayerLevelID | SELECT reader | Primary consumer. Looks up limits for the given @PlayerLevelID and compares against customer's deposit history. Returns @CheckResult code. |
| Billing.MemberLimitAdd | - | INSERT writer | Adds a new tier limit row. |
| Billing.MemberLimitUpdate | - | UPDATE writer | Updates limits for an existing tier. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MemberLimit (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerLevel | Table | Explicit FK target for PlayerLevelID column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CheckMemberLimit | Stored Procedure | SELECT reader - limit enforcement |
| Billing.MemberLimitAdd | Stored Procedure | INSERT writer |
| Billing.MemberLimitUpdate | Stored Procedure | UPDATE writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BMML | NC (PK) | MemberLimitID ASC | - | - | Active (FILLFACTOR=90, MAIN filegroup) |
| BMML_PLAYERLEVEL | NC | PlayerLevelID ASC | - | - | Active (FILLFACTOR=90, MAIN filegroup) - supports lookup by tier |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BMML | PRIMARY KEY | MemberLimitID NONCLUSTERED |
| FK_DPLL_BMML | FK | PlayerLevelID -> Dictionary.PlayerLevel(PlayerLevelID) |

---

## 8. Sample Queries

### 8.1 View all configured tier limits

```sql
SELECT
    pl.Name AS PlayerLevel,
    ml.DailyTransaction,
    ml.DailyAmount / 100.0 AS DailyAmountUSD,
    ml.WeeklyTransaction,
    ml.WeeklyAmount / 100.0 AS WeeklyAmountUSD,
    ml.MonthlyTransaction,
    ml.MonthlyAmount / 100.0 AS MonthlyAmountUSD
FROM Billing.MemberLimit ml WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON ml.PlayerLevelID = pl.PlayerLevelID
ORDER BY pl.Sort
```

### 8.2 Run a member limit check for a specific customer

```sql
DECLARE @CheckResult INT
EXEC Billing.CheckMemberLimit
    @CID = 12345,
    @PlayerLevelID = 1,  -- Bronze
    @CheckResult = @CheckResult OUTPUT
SELECT @CheckResult AS CheckResult
-- 0=Pass, 1=MonthlyTxn, 2=MonthlyAmt, 3=WeeklyTxn, 4=WeeklyAmt, 5=DailyTxn, 6=DailyAmt
```

### 8.3 Find tiers with no configured limits (unlimited)

```sql
SELECT pl.PlayerLevelID, pl.Name AS PlayerLevel
FROM Dictionary.PlayerLevel pl WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Billing.MemberLimit ml WITH (NOLOCK)
    WHERE ml.PlayerLevelID = pl.PlayerLevelID
)
ORDER BY pl.Sort
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (CheckMemberLimit + MemberLimitAdd) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.MemberLimit | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.MemberLimit.sql*

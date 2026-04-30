# Billing.MemberLimitUpdate

> Writer procedure that updates an existing deposit velocity limit row in Billing.MemberLimit by MemberLimitID, raising error 60021 if the row is not found.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MemberLimitID INTEGER - the row to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.MemberLimitUpdate modifies all seven configurable fields on an existing Billing.MemberLimit row, identified by its MemberLimitID. It allows backoffice or admin tools to adjust the deposit velocity limits (transaction counts and amounts per day/week/month) for any loyalty tier without needing to delete and re-insert the row.

If no row matches the given @MemberLimitID, the procedure raises error 60021 (a Billing-domain "record not found" error) and returns 60021 to the caller. This distinguishes a successful zero-change update from a missing-row scenario.

Currently Billing.MemberLimit has only one row (Bronze / MemberLimitID=1), so this procedure is called to adjust the Bronze-tier deposit limits when business or compliance requirements change.

---

## 2. Business Logic

### 2.1 Full Limit Row Update

**What**: Overwrites all 7 configurable fields on the target MemberLimit row.

**Columns/Parameters Involved**: `@MemberLimitID`, `@PlayerLevelID`, all six limit params

**Rules**:
- Updates Billing.MemberLimit SET PlayerLevelID, DailyTransaction, DailyAmount, WeeklyTransaction, WeeklyAmount, MonthlyTransaction, MonthlyAmount WHERE MemberLimitID=@MemberLimitID.
- ALL fields are updated in every call - there is no partial update mode. Pass current values for fields that should not change.
- @@ROWCOUNT = 0 after UPDATE -> RAISERROR(60021,16,1,'Billing.MemberLimit',@LocalError) + RETURN 60021.
- @@ROWCOUNT = 1 -> RETURN @LocalError (0 on success).
- Uses SET NOCOUNT ON.
- No TRY/CATCH - errors propagate unhandled except for the @@ROWCOUNT=0 check.

**Amount columns are in CENTS** (same as Billing.MemberLimitAdd and Billing.MemberLimit): DailyAmount=3,000,000 = $30,000 USD.

**Error 60021 semantics**: In the Billing domain, RAISERROR 60021 is the standard "update target not found" signal. Callers catching this error should verify the @MemberLimitID exists before retrying.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MemberLimitID | INTEGER | NO | - | CODE-BACKED | Primary key of the Billing.MemberLimit row to update. In production, only MemberLimitID=1 (Bronze) exists. If no row matches, error 60021 is raised. |
| 2 | @PlayerLevelID | INTEGER | NO | - | CODE-BACKED | New loyalty tier value. FK to Dictionary.PlayerLevel. Can be changed via this procedure (allows re-assigning a limit row to a different tier). Normally matches the existing value. |
| 3 | @DailyTransaction | INTEGER | NO | - | CODE-BACKED | New maximum number of approved deposits per calendar day. Bronze current: 100. @CheckResult=5 when exceeded during deposit processing. |
| 4 | @DailyAmount | INTEGER | NO | - | CODE-BACKED | New maximum total approved deposit value per calendar day, in CENTS. Bronze current: 3,000,000 (=$30,000 USD). @CheckResult=6 when exceeded. |
| 5 | @WeeklyTransaction | INTEGER | NO | - | CODE-BACKED | New maximum number of approved deposits per calendar week (Mon-Sun). Bronze current: 1,000. @CheckResult=3 when exceeded. |
| 6 | @WeeklyAmount | INTEGER | NO | - | CODE-BACKED | New maximum total approved deposit value per calendar week, in CENTS. Bronze current: 3,000,000. @CheckResult=4 when exceeded. |
| 7 | @MonthlyTransaction | INTEGER | NO | - | CODE-BACKED | New maximum number of approved deposits per calendar month. Bronze current: 5,000. @CheckResult=1 when exceeded. |
| 8 | @MonthlyAmount | INTEGER | NO | - | CODE-BACKED | New maximum total approved deposit value per calendar month, in CENTS. Bronze current: 3,000,000. @CheckResult=2 when exceeded. |
| RETURN | int | NO | - | CODE-BACKED | Returns @@ERROR (0 on success) or 60021 (if no row found for @MemberLimitID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | Billing.MemberLimit | WRITE | Updates the deposit velocity limits for the specified tier row. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing backoffice / admin tool | @MemberLimitID, limits | EXEC | Called to adjust deposit velocity thresholds for a loyalty tier. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MemberLimitUpdate (procedure)
└── Billing.MemberLimit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.MemberLimit | Table | UPDATE - modifies deposit velocity limit values. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing backoffice / admin tool | Application | EXEC - adjusts limit thresholds when compliance/business requirements change. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Update Bronze daily deposit count limit to 200
```sql
-- First check current values
SELECT * FROM Billing.MemberLimit WITH (NOLOCK) WHERE MemberLimitID = 1;

-- Update (must pass ALL fields - no partial update)
EXEC Billing.MemberLimitUpdate
    @MemberLimitID     = 1,
    @PlayerLevelID     = 1,          -- Bronze (unchanged)
    @DailyTransaction  = 200,        -- increased from 100
    @DailyAmount       = 3000000,    -- $30,000 (unchanged)
    @WeeklyTransaction = 1000,
    @WeeklyAmount      = 3000000,
    @MonthlyTransaction= 5000,
    @MonthlyAmount     = 3000000;
```

### 8.2 Verify after update
```sql
SELECT
    ml.MemberLimitID,
    pl.Name AS PlayerLevel,
    ml.DailyTransaction, ml.DailyAmount / 100.0 AS DailyAmountUSD,
    ml.WeeklyTransaction, ml.WeeklyAmount / 100.0 AS WeeklyAmountUSD,
    ml.MonthlyTransaction, ml.MonthlyAmount / 100.0 AS MonthlyAmountUSD
FROM Billing.MemberLimit ml WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON ml.PlayerLevelID = pl.PlayerLevelID
ORDER BY ml.MemberLimitID;
```

### 8.3 Test error 60021 handling
```sql
-- Update with a non-existent MemberLimitID (will return 60021)
DECLARE @rc INT;
EXEC @rc = Billing.MemberLimitUpdate
    @MemberLimitID = 9999,  -- does not exist
    @PlayerLevelID = 1,
    @DailyTransaction = 100,
    @DailyAmount = 3000000,
    @WeeklyTransaction = 1000,
    @WeeklyAmount = 3000000,
    @MonthlyTransaction = 5000,
    @MonthlyAmount = 3000000;
SELECT @rc AS ReturnCode;  -- Returns 60021
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.MemberLimitUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.MemberLimitUpdate.sql*

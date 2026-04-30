# BackOffice.IsDepositUser

> Returns 1 via OUTPUT parameter if the customer has ever made a deposit (TotalDeposit > 0 in CustomerAllTimeAggregatedData), 0 otherwise.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer ID); result returned via @Result OUTPUT (not a result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`IsDepositUser` is a lightweight flag check used to determine whether a given customer has ever deposited funds. The answer is derived from the pre-aggregated `BackOffice.CustomerAllTimeAggregatedData` table, which holds lifetime financial totals per customer, making this check a single index lookup rather than a scan of the transaction history.

The result is communicated via an OUTPUT parameter (`@Result BIT`) rather than a result set, which means callers must use `EXEC ... @Result OUTPUT` syntax and bind a variable to receive the value. This is an older T-SQL pattern used when the SP is embedded in a larger procedural flow where the boolean flag is consumed immediately.

A customer is considered a "deposit user" if their all-time `TotalDeposit` in the aggregated table exceeds 0. The aggregated table is updated by background jobs, so very recent first-deposits may not yet be reflected.

No callers found in the SSDT repo - called by external Back Office services that need to gate actions on deposit status (e.g. eligibility checks, classification changes, marketing triggers).

---

## 2. Business Logic

### 2.1 Deposit Status Check via Aggregated Table

**What**: Checks whether a customer's all-time total deposit is greater than zero using the pre-computed aggregation table.

**Columns/Parameters Involved**: `@CID`, `BackOffice.CustomerAllTimeAggregatedData.TotalDeposit`, `@Result`

**Rules**:
- Uses `IF EXISTS (SELECT 1 FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK) WHERE CID = @CID AND TotalDeposit > 0)`
- If the EXISTS check is TRUE: `SET @Result = 1` (customer has deposited)
- If the EXISTS check is FALSE: `SET @Result = 0` (customer has never deposited, or CID not found in aggregated table)
- The WITH (NOLOCK) hint means reads are dirty - a deposit in flight may or may not be reflected
- If the CID has no row in `CustomerAllTimeAggregatedData` at all, the EXISTS returns FALSE and @Result = 0 (treated as non-depositor)

**Diagram**:
```
@CID
  |
  v
EXISTS (CustomerAllTimeAggregatedData WHERE CID=@CID AND TotalDeposit > 0)?
  YES -> @Result = 1 (deposit user)
  NO  -> @Result = 0 (non-depositor or unknown CID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to check. Looked up in `BackOffice.CustomerAllTimeAggregatedData.CID`. If no row exists for this CID, @Result is set to 0. |
| 2 | @Result | BIT OUTPUT | NO | - | CODE-BACKED | OUTPUT parameter. Set to 1 if the customer has TotalDeposit > 0 in CustomerAllTimeAggregatedData; set to 0 if TotalDeposit = 0, TotalDeposit IS NULL, or CID not found. Callers must declare a BIT variable and pass it with OUTPUT keyword. |

**Output**: No result set. The single boolean answer is communicated exclusively via the `@Result OUTPUT` parameter.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.CustomerAllTimeAggregatedData | Lookup | EXISTS check on CID + TotalDeposit > 0 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.IsDepositUser (procedure)
└── BackOffice.CustomerAllTimeAggregatedData (table) [EXISTS check on TotalDeposit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | Table | EXISTS lookup: CID = @CID AND TotalDeposit > 0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by external Back Office services for deposit status gating |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OUTPUT parameter | Design | Result returned via @Result BIT OUTPUT, not a SELECT result set. Caller must use EXEC ... @Result OUTPUT syntax. |
| WITH (NOLOCK) | Query hint | Dirty read on CustomerAllTimeAggregatedData - very recent deposits may not yet be reflected if the aggregation job hasn't run |
| No SET NOCOUNT | Omission | Row-count messages are not suppressed (benign for EXISTS-only logic with no DML) |
| No TRY/CATCH | Design | Errors propagate to caller |

---

## 8. Sample Queries

### 8.1 Check if a customer is a deposit user

```sql
DECLARE @IsDepositor BIT;

EXEC [BackOffice].[IsDepositUser]
    @CID = 12345,
    @Result = @IsDepositor OUTPUT;

SELECT @IsDepositor AS IsDepositUser;
-- 1 = has deposited, 0 = never deposited
```

### 8.2 Check deposit status for multiple customers (manual loop pattern)

```sql
DECLARE @CID INT, @Result BIT;
DECLARE @Results TABLE (CID INT, IsDepositUser BIT);

DECLARE cids CURSOR FOR SELECT CID FROM #CustomerList;
OPEN cids;
FETCH NEXT FROM cids INTO @CID;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC BackOffice.IsDepositUser @CID = @CID, @Result = @Result OUTPUT;
    INSERT INTO @Results VALUES (@CID, @Result);
    FETCH NEXT FROM cids INTO @CID;
END;
CLOSE cids; DEALLOCATE cids;
```

### 8.3 Direct aggregated table query (equivalent logic)

```sql
SELECT
    CID,
    CASE WHEN TotalDeposit > 0 THEN 1 ELSE 0 END AS IsDepositUser,
    TotalDeposit
FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 6.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.IsDepositUser | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.IsDepositUser.sql*

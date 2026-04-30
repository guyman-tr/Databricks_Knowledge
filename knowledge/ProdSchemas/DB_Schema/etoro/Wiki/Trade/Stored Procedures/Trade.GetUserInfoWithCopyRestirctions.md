# Trade.GetUserInfoWithCopyRestirctions

> Orchestrator for copy-trade pre-execution validation - combines GetUserInfo (copier context), optional GetMirrorData (mirror details), active copy counts by type, RealCustomersDataAndRestrictions (target trader data), and copier's open position count into a multi-result-set response.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CopierCID + one of (@GCIDs, @CopiedCID, @MirrorID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserInfoWithCopyRestirctions` (note: "Restirctions" is a typo in the original - it persists in all callers) is the top-level orchestrator called by the copy-trade pre-execution engine when a customer attempts to start copying another trader. It validates eligibility from both sides: the copier's own context (credit, status, blocks) and the trader being copied (restrictions, profile from Real database).

The procedure returns up to 5 result sets depending on the parameters provided:
1. **GetUserInfo result set** - copier's full pre-execution context (always returned)
2. **MirrorData** - mirror details (only when @MirrorID is provided and @GCIDs is NULL)
3. **Active copy counts by MirrorType** - how many active copies the copier already has per type (CopyTrader vs Fund Copy)
4. **RealCustomersDataAndRestrictions** - the target trader's data and restrictions from the Real database (via dbo synonym)
5. **CopierOpenedPositionsCount** - total open positions count for the copier

The guard condition `IF (@GCIDs IS NOT NULL OR @CopiedCID IS NOT NULL OR @MirrorID IS NOT NULL)` ensures that at least one of the target-trader parameters is provided (otherwise nothing is returned).

---

## 2. Business Logic

### 2.1 Guard Condition (At Least One Target Parameter)

**What**: Procedure only executes if at least one of @GCIDs, @CopiedCID, or @MirrorID is provided.

**Rules**:
- IF condition: `@GCIDs IS NOT NULL OR @CopiedCID IS NOT NULL OR @MirrorID IS NOT NULL`
- If all three are NULL, procedure exits silently (no rows returned, no error)
- @GCIDs: comma-separated or TVP of GCIDs for target traders
- @CopiedCID: CID of the trader being copied
- @MirrorID: existing mirror ID (when updating/validating an existing copy relationship)

### 2.2 Copier Context (GetUserInfo)

**What**: Loads full pre-execution user context for the copier.

**Rules**:
- `EXEC Trade.GetUserInfo @CopierCID` - always executed when guard condition passes
- Returns result set 1: copier's credit, status, blocks, regulation, etc.
- See Trade.GetUserInfo documentation for full column detail

### 2.3 Mirror Data Resolution (When @MirrorID Provided)

**What**: When updating/validating an existing mirror, retrieves mirror details.

**Rules**:
- Only when `@GCIDs IS NULL AND @MirrorID IS NOT NULL`
- Creates temp table `#MirrorData_T` with mirror columns
- Populates via `EXEC Trade.GetMirrorData @MirrorID`
- Returns result set 2: full mirror data
- Extracts `@CopiedCID = TOP 1 ParentCID FROM #MirrorData_T` for use in subsequent calls

### 2.4 Active Copy Counts by Type

**What**: How many active copy relationships the copier has per MirrorTypeID.

**Columns**: `MirrorTypeID, NumberOfActiveCopies`

**Rules**:
- Queries `Trade.Mirror` where `IsActive=1 AND CID=@CopierCID`
- GROUP BY MirrorTypeID, joined to Dictionary.MirrorType
- MirrorTypeID values: 1=CopyTrader, 4=Fund Copy (likely)
- Used to enforce copy limits: e.g., max N active copy relationships per type

### 2.5 Target Trader Data and Restrictions (RealCustomersDataAndRestrictions)

**What**: Fetches the target trader's profile and copy restrictions from the Real database.

**Rules**:
- `EXEC dbo.RealCustomersDataAndRestrictions @GCIDs, @CopiedCID`
- `dbo.RealCustomersDataAndRestrictions` is a synonym pointing to the Real database
- Returns target trader profile including whether they accept new copiers, minimum copy amount, etc.
- Called with @GCIDs (batch) or @CopiedCID (single) - one of these is always non-NULL when the guard passes

### 2.6 Copier's Open Position Count

**What**: Count of all currently open positions for the copier.

**Columns**: `CopierOpenedPositionsCount`

**Rules**:
- `SELECT COUNT(*) FROM Trade.PositionTbl WHERE CID=@CopierCID AND StatusID=1`
- StatusID=1 = open positions
- Used to validate against position count limits

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CopierCID | INT | NO | - | CODE-BACKED | CID of the customer attempting to start copying. GetUserInfo is called with this CID. |
| 2 | @GCIDs | VARCHAR(MAX) | YES | NULL | CODE-BACKED | GCIDs of traders to be copied (comma-separated or similar format). Passed to RealCustomersDataAndRestrictions. |
| 3 | @CopiedCID | INT | YES | NULL | CODE-BACKED | CID of the specific trader being copied. Used when not using @GCIDs. Derived from mirror data when @MirrorID provided. |
| 4 | @MirrorID | INT | YES | NULL | CODE-BACKED | Existing mirror ID. When provided, triggers GetMirrorData call and @CopiedCID derivation from mirror. |

**Output result sets:**

Result Set 1: GetUserInfo columns for @CopierCID (see Trade.GetUserInfo.md for full column list).

Result Set 2 (conditional - only when @MirrorID is provided and @GCIDs is NULL):
- MirrorID, MirrorAmount, MirrorSLAmount, CID, RealizedEquity, MirrorSLPercentage, IsActive, MirrorTypeID, ParentCID, PauseCopy, MirrorCalculationType, MirrorStatusID, GCID, Registered

Result Set 3 (always):
| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 5 | MirrorTypeID | INT | NO | CODE-BACKED | Type of copy relationship. FK to Dictionary.MirrorType. |
| 6 | NumberOfActiveCopies | INT | NO | CODE-BACKED | Count of active mirrors with this type for the copier. |

Result Set 4: RealCustomersDataAndRestrictions columns (from Real database via dbo synonym).

Result Set 5:
| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 7 | CopierOpenedPositionsCount | INT | NO | CODE-BACKED | Total open positions (StatusID=1) for the copier in Trade.PositionTbl. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Result Set 1 | Trade.GetUserInfo | EXEC | Copier's full pre-execution context |
| Result Set 2 | Trade.GetMirrorData | EXEC | Mirror details (conditional on @MirrorID) |
| Active copies | Trade.Mirror | FROM | Count of active copies by type for copier |
| Active copies | Dictionary.MirrorType | INNER JOIN | Mirror type names |
| Result Set 4 | dbo.RealCustomersDataAndRestrictions | EXEC | Target trader data from Real database (synonym) |
| Position count | Trade.PositionTbl | FROM | Copier's open position count |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUserWithRestirctions | EXEC | Caller | Uses this as part of a broader restriction check orchestration |
| (copy-trade pre-execution engine) | @CopierCID | EXEC caller | Called when customer initiates copy |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserInfoWithCopyRestirctions (procedure)
+-- Trade.GetUserInfo (procedure)
+-- Trade.GetMirrorData (procedure) [conditional]
+-- Trade.Mirror (table) [active copy count]
+-- Dictionary.MirrorType (table)
+-- dbo.RealCustomersDataAndRestrictions (synonym -> Real DB procedure)
+-- Trade.PositionTbl (table) [open position count]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUserInfo | Stored Procedure | Result set 1: copier context |
| Trade.GetMirrorData | Stored Procedure | Result set 2: mirror detail (when @MirrorID provided) |
| Trade.Mirror | Table | Active copy count by type |
| Dictionary.MirrorType | Table | Mirror type name join |
| dbo.RealCustomersDataAndRestrictions | Synonym | Target trader data from Real database |
| Trade.PositionTbl | Table | Copier's open position count |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUserWithRestirctions | Stored Procedure | EXEC caller |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Guard condition | Business rule | Silently no-ops if all target parameters NULL |
| WITH (NOLOCK) | Isolation | Trade.Mirror and PositionTbl reads |
| StatusID = 1 | Filter | Only open positions counted |
| #MirrorData_T temp table | Data staging | Used to capture GetMirrorData output and extract @CopiedCID |

---

## 8. Sample Queries

### 8.1 Start copy with GCIDs
```sql
EXEC Trade.GetUserInfoWithCopyRestirctions
    @CopierCID = 123456,
    @GCIDs = '78901234,89012345',
    @CopiedCID = NULL,
    @MirrorID = NULL
```

### 8.2 Validate existing mirror
```sql
EXEC Trade.GetUserInfoWithCopyRestirctions
    @CopierCID = 123456,
    @GCIDs = NULL,
    @CopiedCID = NULL,
    @MirrorID = 99887766
-- Returns 5 result sets including mirror data
```

### 8.3 Check copier's active copy counts manually
```sql
SELECT tm.MirrorTypeID, COUNT(tm.MirrorID) AS NumberOfActiveCopies
FROM Trade.Mirror tm WITH (NOLOCK)
     INNER JOIN Dictionary.MirrorType dm WITH (NOLOCK) ON tm.MirrorTypeID = dm.MirrorTypeID
WHERE tm.IsActive = 1
  AND tm.CID = 123456
GROUP BY tm.MirrorTypeID
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian documentation found for this SP specifically. The copy-trade pre-execution context loading pattern is described generally in the TRAD/DB Confluence folder.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserInfoWithCopyRestirctions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserInfoWithCopyRestirctions.sql*

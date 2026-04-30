# RecurringInvestment.PlansGetUserPlansByPlanID

> Retrieves all plans belonging to the same user as a given PlanID, by first looking up the user's GCID from the specified plan.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanID input, returns all sibling plans for that plan's user |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a way to find all "sibling" plans of a given plan -- that is, all plans belonging to the same user. It performs a two-step lookup: first, it resolves the GCID from the provided @PlanID, then it retrieves all plans for that GCID. This is useful when the system has a PlanID but needs to see the full set of plans for that user, for example during plan modification flows where changes to one plan (like FundingID or RepeatsOn) may need to propagate to all the user's plans.

If the @PlanID does not exist (GCID is NULL after lookup), the procedure returns no results rather than raising an error.

Created per EDGE-3688 (Nilly Meyrav & Noga, 7/11/24).

---

## 2. Business Logic

### 2.1 GCID Lookup from PlanID

**What**: Resolves the owning user's GCID from the specified plan.

**Columns/Parameters Involved**: `@PlanID`, `GCID`, `@GCID`

**Rules**:
- DECLARE @GCID BIGINT
- SELECT @GCID = GCID FROM Plans WHERE ID = @PlanID
- If @PlanID does not exist, @GCID remains NULL
- No NOLOCK hint on this initial lookup (uses default isolation)

### 2.2 Conditional Plan Retrieval

**What**: Returns all plans for the resolved GCID, only if the GCID was found.

**Columns/Parameters Involved**: `@GCID`, all Plans columns

**Rules**:
- IF @GCID IS NOT NULL guards the main query
- SELECT all plan columns FROM Plans WHERE GCID = @GCID
- Uses NOLOCK hint for the main query
- Returns ALL plans for the user, regardless of status (active, cancelled, etc.)
- No instance data is returned -- only plan-level columns
- If @PlanID does not exist, nothing is returned (no error thrown)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanID | int | NO | - | VERIFIED | The plan ID to look up. Used to resolve the owning user's GCID. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlanID | int | NO | - | VERIFIED | Plans.ID - unique plan identifier. |
| 2 | GCID | bigint | NO | - | VERIFIED | User's Global Customer ID. |
| 3 | CID | bigint | YES | - | VERIFIED | User's Customer ID. |
| 4 | InstrumentID | int | YES | - | VERIFIED | Instrument for instrument-type plans. NULL for copy plans. |
| 5 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID. |
| 6 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in plan currency. |
| 7 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 8 | PlanStatusID | int | NO | - | VERIFIED | Plan lifecycle state (any status). See [Plan Status](../../_glossary.md#plan-status). |
| 9 | StatusReasonID | int | YES | - | VERIFIED | Reason for current status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 10 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 11 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. NULL if active. |
| 12 | DepositStartDate | datetime | YES | - | VERIFIED | When the first deposit occurred. |
| 13 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 14 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution. |
| 15 | HasBackupPayment | bit | YES | - | VERIFIED | Whether fallback payment is configured. |
| 16 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 17 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 18 | CopyType | int | NO | - | VERIFIED | Copy trading type. See [Copy Type](../../_glossary.md#copy-type). |
| 19 | PlanType | int | NO | - | VERIFIED | Instrument (1) or Copy (2). See [Plan Type](../../_glossary.md#plan-type). |
| 20 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader's CID. |
| 21 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader's GCID. |
| 22 | MopType | int | NO | - | VERIFIED | Payment method type. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PlanID | RecurringInvestment.Plans | Read | Lookup GCID from plan ID |
| @GCID | RecurringInvestment.Plans | Read | Retrieve all plans for user |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Plan Management Service | - | EXEC | Retrieves sibling plans for cross-plan operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetUserPlansByPlanID (procedure)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | Two reads: GCID lookup by PlanID, then all plans by GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Plan Management Service | Application | Sibling plan retrieval for cross-plan operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Main query uses NOLOCK hint; initial GCID lookup does not
- No transaction wrapper (read-only procedure)
- Two-step approach: first resolves GCID, then queries by GCID
- IF @GCID IS NOT NULL guards against invalid PlanID
- No instance data returned (plan-level only)

---

## 8. Sample Queries

### 8.1 Get all sibling plans for a given plan
```sql
EXEC [RecurringInvestment].[PlansGetUserPlansByPlanID] @PlanID = 1001
```

### 8.2 Verify the two-step lookup
```sql
-- Step 1: Find the GCID
SELECT GCID FROM [RecurringInvestment].[Plans] WHERE ID = 1001

-- Step 2: Find all plans for that GCID
SELECT * FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE GCID = 12345678
```

### 8.3 Check how many sibling plans a given plan has
```sql
DECLARE @GCID BIGINT
SELECT @GCID = GCID FROM [RecurringInvestment].[Plans] WHERE ID = 1001

SELECT COUNT(*) AS SiblingPlanCount
FROM [RecurringInvestment].[Plans] WITH (NOLOCK)
WHERE GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans table structure, GCID as user-level grouping key |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Cross-plan operations and plan modification architecture |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Sibling plan retrieval implementation |

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: RecurringInvestment.PlansGetUserPlansByPlanID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetUserPlansByPlanID.sql*

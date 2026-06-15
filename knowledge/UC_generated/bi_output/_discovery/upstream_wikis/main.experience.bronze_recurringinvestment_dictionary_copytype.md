# Dictionary.CopyType

> Lookup table classifying copy trading relationship types for recurring investment plans - direct instrument, Popular Investor, or SmartPortfolio.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table classifies the type of copy trading relationship a recurring investment plan uses. It determines whether a plan invests directly in a specific instrument, copies a Popular Investor (PI), or copies a SmartPortfolio. This distinction is fundamental to the recurring investment system because it controls which execution path the plan follows.

Without this table, the system could not differentiate between standard instrument-based recurring investments and copy trading plans, which follow entirely different execution flows (direct order vs. mirror/copy registration).

The CopyType value is set when a plan is created via the PlanInsert stored procedure and drives behavior in the Deposit Message Handler, Order Execution Job, and Before Deposit Job. Plans with CopyType=0 (None) use standard instrument ordering, while CopyType=1 (PI) or CopyType=4 (SmartPortfolio) use the copy trading pipeline.

---

## 2. Business Logic

### 2.1 Plan Type and Copy Type Correlation

**What**: PlanType and CopyType work together to determine a plan's investment strategy.

**Columns/Parameters Involved**: `ID`, `Name` (this table), `Plans.PlanType`, `Plans.CopyParentCID`, `Plans.CopyParentGCID`

**Rules**:
- PlanType=1 (Instrument) always has CopyType=0 (None) - direct investment, uses InstrumentID
- PlanType=2 (Copy) has CopyType=1 (PI) or CopyType=4 (SmartPortfolio) - copy investment, uses CopyParentCID/CopyParentGCID
- Gap in IDs (no 2 or 3) suggests deprecated or reserved copy types

**Diagram**:
```
PlanType=1 (Instrument) --> CopyType=0 (None)     --> Uses InstrumentID
PlanType=2 (Copy)       --> CopyType=1 (PI)        --> Uses CopyParentCID/GCID
                        --> CopyType=4 (SmartPortfolio) --> Uses CopyParentCID/GCID
```

---

## 3. Data Overview

| ID | Name | Meaning |
|----|------|---------|
| 0 | None | Plan is not a copy plan - it invests directly in a specific instrument identified by InstrumentID. This is the default for standard recurring investment plans. |
| 1 | PI | Plan copies a Popular Investor - allocates funds to mirror a specific trader's portfolio. The copied trader is identified by CopyParentCID/CopyParentGCID. |
| 4 | SmartPortfolio | Plan copies a SmartPortfolio - a curated thematic portfolio managed by eToro. The portfolio is identified by CopyParentCID/CopyParentGCID. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the copy type. 0=None (direct instrument), 1=PI (Popular Investor copy), 4=SmartPortfolio (managed portfolio copy). See [Copy Type](../../_glossary.md#copy-type). |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label for the copy trading relationship type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.Plans | CopyType | Implicit Lookup | Classifies the copy trading type of each recurring investment plan |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | CopyType column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CopyType | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all copy types
```sql
SELECT ID, Name
FROM [Dictionary].[CopyType] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count active plans by copy type
```sql
SELECT ct.ID, ct.Name, COUNT(*) AS PlanCount
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[CopyType] ct WITH (NOLOCK) ON p.CopyType = ct.ID
WHERE p.PlanStatusID = 1
GROUP BY ct.ID, ct.Name
ORDER BY ct.ID
```

### 8.3 Find copy plans with their parent details
```sql
SELECT p.ID AS PlanID, p.GCID, ct.Name AS CopyTypeName,
       p.CopyParentCID, p.CopyParentGCID
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[CopyType] ct WITH (NOLOCK) ON p.CopyType = ct.ID
WHERE p.CopyType > 0
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan is a recurring investment subscription for specific user for specific instrument ID, based on Recurring Deposit Plan |
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans table structure and CopyType column usage |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CopyType | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.CopyType.sql*

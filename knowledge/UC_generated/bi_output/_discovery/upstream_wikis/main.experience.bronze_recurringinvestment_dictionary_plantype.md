# Dictionary.PlanType

> Lookup table classifying the fundamental nature of a recurring investment plan - direct instrument investment or copy trading.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table classifies whether a recurring investment plan targets a specific financial instrument (stock, ETF, crypto) or copies another trader's portfolio. This is the highest-level classification of a plan and determines the entire execution path.

Without this table, the system could not distinguish between direct investment plans and copy trading plans, which follow fundamentally different execution flows involving different APIs, different data columns, and different business rules.

PlanType is set during plan creation and determines which columns in the Plans table are relevant. Instrument plans (1) use InstrumentID, while Copy plans (2) use CopyParentCID/CopyParentGCID and also require a CopyType (1=PI or 4=SmartPortfolio).

---

## 2. Business Logic

### 2.1 Plan Type Determines Execution Path

**What**: The two plan types follow different execution paths through the recurring investment pipeline.

**Columns/Parameters Involved**: `ID`, `Name`, `Plans.CopyType`, `Plans.InstrumentID`, `Plans.CopyParentCID`

**Rules**:
- Instrument (1): Direct investment in a specific instrument. Uses InstrumentID. CopyType=0 (None). Order goes to Trading API for the specific instrument.
- Copy (2): Copies another trader. Uses CopyParentCID/CopyParentGCID. CopyType=1 (PI) or 4 (SmartPortfolio). Triggers mirror order creation through the copy trading pipeline.

**Diagram**:
```
PlanType = 1 (Instrument)           PlanType = 2 (Copy)
    |                                   |
    v                                   v
InstrumentID --> Order to TAPI     CopyParentCID --> Mirror Order
    |                                   |
    v                                   v
Direct Position Open               Copy Position (Register + AddFunds)
```

---

## 3. Data Overview

| ID | Name | Meaning |
|----|------|---------|
| 1 | Instrument | Plan invests in a specific financial instrument (stock, ETF, crypto, etc.) on a recurring schedule. Each cycle deposits funds and places an order for the chosen instrument. |
| 2 | Copy | Plan copies another trader's portfolio (Popular Investor or SmartPortfolio) on a recurring schedule. Each cycle deposits funds and allocates them to mirror the parent trader's positions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the plan type. 1=Instrument (direct investment), 2=Copy (copy trading). See [Plan Type](../../_glossary.md#plan-type). |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label for the plan investment strategy type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.Plans | PlanType | Implicit Lookup | Classifies the fundamental investment strategy of each plan |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | PlanType column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PlanType | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all plan types
```sql
SELECT ID, Name
FROM [Dictionary].[PlanType] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count active plans by type
```sql
SELECT pt.ID, pt.Name, COUNT(*) AS PlanCount
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[PlanType] pt WITH (NOLOCK) ON p.PlanType = pt.ID
WHERE p.PlanStatusID = 1
GROUP BY pt.ID, pt.Name
```

### 8.3 Find copy plans with their copy details
```sql
SELECT p.ID AS PlanID, p.GCID, pt.Name AS PlanTypeName,
       ct.Name AS CopyTypeName, p.CopyParentCID, p.CopyParentGCID
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[PlanType] pt WITH (NOLOCK) ON p.PlanType = pt.ID
LEFT JOIN [Dictionary].[CopyType] ct WITH (NOLOCK) ON p.CopyType = ct.ID
WHERE p.PlanType = 2
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan is a recurring investment subscription for a specific user and specific instrument ID; copy plans mirror parent traders |
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans table structure showing PlanType and related copy trading columns |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlanType | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.PlanType.sql*

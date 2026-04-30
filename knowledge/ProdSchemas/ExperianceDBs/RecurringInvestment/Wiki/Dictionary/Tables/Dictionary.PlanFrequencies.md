# Dictionary.PlanFrequencies

> Lookup table defining frequency/cadence options for recurring investment plan execution cycles.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table defines how often a recurring investment plan executes - the interval between deposit and order cycles. It determines the cadence at which the system creates new plan instances, triggers deposits, and places orders for the user's chosen instruments.

Without this table, the system could not support different execution frequencies. However, currently only Monthly (ID=3) is active for Recurring Investment Plans. Weekly and BiWeekly options exist in the system but are disabled for this feature.

The FrequencyID is set when a plan is created and determines the Plan Instances Job's behavior - specifically, when to create the next instance record and calculate the NextOrderDate. The RepeatsOn column in the Plans table specifies which day of the month (for Monthly) the plan executes.

---

## 2. Business Logic

### 2.1 Frequency-Based Instance Scheduling

**What**: The frequency determines when new plan instances are created and when deposits/orders occur.

**Columns/Parameters Involved**: `ID`, `FrequencyName`, `Plans.RepeatsOn`

**Rules**:
- Monthly (3) + RepeatsOn = day of month: Instance created for the specified day each month
- Weekly (1) and BiWeekly (2) exist in the system but are NOT in use for Recurring Investment Plans (per Confluence)
- The Plan Instances Job runs daily and creates new instance records for active plans whose next execution date has arrived

---

## 3. Data Overview

DB table is currently empty (0 rows). Confluence documents the canonical values:

| ID | FrequencyName | Meaning |
|----|---------------|---------|
| 1 | Weekly | Plan executes weekly. NOT currently in use for Recurring Investment Plans - exists in the broader system but disabled for this feature. |
| 2 | BiWeekly | Plan executes every two weeks. NOT currently in use for Recurring Investment Plans. |
| 3 | Monthly | Plan executes every month on a specific day chosen by the user (stored in Plans.RepeatsOn). This is the ONLY frequency currently active for Recurring Investment Plans. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the frequency. Per Confluence: 1=Weekly (inactive), 2=BiWeekly (inactive), 3=Monthly (active). See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 2 | FrequencyName | varchar(50) | NO | - | VERIFIED | Human-readable label for the execution frequency cadence. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.Plans | FrequencyID | Implicit Lookup | Determines the execution cadence of the recurring investment plan |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | FrequencyID column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PlanFrequency | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all frequencies
```sql
SELECT ID, FrequencyName
FROM [Dictionary].[PlanFrequencies] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count active plans by frequency
```sql
SELECT p.FrequencyID, pf.FrequencyName, COUNT(*) AS PlanCount
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
LEFT JOIN [Dictionary].[PlanFrequencies] pf WITH (NOLOCK) ON p.FrequencyID = pf.ID
WHERE p.PlanStatusID = 1
GROUP BY p.FrequencyID, pf.FrequencyName
```

### 8.3 Find active plans with their frequency and execution day
```sql
SELECT p.ID AS PlanID, p.GCID, p.FrequencyID, pf.FrequencyName, p.RepeatsOn
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
LEFT JOIN [Dictionary].[PlanFrequencies] pf WITH (NOLOCK) ON p.FrequencyID = pf.ID
WHERE p.PlanStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | FrequencyID values (1=Weekly, 2=BiWeekly, 3=Monthly); only Monthly is active; RepeatsOn is the execution day |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan Instances Job creates new records based on frequency and next trade date |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlanFrequencies | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.PlanFrequencies.sql*

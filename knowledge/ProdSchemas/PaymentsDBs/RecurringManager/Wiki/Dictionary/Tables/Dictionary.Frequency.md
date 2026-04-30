# Dictionary.Frequency

> Lookup table defining the three supported recurring payment cadences: Weekly, BiWeekly, and Monthly.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FrequencyID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Frequency defines the interval between successive scheduled execution dates for a recurring payment plan. When a user creates a recurring deposit or recurring investment plan, they select one of three frequencies that determines how often the system will attempt to charge their payment method.

This table drives the scheduler's date calculation engine. After each execution completes (or is due), the scheduler uses the plan's FrequencyID to compute the next PlannedDate. The frequency also affects the user experience - more frequent plans (Weekly) result in smaller per-charge amounts for the same total, while Monthly plans match typical payroll cycles.

The three frequencies - Weekly, BiWeekly, and Monthly - represent the only cadences supported by the RecurringManager system. No daily, quarterly, or annual options exist.

---

## 2. Business Logic

### 2.1 Frequency-Driven Scheduling

**What**: The plan's frequency determines the interval between successive execution dates, driving the entire scheduling calendar.

**Columns/Parameters Involved**: `FrequencyID`, `Name`

**Rules**:
- Weekly (1): Execution every 7 days from the plan's start date
- BiWeekly (2): Execution every 14 days from the plan's start date
- Monthly (3): Execution once per calendar month on the same day-of-month as the plan's start date
- Monthly is likely the most common frequency, aligning with payroll deposit cycles
- Per Confluence HLD, Recurring Deposit Plans are described as "monthly plan managed by Money Group"

**Diagram**:
```
Plan Start Date: Jan 1
  |
  +-- Weekly (1):    Jan 1, Jan 8, Jan 15, Jan 22, Jan 29, Feb 5, ...
  +-- BiWeekly (2):  Jan 1, Jan 15, Jan 29, Feb 12, Feb 26, ...
  +-- Monthly (3):   Jan 1, Feb 1, Mar 1, Apr 1, May 1, ...
```

---

## 3. Data Overview

| FrequencyID | Name | Meaning |
|---|---|---|
| 1 | Weekly | Plan executes once every 7 days. Highest charge frequency available - results in 52 executions per year. |
| 2 | BiWeekly | Plan executes once every 14 days. Matches biweekly payroll schedules - results in 26 executions per year. |
| 3 | Monthly | Plan executes once per calendar month. Most common cadence, aligns with monthly payroll. Results in 12 executions per year. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FrequencyID | int | NO | - | CODE-BACKED | Primary key identifying the frequency. 1=Weekly, 2=BiWeekly, 3=Monthly. Drives the scheduler's next-execution-date calculation. See [Frequency](../../_glossary.md#frequency) for full definitions. (Dictionary.Frequency) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the frequency. Values: "Weekly", "BiWeekly", "Monthly". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Recurring plan tables) | FrequencyID | Implicit FK | Plan records store the user's selected charge frequency |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No explicit dependents found in SSDT. Consumed by plan creation logic and the scheduler's date calculation engine.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_Frequency | CLUSTERED PK | FrequencyID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_Frequency | PRIMARY KEY | Ensures each frequency has a unique integer identifier |

---

## 8. Sample Queries

### 8.1 List all frequencies
```sql
SELECT FrequencyID, Name
FROM Dictionary.Frequency WITH (NOLOCK)
ORDER BY FrequencyID
```

### 8.2 Calculate approximate annual executions per frequency
```sql
SELECT FrequencyID, Name,
    CASE FrequencyID
        WHEN 1 THEN 52  -- Weekly
        WHEN 2 THEN 26  -- BiWeekly
        WHEN 3 THEN 12  -- Monthly
    END AS ApproxAnnualExecutions
FROM Dictionary.Frequency WITH (NOLOCK)
```

### 8.3 Join with plan data to see frequency distribution
```sql
SELECT f.Name AS Frequency, COUNT(*) AS PlanCount
FROM Recurring.Payment p WITH (NOLOCK)
INNER JOIN Dictionary.Frequency f WITH (NOLOCK) ON p.FrequencyID = f.FrequencyID
GROUP BY f.Name
ORDER BY PlanCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Business context: Recurring Deposit Plans are described as "monthly plan managed by Money Group"; Recurring Investment Plans are triggered by actual deposits |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Frequency | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.Frequency.sql*

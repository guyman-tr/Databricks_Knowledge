# Dictionary.ABTest

> Lookup table defining A/B test experiments, mapping experiment IDs to human-readable test names for controlled feature rollouts and UX experimentation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ExperimentID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ABTest is a registry of A/B test experiments used across the eToro platform. Each row represents a named experiment that splits users into test groups to measure the impact of different feature variants (e.g., deposit page layouts, onboarding flows, UI changes).

Without this table, experiment configurations would rely on hardcoded strings or external systems, making it difficult to track which experiments exist in the database layer and correlate experiment results with transactional data.

The table uses an IDENTITY column, so new experiments are added by INSERT with auto-generated IDs. Currently contains a single experiment ("DepositPreset"), suggesting most A/B testing is managed outside the database or this table is used selectively for experiments that need database-level tracking. Data compression (PAGE) is enabled despite the small size, likely as a schema-wide default for the DICTIONARY filegroup.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is a simple ID-to-Name lookup with a single experiment defined.

---

## 3. Data Overview

| ExperimentID | Name | Meaning |
|---|---|---|
| 1 | DepositPreset | Controls which preset deposit amounts are shown to users on the deposit page. Different user groups see different suggested amounts to optimize conversion rates and average deposit sizes. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExperimentID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key identifying each A/B test experiment. Referenced by experiment assignment tables to link users to specific test variants. |
| 2 | Name | varchar(100) | NO | - | CODE-BACKED | Human-readable experiment name. Describes what feature or flow is being tested. Current value: 'DepositPreset' — controls deposit amount presets shown to users. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No FK references found in the SSDT project pointing to this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ABTest | CLUSTERED PK | ExperimentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_ABTest | PRIMARY KEY | Unique experiment identifier on DICTIONARY filegroup, PAGE compression |

---

## 8. Sample Queries

### 8.1 List all experiments
```sql
SELECT  ExperimentID,
        Name
FROM    Dictionary.ABTest WITH (NOLOCK)
ORDER BY ExperimentID;
```

### 8.2 Find experiment by name
```sql
SELECT  ExperimentID
FROM    Dictionary.ABTest WITH (NOLOCK)
WHERE   Name = 'DepositPreset';
```

### 8.3 Check for recently added experiments
```sql
SELECT  ExperimentID,
        Name
FROM    Dictionary.ABTest WITH (NOLOCK)
WHERE   ExperimentID > 0
ORDER BY ExperimentID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ABTest | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ABTest.sql*

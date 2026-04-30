# dbo.FiatAccountsProperties

> Event-sourced property history table tracking changes to an account's program and sub-program assignment over time.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

FiatAccountsProperties records every change to an account's program assignment. Each row captures a snapshot of the AccountProgramId and SubProgramId at a point in time. When a customer's sub-program changes (upgrade, downgrade, or migration), a new row is created here, preserving the full history of program transitions.

This table exists because customers may transition between sub-programs over their lifecycle (e.g., Standard -> Premium upgrade, or Card -> IBAN migration). Tracking these changes is essential for understanding customer journeys, calculating time-in-program metrics, and auditing program transition correctness.

Data is created by dbo.AddAccountsProperties when the operational system reports a program assignment change.

---

## 2. Business Logic

### 2.1 Program Assignment History

**What**: Chronological record of every program/sub-program change for each account.

**Columns/Parameters Involved**: `AccountId`, `AccountProgramId`, `SubProgramId`, `Created`

**Rules**:
- The latest record (by Created) for an AccountId represents the current program assignment
- AccountProgramId and SubProgramId on FiatAccount may differ from this table's latest if there's a sync delay
- Used in conjunction with ProgramTransitionsEligibility to verify transitions happened correctly

---

## 3. Data Overview

| Id | AccountId | AccountProgramId | SubProgramId | Created | Meaning |
|---|---|---|---|---|---|
| 2213579 | 2135575 | 2 | 6 | 2026-04-14 13:51 | Account assigned to IBAN EU Green (sub-program 6) |
| 2213578 | 2135574 | 2 | 4 | 2026-04-14 13:51 | Account assigned to IBAN Standard UK (sub-program 4) |
| 2213577 | 2135573 | 2 | 6 | 2026-04-14 13:50 | Account assigned to IBAN EU Green (sub-program 6) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The account whose program assignment changed. |
| 3 | AccountProgramId | tinyint | NO | - | CODE-BACKED | Account program type at this point: 0=Unknown, 1=card, 2=iban. See [Account Program](../../_glossary.md#account-program). |
| 4 | SubProgramId | tinyint | NO | - | CODE-BACKED | Specific sub-program at this point: 1-16. See [Sub-Program](../../_glossary.md#sub-program). FK to dbo.SubPrograms. |
| 5 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this program assignment was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountId | dbo.FiatAccount | FK | The account whose program changed |
| AccountProgramId | Dictionary.AccountPrograms | Implicit | Program type at this point |
| SubProgramId | dbo.SubPrograms | Implicit | Sub-program at this point |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddAccountsProperties | INSERT | Writer | Records program assignment changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatAccountsProperties (table)
└── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | FK from AccountId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddAccountsProperties | Stored Procedure | Writes property records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatAccountsProperties | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FiatAccountsProperties_Accounts | FK | AccountId -> dbo.FiatAccount.Id |

---

## 8. Sample Queries

### 8.1 Get program history for an account
```sql
SELECT p.AccountProgramId, ap.Name AS Program, p.SubProgramId, sp.Name AS SubProgram, p.Created
FROM dbo.FiatAccountsProperties p WITH (NOLOCK)
JOIN Dictionary.AccountPrograms ap WITH (NOLOCK) ON ap.Id = p.AccountProgramId
JOIN dbo.SubPrograms sp WITH (NOLOCK) ON sp.Id = p.SubProgramId
WHERE p.AccountId = 2135575 ORDER BY p.Created;
```

### 8.2 Find accounts that changed sub-programs recently
```sql
SELECT p.AccountId, a.Gcid, p.SubProgramId, sp.Name, p.Created
FROM dbo.FiatAccountsProperties p WITH (NOLOCK)
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = p.AccountId
JOIN dbo.SubPrograms sp WITH (NOLOCK) ON sp.Id = p.SubProgramId
WHERE p.Created >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY p.Created DESC;
```

### 8.3 Count current accounts per sub-program (latest assignment)
```sql
;WITH LatestProp AS (
    SELECT AccountId, SubProgramId,
           ROW_NUMBER() OVER (PARTITION BY AccountId ORDER BY Created DESC) AS rn
    FROM dbo.FiatAccountsProperties WITH (NOLOCK)
)
SELECT sp.Name, COUNT(*) AS AccountCount
FROM LatestProp lp
JOIN dbo.SubPrograms sp WITH (NOLOCK) ON sp.Id = lp.SubProgramId
WHERE lp.rn = 1
GROUP BY sp.Name ORDER BY AccountCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatAccountsProperties | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatAccountsProperties.sql*

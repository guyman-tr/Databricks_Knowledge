# RecurringInvestment.BlacklistInstrumentIDsGetAll

> Retrieves all globally blacklisted instrument IDs for the eligibility cache. Created per EDGE-3688.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all instrument IDs from the BlackListInstrumentID table. These instruments are globally blocked from recurring investment plans regardless of the user's country. The application uses this to populate the eligibility cache.

Created 06/08/2024 by Nilly Ron per EDGE-3688. Called by the recurring investment backend service during startup or cache refresh. Currently returns 54 blacklisted instruments.

---

## 2. Business Logic

No complex business logic. Simple full-table read with NOLOCK for cache population.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID (return) | int | NO | - | CODE-BACKED | ID of an instrument globally blocked from recurring investment plans. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.BlackListInstrumentID | Read | Reads all rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.BlacklistInstrumentIDsGetAll (procedure)
└── RecurringInvestment.BlackListInstrumentID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListInstrumentID | Table | SELECT FROM with NOLOCK |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC [RecurringInvestment].[BlacklistInstrumentIDsGetAll]
```

### 8.2 Check if an instrument is blacklisted
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListInstrumentID] WITH (NOLOCK) WHERE InstrumentID = @InstrumentID) THEN 1 ELSE 0 END AS IsBlacklisted
```

### 8.3 Count blacklisted instruments
```sql
SELECT COUNT(*) AS BlacklistedInstruments FROM [RecurringInvestment].[BlackListInstrumentID] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists used for eligibility; code comment references EDGE-3688 |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlacklistInstrumentIDsGetAll | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.BlacklistInstrumentIDsGetAll.sql*

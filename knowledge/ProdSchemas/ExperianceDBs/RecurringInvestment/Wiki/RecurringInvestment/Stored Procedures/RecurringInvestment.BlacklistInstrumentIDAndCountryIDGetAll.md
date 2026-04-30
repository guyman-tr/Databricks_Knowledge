# RecurringInvestment.BlacklistInstrumentIDAndCountryIDGetAll

> Retrieves all blacklisted instrument + country combinations for the eligibility cache. Created per EDGE-3688.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + CountryID pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all instrument + country combination entries from the BlackListInstrumentIDCountryID table. An instrument may be available for recurring investment in most countries but blocked in certain jurisdictions. The application uses this to populate the eligibility cache.

Created 03/06/2024 by Nilly Ron per EDGE-3688. Returns 8,127 entries - the largest blacklist in the system, reflecting extensive per-country instrument restrictions.

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
| 1 | InstrumentID (return) | int | NO | - | CODE-BACKED | ID of an instrument restricted for the specified country. |
| 2 | CountryID (return) | int | NO | - | CODE-BACKED | Country ID. Users from this country cannot create recurring investment plans for this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.BlackListInstrumentIDCountryID | Read | Reads all rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.BlacklistInstrumentIDAndCountryIDGetAll (procedure)
└── RecurringInvestment.BlackListInstrumentIDCountryID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListInstrumentIDCountryID | Table | SELECT FROM with NOLOCK |

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
EXEC [RecurringInvestment].[BlacklistInstrumentIDAndCountryIDGetAll]
```

### 8.2 Find blocked instruments for a country
```sql
SELECT InstrumentID FROM [RecurringInvestment].[BlackListInstrumentIDCountryID] WITH (NOLOCK) WHERE CountryID = @CountryID
```

### 8.3 Count restrictions per country
```sql
SELECT CountryID, COUNT(*) AS BlockedInstruments FROM [RecurringInvestment].[BlackListInstrumentIDCountryID] WITH (NOLOCK) GROUP BY CountryID ORDER BY BlockedInstruments DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklist of instrument IDs per country; code comment references EDGE-3688 |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlacklistInstrumentIDAndCountryIDGetAll | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.BlacklistInstrumentIDAndCountryIDGetAll.sql*

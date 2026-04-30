# RecurringInvestment.BlackListInstrumentID

> Blacklist table globally blocking specific instruments from all recurring investment plans.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + IX_BlackListInstrumentID_InstrumentID) |

---

## 1. Business Meaning

This table maintains a global blacklist of specific instruments that cannot be used in any recurring investment plan. When a user attempts to create an Instrument-type plan (PlanType=1) for a blacklisted instrument, the eligibility check blocks the operation. This applies regardless of the user's country.

Without this table, the system could not block specific instruments from recurring investment - for example, instruments that are being delisted, are under regulatory scrutiny, or have been deemed unsuitable for automated recurring purchases.

System-versioned with history in History.RecurringInvestmentBlackListInstrumentID. Currently contains 54 blacklisted instruments. The blacklist is loaded by BlacklistInstrumentIDsGetAll for the eligibility cache. Triggers PlanEventCode 902 (InstrumentIdNotCompatible) when matched.

---

## 2. Business Logic

No complex multi-column business logic. Single-column blacklist: if an InstrumentID is present, no user can create a recurring investment plan for that instrument.

---

## 3. Data Overview

| InstrumentID | Meaning |
|--------------|---------|
| 1437 | This instrument is globally blocked from recurring investment plans. Users cannot create PlanType=1 plans targeting this instrument. |
| 2192 | Blocked instrument. May be delisted, under review, or incompatible with recurring investment execution. |
| 3027 | Blocked instrument. Part of the 54 instruments currently on the global blacklist. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | ID of the instrument that is blocked from recurring investment plans globally. References the external instrument system. Matches Plans.InstrumentID. |
| 2 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with connection details. |
| 3 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. When the instrument was blacklisted. |
| 4 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end. 9999-12-31 for currently blacklisted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. InstrumentID references the external instrument system.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.BlacklistInstrumentIDsGetAll | - | Reader | Reads all blacklisted instrument IDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlacklistInstrumentIDsGetAll | Stored Procedure | Reads all entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlackListInstrumentID | NONCLUSTERED PK | InstrumentID | - | - | Active |
| IX_BlackListInstrumentID_InstrumentID | NONCLUSTERED | InstrumentID | - | - | Active |

### 7.2 Constraints

None.

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentBlackListInstrumentID`.

---

## 8. Sample Queries

### 8.1 List all blacklisted instruments
```sql
SELECT InstrumentID FROM [RecurringInvestment].[BlackListInstrumentID] WITH (NOLOCK) ORDER BY InstrumentID
```

### 8.2 Check if an instrument is blacklisted
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListInstrumentID] WITH (NOLOCK) WHERE InstrumentID = @InstrumentID) THEN 1 ELSE 0 END AS IsBlacklisted
```

### 8.3 Find active plans for blacklisted instruments (data quality check)
```sql
SELECT p.ID, p.GCID, p.InstrumentID, p.PlanStatusID
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [RecurringInvestment].[BlackListInstrumentID] bl WITH (NOLOCK) ON p.InstrumentID = bl.InstrumentID
WHERE p.PlanStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists are used for eligibility configuration; PlanEventCode 902 = InstrumentIdNotCompatible |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlackListInstrumentID | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.BlackListInstrumentID.sql*

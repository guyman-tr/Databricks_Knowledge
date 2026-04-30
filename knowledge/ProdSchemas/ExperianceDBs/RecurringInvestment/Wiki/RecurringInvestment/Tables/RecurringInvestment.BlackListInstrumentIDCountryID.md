# RecurringInvestment.BlackListInstrumentIDCountryID

> Blacklist table restricting specific instruments for users in specific countries from recurring investment plans.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID + CountryID (NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + IX_BlackListInstrumentIDCountryID_InstrumentID_CountryID) |

---

## 1. Business Meaning

This table maintains a blacklist of specific instrument + country combinations. An instrument may be available for recurring investment in most countries but blocked in certain jurisdictions. This enables fine-grained regulatory compliance at the instrument + country level.

Without this table, instrument restrictions would be all-or-nothing (via BlackListInstrumentID). This table allows selective blocking - for example, a crypto instrument blocked in a specific country but available elsewhere.

System-versioned with history in History.RecurringInvestmentBlackListInstrumentIDCountryID. The largest blacklist table with 8,127 entries, reflecting extensive per-country instrument restrictions. Triggers PlanEventCode 900 (CountryAndInstrumentIdNotCompatible).

---

## 2. Business Logic

### 2.1 Instrument-Country Eligibility Matrix

**What**: Per-country restriction of specific instruments for recurring investment.

**Columns/Parameters Involved**: `InstrumentID`, `CountryID`, `UpdateDate`

**Rules**:
- If InstrumentID + CountryID pair exists, that instrument is blocked for users in that country
- Checked in addition to global BlackListInstrumentID
- UpdateDate tracks when the restriction was last modified (useful for compliance audit)

---

## 3. Data Overview

| InstrumentID | CountryID | UpdateDate | Meaning |
|--------------|-----------|------------|---------|
| 9031 | 188 | 2024-09-03 | Instrument 9031 is blocked for recurring investment by users in country 188. Part of a batch update affecting multiple instruments for this country. |
| 9046 | 188 | 2024-09-03 | Another instrument blocked for the same country in the same batch. Suggests a regulatory change in country 188 affecting multiple instruments simultaneously. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | ID of the instrument that is restricted. References external instrument system. |
| 2 | CountryID | int | NO | - | VERIFIED | Country ID of the user. Users from this country cannot create recurring investment plans for this instrument. |
| 3 | UpdateDate | datetime | NO | GETUTCDATE() | VERIFIED | When this restriction was last added or modified. Used for compliance audit trails. |
| 4 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with connection details. |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.BlacklistInstrumentIDAndCountryIDGetAll | - | Reader | Reads all entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlacklistInstrumentIDAndCountryIDGetAll | Stored Procedure | Reads all entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlackListInstrumentIDCountryID | NONCLUSTERED PK | InstrumentID, CountryID | - | - | Active |
| IX_BlackListInstrumentIDCountryID_InstrumentID_CountryID | NONCLUSTERED | InstrumentID, CountryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BlackListInstrumentIDCountryID_UpdateDate | DEFAULT | GETUTCDATE() - auto-timestamps when restriction is created |

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentBlackListInstrumentIDCountryID`.

---

## 8. Sample Queries

### 8.1 List all instrument+country restrictions
```sql
SELECT InstrumentID, CountryID, UpdateDate FROM [RecurringInvestment].[BlackListInstrumentIDCountryID] WITH (NOLOCK) ORDER BY InstrumentID, CountryID
```

### 8.2 Find all blocked instruments for a country
```sql
SELECT InstrumentID, UpdateDate FROM [RecurringInvestment].[BlackListInstrumentIDCountryID] WITH (NOLOCK) WHERE CountryID = @CountryID ORDER BY InstrumentID
```

### 8.3 Count restrictions per country
```sql
SELECT CountryID, COUNT(*) AS BlockedInstruments FROM [RecurringInvestment].[BlackListInstrumentIDCountryID] WITH (NOLOCK) GROUP BY CountryID ORDER BY BlockedInstruments DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklist of instrument IDs per country; PlanEventCode 900 = CountryAndInstrumentIdNotCompatible |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlackListInstrumentIDCountryID | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.BlackListInstrumentIDCountryID.sql*

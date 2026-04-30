# Trade.UsAllowedInstruments

> Regulatory compliance whitelist of instruments approved for trading by users in specific countries, primarily United States. US securities regulations restrict which instruments can be offered to US-based customers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID + CountryID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

Trade.UsAllowedInstruments is a regulatory compliance whitelist that defines which financial instruments are approved for trading by users in specific countries. The table name reflects its primary use case: US securities regulations restrict which instruments (stocks, ETFs, forex pairs, crypto, etc.) can be offered to US-based customers. Only instruments listed here for the user's country are available for trading. The same instrument can appear in multiple countries (e.g., a popular stock approved for both US and UK users).

This table exists because eToro operates across many jurisdictions with different regulatory requirements. Without it, the platform could not enforce country-specific instrument availability. Compliance and trading operations consult this whitelist before allowing a user to open a position. System versioning tracks all additions and removals with a full audit trail via History.UsAllowedInstruments.

Data flows: Compliance or trading operations INSERT new rows when instruments receive regulatory approval for a country. Rows are REMOVED (or end-dated via temporal versioning) when approval is revoked. Trade.GetUsRegulationIds, Trade.vGetUsRegulationIds, and Trade.PositionsIsUS read this table to determine whether a given instrument is tradeable for a user based on their country. The Created timestamp records when the approval was granted.

---

## 2. Business Logic

### 2.1 Country-Instrument Whitelist

**What**: A row means "instrument X is approved for users in country Y."

**Columns/Parameters Involved**: `InstrumentID`, `CountryID`, `Created`

**Rules**:
- Composite PK (InstrumentID, CountryID) ensures each instrument-country pair appears at most once
- CountryID=219 = United States (primary use case; table name reflects this)
- Created records when the approval was granted; temporal SysStartTime/SysEndTime track full change history
- If a row does not exist for (InstrumentID, CountryID), the instrument is NOT tradeable for users in that country

**Diagram**:
```
[Instrument X] + [Country 219 (US)] -> Tradeable for US users
[Instrument X] + [Country 826 (UK)] -> Tradeable for UK users (if row exists)
[Instrument Y] + [Country 219] -> No row -> NOT tradeable for US users
```

### 2.2 Audit Trail via System Versioning

**What**: All changes are tracked for regulatory audit purposes.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- System versioning copies all old versions to History.UsAllowedInstruments
- DbLoginName (suser_name()) and AppLoginName (context_info()) capture who made each change
- Regulatory audits can query History.UsAllowedInstruments for full change history

---

## 3. Data Overview

| InstrumentID | CountryID | Created | Meaning |
|--------------|-----------|---------|---------|
| 100000 | 219 | 2019-06-30 | Instrument 100000 approved for US (CountryID=219). Created date indicates when approval was granted. |
| 100001 | 219 | 2019-06-30 | Another instrument approved for US users on the same date. |
| (sample) | 826 | (varies) | Same instrument can be approved for multiple countries (e.g., UK=826). |

**Selection criteria**: Representative rows showing US approvals (CountryID=219) and illustrating that Created tracks approval date. Table may contain multiple countries per instrument.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The instrument approved for trading. Part of composite PK. |
| 2 | Created | datetime | NO | - | CODE-BACKED | When this instrument-country approval was granted. Set at INSERT time. |
| 3 | CountryID | int | NO | - | CODE-BACKED | FK to Dictionary.Country. The country whose users may trade this instrument. 219 = United States. Part of composite PK. |
| 4 | DbLoginName | (computed) | NO | - | VERIFIED | Computed: suser_name(). SQL Server login that performed the change. Audit trail. |
| 5 | AppLoginName | (computed) | NO | - | VERIFIED | Computed: CONVERT(varchar(500), context_info()). Application context for audit. Identifies which service made the change. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System versioning row start. Set automatically on INSERT/UPDATE. Part of PERIOD FOR SYSTEM_TIME. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System versioning row end. 9999-12-31 for current rows. Set to modification time in History when row is updated/deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup | The tradeable instrument being whitelisted. |
| CountryID | Dictionary.Country | Lookup | Country whose residents may trade the instrument. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUsRegulationIds | FROM | Reader | Retrieves instrument IDs approved for US regulation. |
| Trade.vGetUsRegulationIds | FROM | Reader | View wrapping US regulation instrument lookup. |
| Trade.PositionsIsUS | FROM | Reader | Checks if positions involve US-regulated instruments. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UsAllowedInstruments (table)
```

Tables are leaf nodes. No code-level dependencies in CREATE TABLE. Lookups to Trade.Instrument and Dictionary.Country are structural.

### 6.1 Objects This Depends On

No explicit FK in DDL. Implicit: Trade.Instrument (InstrumentID), Dictionary.Country (CountryID). History.UsAllowedInstruments is the system-versioned history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUsRegulationIds | Procedure | SELECT to get US-approved instrument list |
| Trade.vGetUsRegulationIds | View | SELECT from this table |
| Trade.PositionsIsUS | Procedure | JOIN/EXISTS to check US regulation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (clustered) | CLUSTERED | InstrumentID, CountryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PK | (InstrumentID, CountryID) - composite, clustered |
| PERIOD FOR SYSTEM_TIME | Temporal | SysStartTime, SysEndTime - enables system versioning |
| HISTORY_TABLE | Temporal | History.UsAllowedInstruments |

---

## 8. Sample Queries

### 8.1 Get all instruments approved for US trading
```sql
SELECT uai.InstrumentID, uai.CountryID, uai.Created
FROM   Trade.UsAllowedInstruments uai WITH (NOLOCK)
WHERE  uai.CountryID = 219
ORDER BY uai.InstrumentID;
```

### 8.2 Check if an instrument is allowed for a specific country
```sql
SELECT uai.InstrumentID, uai.CountryID, uai.Created
FROM   Trade.UsAllowedInstruments uai WITH (NOLOCK)
WHERE  uai.InstrumentID = 100000
       AND uai.CountryID = 219;
```

### 8.3 Resolve instrument IDs to names for US-approved instruments
```sql
SELECT uai.InstrumentID, uai.CountryID, uai.Created,
       dc.Abbreviation AS CountryCode
FROM   Trade.UsAllowedInstruments uai WITH (NOLOCK)
       INNER JOIN Dictionary.Country dc WITH (NOLOCK) ON uai.CountryID = dc.CountryID
WHERE  uai.CountryID = 219
ORDER BY uai.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UsAllowedInstruments | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.UsAllowedInstruments.sql*

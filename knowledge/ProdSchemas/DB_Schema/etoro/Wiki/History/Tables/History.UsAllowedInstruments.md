# History.UsAllowedInstruments

> SQL Server system-versioned temporal history table for Trade.UsAllowedInstruments - stores superseded records of instruments permitted for trading in specific US jurisdictions (country-level), enabling point-in-time auditing of US regulatory instrument availability.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No - stored on [PRIMARY] with PAGE compression |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.UsAllowedInstruments is the temporal history backing table for Trade.UsAllowedInstruments, which is a regulatory allowlist defining which instruments are permitted for trading in specific US jurisdictions. eToro's US operations are subject to state-by-state and federal regulatory constraints that determine which financial instruments customers in a given US country/state can access.

When an instrument is added to or removed from the allowed list for a US jurisdiction - due to regulatory approval, revocation, or policy changes - SQL Server system-versioning archives the old row here. The history enables regulatory compliance teams to demonstrate exactly which instruments were permitted for which jurisdictions at any given point in time.

The source table uses a composite PK on (InstrumentID, CountryID), so each (instrument, jurisdiction) pair has its own temporal history.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Changes to US instrument allowlist entries produce history rows capturing when each permission was active.

**Columns/Parameters Involved**: `InstrumentID`, `CountryID`, `Created`, `SysStartTime`, `SysEndTime`

**Rules**:
- SysStartTime = when this allowlist entry became active in Trade.UsAllowedInstruments
- SysEndTime = when it was superseded
- Created column in source = the original business date when the instrument was first added to the allowlist
- A removal of an instrument from the allowlist creates a history row (SysEndTime = removal time)
- DbLoginName and AppLoginName capture who made the regulatory change

---

## 3. Data Overview

Table is typically empty in non-production environments. Production accumulates rows when US instrument permissions change.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | The instrument that was permitted (or had its permission changed) for US trading. Part of the composite PK (InstrumentID, CountryID) in the source table. |
| 2 | Created | DATETIME | NO | - | CODE-BACKED | Business timestamp when this instrument/country allowlist entry was originally created (defaults to GETUTCDATE() in source). Preserved from the source row - represents when permission was first granted, not when this history row was written. |
| 3 | CountryID | INT | NO | - | CODE-BACKED | US jurisdiction identifier (country or state code). Part of the composite PK. Identifies which US jurisdiction's permission changed. References Dictionary-level country data. |
| 4 | DbLoginName | NVARCHAR(128) | YES | NULL | CODE-BACKED | SQL Server login that made the allowlist change (suser_name() at DML time). Preserved for regulatory audit attribution. |
| 5 | AppLoginName | VARCHAR(500) | YES | NULL | CODE-BACKED | Application login from context_info() at DML time. Identifies which admin tool or service made the regulatory change. |
| 6 | SysStartTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this allowlist entry version became active. SQL Server system-versioning managed. |
| 7 | SysEndTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this entry was superseded (updated or removed). Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Temporal (inherited) | Historical snapshot of which instrument had its US permission changed. |
| CountryID | Dictionary.Country (implied) | Temporal (inherited) | US jurisdiction whose instrument permission changed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UsAllowedInstruments | SYSTEM_VERSIONING | Temporal parent | Writes superseded allowlist entries here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.UsAllowedInstruments (table)
  (leaf - temporal history table)
```

### 6.1 Objects This Depends On

No hard DDL dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UsAllowedInstruments | Table | Temporal parent - writes superseded entries automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UsAllowedInstruments | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, or CHECK constraints.

---

## 8. Sample Queries

### 8.1 View current US instrument allowlist
```sql
SELECT u.InstrumentID, u.CountryID, u.Created, u.SysStartTime
FROM Trade.UsAllowedInstruments u WITH (NOLOCK)
ORDER BY u.CountryID, u.InstrumentID;
```

### 8.2 View allowlist as it was at a specific date
```sql
SELECT u.InstrumentID, u.CountryID, u.Created, u.SysStartTime, u.SysEndTime
FROM Trade.UsAllowedInstruments
FOR SYSTEM_TIME AS OF '2023-01-01T00:00:00'
ORDER BY u.CountryID, u.InstrumentID;
```

### 8.3 Audit when an instrument's US permission was revoked
```sql
SELECT h.InstrumentID, h.CountryID, h.SysStartTime AS RevokedAt, h.DbLoginName, h.AppLoginName
FROM History.UsAllowedInstruments h WITH (NOLOCK)
WHERE h.InstrumentID = 7
ORDER BY h.SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal - SQL Server managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UsAllowedInstruments | Type: Table | Source: etoro/etoro/History/Tables/History.UsAllowedInstruments.sql*

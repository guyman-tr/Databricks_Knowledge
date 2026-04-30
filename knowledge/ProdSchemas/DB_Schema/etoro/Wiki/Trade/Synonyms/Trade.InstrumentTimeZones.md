# Trade.InstrumentTimeZones

> Synonym pointing to the InstrumentTimeZones table in the CalendarDB database (CalendarAzure linked server), providing time zone mappings for instruments used in market schedule calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [CalendarAzure].[CalendarDB].[Market].[InstrumentTimeZones] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentTimeZones provides local access to the InstrumentTimeZones table in the CalendarDB database. This table maps each financial instrument to its relevant time zone, which is essential for correctly interpreting market open/close times, converting between local exchange times and UTC, and determining when trading is available.

Time zone awareness is critical because eToro operates globally with instruments from exchanges across multiple time zones. The CalendarDB system centralizes all market schedule and time zone data, and this synonym allows the Trade schema to reference it seamlessly.

No direct consumers found in the SSDT codebase - likely used by the GetMarketTimes function chain or external calendar services.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 3.

---

## 3. Data Overview

N/A for synonym.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [CalendarAzure].[CalendarDB].[Market].[InstrumentTimeZones]. Maps instruments to their trading time zones. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [CalendarAzure].[CalendarDB].[Market].[InstrumentTimeZones] | Synonym target | Cross-database reference to CalendarDB time zone mappings |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely consumed by market schedule functions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentTimeZones (synonym)
  +-- [CalendarAzure].[CalendarDB].[Market].[InstrumentTimeZones] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [CalendarAzure].[CalendarDB].[Market].[InstrumentTimeZones] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query instrument time zones
```sql
SELECT TOP 10 * FROM Trade.InstrumentTimeZones WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'InstrumentTimeZones' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check connectivity
```sql
SELECT TOP 1 1 AS IsReachable FROM Trade.InstrumentTimeZones WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentTimeZones | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.InstrumentTimeZones.sql*

# Dictionary.TimeZones

> Reference table of Windows time zone identifiers used for time zone conversion across eToro's global operations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table stores the complete list of Windows-standard time zone identifiers (e.g., "Pacific Standard Time", "Israel Standard Time"). Used to support time zone-aware operations across eToro's global customer base, including scheduling, reporting, and customer-facing timestamp display.

Contains 140 time zones covering all global regions. No direct FK references found in the Wallet schema - likely consumed by application-layer code for customer time zone preferences and reporting.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a pure reference table mapping sequential IDs to Windows time zone names. See individual element descriptions in Section 4.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 10 | Pacific Standard Time | US West Coast (UTC-8). Covers California, Washington, Oregon. Used for US West Coast customers and market hours. |
| 22 | Eastern Standard Time | US East Coast (UTC-5). Covers New York financial markets. Used for US East Coast customers. |
| 47 | UTC | Coordinated Universal Time. The base reference time zone used for all internal timestamps and blockchain event recording. |
| 66 | Israel Standard Time | Israel (UTC+2). eToro's headquarters time zone. Used for internal operations and Israeli market hours. |
| 107 | Singapore Standard Time | Singapore (UTC+8). Covers the eToro APAC operations and Asian market hours. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing identifier. 140 values (1-140) covering all Windows time zones. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Windows time zone identifier string. Matches the .NET TimeZoneInfo.Id values used in application code for time zone conversion. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct references found in the Wallet schema.

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in the Wallet schema SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TimeZones | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all time zones
```sql
SELECT Id, Name FROM Dictionary.TimeZones WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find a specific time zone
```sql
SELECT Id, Name FROM Dictionary.TimeZones WITH (NOLOCK) WHERE Name LIKE '%Israel%'
```

### 8.3 Count time zones by UTC offset keyword
```sql
SELECT Id, Name FROM Dictionary.TimeZones WITH (NOLOCK) WHERE Name LIKE 'UTC%' ORDER BY Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TimeZones | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.TimeZones.sql*

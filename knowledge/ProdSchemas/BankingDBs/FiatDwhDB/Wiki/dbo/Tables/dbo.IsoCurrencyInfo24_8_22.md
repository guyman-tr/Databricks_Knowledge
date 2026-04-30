# dbo.IsoCurrencyInfo24_8_22

> Archived snapshot of ISO 4217 currency reference data from 2022-08-24, retained for historical reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | AlphabeticalCode (VARCHAR(3), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

IsoCurrencyInfo24_8_22 is an archived snapshot of ISO 4217 currency codes taken on 2022-08-24. It has the same structure as Dictionary.IsoCurrencyInfo but preserves the currency data as it existed at that point in time. This allows verification of whether currency definitions (particularly minor units) have changed since that date.

This table exists for historical reconciliation. If balance calculations from 2022 need to be verified, the currency minor units (decimal precision) at that time may be needed. The current Dictionary.IsoCurrencyInfo may have been updated since then.

This is a static reference table. No procedures write to or read from it in normal operations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a static reference data snapshot.

---

## 3. Data Overview

N/A - archived snapshot from 2022-08-24. See Dictionary.IsoCurrencyInfo for current values.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AlphabeticalCode | varchar(3) | NO | - | CODE-BACKED | ISO 4217 three-letter currency code (e.g., USD, EUR, GBP). Primary key. |
| 2 | NumericCode | varchar(3) | NO | - | CODE-BACKED | ISO 4217 three-digit numeric currency code (e.g., 840, 978, 826). |
| 3 | MinorUnit | int | NO | - | CODE-BACKED | Number of decimal places for the currency (e.g., 2 for USD/EUR, 0 for JPY, 3 for BHD). Determines amount precision. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No objects reference this archive table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_dbo_IsoCurrencyInfo24_8 | CLUSTERED | AlphabeticalCode ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK).

---

## 8. Sample Queries

### 8.1 Check archived currency data
```sql
SELECT * FROM dbo.IsoCurrencyInfo24_8_22 WITH (NOLOCK) WHERE AlphabeticalCode IN ('USD', 'EUR', 'GBP');
```

### 8.2 Compare archive with current Dictionary data
```sql
SELECT a.AlphabeticalCode, a.MinorUnit AS ArchivedMinorUnit, d.MinorUnit AS CurrentMinorUnit
FROM dbo.IsoCurrencyInfo24_8_22 a WITH (NOLOCK)
JOIN Dictionary.IsoCurrencyInfo d WITH (NOLOCK) ON d.AlphabeticalCode = a.AlphabeticalCode
WHERE a.MinorUnit <> d.MinorUnit;
```

### 8.3 Find currencies that exist in archive but not current
```sql
SELECT a.AlphabeticalCode, a.NumericCode
FROM dbo.IsoCurrencyInfo24_8_22 a WITH (NOLOCK)
LEFT JOIN Dictionary.IsoCurrencyInfo d WITH (NOLOCK) ON d.AlphabeticalCode = a.AlphabeticalCode
WHERE d.AlphabeticalCode IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.IsoCurrencyInfo24_8_22 | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.IsoCurrencyInfo24_8_22.sql*

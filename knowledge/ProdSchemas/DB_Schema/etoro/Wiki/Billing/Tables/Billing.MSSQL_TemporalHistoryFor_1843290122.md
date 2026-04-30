# Billing.MSSQL_TemporalHistoryFor_1843290122

> Orphaned temporal history table that captured historical states of a Refer-A-Friend (RAF) configuration table which no longer exists in the schema (object_id 1843290122 is absent from the live database).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table (Temporal History - Orphaned) |
| **Key Identifier** | No PK - clustered index on (ValidTo ASC, ValidFrom ASC) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom - standard temporal history pattern) |

---

## 1. Business Meaning

Billing.MSSQL_TemporalHistoryFor_1843290122 is the temporal (system-versioned) history table for a Billing-schema table that has since been deleted or renamed. The referenced main table (SQL Server object_id 1843290122) no longer exists in the database. Based on its column structure, the main table was a **RAF (Refer-A-Friend) configuration table** that defined compensation rules per country and regulatory entity for eToro's referral program.

The table captured the historical states of RAF configuration settings: how much referring users were compensated, how much referred users received, minimum deposit requirements to qualify, validity periods, and the Terms & Conditions URL per configuration. The temporal columns ValidFrom/ValidTo record when each configuration was active.

This table now exists as a historical archive only. The main table that fed it has been removed from the Billing schema. The history data is preserved for audit and compliance purposes (RAF payouts may need to be traced back to the configuration that was in effect at the time of the referral).

---

## 2. Business Logic

### 2.1 RAF Compensation Configuration (Historical)

**What**: Each row represents a point-in-time snapshot of RAF compensation rules for a specific country and regulatory entity combination.

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `ReferringCompensationInCents`, `ReferredCompensationInCents`, `MaxNumberOfCompensations`, `ValidFrom`, `ValidTo`

**Rules**:
- ValidFrom / ValidTo: The time period during which this configuration row was the "current" row in the main table.
- When the main table row was updated, the old values were captured here with the actual end time. The current values remain in the main table with ValidTo = 9999-12-31.
- ReferringCompensationInCents: Amount paid to the referring user (the one who sent the referral). In cents (divide by 100 for USD).
- ReferredCompensationInCents: Amount paid to the referred user (the new customer). In cents.
- MaxNumberOfCompensations: Cap on how many referrals a single user can be rewarded for.
- DaysToWaitFromFTD: Grace period (days after first-time deposit) before the compensation is paid out.

---

## 3. Data Overview

Temporal history tables store raw point-in-time snapshots. See the main RAF configuration table (Billing, object_id 1843290122 - no longer in SSDT) for the live configuration. This table is accessible for historical audit queries only.

| Column | Meaning |
|--------|---------|
| RafConfigurationID | Identity of the RAF configuration row this history record tracks |
| CountryID | Country scope for this RAF rule |
| RegulationID | Regulatory entity scope |
| ValidFrom/ValidTo | The temporal period when this row was active in the main table |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | NAME-INFERRED | Country scope for this RAF compensation rule. Implicit FK to Dictionary.Country. |
| 2 | RegulationID | int | NO | - | NAME-INFERRED | Regulatory entity scope. Implicit FK to Dictionary.Regulation. |
| 3 | ReferringCompensationInCents | int | NO | - | NAME-INFERRED | Cash compensation for the user who referred a new customer, in cents. |
| 4 | ReferredCompensationInCents | int | NO | - | NAME-INFERRED | Cash compensation for the newly referred customer on qualifying deposit, in cents. |
| 5 | MaxNumberOfCompensations | int | NO | - | NAME-INFERRED | Maximum number of referring compensations a single user can earn. Prevents abuse of the referral program. |
| 6 | ReferringMinDepositInCents | int | NO | - | NAME-INFERRED | Minimum deposit amount (in cents) the referring user must have made to be eligible for the compensation. |
| 7 | ReferredMinDepositInCents | int | NO | - | NAME-INFERRED | Minimum deposit amount (in cents) the referred (new) user must make to trigger the compensation. |
| 8 | CountRAFFromDate | datetime | YES | - | NAME-INFERRED | Date from which RAF referrals are counted toward MaxNumberOfCompensations. |
| 9 | CheckFTDFromDate | datetime | YES | - | NAME-INFERRED | Date from which first-time deposits are checked for RAF eligibility. |
| 10 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal period start - when this configuration became the active row in the main table. |
| 11 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Temporal period end - when this configuration was superseded by a newer row. Clustered index lead column for efficient temporal range queries. |
| 12 | DaysToWaitFromFTD | int | NO | - | NAME-INFERRED | Number of days to wait after the referred user's first-time deposit before paying the compensation. |
| 13 | ReferringMinPositionsAmountInCents | int | NO | - | NAME-INFERRED | Minimum trading positions value (in cents) the referring user must have for eligibility. |
| 14 | ReferredMinPositionsAmountInCents | int | NO | - | NAME-INFERRED | Minimum trading positions value (in cents) the referred user must achieve for eligibility. |
| 15 | CheckMinPositionsAmountFromDate | datetime | YES | - | NAME-INFERRED | Date from which minimum positions amount is checked. |
| 16 | DaysToCheckMinPositionsAmountFromRegistration | int | NO | - | NAME-INFERRED | Number of days from registration within which the referred user must achieve the minimum positions amount. |
| 17 | TnC_URL | nvarchar(300) | NO | - | NAME-INFERRED | URL to the Terms and Conditions document that governs this RAF configuration. May vary by country/regulation. |
| 18 | RafConfigurationID | int | NO | - | CODE-BACKED | Identity of the specific RAF configuration row this history record archives. References the (now-deleted) main table's PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Country scope of the RAF rule |
| RegulationID | Dictionary.Regulation | Implicit | Regulatory scope of the RAF rule |

### 5.2 Referenced By (other objects point to this)

Not analyzed - this is an orphaned temporal history table with no active main table consuming it.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MSSQL_TemporalHistoryFor_1843290122 (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies (no FK constraints declared on history tables).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (orphaned) | - | The main table (object_id 1843290122) that wrote to this history table no longer exists. No active consumers. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MSSQL_TemporalHistoryFor_1843290122 | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active (PAGE compressed) - standard SQL Server temporal history clustering pattern |

### 7.2 Constraints

None (temporal history tables have no PK or FK constraints by design).

---

## 8. Sample Queries

### 8.1 View all historical RAF configurations

```sql
SELECT
    h.RafConfigurationID,
    h.CountryID,
    h.RegulationID,
    h.ReferringCompensationInCents / 100.0 AS ReferringCompensationUSD,
    h.ReferredCompensationInCents / 100.0 AS ReferredCompensationUSD,
    h.ValidFrom,
    h.ValidTo
FROM Billing.MSSQL_TemporalHistoryFor_1843290122 h WITH (NOLOCK)
ORDER BY h.ValidTo DESC, h.RafConfigurationID
```

### 8.2 Find what RAF configuration was active on a specific date

```sql
SELECT *
FROM Billing.MSSQL_TemporalHistoryFor_1843290122 h WITH (NOLOCK)
WHERE h.ValidFrom <= '2023-01-01'
  AND h.ValidTo > '2023-01-01'
  AND h.RegulationID = 1  -- CySEC
```

### 8.3 N/A - current state query

```sql
-- Note: The main table no longer exists. All data is in this history table.
-- To get the "last known" configuration, use ValidTo = max(ValidTo) per RafConfigurationID
SELECT h.*
FROM Billing.MSSQL_TemporalHistoryFor_1843290122 h WITH (NOLOCK)
WHERE h.ValidTo = (
    SELECT MAX(h2.ValidTo)
    FROM Billing.MSSQL_TemporalHistoryFor_1843290122 h2 WITH (NOLOCK)
    WHERE h2.RafConfigurationID = h.RafConfigurationID
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.0/10 (Elements: 5.5/10, Logic: 7.5/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 16 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (orphaned table) | App Code: 0 repos | Corrections: 0 applied*
*Note: NAME-INFERRED count is high because this table's main counterpart was deleted - no procedure logic or live data to verify column meanings. Column names are self-documenting for this RAF domain.*
*Object: Billing.MSSQL_TemporalHistoryFor_1843290122 | Type: Table (Temporal History) | Source: etoro/etoro/Billing/Tables/Billing.MSSQL_TemporalHistoryFor_1843290122.sql*

# History.BillingDepositTypeConversionFeeOverride

> SQL Server temporal history table for Billing.DepositTypeConversionFeeOverride: records all past states of percentage-based deposit conversion fee overrides for CreditCard deposits, segmented by player level and currency. Currently 360 history rows covering February 2025 to August 2025. Automatically maintained by SYSTEM_VERSIONING.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | DepositTypeConversionFeeID (INT IDENTITY - no PK on history table) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.BillingDepositTypeConversionFeeOverride is the SQL Server temporal system-versioning history table for `Billing.DepositTypeConversionFeeOverride`. It automatically captures every INSERT, UPDATE, and DELETE applied to the deposit conversion fee override configuration, preserving the full audit trail of fee changes.

`Billing.DepositTypeConversionFeeOverride` defines percentage-based fee overrides for currency conversion during deposits. When a customer deposits using a specific payment method and currency, the billing system may apply a conversion fee. This table provides override rates segmented by:
- **PlayerLevelID**: Customer/account tier (7 levels) - different fee rates for different customer tiers
- **CurrencyID**: The deposit currency (30 distinct currencies in history)
- **FundingTypeID**: Payment method - currently only CreditCard (FundingTypeID=1)
- **DepositTypeID**: Deposit classification - currently only DepositTypeID=5

All records have `DepositFee=0` (no flat fee); the actual charge is entirely percentage-based (`DepositFeePercentage`: 0.15% to 0.75%).

**Fee structure**: The combination of FundingTypeID=1 (CreditCard) and DepositTypeID=5 suggests this specifically governs credit card deposit conversion fees for a particular deposit type classification. The "Override" naming implies these supersede a base fee configuration for specific player/currency combinations.

**Scale**: 360 history rows (February 2025 to August 2025). 210 live rows. Ratio of 1.7x indicates moderate reconfiguration activity - the fee schedule has been adjusted multiple times across player levels and currencies.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: SQL Server automatically writes rows to this history table on any INSERT, UPDATE, or DELETE to Billing.DepositTypeConversionFeeOverride.

**Rules**:
- INSERT into source: row becomes active at ValidFrom=NOW; no immediate history row
- UPDATE to source: old row moved to history with ValidTo=NOW; new row active with ValidFrom=NOW
- DELETE from source: deleted row moved to history with ValidTo=NOW
- ValidFrom/ValidTo use UTC (datetime2(7))
- `ModificationDate` (datetime, GETUTCDATE() default) is an application-maintained timestamp in addition to the system-managed ValidFrom/ValidTo

### 2.2 Fee Override Semantics

**What**: Each override specifies a percentage fee for a specific player tier + currency + payment method + deposit type combination.

**Rules**:
- Source PK: DepositTypeConversionFeeID (IDENTITY) - surrogate key, one row per configuration entry
- `DepositFee=0` in all records - no flat fee component, only percentage fee applies
- `DepositFeePercentage`: percentage charged on the deposit amount for currency conversion. Range: 0.15% to 0.75%
- When multiple overrides exist for a player level, the billing system selects by the specific currency and deposit type
- `ModificationDate` tracks when the row was last modified by the application (separate from temporal ValidFrom which tracks the row state)

---

## 3. Data Overview

360 history rows, February 2025 to August 2025. 210 live rows. All rows: FundingTypeID=1 (CreditCard), DepositTypeID=5, DepositFee=0. DepositFeePercentage ranges 0.15%-0.75% across 7 player levels and 30 currencies.

| DepositTypeConversionFeeID | PlayerLevelID | FundingTypeID | CurrencyID | DepositFeePercentage | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|
| (any) | 2 | 1 (CC) | 1 (USD) | 0.45% | 2025-08-26 | 9999-12-31 (live) | PlayerLevel=2 CreditCard USD deposit: 0.45% conversion fee. Changed Aug 2025. |
| (any) | (any) | 1 (CC) | (any) | 0.15-0.75% | 2025-02-24 | 2025-08-25 | Pre-August 2025 fee rates, replaced by the August 2025 reconfiguration. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositTypeConversionFeeID | int | NO | - | CODE-BACKED | Surrogate identity from source table (IDENTITY(1,1) in source). Not a PK on history table. Identifies the override configuration row. |
| 2 | PlayerLevelID | int | NO | - | CODE-BACKED | Customer/account tier. 7 distinct levels in history. Overrides allow different fee rates for different customer tiers (e.g., VIP customers may have lower conversion fees). References Dictionary.PlayerLevel or equivalent. |
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method. Only value in history/live data: 1=CreditCard. Indicates this override table is currently scoped entirely to credit card deposits. References Dictionary.FundingType. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | The deposit currency for which this fee applies. 30 distinct currencies. References Dictionary.Currency. |
| 5 | DepositTypeID | int | NO | - | CODE-BACKED | Classification of the deposit. Only value in history/live data: 5. References Dictionary.DepositType or equivalent lookup table. |
| 6 | DepositFee | int | NO | - | CODE-BACKED | Flat fee component in base currency units. Always 0 in all current records - the fee is entirely percentage-based. |
| 7 | DepositFeePercentage | decimal(18,2) | YES | - | CODE-BACKED | Percentage fee charged on the deposit amount for currency conversion. Range in history: 0.15% to 0.75%. This is the primary business value in this table. NULL would indicate no percentage fee (fallback to DepositFee=0 = free). |
| 8 | ModificationDate | datetime | NO | GETUTCDATE() | CODE-BACKED | Application-managed timestamp of last modification. Uses UTC. Distinct from ValidFrom (which is the temporal system-managed timestamp). Both track "when this changed" but via different mechanisms. |
| 9 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration row became the active state. Managed by SQL Server temporal system. |
| 10 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration row was superseded. Managed by SQL Server temporal system. Clustered index leading key. |
| 11 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON connection context captured via computed column. Format: {"HostName": "...", "AppName": "...", "SUserName": "...", "SPID": "...", "DBName": "...", "ObjectName": "..."}. Identifies who changed the fee configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints on history table. Source table implicit references: Dictionary.FundingType, Dictionary.Currency, Dictionary.PlayerLevel/equivalent.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server SYSTEM_VERSIONING | Automatic | Writer | Temporal versioning engine writes all historical states here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BillingDepositTypeConversionFeeOverride (temporal history table)
  - automatically maintained by: Billing.DepositTypeConversionFeeOverride (source table)
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server temporal engine | System | Writes historical rows from Billing.DepositTypeConversionFeeOverride changes automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BillingDepositTypeConversionFeeOverride | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

Standard temporal clustering on (ValidTo, ValidFrom). PAGE compression. On PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none - no PK) | - | Temporal history tables have no PK constraint. |

---

## 8. Sample Queries

### 8.1 Fee history for a specific player level and currency
```sql
SELECT
    h.DepositTypeConversionFeeID,
    h.PlayerLevelID,
    h.CurrencyID,
    h.DepositFeePercentage,
    h.ModificationDate,
    h.ValidFrom,
    h.ValidTo,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM History.BillingDepositTypeConversionFeeOverride h WITH (NOLOCK)
WHERE h.PlayerLevelID = @PlayerLevelID
  AND h.CurrencyID = @CurrencyID
ORDER BY h.ValidFrom ASC;
```

### 8.2 Point-in-time fee configuration (temporal syntax)
```sql
-- What deposit conversion fees were in effect on a specific date?
SELECT *
FROM Billing.DepositTypeConversionFeeOverride
FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00';
```

### 8.3 Fee percentage changes over time (all player levels, specific currency)
```sql
SELECT
    h.PlayerLevelID,
    h.CurrencyID,
    h.DepositFeePercentage AS OldPct,
    h.ValidFrom AS ChangeTime,
    h.ValidTo AS SupersededAt
FROM History.BillingDepositTypeConversionFeeOverride h WITH (NOLOCK)
WHERE h.CurrencyID = 1  -- USD
ORDER BY h.PlayerLevelID, h.ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BillingDepositTypeConversionFeeOverride | Type: Table | Source: etoro/etoro/History/Tables/History.BillingDepositTypeConversionFeeOverride.sql*

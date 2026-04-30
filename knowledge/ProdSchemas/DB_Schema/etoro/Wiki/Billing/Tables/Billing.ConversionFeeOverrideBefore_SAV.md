# Billing.ConversionFeeOverrideBefore_SAV

> Point-in-time backup snapshot of Billing.ConversionFeeOverride taken before the table was extended with percentage-based fee columns; currently empty and inactive.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | No primary key |
| **Partition** | N/A - DICTIONARY filegroup |
| **Indexes** | None |

---

## 1. Business Meaning

`Billing.ConversionFeeOverrideBefore_SAV` is a backup snapshot of `Billing.ConversionFeeOverride` created before a schema migration added the `DepositFeePercentage`, `CashoutFeePercentage`, and `ConversionFeeID` (IDENTITY) columns to the live table. The "_Before_SAV" naming convention (Save/Backup) is used across the Billing schema to preserve pre-migration state.

The table is currently empty (0 rows). It captures the same structure as the pre-migration ConversionFeeOverride: per-player-level, per-funding-type, per-currency flat fee overrides. The backup was likely taken to allow rollback if the migration failed or caused issues.

No stored procedures reference this table - it is completely inactive. It can be considered a schema artifact from the migration. For current conversion fee override logic, see `Billing.ConversionFeeOverride`.

---

## 2. Business Logic

No complex business logic. This is a static backup table with no active procedures. See `Billing.ConversionFeeOverride` for the live override logic.

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

Table is empty (0 rows). No sample data available.

When the snapshot was taken, rows would have represented the same business data as `Billing.ConversionFeeOverride`: per-player-level, per-funding-type, per-currency deposit and cashout fee overrides in flat (non-percentage) amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | NO | - | CODE-BACKED | Player/customer tier level for which this fee override applies. Same meaning as Billing.ConversionFeeOverride.PlayerLevelID. No explicit FK. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type for which this fee override applies. Implicit FK to Dictionary.FundingType. Same meaning as Billing.ConversionFeeOverride.FundingTypeID. |
| 3 | CurrencyID | int | NO | - | CODE-BACKED | Currency for which the override applies. Same meaning as Billing.ConversionFeeOverride.CurrencyID. No FK constraint (present in the live table but absent in this backup). |
| 4 | DepositFee | int | NO | - | CODE-BACKED | Flat deposit conversion fee in smallest currency unit (e.g., EUR cents). Overrides the base Billing.ConversionFee rate for customers at this PlayerLevelID. Same meaning as Billing.ConversionFeeOverride.DepositFee. |
| 5 | CashoutFee | int | NO | - | CODE-BACKED | Flat cashout/withdrawal conversion fee in smallest currency unit. Same meaning as Billing.ConversionFeeOverride.CashoutFee. |
| 6 | ModifictionDate | datetime | NO | - | CODE-BACKED | Last modification timestamp (note: column name has a typo - "Modifiction" not "Modification"). Same typo carried over from the live table. |
| 7 | CountryID | int | YES | - | CODE-BACKED | Optional country-level scoping for the fee override. NULL means override applies to all countries for this player level + funding type + currency. Same meaning as Billing.ConversionFeeOverride.CountryID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints in DDL).

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this table. It is inactive.

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

No indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | No constraints. No PK, no FK, no check constraints. |

---

## 8. Sample Queries

### 8.1 Verify the table is empty
```sql
SELECT COUNT(*) AS RowCount
FROM   Billing.ConversionFeeOverrideBefore_SAV WITH (NOLOCK);
```

### 8.2 Compare structure to the live table (for migration reference)
```sql
-- Current backup snapshot (empty)
SELECT TOP 5 *
FROM   Billing.ConversionFeeOverrideBefore_SAV WITH (NOLOCK);

-- Live table with same base columns
SELECT TOP 5 PlayerLevelID, FundingTypeID, CurrencyID,
             DepositFee, CashoutFee, ModifictionDate, CountryID
FROM   Billing.ConversionFeeOverride WITH (NOLOCK)
ORDER BY ModifictionDate DESC;
```

### 8.3 Live conversion fee override lookup (use this table instead)
```sql
SELECT  CFO.PlayerLevelID,
        CFO.FundingTypeID,
        CFO.CurrencyID,
        DC.Name             AS CurrencyName,
        CFO.DepositFee,
        CFO.CashoutFee,
        CFO.DepositFeePercentage,
        CFO.CashoutFeePercentage,
        CFO.CountryID
FROM    Billing.ConversionFeeOverride CFO WITH (NOLOCK)
INNER JOIN Dictionary.Currency DC WITH (NOLOCK)
        ON CFO.CurrencyID = DC.CurrencyID
ORDER BY CFO.PlayerLevelID, CFO.FundingTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ConversionFeeOverrideBefore_SAV | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ConversionFeeOverrideBefore_SAV.sql*

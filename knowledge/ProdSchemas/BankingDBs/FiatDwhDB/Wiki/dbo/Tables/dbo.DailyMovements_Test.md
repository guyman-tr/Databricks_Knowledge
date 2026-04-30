# dbo.DailyMovements_Test

> Test clone of dbo.DailyMovements used by dbo.DailyBalanceCalculation_Test for validating daily movement aggregation logic.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

DailyMovements_Test is a test environment clone of dbo.DailyMovements with identical structure. It is used exclusively by the dbo.DailyBalanceCalculation_Test stored procedure to validate movement aggregation and balance calculation logic without affecting production data.

This table exists to enable safe testing of the DailyBalanceCalculation algorithm. Test data is inserted here, and DailyBalanceCalculation_Test processes it to produce test EOD balances in dbo.CustomerEODBalance_Test.

Data flows through this table when DailyBalanceCalculation_Test runs. It reads from this table and uses the movements to calculate test EOD balances.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Identical logic to dbo.DailyMovements - see that table's documentation.

---

## 3. Data Overview

N/A - test table with ephemeral data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | DateId | int | NO | - | CODE-BACKED | Numeric date key in YYYYMMDD format. |
| 3 | MovementsDate | date | NO | - | CODE-BACKED | Business date for the aggregated movements. |
| 4 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID of the test customer. |
| 5 | DailyMovmentsAmount | decimal(36,18) | YES | - | CODE-BACKED | Net aggregated test transaction amount for the day. |
| 6 | COIN | nvarchar(10) | YES | - | CODE-BACKED | ISO 4217 numeric currency code. |
| 7 | MarketRateSymbol | nvarchar(10) | YES | - | CODE-BACKED | Market rate pair symbol for USD conversion reference. |
| 8 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when record was created. |
| 9 | LastDailyTransactionCreated | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the most recent test transaction that contributed to this aggregate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.DailyBalanceCalculation_Test | FROM/INSERT | Writer/Reader | Test version of balance calculation procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.DailyBalanceCalculation_Test | Stored Procedure | Reads and writes test movement data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DailyMovements_Test | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_DailyMovements_Created_Test | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Check test data
```sql
SELECT COUNT(*) AS TestRows FROM dbo.DailyMovements_Test WITH (NOLOCK);
```

### 8.2 View recent test movements
```sql
SELECT TOP 10 * FROM dbo.DailyMovements_Test WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.3 Compare test vs production row counts
```sql
SELECT 'Test' AS Source, COUNT(*) AS Rows FROM dbo.DailyMovements_Test WITH (NOLOCK)
UNION ALL
SELECT 'Prod', COUNT(*) FROM dbo.DailyMovements WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.DailyMovements_Test | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.DailyMovements_Test.sql*

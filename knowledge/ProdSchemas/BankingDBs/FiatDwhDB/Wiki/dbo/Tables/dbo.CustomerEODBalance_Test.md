# dbo.CustomerEODBalance_Test

> Test clone of dbo.CustomerEODBalance used by dbo.DailyBalanceCalculation_Test for validating balance calculation logic without affecting production data.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

CustomerEODBalance_Test is a test environment clone of dbo.CustomerEODBalance with identical structure. It is used exclusively by the dbo.DailyBalanceCalculation_Test stored procedure to validate EOD balance calculation logic in isolation from production data.

This table exists to enable safe testing of changes to the DailyBalanceCalculation algorithm. Developers can populate it with known test data and verify that the calculation procedure produces correct results before deploying changes to the production calculation procedure.

Data flows through this table when DailyBalanceCalculation_Test runs. It reads from dbo.DailyMovements_Test (the test movements table) and writes calculated EOD balances here.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Identical logic to dbo.CustomerEODBalance - see that table's documentation for the EOD balance calculation pattern.

---

## 3. Data Overview

N/A - test table with ephemeral data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | DateId | int | NO | - | CODE-BACKED | Numeric date key in YYYYMMDD format. Same as production CustomerEODBalance.DateId. |
| 3 | EODBalanceDate | date | NO | - | CODE-BACKED | Business date for this EOD balance snapshot. |
| 4 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID of the test customer. |
| 5 | EODBalanceAmount | decimal(36,18) | YES | - | CODE-BACKED | Test customer's fiat balance amount at end of day. |
| 6 | COIN | nvarchar(10) | YES | - | CODE-BACKED | ISO 4217 numeric currency code. |
| 7 | MarketRateSymbol | nvarchar(10) | YES | - | CODE-BACKED | Market rate pair symbol for USD conversion. |
| 8 | RateConverstionToUSD | nvarchar(10) | YES | - | CODE-BACKED | Exchange rate to USD at end of day. |
| 9 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when record was created. |
| 10 | LastDailyMovementCreated | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the most recent test movement that contributed to this balance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.DailyBalanceCalculation_Test | FROM/INSERT/JOIN | Writer/Reader | Test version of balance calculation procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.DailyBalanceCalculation_Test | Stored Procedure | Reads and writes test EOD balance data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EODbalance_Test | CLUSTERED | Id ASC | - | - | Active |
| IX_CustomerEODBalance_EODBalanceDate_Test | NONCLUSTERED | EODBalanceDate ASC | GCID, EODBalanceAmount | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_EODbalance_Created_Test | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Check test data
```sql
SELECT COUNT(*) AS TestRows FROM dbo.CustomerEODBalance_Test WITH (NOLOCK);
```

### 8.2 View recent test balances
```sql
SELECT TOP 10 * FROM dbo.CustomerEODBalance_Test WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.3 Compare test vs production structure
```sql
SELECT 'Test' AS Source, COUNT(*) AS Rows FROM dbo.CustomerEODBalance_Test WITH (NOLOCK)
UNION ALL
SELECT 'Prod', COUNT(*) FROM dbo.CustomerEODBalance WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CustomerEODBalance_Test | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.CustomerEODBalance_Test.sql*

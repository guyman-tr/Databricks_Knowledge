# Trade.UpdateTotalCash

> Maintenance procedure that caps TotalCash for all customers exceeding @amount by resetting it to 0 (real environment) or 2000 (demo environment), processing in batches of @Batch with a before-state log to DB_Logs.dbo.UpdateTotalCash; environment is determined by Maintenance.Feature FeatureID=22.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Customer.CustomerMoney.CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

TotalCash in Customer.CustomerMoney represents the customer's available cash balance. In unusual scenarios (data corruption, excessive bonus credits, runaway demo balance growth) some customers may accumulate TotalCash values above a reasonable threshold. This maintenance procedure caps those balances.

The procedure behaves differently based on the environment flag (Maintenance.Feature FeatureID=22):
- **Real environment** (FeatureID=22 = 1): Reset TotalCash to 0 (removes all cash)
- **Demo environment** (FeatureID=22 != 1): Reset TotalCash to 2000 (the standard demo starting balance that avoids triggering the Billing.RefillDemoBalance process)

The 2000 value was specifically chosen on 2022-06-21 to avoid customers being processed by Billing.RefillDemoBalance (which refills demo balances below a threshold).

Before modifying, each batch is logged to DB_Logs.dbo.UpdateTotalCash for before-state recovery.

---

## 2. Business Logic

### 2.1 Environment Detection via Feature 22

**What**: Determines the reset value based on whether this is a real or demo environment.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID` (= 22), `@IsReal`

**Rules**:
- `@IsReal = CASE WHEN CAST(Value AS int) = 1 THEN 1 ELSE -1 END FROM Maintenance.Feature WHERE FeatureID = 22`
- @IsReal = 1 -> TotalCash set to 0 (real accounts, removes all cash)
- @IsReal = -1 -> TotalCash set to 2000 (demo accounts, standard demo balance)

### 2.2 Above-Threshold Candidate Selection

**What**: Identifies all customers whose TotalCash exceeds the specified threshold.

**Columns/Parameters Involved**: `Customer.CustomerMoney.TotalCash`, `@amount` (default 10,000,000)

**Rules**:
- `WHERE TotalCash > @amount` - only customers with balances above the threshold are affected
- Default @amount = 10,000,000 (10 million) - targets extreme outlier balances
- Candidates loaded into temp table #UpdateTotalCash (CID, TotalCash)

### 2.3 Batch Processing Loop

**What**: Processes candidates in batches of @Batch rows.

**Columns/Parameters Involved**: `@Batch` (default 1000), `@RowC`

**Rules**:
- WHILE @RowC > 0: process TOP @Batch from #UpdateTotalCash ordered by CID
- Each iteration: INSERT log -> UPDATE Customer.CustomerMoney -> DELETE from #UpdateTotalCash
- Loop terminates when no rows remain (@@ROWCOUNT = 0 from DELETE)
- No transaction per batch: each UPDATE and DELETE is auto-commit

### 2.4 Before-State Logging

**What**: The original TotalCash values are logged to DB_Logs before being reset.

**Columns/Parameters Involved**: `DB_Logs.dbo.UpdateTotalCash (CID, TotalCash)`

**Rules**:
- INSERT before the UPDATE: preserves the original balance for potential recovery
- Cross-database write: DB_Logs is a separate logging database

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @amount | int | YES | 10000000 | CODE-BACKED | The TotalCash threshold above which balances are reset. Customers with TotalCash > @amount are included. Default 10,000,000 (10 million) targets extreme outlier balances only. |
| 2 | @Batch | int | YES | 1000 | CODE-BACKED | Number of customers to process per loop iteration. Controls transaction granularity and lock duration. Default 1000. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID = 22 | Maintenance.Feature | SELECT (read) | Environment flag: 1=real (reset to 0), other=demo (reset to 2000) |
| CID | Customer.CustomerMoney | SELECT + UPDATE | Reads candidates (TotalCash > @amount); resets TotalCash per batch |
| (CID, TotalCash) | DB_Logs.dbo.UpdateTotalCash | INSERT (cross-DB) | Before-state log for recovery; written before each batch reset |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External maintenance scripts | Application call | Caller | No internal SP callers found; executed manually or from scheduled maintenance tooling |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateTotalCash (procedure)
|- Maintenance.Feature (table) [READ - FeatureID=22 for environment detection]
|- Customer.CustomerMoney (table) [READ (candidate select) + UPDATE (TotalCash reset)]
+-- DB_Logs.dbo.UpdateTotalCash (table, cross-DB) [INSERT - before-state log]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | READ: FeatureID=22 determines reset value (0 for real, 2000 for demo) |
| Customer.CustomerMoney | Table | READ: candidates WHERE TotalCash > @amount; UPDATE: TotalCash reset per batch |
| DB_Logs.dbo.UpdateTotalCash | Table (cross-DB) | INSERT: before-state log (CID, original TotalCash) per batch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance scripts / DBA tooling | Application | Executed for periodic balance cap maintenance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No transaction | Design | Each batch auto-commits independently; no rollback on partial failure |
| ORDER BY CID | Consistency | Consistent batch ordering prevents reprocessing the same rows (though with no transaction safety) |
| 2000 demo floor | Business rule | 2000 = demo starting balance chosen to avoid Billing.RefillDemoBalance processing |
| Cross-DB log | Infrastructure | DB_Logs must be accessible from this server; cross-database dependency |
| Commented-out index | Note | `---CREATE CLUSTERED INDEX IX ON #UpdateTotalCash` is commented out; may affect performance for large datasets |

---

## 8. Sample Queries

### 8.1 Run with defaults (cap at 10M, batch 1000)

```sql
EXEC Trade.UpdateTotalCash
```

### 8.2 Cap at lower threshold with smaller batches

```sql
EXEC Trade.UpdateTotalCash
    @amount = 1000000,  -- 1 million threshold
    @Batch = 500
```

### 8.3 Check customers above the default threshold

```sql
SELECT COUNT(*) AS AffectedCustomers,
       MIN(TotalCash) AS MinAboveThreshold,
       MAX(TotalCash) AS MaxBalance
FROM Customer.CustomerMoney WITH (NOLOCK)
WHERE TotalCash > 10000000
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateTotalCash | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateTotalCash.sql*

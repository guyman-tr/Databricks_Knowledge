# Billing.DepositHourlyAverage_Update

> Refreshes the deposit hourly average baseline table by aggregating the last N days of deposit data by day-of-week, hour, and payment method - the scheduled maintenance job that keeps alerting baselines current.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPSERT into Billing.DepositHourlyAverage |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositHourlyAverage_Update` is the scheduled maintenance procedure that keeps the deposit monitoring baseline table `Billing.DepositHourlyAverage` current. It reads the last N days (default 28) of deposit records from `Billing.Deposit`, aggregates them into day-of-week + hour + payment-method buckets, and upserts the results into the baseline table.

The baseline drives the deposit alerting system: alert procedures like `Billing.LastHourTotalCreditCardApprovedDepositsVsHistory` compare current-hour deposit volumes against these pre-computed averages to detect payment provider outages in real time. Without regular updates, the baseline would drift from reality and alerts would fire on false positives or miss real incidents.

The procedure contains two execution paths: a commented-out OPENQUERY-based approach for reading from a linked server (historical design, now disabled) and the active local CTE-based query that reads directly from `Billing.Deposit`. The active path uses a two-step UPSERT: UPDATE existing rows, then INSERT new rows for day/hour/payment-method combinations not yet in the baseline (typically new funding types or new hour slots after schema expansions). Parameters `@ServerName` and `@DBName` remain in the signature for backward compatibility but are unused by the active code path.

---

## 2. Business Logic

### 2.1 Lookback Window and CTE Aggregation

**What**: Aggregates deposit counts by day-of-week + hour + funding type over a rolling N-day window.

**Columns/Parameters Involved**: `@NumDays`, `Billing.Deposit.PaymentDate`, `Billing.Funding.FundingTypeID`, `Billing.Deposit.PaymentStatusID`, `Billing.Deposit.RiskManagementStatusID`

**Rules**:
- Default lookback: 28 days (4 full weeks), capturing 4 occurrences of each day-of-week.
- `HourFundingType` CTE: groups deposits by (DayOfWeek, Hour, FundingTypeID) to enumerate distinct occurrences of each slot.
- `DistinctDayOfWeekHour` CTE: counts how many distinct week-occurrences each (DayOfWeek, Hour, FundingTypeID) slot has - typically 4 for a 28-day window. This normalizes averages: `Approved / DistinctDayHours = avg approvals per occurrence`.
- Main SELECT aggregates by PaymentStatusID:
  - `Approved = SUM(CASE PaymentStatusID WHEN 2 THEN 1 ELSE 0 END)`
  - `Declined = SUM(CASE PaymentStatusID WHEN 3 THEN 1 ELSE 0 END)`
  - `Technical = SUM(CASE PaymentStatusID WHEN 4 THEN 1 ELSE 0 END)`
  - `RRE = SUM(CASE PaymentStatusID WHEN 35 THEN 1 ELSE 0 END)`
  - `KycRRE = SUM(CASE WHEN PaymentStatusID = 35 AND RiskManagementStatusID IN (32,33,34,35,37) THEN 1 ELSE 0 END)`
  - `Other = SUM(CASE WHEN PaymentStatusID NOT IN (2,3,4,35) THEN 1 ELSE 0 END)`

### 2.2 Two-Step UPSERT Pattern

**What**: Updates existing baseline rows then inserts new ones - maintains a stable baseline without truncate/reload.

**Columns/Parameters Involved**: All columns in Billing.DepositHourlyAverage

**Rules**:
- Step 1 - UPDATE: Matches rows in `DepositHourlyAverage` by (DepositDay, DepositHour, FundingTypeID) and updates all counts from #T.
- Step 2 - INSERT: Inserts rows from #T where no matching row exists in `DepositHourlyAverage` (new combinations). Anti-join: `WHERE D.DepositDay IS NULL`.
- This pattern avoids a full DELETE/INSERT which would briefly leave the baseline empty (and cause false alerts during the gap).

```
#T (aggregated from Billing.Deposit)
   -> UPDATE existing DepositHourlyAverage rows
   -> INSERT new DepositHourlyAverage rows (new slots)
```

### 2.3 Obsolete OPENQUERY Path (Commented Out)

**What**: Historical design to read from a linked server - disabled but preserved in the code.

**Columns/Parameters Involved**: `@ServerName`, `@DBName`

**Rules**:
- The OPENQUERY block (lines 26-46) is fully commented out. The active path runs locally.
- `@ServerName` and `@DBName` are in the procedure signature for backward compatibility but are NOT used by the active query.
- Callers may still pass these parameters - they are accepted but silently ignored.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumDays | TINYINT | YES | 28 | CODE-BACKED | Lookback window in days for the aggregation. Default 28 produces a 4-week baseline (4 occurrences of each day-of-week). Passed as: `WHERE Dp.PaymentDate >= DATEADD(d, -@NumDays, GETDATE())`. Smaller values produce less stable averages; larger values smooth out anomalies but respond more slowly to trend changes. |
| 2 | @ServerName | VARCHAR(50) | YES | - | CODE-BACKED | Legacy parameter for linked server name used by the now-commented OPENQUERY path. Currently unused by the active query. Accepted for backward compatibility. |
| 3 | @DBName | VARCHAR(50) | YES | - | CODE-BACKED | Legacy parameter for database name used by the now-commented OPENQUERY path. Currently unused by the active query. Accepted for backward compatibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NumDays filter on PaymentDate | Billing.Deposit | READ | Source of all deposit records to aggregate. Joined to Funding to resolve FundingTypeID. |
| FundingID -> FundingTypeID | Billing.Funding | JOIN | Resolves the payment method category. LEFT JOIN since Deposit may have NULL FundingID. |
| PaymentStatusID | Dictionary.PaymentStatus | JOIN (unused output) | LEFT JOINed but no columns selected from it in the active path - likely a leftover from an earlier version. |
| UPSERT target | Billing.DepositHourlyAverage | WRITER | Updates all columns for existing rows; inserts new rows. The core output of this procedure. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Scheduled SQL Server Agent Job) | - | EXEC | Called on a scheduled basis (daily or more frequently) to refresh the baseline. Not referenced by other stored procedures in the SSDT repo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositHourlyAverage_Update (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.PaymentStatus (table)
└── Billing.DepositHourlyAverage (table) [UPSERT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source - aggregated by DW + hour + FundingType over @NumDays. |
| Billing.Funding | Table | LEFT JOINed to resolve FundingTypeID from Deposit.FundingID. |
| Dictionary.PaymentStatus | Table | LEFT JOINed (no columns selected - vestigial join). |
| Billing.DepositHourlyAverage | Table | UPSERT target - both updated and inserted into. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositHourlyAverage_Get | Stored Procedure | READER - reads from the table this proc refreshes. |
| Billing.LastHourTotalCreditCardApprovedDepositsVsHistory | Stored Procedure | READER - alert proc that compares current hour vs baseline this proc maintains. |
| Billing.LastHourTotalPayPalNewDepositsVsHistory | Stored Procedure | READER - alert proc for PayPal monitoring, reads baseline this proc maintains. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Temp table used**: `#T` - same schema as `Billing.DepositHourlyAverage`. Holds aggregated results before the UPSERT. Scoped to this execution.

---

## 8. Sample Queries

### 8.1 Run full baseline refresh with default 28-day window

```sql
EXEC [Billing].[DepositHourlyAverage_Update]
    @NumDays = 28,
    @ServerName = '',
    @DBName = '';
```

### 8.2 Run a quick 7-day refresh to pick up recent trend changes

```sql
EXEC [Billing].[DepositHourlyAverage_Update]
    @NumDays = 7,
    @ServerName = '',
    @DBName = '';
```

### 8.3 Verify the baseline was refreshed recently

```sql
-- Check all day+hour+fundingtype combinations exist after running update
SELECT DepositDay, COUNT(*) AS HourFundingSlots, SUM(TotalRows) AS Total28dDeposits
FROM [Billing].[DepositHourlyAverage] WITH (NOLOCK)
GROUP BY DepositDay
ORDER BY DepositDay;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositHourlyAverage_Update | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositHourlyAverage_Update.sql*

# Billing.DepositHourlyAverage_Get

> Returns all historical deposit hourly baseline rows for a specified day of week, for use in deposit volume alerting and monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositDay -> rows in Billing.DepositHourlyAverage |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositHourlyAverage_Get` retrieves the full historical baseline for a specified day of week from `Billing.DepositHourlyAverage`. The result set covers all hour slots (0-23) and all payment method types for that day, allowing callers to compare the current hour's deposit volume against historical averages.

The primary consumers are monitoring and alerting workflows that need to know: "For this day of the week, what was the historical deposit approval rate per hour per payment method?" This enables real-time anomaly detection - if CreditCard approvals in the last hour are significantly below the historical average for the same day+hour slot, it may indicate a payment provider outage or gateway issue.

The procedure is a pure reader with no side effects. It was created in 2013 (Yitzchak Wahnon, FB: 15792) as part of the deposit monitoring system and adds a computed `Approved/Declined` ratio inline (using NULLIF to avoid division by zero when Declined=0).

---

## 2. Business Logic

### 2.1 Day-of-Week Filter

**What**: Filters the `DepositHourlyAverage` baseline table to a single day-of-week, returning all hour+payment-method combinations for that day.

**Columns/Parameters Involved**: `@DepositDay`, `DepositDay`, `DepositHour`, `FundingTypeID`

**Rules**:
- `@DepositDay` must match `DATEPART(DW, ...)` convention: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday.
- Callers should pass `DATEPART(DW, GETDATE())` for the current day or the day being analyzed.
- Returns up to 24 rows per FundingTypeID (one per hour slot that has data).
- Typical result: ~200+ rows per day (12 funding types x up to 24 hours).

### 2.2 Inline Approval Ratio

**What**: Computes the Approved/Declined ratio inline without requiring the caller to handle division by zero.

**Columns/Parameters Involved**: `Approved`, `Declined`, `[Approved/Declined]` (computed output column)

**Rules**:
- Formula: `1.0 * [Approved] / ISNULL(NULLIF([Declined], 0), 1)`
- When `Declined = 0`, the denominator becomes 1 (not zero), preventing divide-by-zero.
- Result > 1.0 means more approvals than declines (healthy state).
- Result < 1.0 means more declines than approvals (potential issue).
- The column is returned as `[Approved/Declined]` - an alias with a slash, indicating it is a ratio, not a separate stored column.

```
Approved=100, Declined=20  -> Ratio = 5.0  (5 approvals per decline - good)
Approved=20,  Declined=100 -> Ratio = 0.2  (1 approval per 5 declines - alarming)
Approved=50,  Declined=0   -> Ratio = 50.0 (no declines - denominator forced to 1)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositDay | INT | NO | - | CODE-BACKED | Day-of-week filter using SQL Server DATEPART(DW) convention: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday. Pass `DATEPART(DW, GETDATE())` for the current day. Filters `Billing.DepositHourlyAverage.DepositDay`. |

**Output columns** (from `Billing.DepositHourlyAverage` + inline computed):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositDay | int | NO | - | CODE-BACKED | Echoed from the table - day of week (1=Sunday to 7=Saturday). Will equal @DepositDay for all returned rows. |
| 3 | DepositHour | int | NO | - | CODE-BACKED | Hour of day (0-23 UTC) for this baseline row. Combined with DepositDay identifies the specific hour slot. |
| 4 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method for this baseline row. Implicit FK to Dictionary.FundingType. 12 distinct values (e.g., 1=CreditCard, 3=PayPal). |
| 5 | Approved | int | NO | - | CODE-BACKED | Cumulative count of approved deposits (PaymentStatusID=2) in this day+hour+funding-type slot over the 28-day baseline window. |
| 6 | Declined | int | NO | - | CODE-BACKED | Cumulative count of declined deposits (PaymentStatusID=3) in this slot. |
| 7 | [Approved/Declined] | float (computed) | NO | - | CODE-BACKED | Computed ratio: `1.0 * Approved / ISNULL(NULLIF(Declined, 0), 1)`. Values > 1.0 indicate more approvals than declines. Division-by-zero protected via NULLIF. |
| 8 | Technical | int | NO | - | CODE-BACKED | Count of technical failure deposits (PaymentStatusID=4) in this slot. Indicates gateway processing errors. |
| 9 | RRE | int | NO | - | CODE-BACKED | Count of Risk Review Exception deposits (PaymentStatusID=35) in this slot. Deposits held for manual risk review. |
| 10 | KycRRE | int | NO | - | CODE-BACKED | Count of RRE deposits caused by KYC checks (PaymentStatusID=35 AND RiskManagementStatusID IN (32,33,34,35,37)). Subset of RRE. |
| 11 | Other | int | NO | - | CODE-BACKED | Count of deposits with statuses not in (Approved, Declined, Technical, RRE) in this slot. |
| 12 | TotalRows | int | NO | - | CODE-BACKED | Total deposit count (all statuses) in this slot. Used as the denominator for approval rate calculations. |
| 13 | DistinctDayHours | int | NO | - | CODE-BACKED | Number of distinct week occurrences for this (DayOfWeek, Hour) in the 28-day window. Typically 4 (four occurrences of e.g. Monday in 28 days). Normalize with: `Approved / DistinctDayHours` = average approvals per occurrence of this slot. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositDay | Billing.DepositHourlyAverage | Lookup / READER | Filters the pre-aggregated baseline table by day of week. All output columns originate from this table (plus one inline computed ratio). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositHourlyAverage_Get (procedure)
└── Billing.DepositHourlyAverage (table)
      └── [populated from Billing.Deposit by Billing.DepositHourlyAverage_Update]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositHourlyAverage | Table | SELECT - reads all rows matching @DepositDay. Source of all output columns. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in SSDT repo (called by external monitoring jobs or application layer). | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get baseline for the current day of week

```sql
EXEC [Billing].[DepositHourlyAverage_Get]
    @DepositDay = DATEPART(DW, GETDATE());
```

### 8.2 Get baseline for Monday (2) to compare CreditCard performance

```sql
EXEC [Billing].[DepositHourlyAverage_Get]
    @DepositDay = 2;  -- Monday
-- Then filter result: WHERE FundingTypeID = 1 (CreditCard)
```

### 8.3 Check what the historical approval ratio looks like for Friday peak hours

```sql
-- First get the baseline for Friday (6)
EXEC [Billing].[DepositHourlyAverage_Get]
    @DepositDay = 6;
-- Review [Approved/Declined] column for hours 12-18 (peak trading hours)
-- and compare against current hour's deposit counts from Billing.Deposit
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositHourlyAverage_Get | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositHourlyAverage_Get.sql*

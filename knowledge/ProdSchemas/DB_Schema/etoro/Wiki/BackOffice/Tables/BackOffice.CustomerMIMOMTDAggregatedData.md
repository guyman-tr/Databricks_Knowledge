# BackOffice.CustomerMIMOMTDAggregatedData

> Monthly financial aggregates for eToro Money (MIMO) customers, recording per-month deposit, cashout, bonus, and compensation totals from the MIMO payment pipeline. Joined into BackOffice.CustomerMTDAggregatedData view to enrich the unified monthly financial report.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (CID, Year, Month, Date) - composite CLUSTERED PK |
| **Partition** | Yes - ON [MIMOEndMonth]([Date]) |
| **Indexes** | 1 active (1 clustered composite PK) |

---

## 1. Business Meaning

BackOffice.CustomerMIMOMTDAggregatedData stores per-month financial aggregates for customers transacting through the MIMO (eToro Money) payment pipeline. Each row represents one customer's cumulative financial activity in a given calendar month and year: total deposits, cashouts, bonuses, compensation, cashout requests, and reverse cashouts via the eToro Money channel for that month.

MIMO (eToro Money) is eToro's embedded fintech product - a distinct payment pipeline from the standard trading funding path tracked in BackOffice.CustomerMTDAggregatedData_1. MIMO monthly aggregates are maintained via the same event-driven MERGE in BackOffice.UpsertMIMOAggregation that also writes the daily (CustomerMIMODTDAggregatedData) and lifetime (CustomerMIMOAllTimeAggregatedData) MIMO tables, all in a single procedure call per credit event.

5,706,678 rows across 4,674,069 customers as of 2026-03-17. Data spans 2021 (year 1 of MIMO) through 2026. 82.2% of rows have a deposit value > 0. Average of ~1.22 rows per customer - indicating most MIMO customers have 1-2 active months.

The table is consumed by the BackOffice.CustomerMTDAggregatedData view (Year >= 2021), which LEFT JOINs this table to the standard CustomerMTDAggregatedData_1 on (CID, Year, Month), adding MIMO financial flows (TotalDeposit, TotalBonus, TotalCashout, TotalCashoutRequest, TotalReverseCashout, TotalCompensation) while leaving trading metrics (Profit, Investment, Commission, Volume, etc.) from the standard source.

**MIMO aggregation triplet**: UpsertMIMOAggregation always writes to all three MIMO tables in the same call:
- CustomerMIMOAllTimeAggregatedData (lifetime totals per customer)
- CustomerMIMODTDAggregatedData (daily totals per customer per day)
- CustomerMIMOMTDAggregatedData (monthly totals per customer per month) [this table]

---

## 2. Business Logic

### 2.1 Event-Driven Monthly MERGE via UpsertMIMOAggregation

**What**: Each MIMO credit event MERGEs into this table, accumulating into the current calendar month's row.

**Columns Involved**: `CID`, `Year`, `Month`, `Date`, all `Total*` columns, `LastUpdate`

**Rules**:
- MERGE key: (CID, YEAR(D.Date), MONTH(D.Date)) - identifying the current month's row.
- NOT MATCHED (first event for this customer in this calendar month): INSERT with Year=YEAR(D.Date), Month=MONTH(D.Date), Date=D.Date (the date of this specific event), all Total* from computed delta.
- MATCHED (subsequent events for same CID in same calendar month): UPDATE via += (increment all Total* columns by the delta).
- CreditTypeID mapping (same as DTD and AllTime):
  - CreditTypeID=1 (Deposit): TotalDeposit += @Payment/100.
  - CreditTypeID=2 (Cashout): TotalCashout += WithdrawFullAmount.
  - CreditTypeID=6 (Compensation): TotalCompensation += @Payment/100.
  - CreditTypeID=7 (Bonus): TotalBonus += @Payment/100.
  - CreditTypeID=8 or 15 with @CreditChange > 0: TotalReverseCashout += @CreditChange.
  - CreditTypeID=9 or 15 with @CreditChange <= 0: TotalCashoutRequest += abs(@CreditChange).
- The Date column is set at INSERT time to D.Date (the processing date of the first event in the month). It is NOT updated on subsequent MATCHed events, so Date represents the date of the customer's first MIMO event in that month.
- PK note: The PK includes Date despite the effective grain being (CID, Year, Month). This means there can only ever be one row per (CID, Year, Month) per the MERGE logic - the Date is an insert artifact, not a true additional dimension.

### 2.2 Role in the Unified Monthly Aggregation View

**What**: CustomerMTDAggregatedData view combines trading metrics from the standard table with MIMO financial flows from this table.

**Columns Involved**: `CID`, `Year`, `Month`, `TotalDeposit`, `TotalBonus`, `TotalCashout`, `TotalCashoutRequest`, `TotalReverseCashout`, `TotalCompensation`

**Rules**:
- View pattern: LEFT JOIN CustomerMIMOMTDAggregatedData M ON A.CID=M.CID AND M.Year=A.Year AND M.Month=A.Month, WHERE A.Year >= 2021.
- ISNULL(M.TotalDeposit, 0) ensures NULL is treated as zero for months with no MIMO activity.
- Pre-2021 data (WHERE Year < 2021) uses only CustomerMTDAggregatedData_1 (MIMO did not exist before January 2021).
- Trading columns (TotalProfit, TotalInvestment, TotalCommission, TotalVolume, etc.) always come from CustomerMTDAggregatedData_1.

---

## 3. Data Overview

| CID (sample) | Year | Month | Date | TotalDeposit | TotalCashout | Meaning |
|-------------|------|-------|------|-------------|-------------|---------|
| (MIMO customer) | 2021 | 1 | 2021-01-07 | >0 | 0 | First month of MIMO data. Customer's January 2021 eToro Money deposits. Date = first event date in the month. |
| (cashout example) | 2024 | 6 | 2024-06-03 | 0 | >0 | Customer cashed out via eToro Money in June 2024. TotalCashout = full withdraw amount. |
| (multi-event) | 2025 | 3 | 2025-03-01 | >0 | >0 | Customer both deposited and cashed out in March 2025. Both columns > 0 due to accumulation. |

5,706,678 total rows as of 2026-03-17:
- Rows with TotalDeposit > 0: 4,693,407 (82.2%)
- Rows with FirstTimeDepositAttemptDate set: 4,670,520 (81.8%)
- Year range: 2021-2026, Month range: 1-12
- Distinct customers: 4,674,069 (aligns with DTD and AllTime MIMO tables)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. Part of composite CLUSTERED PK. Implicit FK to Customer.CustomerStatic(CID). Joins to the AllTime and DTD MIMO tables on CID. |
| 2 | Year | int | NO | - | VERIFIED | Calendar year of the aggregated month (e.g., 2024). Part of composite CLUSTERED PK. Computed as YEAR(GETUTCDATE()) at INSERT. Range: 2021-2026 as of 2026-03-17. |
| 3 | Month | int | NO | - | VERIFIED | Calendar month number (1=January, 12=December). Part of composite CLUSTERED PK. Computed as MONTH(GETUTCDATE()) at INSERT. Enables monthly bucketing without date arithmetic on consumers. |
| 4 | TotalDeposit | decimal(34,4) | NO | 0 | VERIFIED | Cumulative MIMO deposit amount for this customer in this calendar month. Incremented by CreditTypeID=1 events. Value in USD (payment in cents / 100). DEFAULT=0. 82.2% of rows > 0. |
| 5 | TotalBonus | decimal(34,4) | NO | 0 | VERIFIED | Cumulative MIMO bonus amount for this customer in this calendar month. Incremented by CreditTypeID=7 events. DEFAULT=0. |
| 6 | TotalChampWin | decimal(34,4) | NO | 0 | CODE-BACKED | Championship/contest prize winnings. Always 0 in current MIMO pipeline (UpsertMIMOAggregation hardcodes ChampWinner=0). Exists for structural parity with CustomerMTDAggregatedData_1. DEFAULT=0. |
| 7 | TotalCashout | decimal(34,4) | NO | 0 | VERIFIED | Cumulative MIMO cashout amount (full withdraw amount including fee) for this customer in this calendar month. Incremented by CreditTypeID=2 events. DEFAULT=0. |
| 8 | TotalCashoutRequest | decimal(34,4) | NO | 0 | VERIFIED | Cumulative MIMO cashout request amount for this customer in this calendar month. Incremented by CreditTypeID=9 or 15 with @CreditChange<=0. DEFAULT=0. |
| 9 | TotalReverseCashout | decimal(34,4) | NO | 0 | VERIFIED | Cumulative reversed cashout amount for this customer in this calendar month. Incremented by CreditTypeID=8 or 15 with @CreditChange>0. DEFAULT=0. |
| 10 | TotalCompensation | decimal(34,4) | NO | 0 | VERIFIED | Cumulative MIMO compensation payments for this customer in this calendar month. Incremented by CreditTypeID=6 events. DEFAULT=0. |
| 11 | LastUpdate | datetime | NO | - | VERIFIED | UTC timestamp of the last write to this row (GETUTCDATE() on every INSERT/UPDATE). Reflects the most recent MIMO event in this calendar month for this customer. |
| 12 | FirstTimeDepositAttemptDate | datetime | YES | NULL | VERIFIED | Date of this customer's first deposit attempt. Set at INSERT from the Delta TVP (which inherits it from the AllTime MERGE); preserved by ISNULL on UPDATE. NULL for non-deposit first-events. |
| 13 | FirstTimeDepositSuccessDate | datetime | YES | NULL | VERIFIED | Date of this customer's first successful deposit (PaymentStatusID=2). Set once; preserved by ISNULL. Mirrors AllTime and DTD MIMO tables. |
| 14 | Date | datetime | NO | - | CODE-BACKED | The date of the FIRST MIMO event for this customer in this calendar month (not the last or any specific event date). Assigned at INSERT as D.Date (today's midnight UTC) and never updated on subsequent MATCHed events. Part of the PK for technical reasons but not a true grain dimension - the actual grain is (CID, Year, Month). Partition key for ON [MIMOEndMonth]([Date]). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This table has no declared FK constraints. All references are implicit:

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer account |
| CID | BackOffice.CustomerMIMOAllTimeAggregatedData | Implicit (co-written) | Lifetime MIMO totals for the same customer |
| CID, Date | BackOffice.CustomerMIMODTDAggregatedData | Implicit (co-written) | Daily MIMO totals covering this month's data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertMIMOAggregation | CID, Year, Month | WRITER (MERGE) | Event-driven MIMO credit processing |
| BackOffice.CustomerMTDAggregatedData | CID, Year, Month | VIEW JOIN | LEFT JOIN to provide MIMO financial columns in unified MTD view (2021+) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerMIMOMTDAggregatedData (table)
- Written by: BackOffice.UpsertMIMOAggregation
  |- Same call also writes CustomerMIMOAllTimeAggregatedData and CustomerMIMODTDAggregatedData
- Consumed by: BackOffice.CustomerMTDAggregatedData (view)
  |- View joins with CustomerMTDAggregatedData_1 (standard monthly aggregates)
```

### 6.1 Objects This Depends On

No FK constraints declared. Logically depends on Customer.CustomerStatic (via CID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertMIMOAggregation | Procedure | WRITER - MERGE on (CID, Year, Month) |
| BackOffice.CustomerMTDAggregatedData | View | READER - LEFT JOIN for MIMO financial columns |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MIMO_BOCMTDADN_MM | CLUSTERED PK | CID ASC, Year ASC, Month ASC, Date ASC | - | Partition: MIMOEndMonth(Date) | Active (FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MIMO_BOCMTDADN_MM | PK | Uniqueness of (CID, Year, Month, Date) - functionally one row per (CID, Year, Month) |
| BOCMTDADN_MM_TOTALDEPOSIT | DEFAULT | TotalDeposit = 0 |
| BOCMTDADN_MM_TOTALBONUS | DEFAULT | TotalBonus = 0 |
| BOCMTDADN_MM_TOTALCHAMPWIN | DEFAULT | TotalChampWin = 0 |
| BOCMTDADN_MM_TOTALCASHOUT | DEFAULT | TotalCashout = 0 |
| BOCMTDADN_MM_TOTALCASHOUTREQUEST | DEFAULT | TotalCashoutRequest = 0 |
| BOCMTDADN_MM_TOTALREVERSECASHOUT | DEFAULT | TotalReverseCashout = 0 |
| BOCMTDADN_MM_TOTALCOMPENSATION | DEFAULT | TotalCompensation = 0 |

### 7.3 PK Design Note

The PK includes four columns: (CID, Year, Month, Date). Logically the grain is (CID, Year, Month) since MERGE matches only on those three. The Date column in the PK is technically redundant - once a row is inserted for a given (CID, Year, Month), the MERGE always matches on those three and updates in place; Date is never changed. This design appears to be an artifact - the partition function requires a Date column in the key for partition-aligned storage.

### 7.4 Partitioning

Partitioned ON [MIMOEndMonth]([Date]). The Date column (first event date in the month) drives partition placement, co-locating rows by calendar period for efficient month-range scans. Data from 2021 onwards.

---

## 8. Sample Queries

### 8.1 Get monthly MIMO activity for a customer
```sql
SELECT Year, Month, TotalDeposit, TotalCashout, TotalBonus,
       TotalCompensation, TotalCashoutRequest, TotalReverseCashout, LastUpdate
FROM BackOffice.CustomerMIMOMTDAggregatedData WITH (NOLOCK)
WHERE CID = @CID
ORDER BY Year DESC, Month DESC
```

### 8.2 MIMO monthly deposit totals for the last 12 months
```sql
SELECT Year, Month,
       SUM(TotalDeposit) AS MonthlyDepositTotal,
       COUNT(DISTINCT CID) AS DepositingCustomers
FROM BackOffice.CustomerMIMOMTDAggregatedData WITH (NOLOCK)
WHERE (Year = YEAR(GETUTCDATE()) AND Month <= MONTH(GETUTCDATE()))
   OR (Year = YEAR(GETUTCDATE()) - 1 AND Month > MONTH(GETUTCDATE()))
GROUP BY Year, Month
ORDER BY Year DESC, Month DESC
```

### 8.3 Use the unified view for a customer's monthly history (includes trading metrics)
```sql
SELECT Year, Month, TotalDeposit, TotalCashout, TotalProfit,
       TotalVolume, TotalPositionCount
FROM BackOffice.CustomerMTDAggregatedData WITH (NOLOCK)
WHERE CID = @CID
  AND Year >= 2022
ORDER BY Year DESC, Month DESC
```

---

## 9. Atlassian Knowledge Sources

No direct Atlassian sources found. UpsertMIMOAggregation comment cites PAYUS-1770 (Nov 2020, initial MIMO aggregation) and PAYSOLB-803 (Mar 2022, FirstTimeDepositSuccessDate fix). CustomerMTDAggregatedData view comment cites PAYT-10 (Apr 2022, removed TotalLoginCount/TotalLoggedTime).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerMIMOMTDAggregatedData | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerMIMOMTDAggregatedData.sql*

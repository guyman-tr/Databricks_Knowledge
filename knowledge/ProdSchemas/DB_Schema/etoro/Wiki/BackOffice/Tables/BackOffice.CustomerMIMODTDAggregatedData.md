# BackOffice.CustomerMIMODTDAggregatedData

> Daily financial aggregates for eToro Money (MIMO) customers, recording per-day deposit, cashout, bonus, and compensation totals from the MIMO payment pipeline. Joined into BackOffice.CustomerDTDAggregatedData view to enrich the unified daily financial report.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (CID, Date) - composite CLUSTERED PK |
| **Partition** | Yes - ON [MIMOEndMonth]([Date]) |
| **Indexes** | 1 active (1 clustered composite PK) |

---

## 1. Business Meaning

BackOffice.CustomerMIMODTDAggregatedData stores per-day financial aggregates for customers transacting through the MIMO (eToro Money) payment pipeline. Each row represents one customer's financial activity on a single calendar date: how much they deposited, cashed out, received as bonus or compensation, and requested or reversed as withdrawals through the eToro Money fintech channel on that day.

MIMO (eToro Money) is eToro's embedded fintech product - a separate payment pipeline from the standard trading funding path. While standard trading customers' daily financial aggregates are tracked in BackOffice.CustomerDTDAggregatedData_1 (updated in batch by UpsertIntoAggregationTablesAction), MIMO customers are tracked here via event-driven MERGE calls from BackOffice.UpsertMIMOAggregation - one call per credit event, immediately on occurrence.

5,845,996 rows across 4,674,089 customers as of 2026-03-17. Date range: 2021-01-07 (MIMO/eToro Money launch) to present. 80.6% of rows have a deposit value > 0. Only 5.4% have cashout activity. Bonuses are rare (0.1%).

The table is consumed by the BackOffice.CustomerDTDAggregatedData view (2021 onwards), which LEFT JOINs this table to the standard CustomerDTDAggregatedData_1 on (CID, Date), adding MIMO financial columns (TotalDeposit, TotalBonus, TotalCashout, TotalCashoutRequest, TotalReverseCashout, TotalCompensation) while leaving trading metrics (Profit, Investment, Commission, Volume, etc.) from the standard source. Pre-2021 rows in the view use the standard table only.

**MIMO aggregation triplet**: UpsertMIMOAggregation always writes to all three MIMO tables in the same call:
- CustomerMIMOAllTimeAggregatedData (lifetime totals per customer)
- CustomerMIMODTDAggregatedData (daily totals per customer per day) [this table]
- CustomerMIMOMTDAggregatedData (monthly totals per customer per month)

---

## 2. Business Logic

### 2.1 Event-Driven Daily MERGE via UpsertMIMOAggregation

**What**: Each MIMO credit event immediately MERGEs into this table, adding a delta to that day's row.

**Columns Involved**: `CID`, `Date`, all `Total*` columns, `LastUpdate`, `FirstTimeDepositAttemptDate`, `FirstTimeDepositSuccessDate`

**Rules**:
- MERGE key: (CID, Date) where Date = DATEADD(dd, 0, DATEDIFF(dd, 0, GETUTCDATE())) - today's date at midnight UTC.
- NOT MATCHED (first event for this customer on this date): INSERT new row with computed delta values and GETUTCDATE() as LastUpdate.
- MATCHED (subsequent events for same CID on same date): UPDATE via += (increment all Total* columns by the delta).
- CreditTypeID mapping (same as AllTime):
  - CreditTypeID=1 (Deposit): TotalDeposit += @Payment/100. FirstTimeDepositAttemptDate and FirstTimeDepositSuccessDate set if not already populated.
  - CreditTypeID=2 (Cashout): TotalCashout += WithdrawFullAmount (from Billing.WithdrawToFunding join - full amount including fee).
  - CreditTypeID=6 (Compensation): TotalCompensation += @Payment/100.
  - CreditTypeID=7 (Bonus): TotalBonus += @Payment/100.
  - CreditTypeID=8 or 15 with @CreditChange > 0 (Reverse Cashout): TotalReverseCashout += @CreditChange.
  - CreditTypeID=9 or 15 with @CreditChange <= 0 (Cashout Request): TotalCashoutRequest += abs(@CreditChange).
- TotalChampWin is always 0 in the MERGE (ChampWinner column in delta is hardcoded 0 in UpsertMIMOAggregation).
- LastUpdate = GETUTCDATE() on every write.
- Note: @Payment is passed in cents (integer), divided by 100 for DECIMAL(34,4) storage.

### 2.2 Role in the Unified Daily Aggregation View

**What**: CustomerDTDAggregatedData view combines trading metrics from the standard table with MIMO financial flows from this table.

**Columns Involved**: `CID`, `Date`, `TotalDeposit`, `TotalBonus`, `TotalCashout`, `TotalCashoutRequest`, `TotalReverseCashout`, `TotalCompensation`

**Rules**:
- View pattern: LEFT JOIN CustomerMIMODTDAggregatedData M ON A.CID=M.CID AND M.Date=A.Date, WHERE A.Date >= '20210101'.
- ISNULL(M.TotalDeposit, 0) ensures NULL is treated as zero when no MIMO activity exists for that day.
- For pre-2021 rows (WHERE Date < '20210101'), only the standard CustomerDTDAggregatedData_1 is used without this join (MIMO did not exist before 2021-01-07).
- Trading columns (TotalProfit, TotalInvestment, TotalCommission, TotalVolume, TotalLot, TotalPositionCount, TotalEndOfWeekFee, LastRealizedEquity) always come from the standard CustomerDTDAggregatedData_1; they are not stored here.

---

## 3. Data Overview

| CID (sample) | Date | TotalDeposit | TotalCashout | TotalBonus | Meaning |
|-------------|------|-------------|-------------|-----------|---------|
| (any MIMO customer) | 2021-01-07 | >0 | 0 | 0 | First day of MIMO data. Customer's first eToro Money deposit. TotalDeposit = sum of all deposits that day. |
| (cashout example) | any | 0 | >0 | 0 | Customer withdrew via eToro Money channel. TotalCashout = full withdraw amount including fee (from WithdrawToFunding). |
| (bonus example) | any | 0 | 0 | >0 | MIMO bonus granted. Rare - only 5,931 rows (0.1%) have TotalBonus > 0. |

5,845,996 total rows as of 2026-03-17:
- Rows with TotalDeposit > 0: 4,707,614 (80.6%)
- Rows with TotalCashout > 0: 317,578 (5.4%)
- Rows with TotalBonus > 0: 5,931 (0.1%)
- Rows with FirstTimeDepositAttemptDate set: 4,684,711 (80.2%)
- Date range: 2021-01-07 to 2026-03-17
- Distinct customers: 4,674,089 (aligns with CustomerMIMOAllTimeAggregatedData)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. Part of composite CLUSTERED PK. Implicit FK to Customer.CustomerStatic(CID) - no declared FK constraint. Joins to the AllTime and MTD MIMO tables on CID. |
| 2 | Date | datetime | NO | - | VERIFIED | Calendar date of the activity (midnight UTC, e.g., 2024-03-15 00:00:00). Part of composite CLUSTERED PK. Partition key - ON [MIMOEndMonth]([Date]). Computed as DATEADD(dd, 0, DATEDIFF(dd, 0, GETUTCDATE())) at insert time. Range: 2021-01-07 to present. |
| 3 | TotalDeposit | decimal(34,4) | NO | 0 | VERIFIED | Sum of all MIMO deposit amounts for this customer on this date. Incremented when CreditTypeID=1. Value in USD (payment in cents / 100). DEFAULT=0. 80.6% of rows > 0. |
| 4 | TotalBonus | decimal(34,4) | NO | 0 | VERIFIED | Sum of all MIMO bonus amounts for this customer on this date. Incremented when CreditTypeID=7. Value in USD (payment in cents / 100). DEFAULT=0. Rare: 0.1% of rows > 0. |
| 5 | TotalChampWin | decimal(34,4) | NO | 0 | CODE-BACKED | Championship/contest prize winnings. Always 0 in current MIMO pipeline (UpsertMIMOAggregation hardcodes ChampWinner=0). Field exists for structural parity with CustomerDTDAggregatedData_1. DEFAULT=0. |
| 6 | TotalCashout | decimal(34,4) | NO | 0 | VERIFIED | Sum of full cashout amounts (Withdraw.Amount + Withdraw.Fee) for this customer on this date via MIMO. Incremented when CreditTypeID=2 AND this is the first processed payout (MIN(WithdrawToFunding.ID) check). DEFAULT=0. 5.4% of rows > 0. |
| 7 | TotalCashoutRequest | decimal(34,4) | NO | 0 | VERIFIED | Sum of cashout request amounts initiated by this customer on this date via MIMO. Incremented when CreditTypeID=9 or 15 with @CreditChange<=0 (request, not yet settled). Value = abs(@CreditChange). DEFAULT=0. |
| 8 | TotalReverseCashout | decimal(34,4) | NO | 0 | VERIFIED | Sum of reversed cashout amounts for this customer on this date (cashouts that were reversed/cancelled). Incremented when CreditTypeID=8 or 15 with @CreditChange>0. DEFAULT=0. |
| 9 | TotalCompensation | decimal(34,4) | NO | 0 | VERIFIED | Sum of all compensation payments for this customer on this date via MIMO. Incremented when CreditTypeID=6. Value in USD (payment in cents / 100). DEFAULT=0. |
| 10 | LastUpdate | datetime | NO | - | VERIFIED | UTC timestamp of the last write to this row. Set to GETUTCDATE() on every INSERT and UPDATE by UpsertMIMOAggregation. Reflects the time of the most recent MIMO credit event processed for this customer on this date. |
| 11 | FirstTimeDepositAttemptDate | datetime | YES | NULL | VERIFIED | Date of this customer's first deposit attempt via any channel (inherited from CustomerMIMOAllTimeAggregatedData at insert time). Set once; subsequent events use ISNULL to preserve the existing value. NULL for 19.8% of rows (non-deposit events, or insert before a deposit existed). Mirrors the AllTime table's field. |
| 12 | FirstTimeDepositSuccessDate | datetime | YES | NULL | VERIFIED | Date of this customer's first successful deposit (PaymentStatusID=2) via any channel. Set once; preserved by ISNULL on subsequent events. NULL for customers whose first deposit attempt was not yet successful. Mirrors the AllTime table's field. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This table has no declared FK constraints. All references are implicit:

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer account |
| CID | BackOffice.CustomerMIMOAllTimeAggregatedData | Implicit (co-written) | Lifetime MIMO totals for the same customer |
| CID, Year, Month | BackOffice.CustomerMIMOMTDAggregatedData | Implicit (co-written) | Monthly MIMO totals covering this day's data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertMIMOAggregation | CID, Date | WRITER (MERGE) | Event-driven MIMO credit processing |
| BackOffice.CustomerDTDAggregatedData | CID, Date | VIEW JOIN | LEFT JOIN to provide MIMO financial columns in unified DTD view (2021+) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerMIMODTDAggregatedData (table)
- Written by: BackOffice.UpsertMIMOAggregation
  |- Same call also writes CustomerMIMOAllTimeAggregatedData and CustomerMIMOMTDAggregatedData
- Consumed by: BackOffice.CustomerDTDAggregatedData (view)
  |- View joins with CustomerDTDAggregatedData_1 (standard daily aggregates)
```

### 6.1 Objects This Depends On

No FK constraints declared. Logically depends on Customer.CustomerStatic (via CID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertMIMOAggregation | Procedure | WRITER - MERGE on (CID, Date) |
| BackOffice.CustomerDTDAggregatedData | View | READER - LEFT JOIN for MIMO financial columns |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BOCDTDADN_MM_New | CLUSTERED PK | CID ASC, Date ASC | - | Partition: MIMOEndMonth(Date) | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BOCDTDADN_MM_New | PK | Uniqueness of (CID, Date) - one row per customer per day |
| BOCDTDADN_MM_TOTALDEPOSIT | DEFAULT | TotalDeposit = 0 |
| BOCDTDADN_MM_TOTALBONUS | DEFAULT | TotalBonus = 0 |
| BOCDTDADN_MM_TOTALCHAMPWIN | DEFAULT | TotalChampWin = 0 |
| BOCDTDADN_MM_TOTALCASHOUT | DEFAULT | TotalCashout = 0 |
| BOCDTDADN_MM_TOTALCASHOUTREQUEST | DEFAULT | TotalCashoutRequest = 0 |
| BOCDTDADN_MM_TOTALREVERSECASHOUT | DEFAULT | TotalReverseCashout = 0 |
| BOCDTDADN_MM_TOTALCOMPENSATION | DEFAULT | TotalCompensation = 0 |

### 7.3 Partitioning

Partitioned ON [MIMOEndMonth]([Date]). The MIMOEndMonth partition function likely aligns partition boundaries with month-end dates to co-locate data by calendar month, matching the MIMO monthly aggregation structure. Data added from 2021-01-07 onwards as MIMO launched January 2021.

---

## 8. Sample Queries

### 8.1 Get daily MIMO activity for a customer
```sql
SELECT Date, TotalDeposit, TotalCashout, TotalBonus, TotalCompensation,
       TotalCashoutRequest, TotalReverseCashout, LastUpdate
FROM BackOffice.CustomerMIMODTDAggregatedData WITH (NOLOCK)
WHERE CID = @CID
ORDER BY Date DESC
```

### 8.2 Daily MIMO deposit totals across all customers (last 30 days)
```sql
SELECT Date,
       SUM(TotalDeposit) AS DailyDepositTotal,
       COUNT(DISTINCT CID) AS ActiveCustomers
FROM BackOffice.CustomerMIMODTDAggregatedData WITH (NOLOCK)
WHERE Date >= DATEADD(dd, -30, GETUTCDATE())
GROUP BY Date
ORDER BY Date DESC
```

### 8.3 Use the unified view for a customer's full daily history (includes trading metrics)
```sql
SELECT Date, TotalDeposit, TotalCashout, TotalProfit, TotalVolume,
       TotalPositionCount, TotalEndOfWeekFee
FROM BackOffice.CustomerDTDAggregatedData WITH (NOLOCK)
WHERE CID = @CID
  AND Date >= DATEADD(month, -3, GETUTCDATE())
ORDER BY Date DESC
```

---

## 9. Atlassian Knowledge Sources

No direct Atlassian sources found. UpsertMIMOAggregation comment cites PAYUS-1770 (Nov 2020, initial MIMO aggregation version) and PAYSOLB-803 (Mar 2022, FirstTimeDepositSuccessDate calculation fix). The CustomerDTDAggregatedData view comment cites PAYT-10 (Apr 2022, removed TotalLoginCount/TotalLoggedTime columns).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerMIMODTDAggregatedData | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerMIMODTDAggregatedData.sql*

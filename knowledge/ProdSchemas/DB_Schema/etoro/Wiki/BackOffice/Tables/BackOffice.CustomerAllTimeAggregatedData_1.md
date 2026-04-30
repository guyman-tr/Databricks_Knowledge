# BackOffice.CustomerAllTimeAggregatedData_1

> Lifetime cumulative financial and behavioral aggregates per customer account, updated continuously from billing credit events and login activity. The physical backing table for the BackOffice.CustomerAllTimeAggregatedData view.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, CLUSTERED PK) |
| **Partition** | No (stored ON [HISTORY] filegroup with DATA_COMPRESSION=PAGE) |
| **Indexes** | 5 active (1 clustered PK + 4 NC on milestone date columns) |

---

## 1. Business Meaning

BackOffice.CustomerAllTimeAggregatedData_1 is the all-time lifetime financial summary for every customer account in the platform. Each row holds a single customer's running totals for every material financial event since they joined: total amount deposited, cashed out, earned as profit, received as bonuses and compensation, invested, traded by volume and lot, and the dates of key lifecycle milestones.

The table drives the BackOffice customer header panel (via GetCustomerHeader), risk exposure reports, SalesForce CRM synchronization, and DWH/data lake pipelines (the DWH sources BackOffice.CustomerAllTimeAggregatedData, the view on top of this table). It answers the fundamental operational question: "what has this customer done and how much money have they moved through the platform in total?"

**Naming note**: Prior to February 2021, this data lived in a table named BackOffice.CustomerAllTimeAggregatedData. That table was converted to a view (for backward compatibility with existing queries), and the physical data was moved to BackOffice.CustomerAllTimeAggregatedData_1. All new writes target the _1 table; all reads via the view transparently access it.

6.736M rows as of 2026-03-17 - one per CID. 38.3% of rows have TotalDeposit=0 (registered but never deposited). 65.3% have a first-time deposit date. 99.4% have a LastRealizedEquity value.

---

## 2. Business Logic

### 2.1 Near-Real-Time Delta Upsert from Credit Events

**What**: All financial totals are maintained as running sums updated continuously from billing credit events, not recomputed from scratch.

**Columns Involved**: All `Total*` columns, `LastUpdate`, `LastOccurredTriggerToSF`

**Rules**:
- `UpsertIntoAggregationTablesAction` is the sole writer. It runs continuously, processing batches of new credit events (by CreditID range) from History.ActiveCredit.
- Each credit row maps to exactly one financial total via its CreditTypeID:
  - CreditTypeID=1: Deposit -> TotalDeposit delta
  - CreditTypeID=2: Cashout (withdrawal payment) -> TotalCashout delta
  - CreditTypeID=3, 13: Investment (funds locked into position) -> TotalInvestment delta (negated - stored as positive outflow)
  - CreditTypeID=4: Position close with P&L -> TotalProfit delta (via History.Position.NetProfit), TotalPositionCount, TotalVolume, TotalLot
  - CreditTypeID=5: Championship win payout -> TotalChampWin delta
  - CreditTypeID=6: Manual compensation payment -> TotalCompensation delta
  - CreditTypeID=7: Bonus credit -> TotalBonus delta
  - CreditTypeID=8, 15 (positive TotalCashChange): Reverse cashout (returned withdrawal) -> TotalReverseCashout delta
  - CreditTypeID=9, 15 (negative TotalCashChange): Cashout request deduction -> TotalCashoutRequest delta
  - CreditTypeID=14: End-of-week inactivity fee -> TotalEndOfWeekFee delta (negated)
- UPDATE for existing CID rows, INSERT for new CIDs not yet in the table.
- All deltas are accumulated: `TotalDeposit = TotalDeposit + TotalDepositDelta`.
- LastUpdate set to GETUTCDATE() on every upsert.

**Diagram**:
```
History.ActiveCredit (new CreditIDs since last run)
    |
    v
UpsertIntoAggregationTablesAction
    |-- Classify by CreditTypeID -> compute deltas
    |-- Join History.Position for profit/volume (CreditTypeID=4)
    |-- Join Billing.Deposit for FTD milestone dates
    |-- Join Customer.CustomerMoney for LastRealizedEquity
    |
    v
UPSERT BackOffice.CustomerAllTimeAggregatedData_1 (AllTime running totals)
UPSERT BackOffice.CustomerDTDAggregatedData_1     (Day-to-date by date)
UPSERT BackOffice.CustomerMTDAggregatedData_1     (Month-to-date by year/month)
```

### 2.2 SalesForce CRM Trigger Tracking

**What**: `LastOccurredTriggerToSF` records when financial changes that are relevant to CRM occurred, enabling SalesForce integration to know which customers to re-sync.

**Columns Involved**: `LastOccurredTriggerToSF`

**Rules**:
- Set to GETUTCDATE() during an upsert when ANY of these deltas are non-zero: TotalDepositDelta, TotalBonusDelta, TotalCashoutDelta, TotalCompensationDelta.
- If none of these changed (e.g., only login or position count updated), LastOccurredTriggerToSF is left unchanged.
- 62.6% of customers (4.215M) have this set - those with at least one deposit, bonus, withdrawal, or compensation event.
- Downstream SalesForce integration queries WHERE LastOccurredTriggerToSF > last-sync-time to find customers needing a CRM update.

### 2.3 First-Time Milestone Dates

**What**: Captures the first occurrence of three key customer milestones used for funnel analysis and marketing attribution.

**Columns Involved**: `FirstTimeCashierLoginDate`, `FirstTimeDepositAttemptDate`, `FirstTimeDepositSuccessDate`

**Rules**:
- These columns are set ONCE (when NULL) and never updated again - they record the customer's first-ever occurrence.
- `FirstTimeDepositAttemptDate`: First payment attempt date from Billing.Deposit (set when NULL AND attempt is within last 7 days of the check).
- `FirstTimeDepositSuccessDate`: First successful deposit date from Billing.Deposit (IsFTD=1, PaymentStatusID=2).
- `FirstTimeCashierLoginDate`: Originally calculated from Billing.Login. Calculation was REMOVED on 2023-05-30 (performance). The column is preserved but no longer updated from Billing.Login data; existing values remain.
- 65.3% of customers (4.397M) have FirstTimeDepositSuccessDate set (have made at least one deposit).

### 2.4 Realized Equity Tracking

**What**: Tracks the customer's most recently calculated realized equity (cash + closed P&L) and when it last changed.

**Columns Involved**: `LastRealizedEquity`, `RealizedEquityLastChange`

**Rules**:
- `LastRealizedEquity`: Sourced from Customer.CustomerMoney.RealizedEquity at the time of the upsert (since 05/09/2020 change by Ran Ovadia). Previously computed from credit history directly.
- `RealizedEquityLastChange`: Timestamp of the most recent credit event that triggered a realized equity recalculation. Taken as MAX(Occurred) from the credit batch being processed.
- If the incoming batch has no RealizedEquity value (NULL), the existing value in the table is preserved (ISNULL logic).
- 99.4% of rows (6.695M) have LastRealizedEquity populated.

### 2.5 Login Activity Aggregation

**What**: Tracks cumulative login count, total logged time, and most recent login metadata per customer.

**Columns Involved**: `TotalLoginCount`, `TotalLoggedTime`, `LastLoggedInOn`, `LastClientIp`

**Rules**:
- Login data sourced from dbo.SYN_STS_Audit_MIMO_GetUsersLogin_V (a synonym/view over the STS audit login system), joined to Customer.CustomerStatic for CID resolution.
- TotalLoginCount and TotalLoggedTime incremented per login batch.
- LastLoggedInOn: MAX of most recent login timestamp in the current batch (preserved if batch has no newer login).
- LastClientIp: Most recent IP address from the login event with the latest timestamp (extracted via STUFF(MAX(CONCAT(formatted-datetime, IP))...)). Masked with FUNCTION='default()' - BackOffice agents without elevated permissions see NULL.
- Note: TotalLoginCount and TotalLoggedTime appear as 0 for most rows in practice (the login aggregation pipeline may not have backfilled all historical data).

---

## 3. Data Overview

| CID | TotalDeposit | TotalCashout | TotalProfit | TotalPositionCount | Pattern |
|-----|-------------|-------------|-------------|-------------------|---------|
| (registered, no deposit) | 0.0000 | 0.0000 | 0.0000 | 0 | 38.3% of customers - created row but never funded |
| (funded, active trader) | >0 | varies | +/- | >0 | Core trading customers |
| (funded, no trades) | >0 | 0 | 0.0000 | 0 | Funded but never opened positions |
| (cashed out in full) | X | ~X | varies | >0 | TotalCashout approaches TotalDeposit + TotalProfit |

Platform-wide scale:
- 6.736M rows (one per CID) as of 2026-03-17
- 4.158M (61.7%) have TotalDeposit > 0
- 4.397M (65.3%) have FirstTimeDepositSuccessDate set
- 280,997 (4.2%) have TotalCashout > 0 (successfully withdrawn funds)
- 6,859 customers have TotalProfit > 0 (net profitable all-time)
- Max positions traded by one customer: 54,372
- Max logins for one customer: 6,727
- Table updated from 2017-03-16 (earliest LastUpdate) to live (most recent: 2026-03-17)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID (not group/GCID). Clustered PK. One row per account. Implicit FK to Customer.CustomerStatic.CID. |
| 2 | TotalProfit | decimal(34,4) | NO | 0 | VERIFIED | All-time cumulative net realized profit from closed trading positions. Summed from History.Position.NetProfit via CreditTypeID=4 events. Can be negative (net loss). |
| 3 | TotalDeposit | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of successful deposits (CreditTypeID=1 events). Gross deposit total before any withdrawals or fees. |
| 4 | TotalBonus | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of bonus credits received (CreditTypeID=7). Includes welcome bonuses, promo bonuses, and affiliate bonuses. |
| 5 | TotalInvestment | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of funds invested (locked) into open positions (CreditTypeID=3,13 negated to positive). Represents total capital committed to trading over customer lifetime. |
| 6 | TotalCommission | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of trading commissions charged on closed positions. Sourced from History.Position.CommissionOnClose. |
| 7 | TotalVolume | decimal(34,6) | YES | 0 | VERIFIED | All-time sum of trade volume in units (AmountInUnitsDecimal x UnitMargin from Trade.ProviderToInstrument). Used for VIP tier calculations and revenue analytics. Nullable - NULL in earliest rows before volume tracking was introduced. |
| 8 | TotalLot | decimal(34,6) | YES | 0 | VERIFIED | All-time sum of trading lots (LotCountDecimal). Standard lot-based volume measure used in forex/CFD trading. Nullable for legacy rows. |
| 9 | TotalChampWin | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of championship/tournament prize payouts received (CreditTypeID=5). eToro ran trading championships with cash prizes. |
| 10 | TotalCashout | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of successful withdrawal payments processed (CreditTypeID=2). Represents net cash returned to the customer. Distinct from TotalCashoutRequest (requests may not yet be processed). |
| 11 | TotalCashoutRequest | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of withdrawal requests submitted by the customer (CreditTypeID=9,15 negative). Represents the total amount the customer has requested to withdraw, regardless of approval status. |
| 12 | TotalReverseCashout | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of reversed/returned withdrawal amounts (CreditTypeID=8,15 positive). Occurs when a withdrawal is cancelled or clawed back after initial processing. |
| 13 | TotalCompensation | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of manual compensation payments credited by BackOffice agents (CreditTypeID=6). Covers goodwill payments, trade corrections, and regulatory settlements. |
| 14 | TotalGameCount | bigint | NO | 0 | CODE-BACKED | All-time count of game/contest participations. Always set to 0 in current upsert logic (TotalGameCount+0) - the column exists but the game activity tracking is no longer active. |
| 15 | TotalPositionCount | bigint | NO | 0 | VERIFIED | All-time count of trading positions opened and closed by the customer. Incremented by 1 per CreditTypeID=4 event (position close). |
| 16 | TotalLoginCount | bigint | NO | 0 | VERIFIED | All-time count of login sessions. Incremented from STS login audit data. |
| 17 | TotalLoggedTime | bigint | YES | 0 | CODE-BACKED | All-time total logged-in time in seconds. Sourced from login session duration data. NULL or 0 for most customers (backfill incomplete). |
| 18 | TotalEndOfWeekFee | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of end-of-week inactivity/weekend fees charged (CreditTypeID=14, negated to positive). Applied to open positions held over the weekend. |
| 19 | LastUpdate | datetime | NO | getdate() | VERIFIED | Timestamp of the most recent upsert to this row. Set to GETUTCDATE() on every write by UpsertIntoAggregationTablesAction. Used to detect stale rows. |
| 20 | FirstTimeCashierLoginDate | datetime | YES | - | CODE-BACKED | First time the customer accessed the cashier/deposit page. Originally populated from Billing.Login. Calculation REMOVED 2023-05-30 for performance. Existing values retained; new customers get NULL. Indexed for funnel reporting. |
| 21 | FirstTimeDepositAttemptDate | datetime | YES | - | VERIFIED | First time the customer attempted a deposit (first PaymentDate in Billing.Deposit). Set once when NULL. Indexed. Used for deposit funnel conversion analysis. |
| 22 | FirstTimeDepositSuccessDate | datetime | YES | - | VERIFIED | First time the customer successfully completed a deposit (first Billing.Deposit with IsFTD=1, PaymentStatusID=2). Set once when NULL. Indexed. NULL for 34.7% of customers who have never deposited. |
| 23 | LastOccurredTriggerToSF | datetime | YES | - | VERIFIED | Last time a deposit, bonus, cashout, or compensation event occurred - triggers SalesForce CRM re-sync. Set to GETUTCDATE() when any of these deltas are non-zero. NULL for customers with no financial events. Indexed for efficient SF sync polling. |
| 24 | LastLoggedInOn | datetime | YES | - | VERIFIED | Most recent login timestamp for this customer. Updated from STS login audit data on each run. NULL if no login data captured. |
| 25 | LastClientIp | varchar(20) | YES | - | VERIFIED | IP address of the customer's most recent login session. Dynamic data masking: MASKED WITH (FUNCTION = 'default()') - users without UNMASK permission see NULL. Varchar(20) to accommodate IPv6 short-form and port-appended values. |
| 26 | RealizedEquityLastChange | datetime | YES | - | VERIFIED | Timestamp of the most recent credit event that triggered a realized equity update. MAX(Occurred) from the processed credit batch. NULL if no realized equity event yet processed. |
| 27 | LastRealizedEquity | decimal(15,2) | YES | - | VERIFIED | Customer's realized equity (available cash balance + closed position P&L) as of the last update. Sourced directly from Customer.CustomerMoney.RealizedEquity since September 2020 (previously computed from credit history). 99.4% populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Account identity link |
| CID (via upsert join) | Customer.CustomerMoney | Implicit | LastRealizedEquity sourced here at upsert time |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerAllTimeAggregatedData | CID | VIEW WRAPPER | The view that exposes this table to all legacy consumers |
| BackOffice.UpsertIntoAggregationTablesAction | CID | WRITER/MODIFIER | Primary near-real-time upsert engine |
| BackOffice.GetCustomerHeader | CID | READER (via view) | Customer overview panel - shows TotalDeposit and TotalCashout |
| BackOffice.GetUserAdditionalDetails | CID | READER | Additional customer details with aggregates |
| BackOffice.GetRiskExposureReportPCIVersion | CID | READER | Risk exposure reporting |
| BackOffice.GetBlockedCustomers | CID | READER | Blocked customer list with financial totals |
| BackOffice.GetCashOutRequests_Main | CID | READER | Cashout queue - deposits vs cashout comparison |
| BackOffice.GetWithdrawRequests | CID | READER | Withdrawal requests with lifetime totals |
| BackOffice.NewRiskAlertsPCIVersion | CID | READER | Risk alert reporting |
| BackOffice.IsDepositUser | CID | READER | Checks if customer has ever deposited |
| BackOffice.GetTotalDepositsOfAllLinkedAccounts | CID | READER | Cross-account deposit totals |
| BackOffice.CustomerAcceptance | CID | READER | Customer acceptance workflow |
| BackOffice.SetRiskClassificationNew | CID | READER | AML scoring - uses TotalDeposit |
| BackOffice.GetPlayerLevel | CID | READER | VIP/player level calculation |
| DWH pipeline | CID | READER | Data lake feed (via BackOffice.CustomerAllTimeAggregatedData view) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerAllTimeAggregatedData_1 (table)
- No FK constraints (leaf table)
- Implicitly depends on:
  - Customer.CustomerStatic (CID scope)
  - Customer.CustomerMoney (LastRealizedEquity source)
  - History.ActiveCredit (event source, via UpsertIntoAggregationTablesAction)
  - Billing.Deposit (FTD milestone dates)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | CID population scope; GCID resolution in upsert |
| Customer.CustomerMoney | Table | LastRealizedEquity source at upsert time |
| History.ActiveCredit | Table | Credit event source for all financial deltas |
| Billing.Deposit | Table | FTD attempt and success date calculation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | View | WRAPPER - exposes this table to all readers |
| BackOffice.UpsertIntoAggregationTablesAction | Procedure | WRITER - sole data population mechanism |
| BackOffice.GetCustomerHeader | Procedure | READER - TotalDeposit, TotalCashout |
| BackOffice.GetRiskExposureReportPCIVersion | Procedure | READER - risk exposure analysis |
| BackOffice.GetBlockedCustomers | Procedure | READER - blocked customer financials |
| BackOffice.GetCashOutRequests_Main | Procedure | READER - withdrawal queue |
| BackOffice.NewRiskAlertsPCIVersion | Procedure | READER - alert reporting |
| BackOffice.SetRiskClassificationNew | Procedure | READER - AML scoring |
| BackOffice.IsDepositUser | Procedure | READER - deposit check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerAllTimeAggregatedData_New | CLUSTERED PK | CID ASC | - | - | Active |
| IDX_BCAD_FirstTimeCashierLoginDate_New | NC | FirstTimeCashierLoginDate ASC | CID | - | Active |
| IDX_BCAD_LastOccurredTriggerToSF | NC | LastOccurredTriggerToSF ASC | CID | - | Active (PAGE compressed) |
| IDX_BackOfficeCustomerAllTimeAggregatedData_FirstTimeDepositAttemptDate | NC | FirstTimeDepositAttemptDate ASC | - | - | Active (PAGE compressed) |
| IX_BCAD_FirstTimeDepositSuccessDate_New | NC | FirstTimeDepositSuccessDate ASC | CID | - | Active |

**Storage**: All data on [HISTORY] filegroup (except IDX_BCAD_FirstTimeCashierLoginDate_New on [MAIN]). DATA_COMPRESSION=PAGE on clustered PK and two NC indexes. FILLFACTOR=80 on PK and FirstTimeDepositSuccessDate NC index; FILLFACTOR=95 on LastOccurredTriggerToSF and FirstTimeDepositAttemptDate.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerAllTimeAggregatedData_New | PK | CID - one row per customer account |
| BCATAD_TOTALPROFIT_New | DEFAULT | TotalProfit = 0 |
| BCATAD_TOTALDEPOSIT_New | DEFAULT | TotalDeposit = 0 |
| BCATAD_TOTALBONUS_New | DEFAULT | TotalBonus = 0 |
| BCATAD_TOTALINVESTMENT_New | DEFAULT | TotalInvestment = 0 |
| BCATAD_TOTALCOMMISSION_New | DEFAULT | TotalCommission = 0 |
| BCATAD_TOTALVOLUME_New | DEFAULT | TotalVolume = 0 |
| BCATAD_TOTALLOT_New | DEFAULT | TotalLot = 0 |
| BCATAD_TOTALCHAMPWIN_New | DEFAULT | TotalChampWin = 0 |
| BCATAD_TOTALCASHOUT_New | DEFAULT | TotalCashout = 0 |
| BCATAD_TOTALCASHOUTREQUEST_New | DEFAULT | TotalCashoutRequest = 0 |
| BCATAD_TOTALREVERSECASHOUT_New | DEFAULT | TotalReverseCashout = 0 |
| BCATAD_TOTALCOMPENSATION_New | DEFAULT | TotalCompensation = 0 |
| BCATAD_TOTALGAMECOUNT_New | DEFAULT | TotalGameCount = 0 |
| BCATAD_TOTALPOSITIONCOUNT_New | DEFAULT | TotalPositionCount = 0 |
| BCATAD_TOTALLOGINCOUNT_New | DEFAULT | TotalLoginCount = 0 |
| BCATAD_TOTALLOGGEDTIME_New | DEFAULT | TotalLoggedTime = 0 |
| BCATAD_TOTALENDOFWEEKFEE_New | DEFAULT | TotalEndOfWeekFee = 0 |
| BCATAD_LASTUPDATE_New | DEFAULT | LastUpdate = getdate() |

### 7.3 Data Masking

| Column | Masking Function | Effect |
|--------|-----------------|--------|
| LastClientIp | default() | Users without UNMASK permission see NULL instead of the IP address |

---

## 8. Sample Queries

### 8.1 Get lifetime financial summary for a customer
```sql
SELECT
    a.CID,
    a.TotalDeposit,
    a.TotalCashout,
    a.TotalDeposit - a.TotalCashout AS NetFunding,
    a.TotalProfit,
    a.TotalBonus,
    a.TotalCompensation,
    a.TotalPositionCount,
    a.FirstTimeDepositSuccessDate AS FTDDate,
    a.LastLoggedInOn,
    a.LastRealizedEquity,
    a.LastUpdate
FROM BackOffice.CustomerAllTimeAggregatedData_1 a WITH (NOLOCK)
WHERE a.CID = 12345
```

### 8.2 Find customers eligible for SalesForce re-sync (updated since last poll)
```sql
SELECT
    a.CID,
    a.TotalDeposit,
    a.TotalCashout,
    a.TotalBonus,
    a.TotalCompensation,
    a.LastOccurredTriggerToSF
FROM BackOffice.CustomerAllTimeAggregatedData_1 a WITH (NOLOCK)
WHERE a.LastOccurredTriggerToSF > '2026-03-17 00:00:00'  -- replace with last sync time
ORDER BY a.LastOccurredTriggerToSF ASC
```

### 8.3 Deposit funnel conversion analysis
```sql
SELECT
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN FirstTimeDepositAttemptDate IS NOT NULL THEN 1 ELSE 0 END) AS AttemptedDeposit,
    SUM(CASE WHEN FirstTimeDepositSuccessDate IS NOT NULL THEN 1 ELSE 0 END) AS CompletedFTD,
    CAST(100.0 * SUM(CASE WHEN FirstTimeDepositSuccessDate IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN FirstTimeDepositAttemptDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS AttemptToFTDPct
FROM BackOffice.CustomerAllTimeAggregatedData_1 WITH (NOLOCK)
```

### 8.4 Top depositing customers (use BackOffice.CustomerAllTimeAggregatedData view for legacy compatibility)
```sql
SELECT TOP 100
    a.CID,
    a.TotalDeposit,
    a.TotalCashout,
    a.TotalProfit,
    a.TotalPositionCount,
    a.FirstTimeDepositSuccessDate
FROM BackOffice.CustomerAllTimeAggregatedData a WITH (NOLOCK)  -- uses the view
WHERE a.TotalDeposit > 0
ORDER BY a.TotalDeposit DESC
```

---

## 9. Atlassian Knowledge Sources

Confluence (BDP space): "DWH Process Data Sources" confirms BackOffice.CustomerAllTimeAggregatedData (view) is ingested by the DWH pipeline from server AZR-W-DBLS-4. PII data mapping doc references this table in the data lake pipeline.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.2/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerAllTimeAggregatedData_1 | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerAllTimeAggregatedData_1.sql*

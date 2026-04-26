# BI_DB_dbo.BI_DB_Outliers_New

**Schema**: BI_DB_dbo | **UC Target**: _Not_Migrated
**Row count**: ~6,552 total (2015-01-12 → 2026-04-07) | **Refresh**: daily, P99 FinanceReportSPS
**Distribution**: REPLICATE | **Structure**: HEAP

---

## 1. Business Meaning

Daily snapshot of customers whose **credit-report validity status** (`IsCreditReportValidCB`) changed between two consecutive days. For each such customer, the table records their **cumulative lifetime financial history** up to the day before the transition, enabling the finance team to reconcile the monetary exposure associated with clients gaining or losing credit-valid status.

One row = one customer × one transition day. A customer who transitions back and forth will appear once per transition. All 14 regulations are covered (BVI, CySEC, FCA, ASIC, eToroUS, FSRA, etc.) — this is not ASIC-specific.

**Sign convention**: When `CreditReportValid = 0` (customer became invalid), all financial amounts are **negated** (multiplied by −1). This allows summing the financial columns across all rows to compute net financial impact of validity changes. A positive value represents a valid→valid customer's amount; a negative value represents a now-invalid customer's amount.

**Key distinction from similar tables**: Amounts are **cumulative lifetime totals** up to (but not including) the transition day — not that day's transactions. This table answers "what was this transitioning customer's total financial history?" rather than "what happened today?".

---

## 2. Business Logic

### 2.1 Population Filter
The SP joins `Fact_SnapshotCustomer` for both today (`@ld`) and yesterday (`@ld_t2 = @ld - 1 day`), then filters `WHERE CurrStat ≠ PrevStat` where `CurrStat = IsCreditReportValidCB`. Only customers who **changed** credit validity are included. Customers stable in either direction are absent.

### 2.2 Financial Amounts Are Cumulative
All financial columns aggregate `Fact_CustomerAction.DateID <= @ld_t2` — the full customer history to the day before the transition. The table is not a daily delta table. A row on 2026-04-07 for a customer shows their total deposits/cashouts/etc. since account opening.

### 2.3 Sign-Flip Convention
For `CreditReportValid = 0` rows (customer transitioned to invalid), all 20 financial columns are multiplied by −1. The `[Cycle Calculation]` column (sum of all components) is also negated. This design means:
- Summing `[Cycle Calculation]` across all rows gives net balance impact of validity transitions
- Positive rows = customers who became valid (resources entering validity-scope)
- Negative rows = customers who became invalid (resources leaving validity-scope)

### 2.4 NULL vs 0 Semantics
Financial columns are NULL (not 0) when a customer has no history for that action type. The SP uses LEFT JOINs to each financial temp table, and NULLs propagate through the sign-flip CASE expression. A 0 value means the customer had activity but it netted to zero. Treat NULL and 0 differently when aggregating.

### 2.5 `[Unrealized Commission Change]` — Dead Column
The SP queries `Fact_CustomerUnrealized_PnL` for `CommissionOnOpen` but the result is discarded — the INSERT hardcodes `NULL` for `[Unrealized Commission Change]`. This column exists in the DDL but has never contained data in production.

### 2.6 DLT Outliers — Removed
SR-264692 (2024-07-30) added tracking for customers transitioning between eToro and DLT (real crypto subsidiary). SR-281275 (2024-11-18) removed this logic entirely. The `Transition` column only produces two values: 'Invalid to Valid' and 'Valid To Invalid'. The 'NA' case in the CASE statement is effectively unreachable.

---

## 3. Query Advisory

### 3.1 Bracket All Column Names
Most financial columns contain spaces: `[Deposit Amounts]`, `[Over The Weekend Fee]`, `[Cashout Amounts]`, etc. Always use bracket notation. `GivenBonus`, `Regulation`, `Transition`, `RealCID`, `CreditReportValid`, `Foreclosure` are the only names without spaces.

### 3.2 `CreditReportValid` Is varchar, Not Bit
The DDL declares `CreditReportValid varchar(50)`. It stores string '0' or '1'. Filter with `= '1'` or `= '0'`, not `= 1` or `= 0`.

### 3.3 `UpdateDate` Is varchar, Not datetime
`UpdateDate varchar(50)` stores datetime formatted as varchar (e.g., "Apr  8 2026  2:53AM"). Datetime functions like `DATEPART()` will fail on it. Use `[Date]` (date type) or `[DateID]` (int) for temporal filtering.

### 3.4 Skip `[Unrealized Commission Change]`
This column is always NULL. Do not use it in calculations or reports.

### 3.5 Table Is Very Small — REPLICATE Is Intentional
With only ~6,552 rows across 11 years, REPLICATE distribution is correct and efficient. No partition or date-range optimization is needed.

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| RealCID | int | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. | Tier 1 — DWH_dbo.Dim_Customer wiki | |
| Regulation | varchar(50) | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. | Tier 1 — DWH_dbo.Dim_Regulation wiki | 14 distinct values: BVI (70%), CySEC, eToroUS, FinCEN, FCA, ASIC+ASIC&GAML, FSRA, FSA Seychelles, NFA, FinCEN+FINRA, MAS, None, FINRAONLY |
| CreditReportValid | varchar(50) | Current-day value of IsCreditReportValidCB. '1' = credit-report valid (eligible for financial products), '0' = invalid. Stored as varchar despite being a 0/1 flag. | Tier 2 — SP code | Filter with = '1' / = '0' (string comparison) |
| Transition | varchar(50) | Direction of the credit-valid status change on this day. Values: 'Invalid to Valid' (customer regained validity), 'Valid To Invalid' (customer lost validity). | Tier 2 — SP code | 'NA' branch exists in CASE but is unreachable in production after DLT removal |
| [Deposit Amounts] | decimal(19,4) | Cumulative lifetime gross deposit amount (ActionTypeID=7) up to the day before the transition. Negated when CreditReportValid='0'. NULL when customer has no deposit history. | Tier 2 — SP code | Lifetime cumulative, not daily |
| [Compensation Deposit] | decimal(19,4) | Cumulative compensation classified as deposits (ActionTypeID=36, CompensationReasonID=7). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| GivenBonus | decimal(19,4) | Cumulative bonus amounts granted to customer (ActionTypeID=9). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Compensation] | decimal(19,4) | Cumulative general compensation (ActionTypeID=36, excluding specific sub-reason IDs for deposits, cashouts, affiliates, dormant, lost debt, foreclosure, PI, PnL adj, refill). Negated when CreditReportValid='0'. | Tier 2 — SP code | Broad category; see lineage for excluded CompensationReasonIDs |
| [Negative Refill Compensation] | decimal(19,4) | Cumulative negative refill compensation (ActionTypeID=36, CompensationReasonID=11). Negated when CreditReportValid='0'. | Tier 2 — SP code | DDL places this at position 29 but SP maps it to logical position 9 |
| [Compensation PI] | decimal(19,4) | Cumulative PI-related compensation (ActionTypeID=36, CompensationReasonID=41). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Compensation To Affiliates] | decimal(19,4) | Cumulative compensation passed to affiliates (ActionTypeID=36, CompensationReasonID IN 8,51,52). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Cashout Amounts] | decimal(19,4) | Cumulative lifetime withdrawal amounts (ActionTypeID=8). Negated when CreditReportValid='0'. NULL when customer has no withdrawal history. | Tier 2 — SP code | Lifetime cumulative |
| [Compensation Cashouts] | decimal(19,4) | Cumulative cashout-related compensation (ActionTypeID=36, CompensationReasonID=33). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Cashout Fee] | decimal(19,4) | Cumulative cashout/withdrawal fee charged (ActionTypeID=30, Commission field, already negated in SP). Stored as positive. Negated again when CreditReportValid='0'. | Tier 2 — SP code | Double negation: SP stores (-1×Commission); then (-1×(-1×Commission)) for invalid rows = positive |
| [Chargeback] | decimal(19,4) | Cumulative chargeback amounts (ActionTypeID IN 11,13). Negated when CreditReportValid='0'. | Tier 2 — SP code | ActionTypeIDs 11=chargeback, 13=chargeback reversal |
| [Refund] | decimal(19,4) | Cumulative refund amounts (ActionTypeID=12). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [ClientBalanceCommission] | decimal(19,4) | Cumulative broker commission deducted on closed positions (ActionTypeID IN 4,5,6,28,40, CommissionOnClose field, negated in SP). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Over The Weekend Fee] | decimal(19,4) | Cumulative overnight/weekend holding fees (ActionTypeID=35). Negated when CreditReportValid='0'. | Tier 2 — SP code | Also known as rollover fee |
| [Chargeback Loss] | decimal(19,4) | Cumulative negative balance from V_Liabilities where Liabilities<0 AND PlayerStatusID NOT IN (1,3,5,7) — non-standard status customers. Negated when CreditReportValid='0'. | Tier 2 — SP code | Computed from V_Liabilities snapshot at @ld_t2 |
| [Other Negative] | decimal(19,4) | Cumulative negative balance from V_Liabilities where Liabilities<0 AND PlayerStatusID IN (1,3,5,7) — standard status customers. Negated when CreditReportValid='0'. | Tier 2 — SP code | Complement of Chargeback Loss |
| [Compensation PnL Adjustment] | decimal(19,4) | Cumulative PnL adjustment compensation (ActionTypeID=36, CompensationReasonID=22). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Compensation DormantFee] | decimal(19,4) | Cumulative dormant account fee compensation (ActionTypeID=36, CompensationReasonID=30). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [ClientBalance Realized PnL] | decimal(19,4) | Cumulative realized profit/loss on closed positions (ActionTypeID IN 4,5,6,28,40, NetProfit field). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Unrealized Commission Change] | decimal(19,4) | Always NULL. Column reserved for unrealized commission change but SP hardcodes NULL — the CommissionOnOpen calculation from Fact_CustomerUnrealized_PnL is computed but discarded. | Tier 2 — SP code | Dead column — do not use |
| [Cycle Calculation] | decimal(19,4) | Net balance reconciliation: sum of all 20 financial components above. Represents the customer's net balance position at time of transition. Negated when CreditReportValid='0'. | Tier 2 — SP code | Excludes [Unrealized Commission Change] (NULL) |
| [Foreclosure] | decimal(19,4) | Cumulative foreclosure amounts (ActionTypeID=36, CompensationReasonID=32). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Lost Debt] | decimal(19,4) | Cumulative lost-debt write-off amounts (ActionTypeID=36, CompensationReasonID=31). Negated when CreditReportValid='0'. | Tier 2 — SP code | |
| [Date] | date | Processing date — the day on which the credit-valid status transition was detected. | Tier 2 — SP code | |
| [DateID] | int | YYYYMMDD integer representation of [Date]. | Tier 2 — SP code | |
| UpdateDate | varchar(50) | SP execution timestamp stored as varchar(50) string (e.g., "Apr  8 2026  2:53AM"). Cannot be used with datetime functions. Use [Date] for temporal filtering. | Propagation — ETL metadata | Unusual varchar type — see Query Advisory 3.3 |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Layer | Role |
|--------|-------|------|
| DWH_dbo.Fact_SnapshotCustomer | DWH fact | Customer daily snapshots — IsCreditReportValidCB (today + yesterday), RegulationID, PlayerStatusID |
| DWH_dbo.Dim_Regulation | DWH dimension | Regulation name lookup |
| DWH_dbo.Fact_CustomerAction | DWH fact | All financial action amounts — deposits, cashouts, compensations, fees, closed PnL |
| DWH_dbo.V_Liabilities | DWH view | Client balance snapshot — negative balance detection (ChargebackLoss, OtherNegative) |
| DWH_dbo.Fact_CustomerUnrealized_PnL | DWH fact | CommissionOnOpen — queried but not used in final INSERT |
| DWH_dbo.Dim_Range | DWH dimension | Date range bridge for SnapshotCustomer |
| DWH_dbo.Dim_Date | DWH dimension | Date key resolution |

### 5.2 ETL Pipeline

```
Fact_SnapshotCustomer (today)   ─┐  WHERE CurrStat ≠ PrevStat
Fact_SnapshotCustomer (yesterday)─┤  (IsCreditReportValidCB changed)
Dim_Regulation                  ─┘
           ↓
         #cid (transition customers + Regulation)
           ↓ (LEFT JOINs)
Fact_CustomerAction ──→ #Deposit, #Bonus, #Compensation,
                        #Cashouts, #CashoutFee, #Chargeback,
                        #Refund, #ClientBalanceCommission,
                        #OverTheWeekendFee, #ClientBalanceRealizedPnL
V_Liabilities       ──→ #Liabilities (ChargebackLoss / OtherNegative)
Fact_CustomerUnrealized_PnL ──→ #CommissionOnOpen (NOT used in INSERT)
           ↓
         #out (sign-flip CASE applied when CreditReportValid=0)
           ↓
DELETE WHERE DateID = @ld_t
INSERT INTO BI_DB_Outliers_New ← #out
```

---

## 6. Relationships

| Related Table | Join | Notes |
|--------------|------|-------|
| DWH_dbo.Dim_Customer | RealCID | Customer details lookup |
| DWH_dbo.Fact_SnapshotCustomer | RealCID, DateID | Source of population and status |
| DWH_dbo.Fact_CustomerAction | RealCID, DateID | Source of all financial amounts |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | RealCID, DateID | Daily client balance report — related but covers all clients, not just transitions |

---

## 7. Sample Queries

**Basic: get recent transitions with key financial fields**
```sql
SELECT TOP 20
    [Date],
    RealCID,
    Regulation,
    Transition,
    CreditReportValid,
    [Deposit Amounts],
    [Cashout Amounts],
    [Cycle Calculation]
FROM BI_DB_dbo.BI_DB_Outliers_New
WHERE [Date] >= '2026-01-01'
ORDER BY [Date] DESC, RealCID
```

**Aggregated: net financial impact of transitions by regulation and month**
```sql
SELECT
    YEAR([Date]) yr,
    MONTH([Date]) mo,
    Regulation,
    Transition,
    SUM(1) transitions,
    SUM([Cycle Calculation]) net_cycle_calc,
    SUM([Deposit Amounts]) net_deposits,
    SUM([Cashout Amounts]) net_cashouts
FROM BI_DB_dbo.BI_DB_Outliers_New
WHERE [Date] >= '2024-01-01'
GROUP BY YEAR([Date]), MONTH([Date]), Regulation, Transition
ORDER BY yr DESC, mo DESC, Regulation
```

**Count: transitions per month (trend analysis)**
```sql
SELECT
    YEAR([Date]) yr,
    MONTH([Date]) mo,
    SUM(CASE WHEN Transition = 'Invalid to Valid' THEN 1 ELSE 0 END) invalid_to_valid,
    SUM(CASE WHEN Transition = 'Valid To Invalid' THEN 1 ELSE 0 END) valid_to_invalid,
    SUM(1) total_transitions
FROM BI_DB_dbo.BI_DB_Outliers_New
GROUP BY YEAR([Date]), MONTH([Date])
ORDER BY yr DESC, mo DESC
```

---

## 8. Atlassian / Change History

| Reference | Date | Author | Change |
|-----------|------|--------|--------|
| Original | 2018-08-16 | Katy F | Initial creation — from ETORO_OLAP source |
| — | 2019-10-07 | Boris S | DateID filter updated to ≤ (was <) |
| — | 2020-05-20 | Boris S | Changed validity flag to IsCreditReportValidCB |
| SR-264692 | 2024-07-30 | Guy M | Added DLT transition outlier type (eToro↔DLT) |
| SR-281275 | 2024-11-18 | Guy M | Removed DLT outliers completely; Transition column reverts to credit-valid changes only |

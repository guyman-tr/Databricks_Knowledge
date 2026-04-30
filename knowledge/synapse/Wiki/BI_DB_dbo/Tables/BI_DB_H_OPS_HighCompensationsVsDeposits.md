# BI_DB_dbo.BI_DB_H_OPS_HighCompensationsVsDeposits

> Operations fraud-monitoring table flagging customers with suspiciously high compensation-to-deposit ratios (>50%) or excessive deposit frequency (>3 deposits in 24 hours via ACH/PWMB/Trustly/Sofort/Giropay). Currently 1 row; TRUNCATE+INSERT full refresh via SP_H_OPS_HighCompensationsVsDeposits. Last refreshed 2024-02-05 -- appears dormant.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (OPS Monitoring) |
| **Production Source** | SP_H_OPS_HighCompensationsVsDeposits (aggregates from External_etoro_Billing_Deposit + External_etoro_history_credit) |
| **Refresh** | Ad-hoc / scheduled (TRUNCATE+INSERT). Last run: 2024-02-05 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not documented_ |
| **UC Format** | _Not documented_ |
| **UC Partitioned By** | _Not documented_ |
| **UC Table Type** | _Not documented_ |

---

## 1. Business Meaning

`BI_DB_H_OPS_HighCompensationsVsDeposits` is an operations monitoring table that identifies customers who exhibit suspicious deposit-compensation patterns. It serves two detection use cases:

1. **High Compensation-to-Deposit Ratio**: Customers who received deposit adjustment compensations (CreditTypeID=6, CompensationReasonID=7) totalling more than $2,000 (negative payments) with more than 3 compensation events in the last 31 days, where the compensation amount exceeds 50% of their total approved deposit amount.

2. **Excessive Deposit Frequency**: Customers with more than 3 approved deposits in the last 24 hours via specific payment methods: ACH (29), PWMB (32), Trustly (35), Sofort (15), and Giropay (11).

Only customers with `IsValidCustomer=1` (from Dim_Customer) are included -- excluding Popular Investors, bonus-only accounts, and CountryID=250.

The table is populated via TRUNCATE+INSERT by `SP_H_OPS_HighCompensationsVsDeposits`, which creates temporary tables for depositors, compensation aggregates, deposit aggregates, and last deposit dates before assembling the final result. The SP calls `SP_Create_External_etoro_history_credit` to materialize credit history into `External_etoro_history_credit_Pavlina` before aggregating compensations.

Currently contains 1 row with last update 2024-02-05, suggesting the table is dormant or run infrequently.

---

## 2. Business Logic

### 2.1 High Compensation Detection

**What**: Flags customers whose deposit adjustment compensations exceed 50% of their total deposit amount.

**Columns Involved**: `CompensationAmount`, `DepositAmount$`, `Compensation$/Deposits$`

**Rules**:
- Look-back window: 31 days from current date for depositor identification
- Compensation filter: CreditTypeID=6 (Compensation), CompensationReasonID=7 (Deposit Adjustment), Payment<0
- Thresholds: COUNT(compensations) > 3 AND SUM(payments) < -$2,000
- Ratio threshold: CompensationAmount / DepositAmount$ > 0.5 (50%)
- CompensationAmount is stored as positive (negated from negative source payments)
- Only approved deposits (PaymentStatusID=2) are counted

### 2.2 Excessive 24-Hour Deposit Detection

**What**: Flags customers with more than 3 deposits in the last 24 hours via specific high-risk payment methods.

**Columns Involved**: `#OfDeposits24hrs`, `DepositAmount$24hrs`

**Rules**:
- Time window: last 24 hours (dateadd(day,-1,getdate()))
- Payment methods: ACH (FundingTypeID=29), PWMB (32), Trustly (35), Sofort (15), Giropay (11)
- Threshold: more than 3 deposits in 24hrs
- Joins to External_etoro_Billing_Funding_Datafactory for FundingTypeID resolution

### 2.3 Customer Validity Filter

**What**: Only valid customers are included in the monitoring output.

**Columns Involved**: `RealCID` (via Dim_Customer.IsValidCustomer)

**Rules**:
- IsValidCustomer=1: PlayerLevelID != 4 (not Popular Investor), LabelID NOT IN (30,26), CountryID != 250
- Customer status enrichment via Dim_PlayerStatus, Dim_PlayerStatusReasons, Dim_PlayerStatusSubReasons

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index. For a monitoring table with typically low row counts, this is appropriate. No distribution key optimization needed.

### 3.1b UC (Databricks) Storage & Partitioning

No UC target documented for this table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which customers have high compensation ratios? | `WHERE [Compensation$/Deposits$] > 0.5` |
| Which customers had excessive deposits in 24hrs? | `WHERE [#OfDeposits24hrs] > 3` |
| What is the total flagged deposit volume? | `SUM([DepositAmount$])` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.RealCID = h.RealCID | Full customer profile for flagged accounts |

### 3.4 Gotchas

- **Column names with special characters**: `#ofDeposits`, `#OfDeposits24hrs`, `DepositAmount$`, `DepositAmount$24hrs`, `Compensation$/Deposits$` all require square bracket quoting in queries.
- **CompensationAmount can be NULL**: When a customer is flagged only for the 24hr deposit frequency rule (not high compensation ratio), CompensationAmount and Compensation$/Deposits$ will be NULL.
- **DepositAmount$24hrs is varchar(max)**: Despite holding numeric values, this column is typed as varchar(max) in the DDL -- cast before arithmetic operations.
- **Table may be dormant**: Last update was 2024-02-05. Verify the SP is still scheduled before relying on this data.
- **TRUNCATE+INSERT**: Each SP run completely replaces all data. No historical tracking.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 — upstream wiki verbatim | (Tier 1 — {production source}) |
| *** | Tier 2 — SP code / ETL-computed | (Tier 2 — {source table}) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | CompensationAmount | money | YES | Total deposit adjustment compensation amount for the customer over the last 31 days. Computed as negated SUM of negative Payment values where CreditTypeID=6 (Compensation) and CompensationReasonID=7 (Deposit Adjustment), filtered to customers with >3 events and total <-$2,000. Stored as a positive value. NULL when customer is flagged only for 24hr deposit frequency. (Tier 2 — External_etoro_history_credit_Pavlina) |
| 3 | #ofDeposits | int | YES | Total count of approved deposits (PaymentStatusID=2) for this customer in the last 31 days. Only customers with positive total deposit amount are included. (Tier 2 — External_etoro_Billing_Deposit) |
| 4 | DepositAmount$ | money | YES | Total approved deposit amount in USD for this customer in the last 31 days. Computed as SUM(Amount * ExchangeRate) from approved deposits. Only positive totals are included. (Tier 2 — External_etoro_Billing_Deposit) |
| 5 | Compensation$/Deposits$ | decimal(18,0) | YES | Ratio of compensation amount to deposit amount (CompensationAmount / DepositAmount$). Customers are flagged when this ratio exceeds 0.5 (50%). NULL when CompensationAmount is NULL (customer flagged only for 24hr deposit frequency). (Tier 2 — External_etoro_history_credit_Pavlina / External_etoro_Billing_Deposit) |
| 6 | PlayerStatus | varchar(max) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Passthrough from Dim_PlayerStatus via Dim_Customer. (Tier 1 — Dictionary.PlayerStatus) |
| 7 | PlayerStatusReason | varchar(max) | YES | Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views. Passthrough from Dim_PlayerStatusReasons via Dim_Customer. (Tier 1 — Dictionary.PlayerStatusReasons) |
| 8 | PlayerStatusSubReason | varchar(max) | YES | Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). Passthrough from Dim_PlayerStatusSubReasons via Dim_Customer. (Tier 1 — Dictionary.PlayerStatusSubReasons) |
| 9 | LastDepositDate | datetime | YES | Date and time of the customer's most recent approved deposit (PaymentStatusID=2). Computed as MAX(ModificationDate) from External_etoro_Billing_Deposit. (Tier 2 — External_etoro_Billing_Deposit) |
| 10 | #OfDeposits24hrs | int | YES | Count of approved deposits in the last 24 hours via ACH (FundingTypeID=29), PWMB (32), Trustly (35), Sofort (15), or Giropay (11). 0 when the customer was flagged only for high compensation ratio (not for 24hr deposit frequency). (Tier 2 — External_etoro_Billing_Deposit) |
| 11 | UpdateDate | datetime | YES | ETL execution timestamp. Set to GETDATE() at the time SP_H_OPS_HighCompensationsVsDeposits runs. (Tier 2 — SP_H_OPS_HighCompensationsVsDeposits) |
| 12 | DepositAmount$24hrs | varchar(max) | YES | Total approved deposit amount in USD for the last 24 hours via ACH/PWMB/Trustly/Sofort/Giropay funding types. Computed as SUM(Amount * ExchangeRate). 0 when the customer was flagged only for high compensation ratio. Note: stored as varchar(max) despite holding numeric values -- cast before arithmetic. (Tier 2 — External_etoro_Billing_Deposit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | External_etoro_Billing_Deposit | CID | Rename CID → RealCID |
| CompensationAmount | External_etoro_history_credit_Pavlina | Payment | SUM(Payment) negated; filtered CreditTypeID=6, CompensationReasonID=7 |
| #ofDeposits | External_etoro_Billing_Deposit | DepositID | COUNT(DepositID) for approved deposits |
| DepositAmount$ | External_etoro_Billing_Deposit | Amount, ExchangeRate | SUM(Amount * ExchangeRate) |
| Compensation$/Deposits$ | (computed) | CompensationAmount, DepositAmount$ | -CompensationAmount / DepositAmount$ |
| PlayerStatus | Dictionary.PlayerStatus | Name | Passthrough via Dim_Customer → Dim_PlayerStatus |
| PlayerStatusReason | Dictionary.PlayerStatusReasons | Name | Passthrough via Dim_Customer → Dim_PlayerStatusReasons |
| PlayerStatusSubReason | Dictionary.PlayerStatusSubReasons | Name | Passthrough via Dim_Customer → Dim_PlayerStatusSubReasons; renamed PlayerStatusSubReasonName → PlayerStatusSubReason |
| LastDepositDate | External_etoro_Billing_Deposit | ModificationDate | MAX(ModificationDate) |
| #OfDeposits24hrs | External_etoro_Billing_Deposit | DepositID | COUNT(DepositID) for last 24hrs, specific funding types |
| UpdateDate | — | — | GETDATE() |
| DepositAmount$24hrs | External_etoro_Billing_Deposit | Amount, ExchangeRate | SUM(Amount * ExchangeRate) for last 24hrs, specific funding types |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit (production)
  -> External_etoro_Billing_Deposit (BI_DB external table)
  |
etoro.History.Credit (production)
  -> SP_Create_External_etoro_history_credit @dt, 'Pavlina'
  -> External_etoro_history_credit_Pavlina (BI_DB external table)
  |
  v
SP_H_OPS_HighCompensationsVsDeposits:
  Step 1: #dailydepositors — DISTINCT CIDs with approved deposits in last 31 days
  Step 2: #repeatdeposits1 — 24hr deposit counts via ACH/PWMB/Trustly/Sofort/Giropay
  Step 3: #repeatdeposits — filter to >3 deposits in 24hrs
  Step 4: SP_Create_External_etoro_history_credit → External_etoro_history_credit_Pavlina
  Step 5: #comps — compensation aggregates (CreditTypeID=6, CompensationReasonID=7, Payment<0)
  Step 6: #deps — deposit aggregates (COUNT + SUM for approved deposits)
  Step 7: #lastdeposit — MAX(ModificationDate) per CID
  Step 8: #FINAL — JOIN all temp tables + Dim_Customer + Dim_PlayerStatus dims
          WHERE ratio>0.5 OR deposits24hrs>3, AND IsValidCustomer=1
  Step 9: TRUNCATE + INSERT into BI_DB_H_OPS_HighCompensationsVsDeposits
  |
  v
BI_DB_dbo.BI_DB_H_OPS_HighCompensationsVsDeposits (1 row as of 2024-02-05)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension lookup (JOIN in SP on RealCID) |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Player status name (via Dim_Customer.PlayerStatusID) |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Status reason name (via Dim_Customer.PlayerStatusReasonID) |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason name (via Dim_Customer.PlayerStatusSubReasonID) |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers. This is a terminal OPS monitoring table.

---

## 7. Sample Queries

### 7.1 View all flagged customers with compensation details

```sql
SELECT [RealCID],
       [CompensationAmount],
       [DepositAmount$],
       [Compensation$/Deposits$],
       [PlayerStatus],
       [LastDepositDate],
       [#OfDeposits24hrs],
       [DepositAmount$24hrs]
FROM   [BI_DB_dbo].[BI_DB_H_OPS_HighCompensationsVsDeposits]
ORDER BY [Compensation$/Deposits$] DESC;
```

### 7.2 Find customers flagged for excessive 24hr deposits

```sql
SELECT [RealCID],
       [#OfDeposits24hrs],
       CAST([DepositAmount$24hrs] AS money) AS DepositAmount24hrs,
       [PlayerStatus]
FROM   [BI_DB_dbo].[BI_DB_H_OPS_HighCompensationsVsDeposits]
WHERE  [#OfDeposits24hrs] > 3
ORDER BY [#OfDeposits24hrs] DESC;
```

### 7.3 Join with Dim_Customer for full customer context

```sql
SELECT h.[RealCID],
       dc.UserName,
       dc.CountryID,
       dc.RegulationID,
       h.[CompensationAmount],
       h.[DepositAmount$],
       h.[Compensation$/Deposits$],
       h.[PlayerStatus]
FROM   [BI_DB_dbo].[BI_DB_H_OPS_HighCompensationsVsDeposits] h
JOIN   [DWH_dbo].[Dim_Customer] dc
       ON dc.RealCID = h.RealCID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-29 | Quality: 8.0/10 (****) | Phases: 11/14*
*Tiers: 4 T1, 8 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 12/12, Logic: 9/10, Relationships: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_H_OPS_HighCompensationsVsDeposits | Type: Table | Production Source: SP_H_OPS_HighCompensationsVsDeposits*

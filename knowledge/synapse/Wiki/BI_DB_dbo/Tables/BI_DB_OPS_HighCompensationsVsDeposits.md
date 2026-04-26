# BI_DB_dbo.BI_DB_OPS_HighCompensationsVsDeposits

> 3-row operational fraud monitoring table identifying customers with disproportionately high deposit-adjustment compensations relative to their total deposits (ratio > 50%, >3 compensations, total > $2,000) OR rapid deposit activity (>3 deposits in 24 hours via ACH/PWMB/Trustly/Sofort/Giropay). Sourced from External_etoro_Billing_Deposit + Fact_CustomerAction + Dim_Customer + 3 dim lookups. Daily TRUNCATE+INSERT via SP_OPS_HighCompensationsVsDeposits. Only IsValidCustomer=1.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Key Identifier** | RealCID (not enforced — no PK in DDL) |
| **Production Source** | SP_OPS_HighCompensationsVsDeposits |
| **Refresh** | Daily, TRUNCATE+INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | ~3 (highly filtered — only extreme cases) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Copy Strategy** | N/A |

---

## 1. Business Meaning

`BI_DB_OPS_HighCompensationsVsDeposits` is a daily operational monitoring table that flags customers who exhibit suspicious compensation-to-deposit patterns. It captures two distinct risk populations:

1. **High Compensation Ratio**: Customers who deposited in the last 31 days AND received >3 deposit-adjustment compensations (ActionTypeID=36, CompensationReasonID=7) totaling > $2,000 in absolute value, where the compensation-to-deposit ratio exceeds 50%. These are customers who are getting back a disproportionate amount of their deposits as compensations — a potential chargeback abuse or deposit fraud signal.

2. **Rapid Deposit Activity**: Customers with >3 deposits in the last 24 hours via specific instant-settlement payment methods (ACH=29, PWMB=32, Trustly=35, Sofort=15, Giropay=11). This captures potential deposit cycling or structuring behavior.

The table filters to IsValidCustomer=1 only (excludes Popular Investors, labels 30/26, CountryID=250). The SP runs daily with TRUNCATE+INSERT, meaning the table always reflects the current state of high-risk customers. In the current snapshot, only 3 customers qualify — all with 100% compensation-to-deposit ratio, Blocked or Warning status, with chargebacks or failed deposits.

---

## 2. Business Logic

### 2.1 Compensation Detection (High Ratio Path)

**What**: Identifies customers whose deposit-adjustment compensations exceed 50% of their total approved deposits.
**Columns Involved**: CompensationAmount, DepositAmount$, Compensation$/Deposits$
**Rules**:
- Only ActionTypeID=36 (Compensation) and CompensationReasonID=7 (Deposit Adjustment) from Fact_CustomerAction
- Only negative amounts (Amount < 0) — deductions from customer accounts
- HAVING COUNT > 3 (more than 3 compensation events)
- HAVING SUM < -$2,000 (total compensation exceeds $2,000 in magnitude)
- CompensationAmount is stored as positive (negated: -CompensationAmount)
- Ratio = CompensationAmount / DepositAmount$ — must exceed 0.5 (50%)
- Deposits use all-time approved deposits (no date filter), not just 31-day window

### 2.2 Rapid Deposit Detection (24-Hour Path)

**What**: Identifies customers making >3 deposits in 24 hours via instant-settlement methods.
**Columns Involved**: #OfDeposits24hrs, DepositAmount$24hrs
**Rules**:
- Only approved deposits (PaymentStatusID=2)
- Only specific FundingTypeIDs: 29 (ACH), 32 (PWMB/eToro Money), 35 (Trustly), 15 (Sofort), 11 (Giropay)
- ModificationDate >= DATEADD(day, -1, GETDATE()) — last 24 hours
- HAVING #OfDeposits24hrs > 3
- Customers qualify via this path even if their compensation ratio is below 50%

### 2.3 Inclusion Logic

**What**: The final table includes customers from EITHER path (OR logic).
**Rules**:
- `(-c.CompensationAmount / d.DepositAmount$) > 0.5` (high compensation ratio) OR `r.#OfDeposits24hrs > 3` (rapid deposits)
- AND `dc.IsValidCustomer = 1`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN HEAP**: No distribution key. With only ~3 rows, full table scan is instantaneous.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current high-risk customers | `SELECT * FROM BI_DB_OPS_HighCompensationsVsDeposits` (table is tiny) |
| Blocked customers with high compensation | `WHERE RTRIM(PlayerStatus) = 'Blocked'` |
| Rapid depositors | `WHERE [#OfDeposits24hrs] > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | dc.RealCID = hc.RealCID | Full customer profile |

### 3.4 Gotchas

- **PlayerStatus has trailing spaces**: Use `RTRIM(PlayerStatus)` or `LIKE 'Blocked%'`.
- **DepositAmount$24hrs is varchar(max)**: Despite storing numeric values, the DDL declares this as varchar(max). Use `CAST([DepositAmount$24hrs] AS MONEY)` for arithmetic.
- **Column names with special characters**: Columns `#ofDeposits`, `DepositAmount$`, `Compensation$/Deposits$`, `#OfDeposits24hrs`, `DepositAmount$24hrs` require bracket quoting in queries.
- **Very low row counts**: This table typically has single-digit rows. Zero rows is a healthy state.
- **Compensation ratio is truncated**: `Compensation$/Deposits$` is decimal(18,0) — rounded to integer. Current data shows all 1 (100%).
- **Category column discarded**: The SP computes a Category column ('HighCompensationToDeposits Ratio' vs '>3DepositsLast24hrs') but does NOT insert it — the reason for qualification is not stored.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 1 | Verbatim from upstream wiki (production source documented) | Upstream dimension wiki |
| Tier 2 | Derived from SP code analysis | SP_OPS_HighCompensationsVsDeposits |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. From #deps.CID (depositors in last 31 days). (Tier 1 -- Customer.CustomerStatic) |
| 2 | CompensationAmount | money | YES | Total absolute value of deposit-adjustment compensations (negated from negative Fact_CustomerAction.Amount). Only ActionTypeID=36 (Compensation), CompensationReasonID=7 (Deposit Adjustment), Amount<0, HAVING COUNT>3 AND SUM<-$2,000. NULL when customer qualifies only via rapid-deposit path. (Tier 2 -- SP_OPS_HighCompensationsVsDeposits) |
| 3 | #ofDeposits | int | YES | Total count of all-time approved deposits (PaymentStatusID=2) for this customer. Not date-filtered. (Tier 2 -- SP_OPS_HighCompensationsVsDeposits) |
| 4 | DepositAmount$ | money | YES | Total USD value of all-time approved deposits. Calculated as SUM(Amount * ExchangeRate) WHERE PaymentStatusID=2. Only customers with total > $0 are included. (Tier 2 -- SP_OPS_HighCompensationsVsDeposits) |
| 5 | Compensation$/Deposits$ | decimal(18,0) | YES | Ratio of CompensationAmount to DepositAmount$. Threshold: > 0.5 (50%) triggers inclusion. decimal(18,0) truncates to integer — a 75% ratio appears as 1. NULL when customer qualifies only via rapid-deposit path. (Tier 2 -- SP_OPS_HighCompensationsVsDeposits) |
| 6 | PlayerStatus | varchar(max) | YES | Human-readable restriction state label. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Dim-lookup passthrough from Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID. (Tier 1 -- Dictionary.PlayerStatus) |
| 7 | PlayerStatusReason | varchar(max) | YES | Human-readable reason label. Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Dim-lookup passthrough from Dim_PlayerStatusReasons.Name via Dim_Customer.PlayerStatusReasonID. (Tier 1 -- Dictionary.PlayerStatusReasons) |
| 8 | PlayerStatusSubReason | varchar(max) | YES | Human-readable sub-reason label (renamed from production Name). Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). Dim-lookup passthrough from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName via Dim_Customer.PlayerStatusSubReasonID. (Tier 1 -- Dictionary.PlayerStatusSubReasons) |
| 9 | LastDepositDate | datetime | YES | Most recent approved deposit date for this customer. MAX(ModificationDate) WHERE PaymentStatusID=2 from External_etoro_Billing_Deposit. (Tier 2 -- SP_OPS_HighCompensationsVsDeposits) |
| 10 | #OfDeposits24hrs | int | YES | Count of approved deposits in the last 24 hours via instant-settlement payment methods (ACH=29, PWMB=32, Trustly=35, Sofort=15, Giropay=11). ISNULL to 0 when no rapid deposits. (Tier 2 -- SP_OPS_HighCompensationsVsDeposits) |
| 11 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP execution time. Uniform across all rows (TRUNCATE+INSERT). (Tier 2 -- SP_OPS_HighCompensationsVsDeposits) |
| 12 | DepositAmount$24hrs | varchar(max) | YES | Total USD value of deposits in the last 24 hours via instant-settlement payment methods. Despite storing numeric data, DDL declares varchar(max). ISNULL to 0 when no rapid deposits. (Tier 2 -- SP_OPS_HighCompensationsVsDeposits) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| RealCID | Billing.Deposit (via External table) | CID | Passthrough (renamed) |
| CompensationAmount | Fact_CustomerAction | Amount | -SUM(Amount) WHERE ActionTypeID=36, CompensationReasonID=7 |
| PlayerStatus | Dictionary.PlayerStatus | Name (via Dim_PlayerStatus) | Dim-lookup passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.External_etoro_Billing_Deposit (PaymentStatusID=2, last 31 days)
  |-- #dailydepositors (distinct CIDs) ---|
  |
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=36, CompReasonID=7, Amount<0)
  |-- #comps (COUNT>3, SUM<-$2000) ---|
  |
  + External_etoro_Billing_Deposit (all-time approved)
  |-- #deps (COUNT deposits, SUM amount) ---|
  |
  + External_etoro_Billing_Deposit (last 24hrs)
  + External_etoro_Billing_Funding_Datafactory (FundingTypeID IN 29,32,35,15,11)
  |-- #repeatdeposits (>3 deposits in 24hrs) ---|
  |
  + DWH_dbo.Dim_Customer (IsValidCustomer=1)
  + DWH_dbo.Dim_PlayerStatus, Dim_PlayerStatusReasons, Dim_PlayerStatusSubReasons
  |-- #FINAL (ratio>0.5 OR rapid>3) ---|
  v
TRUNCATE BI_DB_dbo.BI_DB_OPS_HighCompensationsVsDeposits
INSERT FROM #FINAL (~3 rows)
  |
  UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension master |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Account restriction status |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Status change reason |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | Status change sub-reason |

### 6.2 Referenced By (other objects point to this)

No known consumers. Operational reporting endpoint.

---

## 7. Sample Queries

### 7.1 Current High-Risk Customers

```sql
SELECT
    RealCID,
    CompensationAmount,
    [DepositAmount$],
    [Compensation$/Deposits$] AS ratio_pct,
    RTRIM(PlayerStatus) AS status,
    PlayerStatusReason,
    PlayerStatusSubReason,
    [#OfDeposits24hrs],
    LastDepositDate
FROM BI_DB_dbo.BI_DB_OPS_HighCompensationsVsDeposits
ORDER BY CompensationAmount DESC
```

### 7.2 Join with Full Customer Profile

```sql
SELECT
    hc.RealCID,
    dc.FirstName, dc.LastName,
    hc.CompensationAmount,
    hc.[DepositAmount$],
    dc.CountryID,
    dc.RegulationID
FROM BI_DB_dbo.BI_DB_OPS_HighCompensationsVsDeposits hc
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = hc.RealCID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 4 T1, 8 T2, 0 T3, 0 T4, 0 T5 | Elements: 12/12, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_OPS_HighCompensationsVsDeposits | Type: Table | Production Source: SP_OPS_HighCompensationsVsDeposits*

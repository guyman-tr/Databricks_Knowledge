# BI_DB_dbo.BI_DB_RiskPayPalDepositors

> 1.69M-row risk/compliance profiling table for customers who deposited via PayPal (FundingTypeID=3), capturing their KYC, risk, and financial status on each deposit date. Sourced from DWH_dbo Fact_BillingDeposit joined with 10+ dimension tables. Daily DELETE+INSERT by ModificationDateID via SP_Risk_PayPalDepositors. Data from July 2023 to present across 1,000 distinct dates.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Risk_PayPalDepositors (BI_DB_dbo) |
| **Refresh** | Daily — DELETE+INSERT by ModificationDateID (one day per run) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_riskpaypaldepositors` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

This table profiles every eToro customer who deposited money via PayPal, enriched with their compliance and financial status at the time of deposit. Each row represents a unique CID on a specific ModificationDateID (deposit date), providing a daily snapshot of their KYC verification level, player status, risk flags, document status, phone verification, PEP screening, total equity, total deposits, number of distinct PayPal funding instruments, and whether they have an open cashout request.

The population is defined as customers with at least one PayPal deposit (FundingTypeID=3) on the given date, filtered to IsValidCustomer=1 (excluding PI, label 26/30, CountryID=250). The data spans from July 2023 (ModificationDateID=20230701) to April 2026, with approximately 1,690 CIDs per day across 1,000 processing dates.

The SP runs daily per @Date parameter. It first identifies the PayPal depositor population for that date, then enriches each CID with customer attributes from Dim_Customer, country/region from Dim_Country, compliance statuses from multiple Dictionary dimension tables, equity from V_Liabilities, and open cashout detection from External_etoro_Billing_Withdraw. Regulation distribution is heavily CySEC (90.3%), followed by FinCEN+FINRA (5.9%) and ASIC&GAML (3.2%).

---

## 2. Business Logic

### 2.1 Population Filter — PayPal Depositors Only

**What**: Only customers who made a PayPal deposit on the given date are included.
**Columns Involved**: CID, ModificationDateID
**Rules**:
- Fact_BillingDeposit WHERE FundingTypeID=3 (PayPal)
- Dim_Customer.IsValidCustomer=1 (excludes PI, labels 26/30, CountryID=250)
- One row per CID per ModificationDateID (DISTINCT)

### 2.2 Open Cashout Detection

**What**: Flags whether the customer has a pending/in-progress cashout withdrawal.
**Columns Involved**: OpenCashout
**Rules**:
- Checks External_etoro_Billing_Withdraw for CashoutStatusID IN (1=Pending, 2=InProcess, 5=Partially Processed, 14=Pending Review, 15=Under Review)
- 'Yes' if any qualifying open cashout exists, 'No' otherwise
- 98.5% of records show 'No' (no open cashout)

### 2.3 Total Equity Computation

**What**: Customer's total equity from V_Liabilities on the deposit date.
**Columns Involved**: TotalEquity
**Rules**:
- Computed as V_Liabilities.Liabilities + V_Liabilities.ActualNWA
- Joined on CID and DateID=@StartDateID
- NULL if no V_Liabilities record for that CID/date

### 2.4 Total Deposits — Lifetime PayPal

**What**: Lifetime total of approved PayPal deposits for this customer.
**Columns Involved**: TotalDeposits
**Rules**:
- SUM(Fact_BillingDeposit.AmountUSD) WHERE PaymentStatusID=2 (Approved)
- All-time (no date filter beyond population membership)
- NULL if no approved deposits found

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no distribution key. For CID-based queries, consider filtering by ModificationDateID first to limit scan scope.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PayPal depositors on a specific date | `WHERE ModificationDateID = 20260401` |
| High-equity PayPal users with open cashouts | `WHERE OpenCashout = 'Yes' AND TotalEquity > 10000` |
| PayPal depositor compliance profile | `GROUP BY DesignatedRegulation, RiskStatus, DocumentStatus` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Additional customer attributes |
| DWH_dbo.Fact_BillingDeposit | CID + ModificationDateID | Deposit transaction details |

### 3.4 Gotchas

- **RiskStatus can be empty string**: When External_etoro_BackOffice_CustomerRisk has no record for the customer (LEFT JOIN), the value is empty string, not NULL
- **TotalDeposits is lifetime total**: Not limited to the ModificationDateID window — it's the all-time sum of approved PayPal deposits
- **NumberOfPPfundingIDs counts all-time PayPal instruments**: DISTINCT FundingID across all PayPal deposits ever, not just on the current date
- **Data starts July 2023**: No records before ModificationDateID=20230701

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest — verified against production schema docs |
| Tier 2 | SP code analysis | High — derived from stored procedure logic |
| Tier 3 | Live data observation | Medium — inferred from query results |
| Tier 5 | ETL metadata | Standard ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_BillingDeposit (DISTINCT PayPal depositors). (Tier 1 — Billing.Deposit) |
| 2 | Country | varchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country via Dim_Customer.CountryID. (Tier 1 — Dictionary.Country) |
| 3 | City | varchar(max) | YES | City in Unicode. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | Region | varchar(max) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Passthrough from Dim_Country.MarketingRegionManualName. (Tier 3 — Ext_Dim_Country live data) |
| 5 | DesignatedRegulation | varchar(max) | YES | Short code for the regulation. Used in analytics dashboards. Values: CySEC (90.3%), FinCEN+FINRA (5.9%), ASIC&GAML (3.2%), FCA, ASIC, FSRA, FSA Seychelles, FinCEN. Passthrough from Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. (Tier 1 — Dictionary.Regulation) |
| 6 | DateOfRegistration | datetime | YES | Account registration date. Passthrough from Dim_Customer.RegisteredReal. (Tier 1 — Customer.CustomerStatic) |
| 7 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 8 | PlayerStatus | varchar(max) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Passthrough from Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID. (Tier 1 — Dictionary.PlayerStatus) |
| 9 | RiskStatus | varchar(max) | YES | Human-readable risk flag name. Mix of PascalCase codes and plain English (e.g., "Too Many PayPal Accounts", "WithdrawWithShortTermTrades"). Passthrough from Dim_RiskStatus.Name via External_etoro_BackOffice_CustomerRisk.RiskStatusID. Empty string when no risk record exists (LEFT JOIN). (Tier 1 — Dictionary.RiskStatus) |
| 10 | DocumentStatus | varchar(max) | YES | Human-readable document review status label. Used in compliance review UI, customer communications, and regulatory reporting. Passthrough from Dim_DocumentStatus.DocumentStatusName via Dim_Customer.DocumentStatusID. (Tier 1 — Dictionary.DocumentStatus) |
| 11 | PhoneVerifiedName | varchar(max) | YES | Human-readable verification state label. Note: ID=2 has value "ManualyVerified" — a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Passthrough from Dim_PhoneVerified via Dim_Customer.PhoneVerifiedID. (Tier 1 — Dictionary.PhoneVerified) |
| 12 | PEPStatus | varchar(max) | YES | Internal code name for the screening outcome. Passthrough from Dim_ScreeningStatus.Name via Dim_Customer.ScreeningStatusID. (Tier 3 — ScreeningService live data) |
| 13 | TotalEquity | money | YES | Customer total equity on the deposit date. Computed: V_Liabilities.Liabilities + V_Liabilities.ActualNWA. NULL if no V_Liabilities record. (Tier 2 — SP_Risk_PayPalDepositors) |
| 14 | TotalDeposits | money | YES | Lifetime total of approved deposits for this customer. Computed: SUM(Fact_BillingDeposit.AmountUSD) WHERE PaymentStatusID=2. All-time, not date-scoped. (Tier 2 — SP_Risk_PayPalDepositors) |
| 15 | NumberOfPPfundingIDs | int | YES | Count of distinct PayPal funding instruments (credit cards/accounts) used by this customer across all PayPal deposits ever. Computed: COUNT(DISTINCT FundingID) WHERE FundingTypeID=3. (Tier 2 — SP_Risk_PayPalDepositors) |
| 16 | OpenCashout | varchar(max) | YES | Whether customer has a pending/in-process cashout. 'Yes' if any open cashout exists (CashoutStatusID IN 1=Pending, 2=InProcess, 5=Partially Processed, 14=Pending Review, 15=Under Review), 'No' otherwise. 98.5% are 'No'. (Tier 2 — SP_Risk_PayPalDepositors) |
| 17 | ModificationDateID | int | YES | Integer YYYYMMDD date key from Fact_BillingDeposit.ModificationDateID. Partition key for DELETE+INSERT. Range: 20230701–20260412. (Tier 2 — SP_Risk_PayPalDepositors) |
| 18 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Billing.Deposit | CID | DISTINCT via Fact_BillingDeposit |
| Country | Dictionary.Country | Name | Dim-lookup passthrough |
| City | Customer.CustomerStatic | City | Passthrough via Dim_Customer |
| Region | Ext_Dim_Country | MarketingRegionManualName | Passthrough via Dim_Country |
| DesignatedRegulation | Dictionary.Regulation | Name | Dim-lookup passthrough |
| DateOfRegistration | Customer.CustomerStatic | Registered | Rename (RegisteredReal) |
| VerificationLevelID | BackOffice.Customer | VerificationLevelID | Passthrough via Dim_Customer |
| PlayerStatus | Dictionary.PlayerStatus | Name | Dim-lookup passthrough |
| RiskStatus | Dictionary.RiskStatus | Name | Dim-lookup passthrough |
| DocumentStatus | Dictionary.DocumentStatus | DocumentStatusName | Dim-lookup passthrough |
| PhoneVerifiedName | Dictionary.PhoneVerified | PhoneVerifiedName | Dim-lookup passthrough |
| PEPStatus | ScreeningService.Dictionary | Name | Dim-lookup passthrough |
| TotalEquity | V_Liabilities | Liabilities + ActualNWA | Computed |
| TotalDeposits | Billing.Deposit | AmountUSD | SUM(approved) |
| NumberOfPPfundingIDs | Billing.Deposit | FundingID | COUNT(DISTINCT PayPal) |
| OpenCashout | Billing.Withdraw | CashoutStatusID | CASE open/closed |
| ModificationDateID | Billing.Deposit | ModificationDate | INT conversion |
| UpdateDate | ETL | GETDATE() | Metadata |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit / Billing.Withdraw / BackOffice.CustomerRisk (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.Fact_BillingDeposit + Dim_Customer + Dim_Country + 8 Dim tables + V_Liabilities
  |-- SP_Risk_PayPalDepositors @Date (DELETE+INSERT by ModificationDateID) ---|
  v
BI_DB_dbo.BI_DB_RiskPayPalDepositors (1.69M rows)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_riskpaypaldepositors
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension — RealCID |
| Country | DWH_dbo.Dim_Country | Country name lookup |
| VerificationLevelID | Dictionary.VerificationLevel | KYC level |
| ModificationDateID | DWH_dbo.Dim_Date | Date dimension |

### 6.2 Referenced By (other objects point to this)

No known consumers in the documented wiki set.

---

## 7. Sample Queries

### 7.1 PayPal Depositors with Open Cashouts on a Date

```sql
SELECT CID, Country, Region, TotalEquity, TotalDeposits, OpenCashout
FROM BI_DB_dbo.BI_DB_RiskPayPalDepositors
WHERE ModificationDateID = 20260401
  AND OpenCashout = 'Yes'
ORDER BY TotalEquity DESC
```

### 7.2 Regulation Distribution of PayPal Depositors

```sql
SELECT DesignatedRegulation, COUNT(DISTINCT CID) AS unique_depositors
FROM BI_DB_dbo.BI_DB_RiskPayPalDepositors
WHERE ModificationDateID >= 20260101
GROUP BY DesignatedRegulation
ORDER BY unique_depositors DESC
```

### 7.3 High-Risk PayPal Depositors with Multiple Funding IDs

```sql
SELECT CID, Country, RiskStatus, NumberOfPPfundingIDs, TotalDeposits
FROM BI_DB_dbo.BI_DB_RiskPayPalDepositors
WHERE ModificationDateID = 20260401
  AND RiskStatus <> ''
  AND NumberOfPPfundingIDs >= 3
ORDER BY TotalDeposits DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 8 T1, 7 T2, 2 T3, 0 T4, 1 T5 | Elements: 18/18, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_RiskPayPalDepositors | Type: Table | Production Source: SP_Risk_PayPalDepositors*

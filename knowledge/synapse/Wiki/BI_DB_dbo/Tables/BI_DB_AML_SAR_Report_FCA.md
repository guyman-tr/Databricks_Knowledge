# BI_DB_dbo.BI_DB_AML_SAR_Report_FCA

> Daily point-in-time snapshot of 1,414,989 FCA-regulated eToro UK customers for Suspicious Activity Report (SAR) compliance under the Proceeds of Crime Act 2002 — capturing full KYC identity, address, document proof status, lifetime deposit/cashout activity, and SAR risk classification code (XXS99XX/XXGVTXX based on GBP equity > £3,000 threshold). Refreshed daily via TRUNCATE+INSERT by SP_AML_SAR_Report. No historical rows — SARDate is always the run date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (FCA only, via SP_AML_SAR_Report) |
| **Refresh** | Daily TRUNCATE+INSERT — SP_AML_SAR_Report @Date (Priority 20, SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only regulatory export |
| **Row Count** | 1,414,989 (as of 2026-04-13) |
| **PII Classification** | HIGH — contains FirstName, LastName, MiddleName, BirthDate, Phone, Email, Address, Zip, City, BuildingNumber |

---

## 1. Business Meaning

This table is the daily AML (Anti-Money Laundering) Suspicious Activity Report dataset for eToro's FCA (Financial Conduct Authority) regulated customers. It fulfils regulatory obligations under the UK **Proceeds of Crime Act 2002**, which requires financial firms to report suspicious customer activity to the National Crime Agency (NCA).

Each row represents **one FCA-regulated customer** (1,414,989 as of 2026-04-13) who meets all three criteria: verified (VerificationLevelID ≥ 2), a depositor (IsDepositor=1), and a valid account (IsValidCustomer=1) under FCA regulation (RegulationID=2). The table is a **full daily rebuild** — there is no historical data; SARDate always equals the SP run date.

The primary regulatory artefact is **SarCode**:
- **XXS99XX** (136,261 customers, ~9.6%): GBP equity > £3,000 — higher-value accounts that warrant elevated SAR scrutiny
- **XXGVTXX** (1,269,741 customers, ~89.8%): GBP equity ≤ £3,000
- **NULL** (~8,987 customers, ~0.6%): Equity not present in V_Liabilities for the run DateID

Multiple hardcoded fields reflect the legal framework: Source = 'eToro (UK) Limited', Disclosure_Type = 'Proceeds of Crime Act 2002', SourceOutlet = 'London', Currency = 'GBP (POUND STERLING)'.

CustomerStatus distribution in the FCA population: Normal (86%), Blocked (8%), Blocked Upon Request (4%), others (~2%). All seven PlayerStatus values appear, indicating this report covers all statuses — not just suspicious accounts. The FCA team filters rows by SarCode, PlayerStatus, and equity bands when submitting actual SARs.

The ETL reads occupation data from `BI_DB_KYC_Panel.Q18_AnswerText` (LEFT JOIN — NULL when customer hasn't completed KYC question 18).

---

## 2. Business Logic

### 2.1 SAR Risk Classification (SarCode)

**What**: Binary risk tier based on GBP-equivalent equity at the run date.  
**Columns Involved**: SarCode, TotalEquity, GBP_Equity  
**Rules**:
- TotalEquity = ISNULL(V_Liabilities.Liabilities, 0) + ISNULL(V_Liabilities.ActualNWA, 0)
- GBP_Equity = TotalEquity × (1 / Fact_CurrencyPriceWithSplit.Bid) where InstrumentID=2 (GBP/USD rate at @DateID)
- SarCode = 'XXS99XX' if GBP_Equity > 3000, else 'XXGVTXX'
- SarCode is NULL if the customer's CID is not in V_Liabilities for the run DateID (~8,987 rows)

### 2.2 FCA Customer Population Filter

**What**: Restricts the report to FCA-regulated verified depositors only.  
**Columns Involved**: Regulation (always 'FCA'), CID, GCID  
**Rules**:
- WHERE dc.RegulationID = 2 (FCA) — joins Dim_Regulation on DWHRegulationID=2
- AND dc.IsValidCustomer = 1
- AND dc.IsDepositor = 1
- AND dc.VerificationLevelID >= 2 (at least basic verification completed)
- DISTINCT in the final SELECT — one row per CID guaranteed

### 2.3 Transaction Aggregation (Method of Payment)

**What**: Rolls up all-time deposit and cashout activity to a single most-common MOP per customer.  
**Columns Involved**: NumOfMOP_CO, TypeCO, MOP_CO, TotalCO, NumOfMOP_Deposit, TypeDep, MOP_Dep, TotalDeposit_POUND  
**Rules**:
- Deposits: PaymentStatusID=2 (Approved) from Fact_BillingDeposit — ALL TIME (no date filter)
- Cashouts: CashoutStatusID=3 (Approved) — uses ISNULL(CashoutStatusID_Funding, CashoutStatusID_Withdraw)
- Most common MOP selected via ROW_NUMBER() OVER (PARTITION BY CID ORDER BY NumOfMOP DESC) = 1
- TotalCO uses SUM(DISTINCT ISNULL(Amount_WithdrawToFunding, Amount_Withdraw)) — deduplication via DISTINCT
- TypeCO hardcoded 'Debit'; TypeDep hardcoded 'Credit'

### 2.4 Age Computation

**What**: Calculates customer age at run time, handling the sentinel birth year 1900.  
**Columns Involved**: Age, BirthDate  
**Rules**:
- Age = DATEDIFF(YEAR, BirthDate, GETDATE())
- If YEAR(BirthDate) = 1900 → Age = NULL (sentinel for unknown date of birth)

### 2.5 Hardcoded Regulatory Fields

**What**: Static regulatory metadata embedded by the SP for FCA reporting format.  
**Columns Involved**: Source, Currency, Disclosure_Type, Consent_Required, SourceOutlet, AddressType, CurrentAddress, SARDate  
**Rules**:
- Source = 'eToro (UK) Limited' (FCA-registered legal entity)
- Currency = 'GBP (POUND STERLING)' (reporting currency)
- Disclosure_Type = 'Proceeds of Crime Act 2002' (legal framework)
- Consent_Required = 'Y / N' (placeholder — regulatory form field, always the same string)
- SourceOutlet = 'London' (FCA jurisdiction office)
- AddressType = 'Home Address' (all customer addresses treated as home)
- CurrentAddress = 'Y' (hardcoded — no historical address tracking)
- SARDate = CAST(GETDATE() AS DATE) — always the SP run date, not a business event date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no distribution key advantage. Full table scans on all queries. With 1.41M rows, full scans are manageable but avoid unindexed range queries on text columns.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| High-equity FCA customers for SAR filing | `WHERE SarCode = 'XXS99XX'` (136K rows) |
| Customers by player status for review | `WHERE PlayerStatus = 'Blocked'` |
| Customers with significant cashout activity | `ORDER BY TotalCO DESC` |
| Customers by occupation sector | `WHERE Occupation LIKE '%Finance%'` |
| Total deposits per player tier (Club) | `GROUP BY Club ORDER BY SUM(TotalDeposit_POUND) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Enrich with additional customer attributes not in SAR table |
| DWH_dbo.Dim_Position | `CID = CID` | Trading position history for SAR narrative |
| BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | `CID = CID` | AML status change audit trail |

### 3.4 Gotchas

- **SARDate is always the run date** — not a business event date. Do not use SARDate for temporal filtering; all historical analysis must be done on other tables.
- **No primary key enforced** — CID is unique de facto (DISTINCT in SP) but no constraint prevents duplicates on re-runs.
- **MOP aggregation picks most common, not most recent** — TotalCO/TotalDeposit_POUND are ALL-TIME sums but MOP_CO/MOP_Dep reflect the most frequently used method.
- **SUM(DISTINCT ...)  on TotalCO** — DISTINCT de-duplicates identical withdrawal amounts; may under-count if two separate cashouts have the exact same amount.
- **NULL SarCode** — ~8,987 rows lack equity data (not in V_Liabilities for @DateID). These customers are still FCA-verified depositors; their equity was simply not available in the snapshot.
- **Gender values expanded** — Dim_Customer stores 'M'/'F'/'U' but this table stores 'Male'/'Female'/'Unknown'; do not JOIN on gender string values between tables.
- **TotalDeposit_POUND is in USD** — despite the column name "POUND", the amounts come from Fact_BillingDeposit.Amount which is in USD. The naming is a legacy inconsistency in the SP.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (Customer.CustomerStatic or DWH_dbo wiki). Origin source is authoritative. |
| Tier 2 | Derived from SP code analysis, DWH transformation, or DWH-level join/computation. |
| Tier 4 | Inferred from column name and context; no upstream wiki match. |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. DWH note: mapped from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | NO | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | AccountType | nvarchar(500) | YES | Account type name from Dim_AccountType. Values: Private (99.9%), Corporate, Joint Account, Funded Employee Account, Administrated Account, Affiliate Corporate Account, Analyst. (Tier 2 — SP_AML_SAR_Report) |
| 4 | BirthDate | datetime | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 5 | Age | int | YES | Customer age in whole years as of run date: DATEDIFF(YEAR, BirthDate, GETDATE()). NULL if YEAR(BirthDate) = 1900 (sentinel for unknown date of birth). (Tier 2 — SP_AML_SAR_Report) |
| 6 | Regulation | nvarchar(500) | YES | Regulation name. Always 'FCA' in this table — population is filtered to DWHRegulationID=2. (Tier 2 — SP_AML_SAR_Report) |
| 7 | FirstName | nvarchar(500) | YES | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 8 | LastName | nvarchar(500) | YES | Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 9 | MiddleName | nvarchar(500) | YES | Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 — Customer.CustomerStatic) |
| 10 | FullName | nvarchar(500) | YES | Concatenated full name: FirstName + ' ' + MiddleName + ' ' + LastName. Will include extra spaces when MiddleName is empty. (Tier 2 — SP_AML_SAR_Report) |
| 11 | Gender | nvarchar(500) | YES | Gender expanded to full word: 'Female' (source='F'), 'Male' (source='M'), 'Unknown' (source='U' or other). DWH note: Dim_Customer stores single-char 'M'/'F'/'U'. (Tier 1 — Customer.CustomerStatic) |
| 12 | Zip | nvarchar(500) | YES | Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 13 | Address | nvarchar(500) | YES | Street address in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 14 | AddressType | nvarchar(500) | YES | Hardcoded 'Home Address' for all rows — SP treats all customer addresses as home addresses. (Tier 2 — SP_AML_SAR_Report) |
| 15 | CurrentAddress | nvarchar(500) | YES | Hardcoded 'Y' for all rows — SP assumes all on-file addresses are current. (Tier 2 — SP_AML_SAR_Report) |
| 16 | BuildingNumber | nvarchar(500) | YES | Building/apartment number. Separate from Address for structured address storage. (Tier 1 — Customer.CustomerStatic) |
| 17 | City | nvarchar(500) | YES | City in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 18 | Country | nvarchar(500) | YES | Country name resolved from Dim_Country (JOIN on dc.CountryID = dc1.DWHCountryID). (Tier 2 — SP_AML_SAR_Report) |
| 19 | IsIDProof | int | YES | Whether ID proof document is on file (1=yes, 0=no). NULL for ~56% of customers who have no proof record. Updated from BackOffice.CustomerDocument via SP_Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 20 | POI_Expiry_Date | datetime | YES | Proof of Identity document expiry date. Renamed from Dim_Customer.IsIDProofExpiryDate. NULL if no ID proof on file. (Tier 2 — SP_Dim_Customer) |
| 21 | IsAddressProof | int | YES | Whether address proof document is on file (1=yes, 0=no). Updated from BackOffice.CustomerDocument. (Tier 2 — SP_Dim_Customer) |
| 22 | POA_Expiry_Date | datetime | YES | Proof of Address document expiry date. Renamed from Dim_Customer.IsAddressProofExpiryDate. NULL if no address proof on file. (Tier 2 — SP_Dim_Customer) |
| 23 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 24 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 25 | FirstDepositAmount | money | YES | Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer) |
| 26 | PlayerStatus | nvarchar(500) | YES | Customer account status from Dim_PlayerStatus. Values: Normal (86%), Blocked (8%), Blocked Upon Request (4%), Pending Verification (0.8%), Block Deposit & Trading (0.7%), Trade & MIMO Blocked (0.2%), Deposit Blocked (0.1%), Warning (0.07%), Copy Block (<0.1%). (Tier 2 — SP_AML_SAR_Report) |
| 27 | Club | nvarchar(500) | YES | Customer loyalty tier (PlayerLevel) from Dim_PlayerLevel. Values: Bronze (85%), Silver (5%), Gold (5%), Platinum (3%), Platinum Plus (2%), Diamond (<1%). (Tier 2 — SP_AML_SAR_Report) |
| 28 | Occupation | nvarchar(500) | YES | Customer-stated occupation from KYC questionnaire question 18 (free-text). LEFT JOIN on BI_DB_KYC_Panel.Q18_AnswerText — NULL if customer did not complete question 18. (Tier 4 — BI_DB_KYC_Panel) |
| 29 | SourceRef | nvarchar(500) | YES | Regulatory reference field — same value as CID (dc.RealCID). Used in SAR submission forms as the source reference number identifying the eToro account. (Tier 1 — Customer.CustomerStatic) |
| 30 | SARDate | date | YES | Date of the SAR report. Always equals CAST(GETDATE() AS DATE) at SP execution time — the run date, not a business event date. (Tier 2 — SP_AML_SAR_Report) |
| 31 | Source | nvarchar(500) | YES | Hardcoded reporting entity name. Always 'eToro (UK) Limited' — the FCA-registered UK legal entity. (Tier 2 — SP_AML_SAR_Report) |
| 32 | Currency | nvarchar(500) | YES | Hardcoded reporting currency. Always 'GBP (POUND STERLING)' for FCA regulatory submissions. (Tier 2 — SP_AML_SAR_Report) |
| 33 | DisclosedAccountName | nvarchar(500) | YES | Full name repeated for regulatory disclosure form: FirstName + ' ' + MiddleName + ' ' + LastName. Identical to FullName computation. (Tier 2 — SP_AML_SAR_Report) |
| 34 | Consent_Required | nvarchar(500) | YES | Hardcoded regulatory placeholder 'Y / N' — indicates that consent status must be determined per SAR submission. Not a per-row flag. (Tier 2 — SP_AML_SAR_Report) |
| 35 | Disclosure_Type | nvarchar(500) | YES | Legal framework citation. Always 'Proceeds of Crime Act 2002' — the UK statute requiring SAR filing. (Tier 2 — SP_AML_SAR_Report) |
| 36 | SourceOutlet | nvarchar(500) | YES | Hardcoded office location. Always 'London' — the FCA's jurisdiction location for eToro UK. (Tier 2 — SP_AML_SAR_Report) |
| 37 | NumOfMOP_CO | int | YES | Count of approved cashout transactions by method of payment for this CID (all time, CashoutStatusID=3). (Tier 2 — SP_AML_SAR_Report) |
| 38 | TypeCO | nvarchar(500) | YES | Hardcoded cashout transaction type. Always 'Debit'. (Tier 2 — SP_AML_SAR_Report) |
| 39 | MOP_CO | nvarchar(500) | YES | Most frequently used cashout method of payment name (from Dim_FundingType). Selected by ROW_NUMBER OVER (PARTITION BY CID ORDER BY NumOfMOP DESC) = 1. NULL if no cashouts. Common values: eToroMoney, CreditCard, etc. (Tier 2 — SP_AML_SAR_Report) |
| 40 | TotalCO | money | YES | Total approved cashout amount (all time). SUM(DISTINCT ISNULL(Amount_WithdrawToFunding, Amount_Withdraw)) from Fact_BillingWithdraw where CashoutStatusID=3. (Tier 2 — SP_AML_SAR_Report) |
| 41 | NumOfMOP_Deposit | int | YES | Count of approved deposit transactions by method of payment for this CID (all time, PaymentStatusID=2). (Tier 2 — SP_AML_SAR_Report) |
| 42 | TypeDep | nvarchar(500) | YES | Hardcoded deposit transaction type. Always 'Credit'. (Tier 2 — SP_AML_SAR_Report) |
| 43 | MOP_Dep | nvarchar(500) | YES | Most frequently used deposit method of payment name (from Dim_FundingType). Selected by ROW_NUMBER OVER (PARTITION BY CID ORDER BY NumOfMOP_Deposit DESC) = 1. NULL if no deposits. Common values: CreditCard, eToroMoney, etc. (Tier 2 — SP_AML_SAR_Report) |
| 44 | TotalDeposit_POUND | money | YES | Total approved deposit amount (all time). SUM(fbd.Amount) where PaymentStatusID=2 from Fact_BillingDeposit. NOTE: Amount is in USD despite the column name "POUND" — naming is a legacy inconsistency. (Tier 2 — SP_AML_SAR_Report) |
| 45 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at SP execution time. Same value for all rows in a given run. (Tier 2 — SP_AML_SAR_Report) |
| 46 | Phone | nvarchar(500) | YES | Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic) |
| 47 | Email | nvarchar(500) | YES | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic) |
| 48 | SarCode | nvarchar(500) | YES | SAR risk tier code: 'XXS99XX' = GBP_Equity > £3,000 (136,261 customers); 'XXGVTXX' = GBP_Equity ≤ £3,000 (1,269,741 customers); NULL = no equity record for @DateID (~8,987 customers). (Tier 2 — SP_AML_SAR_Report) |
| 49 | TotalEquity | money | YES | Total equity at run date: ISNULL(V_Liabilities.Liabilities, 0) + ISNULL(V_Liabilities.ActualNWA, 0). In USD. NULL if CID not found in V_Liabilities for @DateID. (Tier 2 — SP_AML_SAR_Report) |
| 50 | GBP_Equity | money | YES | TotalEquity converted to GBP: TotalEquity × (1 / GBP_USD bid price from Fact_CurrencyPriceWithSplit where InstrumentID=2 and OccurredDateID = @DateID). Used to determine SarCode threshold. (Tier 2 — SP_AML_SAR_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Passthrough via Dim_Customer.RealCID |
| GCID | Customer.CustomerStatic | GCID | Passthrough via Dim_Customer |
| BirthDate, FirstName, LastName, MiddleName | Customer.CustomerStatic | Same | Passthrough via Dim_Customer |
| Gender | Customer.CustomerStatic | Gender | CASE: 'F'→'Female', 'M'→'Male', else 'Unknown' |
| Zip, Address, BuildingNumber, City | Customer.CustomerStatic | Same | Passthrough via Dim_Customer |
| Phone, Email | Customer.CustomerStatic | Same | Passthrough via Dim_Customer |
| RegisteredReal | Customer.CustomerStatic | Registered | Passthrough via Dim_Customer (renamed) |
| IsIDProof, POI_Expiry_Date, IsAddressProof, POA_Expiry_Date | BackOffice.CustomerDocument | — | Via SP_Dim_Customer |
| TotalEquity, GBP_Equity, SarCode | DWH_dbo.V_Liabilities + Fact_CurrencyPriceWithSplit | Liabilities, ActualNWA, Bid | Equity computation + GBP conversion |
| NumOfMOP_CO, MOP_CO, TotalCO | DWH_dbo.Fact_BillingWithdraw + Dim_FundingType | Amount, Name | Aggregated by CID |
| NumOfMOP_Deposit, MOP_Dep, TotalDeposit_POUND | DWH_dbo.Fact_BillingDeposit + Dim_FundingType | Amount, Name | Aggregated by CID |
| Occupation | BI_DB_dbo.BI_DB_KYC_Panel | Q18_AnswerText | LEFT JOIN on RealCID |

### 5.2 ETL Pipeline

```
Customer.CustomerStatic (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) --|
  v
DWH_dbo.Dim_Customer [FCA filter: RegulationID=2, IsDepositor=1, VerificationLevelID>=2]
  +
DWH_dbo.Dim_Country, Dim_Regulation, Dim_PlayerLevel, Dim_PlayerStatus, Dim_AccountType, Dim_FundingType
  +
DWH_dbo.Fact_BillingDeposit (all-time approved deposits per CID)
DWH_dbo.Fact_BillingWithdraw (all-time approved cashouts per CID)
  +
DWH_dbo.V_Liabilities (equity snapshot for @DateID)
DWH_dbo.Fact_CurrencyPriceWithSplit (GBP/USD rate for @DateID, InstrumentID=2)
  +
BI_DB_dbo.BI_DB_KYC_Panel (Occupation / Q18_AnswerText)
  |-- SP_AML_SAR_Report @Date (TRUNCATE+INSERT daily, SB_Daily, Priority 20) --|
  v
BI_DB_dbo.BI_DB_AML_SAR_Report_FCA
(1,414,989 rows, ROUND_ROBIN HEAP)
  |-- _Not_Migrated (Synapse-only regulatory export) --|
```

---

## 6. Relationships

### 6.1 References To (this table reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID / GCID | DWH_dbo.Dim_Customer | Primary source — FCA customer profiles |
| Country | DWH_dbo.Dim_Country | Country name resolution |
| Regulation | DWH_dbo.Dim_Regulation | FCA regulation name (always RegulationID=2) |
| Club | DWH_dbo.Dim_PlayerLevel | Loyalty tier name |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Account status name |
| AccountType | DWH_dbo.Dim_AccountType | Account type name |
| MOP_CO, MOP_Dep | DWH_dbo.Dim_FundingType | Payment method names |
| TotalDeposit_POUND, NumOfMOP_Deposit | DWH_dbo.Fact_BillingDeposit | All-time approved deposits |
| TotalCO, NumOfMOP_CO | DWH_dbo.Fact_BillingWithdraw | All-time approved cashouts |
| TotalEquity, GBP_Equity, SarCode | DWH_dbo.V_Liabilities | Daily equity snapshot |
| GBP_Equity | DWH_dbo.Fact_CurrencyPriceWithSplit | GBP/USD exchange rate |
| Occupation | BI_DB_dbo.BI_DB_KYC_Panel | KYC question 18 answer |

### 6.2 Referenced By (other objects read from this table)

No stored procedures or views in the SSDT repo reference this table. It is a terminal export table consumed directly by the AML compliance team and regulatory reporting tools.

---

## 7. Sample Queries

### High-Equity FCA Customers (SAR Filing Candidates)

```sql
-- XXS99XX: GBP equity > £3,000 — primary SAR filing population
SELECT
    CID,
    FullName,
    Country,
    PlayerStatus,
    TotalDeposit_POUND,
    TotalCO,
    GBP_Equity,
    SarCode
FROM [BI_DB_dbo].[BI_DB_AML_SAR_Report_FCA]
WHERE SarCode = 'XXS99XX'
ORDER BY GBP_Equity DESC;
```

### FCA Population by Status and Club Tier

```sql
-- Distribution of player status and loyalty tier in the FCA SAR population
SELECT
    PlayerStatus,
    Club,
    COUNT(*) AS CustomerCount,
    AVG(GBP_Equity) AS AvgGBPEquity,
    SUM(TotalDeposit_POUND) AS TotalLifetimeDeposits
FROM [BI_DB_dbo].[BI_DB_AML_SAR_Report_FCA]
GROUP BY PlayerStatus, Club
ORDER BY PlayerStatus, Club;
```

### Customers with KYC Proof Gaps

```sql
-- Customers lacking ID proof or address proof (may need follow-up for SAR)
SELECT
    CID,
    FullName,
    Email,
    Country,
    IsIDProof,
    POI_Expiry_Date,
    IsAddressProof,
    POA_Expiry_Date,
    GBP_Equity,
    SarCode
FROM [BI_DB_dbo].[BI_DB_AML_SAR_Report_FCA]
WHERE (IsIDProof = 0 OR IsIDProof IS NULL
    OR IsAddressProof = 0 OR IsAddressProof IS NULL)
    AND SarCode = 'XXS99XX'
ORDER BY GBP_Equity DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources queried for this object. This is a regulatory compliance table operating under the Proceeds of Crime Act 2002 (UK). Context is derived from SP code and regulatory framework knowledge.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14*  
*Tiers: 15 T1, 34 T2, 0 T3, 1 T4, 0 T5 | Elements: 50/50, Logic: 9/10, Sources: 8/10*  
*Object: BI_DB_dbo.BI_DB_AML_SAR_Report_FCA | Type: Table | Production Source: DWH_dbo.Dim_Customer (FCA, via SP_AML_SAR_Report)*

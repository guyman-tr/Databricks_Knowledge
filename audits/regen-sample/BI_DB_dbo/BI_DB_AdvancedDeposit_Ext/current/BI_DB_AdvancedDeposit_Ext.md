# BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

> **DORMANT TABLE — 0 rows.** Extended deposit analysis table with 47 columns combining deposit transaction details (DepositID, Amount, FundingType, PaymentStatus), customer demographics (Country, Region, Channel), acquisition attribution (Funnel, SerialID, AcquisitionFunnel), and credit card metadata (BinCode, CreditCardType, CardSubType, BINCountry). No writer SP exists in the SSDT repo. A backup cleanup script from 2024-11-17 suggests the table was decommissioned around that time.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP found. Column names suggest Billing.Deposit + customer dims + credit card lookups. |
| **Refresh** | None — table is dormant (0 rows, no writer SP) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 0 (empty) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AdvancedDeposit_Ext` was designed as an **extended deposit analysis table** that denormalized deposit transactions with customer demographics, acquisition channel attribution, payment status lookups, risk management status, and credit card metadata. The "_Ext" suffix indicates it was an extended/denormalized version of a base deposit table.

**This table is now EMPTY (0 rows)** and no automated writer SP exists in the SSDT repo. A backup cleanup script (`2024_12_01_21_07_42_BI_DB_dbo.BI_DB_AdvancedDeposit_Ext_Backup_20241117.sql`) suggests the table was backed up and cleared around November 2024, likely during decommissioning.

Based on column analysis, the table likely combined:
- **Deposit transaction fields** (DepositID, Amount, ExchangeRate, Commission, PaymentDate, ClearingHouseEffectiveDate) — likely from Billing.Deposit or Fact_BillingDeposit
- **Payment processing** (PaymentStatusID, PaymentStatus_Name, RiskManagementStatusID, RiskManagementStatus_Name, TransactionID, ExTransactionID, RefundVerificationCode) — denormalized status lookups
- **Customer demographics** (CID, Country, Region, Channel, SubChannel) — from Dim_Customer + Dim_Country + Dim_Channel
- **Acquisition attribution** (SerialID, FunnelID, Funnel, FunnelFrom, AcquisitionFunnel, FirstDepositAttempt, FirstDepositDate, Registered) — from BI_DB_CIDFirstDates
- **Credit card metadata** (BinCode, CreditCardType, CardSubType, BINCountry, DepoName, CardCategory) — from a payment processor lookup (likely BI_DB_BINInfo or similar)

**Recommendation**: This DDL may be a candidate for cleanup (DROP from SSDT).

---

## 2. Business Logic

### 2.1 Extended Deposit Denormalization

**What**: Combines deposit transactions with all relevant lookups in a single wide table for BI analysis.
**Columns Involved**: All 47 columns
**Rules**:
- No active business logic — table is dormant
- Pattern was likely: deposit fact + customer dim + channel dim + country dim + funnel attribution + credit card BIN lookup
- PaymentStatus and RiskManagementStatus are pre-joined (both ID and Name columns present)

### 2.2 Credit Card Analysis

**What**: Credit card metadata was included for deposit method analysis.
**Columns Involved**: BinCode, CreditCardType, CardSubType, BINCountry, DepoName, CardCategory
**Rules**:
- BinCode: First 6-8 digits of credit card identifying the issuing bank
- BINCountry: Country of the card issuer (may differ from customer's registration country — potential fraud signal)
- CardCategory: Card tier (Standard, Gold, Platinum, etc.)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. **Table is empty — no queries will return data.**

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Deposit analysis with demographics | Use Fact_BillingDeposit + Dim_Customer + Dim_Country instead |
| Credit card analysis | Use BI_DB_DepositWithdrawFee or BI_DB_BINInfo (if available) |

### 3.3 Common JOINs

None applicable — table is empty.

### 3.4 Gotchas

- **TABLE IS EMPTY**: Do not query this table expecting results. Use Fact_BillingDeposit-based alternatives.
- **No writer SP**: There is no automated process to populate this table.
- **47 columns**: Wide table suggesting it was a one-stop-shop analysis table — now superseded by other mechanisms.
- **PII content**: Contains IPAddress, credit card BinCode — treat as sensitive if repopulated.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | bigint | YES | Unique deposit transaction identifier. Likely FK to Billing.Deposit or Fact_BillingDeposit. (Tier 4 — inferred from column name) |
| 2 | CID | int | YES | Customer ID. Platform-internal primary key assigned at registration. (Tier 4 — inferred from column name) |
| 3 | FundingID | bigint | YES | Funding record identifier. Links to Billing.Funding payment processing record. (Tier 4 — inferred from column name) |
| 4 | FundingType | varchar(50) | YES | Payment method name (e.g., Credit Card, Wire Transfer, PayPal). Pre-resolved from Dim_FundingType. (Tier 4 — inferred from column name) |
| 5 | CurrencyID | bigint | YES | Currency identifier for the deposit transaction. FK to Dim_Currency. (Tier 4 — inferred from column name) |
| 6 | PaymentStatusID | bigint | YES | Payment status identifier from Billing.Deposit. (Tier 4 — inferred from column name) |
| 7 | ManagerID | bigint | YES | Account manager identifier assigned to the customer. (Tier 4 — inferred from column name) |
| 8 | RiskManagementStatusID | bigint | YES | Risk management review status identifier for the deposit. (Tier 4 — inferred from column name) |
| 9 | Amount | money | YES | Deposit amount in the transaction currency. (Tier 4 — inferred from column name) |
| 10 | ExchangeRate | numeric(16,8) | YES | Exchange rate applied to convert the deposit amount to the account's base currency. (Tier 4 — inferred from column name) |
| 11 | ModificationDate | datetime | YES | Timestamp of the last modification to the deposit record. (Tier 4 — inferred from column name) |
| 12 | TransactionID | varchar(6) | YES | Short transaction identifier (6 chars). Internal processing reference. (Tier 4 — inferred from column name) |
| 13 | IPAddress | numeric(18,0) | YES | IP address of the depositor at transaction time, stored as numeric. PII field. (Tier 4 — inferred from column name) |
| 14 | Approved | bit | YES | Whether the deposit was approved (1=approved, 0=rejected). (Tier 4 — inferred from column name) |
| 15 | Commission | money | YES | Commission charged on the deposit transaction. (Tier 4 — inferred from column name) |
| 16 | PaymentDate | datetime | YES | Date/time the payment was processed. (Tier 4 — inferred from column name) |
| 17 | ClearingHouseEffectiveDate | datetime | YES | Date when the clearing house settled the transaction. (Tier 4 — inferred from column name) |
| 18 | OldPaymentID | bigint | YES | Legacy payment identifier from a previous payment system. (Tier 4 — inferred from column name) |
| 19 | IsFTD | bit | YES | Whether this deposit is the customer's first-time deposit. 1=FTD, 0=subsequent. (Tier 4 — inferred from column name) |
| 20 | ProcessorValueDate | datetime | YES | Value date assigned by the payment processor. (Tier 4 — inferred from column name) |
| 21 | RefundVerificationCode | varchar(50) | YES | Verification code for refund processing. (Tier 4 — inferred from column name) |
| 22 | DepotID | bigint | YES | Depot/payment processor identifier. (Tier 4 — inferred from column name) |
| 23 | MatchStatusID | bigint | YES | Transaction matching status for reconciliation. (Tier 4 — inferred from column name) |
| 24 | FunnelID | bigint | YES | Registration funnel identifier. FK to funnel dimension. (Tier 4 — inferred from column name) |
| 25 | Code | varchar(50) | YES | Transaction or promotional code associated with the deposit. (Tier 4 — inferred from column name) |
| 26 | ExTransactionID | varchar(50) | YES | External transaction identifier from the payment processor. (Tier 4 — inferred from column name) |
| 27 | PaymentStatus_PaymentStatusID | bigint | YES | Denormalized payment status ID (duplicate of PaymentStatusID for explicit labeling). (Tier 4 — inferred from column name) |
| 28 | PaymentStatus_Name | varchar(50) | YES | Denormalized payment status name (e.g., Completed, Pending, Failed). (Tier 4 — inferred from column name) |
| 29 | RiskManagementStatus_RiskManagementStatusID | bigint | YES | Denormalized risk management status ID (duplicate of RiskManagementStatusID). (Tier 4 — inferred from column name) |
| 30 | RiskManagementStatus_Name | varchar(50) | YES | Denormalized risk management status name (e.g., Approved, Pending Review). (Tier 4 — inferred from column name) |
| 31 | Channel | nvarchar(50) | YES | Marketing channel name (e.g., Organic, Affiliate, Paid). From Dim_Channel via customer attribution. (Tier 4 — inferred from column name) |
| 32 | SubChannel | varchar(100) | YES | Marketing sub-channel detail. From Dim_Channel. (Tier 4 — inferred from column name) |
| 33 | Region | varchar(50) | YES | Customer's marketing region. From Dim_Country. (Tier 4 — inferred from column name) |
| 34 | Country | varchar(50) | YES | Customer's country name. From Dim_Country. (Tier 4 — inferred from column name) |
| 35 | FirstDepositAttempt | datetime | YES | Timestamp of the customer's first deposit attempt (may differ from FirstDepositDate if first attempt was rejected). (Tier 4 — inferred from column name) |
| 36 | FirstDepositDate | datetime | YES | Date of the customer's first successful deposit. (Tier 4 — inferred from column name) |
| 37 | Registered | datetime | YES | Customer's registration date/time. (Tier 4 — inferred from column name) |
| 38 | SerialID | bigint | YES | Affiliate serial ID for attribution tracking. (Tier 4 — inferred from column name) |
| 39 | Funnel | varchar(50) | YES | Registration funnel name at time of deposit. (Tier 4 — inferred from column name) |
| 40 | FunnelFrom | varchar(50) | YES | Original acquisition funnel (may differ from current funnel if customer changed). (Tier 4 — inferred from column name) |
| 41 | AcquisitionFunnel | varchar(50) | YES | Final resolved acquisition funnel for attribution. (Tier 4 — inferred from column name) |
| 42 | BinCode | bigint | YES | Credit card BIN (Bank Identification Number) — first 6-8 digits identifying issuing bank. PII-adjacent. (Tier 4 — inferred from column name) |
| 43 | CreditCardType | varchar(50) | YES | Card network type (e.g., Visa, Mastercard, Amex). (Tier 4 — inferred from column name) |
| 44 | CardSubType | varchar(50) | YES | Card sub-classification (e.g., Debit, Credit, Prepaid). (Tier 4 — inferred from column name) |
| 45 | BINCountry | varchar(50) | YES | Country of the card-issuing bank (from BIN lookup). May differ from customer's registration country — useful for fraud detection. (Tier 4 — inferred from column name) |
| 46 | DepoName | varchar(50) | YES | Payment processor/depot name handling the transaction. (Tier 4 — inferred from column name) |
| 47 | CardCategory | varchar(50) | YES | Card tier category (e.g., Standard, Gold, Platinum, Business). (Tier 4 — inferred from column name) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| All columns | Unknown | — | No writer SP found — table is dormant |

### 5.2 ETL Pipeline

```
(Historical — no longer active)
Billing.Deposit + Dim_Customer + Dim_Country + Dim_Channel + BIN Lookup
  |-- (unknown SP — decommissioned ~Nov 2024) ---|
  v
BI_DB_dbo.BI_DB_AdvancedDeposit_Ext (0 rows — DORMANT)
  |-- Backup: BI_DB_AdvancedDeposit_Ext_Backup_20241117 (cleaned up 2024-12-01)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |
| InstrumentID | — | Not present (deposit table, not trading) |
| DepositID | DWH_dbo.Fact_BillingDeposit | Deposit fact (likely historical source) |

### 6.2 Referenced By (other objects point to this)

No known consumers — table is empty.

---

## 7. Sample Queries

### 7.1 Alternative: Query Fact_BillingDeposit Instead

```sql
-- This table is empty. Use Fact_BillingDeposit for deposit analysis:
SELECT TOP 10 d.*, dc.Name AS Country, dch.Channel
FROM [DWH_dbo].[Fact_BillingDeposit] d
JOIN [DWH_dbo].[Dim_Customer] cust ON d.CID = cust.RealCID
JOIN [DWH_dbo].[Dim_Country] dc ON cust.CountryID = dc.CountryID
JOIN [DWH_dbo].[Dim_Channel] dch ON cust.SubChannelID = dch.SubChannelID
ORDER BY d.PaymentDate DESC
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence or Jira sources found for this table.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 46 T4, 0 T5 | Elements: 47/47, Logic: 6/10, Lineage: 5/10*
*Object: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext | Type: Table | Production Source: Unknown (dormant)*

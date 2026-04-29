# BI_DB_dbo.BI_DB_Wire_PIP_Report

> 318K-row wire transfer revenue spread (PIPs) and discount compensation report for EUR/GBP transactions from Dec 2023 to present — tracking per-transaction PIPs, club-tier discount percentages (from Fivetran Google Sheets config), and compensation amounts for eligible customers by country, regulation, and account type. Refreshed daily by SP_Wires_PIP_Calculation_Report via DELETE+INSERT by PaymentDate. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_Wires_PIP_Calculation_Report` from BI_DB_DepositWithdrawFee + DWH dimensions + Fivetran discount config |
| **Refresh** | Daily — DELETE WHERE PaymentDate=@Date + INSERT. Accumulating by date. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table calculates the **revenue spread (PIPs) and discount compensation** for wire transfer transactions on the eToro platform. When customers deposit or withdraw via wire transfer in EUR or GBP, eToro charges a conversion fee (PIPs). Some customers receive a **discount** on this fee based on their club tier, country, and funding type — configured via a Fivetran-synced Google Sheets document.

The 318K rows cover daily transactions from Dec 2023 to Apr 2026 across 9 regulatory jurisdictions and 8 account types. Key distribution: 81% are withdrawals, 19% deposits. 98% are Private accounts. Discount rates range from 0.25% (Silver/Gold) to 100% (full waiver), with the most common being 20% (36%) and 0.25% (25%).

The SP runs daily for a specific date, sourcing from BI_DB_DepositWithdrawFee (which already contains PIPs calculations), enriching with customer snapshot data (country, regulation, account type, club), and applying discount eligibility from the Fivetran discount config sheet. Only transactions with a non-NULL discount match and EUR/GBP currency are retained.

---

## 2. Business Logic

### 2.1 Discount Eligibility

**What**: Determines which transactions qualify for PIP discount compensation.
**Columns Involved**: Discount%, Eligible_for_discount_private, Eligible_for_discount_corporate, Club, Currency
**Rules**:
- Discount configuration sourced from Fivetran Google Sheets (External_Fivetran_google_sheets_conversion_fee_discounts)
- Matched by: funding_type_id + country_id + player_level_id
- Only records with non-NULL Discount% are included (eligible transactions)
- Only EUR and GBP currencies qualify (no USD wire transfers in this report)

### 2.2 Compensation Calculation

**What**: Computes the actual discount compensation amount in USD.
**Columns Involved**: PIPs in USD, Discount%, Amount Compensation in $
**Rules**:
- Amount Compensation = PIPs in USD × (Discount% / 100)
- PIPs in USD comes pre-calculated from BI_DB_DepositWithdrawFee.PIPsCalculation
- Compensation is always non-negative (ISNULL wraps to 0)

### 2.3 eMoney Supported Flag

**What**: Indicates whether the customer's country supports eMoney (eToro Money) transfers.
**Columns Involved**: eMoney Supported
**Rules**:
- Source: Fivetran config `is_e_tm_country_` field
- 'YES' → 1, 'NO' → 0
- Determines whether the customer could use eToro Money instead of wire transfer

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no clustered index. For date-range queries, filter by PaymentDate for best performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total compensation for a date range | `WHERE PaymentDate BETWEEN @start AND @end GROUP BY PaymentDate` |
| Compensation by regulation | `GROUP BY Regulation` |
| High-discount customers | `WHERE [Discount%] >= 50 ORDER BY [Amount Compensation in $] DESC` |
| Monthly trend | `GROUP BY YEAR(PaymentDate), MONTH(PaymentDate)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_DepositWithdrawFee | CID + DateID | Original transaction details |

### 3.4 Gotchas

- **EUR/GBP only**: USD wire transfers are excluded from this report entirely.
- **Column names with spaces/special characters**: `[eMoney Supported]`, `[Discount%]`, `[PIPs in USD]`, `[Amount Compensation in $]` — always bracket-quote in queries.
- **Negative amounts**: Withdrawals have negative Amount_Currency and Amount_USD values.
- **Discount% is a percentage, not a fraction**: 0.25 means 0.25%, 20 means 20%, 100 means 100% waiver. The formula divides by 100.
- **Eligible_for_discount columns**: Often empty strings — they come from Fivetran Google Sheets and indicate eligibility rules text.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream production wiki — verbatim description |
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID. FK to Dim_Customer.RealCID. One or more rows per customer per day (one per transaction). (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 2 | PaymentDate | date | YES | Transaction date. Set to the @Date input parameter of the SP. Used as the DELETE+INSERT key for daily refresh. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 3 | eMoney Supported | int | YES | Whether the customer's country supports eToro Money transfers. 1=eMoney country, 0=not supported. From Fivetran discount config `is_e_tm_country_` field. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 4 | MarketingRegionManualName | varchar(50) | YES | Marketing region label from Dim_Country.MarketingRegionManualName. Values: UK, German, Italian, Nordics, French, etc. (Tier 2 — SP_Wires_PIP_Calculation_Report, Dim_Country) |
| 5 | AccountType | varchar(50) | YES | Account type name. Values: Private, Corporate, Affiliate Corporate Account, Joint Account, etc. Resolved from Dim_AccountType via Fact_SnapshotCustomer.AccountTypeID. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 6 | TransactionType | varchar(50) | YES | Transaction direction. 'Deposit' or 'Withdraw'. Passthrough from BI_DB_DepositWithdrawFee. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 7 | Country | varchar(50) | YES | Customer's country of registration. Resolved from Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 8 | Discount% | float | YES | Discount percentage applied to PIPs for this transaction. Values: 0.25, 0.5, 1.0, 20, 25, 40, 50, 80, 100. From Fivetran Google Sheets config matched by funding_type + country + player_level. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 9 | Currency | varchar(5) | YES | Transaction currency. Only 'EUR' or 'GBP' (SP filters to these two currencies only). (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 10 | PaymentMethod | varchar(50) | YES | Payment method name. Typically 'WireTransfer' for this report. From BI_DB_DepositWithdrawFee. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 11 | Amount_Currency | float | YES | Transaction amount in original currency (EUR or GBP). Negative for withdrawals, positive for deposits. From BI_DB_DepositWithdrawFee.Amount. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 12 | Amount_USD | float | YES | Transaction amount converted to USD. Negative for withdrawals. From BI_DB_DepositWithdrawFee.AmountUSD. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 13 | PIPs in USD | float | YES | Revenue spread (conversion fee) in USD for this transaction. Pre-calculated in BI_DB_DepositWithdrawFee.PIPsCalculation. Always positive regardless of transaction direction. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 14 | Amount Compensation in $ | money | YES | Discount compensation amount in USD. Calculated as PIPs in USD × (Discount% / 100). Represents the fee reduction the customer receives. 0 if PIPs is NULL. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 15 | UpdateDate | date | NO | ETL metadata: date when this row was inserted by SP_Wires_PIP_Calculation_Report. (Tier 5 — ETL infrastructure) |
| 16 | Club | varchar(20) | YES | Customer club tier at transaction time. Values: Silver, Gold, Platinum, Platinum Plus, Diamond. From BI_DB_DepositWithdrawFee. Determines discount eligibility. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 17 | ExchangeFee | numeric(38,8) | YES | Fixed exchange fee charged for this transaction. From BI_DB_DepositWithdrawFee.ExchangeFee. Typically 150 for wire transfers. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 18 | Regulation | varchar(50) | YES | Regulatory jurisdiction name. Values: FCA, CySEC, ASIC, etc. (9 distinct). Resolved from Dim_Regulation via Fact_SnapshotCustomer.RegulationID. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 19 | Eligible_for_discount_private | nvarchar(4000) | YES | Discount eligibility rule text for private accounts from Fivetran config. Often empty. (Tier 2 — SP_Wires_PIP_Calculation_Report) |
| 20 | Eligible_for_discount_corporate | nvarchar(4000) | YES | Discount eligibility rule text for corporate accounts from Fivetran config. Often empty. (Tier 2 — SP_Wires_PIP_Calculation_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | BI_DB_DepositWithdrawFee | CID | passthrough |
| PaymentDate | SP parameter | @Date | passthrough |
| eMoney Supported | Fivetran Google Sheets | is_e_tm_country_ | computed YES→1/NO→0 |
| MarketingRegionManualName | Dim_Country | MarketingRegionManualName | dim-lookup |
| AccountType | Dim_AccountType | Name | dim-lookup via Fact_SnapshotCustomer |
| TransactionType | BI_DB_DepositWithdrawFee | TransactionType | passthrough |
| Country | Dim_Country | Name | dim-lookup via Fact_SnapshotCustomer |
| Discount% | Fivetran Google Sheets | discount_ | passthrough |
| Currency | BI_DB_DepositWithdrawFee | Currency | passthrough (filtered EUR/GBP) |
| PaymentMethod | BI_DB_DepositWithdrawFee | PaymentMethod | passthrough |
| Amount_Currency | BI_DB_DepositWithdrawFee | Amount | passthrough |
| Amount_USD | BI_DB_DepositWithdrawFee | AmountUSD | passthrough |
| PIPs in USD | BI_DB_DepositWithdrawFee | PIPsCalculation | passthrough |
| Amount Compensation in $ | — | PIPs × (Discount%/100) | computed |
| Club | BI_DB_DepositWithdrawFee | Club | passthrough |
| ExchangeFee | BI_DB_DepositWithdrawFee | ExchangeFee | passthrough |
| Regulation | Dim_Regulation | Name | dim-lookup |
| Eligible_for_discount_private | Fivetran Google Sheets | eligible_for_discount_as_private... | passthrough |
| Eligible_for_discount_corporate | Fivetran Google Sheets | eligible_for_discount_as_corporate... | passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DepositWithdrawFee (transaction amounts, PIPs, fees)
DWH_dbo.Fact_SnapshotCustomer (country, regulation, account type, player level)
DWH_dbo.Dim_Country (country name, marketing region)
DWH_dbo.Dim_AccountType (account type name)
DWH_dbo.Dim_Regulation (regulation name)
DWH_dbo.Dim_FundingType (funding type ID from payment method name)
External_Fivetran_google_sheets_conversion_fee_discounts (discount config)
  |
  |-- SP_Wires_PIP_Calculation_Report @Date (daily)
  |   Filter: Currency IN ('EUR','GBP'), Discount% IS NOT NULL
  |   DELETE WHERE PaymentDate=@Date + INSERT
  v
BI_DB_dbo.BI_DB_Wire_PIP_Report (318K rows, accumulating daily)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer profile |
| — | BI_DB_dbo.BI_DB_DepositWithdrawFee | Source transaction data |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| — | — | No known downstream consumers in SSDT |

---

## 7. Sample Queries

### 7.1 Daily Compensation Total by Regulation

```sql
SELECT PaymentDate, Regulation, COUNT(*) AS transactions,
       SUM([Amount Compensation in $]) AS total_compensation,
       SUM([PIPs in USD]) AS total_pips
FROM BI_DB_dbo.BI_DB_Wire_PIP_Report
WHERE PaymentDate >= '2026-04-01'
GROUP BY PaymentDate, Regulation
ORDER BY PaymentDate DESC, total_compensation DESC
```

### 7.2 Top Discount Recipients

```sql
SELECT TOP 20 CID, Country, Club, [Discount%],
       SUM([Amount Compensation in $]) AS total_compensation,
       COUNT(*) AS transaction_count
FROM BI_DB_dbo.BI_DB_Wire_PIP_Report
WHERE PaymentDate >= '2026-01-01'
GROUP BY CID, Country, Club, [Discount%]
ORDER BY total_compensation DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found for "Wire PIP Report". Context derived from SP code and Fivetran config reference.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 20/20, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Wire_PIP_Report | Type: Table | Production Source: SP_Wires_PIP_Calculation_Report (ETL-computed from BI_DB_DepositWithdrawFee + DWH dimensions + Fivetran config)*

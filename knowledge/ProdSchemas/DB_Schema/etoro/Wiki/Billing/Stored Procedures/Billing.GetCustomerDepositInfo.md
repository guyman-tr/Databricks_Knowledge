# Billing.GetCustomerDepositInfo

> Deposit page initializer - returns 34 numbered result sets in a single call to load the complete deposit UI context for a customer: last deposit, funding instruments, regulation details, package amounts, supported payment methods, exchange rates, and more.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID only; returns 34 result sets covering the entire deposit page context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerDepositInfo` is the deposit page initialization procedure - a "God SP" that assembles the entire dataset needed to render the eToro deposit flow for a customer in a single database round-trip. When a customer navigates to the deposit page, the Payments API calls this procedure once to retrieve all 34 result sets covering the customer's deposit history, available payment methods, regulation-specific settings, and operational configuration.

This pattern (one SP returning many result sets) was common in earlier eToro service architecture as a way to minimize round-trips between the application and the database. The 34 numbered result sets (0-33) each correspond to a specific section of the deposit page UI or a downstream decision.

Data flow: Called by `PamentsAPIUser` (Payments API service) and `DepositUser`. The `BackOffice.GetCustomerDepositInfo` view also references it - likely for backoffice reporting. The CEP (Communications/Event Processing) service also calls it.

---

## 2. Business Logic

### 2.1 Result Set Catalog (34 Result Sets)

**What**: 34 numbered result sets returned in sequence. The caller reads them by ordinal position.

| RS# | Name | Source | Description |
|-----|------|--------|-------------|
| 0 | Depot | Billing.GetDepotInfo | Depot/protocol details for customer's last CC deposit depot |
| 1 | LastDeposit | @DepFun (Billing.Deposit+Funding) | Most recent approved CC deposit (FundingTypeID=1) |
| 2 | PendingWithdrawals | EXEC Billing.GetPendingWithdrawals | List of pending withdrawals for the customer |
| 3 | Funding | @DepFun | Most recent CC funding instrument (FundingTypeID=1) |
| 4 | LabelID | Customer.CustomerStatic | Customer label ID as a single-column single-row result |
| 5 | CustomerRegulationDetails | Customer.CustomerStatic + BackOffice.Customer | DesignatedRegulationID, RegulationID, CountryIDByIP, DepositCount |
| 6 | SupportedBanks | Billing.WireTransferBankInfo + WireTransferBanks | Active wire transfer banks (filtered by LabelID=11 ICMarkets rule) |
| 7 | TotalDeposits | BackOffice.CustomerAllTimeAggregatedData | Lifetime total deposit amount for customer |
| 8 | PlayerLevelID | Customer.CustomerStatic | Customer's player level as single-column result |
| 9 | MinDepositAmountByPackage | Billing.DepositAmount | Package amounts (Min, Package1-3) based on FTD flag and CountryID |
| 10 | PlayerStatusID | Customer.CustomerStatic | Customer player status as single-column result |
| 11 | HasApprovedDeposit | Computed | ~@IsFTD: 1 if customer has previous approved deposit, 0 if first-timer |
| 12 | CreditCards | EXEC Billing.GetSavedCreditCards | Saved credit cards for the customer (top 100) |
| 13 | SofortAccountDetails | @DepFun (FundingTypeID=11) | Most recent Sofort account details (non-blocked) |
| 14 | LastDepositFundingType | @DepFun | FundingTypeID of the most recent deposit |
| 15 | DepositCount | Computed | Count of approved deposits for customer |
| 16 | UnionPaySupportedBanks | Billing.UnionPayRouting + UnionPayBanks + UnionPayTerminal | Active UnionPay banks and terminals |
| 17 | UnionPayCustomerBank | @DepFun | Customer's last UnionPay bank (DepotID 46 or 47) |
| 18 | DefaultPaymentCurrencies | EXEC Billing.GetDefaultCurrencyByFundingTypeAndCID | Default currencies per funding type for customer |
| 19 | MinDepositAmount | Billing.DepositAmount | Minimum deposit amount for customer's country/FTD status |
| 20 | DepositSettings | Billing.FundingTypeDefaultAmount + Dictionary.FundingType | Default and max deposit amounts per funding type |
| 21 | AchAccounts | EXEC Billing.GetCustomerLastFundingByFundingType @CID,29,1,1 | Customer's last ACH account (FundingTypeID=29) |
| 22 | PwmbAccounts | EXEC Billing.GetCustomerLastFundingByFundingType @CID,32,1,1 | Customer's last PWMB account (FundingTypeID=32) |
| 23 | FundingTypes | EXEC Billing.GetFundingTypesByCountry | Available funding types for customer's country |
| 24 | DisabledFundings | EXEC Billing.GetDisabledFundingsFTD | Disabled funding types based on country + regulation |
| 25 | CustomerFundings | EXEC Billing.GetFundingForCustomerByCID | All registered funding instruments for customer |
| 26 | FundingTypesUnderMaintenance | Billing.Maintenance | All funding types currently in maintenance/unavailable |
| 27 | CustomerExchangeRates | EXEC Billing.GetExchangeRatesForCustomer | Personalized exchange rates for customer |
| 28 | BaseExchangeRates | EXEC Billing.GetExchangeRatesBaseTable | Base exchange rate table |
| 29 | NumberOfPendingWithdrawals | EXEC Billing.WithdrawalService_CountPendingWithdrawals | Count of pending withdrawals (also see RS#2) |
| 30 | LastDepositPaymentDate | @DepFun | PaymentDate of most recent deposit |
| 31 | eToroMoneyExposureDate | Billing.CustomerFundingTypeFirstExposure | Date customer was first exposed to eToro Money (FundingTypeID=33) |
| 32 | WireTransferBankID | Dictionary.Regulation | Wire transfer bank ID for customer's designated regulation |
| 33 | WireTransferCurrencies | Billing.WireTransferBankInfo | Currencies supported by customer's wire transfer bank |

### 2.2 FTD (First Time Deposit) Detection

**What**: The procedure determines if the customer is a first-time depositor and uses this flag to select appropriate deposit amounts.

**Rules**:
- `@DepositCount = COUNT(*) FROM @DepFun`: count of approved CC deposits for the customer.
- `@IsFTD = CASE WHEN @DepositCount > 0 THEN 0 ELSE 1 END`: 1 if no prior approved deposits (first-timer), 0 if returning depositor.
- RS#9 and RS#19 filter `Billing.DepositAmount` by `FTD = @IsFTD` - FTD customers see different minimum/package amounts.
- RS#11 returns `~@IsFTD` (bitwise NOT): 1 = has approved deposit, 0 = no approved deposit.

### 2.3 Country Resolution for Deposit Amounts

**What**: CountryID is resolved with an IP fallback for customers who haven't provided their country.

**Rules**:
- `@CountryID = CASE CountryID WHEN 0 THEN CountryIDByIP ELSE CountryID END`: if the customer's registered CountryID is 0 (unknown), use the IP-derived CountryIDByIP.
- This CountryID is used to filter RS#9, RS#19 (DepositAmount) and RS#23 (GetFundingTypesByCountry).

### 2.4 LabelID 11 (ICMarkets) Wire Transfer Rule

**What**: A special rule filters supported banks for white-label partner ICMarkets.

**Rules**:
- RS#6 filter: `AND (@LabelID <> 11 OR WTBI.BankID = 4)`: if LabelID=11 (ICMarkets), only show BankID=4 (Westpac). All other labels see all active banks.
- The commented-out `AND WTBI.RegulationID = @RegulationID` suggests per-regulation bank filtering was previously planned.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. All 34 result sets are derived from or filtered to this customer. |

**Returns**: 34 numbered result sets (see Section 2.1 for full catalog). Key output columns across result sets:

| RS# | Key Output Columns | Notes |
|-----|-------------------|-------|
| 0 | DepotID, ProtocolID, PaymentTypeID, FundingTypeID, Name, ClassKey | TOP 1 - customer's CC depot |
| 1 | DepositID, DepotID, CID, FundingID, CurrencyID, PaymentStatusID, Amount, ExchangeRate, PaymentDate, TransactionID, PaymentData | TOP 1 - most recent approved CC deposit |
| 5 | DesignatedRegulationID, RegulationID, CountryIDByIP, DepositCount | Regulation context |
| 9 | MinAmount, Package1Amount, Package2Amount, Package3Amount, IsPackageVisible | Package amounts based on FTD + country |
| 11 | (bit) | 1 = has approved deposit |
| 20 | FundingTypeID, CurrencyID, DefaultDepositAmount, MaxDepositAmount, PaymentGeneration | All funding type settings |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Billing.Deposit + Billing.Funding | JOIN read | Approved deposits + funding instruments loaded into @DepFun buffer |
| CID | Customer.CustomerStatic | Direct read | Customer label, player status, player level, country |
| CID | BackOffice.Customer | Direct read | Designated regulation and regulation for the customer |
| DepotID | Billing.GetDepotInfo | View read | Depot details for customer's CC depot |
| CID | BackOffice.CustomerAllTimeAggregatedData | Direct read | Lifetime total deposit amount |
| CountryID | Billing.DepositAmount | Direct read | Package and min deposit amounts by country + FTD flag |
| - | Billing.WireTransferBankInfo + WireTransferBanks | JOIN read | Active wire transfer banks |
| - | Billing.UnionPayRouting + UnionPayBanks + UnionPayTerminal | JOIN read | Active UnionPay banks |
| - | Billing.FundingTypeDefaultAmount + Dictionary.FundingType | JOIN read | Default deposit amounts per funding type |
| - | Billing.Maintenance | Direct read | Funding types under maintenance |
| CID | Billing.CustomerFundingTypeFirstExposure | Direct read | eToro Money exposure date |
| DesignatedRegulationID | Dictionary.Regulation | Direct read | Wire transfer bank ID for regulation |
| BankID | Billing.WireTransferBankInfo | Direct read | Wire transfer currencies |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PamentsAPIUser | EXECUTE grant | Permission | Payments API - primary caller; loads deposit page context |
| DepositUser | EXECUTE grant | Permission | Deposit service caller |
| BackOffice.GetCustomerDepositInfo | View | Reference | BackOffice view references this procedure |
| CEP.PR_Run_Statment | Procedure | EXEC call | CEP (event processing) calls this for customer deposit context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerDepositInfo (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Customer.CustomerStatic (table)
├── BackOffice.Customer (table)
├── Billing.GetDepotInfo (view)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── Billing.DepositAmount (table)
├── Billing.WireTransferBankInfo (table)
├── Billing.WireTransferBanks (table)
├── Billing.UnionPayRouting (table)
├── Billing.UnionPayBanks (table)
├── Billing.UnionPayTerminal (table)
├── Billing.FundingTypeDefaultAmount (table)
├── Dictionary.FundingType (table)
├── Billing.Maintenance (table)
├── Billing.CustomerFundingTypeFirstExposure (table)
├── Billing.CustomerToFunding (table)
├── Dictionary.Regulation (table)
├── Billing.GetPendingWithdrawals (procedure)
├── Billing.GetSavedCreditCards (procedure)
├── Billing.GetDefaultCurrencyByFundingTypeAndCID (procedure)
├── Billing.GetCustomerLastFundingByFundingType (procedure)
├── Billing.GetFundingTypesByCountry (procedure)
├── Billing.GetDisabledFundingsFTD (procedure)
├── Billing.GetFundingForCustomerByCID (procedure)
├── Billing.GetExchangeRatesForCustomer (procedure)
├── Billing.GetExchangeRatesBaseTable (procedure)
└── Billing.WithdrawalService_CountPendingWithdrawals (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary read (via @DepFun buffer) - approved deposits for customer |
| Billing.Funding | Table | JOIN - funding type and blocking status |
| Customer.CustomerStatic | Table | Customer context (label, country, player status/level) |
| BackOffice.Customer | Table | Regulation details (DesignatedRegulationID, RegulationID) |
| BackOffice.CustomerAllTimeAggregatedData | Table | Total lifetime deposits |
| Billing.DepositAmount | Table | Package/minimum deposit amounts by country + FTD |
| Billing.WireTransferBankInfo + WireTransferBanks | Tables | Supported wire transfer banks |
| Billing.UnionPayRouting + UnionPayBanks + UnionPayTerminal | Tables | UnionPay bank/terminal availability |
| Billing.FundingTypeDefaultAmount + Dictionary.FundingType | Tables | Deposit settings per funding type |
| Billing.Maintenance | Table | Funding types under maintenance |
| Billing.CustomerFundingTypeFirstExposure | Table | eToro Money first exposure date |
| Billing.CustomerToFunding | Table | Customer Sofort funding instruments |
| Dictionary.Regulation | Table | Wire bank ID for regulation |
| Billing.GetDepotInfo | View | Depot details for CC depot |
| 9x child procedures | Procedures | GetPendingWithdrawals, GetSavedCreditCards, GetDefaultCurrencyByFundingTypeAndCID, GetCustomerLastFundingByFundingType (x2), GetFundingTypesByCountry, GetDisabledFundingsFTD, GetFundingForCustomerByCID, GetExchangeRatesForCustomer, GetExchangeRatesBaseTable, WithdrawalService_CountPendingWithdrawals |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerDepositInfo | View | References this procedure |
| CEP.PR_Run_Statment | Procedure | Calls this procedure for deposit context |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| 34 result sets | Must be read by ordinal position (0-33) in exact sequence |
| @DepFun buffer | Table variable loaded once; reused for RS#0, #1, #3, #13, #14, #17, #30 |
| Amount x100 | RS#1 and RS#3 do NOT scale Amount; raw MONEY value returned |
| NOLOCK | All reads use NOLOCK for performance on this read-heavy SP |

---

## 8. Sample Queries

### 8.1 Execute the deposit info loader

```sql
-- Loads the full 34-result-set deposit page context for customer 1234567
EXEC [Billing].[GetCustomerDepositInfo] @CID = 1234567
-- Caller must read result sets 0-33 in order
```

### 8.2 Check the key RS#5 regulation data directly

```sql
-- Simulate RS#5 CustomerRegulationDetails
SELECT
    c.LabelID,
    c.PlayerStatusID,
    CASE c.CountryID WHEN 0 THEN c.CountryIDByIP ELSE c.CountryID END AS CountryID,
    c.CountryIDByIP,
    bc.DesignatedRegulationID,
    bc.RegulationID
FROM [Customer].[CustomerStatic] c WITH (NOLOCK)
LEFT JOIN [BackOffice].[Customer] bc WITH (NOLOCK) ON bc.CID = c.CID
WHERE c.CID = 1234567
```

### 8.3 Check deposit package amounts for a country

```sql
-- Simulate RS#9 MinDepositAmountByPackage
SELECT MinAmount, Package1Amount, Package2Amount, Package3Amount, IsPackageVisible
FROM [Billing].[DepositAmount] WITH (NOLOCK)
WHERE FTD = 0  -- 0 = returning depositor
  AND CountryID = 171  -- e.g., Spain
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Funding Type Updates](https://etoro-jira.atlassian.net/wiki/spaces/...) | Confluence | Page references GetCustomerDepositInfo in context of funding type configuration updates |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 11 child procedures | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerDepositInfo | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerDepositInfo.sql*

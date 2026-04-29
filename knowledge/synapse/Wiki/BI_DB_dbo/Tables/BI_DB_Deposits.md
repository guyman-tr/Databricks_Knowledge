# BI_DB_dbo.BI_DB_Deposits

> Denormalized deposit reporting table — 580K rows covering 2023-12-20 to 2024-01-16, flattening Fact_BillingDeposit with customer demographics, marketing channel, card BIN attributes, and payment response data. Updated daily via SP_H_Deposits (incremental UPDATE + INSERT for yesterday's modifications). Excludes Popular Investors (PlayerLevelID!=4).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingDeposit + 10 dimension/external tables via SP_H_Deposits |
| **Refresh** | Daily (SP_H_Deposits, incremental UPDATE + INSERT for yesterday's modifications) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, DepositID ASC) |
| | |
| **UC Target** | _Pending_ |
| **UC Format** | _Pending_ |
| **UC Partitioned By** | _Pending_ |
| **UC Table Type** | _Pending_ |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_Deposits` is a denormalized BI reporting table with 580K rows (2023-12-20 to 2024-01-16) that flattens `DWH_dbo.Fact_BillingDeposit` with pre-joined customer demographics (country, region, registration date, affiliate), marketing channel attribution (Channel, SubChannel, Funnel), card BIN metadata (card type, sub-type, category, BIN country), payment status labels, and deposit action response names. SP_H_Deposits runs daily, filtering `Fact_BillingDeposit` for yesterday's modifications (`ModificationDate >= @Date`) and excluding Popular Investors (`PlayerLevelID!=4`). The SP performs UPDATE on existing DepositIDs and INSERT for new ones — not a full reload.

---

## 2. Business Logic

### 2.1 Response Deduplication

**What**: Each deposit may have multiple history action records; only the latest response is kept.

**Columns Involved**: `ResponseName`, `ResponseRN`

**Rules**:
- `ResponseRN = ROW_NUMBER() OVER (PARTITION BY DepositID ORDER BY hda.ModificationDate DESC)` — ranks actions newest-first
- Only rows with `ResponseRN=1` are written to the final table
- ResponseName comes from External_etoro_Dictionary_Response via the latest DepositAction

### 2.2 Marketing Channel Attribution

**What**: Channel and SubChannel are resolved from the customer's affiliate, not from the deposit itself.

**Columns Involved**: `Channel`, `SubChannel`, `SerialID`

**Rules**:
- SerialID (= Dim_Customer.AffiliateID) is joined to Dim_Affiliate, then to Dim_Channel on SubChannelID
- NULL Channel/SubChannel when the customer has no affiliate (organic/direct with no affiliate record)

---

## 3. Query Advisory

### 3.1 Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on (DateID, DepositID). Range scans by DateID are efficient. No hash key — JOINs on DepositID or CID require data movement.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily approved deposit volume | `WHERE PaymentStatusID = 2 GROUP BY DateID` |
| FTD analysis by channel | `WHERE IsFTD = 1 AND PaymentStatusID = 2 GROUP BY Channel` |
| Decline rate by funding type | `GROUP BY FundingType` with CASE on PaymentStatusID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes |
| DWH_dbo.Dim_Currency | ON CurrencyID | Currency name |

### 3.4 Gotchas

- **OldPaymentID and Code are always NULL** — hardcoded in SP, retained for schema compatibility.
- **Popular Investors excluded** — `WHERE PlayerLevelID!=4` in SP means PI deposits are absent.
- **ResponseRN is always 1** — the SP filters to `ResponseRN=1` before INSERT/UPDATE, so all rows have value 1.
- **Limited date range** — table currently holds ~28 days of data (2023-12-20 to 2024-01-16); older data may have been truncated or the SP was recently initialized.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — {source}) |
| Tier 2 — SP ETL code | (Tier 2 — SP_H_Deposits) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | bigint | YES | Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). (Tier 1 — Billing.Deposit) |
| 2 | CID | int | YES | Customer ID. Identifies the eToro customer who made this deposit. (Tier 1 — Billing.Deposit) |
| 3 | FundingID | bigint | YES | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. (Tier 1 — Billing.Deposit) |
| 4 | FundingType | nvarchar(50) | YES | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). (Tier 1 — Dictionary.FundingType) |
| 5 | CurrencyID | bigint | YES | Currency of the deposit amount. 1=USD, 2=EUR, 3=GBP, etc. (Tier 1 — Billing.Deposit) |
| 6 | PaymentStatusID | bigint | YES | Current deposit status. Key values: 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. (Tier 1 — Billing.Deposit) |
| 7 | ManagerID | bigint | YES | Operations manager who processed this deposit. 0=automated. (Tier 1 — Billing.Deposit) |
| 8 | RiskManagementStatusID | bigint | YES | Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation. (Tier 1 — Billing.Deposit) |
| 9 | Amount | money | YES | Deposit amount in the deposit currency (CurrencyID). Capped via CASE expression in upstream ETL to prevent extreme outlier values. (Tier 1 — Billing.Deposit) |
| 10 | ExchangeRate | numeric(16,8) | YES | Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. (Tier 1 — Billing.Deposit) |
| 11 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — Billing.Deposit) |
| 12 | TransactionID | nvarchar(50) | YES | Provider transaction ID string, sourced from Fact_BillingDeposit.TransactionIDAsString (XML-extracted). (Tier 2 — SP_H_Deposits) |
| 13 | IPAddress | numeric(18,0) | YES | Customer IP address at deposit time, as a 32-bit integer. Used for fraud detection. (Tier 1 — Billing.Deposit) |
| 14 | Approved | bit | YES | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Retained for backward compatibility. (Tier 1 — Billing.Deposit) |
| 15 | Commission | money | YES | Commission charged on this deposit. Default 0 in production. (Tier 1 — Billing.Deposit) |
| 16 | PaymentDate | datetime | YES | UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. (Tier 1 — Billing.Deposit) |
| 17 | ClearingHouseEffectiveDate | datetime | YES | Settlement date assigned by the clearing house. NULL for instant payment methods. (Tier 1 — Billing.Deposit) |
| 18 | OldPaymentID | bigint | YES | Always NULL — hardcoded in SP_H_Deposits. Retained for schema compatibility. (Tier 2 — SP_H_Deposits) |
| 19 | IsFTD | bit | YES | First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. (Tier 1 — Billing.Deposit) |
| 20 | ProcessorValueDate | datetime | YES | Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods. (Tier 1 — Billing.Deposit) |
| 21 | RefundVerificationCode | nvarchar(50) | YES | Verification code for refund correlation. Set by UpdateRefundDetails. NULL for non-refunded deposits. (Tier 1 — Billing.Deposit) |
| 22 | DepotID | bigint | YES | Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. (Tier 1 — Billing.Deposit) |
| 23 | MatchStatusID | bigint | YES | PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows. (Tier 1 — Billing.Deposit) |
| 24 | FunnelID | bigint | YES | Marketing funnel ID. FK to Dictionary.Funnel. (Tier 1 — Billing.Deposit) |
| 25 | Code | nvarchar(50) | YES | Always NULL — hardcoded in SP_H_Deposits. Retained for schema compatibility. (Tier 2 — SP_H_Deposits) |
| 26 | ExTransactionID | nvarchar(50) | YES | External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution. (Tier 1 — Billing.Deposit) |
| 27 | PaymentStatus_PaymentStatusID | bigint | YES | Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. (Tier 1 — Dictionary.PaymentStatus) |
| 28 | PaymentStatus_Name | nvarchar(50) | YES | Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. (Tier 1 — Dictionary.PaymentStatus) |
| 29 | RiskManagementStatus_RiskManagementStatusID | bigint | YES | Denormalized risk management status ID from External_etoro_Dictionary_RiskManagementStatus. (Tier 2 — SP_H_Deposits) |
| 30 | RiskManagementStatus_Name | nvarchar(50) | YES | Human-readable risk management status label from External_etoro_Dictionary_RiskManagementStatus. (Tier 2 — SP_H_Deposits) |
| 31 | Channel | nvarchar(50) | YES | Top-level marketing channel (e.g., Affiliate, Direct, SEM, SEO, Friend Referral). Resolved via Dim_Affiliate + Dim_Channel on customer's AffiliateID. NULL if no affiliate. (Tier 2 — SP_H_Deposits) |
| 32 | SubChannel | nvarchar(100) | YES | Granular marketing sub-channel (e.g., Affiliate, Direct Mobile, Google Search). Resolved via Dim_Affiliate + Dim_Channel on customer's AffiliateID. NULL if no affiliate. (Tier 2 — SP_H_Deposits) |
| 33 | Region | nvarchar(50) | YES | Marketing region name for the customer's country, from External_etoro_Dictionary_MarketingRegion via Dim_Country.MarketingRegionID. (Tier 2 — SP_H_Deposits) |
| 34 | Country | nvarchar(50) | YES | Full country name in English. Passthrough from Dim_Country via Dim_Customer.CountryID. (Tier 1 — Dictionary.Country) |
| 35 | FirstDepositAttempt | datetime | YES | Date of the customer's first deposit attempt, from External_etoro_BackOffice_CustomerAllTimeAggregatedData.FirstTimeDepositAttemptDate. (Tier 2 — SP_H_Deposits) |
| 36 | FirstDepositDate | datetime | YES | Date of the customer's first successful deposit, from External_etoro_BackOffice_CustomerAllTimeAggregatedData.FirstTimeDepositSuccessDate. (Tier 2 — SP_H_Deposits) |
| 37 | Registered | datetime | YES | Account registration date. Passthrough from Dim_Customer.RegisteredReal. (Tier 1 — Customer.CustomerStatic) |
| 38 | SerialID | bigint | YES | Affiliate (partner) ID under which the customer was acquired. Passthrough from Dim_Customer.AffiliateID (renamed from SerialID in Customer.CustomerStatic). NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 39 | Funnel | nvarchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Resolved from Dim_Funnel on fbd.FunnelID. (Tier 1 — Dictionary.Funnel) |
| 40 | FunnelFrom | nvarchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Resolved from Dim_Funnel on Dim_Customer.FunnelFromID. (Tier 1 — Dictionary.Funnel) |
| 41 | AcquisitionFunnel | nvarchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Resolved from Dim_Funnel on Dim_Customer.FunnelID. (Tier 1 — Dictionary.Funnel) |
| 42 | BinCode | bigint | YES | Card BIN (first 6-8 digits), sourced from Fact_BillingDeposit.BinCodeAsString (XML-extracted). (Tier 2 — SP_H_Deposits) |
| 43 | CreditCardType | nvarchar(50) | YES | Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. (Tier 1 — Dictionary.CardType) |
| 44 | CardSubType | nvarchar(50) | YES | Sub-classification of the card product (e.g., CREDIT, DEBIT, PREPAID). Passthrough from Dim_CountryBin.CardSubType. (Tier 2 — SP_H_Deposits) |
| 45 | CardCategory | nvarchar(50) | YES | Card product category (e.g., STANDARD, GOLD, PLATINUM, BUSINESS). Passthrough from Dim_CountryBin.CardCategory. (Tier 2 — SP_H_Deposits) |
| 46 | BINCountry | nvarchar(50) | YES | Full country name in English. Passthrough from Dim_Country via fbd.BinCountryIDAsInteger. (Tier 1 — Dictionary.Country) |
| 47 | DepoName | nvarchar(50) | YES | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. (Tier 1 — Billing.Depot) |
| 48 | ResponseName | nvarchar(255) | YES | Payment provider response label for the latest deposit action (e.g., "Permitted transaction.", "Approved", "Suspected Fraud"). From External_etoro_Dictionary_Response. (Tier 2 — SP_H_Deposits) |
| 49 | ResponseRN | bigint | YES | Always 1 — ROW_NUMBER() ranking deposit actions by ModificationDate DESC; only the latest action (RN=1) is kept. (Tier 2 — SP_H_Deposits) |
| 50 | Date | date | YES | Deposit modification date cast to date type from Fact_BillingDeposit.ModificationDate. (Tier 2 — SP_H_Deposits) |
| 51 | DateID | int | YES | Integer YYYYMMDD derived from ModificationDate. Clustered index key. Passthrough from Fact_BillingDeposit.ModificationDateID. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 52 | UpdateDate | datetime | NOT NULL | ETL load timestamp. GETDATE() at SP_H_Deposits execution. (Tier 2 — SP_H_Deposits) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | BI_DB Columns | Transform |
|--------|-------------|-----------|
| DWH_dbo.Fact_BillingDeposit (fbd) | DepositID, CID, FundingID, CurrencyID, PaymentStatusID, ManagerID, RiskManagementStatusID, Amount, ExchangeRate, ModificationDate, IPAddress, Approved, Commission, PaymentDate, ClearingHouseEffectiveDate, IsFTD, ProcessorValueDate, RefundVerificationCode, DepotID, MatchStatusID, FunnelID, ExTransactionID, TransactionID, BinCode, Date, DateID | Mostly passthrough; TransactionID renamed from TransactionIDAsString; Date cast from ModificationDate |
| DWH_dbo.Dim_PaymentStatus (dps) | PaymentStatus_PaymentStatusID, PaymentStatus_Name | JOIN on PaymentStatusID |
| DWH_dbo.Dim_FundingType | FundingType | JOIN via External_Billing_Funding.FundingTypeID |
| DWH_dbo.Dim_Customer (CC) | Registered, SerialID | JOIN on CID=RealCID; RegisteredReal->Registered, AffiliateID->SerialID |
| DWH_dbo.Dim_Country (country) | Country | JOIN via CC.CountryID |
| DWH_dbo.Dim_Country (dc3) | BINCountry | JOIN on fbd.BinCountryIDAsInteger |
| DWH_dbo.Dim_Funnel (df/df2/df3) | Funnel, FunnelFrom, AcquisitionFunnel | 3 JOINs: fbd.FunnelID, CC.FunnelFromID, CC.FunnelID |
| DWH_dbo.Dim_CardType (ct) | CreditCardType | JOIN on fbd.CardTypeIDAsInteger |
| DWH_dbo.Dim_CountryBin (cb) | CardSubType, CardCategory | JOIN on fbd.BinCodeAsString |
| DWH_dbo.Dim_BillingDepot (depo) | DepoName | JOIN on fbd.DepotID |
| DWH_dbo.Dim_Affiliate + Dim_Channel | Channel, SubChannel | JOIN on CC.AffiliateID->Dim_Affiliate->Dim_Channel |
| External_etoro_Dictionary_RiskManagementStatus | RiskManagementStatus_RiskManagementStatusID, RiskManagementStatus_Name | JOIN on fbd.RiskManagementStatusID |
| External_etoro_Dictionary_MarketingRegion | Region | JOIN via country.MarketingRegionID |
| External_etoro_BackOffice_CustomerAllTimeAggregatedData | FirstDepositAttempt, FirstDepositDate | JOIN on fbd.CID |
| External_etoro_History_DepositAction + External_etoro_Dictionary_Response | ResponseName | JOIN on DepositID -> ResponseID, deduplicated by ROW_NUMBER |
| ETL-computed | OldPaymentID, Code, ResponseRN, UpdateDate | Hardcoded NULL / ROW_NUMBER / GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingDeposit (73.9M rows, HASH(DepositID))
  + Dim_PaymentStatus, Dim_FundingType, Dim_Customer, Dim_Country (x2),
    Dim_Funnel (x3), Dim_CardType, Dim_CountryBin, Dim_BillingDepot,
    Dim_Affiliate + Dim_Channel, 5 External tables
  |
  v [SP_H_Deposits — daily, WHERE ModificationDate >= yesterday, PlayerLevelID!=4]
    1. SELECT into #AdvancedDeposit_Ext (multi-source JOIN + ROW_NUMBER)
    2. JOIN Dim_Affiliate + Dim_Channel -> #BI_DB_Deposits_tmp
    3. Filter ResponseRN=1 -> #BI_DB_Deposits_updates
    4. UPDATE existing rows in BI_DB_Deposits ON DepositID
    5. INSERT new DepositIDs not yet in BI_DB_Deposits
  |
  v
BI_DB_dbo.BI_DB_Deposits (580K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Current deposit status |
| FunnelID | DWH_dbo.Dim_Funnel | Marketing funnel |
| DepotID | DWH_dbo.Dim_BillingDepot | Payment gateway depot |
| SerialID | DWH_dbo.Dim_Affiliate | Affiliate partner |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_H_Deposits | (writes this table) | Daily incremental ETL |

---

## 7. Sample Queries

### 7.1 Daily approved deposit count by funding type

```sql
SELECT
    DateID,
    FundingType,
    COUNT(*) AS DepositCount,
    SUM(Amount) AS TotalAmount
FROM [BI_DB_dbo].[BI_DB_Deposits]
WHERE PaymentStatusID = 2
GROUP BY DateID, FundingType
ORDER BY DateID DESC, DepositCount DESC;
```

### 7.2 Decline rate by marketing channel

```sql
SELECT
    Channel,
    COUNT(*) AS TotalDeposits,
    SUM(CASE WHEN PaymentStatusID = 2 THEN 1 ELSE 0 END) AS Approved,
    SUM(CASE WHEN PaymentStatusID IN (3, 35) THEN 1 ELSE 0 END) AS Declined,
    CAST(SUM(CASE WHEN PaymentStatusID = 2 THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(*), 0) AS ApprovalRate
FROM [BI_DB_dbo].[BI_DB_Deposits]
GROUP BY Channel
ORDER BY TotalDeposits DESC;
```

---

## 8. Atlassian Knowledge Sources

- [Deposit Statuses and Back Office](https://etoro-jira.atlassian.net/wiki/spaces/USACS/pages/11752211021/Deposit+Statuses+and+Back+Office) — deposit status definitions and Back Office UI navigation
- [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862/BI+Dictionary) — references BI_DB_Deposits as CID/Deposit Time/Modification Date level table; notes "if a particular column is not in Fact Billing Deposit, there is no reason to use this table"
- [Deposits Dashboard](https://etoro-jira.atlassian.net/wiki/spaces/NOC/pages/12546342913/Deposits+Dashboard) — Grafana operational monitoring for deposit flows

---

*Generated: 2026-04-29 | Quality: pending/10 | Phases: 11/14*
*Tiers: 34 T1, 18 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 52/52, Logic: 8/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_Deposits | Type: Table | Production Source: DWH_dbo.Fact_BillingDeposit via SP_H_Deposits*

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_EY_Audit_CashoutReason`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_EY_Audit_CashoutReason.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_EY_Audit_CashoutReason]
(
	[WithdrawID] [bigint] NULL,
	[CID] [int] NULL,
	[WithdrawPaymentID] [bigint] NULL,
	[ModificationDate_WithdrawToFunding_DateID] [int] NULL,
	[CashoutReasonID] [int] NULL,
	[CashoutReason] [varchar](200) NULL,
	[Country] [varchar](200) NULL,
	[Club] [varchar](200) NULL,
	[GuruStatusName] [varchar](200) NULL,
	[AccountType] [varchar](200) NULL,
	[ExternalID] [varchar](200) NULL,
	[FundingType] [varchar](200) NULL,
	[UpdateDate] [date] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 10 upstream wiki(s). Read EACH one in full.


### Upstream `DWH_dbo.Fact_BillingWithdraw` — synapse
- **Resolved as**: `DWH_dbo.Fact_BillingWithdraw`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md`

# DWH_dbo.Fact_BillingWithdraw

> Denormalized withdrawal fact table; each row combines a customer withdrawal request (Billing.Withdraw), its payment execution leg (Billing.WithdrawToFunding), and the funding instrument metadata (Billing.Funding) into a single wide row with XML-extracted payment details and BIN-code enrichment, providing a one-stop analytics surface for withdrawal operations, cashout monitoring, and regulatory reporting.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | Billing.Withdraw + Billing.WithdrawToFunding + Billing.Funding |
| **Key Identifier** | WithdrawID (CLUSTERED INDEX, HASH distribution key) |
| **Distribution** | HASH(WithdrawID) |
| **Index** | CLUSTERED INDEX (WithdrawID ASC); NCI on ExpirationDateID |
| **Column Count** | 83 |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` |
| **UC Copy Strategy** | Merge |
| **Refresh** | Daily (1440 min) |
| **ETL Pattern** | DELETE-day + Staging INSERT + Post-load BIN enrichment |

---

## 1. Business Meaning

`Fact_BillingWithdraw` is the DWH's primary withdrawal analytics table. It denormalizes three production tables into a single row per withdrawal-to-funding execution:

1. **Billing.Withdraw** (`bw`): The withdrawal request — customer ID, amount, status, fees, request date
2. **Billing.WithdrawToFunding** (`wtf`): The payment execution leg — processing currency, exchange rate, payment status, depot routing
3. **Billing.Funding** (`bf`): The funding instrument — payment method metadata extracted from XML

The ETL uses `DWH_dbo.ExtractXMLValue()` to parse ~40 fields from the XML blobs (`wtf.WithdrawData` and `bf.FundingData`), flattening provider-specific payment details (card numbers, bank accounts, IBAN codes, etc.) into queryable columns. Many fields use a COALESCE pattern that tries the WithdrawToFunding XML first, falling back to the Funding XML when unavailable.

After the main load, `SP_Fact_BillingWithdraw` enriches each day's rows with `BankName` (issuing bank) and `CardCategory` from `Dim_CountryBin` matched on BIN code.

### Business Usage

- **Regulatory Reporting**: Confluence "Business & Regulatory Undertakings Monitoring Platform" queries `Fact_BillingWithdraw WHERE Fee>0` for withdrawal fee monitoring
- **Cashout Fee Analysis**: Confluence "Cashout Fee" joins to `Dim_CashoutReason`, `Dim_BillingDepot`, `Dim_FundingType`, `Dim_CardType` for fee breakdowns by regulation, club, country, and account type
- **Deposits & Withdrawals Reporting**: Confluence "Deposits and withdrawals - DWH" uses this table alongside `Fact_BillingDeposit` for combined payment flow analysis

---

## 2. Business Logic

### 2.1 ETL Pipeline (SP_Fact_BillingWithdraw_DL_To_Synapse)

```
Step 1: DELETE existing rows for @dt day (ModificationDateID range)
Step 2: TRUNCATE Ext_FBW_Fact_BillingWithdraw
Step 3: INSERT into Ext from 3-way staging JOIN:
        bw LEFT JOIN wtf ON WithdrawID
           LEFT JOIN bf ON FundingID
        WHERE bw.ModificationDate in @dt day range
        → ExtractXMLValue() for ~40 columns from XML
        → COALESCE(wtf.WithdrawData, bf.FundingData) for shared fields
Step 4: DELETE existing in Fact matching by WithdrawID (upsert pattern)
Step 5: INSERT from Ext into Fact_BillingWithdraw
Step 6: EXEC SP_Fact_BillingWithdraw @date = @dt
```

### 2.2 Post-Load Enrichment (SP_Fact_BillingWithdraw)

```
Step 1: Wait for Dim_CountryBin to be loaded today (polling loop, 60s intervals)
Step 2: UPDATE BankName = cb.IssuingBank, CardCategory = cb.CardCategory
        FROM Fact_BillingWithdraw fbw
        JOIN Dim_CountryBin cb ON CAST(fbw.BinCodeAsString AS INT) = cb.BinCode
        WHERE ModificationDateID = @dateID
```

### 2.3 Dual Status Tracking

The table carries two CashoutStatusID columns reflecting different levels:
- **CashoutStatusID_Withdraw** (request level): Tracks the overall withdrawal request lifecycle. 71% of requests are Cancelled in production.
- **CashoutStatusID_Funding** (execution level): Tracks the specific payment leg execution. A request can be Processed overall while having multiple legs with different statuses.

Both reference `Dim_CashoutStatus`. Key values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled.

### 2.4 Dual FundingType Tracking

- **FundingTypeID_Withdraw**: The payment method the customer selected when making the withdrawal request (from Billing.Withdraw)
- **FundingTypeID_Funding**: The payment method of the actual funding instrument receiving the payout (from Billing.Funding)

These may differ when the payout is routed to a different method than originally requested.

### 2.5 Dual Amount Tracking

- **Amount_Withdraw**: The gross withdrawal amount in the request currency (CurrencyID)
- **Amount_WithdrawToFunding**: The actual payout amount in the processing currency (ProcessCurrencyID)

The difference may be due to exchange rate conversion (ExchangeRate) and fees (Fee, ExchangeFee).

### 2.6 XML Extraction Pattern

~40 columns are extracted from XML blobs stored in the production `WithdrawData` and `FundingData` columns using `DWH_dbo.ExtractXMLValue()`. All are stored as `nvarchar(max)` regardless of their semantic type (some represent integers, decimals, dates). The COALESCE pattern for shared fields (BIN code, IBAN, SWIFT, etc.) prefers the payment execution data over the funding instrument data, as the execution-time data is more current.

### 2.7 BIN Code Enrichment

After the main ETL load, `SP_Fact_BillingWithdraw` enriches rows by matching `BinCodeAsString` (CAST to INT) against `Dim_CountryBin.BinCode` to populate `BankName` (issuing bank) and `CardCategory`. This step waits for `Dim_CountryBin` to be loaded for the current day, polling every 60 seconds.

### 2.8 Column Rename Disambiguation

| DWH Column | Source Column | Source Table | Why Renamed |
|-----------|-------------|-------------|-------------|
| Amount_Withdraw | Amount | bw (Billing.Withdraw) | Disambiguate from WTF amount |
| Amount_WithdrawToFunding | Amount | wtf (Billing.WithdrawToFunding) | Payment leg amount in process currency |
| FundingTypeID_Withdraw | FundingTypeID | bw (Billing.Withdraw) | Payment method of the withdrawal request |
| FundingTypeID_Funding | FundingTypeID | bf (Billing.Funding) | Payment method of the funding instrument |
| CashoutStatusID_Withdraw | CashoutStatusID | bw (Billing.Withdraw) | Request-level status |
| CashoutStatusID_Funding | CashoutStatusID | wtf (Billing.WithdrawToFunding) | Execution-level status |
| ModificationDate_WithdrawToFunding | ModificationDate | wtf (Billing.WithdrawToFunding) | Execution leg last modified |
| WithdrawPaymentID | ID | wtf (Billing.WithdrawToFunding) | WTF surrogate key |

---

## 3. Query Advisory

### 3.1 Distribution & Indexing

- **HASH(WithdrawID)**: Queries filtering on `WithdrawID` are single-node. Customer-level queries (by CID) require data movement across distributions.
- **Clustered Index**: WithdrawID ASC — efficient for point lookups and range scans by WithdrawID.
- **NCI on ExpirationDateID**: Supports card expiration-based queries (compliance, PCI reporting).

### 3.2 Data Freshness

- Daily incremental load based on `ModificationDate` in the source
- Post-load BIN enrichment depends on `Dim_CountryBin` being loaded first (blocking dependency with polling)
- `UpdateDate` reflects the ETL execution timestamp

---

## 4. Elements

> Note: Upstream production wikis available for Billing.Withdraw (9.5/10), Billing.WithdrawToFunding (9.1/10), and Billing.Funding. Tier 1 descriptions inherited verbatim from upstream where columns are passthrough or renamed. XML-extracted columns (parsed from WithdrawData/FundingData XML blobs via ExtractXMLValue) are Tier 2 because they are not table-level columns in the source — they are values inside an XML document.

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. (Tier 1 — Billing.Withdraw) |
| 2 | WithdrawID | int | YES | Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. (Tier 1 — Billing.Withdraw) |
| 3 | CurrencyID | int | YES | Currency of the withdrawal amount. FK to Dictionary.Currency. (Tier 1 — Billing.Withdraw) |
| 4 | FundingTypeID_Withdraw | int | YES | Payment method type of the withdrawal request (Visa/Wire/Neteller/eToroMoney/etc.). 26 distinct values in production. Renamed from FundingTypeID to disambiguate from Billing.Funding's FundingTypeID. (Tier 1 — Billing.Withdraw) |
| 5 | RequestDate | datetime | YES | Timestamp when the customer submitted the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 6 | Amount_Withdraw | money | YES | Gross withdrawal amount in CurrencyID denomination. Renamed from Amount to disambiguate from WithdrawToFunding Amount. (Tier 1 — Billing.Withdraw) |
| 7 | Commission | money | YES | Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers. (Tier 1 — Billing.Withdraw) |
| 8 | Approved | int | YES | Whether the withdrawal has received required approval. 1=Approved, 0=Pending approval. DEFAULT=0. DWH note: CAST from bit to int. (Tier 1 — Billing.Withdraw) |
| 9 | ModificationDate | datetime | YES | UTC timestamp of the most recent status change or update on the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 10 | ModificationDateID | int | YES | Integer date key derived from ModificationDate: CONVERT(INT, CONVERT(VARCHAR, ModificationDate, 112)). Format YYYYMMDD. Used for partition-style filtering and the DELETE/INSERT ETL pattern. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 11 | Fee | money | YES | Platform fee charged for this withdrawal. Subtracted from the gross Amount_Withdraw. (Tier 1 — Billing.Withdraw) |
| 12 | FundingID | int | YES | FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. (Tier 1 — Billing.Withdraw) |
| 13 | CashoutReasonID | int | YES | Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. (Tier 1 — Billing.Withdraw) |
| 14 | ClientWithdrawReasonID | int | YES | Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied). FK to Dim_ClientWithdrawReason. (Tier 1 — Billing.Withdraw) |
| 15 | AccountCurrencyID | int | YES | Customer eToro account currency, if different from CurrencyID. Used when account and withdrawal currencies differ. FK to Dim_Currency. (Tier 1 — Billing.Withdraw) |
| 16 | CashoutStatusID_Withdraw | int | YES | Withdrawal request-level status. FK to Dim_CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. Renamed from CashoutStatusID. (Tier 1 — Billing.Withdraw) |
| 17 | Comment | nvarchar(255) | YES | Operations comment on the withdrawal request. Free-text field populated by back-office staff. (Tier 1 — Billing.Withdraw) |
| 18 | FlowID | int | YES | Processing flow identifier. NULL=legacy, 0=standard, 2=eToroMoney (triggers MoveMoneyReasonID=5), 3=alternate (triggers MoveMoneyReasonID=6). (Tier 1 — Billing.Withdraw) |
| 19 | WithdrawTypeID | int | YES | Withdrawal type classification. NULL=legacy (55%), 0=standard (41%), 1=special/alternate (3.7%), 2=second alternate (0.5%). Added 2024-08-22. (Tier 1 — Billing.Withdraw) |
| 20 | CashoutStatusID_Funding | int | YES | Execution-level status of the payment leg. FK to Dim_CashoutStatus. Values: 3=Processed (31.5%), 4=Canceled (67.7%), 14=Pending Review, 17=Partially Reversed. Renamed from CashoutStatusID. (Tier 1 — Billing.WithdrawToFunding) |
| 21 | ProcessCurrencyID | int | YES | Currency used for the actual payment processing. May differ from withdrawal CurrencyID when cross-currency routing is applied. FK to Dim_Currency. (Tier 1 — Billing.WithdrawToFunding) |
| 22 | ExchangeRate | numeric(16,8) | YES | Exchange rate applied to convert from withdrawal currency to ProcessCurrencyID. NULL for same-currency payouts. (Tier 1 — Billing.WithdrawToFunding) |
| 23 | Amount_WithdrawToFunding | money | YES | Payout amount in ProcessCurrencyID currency. Renamed from Amount. For refunds, the amount being refunded to the instrument. (Tier 1 — Billing.WithdrawToFunding) |
| 24 | ModificationDate_WithdrawToFunding | datetime | YES | UTC timestamp of the most recent status change on the payment execution leg. Renamed from ModificationDate. (Tier 1 — Billing.WithdrawToFunding) |
| 25 | DepositID | int | YES | For refund legs (CashoutTypeID=2): references the source Billing.Deposit being refunded. Value 0 is null-equivalent for cashout legs. (Tier 1 — Billing.WithdrawToFunding) |
| 26 | CashoutTypeID | tinyint | YES | Categorizes the type of payment execution: 1=Cashout (standard withdrawal, 69%), 2=Refund (refund of a prior deposit, 31%). (Tier 1 — Billing.WithdrawToFunding) |
| 27 | VerificationCode | varchar(50) | YES | Verification code supplied or received during withdrawal processing. (Tier 1 — Billing.WithdrawToFunding) |
| 28 | ProcessorValueDate | datetime | YES | Value date from the payment processor — when funds are considered available. Set for wire/ACH payouts; NULL for instant methods. (Tier 1 — Billing.WithdrawToFunding) |
| 29 | DepotID | int | YES | Which Billing.Depot (acquirer/gateway configuration) processed this payment leg. FK to Dim_BillingDepot. (Tier 1 — Billing.WithdrawToFunding) |
| 30 | ExchangeFee | int | YES | Exchange fee in provider-specific integer units. (Tier 1 — Billing.WithdrawToFunding) |
| 31 | WithdrawPaymentID | int | YES | Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID. (Tier 1 — Billing.WithdrawToFunding) |
| 32 | BaseExchangeRate | numeric(16,8) | YES | Reference exchange rate before fee markup. Spread = ExchangeRate minus BaseExchangeRate. (Tier 1 — Billing.WithdrawToFunding) |
| 33 | ProtocolMIDSettingsID | int | YES | MID configuration profile used for this payment leg. FK to Dim_BillingProtocolMIDSettingsID. Default=0. (Tier 1 — Billing.WithdrawToFunding) |
| 34 | CashoutModeID | tinyint | YES | Mode of withdrawal execution: 1=Standard (75.2%), NULL=legacy (17%), 2=Alternate e.g. eToroMoney/ACH (4%), 0=Unknown/fallback (3.8%). FK to Dim_CashoutMode. (Tier 1 — Billing.WithdrawToFunding) |
| 35 | FundingTypeID_Funding | int | YES | Payment method type of the funding instrument receiving the payout. Renamed from FundingTypeID on Billing.Funding. 34 distinct types (Visa/MC/Neteller/PayPal/Wire/eToroMoney/etc.). FK to Dim_FundingType. (Tier 1 — Billing.Funding) |
| 36 | AccountIDAsString | nvarchar(max) | YES | Payment account identifier. COALESCE: prefers wtf.WithdrawData XML, falls back to bf.FundingData XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 37 | ACHBankAccountIDAsInteger | nvarchar(max) | YES | ACH bank account identifier for US bank transfers. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 38 | BinCodeAsString | nvarchar(max) | YES | Bank Identification Number (first 6-8 digits of card). COALESCE from wtf/bf XML. CAST to INT for JOIN with Dim_CountryBin to populate BankName and CardCategory. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 39 | BinCountryIDAsInteger | nvarchar(max) | YES | Country associated with the BIN code. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 40 | BSBNumberAsString | nvarchar(max) | YES | Bank State Branch number for Australian bank transfers. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 41 | CardTypeIDAsInteger | nvarchar(max) | YES | Card type identifier (Visa, Mastercard, etc.). COALESCE from wtf/bf XML. FK to Dim_CardType after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 42 | CityAsString | nvarchar(max) | YES | City from the payment execution data. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 43 | ClientAddressAsString | nvarchar(max) | YES | Client address from the payment execution data. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 44 | ClientBankNameAsString | nvarchar(max) | YES | Client's bank name. COALESCE from wtf/bf XML. Distinct from BankNameAsString (#67) which is from bf.FundingData only, and BankName (#82) which is post-load enrichment from Dim_CountryBin. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 45 | CountryIDAsInteger | nvarchar(max) | YES | Country identifier from payment data. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 46 | ExpirationDateAsString | nvarchar(max) | YES | Card expiration date as raw string from wtf.WithdrawData XML. Format varies by provider (MMYY, MM/YY, etc.). See ExpirationDateID (#69) for the normalized integer version. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 47 | ErrorCodeAsString | nvarchar(max) | YES | Provider error code if the payment leg failed or was rejected. Extracted from wtf.WithdrawData XML only. NULL for successful transactions. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 48 | IBANCodeAsString | nvarchar(max) | YES | International Bank Account Number for SEPA/wire transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 49 | InitialTransactionIDAsString | nvarchar(max) | YES | Initial transaction reference from the payment provider. Extracted from wtf.WithdrawData XML only. Links the withdrawal to the original deposit transaction for refund tracing. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 50 | MD5AsString | nvarchar(max) | YES | MD5 hash of payment data for verification/deduplication. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 51 | PayeeNameAsString | nvarchar(max) | YES | Payee name from the payment execution. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 52 | PayerPurseAsString | nvarchar(max) | YES | E-wallet purse identifier (e.g., PayPal, Neteller purse ID). Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 53 | ReferenceNumberAsString | nvarchar(max) | YES | Provider reference number for the transaction. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 54 | ResponseMessageAsString | nvarchar(max) | YES | Provider response message (success/failure details). Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 55 | ResponseTimeAsString | nvarchar(max) | YES | Provider response timestamp as string. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 56 | RoutingNumberAsString | nvarchar(max) | YES | Bank routing number for US bank transfers (ABA routing). COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 57 | SecuredCardDataAsString | nvarchar(max) | YES | Secured/tokenized card data from the payment provider. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 58 | SortCodeAsString | nvarchar(max) | YES | Bank sort code for UK bank transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 59 | SwiftCodeAsString | nvarchar(max) | YES | SWIFT/BIC code for international wire transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 60 | AccountIDAsDecimal | nvarchar(max) | YES | Funding instrument account ID (decimal form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 61 | AccountNameAsString | nvarchar(max) | YES | Account holder name on the funding instrument. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 62 | AccountTypeAsString | nvarchar(max) | YES | Account type (checking, savings, etc.). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 63 | BankAccountAsString | nvarchar(max) | YES | Bank account number for wire/bank transfers. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 64 | BankAddressAsString | nvarchar(max) | YES | Bank address for wire transfers. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 65 | BankCodeAsString | nvarchar(max) | YES | Bank code (national bank identifier). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 66 | BankDetailsAccountIDAsString | nvarchar(max) | YES | Bank details account reference. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 67 | BankIDAsInteger | nvarchar(max) | YES | Bank identifier (integer form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 68 | BankIDAsString | nvarchar(max) | YES | Bank identifier (string form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 69 | BankNameAsString | nvarchar(max) | YES | Bank name from the bf.FundingData XML. Distinct from the enriched BankName (#82) which comes from Dim_CountryBin BIN-code lookup, and ClientBankNameAsString (#44) which is COALESCE from wtf/bf. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 70 | CardNumberAsString | nvarchar(max) | YES | Masked card number (last 4 digits typically visible). Extracted from bf.FundingData XML only. Source column FundingData is masked with FUNCTION='default()' in production. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 71 | CryptoCodeAsString | nvarchar(max) | YES | Cryptocurrency code/address for crypto withdrawals. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 72 | CustomerAddressAsString | nvarchar(max) | YES | Customer address from the funding instrument record. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 73 | CustomerNameAsString | nvarchar(max) | YES | Customer name from the funding instrument record. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 74 | EmailAsString | nvarchar(max) | YES | Email address associated with the funding instrument (e.g., PayPal email). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 75 | ExpirationDateID | int | YES | Card expiration date as normalized integer key: 200000 + YY*100 + MM for valid dates; 190001 for NULL or strings shorter than 4 characters. NCI index on this column. Computed from bf.FundingData ExpirationDateAsString XML field. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 76 | InstrumentIDAsInteger | nvarchar(max) | YES | Instrument identifier within the funding provider. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 77 | MaskedAccountIDAsString | nvarchar(max) | YES | Masked version of the account ID for display/audit. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 78 | PayerIDAsString | nvarchar(max) | YES | Payer identifier (e.g., PayPal Payer ID). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 79 | PurseAsString | nvarchar(max) | YES | E-wallet purse identifier from the funding instrument. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 80 | SecureIDAsDecimal | nvarchar(max) | YES | Secure identifier for payment verification. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 81 | UpdateDate | datetime | YES | ETL load timestamp (Synapse server time at INSERT via GETDATE()). (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 82 | BankName | varchar(100) | YES | Issuing bank name looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.IssuingBank. NULL when BinCodeAsString is NULL or BIN code not found. Distinct from BankNameAsString (#69) which comes from the funding XML. (Tier 2 — SP_Fact_BillingWithdraw) |
| 83 | CardCategory | varchar(50) | YES | Card category (Debit, Credit, Prepaid, etc.) looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.CardCategory. NULL when BIN code not found. (Tier 2 — SP_Fact_BillingWithdraw) |

---

## 5. Lineage

### 5.1 Staging Sources (from DWH_staging)

| Alias | Staging Table | Production Source | Role |
|-------|--------------|-------------------|------|
| `bw` | `DWH_staging.etoro_Billing_Withdraw` | `Billing.Withdraw` | Withdrawal request (core facts) |
| `wtf` | `DWH_staging.etoro_Billing_WithdrawToFunding` | `Billing.WithdrawToFunding` | Payment execution leg + XML payment data |
| `bf` | `DWH_staging.etoro_Billing_Funding` | `Billing.Funding` | Funding instrument + XML funding data |

### 5.3 Internal DWH Dependencies

| Table | Role |
|-------|------|
| `DWH_dbo.Ext_FBW_Fact_BillingWithdraw` | Staging/external table for the 3-way join result |
| `DWH_dbo.Dim_CountryBin` | Post-load enrichment: BankName + CardCategory via BIN code |
| `DWH_dbo.ExtractXMLValue` (function) | Parses individual fields from XML blobs |

---

## 6. Relationships

### 6.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CID | Dim_Customer | CID = RealCID |
| CurrencyID / AccountCurrencyID / ProcessCurrencyID | Dim_Currency | CurrencyID = CurrencyID |
| FundingTypeID_Withdraw / FundingTypeID_Funding | Dim_FundingType | FundingTypeID = FundingTypeID |
| CashoutStatusID_Withdraw / CashoutStatusID_Funding | Dim_CashoutStatus | CashoutStatusID = CashoutStatusID |
| CashoutReasonID | Dim_CashoutReason | CashoutReasonID = CashoutReasonID |
| ClientWithdrawReasonID | Dim_ClientWithdrawReason | ClientWithdrawReasonID = ClientWithdrawReasonID |
| CashoutModeID | Dim_CashoutMode | CashoutModeID = CashoutModeID |
| DepotID | Dim_BillingDepot | DepotID = DepotID |
| ProtocolMIDSettingsID | Dim_BillingProtocolMIDSettingsID | ProtocolMIDSettingsID = ProtocolMIDSettingsID |
| BinCodeAsString (CAST INT) | Dim_CountryBin | CAST(BinCodeAsString AS INT) = BinCode |
| ModificationDateID | Dim_Date (implicit) | YYYYMMDD integer key |

### 6.2 Source Chain

```
Billing.Withdraw ──bw──┐
                        ├── LEFT JOIN ON WithdrawID ──► Ext_FBW_Fact_BillingWithdraw ──► Fact_BillingWithdraw
Billing.WithdrawToFunding ─wtf─┤                                                            │
                        ├── LEFT JOIN ON FundingID                                    POST-LOAD UPDATE
Billing.Funding ──bf────┘                                                                    │
                                                                                     Dim_CountryBin
                                                                                   (BankName, CardCategory)
```

### 6.3 Referenced By

*To be populated during cross-object enrichment (Phase 12).*

---

## 7. Sample Queries

```sql
-- Withdrawal details with status names
SELECT fbw.WithdrawID, fbw.CID, fbw.Amount_Withdraw, fbw.Fee,
       dcs.Name AS WithdrawStatus, dcs2.Name AS FundingStatus
FROM DWH_dbo.Fact_BillingWithdraw fbw
JOIN DWH_dbo.Dim_CashoutStatus dcs ON fbw.CashoutStatusID_Withdraw = dcs.CashoutStatusID
LEFT JOIN DWH_dbo.Dim_CashoutStatus dcs2 ON fbw.CashoutStatusID_Funding = dcs2.CashoutStatusID
WHERE fbw.ModificationDateID BETWEEN 20260301 AND 20260319;

-- Withdrawal fee analysis (regulatory pattern)
SELECT fbw.CID, fbw.WithdrawID, fbw.Amount_Withdraw, fbw.Fee,
       dft.Name AS FundingType, dcr.Name AS CashoutReason
FROM DWH_dbo.Fact_BillingWithdraw fbw
JOIN DWH_dbo.Dim_FundingType dft ON fbw.FundingTypeID_Withdraw = dft.FundingTypeID
LEFT JOIN DWH_dbo.Dim_CashoutReason dcr ON fbw.CashoutReasonID = dcr.CashoutReasonID
WHERE fbw.Fee > 0;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| Business & Regulatory Undertakings Monitoring Platform | Queries Fact_BillingWithdraw WHERE Fee>0 for withdrawal fee monitoring |
| Cashout Fee (Confluence) | Joins to Dim_CashoutReason, Dim_BillingDepot, Dim_FundingType for fee breakdowns |
| Deposits and withdrawals - DWH (Confluence) | Uses alongside Fact_BillingDeposit for combined payment flow analysis |

---
*Generated: 2026-03-19 | Quality: 8.5/10*
*Tiers: 34 T1, 49 T2, 0 T3, 0 T4, 0 T5 | Phases: 1,5,8,9,9B,10,10.5,13,11*


### Upstream `DWH_dbo.Dim_CashoutReason` — synapse
- **Resolved as**: `DWH_dbo.Dim_CashoutReason`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CashoutReason.md`

# DWH_dbo.Dim_CashoutReason

> 19-row replicated dimension table defining the reasons for initiating a cashout (withdrawal) -- from user-requested withdrawals and PI payments to risk refunds, account closures, and crypto transfers. Refreshed daily via TRUNCATE+INSERT from etoro.Dictionary.CashoutReason.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CashoutReason via SP_Dictionaries_DL_To_Synapse |
| **Refresh** | Daily (TRUNCATE + INSERT, 1440 min cycle) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CashoutReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_CashoutReason` is the Synapse DWH replica of the production `Dictionary.CashoutReason` lookup table. It holds exactly 19 rows, each representing a distinct reason why a withdrawal (cashout) was initiated. Every withdrawal recorded in `Billing.Withdraw` carries a `CashoutReasonID` that classifies the business context: standard user request (16), Popular Investor payment (14), affiliate payment (15), risk refund (3), account closure (12, 19), crypto transfer (18), and others.

The ETL is a straightforward TRUNCATE + INSERT inside `SP_Dictionaries_DL_To_Synapse`, pulling from the staging table `DWH_staging.etoro_Dictionary_CashoutReason` (which mirrors production `Dictionary.CashoutReason` via the Generic Pipeline Bronze export). The only column not inherited from production is `UpdateDate`, which is set to `GETDATE()` on each load.

This dimension is joined by downstream fact tables and BackOffice reporting procedures to resolve `CashoutReasonID` into its human-readable `Name`.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: The 19 cashout reasons fall into distinct business categories.

**Columns Involved**: `CashoutReasonID`, `Name`

**Rules**:
- **User-Initiated (16)**: Standard withdrawal requested by the customer. Default value in WithdrawRequestAdd.
- **Partner Payments (14, 15)**: Automated payments to Popular Investors (PI Payment) and Affiliates (Affiliate Payment). Special processing in WithdrawToFundingProcess.
- **Risk/Compliance (3, 7, 8)**: Risk refunds, 3rd party payment returns, bonus abuse adjustments.
- **Account Closures (6, 12, 17, 19)**: Forced withdrawals when accounts are blocked, foreclosed, or failed verification. CashoutReasonID=12 and 19 trigger special handling in processing.
- **Adjustments (1, 4, 5)**: Financial corrections -- general adjustments, negative balance fixes, withdrawal fee adjustments.
- **Technical/Operational (9, 10, 11, 13)**: Returned withdrawals, technical issues, underage account closures, test transactions.
- **Crypto (18)**: Withdrawal via crypto wallet transfer.

### 2.2 Special Processing by Reason

**What**: Specific CashoutReasonIDs trigger different downstream processing logic.

**Columns Involved**: `CashoutReasonID`

**Rules**:
- `Billing.WithdrawToFundingProcess` checks `CashoutReasonID IN (12, 14, 15)` -- foreclose, PI payment, and affiliate payment get special routing.
- `Billing.WithdrawRequestAdd` defaults `@CashoutReasonID=16` for standard user-initiated withdrawals.
- `Billing.WithdrawAndWithdrawToFundingAdd` defaults `@CashoutReasonID=18` for crypto wallet transfers.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (19 rows trivially replicated to all compute nodes). CLUSTERED INDEX on `CashoutReasonID ASC` -- zero JOIN overhead. All queries are instant at this table size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| List all cashout reasons | `SELECT * FROM DWH_dbo.Dim_CashoutReason ORDER BY CashoutReasonID` |
| Resolve reason name for a withdrawal | `JOIN Dim_CashoutReason ON CashoutReasonID` |
| Find closure-related reasons | `WHERE CashoutReasonID IN (6, 12, 17, 19)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact tables with CashoutReasonID | `ON f.CashoutReasonID = dcr.CashoutReasonID` | Resolve reason name for reporting |

### 3.4 Gotchas

- **Static 19 rows**: This is a fixed enumeration. New reasons require a production DDL insert into `Dictionary.CashoutReason`.
- **UpdateDate is ETL timestamp**: Reflects the last SP run (GETDATE()), not when the reason was created or modified in production.
- **No DWH surrogate key**: Unlike many Dim tables, there is no `DWHCashoutReasonID` column -- `CashoutReasonID` is used directly.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream production wiki | `(Tier 1 -- Dictionary.CashoutReason)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CashoutReasonID | int | NO | Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures. Values: 1=Adjustment, 2=Partners withdraw, 3=Risk Refund, 4=Negative Balance adjustment, 5=Withdraw fees adjustment, 6=Block account -- Not communicative, 7=3rd party payment, 8=Bonus abuse adjustment, 9=Returned withdraw, 10=Technical issue -- Customer side, 11=Underage, 12=Foreclose account, 13=Test, 14=PI Payment, 15=Affiliate Payment, 16=Requested by User, 17=Failed Verification, 18=Transfered by CryptoWallet, 19=ForClose(GAP). (Tier 1 -- Dictionary.CashoutReason) |
| 2 | Name | varchar(50) | NO | Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. (Tier 1 -- Dictionary.CashoutReason) |
| 3 | UpdateDate | datetime | NO | ETL run timestamp set to GETDATE() on each daily TRUNCATE+INSERT cycle. Reflects last SP_Dictionaries_DL_To_Synapse execution, not production modification time. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CashoutReasonID | etoro.Dictionary.CashoutReason | CashoutReasonID | Passthrough |
| Name | etoro.Dictionary.CashoutReason | Name | Passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.CashoutReason (production, 19 rows)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_CashoutReason
  |-- SP_Dictionaries_DL_To_Synapse ---|
      TRUNCATE Dim_CashoutReason
      INSERT CashoutReasonID, Name, GETDATE() AS UpdateDate
  v
DWH_dbo.Dim_CashoutReason (19 rows; daily TRUNCATE+INSERT)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_CashoutReason/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Billing.Withdraw | CashoutReasonID | Main withdrawal table stores reason |
| History.WithdrawAction | CashoutReasonID | Withdrawal action history stores reason |
| BackOffice.GetWithdrawRequests | CashoutReasonID | Withdrawal screen shows reason name |
| BackOffice.GetCashOutRequests_Main | CashoutReasonID | Main cashout screen shows reason |
| Billing.WithdrawToFundingProcess | CashoutReasonID | Special processing for IN (12, 14, 15) |
| Billing.WithdrawRequestAdd | @CashoutReasonID | Sets reason at withdrawal creation (default 16) |
| Billing.WithdrawAndWithdrawToFundingAdd | @CashoutReasonID | Crypto wallet transfers (default 18) |

---

## 7. Sample Queries

### 7.1 List all cashout reasons

```sql
SELECT CashoutReasonID,
       Name
FROM   [DWH_dbo].[Dim_CashoutReason]
ORDER BY CashoutReasonID;
```

### 7.2 Count withdrawals by cashout reason

```sql
SELECT dcr.Name            AS CashoutReason,
       COUNT(*)            AS WithdrawalCount
FROM   [DWH_dbo].[Fact_BillingWithdraw] fw
JOIN   [DWH_dbo].[Dim_CashoutReason] dcr
       ON fw.CashoutReasonID = dcr.CashoutReasonID
GROUP BY dcr.Name
ORDER BY WithdrawalCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream Dictionary.CashoutReason wiki and SP code analysis.

---

*Generated: 2026-04-28 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 | Elements: 3/3, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_CashoutReason | Type: Table | Production Source: etoro.Dictionary.CashoutReason*


### Upstream `DWH_dbo.Fact_SnapshotCustomer` — synapse
- **Resolved as**: `DWH_dbo.Fact_SnapshotCustomer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md`

# DWH_dbo.Fact_SnapshotCustomer

> Daily SCD Type 2 snapshot of every eToro customer's current state — the central customer-attribute table powering regulatory reporting, risk, and analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Ext_FSC_Real_Customer_Customer (CC), Ext_FSC_BackOffice_Customer (BO), Ext_FSC_BackOffice_RegulationChangeLog, Ext_FSC_Customer_FirstTimeDeposits, Ext_FSC_PhoneCustomer, Ext_FSC_StocksLending, Ext_Dim_Customer_CustomerIdentification_DLT |
| **Refresh** | Daily via MERGE (SP_Fact_SnapshotCustomer), orchestrated by SP_Fact_SnapshotCustomer_DL_To_Synapse |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX + NCI(RealCID ASC) |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked; matches `_generic_pipeline_mapping.json` generic_id=1115, `business_group` DWH). Unmasked PII export: `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid`. |
| **UC Format** | delta |
| **UC Partitioned By** | N/A (view is unpartitioned) |
| **UC Table Type** | Two UC targets: `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` (unmasked) + `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked) |

---

## 1. Business Meaning

Fact_SnapshotCustomer is the central customer state table in the DWH. For every eToro customer (RealCID), it holds one row per distinct attribute state within a year, recording which attributes were active between FromDate and ToDate (encoded together in `DateRangeID`). The pattern is SCD Type 2 by year: each year's rows are closed as attribute changes occur, and a new open row is created with the updated state. At year-end, all open rows are closed and reopened with the new year's date range.

As of 2026-03-19: **406M+ total rows**, **46.4M distinct customers**, data from **2007-08-22 to present**. 302M rows are "currently open" (ToDate = year-end). 11.9% of current open rows represent depositors; 98.0% are valid customers (IsValidCustomer=1).

The SP loads data from 6 source systems via staging Ext_FSC tables pre-populated by SP_Fact_SnapshotCustomer_DL_To_Synapse. The core CC (Customer Core) source provides demographics and status; the BO (Back Office) source provides risk/compliance attributes. RegulationID is taken from RegulationChangeLog — **not** from Back Office — because regulation changes take effect end-of-day.

8 legacy columns (DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist) are present in the DDL but NOT populated by the current SP. They carry DEFAULT (0) values.

---

## 2. Business Logic

### 2.1 SCD Type 2 Pattern — DateRangeID

**What**: Each customer-state row has a DateRangeID encoding both the open date (FromDate) and close date (ToDate) as a 12-digit bigint.

**Columns Involved**: `DateRangeID`, `RealCID`

**Rules**:
- DateRangeID = `YYYYMMDD` (open date, 8 chars) + `MMDDD` (year-end month+day, 4 chars) → e.g., `202603101231` = opened 2026-03-10, closes 2026-12-31
- When an attribute changes, the SP updates DateRangeID of the existing row to close it (right 4 chars become yesterday's MMDD), then inserts a new row with today's open date + year-end
- To get the **most current row** per customer: `RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'`
- On January 1st: all prior year's open rows are closed (12-31) and re-opened for the new year
- The `Dim_Range` dimension table stores FromDateID + ToDateID for each DateRangeID

### 2.2 IsValidCustomer — Segment Flag

**What**: Computed flag indicating whether a customer is a "valid" retail customer for analytics (excludes demo, blocked countries, excluded labels).

**Columns Involved**: `IsValidCustomer`, `PlayerLevelID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsValidCustomer = 1 IF:
  PlayerLevelID <> 4 (not demo)
  AND LabelID NOT IN (30, 26) (not internal/excluded label)
  AND CountryID <> 250 (not blocked country)
ELSE 0
```
Pre-2020-03-14 rule additionally excluded AccountTypeID=9.

### 2.3 IsCreditReportValidCB — Credit Reporting Flag

**What**: Flag indicating whether a customer is eligible for credit report validation (CB = CreditBureau context).

**Columns Involved**: `IsCreditReportValidCB`, `PlayerLevelID`, `AccountTypeID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsCreditReportValidCB = 1 IF:
  NOT (PlayerLevelID = 4 AND AccountTypeID <> 2)  (not non-real demo)
  AND LabelID NOT IN (26, 30)
  AND NOT (CountryID = 250 AND CID NOT IN (3400616, 10526243))
ELSE 0
```

### 2.4 RegulationID — End-of-Day Rule

**What**: A customer's regulatory jurisdiction is taken from RegulationChangeLog (end-of-day change), NOT from the back-office system (immediate change), because regulation changes take effect at end of day for business/legal reasons.

**Columns Involved**: `RegulationID`, sourced from `Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID`

### 2.5 GDPR Erasure Masking

**What**: When a GDPR deletion request is processed, the UserName in Customer Core gets a `DelUserName` prefix. The SP detects this and masks Email, City, Address, Zip, and PhoneNumber in Fact_SnapshotCustomer.

**Columns Involved**: `Email`, `City`, `Address`, `Zip`, `PhoneNumber`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) distribution + CCI makes per-customer aggregations and filters on RealCID highly efficient — queries that filter or join on RealCID benefit from colocation. The NCI on RealCID provides efficient point-lookup for single customers.

**Warning**: With 406M rows, full table scans are expensive. Always filter by DateRangeID or a specific year range when possible.

### 3.1b UC (Databricks) Storage

**In Databricks**, the data is accessed via `V_Fact_SnapshotCustomer_FromDateID` (generic_id=1115), not directly. Two UC targets:
- `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` — full PII (gated access)
- `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` — Email/City/Address/Zip masked

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current state for all customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Current state for one customer | `WHERE RealCID = @cid AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Customer state on a specific date | `WHERE RealCID = @cid AND LEFT(CAST(DateRangeID AS VARCHAR(12)),8) <= @date AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) >= RIGHT(@date, 4)` |
| Count of depositors | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsDepositor = 1` |
| Valid retail customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsValidCustomer = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON f.CountryID = dc.CountryID | Country name/region |
| DWH_dbo.Dim_Label | ON f.LabelID = dl.LabelID | Brand/label name |
| DWH_dbo.Dim_Language | ON f.LanguageID = dl.LanguageID | Customer language |
| DWH_dbo.Dim_VerificationLevel | ON f.VerificationLevelID = dv.VerificationLevelID | KYC verification status |
| DWH_dbo.Dim_PlayerStatus | ON f.PlayerStatusID = dp.PlayerStatusID | Account lifecycle status |
| DWH_dbo.Dim_Regulation | ON f.RegulationID = dr.RegulationID | Regulatory jurisdiction |
| DWH_dbo.Dim_AccountStatus | ON f.AccountStatusID = das.AccountStatusID | Account enabled/disabled |
| DWH_dbo.Dim_Range | ON f.DateRangeID = dr.DateRangeID | Decode FromDateID + ToDateID |
| DWH_dbo.Fact_Guru_Copiers | ON f.RealCID = fg.RealCID | Copy-trading activity |

### 3.4 Gotchas

- **DateRangeID is NOT a date** — it is a 12-digit bigint encoding (FromDate)(ToDate MMDD). Always extract with LEFT(...,8) for FromDate and RIGHT(...,4) for ToDate MMDD.
- **Most-current-row filter**: `RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` gets the currently open row, but after year-end closure this may temporarily return 0 rows. Use `MAX(DateRangeID)` per RealCID as a safer alternative.
- **Legacy columns with 0 defaults**: DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist are all DEFAULT 0 and NOT populated by the current SP. Do not rely on them.
- **PII masking**: Email, City, Address, Zip are dynamically masked (`MASKED WITH (FUNCTION = 'default()')`). Users without `UNMASK` permission see NULL. PhoneNumber is NOT masked at DDL level but is GDPR-erased via the SP for deleted users.
- **WeekendFeePrecentage** (note: typo in column name — "Precentage" instead of "Percentage") — use as-is.
- **AccountStatusID distribution**: 1=93.2% (Active), 0=6.1% (unknown/default), 2=0.9% (Inactive). Only 3 distinct values observed.
- **Not exported directly to UC** — join via `V_Fact_SnapshotCustomer_FromDateID` in UC.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 2 | RealCID | int | YES | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 3 | DemoCID | int | YES | [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL) |
| 4 | CustomerChangeTypeID | tinyint | YES | [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=Insert, 2=Update). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL) |
| 5 | CurentValue | int | YES | [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL) |
| 6 | PreviousValue | int | YES | [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL) |
| 7 | CountryID | int | YES | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 8 | LabelID | int | YES | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 9 | LanguageID | int | YES | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 10 | VerificationLevelID | int | YES | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 11 | DocsOK | smallint | YES | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 12 | PlayerStatusID | int | YES | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 13 | Bankruptcy | smallint | YES | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 14 | RiskStatusID | int | YES | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 15 | RiskClassificationID | int | YES | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 16 | CommunicationLanguageID | int | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 17 | PremiumAccount | smallint | YES | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 18 | Evangelist | smallint | YES | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 19 | GuruStatusID | smallint | YES | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 20 | UpdateDate | datetime | YES | DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 21 | RegulationID | tinyint | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 22 | AccountStatusID | int | YES | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 23 | AccountManagerID | int | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 24 | PlayerLevelID | int | YES | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 25 | AccountTypeID | int | YES | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 26 | DateRangeID | bigint | YES | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 27 | IsDepositor | bit | YES | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 28 | PendingClosureStatusID | tinyint | YES | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 29 | DocumentStatusID | int | YES | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 30 | SuitabilityTestStatusID | int | YES | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 31 | MifidCategorizationID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 32 | IsEmailVerified | int | YES | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 33 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 34 | DesignatedRegulationID | int | YES | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 35 | EvMatchStatus | int | YES | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 36 | RegionID | int | YES | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 37 | PlayerStatusReasonID | int | YES | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 38 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 39 | AffiliateID | int | YES | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 40 | Email | nvarchar(50) | YES | Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName='DelUserName*'. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 41 | City | nvarchar(50) | YES | Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 42 | Address | nvarchar(100) | YES | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 43 | Zip | nvarchar(50) | YES | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 44 | PhoneNumber | varchar(30) | YES | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 45 | IsPhoneVerified | bit | YES | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 46 | PhoneVerificationDateID | varchar(8) | YES | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 47 | PlayerStatusSubReasonID | int | YES | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 48 | WeekendFeePrecentage | int | YES | Weekend overnight fee percentage applied to this customer. Note: column name typo ("Precentage"). Source: Ext_FSC_Real_Customer_Customer.WeekendFeePrecentage (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 49 | DltStatusID | int | YES | DLT (Digital Ledger/Tangany) wallet status ID. DEFAULT 0. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 50 | DltID | nvarchar(100) | YES | DLT wallet identifier (Tangany ID). NULL if no DLT wallet. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 51 | EquiLendID | varchar(4000) | YES | EquiLend securities lending platform identifier. NULL if not enrolled in stocks lending. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 52 | StocksLendingStatusID | int | YES | Status of the customer's stocks lending enrollment. NULL if not enrolled. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source System | Source Object | Source Column | Transform |
|---------------|--------------|---------------|---------------|-----------|
| RealCID | Customer Core (CC) | Ext_FSC_Real_Customer_Customer | CID | Passthrough |
| GCID | CC / DLT | Ext_FSC_Real_Customer_Customer / Ext_Dim_Customer_CustomerIdentification_DLT | GCID | COALESCE(CC.GCID, FSC.GCID, DLT.GCID, 0) |
| CountryID | CC | Ext_FSC_Real_Customer_Customer | CountryID | COALESCE(CC, FSC, 0) |
| LabelID | CC | Ext_FSC_Real_Customer_Customer | LabelID | COALESCE(CC, FSC, 0) |
| LanguageID | CC | Ext_FSC_Real_Customer_Customer | LanguageID | COALESCE(CC, FSC, 0) |
| PlayerStatusID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusID | COALESCE(CC, FSC, 0) |
| CommunicationLanguageID | CC | Ext_FSC_Real_Customer_Customer | CommunicationLanguageID | COALESCE(CC, FSC, 0) |
| AccountStatusID | CC | Ext_FSC_Real_Customer_Customer | AccountStatusID | COALESCE(CC, FSC, 0) |
| PlayerLevelID | CC | Ext_FSC_Real_Customer_Customer | PlayerLevelID | COALESCE(CC, FSC, 0) |
| IsEmailVerified | CC | Ext_FSC_Real_Customer_Customer | IsEmailVerified | COALESCE(CC, FSC, 0) |
| PendingClosureStatusID | CC | Ext_FSC_Real_Customer_Customer | PendingClosureStatusID | COALESCE(CC, FSC, 0) |
| RegionID | CC | Ext_FSC_Real_Customer_Customer | RegionID | COALESCE(CC, FSC, 0) |
| PlayerStatusReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusReasonID | COALESCE(CC, FSC, 0) |
| PlayerStatusSubReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusSubReasonID | COALESCE(CC, FSC, 0) |
| WeekendFeePrecentage | CC | Ext_FSC_Real_Customer_Customer | WeekendFeePrecentage | COALESCE(CC, FSC) |
| AffiliateID | CC | Ext_FSC_Real_Customer_Customer | AffiliateID | COALESCE(CC, FSC, 0) |
| Email | CC | Ext_FSC_Real_Customer_Customer | Email | COALESCE(CC, FSC, '') + GDPR masking |
| City | CC | Ext_FSC_Real_Customer_Customer | City | COALESCE(CC, FSC, '') + GDPR masking |
| Address | CC | Ext_FSC_Real_Customer_Customer | Address | COALESCE(CC, FSC, '') + GDPR masking |
| Zip | CC | Ext_FSC_Real_Customer_Customer | Zip | COALESCE(CC, FSC, '') + GDPR masking |
| VerificationLevelID | Back Office (BO) | Ext_FSC_BackOffice_Customer | VerificationLevelID | COALESCE(BO, FSC, 0) |
| RiskStatusID | BO | Ext_FSC_BackOffice_Customer | RiskStatusID | COALESCE(BO, FSC, 0) |
| RiskClassificationID | BO | Ext_FSC_BackOffice_Customer | RiskClassificationID | COALESCE(BO, FSC, 0) |
| GuruStatusID | BO | Ext_FSC_BackOffice_Customer | GuruStatusID | COALESCE(BO, FSC, 0) |
| AccountTypeID | BO | Ext_FSC_BackOffice_Customer | AccountTypeID | COALESCE(BO, FSC, 0) |
| AccountManagerID | BO | Ext_FSC_BackOffice_Customer | AccountManagerID | COALESCE(BO, FSC, 0) |
| DocumentStatusID | BO | Ext_FSC_BackOffice_Customer | DocumentStatusID | COALESCE(BO, FSC, 0) |
| SuitabilityTestStatusID | BO | Ext_FSC_BackOffice_Customer | SuitabilityTestStatusID | COALESCE(BO, FSC, 0) |
| MifidCategorizationID | BO | Ext_FSC_BackOffice_Customer | MifidCategorizationID | COALESCE(BO, FSC, 0) |
| DesignatedRegulationID | BO | Ext_FSC_BackOffice_Customer | DesignatedRegulationID | COALESCE(BO, FSC, 0) |
| EvMatchStatus | BO | Ext_FSC_BackOffice_Customer | EvMatchStatus | COALESCE(BO, FSC, 0) |
| RegulationID | Regulation | Ext_FSC_BackOffice_RegulationChangeLog | ToRegulationID | COALESCE(RegChange, FSC.RegulationID, BO.RegulationID, 0) — end-of-day |
| IsDepositor | FTD | Ext_FSC_Customer_FirstTimeDeposits | CID | 1 if CID exists in FTD table |
| PhoneNumber | Phone | Ext_FSC_PhoneCustomer | PhoneNumber | COALESCE(Phone, FSC, '') |
| IsPhoneVerified | Phone | Ext_FSC_PhoneCustomer | PhoneVerifiedID | CASE WHEN PhoneVerifiedID IN (1,2) THEN 1 ELSE 0 |
| PhoneVerificationDateID | Phone | Ext_FSC_PhoneCustomer | PhoneVerificationDateID | COALESCE(Phone, FSC, ''); exclude 19000101 |
| DltStatusID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltStatusID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| DltID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| EquiLendID | StocksLending | ComplianceStateDB_Compliance_StocksLending | EquiLendID | via Ext_FSC_StocksLending |
| StocksLendingStatusID | StocksLending | ComplianceStateDB_Compliance_StocksLending | StocksLendingStatusID | via Ext_FSC_StocksLending |
| DateRangeID | ETL-computed | N/A | @date + year-end | convert(bigint, convert(varchar,@date,112) + right(convert(varchar,@largedate,112),4)) |
| IsValidCustomer | ETL-computed | N/A | N/A | CASE on PlayerLevelID, LabelID, CountryID |
| IsCreditReportValidCB | ETL-computed | N/A | N/A | CASE on PlayerLevelID, AccountTypeID, LabelID, CountryID |
| UpdateDate | ETL-computed | N/A | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Customer Core (CC) → etoro_History_Customer_Customer (CDC)
  → Ext_FSC_Real_Customer_Customer

Back Office (BO) → etoro_History_BackOfficeCustomer (CDC)
  → Ext_FSC_BackOffice_Customer
  → Ext_FSC_BackOffice_RegulationChangeLog

FTD System → CustomerFinanceDB_Customer_FirstTimeDeposits
  → Ext_FSC_Customer_FirstTimeDeposits

Phone Verification → ContactVerification_Phone_Customer
  → Ext_FSC_PhoneCustomer

DLT/Tangany → UserApiDB_Customer_CustomerIdentification
  → Ext_Dim_Customer_CustomerIdentification_DLT

Stocks Lending → ComplianceStateDB_Compliance_StocksLending
  → Ext_FSC_StocksLending

[All above via SP_Fact_SnapshotCustomer_DL_To_Synapse]
  → SP_Fact_SnapshotCustomer(@dt) [MERGE + DateRange update]
  → DWH_dbo.Fact_SnapshotCustomer
```

| Step | Object | Description |
|------|--------|-------------|
| Source Load | SP_Fact_SnapshotCustomer_DL_To_Synapse | Loads 6 Ext_FSC staging tables from DL, then calls inner SP |
| ETL | SP_Fact_SnapshotCustomer (Author: Boris Slutski, 2018-03-11) | MERGE: close existing rows + INSERT new rows + Dim_Range update |
| Target | DWH_dbo.Fact_SnapshotCustomer | DWH customer snapshot table |
| UC Export | V_Fact_SnapshotCustomer_FromDateID (generic_id=1115) | Daily Merge to UC (two targets: PII + masked) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country name/region |
| LabelID | DWH_dbo.Dim_Label | Brand/label name |
| LanguageID | DWH_dbo.Dim_Language | Language name |
| VerificationLevelID | DWH_dbo.Dim_VerificationLevel | KYC tier |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Account lifecycle status |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Real vs demo tier |
| RiskStatusID | DWH_dbo.Dim_RiskStatus | Risk status |
| RiskClassificationID | DWH_dbo.Dim_RiskClassification | Risk classification |
| GuruStatusID | DWH_dbo.Dim_GuruStatus | Popular Investor status |
| RegulationID / DesignatedRegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction |
| AccountStatusID | DWH_dbo.Dim_AccountStatus | Account enabled/disabled |
| AccountTypeID | DWH_dbo.Dim_AccountType | Account type |
| DocumentStatusID | DWH_dbo.Dim_DocumentStatus | KYC document status |
| MifidCategorizationID | DWH_dbo.Dim_MifidCategorization | MiFID II client category |
| PlayerStatusReasonID | DWH_dbo.Dim_PlayerStatusReasons | Status reason code |
| PlayerStatusSubReasonID | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| EvMatchStatus | DWH_dbo.Dim_EvMatchStatus | eVerify match status |
| PendingClosureStatusID | DWH_dbo.Dim_PendingClosureStatus | Closure status |
| DateRangeID | DWH_dbo.Dim_Range | SCD2 date range decode |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Guru_Copiers | RealCID | SP_Fact_Guru_Copiers joins FSC for guru/copier state |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | All columns | Databricks export view (generic_id=1115) |
| DWH_dbo.V_Fact_SnapshotCustomer | All columns | Alternative view (not in generic mapping) |
| DWH_dbo.Dim_Range | DateRangeID | SP inserts new DateRangeIDs into Dim_Range |

---

## 7. Sample Queries

### 7.1 Current customer state for a single customer

```sql
SELECT
    f.RealCID,
    f.GCID,
    f.AccountStatusID,
    f.PlayerStatusID,
    f.CountryID,
    f.RegulationID,
    f.IsDepositor,
    f.IsValidCustomer,
    f.DateRangeID,
    LEFT(CAST(f.DateRangeID AS VARCHAR(12)), 8) AS FromDateYYYYMMDD
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
WHERE f.RealCID = 12345678
  AND RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231';
```

### 7.2 Count of valid retail depositors by country (current snapshot)

```sql
SELECT
    dc.CountryName,
    COUNT(DISTINCT f.RealCID) AS depositor_count
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
JOIN [DWH_dbo].[Dim_Country] dc ON f.CountryID = dc.CountryID
WHERE RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231'
  AND f.IsDepositor = 1
  AND f.IsValidCustomer = 1
GROUP BY dc.CountryName
ORDER BY depositor_count DESC;
```

### 7.3 Customers who changed regulation during 2025 (history)

```sql
SELECT
    f.RealCID,
    f.Regula

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Range` — synapse
- **Resolved as**: `DWH_dbo.Dim_Range`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md`

# DWH_dbo.Dim_Range

> DWH-internal date range helper table mapping (FromDate, ToDate) pairs as composite keys, used by Snapshot analytics to efficiently join year-to-date and multi-period equity/customer snapshots.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH-internal (generated by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer) |
| **Refresh** | Daily - INSERT-only accumulation by Snapshot SPs |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DateRangeID, FromDateID, ToDateID) + 3 NCI indexes |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Range is a DWH-internal helper lookup that pre-computes all possible (FromDate, ToDate) date range pairs needed by the Snapshot analytics pipelines. Each row represents a unique start-to-end date interval, identified by a composite BigInt key (DateRangeID). The table enables efficient range-based JOINs in SnapshotEquity and SnapshotCustomer views without requiring date arithmetic at query time.

This table has no external production source. It is generated entirely within the DWH by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer, which INSERT new DateRangeID combinations as they encounter new date pairs during snapshot processing. The pattern is append-only - new rows are added daily but existing rows are never updated or deleted.

As of 2026-03-10, the table contains approximately 1.3 million date range pairs spanning from 2007-01-01 to 2026-03-10 on the FromDate side, and 2007-08-26 to 2026-12-31 on the ToDate side.

---

## 2. Business Logic

### 2.1 DateRangeID Encoding

**What**: DateRangeID is a deterministic composite key encoding both FromDate and MMDD(ToDate) into a single 12-digit BigInt.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- Formula: `DateRangeID = CONCAT(YYYYMMDD(FromDate), MMDD(ToDate))`
- Example: FromDateID=20070101, ToDateID=20071231 -> DateRangeID=200701011231
- Decoding FromDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 8))`
- Decoding ToDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 4) + RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4))`
- The YEAR component of ToDateID is always the SAME as the YEAR of FromDateID (only MMDD of ToDate is stored in the last 4 digits)

**Diagram**:
```
DateRangeID (12-digit BigInt):
  [ YYYY | MM | DD | MM | DD ]
  [  From Year  | From MMDD  | To MMDD ]
   |___________|             |________|
   Chars 1-8 = FromDateID    Chars 9-12 = MMDD(ToDate)

  ToDateID = YYYY(FromDate) + MMDD(ToDate)
  -> Year-end range example:
     FromDate=2020-03-15, ToDate=2020-12-31
     DateRangeID = 202003151231
     ToDateID    = 20201231
```

### 2.2 Snapshot Range Pattern

**What**: Dim_Range is the bridge between individual customer dates and fiscal/calendar year-end periods in Snapshot reports.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- The primary use case is "from customer registration/event date to year-end": FromDate = customer's start date, ToDate = December 31 of that year
- The SPs also generate non-year-end ranges when snapshots require partial-period measurements
- The table grows daily as new snapshot dates are processed
- No deduplication needed - DateRangeID uniqueness is enforced by the NOT EXISTS check in both SPs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a composite CLUSTERED INDEX on (DateRangeID, FromDateID, ToDateID) and three Non-Clustered Indexes: IX_Dim_Range_FromDateID, IX_Dim_Range_ToDateID, and IX_Dim_Range_FromDateID_ToDateID. The NCI indexes are unusual for Synapse (which typically uses only CCI) and suggest heavy range-based lookups by the Snapshot SPs. Always filter on FromDateID or ToDateID directly to leverage these indexes.

Note: PRIMARY KEY (DateRangeID) is declared NOT ENFORCED - Synapse does not validate uniqueness but the ETL SPs maintain it via NOT EXISTS guards.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` is Parquet. With 1.3M rows, consider filtering on FromDateID for performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find the DateRangeID for a specific (from, to) pair | `SELECT DateRangeID FROM DWH_dbo.Dim_Range WHERE FromDateID = @from AND ToDateID = @to` |
| Find all ranges starting from a given date | `WHERE FromDateID = @date` (uses IX_Dim_Range_FromDateID) |
| Look up range details from a DateRangeID | `SELECT FromDateID, ToDateID FROM DWH_dbo.Dim_Range WHERE DateRangeID = @id` |
| Check how many ranges exist for a year | `WHERE FromDateID BETWEEN @year*10000+101 AND @year*10000+1231` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_SnapshotEquity | DateRangeID | Resolve snapshot equity date ranges |
| DWH_dbo.Fact_SnapshotCustomer | DateRangeID | Resolve snapshot customer date ranges |
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | View-level access to snapshot equity with resolved ranges |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridging |

### 3.4 Gotchas

- **ToDate YEAR = FromDate YEAR**: The DateRangeID encoding only stores MMDD of ToDate. The year of ToDate is derived from FromDate's year. This means all ranges in this table are within-year ranges - cross-year ranges cannot be represented.
- **INSERT-only, no TRUNCATE**: Both writer SPs use NOT EXISTS guards, making the table append-only. Rows are never deleted. If a DateRangeID is erroneously created, it persists forever.
- **Primary key NOT ENFORCED**: Synapse does not verify uniqueness of DateRangeID. Trust the ETL logic, not the constraint.
- **DateRangeID is a STRING-derived number**: Always treat DateRangeID as a derived key, not a business ID. Decode using LEFT/RIGHT string operations if needed.
- **1.3M rows for a dim table**: Larger than typical dimensions. REPLICATE is appropriate given daily Snapshot SP joins from all distributions.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3b - DDL structure | `(Tier 3b - DDL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateRangeID | bigint | NO | Primary key (NOT ENFORCED). 12-digit composite key encoding FromDate and MMDD(ToDate). Formula: CONCAT(YYYYMMDD(From), MMDD(To)). Example: 200701011231 = From:20070101, To:20071231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 2 | FromDateID | int | NO | Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 3 | ToDateID | int | NO | End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 4 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() when the row was inserted. NULL for oldest rows (pre-UpdateDate tracking). Not a business date. (Tier 3b - DDL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateRangeID | DWH-internal (computed) | - | ETL-computed: CONCAT(YYYYMMDD(@date), MMDD(@largedate)) |
| FromDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 8) |
| ToDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 4) + RIGHT(DateRangeID, 4) |
| UpdateDate | - | - | ETL-computed: GETDATE() at insert time |

### 5.2 ETL Pipeline

```
SP_Fact_SnapshotEquity (daily) ---+
                                  +--> INSERT new DateRangeIDs --> DWH_dbo.Dim_Range
SP_Fact_SnapshotCustomer (daily) -+
```

| Step | Object | Description |
|------|--------|-------------|
| Writer 1 | SP_Fact_SnapshotEquity | INSERTs new (FromDate, ToDate) pairs from #outputdata temp table (Action='UPDATE') |
| Writer 2 | SP_Fact_SnapshotCustomer | INSERTs new (FromDate, ToDate) pairs from #outputdata and #UpdatedRanges temp tables |
| Guard | NOT EXISTS check | Both SPs use NOT EXISTS to prevent duplicate DateRangeIDs |
| Target | DWH_dbo.Dim_Range | Append-only. 1.3M rows as of 2026-03-10 |
| Export | Generic Pipeline (daily) | Exports to dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - DateRangeID, FromDateID, and ToDateID are DWH-internal keys with no external FK targets.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | Snapshot equity view with date range context |
| DWH_dbo.V_Fact_SnapshotEquity_FromDateID | DateRangeID / FromDateID | Snapshot equity filtered by customer registration date |
| DWH_dbo.V_Fact_SnapshotCustomer | DateRangeID | Snapshot customer view with date range context |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | DateRangeID / FromDateID | Snapshot customer filtered by registration date |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridge view |

---

## 7. Sample Queries

### 7.1 Decode a DateRangeID back to its components
```sql
SELECT
    DateRangeID,
    FromDateID,
    ToDateID,
    -- Verify encoding formula
    CONVERT(BIGINT,
        LEFT(CONVERT(VARCHAR(12), DateRangeID), 4)
        + RIGHT(CONVERT(VARCHAR(12), DateRangeID), 4)
    ) AS ToDateID_decoded
FROM [DWH_dbo].[Dim_Range]
WHERE DateRangeID = 200701011231
```

### 7.2 Find all year-end ranges (FromDate to Dec 31 of same year)
```sql
SELECT DateRangeID, FromDateID, ToDateID
FROM [DWH_dbo].[Dim_Range]
WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'
ORDER BY FromDateID DESC
```

### 7.3 Count ranges per year
```sql
SELECT
    LEFT(CAST(FromDateID AS VARCHAR(8)), 4) AS FromYear,
    COUNT(*) AS range_count
FROM [DWH_dbo].[Dim_Range]
GROUP BY LEFT(CAST(FromDateID AS VARCHAR(8)), 4)
ORDER BY FromYear DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.3/10 (★★★★☆) | Phases: 10/14*
*Tiers: 0 T1, 3 T2, 1 T3b, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Range | Type: Table | Production Source: DWH-internal (SP_Fact_SnapshotEquity + SP_Fact_SnapshotCustomer)*


### Upstream `DWH_dbo.Dim_Country` — synapse
- **Resolved as**: `DWH_dbo.Dim_Country`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md`

# DWH_dbo.Dim_Country

> Master country dimension (251 rows) mapping every country/territory to geographic, regulatory, marketing, and risk attributes. One of the most-referenced dimension tables in the DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Country (primary) + etoro.Dictionary.MarketingRegion (region label) + Ext_Dim_Country (EU flags) + Ext_Dim_Country_Region_Desk (desk/CFKey) + ComplianceStateDB.Compliance.RegulationCountry (regulation) |
| **Refresh** | Daily (SP_Dictionaries_Country_DL_To_Synapse, full TRUNCATE+INSERT + 3 UPDATE passes) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (non-clustered PK on CountryID NOT ENFORCED) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Country` is one of the most heavily-referenced dimension tables in the DWH. It defines every country and territory the eToro platform recognizes (251 rows: 250 active countries + 1 "Not available" placeholder at CountryID=0). Each row provides geographic classification, regulatory risk attributes, marketing segmentation, and compliance data for users registered from that country.

When a customer registers, their CountryID determines: which regulatory entity governs them (via RegulationID), what AML/KYC scrutiny level applies (IsHighRiskCountry, RiskGroupID), what marketing desk handles them (Desk), and whether they can receive RAF bonuses (IsEligibleForRAFBonusCountry).

The ETL is multi-step: TRUNCATE+INSERT from etoro.Dictionary.Country (primary, joined to etoro.Dictionary.MarketingRegion for the Region label), then three UPDATE passes that patch in EU classification from Ext_Dim_Country, Desk/CFKey from Ext_Dim_Country_Region_Desk, and RegulationID from ComplianceStateDB.Compliance.RegulationCountry. Several columns present in the upstream Dictionary.Country source are dropped in DWH (IsSettlementRestricted, DefaultCurrencyID, LanguageID, IsActive, PhonePrefix, IsoCode).

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, VERIFIED confidence).

---

## 2. Business Logic

### 2.1 High-Risk Country Flag (Computed)

**What**: IsHighRiskCountry is derived from RiskGroupID in the ETL, not passed through from source. AML-flagged countries trigger enhanced due diligence.

**Columns Involved**: `IsHighRiskCountry`, `RiskGroupID`

**Rules**:
- `CASE WHEN RiskGroupID IN (0, 4) THEN 0 ELSE 1 END` -> IsHighRiskCountry
- RiskGroupID=0 (None): 70 countries -> not high risk
- RiskGroupID=4 (Verified before deposit): 2 countries -> not high risk
- RiskGroupID=1 (High risk country): 100 countries -> high risk
- RiskGroupID=2 (High risk for new clients): 71 countries -> high risk
- RiskGroupID=3 (High risk FATF country): 8 countries -> high risk
- High-risk countries trigger enhanced document verification, manual review of first deposit, and reduced transaction monitoring thresholds

**Diagram**:
```
RiskGroupID -> IsHighRiskCountry
0 (None)                  -> 0  (70 countries)
4 (Verified bfr deposit)  -> 0  (2 countries)
1 (High risk)             -> 1  (100 countries)
2 (High risk new clients) -> 1  (71 countries)
3 (High risk FATF)        -> 1  (8 countries)
```

### 2.2 EU vs. European Country Classification

**What**: Two separate flags distinguish full EU membership from broader European geography.

**Columns Involved**: `EU`, `IsEuropeanCountry`

**Rules**:
- EU=1: 27 countries with full EU membership (legal/treaty member states)
- IsEuropeanCountry=1: 66 countries total (27 EU members + 39 other European countries)
- Source: Ext_Dim_Country (manual extension table), not from etoro.Dictionary.Country
- EU=1 always implies IsEuropeanCountry=1. IsEuropeanCountry=1 does NOT imply EU=1.

### 2.3 Region vs. MarketingRegion

**What**: DWH exposes two separate geographic segmentations. `Region` is marketing-driven; the source geographic `RegionID` is dropped.

**Columns Involved**: `Region`, `MarketingRegionID`, `MarketingRegionManualName`, `Desk`

**Rules**:
- `Region` is loaded from etoro.Dictionary.MarketingRegion.Name (y.Name AS Region in SP). It is the marketing region label.
- `MarketingRegionManualName` is a manual override from Ext_Dim_Country - may differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE).
- `Desk` is a sales/support desk assignment from Ext_Dim_Country_Region_Desk, joined via MarketingRegionID.
- The upstream Dictionary.Country source has a geographic `RegionID` pointing to Dictionary.Region - this is NOT loaded to DWH.
- 22 distinct Region values in DWH (South & Central America=40, Africa=38, ROW=38, French=23, etc.)

### 2.4 Dropped Source Columns (Compliance-Critical)

**What**: Several compliance and localization columns present in the upstream source are NOT loaded to DWH.

**Dropped from etoro.Dictionary.Country**:
- `IsSettlementRestricted`: 21 countries restricted to CFD-only trading (cannot hold REAL assets). Includes United States (SEC/FINRA). CRITICAL for compliance analysts.
- `DefaultCurrencyID`: Trading account default currency (USD/EUR/GBP/AUD/CAD/PLN).
- `LanguageID`: UI language default.
- `IsActive`: Whether country is active on platform.
- `PhonePrefix`: International dialing code.
- `IsoCode`: ISO 3166-1 numeric code.
- `RegionID`: Geographic region FK (DWH replaces with text Region label from MarketingRegion).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE (correct for a 251-row dimension - broadcast to all nodes avoids data movement on JOINs). HEAP means no sorted index. The non-clustered PK on CountryID is NOT ENFORCED - duplicates are theoretically possible but prevented by ETL TRUNCATE.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (251 rows). Z-ORDER on CountryID optional for join optimization.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode country for a customer | `JOIN DWH_dbo.Dim_Country d ON f.CountryID = d.CountryID` |
| Filter high-risk countries | `WHERE d.IsHighRiskCountry = 1` |
| Filter EU customers | `WHERE d.EU = 1` |
| Group by marketing region | `GROUP BY d.Region` |
| Find regulation for a country | `SELECT RegulationID FROM Dim_Country WHERE CountryID = @id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON c.CountryID = d.CountryID | Decode customer country attributes |
| DWH_dbo.Fact_BillingDeposit | ON f.CountryID = d.CountryID | Country-level deposit analytics |
| DWH_dbo.Dim_CountryBin | ON c.CountryID = d.CountryID | BIN-to-country card mapping |
| DWH_dbo.V_Dim_Customer | ON v.CountryID = d.CountryID | Customer view with country decode |

### 3.4 Gotchas

- CountryID=0 ("Not available") is a real row - use `WHERE CountryID > 0` to exclude the placeholder in population-level queries.
- `IsHighRiskCountry` is RECOMPUTED from `RiskGroupID` by the ETL (not passthrough from source). If source IsHighRiskCountry changes but RiskGroupID stays the same, DWH will not reflect the change.
- `IsSettlementRestricted` is NOT in DWH. This critical compliance flag must be looked up in the source etoro.Dictionary.Country if needed.
- `Region` reflects `MarketingRegion.Name`, not the geographic `Dictionary.Region`. The two segmentations differ (e.g., Albania: geographic region=Europe, marketing Region=ROE).
- `DWHCountryID` always equals `CountryID` (redundant copy from SP: `x.CountryID AS DWHCountryID`). Never use both in GROUP BY.
- `StatusID` is hardcoded to 1 for all rows (including CountryID=0). No meaningful variation.
- `InsertDate` and `UpdateDate` are both set to GETDATE() on each daily reload - they reflect ETL run time, not original insert or data change time.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. (Tier 1 - Dictionary.Country upstream wiki) |
| 2 | Abbreviation | char(2) | NO | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Unique per row. Used in UI display, API parameters, and geolocation matching. Trimmed on use (char type has trailing spaces). (Tier 1 - Dictionary.Country upstream wiki) |
| 3 | LongAbbreviation | char(3) | NO | ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). Unique per row. Used in some international reporting standards and Compliance.GetCountryLongAbbreviation (WorldCheck KYC/AML integration). (Tier 1 - Dictionary.Country upstream wiki) |
| 4 | Name | varchar(50) | NO | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) |
| 5 | IsHighRiskCountry | tinyint | YES | AML/compliance risk flag. 0=standard risk, 1=high risk. RECOMPUTED by SP from RiskGroupID: `CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END`. 179 high-risk countries. Triggers enhanced due diligence and stricter transaction monitoring. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 6 | Region | varchar(50) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows by SP. Intended to indicate active status. In practice carries no variation. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | DWHCountryID | int | NO | Redundant copy of CountryID (set to `x.CountryID AS DWHCountryID` in SP). Always equals CountryID. Retained for legacy compatibility. Do not use both CountryID and DWHCountryID in the same GROUP BY. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily full reload. Reflects ETL run time, not when country data actually changed. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 10 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate) on each daily full reload. Not a true insert timestamp - both dates are refreshed on every reload due to TRUNCATE+INSERT. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 11 | EU | int | YES | Whether this country is a full EU member state. 1=EU member (27 countries), 0=non-EU. Source: Ext_Dim_Country manual extension table (left join - NULL if not in Ext_Dim_Country). Always 0 or 1 in practice. Distinct from IsEuropeanCountry. (Tier 3 - Ext_Dim_Country live data) |
| 12 | Desk | nvarchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. (Tier 3 - Ext_Dim_Country_Region_Desk via SP) |
| 13 | RegulationID | int | YES | Regulatory entity ID governing users from this country. Loaded from ComplianceStateDB.Compliance.RegulationCountry via Ext_Dim_Country_Regulation staging. Left join - NULL if country not in compliance mapping. References the regulatory framework (e.g., CySEC, FCA, ASIC). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse via ComplianceStateDB) |
| 14 | CFKey | int | YES | Clearing/settlement framework key for this country's marketing region. Loaded from Ext_Dim_Country_Region_Desk.CFKey via MarketingRegionID join. Exact business meaning unclear - likely maps to a clearing firm or settlement category. (Tier 3 - Ext_Dim_Country_Region_Desk live data) |
| 15 | MarketingRegionID | int | YES | FK to etoro.Dictionary.MarketingRegion. Marketing segment ID grouping countries by marketing strategy. Distinct from geographic RegionID (which is dropped in DWH). 22 distinct values matching the 22 Region labels. (Tier 1 - Dictionary.Country upstream wiki) |
| 16 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. (Tier 1 - Dictionary.Country upstream wiki) |
| 17 | IsEligibleForRAFBonusCountry | int | YES | Whether users from this country can participate in the Refer-A-Friend bonus program. Source: CAST(etoro.Dictionary.Country.IsEligibleForRAFBonusCountry AS int) - type cast from bit to int. 1=eligible (most countries), 0=ineligible (regulatory/fraud restrictions). (Tier 1 - Dictionary.Country upstream wiki) |
| 18 | IsEuropeanCountry | int | YES | Whether this country is geographically European (broader than EU membership). 1=European (66 countries total: 27 EU + 39 others), 0=non-European. Source: Ext_Dim_Country manual extension table. Always >= EU flag. (Tier 3 - Ext_Dim_Country live data) |
| 19 | MarketingRegionManualName | varchar(50) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. (Tier 3 - Ext_Dim_Country live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | etoro.Dictionary.Country | CountryID | passthrough |
| Abbreviation | etoro.Dictionary.Country | Abbreviation | passthrough (nvarchar(max) -> char(2)) |
| LongAbbreviation | etoro.Dictionary.Country | LongAbbreviation | passthrough (nvarchar(max) -> char(3)) |
| Name | etoro.Dictionary.Country | Name | passthrough |
| IsHighRiskCountry | etoro.Dictionary.Country | RiskGroupID | computed: CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END |
| Region | etoro.Dictionary.MarketingRegion | Name | rename (y.Name AS Region via JOIN on MarketingRegionID) |
| StatusID | - | - | ETL-computed (hardcoded constant 1) |
| DWHCountryID | etoro.Dictionary.Country | CountryID | copy (x.CountryID AS DWHCountryID, always = CountryID) |
| UpdateDate | - | - | ETL-computed (GETDATE()) |
| InsertDate | - | - | ETL-computed (GETDATE()) |
| EU | DWH_dbo.Ext_Dim_Country | EU | UPDATE pass (LEFT JOIN on CountryID) |
| Desk | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| RegulationID | ComplianceStateDB.Compliance.RegulationCountry | RegulationID | UPDATE pass via Ext_Dim_Country_Regulation staging |
| CFKey | DWH_dbo.Ext_Dim_Country_Region_Desk | CFKey | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| MarketingRegionID | etoro.Dictionary.Country | MarketingRegionID | passthrough |
| RiskGroupID | etoro.Dictionary.Country | RiskGroupID | passthrough |
| IsEligibleForRAFBonusCountry | etoro.Dictionary.Country | IsEligibleForRAFBonusCountry | type cast (CAST(bit AS int)) |
| IsEuropeanCountry | DWH_dbo.Ext_Dim_Country | IsEuropeanCountry | UPDATE pass (LEFT JOIN on CountryID) |
| MarketingRegionManualName | DWH_dbo.Ext_Dim_Country | MarketingRegionManualName | UPDATE pass (LEFT JOIN on CountryID) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10).

### 5.2 ETL Pipeline

```
etoro.Dictionary.Country (x)
  -> [Generic Pipeline or direct load]
  -> DWH_staging.etoro_Dictionary_Country
  -> (JOIN) DWH_staging.etoro_Dictionary_MarketingRegion
  -> DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_Country (initial population: 19 cols partially loaded)
  -> UPDATE from DWH_dbo.Ext_Dim_Country (EU, IsEuropeanCountry, MarketingRegionManualName)
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Region_Desk (CFKey, Desk via MarketingRegionID)
  -> TRUNCATE+INSERT DWH_dbo.Ext_Dim_Country_Regulation from DWH_staging.ComplianceStateDB_Compliance_RegulationCountry
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Regulation (RegulationID)
  -> DWH_dbo.Dim_Country (fully loaded)
```

Note: The same SP also loads Dim_CountryIPAnonymous in the same transaction.

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Country | Master country reference (251 rows). 16-column source, DWH drops 8 columns. |
| Source | etoro.Dictionary.MarketingRegion | Marketing region labels. Provides Region text and MarketingRegionID. |
| Staging | DWH_staging.etoro_Dictionary_Country | Raw staging: 16 cols, HEAP ROUND_ROBIN. |
| ETL | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse | TRUNCATE + INSERT. Computes IsHighRiskCountry from RiskGroupID. Joins MarketingRegion. Hardcodes StatusID=1. Sets GETDATE() for UpdateDate/InsertDate. |
| Patch 1 | DWH_dbo.Ext_Dim_Country | Manual extension table: EU=1/0, IsEuropeanCountry=1/0, MarketingRegionManualName. LEFT JOIN on CountryID. |
| Patch 2 | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk and CFKey lookup by MarketingRegionID. LEFT JOIN on MarketingRegionID=RegionID. |
| Patch 3 | DWH_dbo.Ext_Dim_Country_Regulation | Regulation staging loaded from ComplianceStateDB.Compliance.RegulationCountry. Then LEFT JOIN on CountryID. |
| Target | DWH_dbo.Dim_Country | Final DWH dimension (251 rows). |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| MarketingRegionID | etoro.Dictionary.MarketingRegion | Marketing region segment. Implicit FK (not enforced in Synapse). |
| RiskGroupID | etoro.Dictionary.CountryRiskGroup | Country risk classification. Implicit FK (not enforced in Synapse). |
| RegulationID | ComplianceStateDB (Regulation) | Regulatory entity governing country users. Sourced from ComplianceStateDB. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | CountryID | Customer view JOINs to Dim_Country for country attributes. |
| DWH_dbo.Dim_CountryIP | CountryID | IP-to-country lookup table references Dim_Country via Abbreviation join. |
| DWH_dbo.Dim_CountryIPAnonymous | CountryID | Anonymous proxy IP table; CountryID set via Abbreviation-to-CountryID lookup against Dim_Country. |
| DWH_dbo.SP_Fact_BillingDeposit | CountryID | Billing deposit facts reference Dim_Country for country-level analytics. |
| BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table | CountryID | LTV modeling references country dimension. |
| BI_DB_dbo.SP_Group_LTV_Table | CountryID | Group LTV analytics references country dimension. |

---

## 7. Sample Queries

### 7.1 Decode customer country
```sql
SELECT c.CustomerID, d.Name AS Country, d.Region, d.IsHighRiskCountry
FROM [DWH_dbo].[Dim_Customer] c
JOIN [DWH_dbo].[Dim_Country] d ON c.CountryID = d.CountryID
WHERE d.IsHighRiskCountry = 1;
```

### 7.2 Countries by EU membership
```sql
SELECT CountryID, Name, Abbreviation, EU, IsEuropeanCountry, Region
FROM [DWH_dbo].[Dim_Country]
WHERE EU = 1
ORDER BY Name;
```

### 7.3 Risk group distribution
```sql
SELECT RiskGroupID, IsHighRiskCountry, COUNT(*) AS CountryCount
FROM [DWH_dbo].[Dim_Country]
WHERE CountryID > 0
GROUP BY RiskGroupID, IsHighRiskCountry
ORDER BY RiskGroupID;
```

### 7.4 RAF-ineligible countries by region
```sql
SELECT Region, Name, Abbreviation
FROM [DWH_dbo].[Dim_Country]
WHERE IsEligibleForRAFBonusCountry = 0 AND CountryID > 0
ORDER BY Region, Name;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, 16 VERIFIED columns).

---

*Generated: 2026-03-19 | Quality: 8.8/10 (4 stars) | Phases: 9/14 (full pipeline, no Atlassian)*
*Tiers: 6 T1, 8 T2, 5 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Country | Type: Table | Production Source: etoro.Dictionary.Country + etoro.Dictionary.MarketingRegion + Ext_Dim_Country + ComplianceStateDB*


### Upstream `DWH_dbo.Dim_PlayerLevel` — synapse
- **Resolved as**: `DWH_dbo.Dim_PlayerLevel`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md`

# DWH_dbo.Dim_PlayerLevel

> Lookup table defining the 7 eToro Club loyalty tiers (Bronze through Diamond plus Internal) with tier-specific cashout wait times and display sort order. NOTE: DWH drops the primary equity qualification thresholds (RealizedEquityFrom/To, DaysInRiskBeforeDowngrade) present in production.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PlayerLevel |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PlayerLevel defines the eToro Club loyalty program tiers that segment customers by their realized equity (account value). Each tier grants progressively better benefits: faster cashout processing, higher service priority, and dedicated account management. The tiers in ascending rank are: Bronze -> Silver -> Gold -> Platinum -> Platinum Plus -> Diamond, plus a special Internal tier for employee/test accounts.

The data originates from `etoro.Dictionary.PlayerLevel` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/PlayerLevel/` in the data lake. Production has 7 active tier rows (IDs 1-7); DWH adds a synthetic ID=0 N/A placeholder.

**CRITICAL SCHEMA DRIFT**: The DWH ETL loads only 8 of the production's 13 columns. The following production columns are DROPPED and not available in DWH: `RealizedEquityFrom`, `RealizedEquityTo` (the primary tier qualification thresholds), `IsWalletRedeemAllowed`, `ThresholdPercentToCurrentLevel`, and `DaysInRiskBeforeDowngrade`. For tier qualification logic, query the upstream `etoro.Dictionary.PlayerLevel` directly or the upstream wiki. The DWH table is suitable only for resolving tier names and cashout hours -- not for equity-based tier evaluation.

Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from staging, followed by a separate INSERT VALUES for the ID=0 N/A sentinel using `@ddate` (midnight timestamp). Refreshes daily.

---

## 2. Business Logic

### 2.1 Tier Hierarchy and Rank Order

**What**: Six customer-facing loyalty tiers plus one internal tier, ranked by realized equity.

**Columns Involved**: `PlayerLevelID`, `Name`, `Sort`

**Rules**:
- IDs are NOT in rank order -- use `Sort` column for display ordering.
- Sort order: 0=Internal (excluded), 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond.
- Internal (ID=4) is excluded from customer-facing reports: `WHERE PlayerLevelID <> 4`.
- ID=0 (N/A) is a DWH-only ETL placeholder for NULL FK safety. Not in production.

**Diagram**:
```
Tier Hierarchy (by Sort/Rank):
  Sort 1 = Bronze     (ID=1) -- entry level
  Sort 2 = Silver     (ID=5)
  Sort 3 = Gold       (ID=3)
  Sort 4 = Platinum   (ID=2)
  Sort 5 = Platinum + (ID=6)
  Sort 6 = Diamond    (ID=7) -- top tier
  Sort 0 = Internal   (ID=4) -- excluded
  (ID=0  = N/A       -- DWH ETL placeholder)
```

### 2.2 Cashout Processing Speed by Tier

**What**: Higher tiers receive priority cashout processing as a loyalty benefit.

**Columns Involved**: `CashoutPendingHours`

**Rules**:
- **120 hours (5 days)**: Bronze (1), Silver (5), Internal (4), N/A (0)
- **72 hours (3 days)**: Gold (3)
- **24 hours (1 day)**: Platinum (2), Platinum Plus (6), Diamond (7)
- This is one of the most impactful benefits of upper tier membership.

### 2.3 Legacy Lot/Deposit Thresholds (Deprecated)

**What**: Historical tier qualification fields -- superseded by RealizedEquity (not in DWH).

**Columns Involved**: `FromSumLotCount`, `ToSumLotCount`, `FromSumDeposit`, `ToSumDeposit`

**Rules**:
- All set to `-1` for Platinum (2), Platinum Plus (6), Diamond (7) -- meaning "disabled/not applicable".
- Bronze (1) has 1-3000 lots, $0-$999 deposit; Silver (5) has 3001-20000 lots, $1000-$4999; Gold (3) has 20001-100000 lots, $5000-$19999.
- These columns are legacy artifacts. The current tier system uses `RealizedEquityFrom/To` which are NOT loaded into DWH.
- Value -1 = "threshold disabled -- upper tier, equity-based qualification only".

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP index. HEAP (no clustering) is unusual for dimension tables -- most Dim_ tables use CLUSTERED INDEX. With only 8 rows, HEAP is not a concern for performance but means scans are unordered. Always use `ORDER BY Sort` for consistent tier display.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`. With 8 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What tier is a customer in? | JOIN Dim_Customer ON PlayerLevelID for Name |
| Tier distribution of customer base | GROUP BY PlayerLevelID, exclude Internal (ID=4) |
| Display tiers in rank order | ORDER BY Sort ASC, exclude ID=0 and ID=4 |
| Cashout processing time for a tier | SELECT CashoutPendingHours WHERE PlayerLevelID = X |
| What are the equity thresholds? | NOT available in DWH -- use upstream wiki or prod data |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PlayerLevelID = dpl.PlayerLevelID | Resolve tier name per customer |
| DWH_dbo.V_Dim_Customer | ON vdc.PlayerLevelID = dpl.PlayerLevelID | View-level tier resolution |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PlayerLevelID = dpl.PlayerLevelID | Tier in daily snapshots |

### 3.4 Gotchas

- **IDs are NOT in rank order**: PlayerLevelID 2=Platinum, 3=Gold, 5=Silver. Always use `Sort` for ordering tiers. Filtering `PlayerLevelID > 3` does NOT mean "higher than Gold".
- **Internal tier (ID=4)**: Must be excluded in most customer analytics: `WHERE PlayerLevelID <> 4` or `WHERE PlayerLevelID NOT IN (0, 4)`.
- **-1 in range columns means disabled**: For Platinum/Platinum Plus/Diamond, FromSumLotCount=-1 and ToSumLotCount=-1 indicate the legacy lot-count threshold is not used. Do NOT interpret -1 as a valid lot count.
- **Critical columns missing from DWH**: `RealizedEquityFrom`, `RealizedEquityTo`, `DaysInRiskBeforeDowngrade`, `ThresholdPercentToCurrentLevel`, and `IsWalletRedeemAllowed` are ALL in production but NOT in DWH. For equity-tier evaluation, use the upstream source.
- **HEAP index**: Unlike most DWH Dim_ tables, this uses HEAP (no CCI). Row order is not guaranteed without explicit ORDER BY.
- **ID=0 midnight timestamp**: The N/A placeholder (ID=0) has midnight InsertDate/UpdateDate from `@ddate = CAST(GETDATE() AS DATE)`, while production rows have full timestamps from GETDATE().

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlayerLevelID | int | NO | Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 2 | Name | varchar(50) | NO | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 3 | CashoutPendingHours | int | NO | Maximum hours a cashout request waits before processing. 24=1 day (Platinum/Platinum Plus/Diamond), 72=3 days (Gold), 120=5 days (Bronze/Silver/Internal). Key loyalty benefit -- higher tiers get faster withdrawals. 0 for N/A placeholder. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 4 | FromSumLotCount | int | NO | Legacy: minimum cumulative lot count for tier qualification. Set to -1 for upper tiers (Platinum/Platinum Plus/Diamond -- threshold disabled). Superseded by RealizedEquityFrom (not loaded in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 5 | ToSumLotCount | int | NO | Legacy: maximum cumulative lot count for tier qualification. Set to -1 for upper tiers (threshold disabled). Superseded by RealizedEquityTo (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 6 | FromSumDeposit | int | NO | Legacy: minimum cumulative deposit (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquityFrom (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 7 | ToSumDeposit | int | NO | Legacy: maximum cumulative deposit (USD) for tier qualification. Set to -1 for upper tiers (disabled). Superseded by RealizedEquityTo (not in DWH). 0 for ID=0 and Internal. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 8 | Sort | int | NO | Display order for tier hierarchy. 0=Internal/N/A, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Platinum Plus, 6=Diamond. Use ASC sort on this column for correct tier rank ordering. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 9 | DWHPlayerLevelID | int | NO | DWH surrogate key -- always equals PlayerLevelID (redundant copy). Set by ETL: SELECT [PlayerLevelID] AS [DWHPlayerLevelID]. 0 for ID=0 sentinel. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 10 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() for production rows; set to @ddate (midnight) for the ID=0 N/A sentinel. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 11 | InsertDate | datetime | NO | ETL load timestamp -- set to GETDATE() for production rows; set to @ddate (midnight) for the ID=0 N/A sentinel. Does not reflect production insert time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 12 | StatusID | tinyint | NO | Hardcoded to 1 (active) for all rows by the ETL. Not derived from production source. DWH ETL convention for dictionary tables loaded by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlayerLevelID | Dictionary.PlayerLevel | PlayerLevelID | passthrough |
| Name | Dictionary.PlayerLevel | Name | passthrough |
| CashoutPendingHours | Dictionary.PlayerLevel | CashoutPendingHours | passthrough |
| FromSumLotCount | Dictionary.PlayerLevel | FromSumLotCount | passthrough |
| ToSumLotCount | Dictionary.PlayerLevel | ToSumLotCount | passthrough |
| FromSumDeposit | Dictionary.PlayerLevel | FromSumDeposit | passthrough |
| ToSumDeposit | Dictionary.PlayerLevel | ToSumDeposit | passthrough |
| Sort | Dictionary.PlayerLevel | Sort | passthrough |
| DWHPlayerLevelID | -- | -- | ETL-computed: = PlayerLevelID (redundant surrogate) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() (or @ddate for ID=0 sentinel) |
| InsertDate | -- | -- | ETL-computed: GETDATE() (or @ddate for ID=0 sentinel) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |

**Dropped from production (schema drift)**: IsWalletRedeemAllowed, RealizedEquityFrom, RealizedEquityTo, ThresholdPercentToCurrentLevel, DaysInRiskBeforeDowngrade.

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PlayerLevel.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PlayerLevel
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PlayerLevel/
  -> DWH_staging.etoro_Dictionary_PlayerLevel
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT SELECT + INSERT VALUES for ID=0)
  -> DWH_dbo.Dim_PlayerLevel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PlayerLevel | Production tier dictionary (etoroDB-REAL) -- 13 cols, 7 rows |
| Lake | Bronze/etoro/Dictionary/PlayerLevel/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PlayerLevel | Raw staging import -- 8 passthrough cols only |
| ETL step 1 | SP_Dictionaries_DL_To_Synapse (line ~931) | TRUNCATE + INSERT SELECT; adds 4 computed cols; drops 5 production cols |
| ETL step 2 | SP_Dictionaries_DL_To_Synapse (line ~1538) | INSERT VALUES for ID=0 N/A sentinel using @ddate (midnight) |
| Target | DWH_dbo.Dim_PlayerLevel | 8 rows, 12 cols, REPLICATE + HEAP |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PlayerLevelID | Customer's current loyalty tier |
| DWH_dbo.V_Dim_Customer | PlayerLevelID | View exposing tier for customer dimension |
| DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Daily snapshot of customer tier |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PlayerLevelID | Year-end snapshot tier |

---

## 7. Sample Queries

### 7.1 List all tiers in rank order

```sql
SELECT PlayerLevelID,
       Name,
       Sort,
       CashoutPendingHours
FROM   [DWH_dbo].[Dim_PlayerLevel]
WHERE  PlayerLevelID NOT IN (0, 4)   -- exclude N/A and Internal
ORDER BY Sort ASC;
```

### 7.2 Count customers by tier (excluding internal)

```sql
SELECT  dpl.Name             AS Tier,
        dpl.Sort,
        COUNT(*)             AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerLevel] dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.PlayerLevelID NOT IN (0, 4)
GROUP BY dpl.Name, dpl.Sort
ORDER BY dpl.Sort;
```

### 7.3 Identify customers in premium tiers (24h cashout)

```sql
SELECT  dc.CID,
        dpl.Name  AS Tier,
        dpl.CashoutPendingHours
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PlayerLevel] dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
WHERE   dpl.CashoutPendingHours = 24   -- Platinum, Platinum Plus, Diamond
ORDER BY dc.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (*****) | Phases: 11/14*
*Tiers: 8 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PlayerLevel | Type: Table | Production Source: etoro.Dictionary.PlayerLevel*


### Upstream `DWH_dbo.Dim_GuruStatus` — synapse
- **Resolved as**: `DWH_dbo.Dim_GuruStatus`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md`

# DWH_dbo.Dim_GuruStatus

> Popular Investor (Guru) status dimension - maps integer codes to eToro Popular Investor program tier labels, from "No" (not enrolled) through Cadet, Rising Star, Champion, Elite, and Elite Pro, plus Removed and Rejected states.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.GuruStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (GuruStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_GuruStatus` is a 9-row dictionary classifying eToro customers in the **Popular Investor (PI) program** (internally called "Guru"). The PI program allows experienced traders to earn income by being copied; status reflects their tier and program standing.

The status ladder (active tiers):
- 0 = No: Customer is not enrolled in the Popular Investor program
- 1 = Certified: Entry-level PI certification
- 2 = Cadet: First active tier of the PI program
- 3 = Rising Star: Second tier - growing following
- 4 = Champion: Third tier
- 5 = Elite: Fourth tier - top performers
- 6 = Elite Pro: Highest active tier - professional Popular Investors

Negative states:
- 7 = Removed: Previously enrolled, now removed from the program
- 8 = Rejected: Applied but rejected from the program

**GuruStatusID=0 (No)** serves as both the "not enrolled" value and the null-safe join sentinel: SP_Dim_Customer uses `ISNULL(GuruStatusID, 0)` to coerce NULLs to 0.

The data originates from `etoro.Dictionary.GuruStatus` via `DWH_staging.etoro_Dictionary_GuruStatus`. ETL: TRUNCATE + INSERT, `Name` renamed to `GuruStatusName`.

Consumers: `Dim_Customer` (each customer's current PI status), `Fact_SnapshotCustomer` (daily PI status snapshot), `Fact_CustomerAction_DL_To_Synapse` (PI status at action time).

---

## 2. Business Logic

### 2.1 Popular Investor Tier Ladder

**What**: Active PI statuses represent a progression from entry-level to elite.

**Columns Involved**: `GuruStatusID`, `GuruStatusName`

**Rules**:
```
Tier progression (active):
  No (0) -> Certified (1) -> Cadet (2) -> Rising Star (3)
         -> Champion (4) -> Elite (5) -> Elite Pro (6)

Negative states (off-ladder):
  Removed (7): was in program, exited
  Rejected (8): applied, not accepted
```

**For analysis**: GuruStatusID > 0 AND < 7 = currently active in PI program. GuruStatusID = 0 = regular customer.

### 2.2 Null-Sentinel Pattern

**What**: GuruStatusID=0 (No) absorbs NULL values from Dim_Customer.

**Columns Involved**: `GuruStatusID`

**Rules**:
- SP_Dim_Customer: `ISNULL(GuruStatusID, 0) AS GuruStatusID` (customers with no PI enrollment get ID 0)
- SP_Dim_Customer change detection: `OR ISNULL(dc.GuruStatusID, 0) <> ISNULL(a.GuruStatusID, 0)`
- Meaning: NULL and 0 are semantically equivalent (not in PI program)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (9 rows - appropriate). CLUSTERED INDEX on GuruStatusID. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 9 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode GuruStatusID to name | `LEFT JOIN DWH_dbo.Dim_GuruStatus ON GuruStatusID` |
| Find active Popular Investors | `WHERE GuruStatusID BETWEEN 1 AND 6` |
| Exclude regular customers | `WHERE GuruStatusID > 0 AND GuruStatusID < 7` |
| Count customers by PI tier | `GROUP BY GuruStatusName ORDER BY GuruStatusID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON GuruStatusID | Customer's current Popular Investor status |
| DWH_dbo.Fact_SnapshotCustomer | ON GuruStatusID | Daily PI status snapshot per customer |
| DWH_dbo.Fact_CustomerAction | ON GuruStatusID | PI status at time of action |

### 3.4 Gotchas

- **ID=0 is NOT null**: GuruStatusID=0 means "No" (not in PI program). It is the semantic null sentinel. Do not filter it out when showing all customers - it represents the majority.
- **Active PI filter**: To find active Popular Investors, use `GuruStatusID BETWEEN 1 AND 6`. IDs 7 (Removed) and 8 (Rejected) are ex-PI or rejected applicants and should be excluded from "active PI" counts.
- **Tiers imply rank**: GuruStatusID 1-6 form a meaningful rank ordering (lower = less established). Use ORDER BY GuruStatusID for tier comparisons.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| **** | Tier 1 | Upstream Dictionary wiki (DB_Schema), verbatim |
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GuruStatusID | int | NO | Primary key identifying the PI program state. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Referenced by BackOffice.Customer (FK), Billing.GuruStatusToCashoutFeeGroup (FK). Filtered as IN (2,3,4,5) for active PIs or IN (2,3,4,5,6) including Elite Pro. (Tier 1 — Dictionary.GuruStatus) |
| 2 | GuruStatusName | varchar(50) | NO | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 — Dictionary.GuruStatus) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GuruStatusID | etoro.Dictionary.GuruStatus | GuruStatusID | passthrough |
| GuruStatusName | etoro.Dictionary.GuruStatus | Name | rename: Name -> GuruStatusName |
| UpdateDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.GuruStatus -> Generic Pipeline -> DWH_staging.etoro_Dictionary_GuruStatus -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 718) -> DWH_dbo.Dim_GuruStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.GuruStatus | Guru/PI status dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/GuruStatus/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_GuruStatus | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Name -> GuruStatusName rename. UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_GuruStatus | 9-row REPLICATE/CLUSTERED PI status dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | GuruStatusID | Customer's current Popular Investor tier |
| DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | Daily PI status snapshot per customer |
| DWH_dbo.Fact_CustomerAction | GuruStatusID | PI status at time of customer action |

---

## 7. Sample Queries

### 7.1 All Guru status values

```sql
SELECT GuruStatusID, GuruStatusName
FROM DWH_dbo.Dim_GuruStatus
ORDER BY GuruStatusID
```

### 7.2 Count active Popular Investors by tier

```sql
SELECT gs.GuruStatusName, COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_GuruStatus gs ON dc.GuruStatusID = gs.GuruStatusID
WHERE dc.GuruStatusID BETWEEN 1 AND 6
GROUP BY gs.GuruStatusID, gs.GuruStatusName
ORDER BY gs.GuruStatusID
```

### 7.3 PI tier distribution across all customers

```sql
SELECT gs.GuruStatusName, COUNT(*) AS CustomerCount,
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS Pct
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_GuruStatus gs ON dc.GuruStatusID = gs.GuruStatusID
GROUP BY gs.GuruStatusID, gs.GuruStatusName
ORDER BY gs.GuruStatusID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 9/10, Sources: 7/10*
*Object: DWH_dbo.Dim_GuruStatus | Type: Table | Production Source: etoro.Dictionary.GuruStatus*


### Upstream `DWH_dbo.Dim_AccountType` — synapse
- **Resolved as**: `DWH_dbo.Dim_AccountType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md`

# DWH_dbo.Dim_AccountType

> Lookup dimension classifying eToro accounts by ownership type and purpose. Controls feature access, regulatory treatment, fee structures, and compliance monitoring. Sourced daily from etoro.Dictionary.AccountType via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.AccountType |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_AccountType is the DWH version of etoro.Dictionary.AccountType. It classifies every eToro account into one of 18 categories based on ownership structure and operational purpose. This classification drives which platform features are available, what regulatory rules apply, how fees are calculated, and how accounts are monitored for compliance.

Source: etoro.Dictionary.AccountType on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Dictionary/AccountType/ and staged into DWH_staging.etoro_Dictionary_AccountType. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern.

The DWH table has 19 rows: IDs 0-18. ID=0 (N/A) is a DWH placeholder row from the production source itself (no separate placeholder insert in the SP). DWHAccountTypeID is set equal to AccountTypeID by the ETL and carries no additional information. StatusID is hardcoded to 1. UpdateDate and InsertDate are both set to GETDATE() at load time.

Account types are assigned at customer registration and stored in Customer.CustomerStatic. They are read across BackOffice, Trade, Hedge, Billing, and Compliance systems. The account type rarely changes after initial assignment.

---

## 2. Business Logic

### 2.1 Account Category Groups

**What**: Account types cluster into functional groups that determine system behavior, regulatory treatment, and fee structures.

**Columns Involved**: `AccountTypeID`, `Name`

**Rules**:
- Retail accounts (1=Private, 4=Joint, 14=SMSF, 16=Administrated): Standard users subject to full retail regulation
- Corporate accounts (2=Corporate, 15=Affiliate Corporate): Business entities with enhanced KYC and reporting
- Partner accounts (3=IB, 5=White Label, 6=Affiliate Private, 12=White List): Revenue-sharing arrangements with special fee/commission structures
- Internal accounts (7=Employee, 10=eToro Group, 11=News, 13=Analyst, 17=Funded Employee): eToro-operated accounts with enhanced compliance monitoring
- Managed accounts (8=Custodian, 9=Fund): Third-party managed accounts with fiduciary requirements
- 18=Trust: Registered after the upstream wiki was generated; classification consistent with retail/managed category
- AccountTypeID=0 (N/A): DWH placeholder for NULL-safe JOINs

**Value Map** (19 rows in DWH):

| AccountTypeID | Name | Category |
|---|---|---|
| 0 | N/A | DWH placeholder |
| 1 | Private | Retail |
| 2 | Corporate | Corporate |
| 3 | IB Account | Partner |
| 4 | Joint Account | Retail |
| 5 | White Label | Partner |
| 6 | Affiliate Private Account | Partner |
| 7 | Employee Account | Internal |
| 8 | Custodian | Managed |
| 9 | Fund | Managed |
| 10 | eToro Group Account | Internal |
| 11 | News | Internal |
| 12 | White List | Partner |
| 13 | Analyst | Internal |
| 14 | SMSF | Retail |
| 15 | Affiliate Corporate Account | Corporate |
| 16 | Administrated Account | Retail |
| 17 | Funded Employee Account | Internal |
| 18 | Trust | Retail/Managed |

### 2.2 Fund and Copy Trading Routing

**What**: AccountTypeID=9 (Fund) receives special handling in copy trading and fund management.

**Columns Involved**: `AccountTypeID`

**Rules**:
- AccountTypeID=9 (Fund) accounts have special copy-trading settlement restrictions
- Fund allocation procedures route based on account type
- Hedge procedures use account type to route to correct liquidity accounts

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a HEAP index. REPLICATE is correct for a 19-row lookup -- every distribution node holds a local copy, eliminating data movement on JOINs with fact tables. HEAP is appropriate for a table this small with no range queries.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for a 19-row reference table. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All retail (Private) customers | JOIN Dim_Customer ON AccountTypeID, filter AccountTypeID = 1 |
| Fund accounts and their performance | JOIN fact tables on CID, filter AccountTypeID = 9 |
| Internal vs external account split | CASE WHEN AccountTypeID IN (7,10,11,13,17) THEN 'Internal' ELSE 'External' END |
| Resolve type ID to name | JOIN Dim_AccountType ON AccountTypeID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.AccountTypeID = Dim_AccountType.AccountTypeID | Resolve account type for each customer |

### 3.4 Gotchas

- **DWHAccountTypeID = AccountTypeID**: This column is always equal to AccountTypeID. It is an ETL artifact with no additional information -- do not use it as a join key when AccountTypeID is available.
- **Name, not AccountTypeName**: The DWH column is called `Name` (not `AccountTypeName` like the production source). When joining or comparing to upstream wikis, note the rename.
- **ID=0 from production source**: Unlike other DWH Dim_ tables, the ID=0 (N/A) placeholder row comes from the production Dictionary.AccountType table itself, not from an explicit DWH SP insert.
- **18=Trust not in upstream wiki**: Type 18 (Trust) appears in the DWH live data but was added after the upstream Dictionary.AccountType wiki was generated.
- **StatusID always 1**: Hardcoded by ETL convention, carries no business meaning.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountTypeID | int | NOT NULL | Primary key identifying the account classification. 0=N/A (DWH placeholder), 1=Private, 2=Corporate, 3=IB Account, 4=Joint Account, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. Referenced by Dim_Customer.AccountTypeID. (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 2 | Name | varchar(50) | NOT NULL | Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. (Tier 1 - upstream wiki, Dictionary.AccountType) |
| 3 | DWHAccountTypeID | int | NOT NULL | ETL surrogate key. Set equal to AccountTypeID by SP_Dictionaries_DL_To_Synapse (SELECT AccountTypeID AS DWHAccountTypeID). Carries no additional information beyond AccountTypeID. Present for DWH schema consistency with other Dim_ tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | NOT NULL | ETL-internal active-row indicator. Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows. Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production value changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | NOT NULL | ETL load timestamp for row (re-)insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AccountTypeID | etoro.Dictionary.AccountType | AccountTypeID | Passthrough |
| Name | etoro.Dictionary.AccountType | AccountTypeName | Passthrough (renamed) |
| DWHAccountTypeID | etoro.Dictionary.AccountType | AccountTypeID | ETL-computed: SELECT AccountTypeID AS DWHAccountTypeID |
| StatusID | - | - | ETL-computed: hardcoded to 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| InsertDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.AccountType -> Generic Pipeline (daily, Override) -> Bronze/etoro/Dictionary/AccountType/ -> DWH_staging.etoro_Dictionary_AccountType -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_AccountType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.AccountType | 19-row production lookup (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/AccountType/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_AccountType | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; DWHAccountTypeID=AccountTypeID; StatusID=1; UpdateDate/InsertDate=GETDATE() |
| Target | DWH_dbo.Dim_AccountType | 19 rows (ID=0 through ID=18) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountTypeID | etoro.Dictionary.AccountType | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | AccountTypeID | Customer account type lookup (primary consumer in DWH) |

---

## 7. Sample Queries

### 7.1 List all account types

```sql
SELECT AccountTypeID, Name
FROM [DWH_dbo].[Dim_AccountType]
ORDER BY AccountTypeID
-- Returns: 0=N/A, 1=Private, 2=Corporate ... 18=Trust
```

### 7.2 Count customers by account type

```sql
SELECT
    dat.Name AS AccountTypeName,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_AccountType] dat
    ON dc.AccountTypeID = dat.AccountTypeID
WHERE dat.AccountTypeID > 0
GROUP BY dat.Name
ORDER BY CustomerCount DESC
```

### 7.3 Internal vs external account breakdown

```sql
SELECT
    CASE
        WHEN AccountTypeID IN (7, 10, 11, 13, 17) THEN 'Internal'
        WHEN AccountTypeID = 0 THEN 'Placeholder'
        ELSE 'External'
    END AS AccountCategory,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer]
GROUP BY
    CASE
        WHEN AccountTypeID IN (7, 10, 11, 13, 17) THEN 'Internal'
        WHEN AccountTypeID = 0 THEN 'Placeholder'
        ELSE 'External'
    END
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.0/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 8.0/10, Relationships: 5.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_AccountType | Type: Table | Production Source: etoro.Dictionary.AccountType*


### Upstream `DWH_dbo.Dim_FundingType` — synapse
- **Resolved as**: `DWH_dbo.Dim_FundingType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md`

# DWH_dbo.Dim_FundingType

> Payment method dimension - maps funding type IDs to payment method names and behavioral flags for eToro deposits, withdrawals, and cashout eligibility. Used by billing and customer action fact tables.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.FundingType |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (FundingTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_FundingType` is a payment method dimension with 44 rows (FundingTypeID 0-44, with ID 41 absent). Each row represents a payment method or funding channel that eToro customers use for deposits and withdrawals. Methods span credit cards, bank transfers, e-wallets, crypto, regional payment systems (Yandex, Qiwi, AliPay, WeChat, Przelewy24), and eToro-internal channels (eToroCryptoWallet, eToroMoney).

Three behavioral flags classify each method:
- `IsNewStyle`: modern-era payment integration (True = post-legacy platform)
- `IsSingleFunding`: one-time/single use (True = e.g., BankDraft, InternalPayment)
- `IsCashoutActive`: cashout/withdrawal supported via this method (True = bidirectional)

**FundingTypeID=0 (N/A)** is a DWH-injected synthetic null-sentinel row, inserted after the main staging load as a hardcoded VALUES insert. Fact tables use `ISNULL(FundingTypeID, 0)` to replace NULLs with this sentinel, enabling NULL-safe joins.

**FundingTypeID=27 (eToroCryptoWallet)** has hardcoded business logic: `SP_Fact_CustomerAction` calculates `IsRedeem = 1` when CreditTypeID=2 AND FundingTypeID=27. This hardcoding creates a maintenance risk if the crypto wallet ID changes.

This dimension is actively consumed by three major fact tables: `Fact_BillingDeposit`, `Fact_BillingWithdraw`, and `Fact_CustomerAction`.

---

## 2. Business Logic

### 2.1 Payment Method Classification Flags

**What**: Three bit flags classify payment method behavior.

**Columns Involved**: `IsNewStyle`, `IsSingleFunding`, `IsCashoutActive`

**Rules**:
- `IsNewStyle`: FALSE only for BankDraft (4), WesternUnion (5), MoneyGram (9). These are legacy payment methods.
- `IsSingleFunding`: TRUE for one-time or non-reusable methods: BankDraft (4), WesternUnion (5), MoneyGram (9), InternalPayment (16), TestDeposit (18), IBDeposit (19)
- `IsCashoutActive`: FALSE for methods where withdrawal is not supported: Giropay (11), Payoneer (14), Sofort (15), InternalPayment (16), LocalBankWire (17), TestDeposit (18), CashU (24), AliPay (25), WeChat (26), RapidTransfer (30), AstroPay (31), EtoroOptions (42), MoneyFarm (44)

### 2.2 Null Sentinel (FundingTypeID=0)

**What**: FundingTypeID=0 / Name='N/A' is a synthetic row added post-staging to represent unknown/missing funding type.

**Columns Involved**: `FundingTypeID`, `DWHFundingTypeID`

**Rules**:
- SP_Fact_CustomerAction uses `ISNULL(FundingTypeID, 0)` and `ISNULL(d.FundingTypeID, ISNULL(dd.FundingTypeID, 0))` to coerce NULLs to 0
- For the N/A row: DWHFundingTypeID=0 (same as FundingTypeID), all flags=False
- Inserted via hardcoded VALUES block in SP_Dictionaries (not from staging)

### 2.3 eToroCryptoWallet Hardcoded Logic

**What**: FundingTypeID=27 (eToroCryptoWallet) drives the `IsRedeem` flag in Fact_CustomerAction.

**Columns Involved**: `FundingTypeID`

**Rules**:
- `IsRedeem = CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`
- This hardcoded check appears in multiple sections of SP_Fact_CustomerAction
- Risk: If eToroCryptoWallet is assigned a new FundingTypeID, IsRedeem calculation breaks silently

### 2.4 DWHFundingTypeID Passthrough

**What**: `DWHFundingTypeID` mirrors `FundingTypeID` for all source rows (passthrough from staging).

**Rules**:
- For rows from staging: `DWHFundingTypeID = FundingTypeID` (same value, ETL SET `[FundingTypeID] as [DWHFundingTypeID]`)
- For the N/A row (FundingTypeID=0): `DWHFundingTypeID = 0`
- Purpose is likely for DWH-layer remapping or future surrogate key substitution. Currently identical to FundingTypeID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (44 rows - appropriate). CLUSTERED INDEX on FundingTypeID. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 44 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FundingTypeID to name | `LEFT JOIN DWH_dbo.Dim_FundingType ON FundingTypeID` |
| Find cashout-eligible methods | `WHERE IsCashoutActive = 1` |
| Identify legacy payment methods | `WHERE IsNewStyle = 0` |
| Exclude N/A sentinel | `WHERE FundingTypeID > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingDeposit | ON FundingTypeID | Payment method for deposits |
| DWH_dbo.Fact_BillingWithdraw | ON FundingTypeID_Withdraw / FundingTypeID_Funding | Payment method for withdrawals |
| DWH_dbo.Fact_CustomerAction | ON FundingTypeID | Payment method for customer financial actions |

### 3.4 Gotchas

- **FundingTypeID=0 is synthetic**: The N/A row (ID=0) does not come from the source system. It is DWH-injected after TRUNCATE+INSERT. Never filter it out blindly - fact tables use it for NULL FK rows.
- **FundingTypeID=41 missing**: The sequence jumps from 40 to 42. ID 41 was likely deleted or never assigned.
- **FundingTypeID=27 hardcoded**: eToroCryptoWallet ID is hardcoded in SP_Fact_CustomerAction for IsRedeem logic. Do not renumber/reassign this ID.
- **FundingTypeID is smallint NULL**: Nullable primary key with NOT NULL-equivalent usage. Join columns in fact tables may be int - implicit type conversion occurs.
- **Fact_BillingWithdraw has TWO FK columns**: `FundingTypeID_Withdraw` (the withdrawal method) and `FundingTypeID_Funding` (the original funding method). Both reference this dimension.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundingTypeID | smallint | YES | Primary key identifying the payment method. (Tier 1 — Dictionary.FundingType) |
| 2 | Name | varchar(50) | NO | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). (Tier 1 — Dictionary.FundingType) |
| 3 | IsNewStyle | bit | NO | Whether this payment method uses the newer integration style. Affects which code path handles the transaction. (Tier 1 — Dictionary.FundingType) |
| 4 | IsSingleFunding | bit | NO | Whether this is a one-time payment method (cannot be saved for repeat use). 1=single-use, 0=can be saved. (Tier 1 — Dictionary.FundingType) |
| 5 | IsCashoutActive | bit | NO | Whether withdrawals (cashouts) are supported via this method. 1=supports cashout, 0=deposit-only. (Tier 1 — Dictionary.FundingType) |
| 6 | DWHFundingTypeID | smallint | NO | DWH copy of FundingTypeID. SET in ETL as `[FundingTypeID] as [DWHFundingTypeID]`. Currently identical to FundingTypeID for all rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows (both staging rows and N/A sentinel). Likely means active. No corresponding Dim_Status table found. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 8 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() (stored as @ddate variable). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 9 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate). Both columns set on each run. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | passthrough |
| Name | etoro.Dictionary.FundingType | Name | passthrough |
| IsNewStyle | etoro.Dictionary.FundingType | IsNewStyle | passthrough |
| IsSingleFunding | etoro.Dictionary.FundingType | IsSingleFunding | passthrough |
| IsCashoutActive | etoro.Dictionary.FundingType | IsCashoutActive | passthrough |
| DWHFundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | ETL-computed: same as FundingTypeID (alias) |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.FundingType -> Generic Pipeline -> DWH_staging.etoro_Dictionary_FundingType
    -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 672) -> Dim_FundingType (rows 1-44)
    -> SP_Dictionaries_DL_To_Synapse (VALUES INSERT, ~line 1475) -> Dim_FundingType row 0 (N/A sentinel)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.FundingType | Payment method dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/FundingType/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_FundingType | Raw import |
| ETL (main) | DWH_dbo.SP_Dictionaries_DL_To_Synapse ~line 672 | TRUNCATE + INSERT. Adds DWHFundingTypeID=FundingTypeID, StatusID=1, UpdateDate/InsertDate=GETDATE(). |
| ETL (sentinel) | DWH_dbo.SP_Dictionaries_DL_To_Synapse ~line 1475 | Hardcoded VALUES INSERT for FundingTypeID=0, Name='N/A'. |
| Target | DWH_dbo.Dim_FundingType | 44-row REPLICATE/CLUSTERED dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingDeposit | FundingTypeID | Payment method for each deposit transaction |
| DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Withdraw | Withdrawal payment method |
| DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Funding | Original funding method for withdrawal |
| DWH_dbo.Fact_CustomerAction | FundingTypeID | Payment method for customer financial actions |

---

## 7. Sample Queries

### 7.1 All payment methods with cashout support

```sql
SELECT FundingTypeID, Name, IsNewStyle, IsSingleFunding
FROM DWH_dbo.Dim_FundingType
WHERE IsCashoutActive = 1 AND FundingTypeID > 0
ORDER BY FundingTypeID
```

### 7.2 Legacy (non-new-style) methods

```sql
SELECT FundingTypeID, Name, IsSingleFunding, IsCashoutActive
FROM DWH_dbo.Dim_FundingType
WHERE IsNewStyle = 0 AND FundingTypeID > 0
```

### 7.3 Join deposits with payment method name

```sql
SELECT ft.Name AS PaymentMethod, COUNT(*) AS DepositCount
FROM DWH_dbo.Fact_BillingDeposit bd
JOIN DWH_dbo.Dim_FundingType ft ON bd.FundingTypeID = ft.FundingTypeID
WHERE ft.FundingTypeID > 0
GROUP BY ft.Name
ORDER BY DepositCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 5 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 9/10, Sources: 8/10*
*Object: DWH_dbo.Dim_FundingType | Type: Table | Production Source: etoro.Dictionary.FundingType*


### Upstream `DWH_dbo.Dim_Customer` — synapse
- **Resolved as**: `DWH_dbo.Dim_Customer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`

﻿# DWH_dbo.Dim_Customer

> Master customer dimension table for the DWH; consolidates identity, demographics, compliance status, acquisition tracking, and external integrations from 14+ staging sources into a single slowly-changing Type 1 dimension with explicit change detection, PII masking, and multi-phase post-load enrichment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | RealCID (PK NOT ENFORCED, CLUSTERED INDEX, HASH distribution key) |
| **Distribution** | HASH(RealCID) |
| **Index** | CLUSTERED INDEX (RealCID ASC); PK NONCLUSTERED NOT ENFORCED |
| **Column Count** | 107 |
| **PII Masking** | 14 columns with Dynamic Data Masking |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Tables** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (masked), `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer` (unmasked PII) |
| **UC Copy Strategy** | Override |
| **Refresh** | Daily (1440 min) |
| **ETL Pattern** | CDC-style: change detection → DELETE/INSERT → multi-phase UPDATE enrichment |

---

## 1. Business Meaning

`Dim_Customer` is the DWH's central customer master table — the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer.

The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle.

Two UC copies exist:
- **Masked**: `main.dwh.gold_...dim_customer_masked` — PII columns contain masked values, accessible to general analytics
- **Unmasked**: `main.pii_data.gold_...dim_customer` — full PII, restricted access

### Business Usage

- **Regulatory Reporting**: Confluence "Business & Regulatory Undertakings Monitoring Platform" JOINs `Dim_Customer` on CID=RealCID for country, regulation, and status filtering
- **BI Queries**: Nearly every DWH fact table JOINs to Dim_Customer (via CID=RealCID) for customer segmentation
- **Synapse Training**: Confluence "Temporary Tables in Synapse" uses Dim_Customer as a reference example for HASH distribution optimization

---

## 5. Lineage

### 2.1 Staging Sources (14+ tables)

| Staging Table | Production Source | Role |
|--------------|-------------------|------|
| `DWH_staging.etoro_Customer_Customer` | Customer.CustomerStatic | Core customer profile (identity, demographics, registration) |
| `DWH_staging.etoro_BackOffice_Customer` | BackOffice.Customer | Compliance/admin attributes (verification, risk, regulation, guru status) |
| `DWH_staging.etoro_History_Customer` | History.Customer | Latest version for change detection (SCD) |
| `DWH_staging.etoro_History_BackOfficeCustomer` | History.BackOfficeCustomer | Latest version for BO attribute change detection |
| `DWH_staging.STS_Audit_UserOperationsData` | STS_Audit.UserOperationsData | 2FA enable/disable tracking |
| `DWH_staging.ContactVerification_Phone_Customer` | ContactVerification.Phone.Customer | Phone number, verification status |
| `DWH_staging.UserApiDB_Customer_Avatars` | UserApiDB.Customer.Avatars | Avatar upload tracking |
| `DWH_staging.etoro_Billing_vDeposit` | Billing.vDeposit | Legacy FTD source (replaced by below) |
| `DWH_staging.CustomerFinanceDB_Customer_FirstTimeDeposits` | CustomerFinanceDB.Customer.FirstTimeDeposits | FTD date, amount, platform, recovery date |
| `DWH_staging.ScreeningService_Screening_UserScreening` | ScreeningService.Screening.UserScreening | Screening/compliance status |
| `DWH_staging.SalesForce_DB_Prod_dbo_IdMapTopology` | SalesForce_DB_Prod.dbo.IdMapTopology | SalesForce account ID mapping |
| `DWH_staging.etoro_BackOffice_CustomerDocument` + `etoro_BackOffice_CustomerDocumentToDocumentType` | BackOffice.CustomerDocument | Address proof & ID proof status |
| `DWH_staging.etoro_Customer_CustomerStatic` | Customer.CustomerStatic | ApexID only |
| `DWH_staging.UserApiDB_Customer_CustomerIdentification` | UserApiDB.Customer.CustomerIdentification | GCID, DemoCID, TanganyID, DltID |
| `DWH_staging.ComplianceStateDB_Compliance_StocksLending` | ComplianceStateDB.Compliance.StocksLending | EquiLendID, StocksLendingStatusID |
| `DWH_dbo.Ext_Dim_SubChannel_UnifyCode` | (DWH internal) | SubChannelID via AffiliateID mapping |

### 2.2 ETL Pipeline (SP_Dim_Customer_DL_To_Synapse → SP_Dim_Customer)

```
ORCHESTRATOR (SP_Dim_Customer_DL_To_Synapse):
  1. Load 14 staging/external tables:
     Ext_Dim_Customer_Affiliate, Ext_Dim_Customer_BOCustomer, Ext_Dim_Customer_2FA,
     Ext_Dim_Customer_PhoneCustomer, Ext_Dim_Customer_Customer, Ext_Dim_Customer_Avatars,
     Ext_etoro_Billing_vDeposit, Ext_CustomerFinanceDB_Customer_FirstTimeDeposits,
     Ext_Dim_Customer_ScreeningStatusID, Ext_Dim_Customer_SF_ID, Ext_Dim_Customer_Document,
     Ext_Dim_CustomerStatic, Ext_Dim_Customer_CustomerIdentification, Ext_Dim_Customer_StocksLending
  2. EXEC SP_Dim_Customer

CORE LOGIC (SP_Dim_Customer):
  Step 1: Build #customer — JOIN Ext_Customer_Customer + Ext_BOCustomer
          Compute: IsValidCustomer, IsCreditReportValidCB
          Rename: SerialID→AffiliateID, ManagerID→AccountManagerID, isEmployeeAccount→EmployeeAccount
  Step 2: Detect #new (CIDs not yet in Dim_Customer)
  Step 3: Detect #update (50+ column comparison using ISNULL + COLLATE)
  Step 4: Build #full_list (new OR updated CIDs) with 2FA from Ext_2FA
  Step 5: Preserve #CustomerInitalIndicaton (deposit, avatar, document, Tangany, DLT, phone, FTD fields)
  Step 6: BEGIN TRAN: DELETE matching CIDs → INSERT with preserved indicators
  Step 7: Post-transaction UPDATEs:
          Avatar → HasAvatar, AvatarUploadDate
          Deposit → IsDepositor, FirstDepositDate, FirstDepositAmount, FTD fields
          ScreeningStatusID → from screening service
          SalesForceAccountID → from SF ID map
          Document proofs → IsAddressProof, IsIDProof + expiry dates
          2FA → from audit log
          SubChannelID → from affiliate mapping
          ApexID → from CustomerStatic
          Phone → PhoneNumber, IsPhoneVerified, PhoneVerificationDate
          Tangany → TanganyID, TanganyStatusID
          DLT → DltID, DltStatusID
          StocksLending → EquiLendID, StocksLendingStatusID
  Step 8: Populate Ext_Dim_Customer_ExternalID_GCID, update UserName_Lower
```

### 2.3 Key Column Renames

| DWH Column | Source Column | Source Table | Why |
|-----------|-------------|-------------|-----|
| RealCID | CID | etoro_Customer_Customer | Disambiguate from other CID uses in DWH |
| AffiliateID | SerialID | etoro_Customer_Customer | Business-friendly name |
| AccountManagerID | ManagerID | etoro_BackOffice_Customer | Disambiguate from other ManagerID columns |
| EmployeeAccount | isEmployeeAccount | etoro_BackOffice_Customer | Normalize casing |
| RegisteredReal | Registered | etoro_Customer_Customer | Clarify real-account registration |

### 2.4 DWH-Computed Columns

| Column | Computation |
|--------|------------|
| IsValidCustomer | `1` when PlayerLevelID≠4 AND LabelID NOT IN (30,26) AND CountryID≠250; else `0` |
| IsCreditReportValidCB | Similar to IsValidCustomer but also excludes PlayerLevelID=4 when AccountTypeID≠2, and has specific CID exceptions for CountryID=250 |
| UpdateDate | `GETDATE()` — ETL timestamp |
| UserName_Lower | `LOWER(UserName)` — set in final UPDATE |

---

## 4. Elements

### 3.1 Customer Identity

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 1 | RealCID | int | NO | No | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | No | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | DemoCID | int | YES | No | Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 — SP_Dim_Customer) |
| 4 | OriginalCID | int | YES | No | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 5 | ID | uniqueidentifier | NO | No | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — Customer.CustomerStatic) |
| 6 | ExternalID | decimal(38,0) | YES | No | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — Customer.CustomerStatic) |

### 3.2 Personal Information (PII — Masked)

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 7 | UserName | varchar(20) | YES | Yes | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 8 | UserName_Lower | varchar(20) | YES | Yes | Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 9 | FirstName | nvarchar(50) | YES | Yes | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 10 | LastName | nvarchar(50) | YES | Yes | Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 11 | MiddleName | nvarchar(50) | YES | Yes | Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 — Customer.CustomerStatic) |
| 12 | Gender | char(1) | YES | Yes | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 13 | BirthDate | datetime | YES | Yes | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 14 | Email | varchar(50) | YES | Yes | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic) |
| 15 | Phone | varchar(30) | YES | Yes | Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic) |
| 16 | IP | varchar(15) | YES | Yes | Registration IP address. (Tier 1 — Customer.CustomerStatic) |
| 17 | Zip | nvarchar(50) | YES | Yes | Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 18 | City | nvarchar(50) | YES | Yes | City in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 19 | Address | nvarchar(100) | YES | Yes | Street address in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 20 | BuildingNumber | nvarchar(30) | YES | Yes | Building/apartment number. Separate from Address for structured address storage. (Tier 1 — Customer.CustomerStatic) |

### 3.3 Acquisition & Marketing

| # | Column | Type | Description |
|---|--------|------|-------------|
| 21 | AffiliateID | int | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 22 | CampaignID | int | Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers. (Tier 1 — Customer.CustomerStatic) |
| 23 | SubChannelID | int | Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 24 | LabelID | int | Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. (Tier 1 — Customer.CustomerStatic) |
| 25 | BannerID | int | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 26 | FunnelID | int | Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked. (Tier 1 — Customer.CustomerStatic) |
| 27 | FunnelFromID | int | Source funnel variant ID tracking where the customer came from within the acquisition funnel. (Tier 1 — Customer.CustomerStatic) |
| 28 | DownloadID | int | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 — Customer.CustomerStatic) |
| 29 | ReferralID | int | Referral CID - the customer who referred this customer (for RAF program tracking). (Tier 1 — Customer.CustomerStatic) |
| 30 | SubSerialID | varchar(1024) | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 — Customer.CustomerStatic) |

### 3.4 Registration & Account Lifecycle

| # | Column | Type | Description |
|---|--------|------|-------------|
| 31 | RegisteredReal | datetime | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 32 | RegisteredDemo | datetime | Demo account registration date. Source unclear — may be populated separately. (Tier 2 — SP_Dim_Customer) |
| 33 | AccountExpirationDate | datetime | Expiration date for demo or time-limited accounts. NULL for standard real-money accounts. (Tier 1 — Customer.CustomerStatic) |
| 34 | AccountStatusID | int | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 — Customer.CustomerStatic) |
| 35 | PlayerStatusID | int | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 36 | PlayerStatusReasonID | int | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 — Customer.CustomerStatic) |
| 37 | PlayerStatusSubReasonID | int | Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). (Tier 1 — Customer.CustomerStatic) |
| 38 | PendingClosureStatusID | tinyint | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. (Tier 1 — Customer.CustomerStatic) |
| 39 | PlayerLevelID | int | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 40 | AccountTypeID | int | Customer account classification. Default=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K. (Tier 1 — BackOffice.Customer) |
| 41 | IsDepositor | bit | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. (Tier 2 — SP_Dim_Customer) |
| 42 | FirstDepositDate | datetime | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 43 | FirstDepositAmount | money | Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer) |

### 3.5 Compliance & Regulation

| # | Column | Type | Description |
|---|--------|------|-------------|
| 44 | RegulationID | tinyint | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 45 | DesignatedRegulationID | int | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 — BackOffice.Customer) |
| 46 | RegulationChangeDate | datetime | Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger. NULL if never changed since creation. (Tier 1 — BackOffice.Customer) |
| 47 | CountryID | int | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 48 | CountryIDByIP | int | Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). (Tier 1 — Customer.CustomerStatic) |
| 49 | CitizenshipCountryID | int | Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 — Customer.CustomerStatic) |
| 50 | POBCountryID | int | Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436). (Tier 1 — Customer.CustomerStatic) |
| 51 | RegionID | int | Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. (Tier 1 — Customer.CustomerStatic) |
| 52 | RegionByIP_ID | int | Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. (Tier 1 — Customer.CustomerStatic) |
| 53 | VerificationLevelID | int | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. (Tier 1 — BackOffice.Customer) |
| 54 | DocsOK | tinyint | Whether required documents are verified. (Tier 2 — SP_Dim_Customer) |
| 55 | DocumentStatusID | int | Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 — BackOffice.Customer) |
| 56 | IsAddressProof | int | Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. (Tier 2 — SP_Dim_Customer) |
| 57 | IsAddressProofExpiryDate | datetime | Expiry date of address proof document. (Tier 2 — SP_Dim_Customer) |
| 58 | IsIDProof | int | Whether ID proof document is on file (1/0). (Tier 2 — SP_Dim_Customer) |
| 59 | IsIDProofExpiryDate | datetime | Expiry date of ID proof document. (Tier 2 — SP_Dim_Customer) |
| 60 | SuitabilityTestStatusID | int | MiFID II appropriateness/suitability test result. NULL if test not completed. (Tier 1 — BackOffice.Customer) |
| 61 | MifidCategorizationID | int | MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1. (Tier 1 — BackOffice.Customer) |
| 62 | ScreeningStatusID | int | Compliance screening status. Updated from ScreeningService. (Tier 2 — SP_Dim_Customer) |
| 63 | WorldCheckID | int | Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 — BackOffice.Customer) |
| 64 | WorldCheckResultsUpdated | datetime | When World-Check results were last updated. Preserved from previous row. (Tier 2 — SP_Dim_Customer) |
| 65 | IsEDD | bit | Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. Default=0. (Tier 1 — BackOffice.Customer) |
| 66 | Bankruptcy | tinyint | Bankruptcy flag. (Tier 2 — SP_Dim_Customer) |
| 67 | IsValidCustomer | int | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) |
| 68 | IsCreditReportValidCB | int | DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. (Tier 2 — SP_Dim_Customer) |

### 3.6 Risk & Communication

| # | Column | Type | Description |
|---|--------|------|-------------|
| 69 | RiskStatusID | int | Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags). (Tier 1 — BackOffice.Customer) |
| 70 | RiskClassificationID | int | Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Tracked in UPDATE trigger audit. (Tier 1 — BackOffice.Customer) |
| 71 | EmployeeAccount | tinyint | 1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks. (Tier 1 — BackOffice.Customer) |
| 72 | LanguageID | int | Customer preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 73 | CommunicationLanguageID | int | Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences. (Tier 1 — Customer.CustomerStatic) |
| 74 | IsEmailVerified | int | Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. (Tier 1 — Customer.CustomerStatic) |
| 75 | PrivacyPolicyID | int | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 — Customer.CustomerStatic) |
| 76 | IsCopyBlocked | bit | 1 if the customer is blocked from copy trading. 0 in all current rows - feature exists but currently unused/not enforced. (Tier 1 — BackOffice.Customer) |

### 3.7 Social & Trading Features

| # | Column | Type | Description |
|---|--------|------|-------------|
| 77 | GuruStatusID | smallint | eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. (Tier 1 — BackOffice.Customer) |
| 78 | NumOfGurus | int | Number of Popular Investors this customer is copying. (Tier 2 — SP_Dim_Customer) |
| 79 | NumOfCopiers | int | Number of customers copying this customer's trades. (Tier 2 — SP_Dim_Customer) |
| 80 | NumOfRAF | int | Number of successful Refer-A-Friend referrals. (Tier 2 — SP_Dim_Customer) |
| 81 | SocialConnectID | int | Social media connection type. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 82 | PremiumAccount | tinyint | Whether this is a premium account. (Tier 2 — SP_Dim_Customer) |
| 83 | Evangelist | tinyint | Whether this customer is an evangelist/ambassador. (Tier 2 — SP_Dim_Customer) |
| 84 | HasAvatar | tinyint | Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). (Tier 2 — SP_Dim_Customer) |
| 85 | AvatarUploadDate | datetime | When the avatar was uploaded. (Tier 2 — SP_Dim_Customer) |
| 86 | EvMatchStatus | int | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — BackOffice.Customer) |

### 3.8 Account Management

| # | Column | Type | Description |
|---|--------|------|-------------|
| 87 | AccountManagerID | int | Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 — BackOffice.Customer) |
| 88 | UpdateDate | datetime | ETL load/update timestamp (GETDATE()). (Tier 2 — SP_Dim_Customer) |
| 89 | SalesForceAccountID | nvarchar(18) | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. (Tier 1 — BackOffice.Customer) |

### 3.9 Authentication & Phone Verification

| # | Column | Type | Description |
|---|--------|------|-------------|
| 90 | 2FA | int | Two-factor authentication status. 0=disabled, 1=enabled. Derived from `STS_Audit_UserOperationsData` login type events. Preserves previous value when no new 2FA event exists. (Tier 2 — SP_Dim_Customer) |
| 91 | PhoneVerifiedID | int | Result code of phone number verification process. NULL if not yet attempted. (Tier 1 — BackOffice.Customer) |
| 92 | PhoneNumber | varchar(30) | Verified phone number from ContactVerification service. Overrides `Phone` from Customer_Customer when available. (Tier 2 — SP_Dim_Customer) |
| 93 | IsPhoneVerified | bit | Whether phone is verified (VerificationStatusID IN (1,2) → 1). (Tier 2 — SP_Dim_Customer) |
| 94 | PhoneVerificationDate | smalldatetime | Date phone was verified. '1900-01-01' if not verified. (Tier 2 — SP_Dim_Customer) |

### 3.10 External Integrations

| # | Column | Type | Description |
|---|--------|------|-------------|
| 95 | ApexID | varchar(8) | APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts. (Tier 1 — Customer.CustomerStatic) |
| 96 | TanganyID | nvarchar(max) | Tangany crypto custody integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 97 | TanganyStatusID | tinyint | Tangany integration status. (Tier 2 — SP_Dim_Customer) |
| 98 | EquiLendID | nvarchar(max) | EquiLend securities lending integration ID. Updated from StocksLending. (Tier 2 — SP_Dim_Customer) |
| 99 | StocksLendingStatusID | int | Stocks lending consent status. (Tier 2 — SP_Dim_Customer) |
| 100 | DltID | nvarchar(max) | Distributed Ledger Technology integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 101 | DltStatusID | int | DLT integration status. (Tier 2 — SP_Dim_Customer) |
| 102 | HasWallet | int | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) |

### 3.11 FTD (First Time Deposit) Tracking

| # | Column | Type | Description |
|---|--------|------|-------------|
| 103 | FTDPlatformID | nvarchar(4000) | Platform/account type of the first deposit (AccountTypeId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 104 | FTDTransactionID | nvarchar(4000) | Transaction ID of the first deposit (TransactionId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 105 | FTDRecoveryDate | datetime2(7) | Recovery date for the FTD (Updated field from source). If FTDRecoveryDate is later than original FirstDepositDate, FirstDepositDate is updated to FTDRecoveryDate. Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |

### 3.12 Miscellaneous

| # | Column | Type | Description |
|---|--------|------|-------------|
| 106 | CashoutFeeGroupID | int | Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group. (Tier 1 — BackOffice.Customer) |
| 107 | WeekendFeePrecentage | int | Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo Precentage. (Tier 1 — Customer.CustomerStatic) |

---

## 2. Business Logic

### 4.1 Change Detection (CDC-Style)

The SP compares 50+ columns between `#customer` (staging) and existing `Dim_Customer` using `ISNULL(old,0) <> ISNULL(new,0)` with explicit `COLLATE Latin1_General_100_BIN` for string columns. Only customers with actual changes (or new customers) are processed. This prevents unnecessary row churn.

### 4.2 Indicator Preservation

When a customer row is updated (DELETE+INSERT), certain indicator fields are preserved from the old row via `#CustomerInitalIndicaton`: FirstDepositAmount, FirstDepositDate, HasAvatar, IsDepositor, ScreeningStatusID, SalesForceAccountID, document proofs, WorldCheckID, Tangany, Phone, EquiLend, DLT, FTD fields. These are then refreshed in subsequent post-load UPDATEs if new data is available.

### 4.3 Multi-Source Identity Resolution

Customer attributes come from multiple microservices. The ETL uses `ISNULL(history_version, current_value)` patterns to prefer the latest History version (with temporal filtering: ValidFrom < @CurrentDate, ValidFrom >= @DelayDate, ValidTo >= @CurrentDate) over the current snapshot, ensuring the most up-to-date attribute values are captured.

### 4.4 FTD Recovery Date Logic

The `FirstDepositDate` is updated using: if the existing `FirstDepositDate` (as date) is earlier than `FTDRecoveryDate`, use `FTDRecoveryDate`; otherwise use the `FTDDate`. This handles cases where an FTD was reversed and re-deposited on a different day.

### 4.5 IsValidCustomer Business Rule

```
IsValidCustomer = 1 WHEN:
  PlayerLevelID ≠ 4 (not Popular Investor)
  AND LabelID NOT IN (30, 26) (not bonus-only or specific label)
  AND CountryID ≠ 250
```

This excludes demo-like, internal, and specific-jurisdiction accounts from standard reporting.

---

## 6. Relationships

### 5.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CountryID / CountryIDByIP / CitizenshipCountryID / POBCountryID | Dim_Country | CountryID = CountryID |
| AffiliateID | Dim_Affiliate | AffiliateID = AffiliateID |
| CampaignID | Dim_Campaign | CampaignID = CampaignID |
| AccountTypeID | Dim_AccountType | AccountTypeID = AccountTypeID |
| AccountStatusID | Dim_AccountStatus | AccountStatusID = AccountStatusID |
| PlayerLevelID | (Dictionary.PlayerLevel — no DWH dim) | — |
| GuruStatusID | Dim_GuruStatus | GuruStatusID = GuruStatusID |
| FunnelID | Dim_Funnel | FunnelID = FunnelID |
| DocumentStatusID | Dim_DocumentStatus | DocumentStatusID = DocumentStatusID |
| EvMatchStatus | Dim_EvMatchStatus | EvMatchStatus = EvMatchStatus |
| CashoutFeeGroupID | Dim_CashoutFeeGroup | CashoutFeeGroupID = CashoutFeeGroupID |

### 5.2 Fact Table Relationships

Nearly every DWH fact table JOINs to Dim_Customer:
- `Fact_BillingWithdraw.CID = Dim_Customer.RealCID`
- `Fact_CustomerUnrealized_PnL.CID = Dim_Customer.RealCID`
- `Fact_SnapshotCustomer.RealCID = Dim_Customer.RealCID`
- `Fact_CustomerAction.CID = Dim_Customer.RealCID`
- `Dim_Position.CID = Dim_Customer.RealCID`

### 5.3 Source Chain

```
Production Microservices                    DWH Staging                         Synapse DWH
──────────────────────                    ──────────                         ───────────
Customer.CustomerStatic          →  etoro_Customer_Customer            ─┐
BackOffice.Customer              →  etoro_BackOffice_Customer          ─┤
History.Customer                 →  etoro_History_Customer             ─┤
History.BackOfficeCustomer       →  etoro_History_BackOfficeCustomer   ─┤  

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_EY_Audit_Automation_CashoutReason`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_EY_Audit_Automation_CashoutReason.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_EY_Audit_Automation_CashoutReason] @Date [Date] AS
/**************************************Start Main Comment History******************************************************
Author:		 Adi Meidan
Date:        2023-06-14
Description: Audit_Automation_Cashout Reason

**************************
** Change History
**************************
Date			Author					Description	
      
2024-07-03		Guy M		added date auto completion code for missing dates	

****************************************End Main Comment History****************************************************/

BEGIN

-- EXEC [BI_DB_dbo].[SP_EY_Audit_Automation_CashoutReason] '20240621'

SET NOCOUNT ON;

--DECLARE @Date DATE = cast (getdate()-1 as date)
DECLARE @DateID INT =CAST(CONVERT(VARCHAR(10), @Date, 112) AS INT)

		----- check for missing previous dates and fill up -----

		DECLARE @TargetDateInt INT = CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)
		DECLARE @MaxDateID INT;
		-- Get the maximum DateID from the table
		SELECT @MaxDateID = MAX(ModificationDate_WithdrawToFunding_DateID)
		FROM BI_DB_dbo.BI_DB_EY_Audit_CashoutReason ;
		
		PRINT @MaxDateID
		
		-- Check if there are any missing dates
		IF @MaxDateID < @TargetDateInt
		BEGIN
		    DECLARE @StartDate DATE = CAST(CAST(@MaxDateID AS VARCHAR(8)) AS DATE);
		    DECLARE @EndDate DATE = DATEADD(DAY, -1, @Date);
		    DECLARE @DateToProcess DATE = DATEADD(DAY, 1, @StartDate);
		
		    WHILE @DateToProcess <= @EndDate
		    BEGIN
		        DECLARE @DateInt INT = CAST(FORMAT(@DateToProcess, 'yyyyMMdd') AS INT);
		        -- Run the stored procedure for the missing date
		        EXEC BI_DB_dbo.SP_EY_Audit_Automation_CashoutReason @Date = @DateToProcess;
				PRINT cast( @DateToProcess AS VARCHAR (20)) + ' Data Added'
		        SET @DateToProcess = DATEADD(DAY, 1, @DateToProcess);
		    END
		END
		
	ELSE
	
	BEGIN
	PRINT 'no missing dates'
	END


IF OBJECT_ID('tempdb..#cashoutreasons') IS NOT NULL DROP TABLE #cashoutreasons
CREATE TABLE #cashoutreasons 
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT 
    effbw.WithdrawID
  , effbw.CID
  , effbw.WithdrawPaymentID
  ,effbw.ModificationDate_WithdrawToFunding_DateID
  , effbw.CashoutReasonID
  , dcr.Name AS CashoutReason
  , dc.Name AS Country
  , dpl.Name AS Club
  , dgs.GuruStatusName
  , dat.Name AS AccountType
  , dc1.ExternalID
  , dft.Name AS FundingType
FROM (select effbw.*,cast(convert(varchar(10),cast(effbw.ModificationDate_WithdrawToFunding as date),112) as int) ModificationDate_WithdrawToFunding_DateID from DWH_dbo.Fact_BillingWithdraw effbw) effbw
JOIN DWH_dbo.Dim_CashoutReason dcr
    ON effbw.CashoutReasonID = dcr.CashoutReasonID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
    ON fsc.RealCID = effbw.CID
JOIN DWH_dbo.Dim_Range dr
    ON fsc.DateRangeID = dr.DateRangeID AND effbw.ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Country dc
    ON fsc.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl
    ON fsc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN DWH_dbo.Dim_GuruStatus dgs
    ON fsc.GuruStatusID = dgs.GuruStatusID
JOIN DWH_dbo.Dim_AccountType dat
    ON fsc.AccountTypeID = dat.AccountTypeID
LEFT JOIN DWH_dbo.Dim_FundingType dft
    ON dft.FundingTypeID = effbw.FundingTypeID_Funding
JOIN DWH_dbo.Dim_Customer dc1
    ON fsc.RealCID = dc1.RealCID
WHERE effbw.ModificationDate_WithdrawToFunding_DateID=@DateID

--------Delete and Insert--------------------------


DELETE  BI_DB_dbo.BI_DB_EY_Audit_CashoutReason FROM  BI_DB_dbo.BI_DB_EY_Audit_CashoutReason WHERE ModificationDate_WithdrawToFunding_DateID=@DateID

 --insert data
 INSERT INTO  BI_DB_dbo.BI_DB_EY_Audit_CashoutReason
 (WithdrawID,
	CID ,
	WithdrawPaymentID,
	ModificationDate_WithdrawToFunding_DateID,
	CashoutReasonID,
	CashoutReason,
	Country,
	Club,
	GuruStatusName,
	AccountType,
	ExternalID,
	FundingType,
	UpdateDate)

SELECT c.WithdrawID,
		c.CID ,
		c.WithdrawPaymentID,
		c.ModificationDate_WithdrawToFunding_DateID ,
		c.CashoutReasonID,
		c.CashoutReason,
		c.Country,
		c.Club,
		c.GuruStatusName,
		c.AccountType,
		c.ExternalID,
		c.FundingType,
	  GETDATE() AS 'UpdateDate'

FROM #cashoutreasons c


END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_EY_Audit_Automation_CashoutReason` | synapse_sp | BI_DB_dbo | SP_EY_Audit_Automation_CashoutReason | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_EY_Audit_Automation_CashoutReason.sql` |
| `DWH_dbo.Fact_BillingWithdraw` | synapse | DWH_dbo | Fact_BillingWithdraw | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `DWH_dbo.Dim_CashoutReason` | synapse | DWH_dbo | Dim_CashoutReason | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CashoutReason.md` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `DWH_dbo.Dim_PlayerLevel` | synapse | DWH_dbo | Dim_PlayerLevel | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `DWH_dbo.Dim_GuruStatus` | synapse | DWH_dbo | Dim_GuruStatus | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `DWH_dbo.Dim_AccountType` | synapse | DWH_dbo | Dim_AccountType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `DWH_dbo.Dim_FundingType` | synapse | DWH_dbo | Dim_FundingType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |

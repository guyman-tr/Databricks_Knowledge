# EXW_dbo.V_EXW_C2F_E2E_4Export

> Export-optimized view over EXW_dbo.EXW_C2F_E2E for downstream data delivery. Exposes all 103 columns of the C2F end-to-end reconciliation table with two type casts that convert uniqueidentifier columns (`C2FCorrelationID`, `SentWalletID`) to varchar(50), enabling compatibility with consumers such as Power BI, Excel/ODBC connectors, and export pipelines that do not natively support the GUID type. No rows are filtered — the view is a complete projection of EXW_C2F_E2E (14,544 rows, all C2F conversions).

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | View |
| **Base Table** | EXW_dbo.EXW_C2F_E2E |
| **Writer SP** | N/A (read-only view) |
| **Refresh** | Derived from SP_EXW_C2F_E2E (same schedule as base table) |
| **Row Count** | 14,544 (as of April 2026 — same as base table, no filter) |
| **Synapse Distribution** | N/A (view) |
| **Synapse Index** | N/A (view) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

V_EXW_C2F_E2E_4Export is the export-ready surface of the Crypto-to-Fiat (C2F) E2E reconciliation data. The suffix `_4Export` signals its purpose: the view exists specifically to bridge the internal DWH data model (which uses `uniqueidentifier` columns natively) to export consumers that require string-compatible identifiers.

The two uniqueidentifier columns in EXW_C2F_E2E — `C2FCorrelationID` (the distributed tracing correlation GUID) and `SentWalletID` (the wallet GUID from WalletDB) — are cast to varchar(50) so that:
- Power BI DirectQuery and Import mode can handle them without data type errors
- Excel/ODBC exports produce human-readable GUID strings instead of binary blobs
- Downstream file exports (CSV, Parquet) get consistent string representations

For all analytical, operational, and reporting use cases, **this view and the base table EXW_C2F_E2E are functionally equivalent**. Use whichever is more convenient for your toolchain.

**C2F context**: Each row represents a single Crypto-to-Fiat conversion — a customer selling cryptocurrency and receiving fiat directly to an IBAN bank account, eToro trading platform, or position funding. The full lifecycle is captured in a single denormalized row with 103 attributes covering conversion orchestration, blockchain execution, eMoney settlement, and a point-in-time customer profile snapshot.

---

## 2. Business Logic

### 2.1 Type Casts (the only logic in this view)

**What**: Two uniqueidentifier columns are cast to varchar(50) for export compatibility.

**Columns**:
- `C2FCorrelationID`: CAST(uniqueidentifier AS varchar(50)) — GUID of the Saga correlation chain
- `SentWalletID`: CAST(uniqueidentifier AS varchar(50)) — GUID of the sending wallet

**Rules**:
- SQL Server converts uniqueidentifier to varchar in uppercase hyphenated format: `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` (36 characters, fits varchar(50) with margin)
- No data loss — GUIDs are losslessly representable as varchar(36), well within varchar(50)
- All 101 other columns: direct pass-through from base table

### 2.2 No Row Filter

All rows from EXW_C2F_E2E are included. The view scope equals the base table scope (full C2F conversion history, all ConversionCycle values, all TargetPlatformID values).

---

## 3. Data Overview

Same as EXW_C2F_E2E — all 14,544 rows, all conversion states:

| C2FCorrelationID | TargetPlatformID | ConversionCycle | Crypto | FiatCurrency | CryptoAmount | FiatAmount | UsdAmount |
|---|---|---|---|---|---|---|---|
| FAEF03FC-1234-... | 1 | Full Cycle | USDC | GBP | 1549.0 | 1147.54 | 1449.12 |
| BEFB92B9-5678-... | 1 | Full Cycle | ETH | GBP | 0.085054 | 142.86 | 180.49 |
| BC902A8D-ABCD-... | 1 | Full Cycle | XRP | AUD | 200.0 | 392.32 | 255.98 |

Key distribution (identical to base table):
- **TargetPlatformID**: 1=IbanAccount (13,450), 2=EtoroPlatform (1,093), 1 NULL
- **ConversionCycle**: Full Cycle (13,965), FailedConversion (575), Other (4)
- **Top Cryptos**: BTC (5,877), ETH (3,733), XRP (1,988), USDC (1,853), SOL (519)
- **FiatCurrency**: GBP (7,287), EUR (5,856), USD (1,093), AUD (307)
- **C2FCorrelationID**: varchar(50) in this view (uniqueidentifier in base table)
- **SentWalletID**: varchar(50) in this view (uniqueidentifier in base table)

---

## 4. Elements

All column descriptions are T1/T2-inherited verbatim from [EXW_dbo.EXW_C2F_E2E](../Tables/EXW_C2F_E2E.md). Two type differences noted with ▶.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | C2FCorrelationID | varchar(50) ▶ | YES | — | VERIFIED | Distributed tracing correlation ID linking this conversion to its Saga.SagaRuns orchestration entry and all cross-service operations. Used as the deduplication key by InsertConversion. **View note**: cast from uniqueidentifier to varchar(50) for export compatibility. (Tier 1 — C2F.Conversions) |
| 2 | TargetPlatformID | tinyint | YES | — | VERIFIED | Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. Determines the downstream routing of fiat proceeds. (Tier 1 — C2F.Conversions) |
| 3 | TargetPlatform | varchar(256) | YES | — | VERIFIED | Display name for TargetPlatformID. Values: IbanAccount, EtoroPlatform, EtoroPosition. Lookup from WalletConversionDB Dictionary.FiatConversionTargets. (Tier 2 — SP_EXW_C2F_E2E) |
| 4 | ConversionCycle | varchar(216) | YES | — | VERIFIED | End-to-end reconciliation status classifying completion state across WalletDB request, blockchain send, and eMoney settlement. Values: Full Cycle (96%), FailedConversion (4%), and edge-case variants. (Tier 2 — SP_EXW_C2F_E2E) |
| 5 | LastModificationDateTime | datetime2(7) | YES | — | VERIFIED | Latest event timestamp across all sub-systems: GREATEST(FiatTransaction.Occurred, ConversionTime, ConversionStatusTime, CryptoTransactionTime). (Tier 2 — SP_EXW_C2F_E2E) |
| 6 | LastModificationDate | date | YES | — | VERIFIED | Date portion of LastModificationDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 7 | LastModificationDateID | int | YES | — | VERIFIED | Date integer key YYYYMMDD from LastModificationDate. Used as the reference date for the point-in-time customer snapshot join. (Tier 2 — SP_EXW_C2F_E2E) |
| 8 | GCID | int | YES | — | VERIFIED | Global Customer ID identifying the customer who initiated the conversion. Validated NOT NULL by InsertConversion. Indexed for customer-scoped queries. (Tier 1 — C2F.Conversions) |
| 9 | RealCID | int | YES | — | VERIFIED | Internal CID after deduplication mapping. Sourced from EXW_dbo.EXW_DimUser.RealCID; maps GCID to the canonical customer record. (Tier 2 — SP_EXW_C2F_E2E) |
| 10 | RequestID | bigint | YES | — | VERIFIED | Auto-incrementing primary key and the primary identifier for a request across the entire wallet system. Referenced by Wallet.RequestStatuses.RequestId as FK. (Tier 1 — Wallet.Requests) |
| 11 | RequestCryptoID | int | YES | — | VERIFIED | Identifier of the cryptocurrency this request operates on. Implicit reference to Wallet.CryptoTypes.CryptoID. For conversions, this is the source crypto. (Tier 1 — Wallet.Requests) |
| 12 | RequestDateTime | datetime2(7) | YES | — | VERIFIED | When the request was created. Indexed descending for recent-request lookups. (Tier 1 — Wallet.Requests) |
| 13 | RequestLastStatusID | tinyint | YES | — | CODE-BACKED | Last-known status ID of the Wallet ConversionToFiat request. Values: 1=Done, 2=Error, 7=TransactionVerified, 31=ReadByConversionWorker. (Tier 2 — SP_EXW_C2F_E2E) |
| 14 | RequestLastStatus | varchar(64) | YES | — | CODE-BACKED | Display name for RequestLastStatusID. Values observed: Done, Error, TransactionVerified, ReadByConversionWorker. (Tier 2 — SP_EXW_C2F_E2E) |
| 15 | RequestLastStatusDateTime | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the last RequestStatuses entry for this request. (Tier 2 — SP_EXW_C2F_E2E) |
| 16 | SentTransactionID | bigint | YES | — | VERIFIED | Auto-incrementing PK. FK target for Wallet.SentTransactionStatuses, SentTransactionOutputs, and SentTransactionReplaces. (Tier 1 — Wallet.SentTransactions) |
| 17 | SentBlockchainTransactionID | nvarchar(100) | YES | — | VERIFIED | The on-chain transaction hash/ID. Unique constraint enforced. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). (Tier 1 — Wallet.SentTransactions) |
| 18 | SentWalletID | varchar(50) ▶ | YES | — | VERIFIED | The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. **View note**: cast from uniqueidentifier to varchar(50) for export compatibility. (Tier 1 — Wallet.SentTransactions) |
| 19 | SentTransactionDateTime | datetime2(7) | YES | — | VERIFIED | Timestamp when the transaction was broadcast to the blockchain. (Tier 1 — Wallet.SentTransactions) |
| 20 | SentBlockchainFee | numeric(36,18) | YES | — | VERIFIED | Network fee paid in the crypto's native units. Recorded after on-chain confirmation. Used for cost analysis and financial reconciliation. (Tier 1 — Wallet.SentTransactions) |
| 21 | SentCryptoID | int | YES | — | VERIFIED | The cryptocurrency sent. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 — Wallet.SentTransactions) |
| 22 | SentAmount | numeric(36,18) | YES | — | CODE-BACKED | Amount of crypto transferred in the sent transaction. Sourced from Wallet.SentTransactionOutputs.Amount. Matches or closely tracks CryptoAmount. (Tier 2 — SP_EXW_C2F_E2E) |
| 23 | SentEtoroFees | numeric(36,18) | YES | — | CODE-BACKED | eToro fees deducted from the blockchain output. Sourced from Wallet.SentTransactionOutputs.EtoroFees. Observed as 0 for all current rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 24 | SentLastStatusID | tinyint | YES | — | CODE-BACKED | Last-known status ID of the sent transaction. Values: 2=Verified, 6=WavedError. NULL when no sent transaction exists. (Tier 2 — SP_EXW_C2F_E2E) |
| 25 | SentLastStatus | varchar(50) | YES | — | CODE-BACKED | Display name for SentLastStatusID. Values observed: Verified, WavedError. NULL when SentTransactionID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 26 | EstimatedFiatAmount | decimal(36,18) | YES | — | VERIFIED | Estimated fiat amount the customer will receive in the target fiat currency. Calculated as CryptoAmount * CryptoToFiatRate (with fee adjustments). (Tier 1 — C2F.EstimatedFiatTransactions) |
| 27 | EstimatedUsdAmount | decimal(36,18) | YES | — | VERIFIED | Estimated USD equivalent of the fiat amount. Used for regulatory limit calculations. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 28 | EstimatedCryptoToUsdRate | decimal(36,18) | YES | — | VERIFIED | Exchange rate from source crypto to USD at conversion creation time. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 29 | EstimatedFiatToUsdRate | decimal(36,18) | YES | — | VERIFIED | Exchange rate from the target fiat currency to USD. 1.0 when target is USD. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 30 | EstimatedCryptoToFiatRate | decimal(36,18) | YES | — | VERIFIED | Direct exchange rate from source crypto to target fiat shown to the customer. Derived from CryptoToUsdRate / FiatToUsdRate. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 31 | EstimatedDateTime | datetime2(7) | YES | — | CODE-BACKED | UTC timestamp when the estimate was recorded. Matches Conversions.Occurred. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 32 | C2FConversionID | int | YES | — | VERIFIED | Auto-incrementing surrogate PK. Referenced by all child tables (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) via ConversionId FK. (Tier 1 — C2F.Conversions) |
| 33 | CryptoID | int | YES | — | VERIFIED | Crypto asset identifier. Identifies which cryptocurrency is being sold. (Tier 1 — C2F.Conversions) |
| 34 | Crypto | nvarchar(256) | YES | — | VERIFIED | Display name for CryptoID. Values: BTC, ETH, XRP, USDC, SOL, DOGE, ADA, TRX, LTC, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 35 | FiatCurrencyID | int | YES | — | CODE-BACKED | Fiat currency identifier. Identifies which fiat currency the customer receives. (Tier 1 — C2F.Conversions) |
| 36 | FiatCurrency | nvarchar(256) | YES | — | VERIFIED | Display name for FiatCurrencyID. Values: GBP (50%), EUR (40%), USD (7.5%), AUD (2%). (Tier 2 — SP_EXW_C2F_E2E) |
| 37 | CryptoAmount | decimal(36,18) | YES | — | VERIFIED | Quantity of cryptocurrency being converted. High precision (18 decimals). Gross amount before fees. (Tier 1 — C2F.Conversions) |
| 38 | TotalFeePercentage | decimal(36,18) | YES | — | VERIFIED | Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. (Tier 1 — C2F.Conversions) |
| 39 | TotalFeeUSD | decimal(36,18) | YES | — | CODE-BACKED | Fee amount in USD. Computed: CAST(CryptoAmount AS FLOAT) * CAST(CryptoToUsdRate AS FLOAT) / 100 * TotalFeePercentage. Approximation subject to float precision. (Tier 2 — SP_EXW_C2F_E2E) |
| 40 | ConversionDateTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the conversion was created. Indexed DESC for recency queries. (Tier 1 — C2F.Conversions) |
| 41 | ConversionDateID | int | YES | — | CODE-BACKED | Date integer key YYYYMMDD from ConversionDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 42 | ConversionDate | date | YES | — | CODE-BACKED | Date portion of ConversionDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 43 | ConversionStatusID | int | YES | — | VERIFIED | FK to Dictionary.ConversionToFiatStatuses. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. (Tier 1 — C2F.ConversionStatuses) |
| 44 | ConversionStatus | varchar(64) | YES | — | VERIFIED | Display name for ConversionStatusID. Values: Pending, Failed, Completed, Rejected. (Tier 2 — SP_EXW_C2F_E2E) |
| 45 | ConversionStatusDateTime | datetime2(7) | YES | — | CODE-BACKED | UTC timestamp of the most recent ConversionStatuses entry. (Tier 2 — SP_EXW_C2F_E2E) |
| 46 | ConversionStatusDateID | int | YES | — | CODE-BACKED | Date integer key YYYYMMDD from ConversionStatusDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 47 | ConversionStatusDate | date | YES | — | CODE-BACKED | Date portion of ConversionStatusDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 48 | BlockchainTransactionID | nvarchar(max) | YES | — | VERIFIED | On-chain transaction hash/identifier. Unique across all rows. Format varies by blockchain. Serves as proof of on-chain execution. (Tier 1 — C2F.CryptoTransactions) |
| 49 | FromAddress | nvarchar(max) | YES | — | CODE-BACKED | Source blockchain address of the customer's wallet at conversion time. NULL (0 observed) for all rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 50 | ToAddress | nvarchar(max) | YES | — | VERIFIED | Destination blockchain address where crypto was sent. May include chain-specific qualifiers (Ripple destination tags). (Tier 1 — C2F.CryptoTransactions) |
| 51 | BlockchainFee | decimal(36,18) | YES | — | VERIFIED | Network/gas fee charged by the blockchain. Very small values (0.000045 XRP, 6e-8 for ERC-20). Deducted from transfer, not from conversion amount. (Tier 1 — C2F.CryptoTransactions) |
| 52 | CryptoTransactionDateTime | datetime2(7) | YES | — | CODE-BACKED | UTC timestamp when the crypto transaction was recorded. (Tier 1 — C2F.CryptoTransactions) |
| 53 | CryptoTransactionDateID | int | YES | — | CODE-BACKED | Date integer key YYYYMMDD from CryptoTransactionDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 54 | CryptoTransactionDate | date | YES | — | CODE-BACKED | Date portion of CryptoTransactionDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 55 | CryptoToFiatRate | decimal(36,18) | YES | — | VERIFIED | Actual exchange rate from crypto to fiat at execution time. May differ from EstimatedCryptoToFiatRate due to market movement. (Tier 1 — C2F.FiatTransactions) |
| 56 | FiatToUsdRate | decimal(36,18) | YES | — | VERIFIED | Actual fiat-to-USD exchange rate at execution time. 1.0 when target is USD. (Tier 1 — C2F.FiatTransactions) |
| 57 | CryptoToUsdRate | decimal(36,18) | YES | — | VERIFIED | Actual crypto-to-USD rate at execution time. Primary pricing rate. (Tier 1 — C2F.FiatTransactions) |
| 58 | FiatAmount | decimal(36,18) | YES | — | VERIFIED | Actual fiat amount credited to the customer in the target currency. Post-fee amount the customer receives. (Tier 1 — C2F.FiatTransactions) |
| 59 | UsdAmount | decimal(36,18) | YES | — | VERIFIED | USD equivalent of the fiat amount. Used for regulatory limit calculations. (Tier 1 — C2F.FiatTransactions) |
| 60 | FiatAccountID | varchar(100) | YES | — | VERIFIED | Customer's fiat account identifier where funds were credited. Format varies by target platform. (Tier 1 — C2F.FiatTransactions) |
| 61 | FiatDetails | varchar(514) | YES | — | VERIFIED | Unique client-load reference ID in format "C2F" + 8 digits. Indexed for lookups. Serves as external payment reference. (Tier 1 — C2F.FiatTransactions) |
| 62 | RateTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the exchange rate was locked. May precede FiatTxTime if rate was locked before fiat credit. (Tier 1 — C2F.FiatTransactions) |
| 63 | FiatTxTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the fiat transaction was recorded. (Tier 1 — C2F.FiatTransactions) |
| 64 | eMoneyTransactionID | int | YES | — | CODE-BACKED | FiatDwhDB transaction ID for the eToro Money fiat settlement event. Matched by C2FCorrelationID = FiatDwhDB.MoneyCorrelationID. NULL (10.8%) for EtoroPosition-path conversions. (Tier 2 — SP_EXW_C2F_E2E) |
| 65 | eMoneyTxCreatedDate | date | YES | — | CODE-BACKED | Date the eToro Money transaction was created in FiatDwhDB. (Tier 2 — SP_EXW_C2F_E2E) |
| 66 | eMoneyReferenceNumber | nvarchar(300) | YES | — | CODE-BACKED | External reference ID from eToro Money system. Matches FiatDetails ("C2F" + 8 digits format) for correlated rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 67 | eMoneyLastTxStatusID | int | YES | — | CODE-BACKED | Last transaction status ID in FiatDwhDB. Values: 2=Settled (all observed rows with data). (Tier 2 — SP_EXW_C2F_E2E) |
| 68 | eMoneyLastTxStatus | varchar(50) | YES | — | CODE-BACKED | Display name for eMoneyLastTxStatusID. Value observed: Settled. (Tier 2 — SP_EXW_C2F_E2E) |
| 69 | eMoneyHolderAmount | numeric(38,4) | YES | — | CODE-BACKED | Fiat amount credited to the eToro Money holder account. Should match FiatAmount for fully settled rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 70 | eMoneyLastStatusTime | datetime | YES | — | CODE-BACKED | Timestamp of the eToro Money transaction event. (Tier 2 — SP_EXW_C2F_E2E) |
| 71 | eMoneyProviderTransactionID | float | YES | — | CODE-BACKED | Provider-side transaction ID from the eToro Money settlement system (large numeric ID, ~17 digits). (Tier 2 — SP_EXW_C2F_E2E) |
| 72 | eMoneyAccountProgram | varchar(50) | YES | — | CODE-BACKED | eToro Money account program classification. Values: iban, card. (Tier 2 — SP_EXW_C2F_E2E) |
| 73 | eMoneyAccountSubProgram | varchar(50) | YES | — | CODE-BACKED | eToro Money account sub-program. Values: IBAN Standard UK, IBAN Green AUS, Card Standard UK. (Tier 2 — SP_EXW_C2F_E2E) |
| 74 | eMoneyCurrencyBalanceID | int | YES | — | CODE-BACKED | eToro Money currency balance account ID. Internal identifier for the customer's balance in the eMoney system. (Tier 2 — SP_EXW_C2F_E2E) |
| 75 | eMoneyProviderCurrencyBalanceID | int | YES | — | CODE-BACKED | Provider-side currency balance ID in the eToro Money system. References the provider's ledger entry. (Tier 2 — SP_EXW_C2F_E2E) |
| 76 | eMoneyHolderID | int | YES | — | CODE-BACKED | eToro Money holder account ID. Internal identifier for the customer's eToro Money account. (Tier 2 — SP_EXW_C2F_E2E) |
| 77 | eMoneyIsValidETM | int | YES | — | CODE-BACKED | Flag: 1=customer has a valid eToro Money (ETM) account. 1 for all settled rows with eMoney data. (Tier 2 — SP_EXW_C2F_E2E) |
| 78 | eMoneyEntity | varchar(100) | YES | — | CODE-BACKED | eToro Money legal entity for the fiat settlement. Values: eToro Money UK, eToro Money Malta, eToro Money AUS. (Tier 2 — SP_EXW_C2F_E2E) |
| 79 | IsTestAccount | int | YES | — | CODE-BACKED | Flag: 1=internal test/QA account. Sourced from EXW_dbo.EXW_DimUser.IsTestAccount. 0 for all production rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 80 | IsRequestDone | int | YES | — | CODE-BACKED | Computed flag: 1 if Wallet request reached Done status (RequestStatusId=1), 0 otherwise. (Tier 2 — SP_EXW_C2F_E2E) |
| 81 | TribeHolderAmount | decimal(36,18) | YES | — | CODE-BACKED | Amount in the Tribe (eToro Money settlement layer) holder account. Cross-validates against eMoneyHolderAmount. NULL (1,568 rows) for non-eMoney rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 82 | TribeTxDateTime | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the Tribe transaction. NULL when TribeHolderAmount is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 83 | DepositID | int | YES | — | CODE-BACKED | Billing deposit ID from DWH_dbo.Fact_BillingDeposit. Populated only for EtoroPosition conversions (TargetPlatformID=3). NULL (93%) for IbanAccount and EtoroPlatform paths. (Tier 2 — SP_EXW_C2F_E2E) |
| 84 | DepositDateTime | datetime2(7) | YES | — | CODE-BACKED | Payment date of the resulting deposit. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 85 | DepositModificationTime | datetime2(7) | YES | — | CODE-BACKED | Last modification time of the deposit record. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 86 | DepositLastStatusID | int | YES | — | CODE-BACKED | Last payment status ID of the deposit. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 87 | DepositLastStatus | varchar(100) | YES | — | CODE-BACKED | Display name for DepositLastStatusID. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 88 | DepositUSD | decimal(36,18) | YES | — | CODE-BACKED | USD-normalized deposit amount. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 89 | RegulationID | int | YES | — | CODE-BACKED | Regulatory jurisdiction ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join on LastModificationDateID. (Tier 2 — SP_EXW_C2F_E2E) |
| 90 | Regulation | varchar(250) | YES | — | CODE-BACKED | Regulation name at conversion time. Lookup from DWH_dbo.Dim_Regulation. Values: FCA, ASIC & GAML, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 91 | CountryID | int | YES | — | CODE-BACKED | Customer's country ID at conversion time from Fact_SnapshotCustomer point-in-time join. (Tier 2 — SP_EXW_C2F_E2E) |
| 92 | Country | varchar(250) | YES | — | CODE-BACKED | Country name from DWH_dbo.Dim_Country. Values: United Kingdom, Australia, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 93 | CustomerRegionID | int | YES | — | CODE-BACKED | US state/region ID. Non-NULL for US customers (CountryID=219) only. (Tier 2 — SP_EXW_C2F_E2E) |
| 94 | State | varchar(250) | YES | — | CODE-BACKED | US state name from DWH_dbo.Dim_State_and_Province. NULL for non-US customers. (Tier 2 — SP_EXW_C2F_E2E) |
| 95 | IsValidCustomer | int | YES | — | CODE-BACKED | Customer validity flag at conversion time from Fact_SnapshotCustomer. 1 for all observed rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 96 | IsCreditReportValidCB | int | YES | — | CODE-BACKED | Credit bureau report validity flag at conversion time from Fact_SnapshotCustomer. (Tier 2 — SP_EXW_C2F_E2E) |
| 97 | PlayerLevelID | int | YES | — | CODE-BACKED | Customer club tier ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_EXW_C2F_E2E) |
| 98 | Club | varchar(250) | YES | — | CODE-BACKED | Club tier name. Values: Bronze, Gold, Silver, Platinum, Diamond. (Tier 2 — SP_EXW_C2F_E2E) |
| 99 | PlayerStatusID | int | YES | — | CODE-BACKED | Customer activity status ID at conversion time from Fact_SnapshotCustomer. (Tier 2 — SP_EXW_C2F_E2E) |
| 100 | PlayerStatus | varchar(250) | YES | — | CODE-BACKED | Player status name. Values observed: Normal. (Tier 2 — SP_EXW_C2F_E2E) |
| 101 | WalletEntity | varchar(250) | YES | — | CODE-BACKED | eToro legal entity responsible for the customer's wallet. Values: eToroUK, eToroAUS, eToroEU. NULL (2.2%) when no WalletEntity record found for the date. (Tier 2 — SP_EXW_C2F_E2E) |
| 102 | AccountManager | varchar(1000) | YES | — | CODE-BACKED | Full name of the customer's account manager. "System " indicates no assigned manager. (Tier 2 — SP_EXW_C2F_E2E) |
| 103 | UpdateDate | datetime | NO | — | CODE-BACKED | SP_EXW_C2F_E2E batch timestamp. Only non-nullable column. Reflects SP execution time, not conversion time. (Tier 2 — SP_EXW_C2F_E2E) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| — | EXW_dbo.EXW_C2F_E2E | View over base table | All data sourced from base table; no independent storage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Relationship Type | Description |
|--------------|-------------------|-------------|
| BI reports / export pipelines | Consumer | Export-compatible surface for Power BI, Excel/ODBC, data delivery |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
EXW_dbo.V_EXW_C2F_E2E_4Export (depth=1, view)
└── EXW_dbo.EXW_C2F_E2E (depth=2, base table)
    ├── WalletConversionDB.C2F (5 tables via CopyFromLake)
    ├── WalletDB.Wallet (6 tables/views via EXW_Wallet)
    ├── FiatDwhDB (eMoney settlement tables)
    ├── DWH_dbo.Fact_SnapshotCustomer + Dim_Range (point-in-time)
    ├── DWH_dbo.Dim_* (Country, Regulation, PlayerLevel, PlayerStatus, Manager)
    ├── DWH_dbo.Fact_BillingDeposit (EtoroPosition path)
    ├── EXW_dbo.EXW_WalletEntity
    └── EXW_dbo.EXW_DimUser
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| EXW_dbo.EXW_C2F_E2E | Table | Sole data source — view wraps this table with 2 type casts |

---

## 7. Technical Details

### 7.1 View Definition

```sql
CREATE VIEW [EXW_dbo].[V_EXW_C2F_E2E_4Export] AS
SELECT
    CAST(C2FCorrelationID AS varchar(50)) AS C2FCorrelationID,
    TargetPlatformID,
    TargetPlatform,
    -- ... [101 direct pass-through columns] ...
    CAST([SentWalletID] AS varchar(50)) AS SentWalletID,
    -- ... [remaining pass-through columns] ...
    UpdateDate
FROM EXW_dbo.EXW_C2F_E2E;
```

### 7.2 Type Cast Details

| Column | Base Type | View Type | varchar(50) Capacity | Notes |
|--------|-----------|-----------|---------------------|-------|
| C2FCorrelationID | uniqueidentifier | varchar(50) | GUID = 36 chars — fits comfortably | Renders as uppercase `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` |
| SentWalletID | uniqueidentifier | varchar(50) | GUID = 36 chars — fits comfortably | Same format |

### 7.3 Known Issues / Gotchas

- No known issues with the view definition itself.
- If the base table EXW_C2F_E2E is truncated/rebuilt by SP_EXW_C2F_E2E, this view immediately reflects the new state (no caching).
- No UC target — view is not migrated to Unity Catalog.

---

## 8. Sample Queries

### 8.1 Full cycle volume by entity and month
```sql
SELECT eMoneyEntity,
    FORMAT(ConversionDate, 'yyyy-MM') AS YearMonth,
    COUNT(1) AS cnt,
    SUM(UsdAmount) AS TotalUSD
FROM EXW_dbo.V_EXW_C2F_E2E_4Export
WHERE ConversionCycle = 'Full Cycle'
    AND IsTestAccount = 0
GROUP BY eMoneyEntity, FORMAT(ConversionDate, 'yyyy-MM')
ORDER BY YearMonth DESC, TotalUSD DESC
```

### 8.2 Cross-reference by correlation ID (using varchar-cast form)
```sql
-- C2FCorrelationID is varchar(50) in this view
SELECT C2FCorrelationID, GCID, Crypto, FiatCurrency,
    CryptoAmount, FiatAmount, ConversionStatus, ConversionCycle
FROM EXW_dbo.V_EXW_C2F_E2E_4Export
WHERE C2FCorrelationID = 'FAEF03FC-1234-5678-ABCD-000000000001'
```

### 8.3 Rate slippage analysis
```sql
SELECT C2FCorrelationID, Crypto, FiatCurrency,
    EstimatedCryptoToFiatRate, CryptoToFiatRate,
    CryptoToFiatRate - EstimatedCryptoToFiatRate AS RateSlippage,
    FiatAmount, EstimatedFiatAmount
FROM EXW_dbo.V_EXW_C2F_E2E_4Export
WHERE ConversionStatusID = 3
    AND IsTestAccount = 0
ORDER BY ABS(CryptoToFiatRate - EstimatedCryptoToFiatRate) DESC
```

---

*Column descriptions T1/T2-inherited from [EXW_dbo.EXW_C2F_E2E](../Tables/EXW_C2F_E2E.md). Quality score: 9.60/10 (Phase 16 — 2026-04-20).*

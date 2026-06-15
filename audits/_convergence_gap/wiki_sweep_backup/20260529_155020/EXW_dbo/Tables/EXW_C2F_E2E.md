# EXW_dbo.EXW_C2F_E2E

> End-to-end reconciliation table for Crypto-to-Fiat (C2F) conversions, combining the WalletConversionDB conversion lifecycle (crypto sent, fiat received, status) with the eToro Money (eMoney) settlement side, Wallet request metadata, and a point-in-time customer snapshot. One row per conversion, capturing every stage from blockchain execution through fiat credit for 14,544 active conversions.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Fact/Reconciliation) |
| **Production Sources** | WalletConversionDB.C2F (Conversions, CryptoTransactions, FiatTransactions, EstimatedFiatTransactions, ConversionStatuses) + WalletDB.Wallet (SentTransactions, Requests) |
| **Writer SP** | EXW_dbo.SP_EXW_C2F_E2E |
| **Refresh** | Full reload (DELETE + INSERT) on every SP run |
| **Row Count** | 14,544 (as of April 2026) |
| **Date Range** | ConversionDateTime: active C2F conversions only |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_C2F_E2E is the central reconciliation and analytics table for the Crypto-to-Fiat (C2F) conversion product. Each row represents a single conversion — a customer selling cryptocurrency and receiving fiat currency — with every stage of the lifecycle captured in a single denormalized row.

The "E2E" name reflects the end-to-end scope: from the initial conversion request through the blockchain crypto transfer, the exchange rate locking, the fiat credit to the customer's account, and the downstream eToro Money settlement. The SP also enriches each row with a customer profile snapshot (regulation, country, player level) valid at the time of the conversion, enabling regulatory and cohort analysis without join overhead.

**Business context**: C2F conversions allow eToro Wallet users to sell crypto and receive fiat directly to an IBAN bank account (93% of rows), to an eToro trading account (7.5%), or to fund a trading position. Each conversion requires coordinated execution across three systems: WalletConversionDB (conversion orchestration), WalletDB (blockchain send), and FiatDwhDB (eMoney fiat settlement). The ConversionCycle column exposes the reconciliation state: `Full Cycle` (96%) means all three systems agree on success; other values indicate partial failures or data gaps requiring operational review.

**Note**: SP_EXW_C2F_E2E is a dual-writer procedure — it also populates EXW_dbo.EXW_C2P_E2E in the second half of the same run. Changes to SP_EXW_C2F_E2E affect both tables.

---

## 2. Business Logic

### 2.1 Conversion Cycle Reconciliation

**What**: The ConversionCycle column classifies each conversion's end-to-end completion state across three systems: WalletDB request, blockchain send, and eMoney settlement.

**Columns/Parameters Involved**: `ConversionCycle`, `TargetPlatformID`, `SentLastStatusID`, `ConversionStatusID`, `eMoneyLastTxStatusID`, `IsRequestDone`

**Rules**:
- `Full Cycle` (13,965 rows, 96%): All checks pass — request done, sent verified, conversion completed, eMoney settled
- `FailedConversion` (575 rows, 4%): ConversionStatusID=2 (Failed)
- `Other` (4 rows): Edge cases not matching other patterns
- ConversionCycle is only evaluated for TargetPlatformID=1 (IbanAccount); EtoroPlatform and EtoroPosition rows use a UNION ALL branch with deposit matching instead

### 2.2 Dual-Branch Population (IbanAccount vs EtoroPosition)

**What**: The SP uses a UNION ALL to handle two distinct C2F routing paths with different data sources.

**Columns/Parameters Involved**: `TargetPlatformID`, `DepositID`, `DepositUSD`, `TribeHolderAmount`, `eMoneyTransactionID`

**Rules**:
- **IbanAccount branch** (TargetPlatformID=1, and rows with no platform): Joins to EXW_Wallet.SentTransactions, FiatDwhDB eMoney transactions, and Tribe data. DepositID is NULL.
- **EtoroPosition branch** (TargetPlatformID=3): Joins to DWH_dbo.Fact_BillingDeposit (FundingTypeID=27) for the resulting deposit. DepositID is populated; eMoneyTransactionID and TribeHolderAmount are NULL.
- TargetPlatformID=2 (EtoroPlatform) rows are excluded from the IbanAccount branch by `WHERE ISNULL(TargetPlatformID,0) NOT IN (2,3)` and handled in the EtoroPosition/deposit path.

### 2.3 Point-in-Time Customer Snapshot

**What**: Customer attributes (regulation, country, player level, etc.) are joined at the date of the conversion using Fact_SnapshotCustomer + Dim_Range.

**Columns/Parameters Involved**: `RegulationID`, `Regulation`, `CountryID`, `Country`, `PlayerLevelID`, `Club`, `PlayerStatusID`, `IsValidCustomer`, `IsCreditReportValidCB`

**Rules**:
- Join: `Fact_SnapshotCustomer.DateRangeID BETWEEN Dim_Range.FromDateID AND Dim_Range.ToDateID`
- The LastModificationDateID is used as the reference date, giving the customer profile at conversion time
- This means customer attributes in this table reflect the customer's state AT THE TIME of the conversion, not today

### 2.4 eMoney Settlement Correlation

**What**: C2F fiat proceeds are settled through eToro Money (FiatDwhDB). The eMoney columns link each conversion to its corresponding settlement transaction.

**Columns/Parameters Involved**: `eMoneyTransactionID`, `eMoneyReferenceNumber`, `eMoneyLastTxStatus`, `eMoneyEntity`, `eMoneyAccountProgram`

**Rules**:
- Matched by C2FCorrelationID = FiatDwhDB.MoneyCorrelationID
- 1,567 rows (10.8%) have NULL eMoneyTransactionID — primarily TargetPlatformID=3 (EtoroPosition) conversions which don't flow through eMoney
- eMoneyReferenceNumber matches FiatDetails (the "C2F" + 8-digit reference)
- eMoneyIsValidETM=1 for virtually all settled rows; eMoneyEntity identifies the eToro Money legal entity (UK, Malta, AUS)

---

## 3. Data Overview

| C2FCorrelationID | TargetPlatformID | TargetPlatform | ConversionCycle | GCID | Crypto | FiatCurrency | CryptoAmount | FiatAmount | ConversionStatus |
|---|---|---|---|---|---|---|---|---|---|
| FAEF03FC-... | 1 | IbanAccount | Full Cycle | 47612115 | USDC | GBP | 1549.0 | 1147.54 | Completed |
| BEFB92B9-... | 1 | IbanAccount | Full Cycle | 27328904 | ETH | GBP | 0.085054 | 142.86 | Completed |
| 71F18F5C-... | 1 | IbanAccount | Full Cycle | 19612792 | BTC | GBP | 0.013958 | 772.33 | Completed |
| BC902A8D-... | 1 | IbanAccount | Full Cycle | 41501888 | XRP | AUD | 200.0 | 392.32 | Completed |

Key distribution (14,544 rows as of April 2026):
- **TargetPlatformID**: 1=IbanAccount (13,450), 2=EtoroPlatform (1,093), 1 NULL
- **ConversionCycle**: Full Cycle (13,965), FailedConversion (575), Other (4)
- **Top Cryptos**: BTC (5,877), ETH (3,733), XRP (1,988), USDC (1,853), SOL (519)
- **FiatCurrency**: GBP (7,287), EUR (5,856), USD (1,093), AUD (307)
- **eMoneyEntity**: Malta/iban (4,679), UK/iban (3,853), UK/card (3,254), NULL (1,567), Malta/card (923), AUS/iban (268)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | C2FCorrelationID | uniqueidentifier | YES | — | VERIFIED | Distributed tracing correlation ID linking this conversion to its Saga.SagaRuns orchestration entry and all cross-service operations. Used as the deduplication key by InsertConversion. Indexed with Id for lookups. All SPs identify conversions by CorrelationId rather than Id. (Tier 1 — C2F.Conversions) |
| 2 | TargetPlatformID | tinyint | YES | — | VERIFIED | Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target). Determines the downstream routing of fiat proceeds. (Tier 1 — C2F.Conversions) |
| 3 | TargetPlatform | varchar(256) | YES | — | VERIFIED | Display name for TargetPlatformID. Values: IbanAccount, EtoroPlatform, EtoroPosition. Lookup from WalletConversionDB Dictionary.FiatConversionTargets. (Tier 2 — SP_EXW_C2F_E2E) |
| 4 | ConversionCycle | varchar(216) | YES | — | VERIFIED | End-to-end reconciliation status classifying completion state across WalletDB request, blockchain send, and eMoney settlement. Values: Full Cycle (all systems agree success), FailedConversion (ConversionStatusID=2), Wallet Sent Tx Status Issue, Conversion Status Issue, eMoney Data Missing, eMoney Status Issue, eMoney Transaction Missing, Missing Wallet Side, Request Status Issue, Uncompleted Request, Other. Only evaluated for TargetPlatformID=1 (IbanAccount) path. (Tier 2 — SP_EXW_C2F_E2E) |
| 5 | LastModificationDateTime | datetime2(7) | YES | — | VERIFIED | Latest event timestamp across all sub-systems: GREATEST(FiatTransaction.Occurred, ConversionTime, ConversionStatusTime, CryptoTransactionTime). Represents the most recent activity for this conversion row. Used as the reference timestamp for LastModificationDate and LastModificationDateID. (Tier 2 — SP_EXW_C2F_E2E) |
| 6 | LastModificationDate | date | YES | — | VERIFIED | Date portion of LastModificationDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 7 | LastModificationDateID | int | YES | — | VERIFIED | Date integer key in YYYYMMDD format derived from LastModificationDate. Used as the reference date for the point-in-time customer snapshot join (Fact_SnapshotCustomer BETWEEN Dim_Range.FromDateID AND ToDateID). (Tier 2 — SP_EXW_C2F_E2E) |
| 8 | GCID | int | YES | — | VERIFIED | Global Customer ID identifying the customer who initiated the conversion. Validated NOT NULL by InsertConversion (raises error if null). Indexed for customer-scoped queries (GetConversionAmounts, GetConversionsUsdSum). (Tier 2 — C2F.Conversions) |
| 9 | RealCID | int | YES | — | VERIFIED | Internal CID after deduplication mapping. Sourced from EXW_dbo.EXW_DimUser.RealCID; maps GCID to the canonical customer record. (Tier 2 — SP_EXW_C2F_E2E) |
| 10 | RequestID | bigint | YES | — | VERIFIED | Auto-incrementing primary key and the primary identifier for a request across the entire wallet system. Referenced by Wallet.RequestStatuses.RequestId as FK. Also used as lookup key by numerous stored procedures. (Tier 1 — Wallet.Requests) |
| 11 | RequestCryptoID | int | YES | — | VERIFIED | Identifier of the cryptocurrency this request operates on. Implicit reference to Wallet.CryptoTypes.CryptoID. For conversions, this is the source crypto. Combined with Gcid for per-user per-crypto request lookups. (Tier 1 — Wallet.Requests) |
| 12 | RequestDateTime | datetime2(7) | YES | — | VERIFIED | When the request was created. No default - explicitly set by the calling code. Used for chronological ordering, SLA monitoring, and date-range queries. Indexed descending for recent-request lookups. (Tier 1 — Wallet.Requests) |
| 13 | RequestLastStatusID | tinyint | YES | — | CODE-BACKED | Last-known status ID of the Wallet ConversionToFiat request. Derived by ROW_NUMBER() OVER (PARTITION BY er.Id ORDER BY ers.Timestamp DESC) = 1 from Wallet.RequestStatuses. Values: 1=Done, 2=Error, 7=TransactionVerified, 31=ReadByConversionWorker. (Tier 2 — SP_EXW_C2F_E2E) |
| 14 | RequestLastStatus | varchar(64) | YES | — | CODE-BACKED | Display name for RequestLastStatusID. Lookup from WalletDB_Dictionary_RequestStatuses. Values observed: Done, Error, TransactionVerified, ReadByConversionWorker. (Tier 2 — SP_EXW_C2F_E2E) |
| 15 | RequestLastStatusDateTime | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the last RequestStatuses entry for this request. Corresponds to when the RequestLastStatusID was set. (Tier 2 — SP_EXW_C2F_E2E) |
| 16 | SentTransactionID | bigint | YES | — | VERIFIED | Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces. (Tier 1 — Wallet.SentTransactions) |
| 17 | SentBlockchainTransactionID | nvarchar(100) | YES | — | VERIFIED | The on-chain transaction hash/ID. Unique constraint enforced. Can be looked up on blockchain explorers. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). (Tier 1 — Wallet.SentTransactions) |
| 18 | SentWalletID | uniqueidentifier | YES | — | VERIFIED | The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer's wallet. For redemptions, this is the system's omnibus/redeem wallet. (Tier 1 — Wallet.SentTransactions) |
| 19 | SentTransactionDateTime | datetime2(7) | YES | — | VERIFIED | Timestamp when the transaction was broadcast to the blockchain. NULL only for legacy records. (Tier 1 — Wallet.SentTransactions) |
| 20 | SentBlockchainFee | numeric(36,18) | YES | — | VERIFIED | Network fee paid in the crypto's native units. Recorded after on-chain confirmation. Used for cost analysis, customer billing, and financial reconciliation. (Tier 1 — Wallet.SentTransactions) |
| 21 | SentCryptoID | int | YES | — | VERIFIED | The cryptocurrency sent. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId for per-wallet per-crypto transaction history queries. (Tier 1 — Wallet.SentTransactions) |
| 22 | SentAmount | numeric(36,18) | YES | — | CODE-BACKED | Amount of crypto transferred in the sent transaction. Sourced from Wallet.SentTransactionOutputs.Amount (the output detail record). Matches or closely tracks CryptoAmount. (Tier 2 — SP_EXW_C2F_E2E) |
| 23 | SentEtoroFees | numeric(36,18) | YES | — | CODE-BACKED | eToro fees deducted from the blockchain output. Sourced from Wallet.SentTransactionOutputs.EtoroFees. Observed as 0 for all current rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 24 | SentLastStatusID | tinyint | YES | — | CODE-BACKED | Last-known status ID of the sent transaction. Derived by ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY ests.Occurred DESC) = 1 from Wallet.SentTransactionStatuses. Values: 2=Verified, 6=WavedError. NULL when no sent transaction exists (failed conversions). (Tier 2 — SP_EXW_C2F_E2E) |
| 25 | SentLastStatus | varchar(50) | YES | — | CODE-BACKED | Display name for SentLastStatusID. Lookup from WalletDB_Dictionary_TransactionStatus. Values observed: Verified, WavedError. NULL when SentTransactionID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 26 | EstimatedFiatAmount | decimal(36,18) | YES | — | VERIFIED | Estimated fiat amount the customer will receive, in the target fiat currency (determined by Conversions.FiatId). Calculated as CryptoAmount * CryptoToFiatRate (approximately, with fee adjustments). (Tier 1 — C2F.EstimatedFiatTransactions) |
| 27 | EstimatedUsdAmount | decimal(36,18) | YES | — | VERIFIED | Estimated USD equivalent of the fiat amount. Used as the normalization currency for regulatory limit calculations (GetConversionsUsdSum). When FiatId=1 (USD), equals FiatAmount. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 28 | EstimatedCryptoToUsdRate | decimal(36,18) | YES | — | VERIFIED | Exchange rate from the source crypto asset to USD at conversion creation time. The primary pricing rate. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 29 | EstimatedFiatToUsdRate | decimal(36,18) | YES | — | VERIFIED | Exchange rate from the target fiat currency to USD. When target is USD, this is 1.0. Used to derive the cross-rate: CryptoToFiatRate = CryptoToUsdRate / FiatToUsdRate. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 30 | EstimatedCryptoToFiatRate | decimal(36,18) | YES | — | VERIFIED | Direct exchange rate from source crypto to target fiat. This is the rate shown to the customer. Derived from CryptoToUsdRate / FiatToUsdRate. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 31 | EstimatedDateTime | datetime2(7) | YES | — | CODE-BACKED | UTC timestamp when the estimate was recorded. Matches Conversions.Occurred since both are created in the same transaction. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 32 | C2FConversionID | int | YES | — | VERIFIED | Auto-incrementing surrogate primary key. Referenced by all child tables (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) via ConversionId FK. (Tier 1 — C2F.Conversions) |
| 33 | CryptoID | int | YES | — | VERIFIED | Crypto asset identifier (external reference). Identifies which cryptocurrency is being sold. Values observed: 4, 64, 107 (likely mapped to assets like BTC, ETH, etc. in an external system). (Tier 1 — C2F.Conversions) |
| 34 | Crypto | nvarchar(256) | YES | — | VERIFIED | Display name for CryptoID. Lookup from EXW_Wallet.CryptoTypes. Values observed: BTC, ETH, XRP, USDC, SOL, DOGE, ADA, TRX, LTC, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 35 | FiatCurrencyID | int | YES | — | CODE-BACKED | Fiat currency identifier (external reference). Identifies which fiat currency the customer receives. Values observed: 1, 2 (likely USD, EUR). (Tier 1 — C2F.Conversions) |
| 36 | FiatCurrency | nvarchar(256) | YES | — | VERIFIED | Display name for FiatCurrencyID. Lookup from EXW_Wallet.FiatTypes. Values observed: GBP (50%), EUR (40%), USD (7.5%), AUD (2%). (Tier 2 — SP_EXW_C2F_E2E) |
| 37 | CryptoAmount | decimal(36,18) | YES | — | VERIFIED | Quantity of cryptocurrency being converted. High precision (18 decimals) to handle fractional crypto amounts. This is the gross amount before fees. (Tier 1 — C2F.Conversions) |
| 38 | TotalFeePercentage | decimal(36,18) | YES | — | VERIFIED | Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. Zero fee observed for some EtoroPosition conversions. (Tier 1 — C2F.Conversions) |
| 39 | TotalFeeUSD | decimal(36,18) | YES | — | CODE-BACKED | Fee amount in USD. Computed by SP: CAST(CryptoAmount AS FLOAT) * CAST(CryptoToUsdRate AS FLOAT) / 100 * TotalFeePercentage. Approximation subject to float precision. (Tier 2 — SP_EXW_C2F_E2E) |
| 40 | ConversionDateTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the conversion was created. Default constraint provides automatic timestamping. Indexed DESC for recency queries. Used by time-windowed queries (GetConversionAmounts, GetConversionsUsdSum) via @FromDateTime filter. (Tier 1 — C2F.Conversions) |
| 41 | ConversionDateID | int | YES | — | CODE-BACKED | Date integer key (YYYYMMDD) derived from ConversionDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 42 | ConversionDate | date | YES | — | CODE-BACKED | Date portion of ConversionDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 43 | ConversionStatusID | int | YES | — | VERIFIED | FK to Dictionary.ConversionToFiatStatuses. Current status in this transition. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status). Included in NC index on ConversionId for covering queries. (Tier 1 — C2F.ConversionStatuses) |
| 44 | ConversionStatus | varchar(64) | YES | — | VERIFIED | Display name for ConversionStatusID. Lookup from WalletConversionDB_Dictionary_ConversionToFiatStatuses. Values: Pending, Failed, Completed, Rejected. (Tier 2 — SP_EXW_C2F_E2E) |
| 45 | ConversionStatusDateTime | datetime2(7) | YES | — | CODE-BACKED | UTC timestamp of the most recent ConversionStatuses entry (ORDER BY Occurred DESC, Rn=1). Represents when ConversionStatusID was set. (Tier 2 — SP_EXW_C2F_E2E) |
| 46 | ConversionStatusDateID | int | YES | — | CODE-BACKED | Date integer key (YYYYMMDD) derived from ConversionStatusDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 47 | ConversionStatusDate | date | YES | — | CODE-BACKED | Date portion of ConversionStatusDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 48 | BlockchainTransactionID | nvarchar(max) | YES | — | VERIFIED | On-chain transaction hash/identifier. Unique across all rows (UNIQUE constraint). Format varies by blockchain: Ethereum "0x" + 64 hex chars, Ripple uppercase hex, etc. Serves as proof of on-chain execution. (Tier 1 — C2F.CryptoTransactions) |
| 49 | FromAddress | nvarchar(max) | YES | — | CODE-BACKED | Source blockchain address of the customer's wallet at conversion time. Sourced from Wallet.CustomerWalletsView.Address, joined on GCID and CryptoId. Reflects the wallet that sent the crypto. NULL (0 observed) for all rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 50 | ToAddress | nvarchar(max) | YES | — | VERIFIED | Destination blockchain address where crypto was sent. May include chain-specific qualifiers (Ripple destination tags as "?dt=..."). Repeated addresses across transactions suggest omnibus wallet patterns. (Tier 1 — C2F.CryptoTransactions) |
| 51 | BlockchainFee | decimal(36,18) | YES | — | VERIFIED | Network/gas fee charged by the blockchain for processing the transaction. Very small values observed (0.000045 XRP, 6e-8 for ERC-20). Deducted from the transfer, not from the conversion amount. (Tier 1 — C2F.CryptoTransactions) |
| 52 | CryptoTransactionDateTime | datetime2(7) | YES | — | CODE-BACKED | UTC timestamp when the crypto transaction was recorded. Default constraint auto-sets. (Tier 1 — C2F.CryptoTransactions) |
| 53 | CryptoTransactionDateID | int | YES | — | CODE-BACKED | Date integer key (YYYYMMDD) derived from CryptoTransactionDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 54 | CryptoTransactionDate | date | YES | — | CODE-BACKED | Date portion of CryptoTransactionDateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 55 | CryptoToFiatRate | decimal(36,18) | YES | — | VERIFIED | Actual exchange rate from crypto to fiat at execution time. May differ from EstimatedFiatTransactions.CryptoToFiatRate due to market movement. (Tier 1 — C2F.FiatTransactions) |
| 56 | FiatToUsdRate | decimal(36,18) | YES | — | VERIFIED | Actual fiat-to-USD exchange rate at execution time. 1.0 when target currency is USD. (Tier 1 — C2F.FiatTransactions) |
| 57 | CryptoToUsdRate | decimal(36,18) | YES | — | VERIFIED | Actual crypto-to-USD rate at execution time. Primary pricing rate. (Tier 1 — C2F.FiatTransactions) |
| 58 | FiatAmount | decimal(36,18) | YES | — | VERIFIED | Actual fiat amount credited to the customer in the target currency. This is the post-fee amount the customer receives. (Tier 1 — C2F.FiatTransactions) |
| 59 | UsdAmount | decimal(36,18) | YES | — | VERIFIED | USD equivalent of the fiat amount. Used for regulatory limit calculations. Preferred over EstimatedFiatTransactions.UsdAmount when available. (Tier 1 — C2F.FiatTransactions) |
| 60 | FiatAccountID | varchar(100) | YES | — | VERIFIED | Customer's fiat account identifier where the funds were credited. Format varies by target platform (IBAN account number, platform account ID, etc.). (Tier 1 — C2F.FiatTransactions) |
| 61 | FiatDetails | varchar(514) | YES | — | VERIFIED | Unique client-load reference ID in format "C2F" + 8 digits. Generated by GenerateUniqueClientLoadReferenceId. Serves as external payment reference. Indexed for lookups. (Tier 1 — C2F.FiatTransactions) |
| 62 | RateTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the exchange rate was locked for this transaction. May precede the Occurred timestamp if rate was locked before the fiat credit was recorded. (Tier 1 — C2F.FiatTransactions) |
| 63 | FiatTxTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the fiat transaction was recorded. (Tier 1 — C2F.FiatTransactions) |
| 64 | eMoneyTransactionID | int | YES | — | CODE-BACKED | FiatDwhDB transaction ID for the eToro Money fiat settlement event. Matched by C2FCorrelationID = FiatDwhDB.MoneyCorrelationID. NULL (1,567 rows, 10.8%) for EtoroPosition-path conversions. (Tier 2 — SP_EXW_C2F_E2E) |
| 65 | eMoneyTxCreatedDate | date | YES | — | CODE-BACKED | Date the eToro Money transaction was created in FiatDwhDB. (Tier 2 — SP_EXW_C2F_E2E) |
| 66 | eMoneyReferenceNumber | nvarchar(300) | YES | — | CODE-BACKED | External reference ID from the eToro Money system. Matches FiatDetails ("C2F" + 8 digits format) for correlated rows, confirming end-to-end reference linkage. (Tier 2 — SP_EXW_C2F_E2E) |
| 67 | eMoneyLastTxStatusID | int | YES | — | CODE-BACKED | Last transaction status ID in the FiatDwhDB system. Values: 2=Settled (all observed rows with data). (Tier 2 — SP_EXW_C2F_E2E) |
| 68 | eMoneyLastTxStatus | varchar(50) | YES | — | CODE-BACKED | Display name for eMoneyLastTxStatusID. Lookup from FiatDwhDB_Dictionary_TransactionStatuses. Value observed: Settled. (Tier 2 — SP_EXW_C2F_E2E) |
| 69 | eMoneyHolderAmount | numeric(38,4) | YES | — | CODE-BACKED | Fiat amount credited to the eToro Money holder account. Should match FiatAmount for fully settled rows (minor precision differences observed). (Tier 2 — SP_EXW_C2F_E2E) |
| 70 | eMoneyLastStatusTime | datetime | YES | — | CODE-BACKED | Timestamp of the eToro Money transaction event. (Tier 2 — SP_EXW_C2F_E2E) |
| 71 | eMoneyProviderTransactionID | float | YES | — | CODE-BACKED | Provider-side transaction ID from the eToro Money settlement system (large numeric ID, ~17 digits). (Tier 2 — SP_EXW_C2F_E2E) |
| 72 | eMoneyAccountProgram | varchar(50) | YES | — | CODE-BACKED | eToro Money account program classification. Values: iban, card. Indicates whether the customer's eToro Money account is bank-account-based or card-based. (Tier 2 — SP_EXW_C2F_E2E) |
| 73 | eMoneyAccountSubProgram | varchar(50) | YES | — | CODE-BACKED | eToro Money account sub-program. Values observed: IBAN Standard UK, IBAN Green AUS, Card Standard UK. More granular classification within the program type. (Tier 2 — SP_EXW_C2F_E2E) |
| 74 | eMoneyCurrencyBalanceID | int | YES | — | CODE-BACKED | eToro Money currency balance account ID. Internal identifier for the customer's balance in the eMoney system. (Tier 2 — SP_EXW_C2F_E2E) |
| 75 | eMoneyProviderCurrencyBalanceID | int | YES | — | CODE-BACKED | Provider-side currency balance ID in the eToro Money system. Distinct from eMoneyCurrencyBalanceID, referencing the provider's ledger entry. (Tier 2 — SP_EXW_C2F_E2E) |
| 76 | eMoneyHolderID | int | YES | — | CODE-BACKED | eToro Money holder account ID. Internal identifier for the customer's eToro Money account (FiatDwhDB.HolderID). (Tier 2 — SP_EXW_C2F_E2E) |
| 77 | eMoneyIsValidETM | int | YES | — | CODE-BACKED | Flag indicating whether the customer has a valid eToro Money (ETM) account. 1=valid for all settled rows with eMoney data. (Tier 2 — SP_EXW_C2F_E2E) |
| 78 | eMoneyEntity | varchar(100) | YES | — | CODE-BACKED | eToro Money legal entity responsible for the fiat settlement. Values: eToro Money UK, eToro Money Malta, eToro Money AUS. Determines which regulatory entity handled the conversion proceeds. (Tier 2 — SP_EXW_C2F_E2E) |
| 79 | IsTestAccount | int | YES | — | CODE-BACKED | Flag indicating whether this is an internal test/QA account. Sourced from EXW_dbo.EXW_DimUser.IsTestAccount. 0 for all production rows observed. (Tier 2 — SP_EXW_C2F_E2E) |
| 80 | IsRequestDone | int | YES | — | CODE-BACKED | Computed flag: 1 if the Wallet request reached Done status (RequestStatusId=1), 0 otherwise. Derived by SP via #requestdone presence check: CASE WHEN rd.RequestCorrelationID IS NOT NULL THEN 1 ELSE 0 END. (Tier 2 — SP_EXW_C2F_E2E) |
| 81 | TribeHolderAmount | decimal(36,18) | YES | — | CODE-BACKED | Amount in the Tribe (eToro Money settlement layer) holder account. Sourced from FiatDwhDB Tribe schema, matched via eMoneyProviderTransactionID. Cross-validates against eMoneyHolderAmount. NULL (1,568 rows) for non-eMoney rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 82 | TribeTxDateTime | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the Tribe transaction. Sourced from FiatDwhDB Tribe.WorkDate. NULL when TribeHolderAmount is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 83 | DepositID | int | YES | — | CODE-BACKED | Billing deposit ID from DWH_dbo.Fact_BillingDeposit. Populated only for EtoroPosition conversions (TargetPlatformID=3) where the fiat proceeds fund a trading deposit (FundingTypeID=27). NULL (13,555 rows, 93%) for IbanAccount and EtoroPlatform paths. (Tier 2 — SP_EXW_C2F_E2E) |
| 84 | DepositDateTime | datetime2(7) | YES | — | CODE-BACKED | Payment date of the resulting deposit from Fact_BillingDeposit.PaymentDate. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 85 | DepositModificationTime | datetime2(7) | YES | — | CODE-BACKED | Last modification time of the deposit record from Fact_BillingDeposit.ModificationDate. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 86 | DepositLastStatusID | int | YES | — | CODE-BACKED | Last payment status ID of the deposit from Fact_BillingDeposit.PaymentStatusID. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 87 | DepositLastStatus | varchar(100) | YES | — | CODE-BACKED | Display name for DepositLastStatusID, joined from DWH_dbo.Dim_PaymentStatus. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 88 | DepositUSD | decimal(36,18) | YES | — | CODE-BACKED | USD-normalized deposit amount from Fact_BillingDeposit.AmountUSD. NULL when DepositID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 89 | RegulationID | int | YES | — | CODE-BACKED | Regulatory jurisdiction ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join on LastModificationDateID. (Tier 2 — SP_EXW_C2F_E2E) |
| 90 | Regulation | varchar(250) | YES | — | CODE-BACKED | Regulation name. Lookup from DWH_dbo.Dim_Regulation. Values observed: FCA, ASIC & GAML, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 91 | CountryID | int | YES | — | CODE-BACKED | Customer's country ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join. (Tier 2 — SP_EXW_C2F_E2E) |
| 92 | Country | varchar(250) | YES | — | CODE-BACKED | Country name lookup from DWH_dbo.Dim_Country. Values observed: United Kingdom, Australia, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 93 | CustomerRegionID | int | YES | — | CODE-BACKED | US state/region ID for US customers only. Computed: Fact_SnapshotCustomer.RegionID when CountryID=219, NULL otherwise. (Tier 2 — SP_EXW_C2F_E2E) |
| 94 | State | varchar(250) | YES | — | CODE-BACKED | US state name for US customers only. Lookup from DWH_dbo.Dim_State_and_Province when CountryID=219, NULL otherwise. (Tier 2 — SP_EXW_C2F_E2E) |
| 95 | IsValidCustomer | int | YES | — | CODE-BACKED | Customer validity flag at conversion time from Fact_SnapshotCustomer. 1=valid for all observed rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 96 | IsCreditReportValidCB | int | YES | — | CODE-BACKED | Credit bureau report validity flag at conversion time from Fact_SnapshotCustomer. (Tier 2 — SP_EXW_C2F_E2E) |
| 97 | PlayerLevelID | int | YES | — | CODE-BACKED | Customer club tier ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_EXW_C2F_E2E) |
| 98 | Club | varchar(250) | YES | — | CODE-BACKED | Club tier name lookup from DWH_dbo.Dim_PlayerLevel. Values observed: Bronze, Gold, Silver, Platinum, Diamond. (Tier 2 — SP_EXW_C2F_E2E) |
| 99 | PlayerStatusID | int | YES | — | CODE-BACKED | Customer activity status ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_EXW_C2F_E2E) |
| 100 | PlayerStatus | varchar(250) | YES | — | CODE-BACKED | Player status name lookup from DWH_dbo.Dim_PlayerStatus. Values observed: Normal. (Tier 2 — SP_EXW_C2F_E2E) |
| 101 | WalletEntity | varchar(250) | YES | — | CODE-BACKED | eToro legal entity responsible for the customer's wallet. Sourced from EXW_dbo.EXW_WalletEntity joined on GCID and LastModificationDateID. Values: eToroUK, eToroAUS, eToroEU, and others. NULL (317 rows, 2.2%) when no WalletEntity record found for the date. (Tier 2 — SP_EXW_C2F_E2E) |
| 102 | AccountManager | varchar(1000) | YES | — | CODE-BACKED | Full name of the customer's account manager. Computed by SP as DWH_dbo.Dim_Manager.FirstName + ' ' + LastName, joined via Fact_SnapshotCustomer.AccountManagerID. Value "System " indicates no assigned manager. (Tier 2 — SP_EXW_C2F_E2E) |
| 103 | UpdateDate | datetime | NO | — | CODE-BACKED | Timestamp of when this row was loaded by SP_EXW_C2F_E2E. Batch watermark; reflects the SP execution time, not the conversion time. (Tier 2 — SP_EXW_C2F_E2E) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | Implicit | Customer identity; GCID is the join key |
| TargetPlatformID | WalletConversionDB.Dictionary.FiatConversionTargets | Upstream FK | Fiat destination type (denormalized as TargetPlatform) |
| CryptoID | EXW_Wallet.CryptoTypes | Implicit | Crypto asset (denormalized as Crypto) |
| FiatCurrencyID | EXW_Wallet.FiatTypes | Implicit | Fiat currency (denormalized as FiatCurrency) |
| ConversionStatusID | WalletConversionDB.Dictionary.ConversionToFiatStatuses | Upstream FK | Conversion lifecycle status (denormalized as ConversionStatus) |
| RequestLastStatusID | WalletDB.Dictionary.RequestStatuses | Upstream FK | Wallet request status (denormalized as RequestLastStatus) |
| SentLastStatusID | WalletDB.Dictionary.TransactionStatus | Upstream FK | Sent transaction status (denormalized as SentLastStatus) |
| RegulationID | DWH_dbo.Dim_Regulation | Implicit | Regulatory jurisdiction (denormalized as Regulation) |
| CountryID | DWH_dbo.Dim_Country | Implicit | Customer country (denormalized as Country) |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Implicit | Club tier (denormalized as Club) |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Implicit | Player status (denormalized as PlayerStatus) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EXW_dbo.V_EXW_C2F_E2E_4Export | — | View | Export view wrapping this table for downstream data delivery |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
EXW_dbo.EXW_C2F_E2E (depth=4)
├── WalletConversionDB.C2F (CopyFromLake: Conversions, CryptoTransactions, FiatTransactions, EstimatedFiatTransactions, ConversionStatuses)
├── WalletDB.Wallet (EXW_Wallet views: SentTransactions, Requests, RequestStatuses, SentTransactionOutputs, SentTransactionStatuses, CustomerWalletsView)
├── FiatDwhDB (EXW_Wallet eMoney tables)
├── DWH_dbo.Fact_SnapshotCustomer → DWH_dbo.Dim_Range (point-in-time join)
├── DWH_dbo.Dim_Country, Dim_Regulation, Dim_PlayerLevel, Dim_PlayerStatus, Dim_Manager
├── DWH_dbo.Fact_BillingDeposit (EtoroPosition path only)
├── EXW_dbo.EXW_WalletEntity
└── EXW_dbo.EXW_DimUser
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| CopyFromLake.WalletConversionDB_C2F_Conversions | External Table | Primary C2F conversion records |
| CopyFromLake.WalletConversionDB_C2F_CryptoTransactions | External Table | Blockchain transaction details |
| CopyFromLake.WalletConversionDB_C2F_FiatTransactions | External Table | Actual fiat transaction details |
| CopyFromLake.WalletConversionDB_C2F_EstimatedFiatTransactions | External Table | Pre-execution rate quotes |
| CopyFromLake.WalletConversionDB_C2F_ConversionStatuses | External Table | Conversion lifecycle status |
| EXW_Wallet.SentTransactions | External Table | Blockchain sent transaction records |
| EXW_Wallet.SentTransactionOutputs | External Table | Output amounts and fees |
| EXW_Wallet.SentTransactionStatuses | External Table | Sent transaction lifecycle status |
| EXW_Wallet.Requests | External Table | Wallet operation requests |
| EXW_Wallet.RequestStatuses | External Table | Request lifecycle status |
| EXW_Wallet.CustomerWalletsView | View | Customer wallet addresses |
| DWH_dbo.Fact_SnapshotCustomer | Table | Point-in-time customer snapshot |
| DWH_dbo.Dim_Range | Table | Date range for point-in-time join |
| DWH_dbo.Fact_BillingDeposit | Table | EtoroPosition path deposit data |
| EXW_dbo.EXW_WalletEntity | Table | eToro legal entity per customer/date |
| EXW_dbo.EXW_DimUser | Table | RealCID and IsTestAccount lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EXW_dbo.V_EXW_C2F_E2E_4Export | View | Export wrapper |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (heap) | HEAP | — | — | — | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DISTRIBUTION | HASH | HASH(GCID) — routes rows by customer |
| UpdateDate | NOT NULL | Only non-nullable column; batch timestamp |

### 7.3 ETL Schedule

SP_EXW_C2F_E2E runs on a scheduled basis (daily), performing a full DELETE + INSERT. The same SP also populates EXW_dbo.EXW_C2P_E2E (Crypto-to-Position) in its second half. No incremental loading — each run rebuilds the full set of C2F conversions from source.

---

## 8. Sample Queries

### 8.1 Full cycle summary by crypto and entity
```sql
SELECT Crypto, eMoneyEntity, COUNT(1) cnt, SUM(UsdAmount) total_usd
FROM EXW_dbo.EXW_C2F_E2E
WHERE ConversionCycle = 'Full Cycle'
GROUP BY Crypto, eMoneyEntity
ORDER BY total_usd DESC
```

### 8.2 Rate slippage — estimated vs actual
```sql
SELECT C2FCorrelationID, Crypto, FiatCurrency,
    EstimatedCryptoToFiatRate, CryptoToFiatRate,
    CryptoToFiatRate - EstimatedCryptoToFiatRate AS RateSlippage,
    FiatAmount, EstimatedFiatAmount,
    FiatAmount - EstimatedFiatAmount AS FiatAmountDiff
FROM EXW_dbo.EXW_C2F_E2E
WHERE ConversionStatusID = 3
ORDER BY ABS(CryptoToFiatRate - EstimatedCryptoToFiatRate) DESC
```

### 8.3 Failed conversions needing investigation
```sql
SELECT C2FCorrelationID, GCID, Crypto, FiatCurrency, CryptoAmount,
    ConversionCycle, ConversionStatus, ConversionStatusDateTime,
    RequestLastStatus, SentLastStatus, eMoneyLastTxStatus
FROM EXW_dbo.EXW_C2F_E2E
WHERE ConversionCycle != 'Full Cycle'
ORDER BY ConversionStatusDateTime DESC
```

### 8.4 Conversion volume by regulation and date
```sql
SELECT RegulationID, Regulation, ConversionDate, COUNT(1) cnt,
    SUM(UsdAmount) total_usd
FROM EXW_dbo.EXW_C2F_E2E
WHERE ConversionStatusID = 3
GROUP BY RegulationID, Regulation, ConversionDate
ORDER BY ConversionDate DESC, total_usd DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources searched (Phase 10 skipped for EXW tables — low confluence coverage expected).

---

*Generated: 2026-04-20 | Enriched: - | Quality: pending | Phases: P1 P2 P3 P4 P5 P6 P7 P8 P9 P10A P10B P11*
*Confidence: 0 EXPERT, 38 VERIFIED (T1), 65 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Sources: WalletConversionDB.C2F (5 tables), WalletDB.Wallet (2 tables) | Writer SP: SP_EXW_C2F_E2E (1,679 lines)*
*Object: EXW_dbo.EXW_C2F_E2E | Type: Table | Source: DataPlatform/SynapseSQLPool1/sql_dp_prod_we/EXW_dbo/Tables/EXW_dbo.EXW_C2F_E2E.sql*

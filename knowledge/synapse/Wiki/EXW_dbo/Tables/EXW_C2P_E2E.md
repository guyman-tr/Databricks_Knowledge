# EXW_dbo.EXW_C2P_E2E

> End-to-end reconciliation table for Crypto-to-Position (C2P) conversions, combining the WalletConversionDB conversion lifecycle (crypto sent, position opened, status) with Dealing staging admin position logs, eToro DWH position and customer action data, and a point-in-time customer snapshot. One row per conversion, capturing every stage from blockchain execution through position opening for 3,967 C2P conversions. Exclusively covers TargetPlatformID=3 (EtoroPosition) — the subset of C2F conversions where the converted value funds a new trading position rather than an IBAN bank account.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Fact/Reconciliation) |
| **Production Sources** | WalletConversionDB.C2F (Conversions, CryptoTransactions, EstimatedFiatTransactions, ConversionStatuses) + WalletDB.Wallet (SentTransactions, Requests) + Dealing_staging.etoro_Trade_AdminPositionLog + DWH_dbo (Dim_Position, Fact_CustomerAction, Fact_SnapshotCustomer) |
| **Writer SP** | EXW_dbo.SP_EXW_C2F_E2E |
| **Refresh** | Full reload (DELETE + INSERT) on every SP run |
| **Row Count** | 3,967 (as of April 2026) |
| **Date Range** | ConversionTime: C2P conversions from 2025-12-11 onwards |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_C2P_E2E is the end-to-end reconciliation and analytics table for the Crypto-to-Position (C2P) conversion product. Each row represents a single conversion where a customer sells cryptocurrency and the resulting USD value is used to open a new trading position on the eToro platform — the "E2E" scope spanning from the blockchain crypto send through the eToro position opening.

C2P is a subset of the broader Crypto-to-Fiat (C2F) product, filtering exclusively on TargetPlatformID=3 (EtoroPosition). Unlike the C2F IbanAccount path — where fiat is credited to a bank account via eToro Money — the C2P path routes the converted value directly into an eToro trading position via an admin position log entry (CompensationReasonID=134 "Crypto Transfer"). The position is opened by the Dealing system on the customer's behalf and is classified as an AirDrop (IsAirDrop=1) in Fact_CustomerAction.

**Business context**: C2P enables a direct "crypto-to-position" workflow: a customer converts BTC, ETH, SOL, or another supported crypto, and instead of receiving cash, a long trading position on a specified instrument (e.g., BTC/USD, SOL/USD) is opened for the equivalent USD amount. This table supports regulatory reporting, reconciliation (matching wallet sends to position opens), and operations monitoring. The product launched 2025-12-11.

**Note**: SP_EXW_C2F_E2E is a dual-writer procedure — it populates EXW_C2F_E2E in the first half and EXW_C2P_E2E in the second half of the same run. Any change to SP_EXW_C2F_E2E affects both tables.

---

## 2. Business Logic

### 2.1 C2P Flow and Position Matching

**What**: A C2P conversion links a WalletConversionDB conversion record (TargetPlatformID=3) to an eToro position opened on the customer's behalf via the Dealing admin position log.

**Columns/Parameters Involved**: `CorrelationID`, `PositionID`, `CompensationCreditID`, `AdminLog*`

**Rules**:
- The conversion is identified in WalletConversionDB by TargetPlatformID=3 (EtoroPosition)
- The AdminPositionLog entry (CompensationReasonID=134) is joined via RequestCorrelationID = AdminPositionRequestID
- PositionID is populated from AdminPositionLog; NULL for 1,456 rows (Other-cycle conversions with no matched position)
- CompensationCreditID links the position opening to the credit transaction in Dealing

### 2.2 ConversionCycle (Binary)

**What**: Unlike the 10-state C2F ConversionCycle, the C2P cycle is a binary Full Cycle / Other check.

**Columns/Parameters Involved**: `ConversionCycle`

**Rules**:
- `Full Cycle` (2,509 rows, 63%): All six checks pass — CryptoAmount IS NOT NULL, EstimatedFiatAmount IS NOT NULL, BlockchainTransactionID IS NOT NULL, ABS(InitialUnits - SentAmount) < 0.000001 (unit fidelity), RequestLastStatusID=1 (Done), ConversionStatusID=3 (Completed)
- `Other` (1,458 rows, 37%): Any check fails — typically missing position match or non-completed conversion status

### 2.3 FactAction Dual-Enrichment

**What**: Two Fact_CustomerAction rows per C2P conversion capture the financial events: a compensation credit (AirDrop) and a position open debit.

**Columns/Parameters Involved**: `FactActionCompensationOccurred`, `FactActionCompensationAmountUSD`, `FactActionPositionOpenOccurred`, `FactActionPositionOpenAmountUSD`, `FactActionPositionOpenInitialUnits`, `IsAirDrop`, `Commission`, `FullCommission`

**Rules**:
- ActionTypeID=36 (compensation credit): The USD credit that funds the position. FactActionCompensationAmountUSD is a positive value.
- ActionTypeID=1 (position open): The position debit. FactActionPositionOpenAmountUSD is negative (debit for opening). IsAirDrop=1 for all C2P position-open rows — positions opened via AdminPositionLog CompensationReasonID=134 (Crypto Transfer) are categorized as AirDrop by the Dealing system.
- Commission and FullCommission come from the ActionTypeID=1 row.

### 2.4 Point-in-Time Customer Snapshot

**What**: Customer attributes (regulation, country, player level, etc.) are joined at the date of the conversion using Fact_SnapshotCustomer + Dim_Range.

**Columns/Parameters Involved**: `RegulationID`, `Regulation`, `CountryID`, `Country`, `PlayerLevelID`, `Club`, `PlayerStatusID`, `IsValidCustomer`, `IsCreditReportValidCB`

**Rules**:
- Join: `Fact_SnapshotCustomer.DateRangeID BETWEEN Dim_Range.FromDateID AND Dim_Range.ToDateID`
- LastModificationDateID is used as the reference date, giving the customer profile at conversion time
- Customer attributes reflect the customer's state AT THE TIME of the conversion, not today

---

## 3. Data Overview

| CorrelationID | TargetPlatformID | ConversionCycle | GCID | Crypto | InstrumentName | CryptoAmount | PositionID | ConversionStatus |
|---|---|---|---|---|---|---|---|---|
| (uuid) | 3 | Full Cycle | 47612115 | BTC | BTC/USD | 0.015000000... | 1234567890 | Completed |
| (uuid) | 3 | Full Cycle | 27328904 | ETH | ETH/USD | 0.500000000... | 1234567891 | Completed |
| (uuid) | 3 | Other | 19612792 | SOL | SOL/USD | 10.000000000... | NULL | Failed |

Key distribution (3,967 rows as of April 2026):
- **TargetPlatformID**: 3=EtoroPosition (3,967) — exclusively C2P rows; no IbanAccount or EtoroPlatform
- **ConversionCycle**: Full Cycle (2,509, 63%), Other (1,458, 37%)
- **PositionID**: NULL for 1,456 rows (Other-cycle), populated for 2,511 rows
- **IsAirDrop**: 1 for all 2,511 rows with position data
- **FiatCurrency**: Always USD (FiatCurrencyID=1) — EtoroPosition conversions exclusively target USD
- **WalletRequestType**: Always "ConversionToPosition" (RequestTypeId=9)
- **CompensationReasonID**: Always 134 (Crypto Transfer) for all rows with position data
- **Data starts**: 2025-12-11 (C2P product launch)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CorrelationID | uniqueidentifier | YES | — | VERIFIED | Distributed tracing correlation ID linking this conversion to its Saga.SagaRuns orchestration entry and all cross-service operations. Used as the deduplication key by InsertConversion. Indexed with Id for lookups. All SPs identify conversions by CorrelationId rather than Id. (Tier 1 — C2F.Conversions) |
| 2 | ConversionID | int | YES | — | VERIFIED | Auto-incrementing surrogate primary key. Referenced by all child tables (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) via ConversionId FK. (Tier 1 — C2F.Conversions) |
| 3 | TargetPlatformID | tinyint | YES | — | VERIFIED | Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target). Determines the downstream routing of fiat proceeds. DWH note: filtered to TargetPlatformID=3 (EtoroPosition) only; no IbanAccount or EtoroPlatform rows in this table. (Tier 1 — C2F.Conversions) |
| 4 | TargetPlatform | varchar(128) | YES | — | VERIFIED | Display name for TargetPlatformID. Always "EtoroPosition" for all rows in this table. Lookup from WalletConversionDB Dictionary.FiatConversionTargets. (Tier 2 — SP_EXW_C2F_E2E) |
| 5 | ConversionCycle | varchar(128) | YES | — | VERIFIED | End-to-end reconciliation status. Values: Full Cycle (2,509 rows, 63%) — all six checks pass (CryptoAmount not null, EstimatedFiatAmount not null, BlockchainTransactionID not null, ABS(InitialUnits - SentAmount) < 0.000001, RequestStatus=Done, ConversionStatus=Completed); Other (1,458 rows, 37%) — any check fails. Simpler than the C2F 10-state cycle; C2P only tests position match fidelity and completion. (Tier 2 — SP_EXW_C2F_E2E) |
| 6 | LastModificationTime | datetime2(7) | YES | — | VERIFIED | Latest event timestamp across all sub-systems: GREATEST of 7 event timestamps including AdminLogRequestOccurred, AdminLogExecutionOccurred, ConversionTime, SentTransactionTime, ConversionStatusTime, RequestTime, and PositionOpenTime. Represents the most recent activity for this conversion row. (Tier 2 — SP_EXW_C2F_E2E) |
| 7 | LastModificationDate | date | YES | — | VERIFIED | Date portion of LastModificationTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 8 | LastModificationDateID | int | YES | — | VERIFIED | Date integer key in YYYYMMDD format derived from LastModificationDate. Used as the reference date for the point-in-time customer snapshot join (Fact_SnapshotCustomer BETWEEN Dim_Range.FromDateID AND ToDateID). (Tier 2 — SP_EXW_C2F_E2E) |
| 9 | GCID | int | YES | — | VERIFIED | Global Customer ID identifying the customer who initiated the conversion. Validated NOT NULL by InsertConversion (raises error if null). Indexed for customer-scoped queries (GetConversionAmounts, GetConversionsUsdSum). (Tier 1 — C2F.Conversions) |
| 10 | RealCID | int | YES | — | CODE-BACKED | Internal CID after deduplication mapping. Sourced from EXW_dbo.EXW_DimUser.RealCID; maps GCID to the canonical customer record. (Tier 2 — SP_EXW_C2F_E2E) |
| 11 | RequestID | bigint | YES | — | VERIFIED | Auto-incrementing primary key and the primary identifier for a request across the entire wallet system. Referenced by Wallet.RequestStatuses.RequestId as FK. Also used as lookup key by numerous stored procedures. (Tier 1 — Wallet.Requests) |
| 12 | RequestTime | datetime2(7) | YES | — | VERIFIED | When the request was created. No default - explicitly set by the calling code. Used for chronological ordering, SLA monitoring, and date-range queries. Indexed descending for recent-request lookups. (Tier 1 — Wallet.Requests) |
| 13 | RequestLastStatusID | tinyint | YES | — | CODE-BACKED | Last-known status ID of the Wallet ConversionToPosition request (RequestTypeId=9). Derived by ROW_NUMBER() OVER (PARTITION BY request Id ORDER BY Timestamp DESC) = 1 from Wallet.RequestStatuses. Values: 1=Done, 2=Error, 7=TransactionVerified. (Tier 2 — SP_EXW_C2F_E2E) |
| 14 | RequestLastStatus | varchar(64) | YES | — | CODE-BACKED | Display name for RequestLastStatusID. Lookup from WalletDB Dictionary.RequestStatuses. Values: Done, Error, TransactionVerified. (Tier 2 — SP_EXW_C2F_E2E) |
| 15 | RequestLastStatusTime | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the last RequestStatuses entry for this ConversionToPosition request. Corresponds to when RequestLastStatusID was set. (Tier 2 — SP_EXW_C2F_E2E) |
| 16 | WalletRequestType | varchar(64) | YES | — | CODE-BACKED | Request type display name. Always "ConversionToPosition" for all rows (RequestTypeId=9 filter applied in SP). Lookup from WalletDB Dictionary.RequestTypes. (Tier 2 — SP_EXW_C2F_E2E) |
| 17 | SentTransactionID | int | YES | — | VERIFIED | Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces. (Tier 1 — Wallet.SentTransactions) |
| 18 | SentWalletID | uniqueidentifier | YES | — | VERIFIED | The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer's wallet. For redemptions, this is the system's omnibus/redeem wallet. (Tier 1 — Wallet.SentTransactions) |
| 19 | SentTransactionTime | datetime2(7) | YES | — | VERIFIED | Timestamp when the transaction was broadcast to the blockchain. NULL only for legacy records. (Tier 1 — Wallet.SentTransactions) |
| 20 | SentBlockchainFee | numeric(36,18) | YES | — | VERIFIED | Network fee paid in the crypto's native units. Recorded after on-chain confirmation. Used for cost analysis, customer billing, and financial reconciliation. (Tier 1 — Wallet.SentTransactions) |
| 21 | FromAddress | varchar(512) | YES | — | CODE-BACKED | Source blockchain address of the customer's wallet at conversion time. Sourced from Wallet.CustomerWalletsView.Address, joined on GCID and CryptoId. Reflects the wallet that sent the crypto. (Tier 2 — SP_EXW_C2F_E2E) |
| 22 | ToAddress | varchar(512) | YES | — | CODE-BACKED | Destination blockchain address where crypto was sent. Sourced from Wallet.SentTransactionOutputs.ToAddress (output destination record). May include chain-specific qualifiers. (Tier 2 — SP_EXW_C2F_E2E) |
| 23 | BlockchainTransactionID | nvarchar(max) | YES | — | VERIFIED | On-chain transaction hash/identifier. Unique across all rows (UNIQUE constraint). Format varies by blockchain: Ethereum "0x" + 64 hex chars, Ripple uppercase hex, etc. Serves as proof of on-chain execution. (Tier 1 — C2F.CryptoTransactions) |
| 24 | BlockchainFee | decimal(36,18) | YES | — | VERIFIED | Network/gas fee charged by the blockchain for processing the transaction. Very small values observed (0.000045 XRP, 6e-8 for ERC-20). Deducted from the transfer, not from the conversion amount. (Tier 1 — C2F.CryptoTransactions) |
| 25 | SentAmount | decimal(36,18) | YES | — | CODE-BACKED | Amount of crypto transferred in the sent transaction. Sourced from Wallet.SentTransactionOutputs.Amount. The Full Cycle check requires ABS(InitialUnits - SentAmount) < 0.000001 for unit reconciliation. (Tier 2 — SP_EXW_C2F_E2E) |
| 26 | SentLastStatusID | int | YES | — | CODE-BACKED | Last-known status ID of the sent blockchain transaction. Derived by ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY Occurred DESC) = 1 from Wallet.SentTransactionStatuses. NULL when no sent transaction exists. (Tier 2 — SP_EXW_C2F_E2E) |
| 27 | SentLastStatus | varchar(64) | YES | — | CODE-BACKED | Display name for SentLastStatusID. Lookup from WalletDB Dictionary.TransactionStatus. NULL when SentTransactionID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 28 | SentLastStatusTime | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the last SentTransactionStatuses entry for this transaction. NULL when SentTransactionID is NULL. (Tier 2 — SP_EXW_C2F_E2E) |
| 29 | WalletTransactionType | varchar(64) | YES | — | CODE-BACKED | Transaction type display name for the blockchain send. Always "ConversionToFiat" (TransactionTypeId=12) in EXW_Dictionary — C2P sends use the same wallet transaction type as C2F. Lookup from EXW_Dictionary.TransactionTypes. (Tier 2 — SP_EXW_C2F_E2E) |
| 30 | EstimatedFiatAmount | decimal(36,18) | YES | — | VERIFIED | Estimated fiat amount the customer will receive, in the target fiat currency (determined by Conversions.FiatId). Calculated as CryptoAmount * CryptoToFiatRate (approximately, with fee adjustments). (Tier 1 — C2F.EstimatedFiatTransactions) |
| 31 | EstimatedUsdAmount | decimal(36,18) | YES | — | VERIFIED | Estimated USD equivalent of the fiat amount. Used as the normalization currency for regulatory limit calculations (GetConversionsUsdSum). When FiatId=1 (USD), equals FiatAmount. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 32 | EstimatedCryptoToUsdRate | decimal(36,18) | YES | — | VERIFIED | Exchange rate from the source crypto asset to USD at conversion creation time. The primary pricing rate. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 33 | EstimatedFiatToUsdRate | decimal(36,18) | YES | — | VERIFIED | Exchange rate from the target fiat currency to USD. When target is USD, this is 1.0. Used to derive the cross-rate: CryptoToFiatRate = CryptoToUsdRate / FiatToUsdRate. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 34 | EstimatedCryptoToFiatRate | decimal(36,18) | YES | — | VERIFIED | Direct exchange rate from source crypto to target fiat. This is the rate shown to the customer. Derived from CryptoToUsdRate / FiatToUsdRate. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 35 | EstimatedTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the estimate was recorded. Matches Conversions.Occurred since both are created in the same transaction. (Tier 1 — C2F.EstimatedFiatTransactions) |
| 36 | CryptoID | int | YES | — | VERIFIED | Identifier of the cryptocurrency this request operates on. Implicit reference to Wallet.CryptoTypes.CryptoID. For conversions, this is the source crypto. Combined with Gcid for per-user per-crypto request lookups. (Tier 1 — Wallet.Requests) |
| 37 | Crypto | varchar(128) | YES | — | CODE-BACKED | Display name for CryptoID. Lookup from EXW_Wallet.CryptoTypes. Values observed: BTC, ETH, SOL, XRP, and others matching the converted asset. (Tier 2 — SP_EXW_C2F_E2E) |
| 38 | FiatCurrencyID | int | YES | — | VERIFIED | Fiat currency identifier (external reference). Identifies which fiat currency the customer receives. Values observed: 1, 2 (likely USD, EUR). DWH note: always 1 (USD) for EtoroPosition path — C2P conversions exclusively target USD. (Tier 1 — C2F.Conversions) |
| 39 | FiatCurrency | varchar(128) | YES | — | CODE-BACKED | Display name for FiatCurrencyID. Always "USD" for all rows in this table (FiatCurrencyID=1 for EtoroPosition). Lookup from EXW_Wallet.FiatTypes. (Tier 2 — SP_EXW_C2F_E2E) |
| 40 | CryptoAmount | decimal(36,18) | YES | — | VERIFIED | Quantity of cryptocurrency being converted. High precision (18 decimals) to handle fractional crypto amounts. This is the gross amount before fees. (Tier 1 — C2F.Conversions) |
| 41 | TotalFeePercentage | decimal(5,2) | YES | — | VERIFIED | Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. Zero fee observed for some EtoroPosition conversions. (Tier 1 — C2F.Conversions) |
| 42 | TotalFeeUSD | decimal(36,18) | YES | — | CODE-BACKED | Fee amount in USD. Computed by SP: CAST(CryptoAmount AS FLOAT) * CAST(CryptoToUsdRate AS FLOAT) / 100 * TotalFeePercentage. Approximation subject to float precision. (Tier 2 — SP_EXW_C2F_E2E) |
| 43 | ConversionTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the conversion was created. Default constraint provides automatic timestamping. Indexed DESC for recency queries. Used by time-windowed queries (GetConversionAmounts, GetConversionsUsdSum) via @FromDateTime filter. (Tier 1 — C2F.Conversions) |
| 44 | CryptoTransactionTime | datetime2(7) | YES | — | VERIFIED | UTC timestamp when the crypto transaction was recorded. Default constraint auto-sets. (Tier 1 — C2F.CryptoTransactions) |
| 45 | ConversionStatusID | int | YES | — | VERIFIED | FK to Dictionary.ConversionToFiatStatuses. Current status in this transition. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status). Included in NC index on ConversionId for covering queries. (Tier 1 — C2F.ConversionStatuses) |
| 46 | ConversionStatus | varchar(256) | YES | — | CODE-BACKED | Display name for ConversionStatusID. Lookup from WalletConversionDB Dictionary.ConversionToFiatStatuses. Values: Pending, Failed, Completed, Rejected. (Tier 2 — SP_EXW_C2F_E2E) |
| 47 | ConversionStatusTime | datetime2(7) | YES | — | CODE-BACKED | UTC timestamp of the most recent ConversionStatuses entry (ORDER BY Occurred DESC, Rn=1). Represents when ConversionStatusID was last set. (Tier 2 — SP_EXW_C2F_E2E) |
| 48 | PositionID | bigint | YES | — | CODE-BACKED | eToro trading position ID opened as a result of this C2P conversion. Sourced from Dealing_staging.etoro_Trade_AdminPositionLog where CompensationReasonID=134, joined via RequestCorrelationID = AdminPositionRequestID. NULL (1,456 rows) for Other-cycle conversions with no matched position. (Tier 2 — SP_EXW_C2F_E2E) |
| 49 | AdminLogAmountUnits | decimal(36,18) | YES | — | CODE-BACKED | Crypto units amount recorded in the admin position log at the time of position opening. From Dealing_staging.etoro_Trade_AdminPositionLog.AmountInUnits. Used in the Full Cycle unit reconciliation check (ABS(InitialUnits - SentAmount) < 0.000001). (Tier 2 — SP_EXW_C2F_E2E) |
| 50 | HedgeServerID | int | YES | — | CODE-BACKED | ID of the hedge server that processed the position open request. From Dealing_staging.etoro_Trade_AdminPositionLog.HedgeServerID. (Tier 2 — SP_EXW_C2F_E2E) |
| 51 | AdminLogRequestOccurred | datetime2(7) | YES | — | CODE-BACKED | Timestamp when the position open was requested by the Dealing system. From Dealing_staging.etoro_Trade_AdminPositionLog.RequestOccurred. One of the 7 timestamps feeding LastModificationTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 52 | AdminLogExecutionOccurred | datetime2(7) | YES | — | CODE-BACKED | Timestamp when the position open was executed by the Dealing system. From Dealing_staging.etoro_Trade_AdminPositionLog.ExecutionOccurred. One of the 7 timestamps feeding LastModificationTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 53 | AdminLogRate | decimal(36,18) | YES | — | CODE-BACKED | Exchange rate (instrument price) at the time of position opening. From Dealing_staging.etoro_Trade_AdminPositionLog.Rate. (Tier 2 — SP_EXW_C2F_E2E) |
| 54 | AdminLogRateTime | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the exchange rate used for position opening. From Dealing_staging.etoro_Trade_AdminPositionLog.RateTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 55 | CompensationCreditID | bigint | YES | — | CODE-BACKED | Credit transaction ID from the admin position log that links the position open to the compensation/crypto-transfer event. From Dealing_staging.etoro_Trade_AdminPositionLog.CompensationCreditID. (Tier 2 — SP_EXW_C2F_E2E) |
| 56 | PositionUSD | decimal(36,18) | YES | — | CODE-BACKED | USD value of the opened position. Sourced from DWH_dbo.Dim_Position.Amount. (Tier 2 — SP_EXW_C2F_E2E) |
| 57 | PositionUnits | decimal(36,18) | YES | — | CODE-BACKED | Decimal units amount of the opened position. Sourced from DWH_dbo.Dim_Position.AmountInUnitsDecimal. (Tier 2 — SP_EXW_C2F_E2E) |
| 58 | PositionInitialUnits | decimal(36,18) | YES | — | CODE-BACKED | Initial units at position open from DWH_dbo.Dim_Position.InitialUnits. Used in reconciliation with AdminLogAmountUnits and SentAmount. (Tier 2 — SP_EXW_C2F_E2E) |
| 59 | PositionInitialAmountCents | decimal(36,18) | YES | — | CODE-BACKED | Initial position value in cents at open time. Sourced from DWH_dbo.Dim_Position.InitialAmountCents. (Tier 2 — SP_EXW_C2F_E2E) |
| 60 | PositionOpenTime | datetime2(7) | YES | — | CODE-BACKED | Timestamp when the trading position was opened. Sourced from DWH_dbo.Dim_Position.OpenOccurred. One of the 7 timestamps feeding LastModificationTime. (Tier 2 — SP_EXW_C2F_E2E) |
| 61 | InstrumentID | int | YES | — | CODE-BACKED | Trading instrument FK. Sourced from Dealing_staging.etoro_Trade_AdminPositionLog or DWH_dbo.Dim_Position. Identifies the instrument (e.g., BTC/USD, SOL/USD) of the opened position. FK to DWH_dbo.Dim_Instrument. (Tier 2 — SP_EXW_C2F_E2E) |
| 62 | InstrumentName | varchar(256) | YES | — | CODE-BACKED | Instrument name lookup from DWH_dbo.Dim_Instrument. Values: BTC/USD, ETH/USD, SOL/USD, XRP/USD, and others — matching the crypto being converted. (Tier 2 — SP_EXW_C2F_E2E) |
| 63 | CompensationReasonID | int | YES | — | CODE-BACKED | Compensation reason FK. Always 134 (Crypto Transfer) for all C2P conversions. From DWH_dbo.Fact_CustomerAction.CompensationReasonID for ActionTypeID=36 rows. (Tier 2 — SP_EXW_C2F_E2E) |
| 64 | CompensationReason | varchar(256) | YES | — | CODE-BACKED | Compensation reason name. Always "Crypto Transfer" (CompensationReasonID=134) for all rows in this table. Lookup from DWH_dbo.Dim_CompensationReason. (Tier 2 — SP_EXW_C2F_E2E) |
| 65 | FactActionCompensationOccurred | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the compensation credit event (ActionTypeID=36 in Fact_CustomerAction). Represents when the USD credit was applied to fund the position. (Tier 2 — SP_EXW_C2F_E2E) |
| 66 | FactActionCompensationAmountUSD | decimal(36,18) | YES | — | CODE-BACKED | USD amount of the compensation credit (ActionTypeID=36). Positive value representing the credit applied to fund the position open. (Tier 2 — SP_EXW_C2F_E2E) |
| 67 | FactActionPositionOpenOccurred | datetime2(7) | YES | — | CODE-BACKED | Timestamp of the position open debit event (ActionTypeID=1 in Fact_CustomerAction). Represents when the trading position was debited from the customer's balance. (Tier 2 — SP_EXW_C2F_E2E) |
| 68 | FactActionPositionOpenAmountUSD | decimal(36,18) | YES | — | CODE-BACKED | USD amount of the position open action (ActionTypeID=1). Negative value (debit) representing the cost of opening the position. (Tier 2 — SP_EXW_C2F_E2E) |
| 69 | FactActionPositionOpenInitialUnits | decimal(36,18) | YES | — | CODE-BACKED | Initial units for the position open action (ActionTypeID=1) from Fact_CustomerAction.InitialUnits. (Tier 2 — SP_EXW_C2F_E2E) |
| 70 | IsAirDrop | tinyint | YES | — | CODE-BACKED | Flag from Fact_CustomerAction for the position open action (ActionTypeID=1). Always 1 for C2P positions — positions opened via AdminPositionLog CompensationReasonID=134 (Crypto Transfer) are classified as AirDrop by the Dealing system. (Tier 2 — SP_EXW_C2F_E2E) |
| 71 | Commission | decimal(36,18) | YES | — | CODE-BACKED | Commission charged on the position open, from Fact_CustomerAction.Commission where ActionTypeID=1. (Tier 2 — SP_EXW_C2F_E2E) |
| 72 | FullCommission | decimal(36,18) | YES | — | CODE-BACKED | Full (gross) commission on the position open, from Fact_CustomerAction.FullCommission where ActionTypeID=1. (Tier 2 — SP_EXW_C2F_E2E) |
| 73 | IsTestAccount | tinyint | YES | — | CODE-BACKED | Flag indicating whether this is an internal test/QA account. Sourced from EXW_dbo.EXW_DimUser.IsTestAccount. (Tier 2 — SP_EXW_C2F_E2E) |
| 74 | RegulationID | int | YES | — | CODE-BACKED | Regulatory jurisdiction ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join on LastModificationDateID. (Tier 2 — SP_EXW_C2F_E2E) |
| 75 | Regulation | varchar(256) | YES | — | CODE-BACKED | Regulation name lookup from DWH_dbo.Dim_Regulation. Values observed: FCA, ASIC & GAML, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 76 | CountryID | int | YES | — | CODE-BACKED | Customer's country ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join. (Tier 2 — SP_EXW_C2F_E2E) |
| 77 | Country | varchar(256) | YES | — | CODE-BACKED | Country name lookup from DWH_dbo.Dim_Country. (Tier 2 — SP_EXW_C2F_E2E) |
| 78 | CustomerRegionID | int | YES | — | CODE-BACKED | US state/region ID for US customers only. Computed: Fact_SnapshotCustomer.RegionID when CountryID=219, NULL otherwise. (Tier 2 — SP_EXW_C2F_E2E) |
| 79 | State | varchar(256) | YES | — | CODE-BACKED | US state name for US customers only. Lookup from DWH_dbo.Dim_State_and_Province when CountryID=219, NULL otherwise. (Tier 2 — SP_EXW_C2F_E2E) |
| 80 | IsValidCustomer | tinyint | YES | — | CODE-BACKED | Customer validity flag at conversion time from Fact_SnapshotCustomer. (Tier 2 — SP_EXW_C2F_E2E) |
| 81 | IsCreditReportValidCB | tinyint | YES | — | CODE-BACKED | Credit bureau report validity flag at conversion time from Fact_SnapshotCustomer. (Tier 2 — SP_EXW_C2F_E2E) |
| 82 | PlayerLevelID | int | YES | — | CODE-BACKED | Customer club tier ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_EXW_C2F_E2E) |
| 83 | Club | varchar(256) | YES | — | CODE-BACKED | Club tier name lookup from DWH_dbo.Dim_PlayerLevel. Values observed: Bronze, Gold, Silver, Platinum, Diamond. (Tier 2 — SP_EXW_C2F_E2E) |
| 84 | PlayerStatusID | int | YES | — | CODE-BACKED | Customer activity status ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_EXW_C2F_E2E) |
| 85 | PlayerStatus | varchar(256) | YES | — | CODE-BACKED | Player status name lookup from DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_EXW_C2F_E2E) |
| 86 | WalletEntity | varchar(256) | YES | — | CODE-BACKED | eToro legal entity responsible for the customer's wallet. Sourced from EXW_dbo.EXW_WalletEntity joined on GCID and LastModificationDateID. Values: eToroUK, eToroAUS, eToroEU, and others. (Tier 2 — SP_EXW_C2F_E2E) |
| 87 | AccountManager | varchar(256) | YES | — | CODE-BACKED | Full name of the customer's account manager. Computed by SP as DWH_dbo.Dim_Manager.FirstName + ' ' + LastName, joined via Fact_SnapshotCustomer.AccountManagerID. (Tier 2 — SP_EXW_C2F_E2E) |
| 88 | LabelID | int | YES | — | CODE-BACKED | Customer label ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer. FK to DWH_dbo.Dim_Label. (Tier 2 — SP_EXW_C2F_E2E) |
| 89 | Lable | varchar(256) | YES | — | CODE-BACKED | Label name lookup from DWH_dbo.Dim_Label. Note: column name is "Lable" (typo for "Label") — matches the production DDL. (Tier 2 — SP_EXW_C2F_E2E) |
| 90 | UpdateDate | datetime2(7) | YES | — | CODE-BACKED | Timestamp of when this row was loaded by SP_EXW_C2F_E2E. Batch watermark; reflects the SP execution time, not the conversion time. (Tier 2 — SP_EXW_C2F_E2E) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | Implicit | Customer identity; GCID is the join key |
| TargetPlatformID | WalletConversionDB.Dictionary.FiatConversionTargets | Upstream FK | Fiat destination type (denormalized as TargetPlatform) |
| CryptoID | EXW_Wallet.CryptoTypes | Implicit | Crypto asset (denormalized as Crypto) |
| FiatCurrencyID | EXW_Wallet.FiatTypes | Implicit | Fiat currency (denormalized as FiatCurrency; always USD) |
| ConversionStatusID | WalletConversionDB.Dictionary.ConversionToFiatStatuses | Upstream FK | Conversion lifecycle status (denormalized as ConversionStatus) |
| RequestLastStatusID | WalletDB.Dictionary.RequestStatuses | Upstream FK | Wallet request status (denormalized as RequestLastStatus) |
| SentLastStatusID | WalletDB.Dictionary.TransactionStatus | Upstream FK | Sent transaction status (denormalized as SentLastStatus) |
| PositionID | DWH_dbo.Dim_Position | Implicit | Opened trading position |
| InstrumentID | DWH_dbo.Dim_Instrument | Implicit | Trading instrument (denormalized as InstrumentName) |
| CompensationReasonID | DWH_dbo.Dim_CompensationReason | Implicit | Always 134 = Crypto Transfer (denormalized as CompensationReason) |
| RegulationID | DWH_dbo.Dim_Regulation | Implicit | Regulatory jurisdiction (denormalized as Regulation) |
| CountryID | DWH_dbo.Dim_Country | Implicit | Customer country (denormalized as Country) |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Implicit | Club tier (denormalized as Club) |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Implicit | Player status (denormalized as PlayerStatus) |
| LabelID | DWH_dbo.Dim_Label | Implicit | Customer label (denormalized as Lable [typo]) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| — | — | — | No documented downstream objects as of April 2026 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
EXW_dbo.EXW_C2P_E2E (depth=4)
├── WalletConversionDB.C2F (CopyFromLake: Conversions, CryptoTransactions, EstimatedFiatTransactions, ConversionStatuses)
├── WalletDB.Wallet (EXW_Wallet views: SentTransactions, Requests, RequestStatuses, SentTransactionOutputs, SentTransactionStatuses, CustomerWalletsView)
├── Dealing_staging.etoro_Trade_AdminPositionLog (CompensationReasonID=134)
├── DWH_dbo.Dim_Position (joined via PositionID from admin log)
├── DWH_dbo.Fact_CustomerAction (ActionTypeID=36 compensation, ActionTypeID=1 position open)
├── DWH_dbo.Fact_SnapshotCustomer → DWH_dbo.Dim_Range (point-in-time join)
├── DWH_dbo.Dim_Instrument, Dim_CompensationReason, Dim_ActionType, Dim_Country, Dim_Regulation, Dim_PlayerLevel, Dim_PlayerStatus, Dim_Manager, Dim_Label, Dim_State_and_Province
├── EXW_dbo.EXW_WalletEntity
└── EXW_dbo.EXW_DimUser
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| CopyFromLake.WalletConversionDB_C2F_Conversions | External Table | Primary C2F conversion records (filtered to TargetPlatformID=3) |
| CopyFromLake.WalletConversionDB_C2F_CryptoTransactions | External Table | Blockchain transaction details |
| CopyFromLake.WalletConversionDB_C2F_EstimatedFiatTransactions | External Table | Pre-execution rate quotes |
| CopyFromLake.WalletConversionDB_C2F_ConversionStatuses | External Table | Conversion lifecycle status |
| EXW_Wallet.SentTransactions | External Table | Blockchain sent transaction records (TransactionTypeId=12) |
| EXW_Wallet.SentTransactionOutputs | External Table | Output amounts and destination addresses |
| EXW_Wallet.SentTransactionStatuses | External Table | Sent transaction lifecycle status |
| EXW_Wallet.Requests | External Table | Wallet ConversionToPosition requests (RequestTypeId=9) |
| EXW_Wallet.RequestStatuses | External Table | Request lifecycle status |
| EXW_Wallet.CustomerWalletsView | View | Customer wallet addresses (FromAddress) |
| EXW_Dictionary.TransactionTypes | External Table | WalletTransactionType lookup |
| Dealing_staging.etoro_Trade_AdminPositionLog | Table | Position open records (CompensationReasonID=134) |
| DWH_dbo.Dim_Position | Table | Position USD/units values |
| DWH_dbo.Fact_CustomerAction | Table | ActionTypeID=36 (compensation) and ActionTypeID=1 (position open) events |
| DWH_dbo.Fact_SnapshotCustomer | Table | Point-in-time customer snapshot |
| DWH_dbo.Dim_Range | Table | Date range for point-in-time join |
| DWH_dbo.Dim_Instrument | Table | InstrumentName lookup |
| DWH_dbo.Dim_CompensationReason | Table | CompensationReason lookup |
| DWH_dbo.Dim_Country | Table | Country lookup |
| DWH_dbo.Dim_Regulation | Table | Regulation lookup |
| DWH_dbo.Dim_PlayerLevel | Table | Club lookup |
| DWH_dbo.Dim_PlayerStatus | Table | PlayerStatus lookup |
| DWH_dbo.Dim_Manager | Table | AccountManager name |
| DWH_dbo.Dim_Label | Table | Lable lookup |
| DWH_dbo.Dim_State_and_Province | Table | State lookup (US only) |
| EXW_dbo.EXW_WalletEntity | Table | eToro legal entity per customer/date |
| EXW_dbo.EXW_DimUser | Table | RealCID and IsTestAccount lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| — | — | No documented downstream objects as of April 2026 |

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

### 7.3 ETL Schedule

SP_EXW_C2F_E2E runs on a scheduled basis (daily), performing a full DELETE + INSERT for EXW_C2P_E2E in its second half (after writing EXW_C2F_E2E). No incremental loading — each run rebuilds the full set of C2P conversions from source.

---

## 8. Sample Queries

### 8.1 Full cycle summary by crypto and instrument
```sql
SELECT Crypto, InstrumentName, COUNT(1) cnt,
    SUM(EstimatedUsdAmount) total_usd
FROM EXW_dbo.EXW_C2P_E2E
WHERE ConversionCycle = 'Full Cycle'
GROUP BY Crypto, InstrumentName
ORDER BY total_usd DESC
```

### 8.2 Unit reconciliation check
```sql
SELECT CorrelationID, Crypto, CryptoAmount,
    SentAmount, PositionInitialUnits, AdminLogAmountUnits,
    ABS(CAST(PositionInitialUnits AS FLOAT) - CAST(SentAmount AS FLOAT)) AS UnitDiff
FROM EXW_dbo.EXW_C2P_E2E
WHERE PositionID IS NOT NULL
ORDER BY UnitDiff DESC
```

### 8.3 Other-cycle conversions needing investigation
```sql
SELECT CorrelationID, GCID, Crypto, CryptoAmount,
    ConversionCycle, ConversionStatus, ConversionStatusTime,
    RequestLastStatus, PositionID
FROM EXW_dbo.EXW_C2P_E2E
WHERE ConversionCycle = 'Other'
ORDER BY ConversionStatusTime DESC
```

### 8.4 C2P volume by regulation and date
```sql
SELECT RegulationID, Regulation, CAST(ConversionTime AS DATE) ConversionDate,
    COUNT(1) cnt, SUM(EstimatedUsdAmount) total_usd
FROM EXW_dbo.EXW_C2P_E2E
WHERE ConversionStatusID = 3
GROUP BY RegulationID, Regulation, CAST(ConversionTime AS DATE)
ORDER BY ConversionDate DESC, total_usd DESC
```

---

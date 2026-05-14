# eMoney_dbo.eMoney_Dim_Transaction

> One row per eToro Money fiat transaction at its **latest status** (current-state snapshot). Consolidates transaction identity, customer DWH enrichment at transaction date, FiatDwhDB status and provider data, and USD approximation from FiatDwhDB and DWH_dbo sources. 28,538,711 rows; transactions created 2020-11-10 to 2026-04-20; refreshed daily via DELETE + INSERT (Step 10 of SP_eMoney_DimFact_Transaction).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dimension) |
| **Production Source** | FiatDwhDB (eToro Money fiat platform DWH) via SP_eMoney_DimFact_Transaction (Step 10) |
| **Refresh** | Daily DELETE + INSERT (Step 10 of SP_eMoney_DimFact_Transaction; shared SP with eMoney_Fact_Transaction_Status) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC); NCI (CurrencyBalanceID, ProviderCurrencyBalanceID, ProviderTransactionID, TransactionID, TxStatusModificationDateID) |
| **Row Count** | 28,538,711 (sampled 2026-04-20) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dim_Transaction` is the current-state transaction dimension for eToro Money (eTM). Each row represents one fiat transaction at its **most recent status event** — i.e., only the latest entry from `FiatTransactionsStatuses` per transaction (`RNDesc=1`, ordered by `TransactionOccured DESC`). This makes it a point-in-time snapshot suitable for standard transaction analytics.

The table is populated by **Step 10** of `SP_eMoney_DimFact_Transaction`, which also populates `eMoney_Fact_Transaction_Status` in **Step 11**. The two tables share an identical 11-step pipeline (`#leveled_txs` staging CTE containing all status events), diverging only at the final INSERT step:
- `eMoney_Dim_Transaction` (Step 10): inserts from `#leveled_txs WHERE RNDesc=1` — current state only
- `eMoney_Fact_Transaction_Status` (Step 11): inserts from `#leveled_txs` without filter — all status events

The table consolidates four data layers:
1. **FiatDwhDB transaction identity** — core transaction fields from `FiatTransactions`, latest status fields from `FiatTransactionsStatuses`, and provider data from `TransactionsProvidersMapping`
2. **DWH customer enrichment at transaction date** — club, regulation, country, and player status from `DWH_dbo.Fact_SnapshotCustomer` at `TxLocalDateID` (snapshot-in-time, not current values)
3. **USD approximation** — `HolderAmount × mid-rate` using `DWH_dbo.Fact_CurrencyPriceWithSplit` at `TxLocalDate`
4. **Account dimension snapshot** — `IsValidETM`, `AccountProgramID`, `AccountSubProgramID`, and provider card/balance IDs from `eMoney_Dim_Account` at ETL run time (not at transaction date)

**Transaction type distribution** (2026-04-20): Transfer=8.16M (28.6%), TransferReceived=6.89M (24.2%), PaymentReceived=5.85M (20.5%), Payment=4.31M (15.1%), Contactless=1.77M (6.2%), OnlinePayment=0.92M (3.2%), other types <2%.

**Transaction status distribution**: Settled=98.3%, Authorized=0.8%, Failed=0.5%, other <0.4%.

**Key difference from eMoney_Fact_Transaction_Status**: Column 49 is `IsTxSettled` here (CASE WHEN TxStatusID=2 THEN 1 ELSE 0) vs `FiatTransactionStatusRunningID` in the Fact table. The Fact table has no `IsTxSettled` flag but retains the full status event history.

---

## 2. Business Logic

### 2.1 Latest-Status-Per-Transaction Grain

**What**: Each `TransactionID` appears exactly once — representing the transaction's current/latest status.

**Columns Involved**: `TransactionID`, `TxStatusID`, `TxStatus`, `IsTxSettled`, `CountStatusChanges`, `TxStatusModificationTime`

**Rules**:
- `RNDesc = ROW_NUMBER() PARTITION BY TransactionId ORDER BY TransactionOccured DESC` — rank 1 = most recent status event
- `eMoney_Dim_Transaction` inserts only rows where `RNDesc=1`
- `CountStatusChanges = MAX(RNDesc)` per `TransactionID` from `#tx_status` — total count of status events for that transaction
- `IsTxSettled = CASE WHEN TxStatusID = 2 THEN 1 ELSE 0` (TxStatusID 2 = Settled)
- For the full status history of a transaction, use `eMoney_Fact_Transaction_Status` instead

### 2.2 Customer Snapshot at Transaction Date vs Current

**What**: Customer attributes (club, regulation, country, player status) in this table reflect the **customer's state at the transaction local date** — not current values.

**Columns Involved**: `ClubIDTxDate`, `ClubTxDate`, `RegulationIDTxDate`, `RegulationTxDate`, `CountryIDTxDate`, `CountryTxDate`, `PlayerStatusIDTxDate`, `PlayerStatusTxDate`, `IsValidCustomer`

**Rules**:
- Sourced from `DWH_dbo.Fact_SnapshotCustomer` joined at `TxLocalDateID` range (Step 08 of SP)
- `IsValidCustomer` is also snapshot-in-time (the customer's valid flag on the transaction date)
- `AccountProgramID`, `AccountSubProgramID`, and `IsValidETM` reflect **current values** (from `eMoney_Dim_Account` at ETL run time, NOT at transaction date)
- This temporal mismatch must be understood when combining these columns in analytics

### 2.3 USD Approximation Logic

**What**: `USDAmountApprox` and `USDRateApprox` provide a USD-equivalent estimate for each transaction.

**Columns Involved**: `HolderAmount`, `HolderCurrencyISO`, `USDAmountApprox`, `USDRateApprox`, `AccumulatedUSDAmountApprox`

**Rules**:
- USD rate sourced from `DWH_dbo.Fact_CurrencyPriceWithSplit` at `TxLocalDate` using mid-rate `(Ask+Bid)/2`
- Currency mapped to eToro instrument via `eMoney_Currency_Instrument_Mapping_ISO` (buy-side) with fallback to sell-side
- `USDAmountApprox = ROUND(HolderAmount × rate, 2)` or inverse depending on whether currency is base or quote
- DKK has no matching instrument in `Fact_CurrencyPriceWithSplit` → `USDAmountApprox` and `USDRateApprox` are NULL for DKK transactions (fixed 2025-12-24 by Shachar)
- `AccumulatedUSDAmountApprox` follows the same logic applied to `AccumulatedAmount`

### 2.4 IsTxSettled Flag

**What**: Boolean indicating whether the transaction's current status is Settled (the terminal successful state).

**Columns Involved**: `IsTxSettled`, `TxStatusID`

**Rules**:
- `IsTxSettled = CASE WHEN TxStatusID = 2 THEN 1 ELSE 0`
- 98.3% of rows have `IsTxSettled=1` (Settled is the dominant terminal state)
- This flag does NOT exist in `eMoney_Fact_Transaction_Status` — use it here for settled-transaction filters
- Use `IsTxStatusCBRelevant` for chargeback-relevant transactions (Settled/Rejected/Returned AND not authorization types 12/13)

### 2.5 Transaction Type and Category

**What**: Transactions are classified along two dimensions: `TxTypeID` (the nature of the transaction) and `TxClientBalanceCategory` (the balance impact category for client-facing reporting).

**Columns Involved**: `TxTypeID`, `TxType`, `TxTypeCategory`, `TxClientBalanceCategory`, `TxCategoryID`, `TxCategory`

**Rules**:
- `TxTypeCategory` CASE: TxTypeID 1-4 and 13 = Card; 5-8 = IBAN; else = Other
- `TxClientBalanceCategory` CASE: 14 values mapped to 9 category labels (e.g., Payments, Refunds, Transfers In/Out, Cash Withdrawals, Fees, DirectDebit, CryptoToFiat)
- `TxCategoryID` passthrough from `FiatTransactions.TransactionCategory`: 1=CardTransaction, 2=BankingTransaction, 3=TransferTransaction, 4=BalanceAdjustmentTransaction

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is distributed on `HASH(CID)`. Most analytics joins are CID-based (joining to `eMoney_Dim_Account` or trading-side DWH tables), so hash collocation minimizes data movement.

`CLUSTERED INDEX(CID ASC)` means row groups are sorted by CID — segment elimination is effective for `WHERE CID = N` predicates but NOT for date-range predicates. For date-range analytics, use `TxStatusModificationDateID` (has NCI) or `TxCreatedDateID`/`TxLocalDateID`.

The five NCIs:
- `CurrencyBalanceID` — balance-level transaction lookups
- `ProviderCurrencyBalanceID` — provider reconciliation joins
- `ProviderTransactionID` — provider-side transaction ID lookups
- `TransactionID` — direct transaction key lookups
- `TxStatusModificationDateID` — date-range queries on status modification date

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Settled eTM transactions this month | `WHERE IsTxSettled=1 AND TxStatusModificationDateID BETWEEN ... AND ...` |
| Monthly transfer volume by entity | JOIN `eMoney_Dim_Account` ON CID WHERE TxTypeCategory='IBAN' GROUP BY Entity, TxLocalDate |
| Chargeback-relevant transactions | `WHERE IsTxStatusCBRelevant=1` |
| MoneyOut vs MoneyIn by TxType | GROUP BY MoneyMoveDirection, TxType WHERE IsTxSettled=1 |
| USD volume by regulation at tx date | GROUP BY RegulationIDTxDate, RegulationTxDate, SUM(USDAmountApprox) |
| DKK transaction count (no USD approx) | WHERE HolderCurrencyISO='208' AND USDAmountApprox IS NULL |
| Transaction status lifecycle | Use `eMoney_Fact_Transaction_Status` instead — all events |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | ON dt.CID = da.CID AND da.GCID_Unique_Count=1 | Current account attributes |
| eMoney_dbo.eMoney_Fact_Transaction_Status | ON dt.TransactionID = fts.TransactionID | Full status event history |
| DWH_dbo.Dim_Customer | ON dt.CID = dc.RealCID | Trading platform customer profile |
| DWH_dbo.Dim_Regulation | ON dt.RegulationIDTxDate = r.DWHRegulationID | Regulation name at tx date |
| DWH_dbo.Dim_Country | ON dt.CountryIDTxDate = c.CountryID | Country name at tx date |

### 3.4 Gotchas

- **USDAmountApprox NULL for DKK**: ISO numeric 208 (DKK) has no Fact_CurrencyPriceWithSplit instrument; USD approximation fields are NULL for all DKK transactions.
- **Customer snapshot vs current**: `ClubIDTxDate`, `RegulationIDTxDate`, `CountryIDTxDate`, `PlayerStatusIDTxDate` are at the transaction date; `AccountProgramID`, `IsValidETM` are current (at ETL run time). Do not mix temporal contexts.
- **PaymentSchemaTypeID edge cases**: IDs 8 and 10 have no matching dictionary name (NULL `PaymentSchemaType`). Also some rows have NULL `PaymentSchemaTypeID`.
- **ProviderTransactionID is float**: DDL type is `float` (not int/bigint); avoid exact equality predicates — use `CAST AS BIGINT` or `ROUND` for join conditions.
- **UpdateDate ≠ transaction date**: `UpdateDate = GETDATE()` at INSERT time; it reflects the ETL run date, not any transaction event time.
- **SourceCugTransactionID**: Added 2025-09-08 (Inessa Ovadia). NULL for transactions created before this feature was deployed.
- **TxLabel / PaymentReference / MoneyCorrelationID / TXStatusCorrelationID**: nvarchar(300)/varchar(2000) — large PII-sensitive fields; avoid selecting without need.
- **IsTxStatusCBRelevant**: Only meaningful for chargeback analysis; uses TxStatusID IN (2,3,4) AND AuthorizationTypeID NOT IN (12,13) — both columns required together.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (FiatDwhDB or DWH_dbo) |
| Tier 2 | Description written from ETL SP code analysis (SP_eMoney_DimFact_Transaction) |
| Tier 3 | Description inferred from column name and surrounding context |
| Tier 4 | Best available — limited evidence |
| Tier 5 | Name only — no description available |

### 4.1 Transaction & Account Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TransactionID | int | YES | Surrogate key for the fiat transaction from FiatDwhDB.dbo.FiatTransactions.Id. Each transaction appears exactly once in this table (latest status only). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 2 | AccountID | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. Passthrough from FiatTransactions.AccountId → FK to FiatAccount.Id. (Tier 1 — dbo.FiatAccount) |
| 3 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. Passthrough via eMoney_Dim_Account snapshot (Step 01). (Tier 1 — dbo.FiatAccount) |
| 4 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. Passthrough via eMoney_Dim_Account snapshot. (Tier 1 — Customer.CustomerStatic) |
| 5 | CardID | int | YES | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. FK from FiatTransactions.CardId. NULL for non-card transactions. (Tier 1 — dbo.FiatCards) |
| 6 | ProviderCardID | int | YES | Provider-side card identifier from CardsProvidersMapping, sourced from eMoney_Dim_Account snapshot (RN_Card_Desc=1 join). NULL for non-card transactions or accounts without a provider card mapping. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 7 | CurrencyBalanceID | int | YES | Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. FK from FiatTransactions.CurrencyBalanceId. (Tier 1 — dbo.FiatCurrencyBalances) |
| 8 | ProviderCurrencyBalanceID | int | YES | Provider-side currency balance identifier from CurrencyBalancesProvidersMapping, sourced from eMoney_Dim_Account snapshot (RN_CurrencyBalance_Desc=1 join). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 9 | ExternalBankAccountID | int | YES | Auto-incrementing surrogate primary key for the external bank account record. FK from FiatTransactions.ExternalBankAccountId → dbo.FiatBankAccount.Id. NULL for non-bank-transfer transactions. (Tier 1 — dbo.FiatBankAccount) |

### 4.2 Transaction Type & Category

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 10 | TxTypeID | int | YES | Transaction type identifier. 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat (15=CryptoToFiat via dictionary). Passthrough from FiatTransactions.TransactionTypeId. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 11 | TxType | varchar(50) | YES | Transaction type display name for TxTypeID, resolved from External_FiatDwhDB_Dictionary_TransactionTypes.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 12 | TxTypeCategory | varchar(50) | YES | Grouped transaction type bucket: Card (TxTypeID 1-4, 13), IBAN (TxTypeID 5-8), Other (all other TxTypeIDs). ETL CASE expression in Step 03. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 13 | TxClientBalanceCategory | varchar(50) | YES | Client-facing balance impact category. ETL CASE maps all 14 TxTypeID values to one of 9 labels (e.g., Payments, Refunds, TransferIn, TransferOut, CashWithdrawal, Fee, DirectDebit, CryptoToFiat, Other). Step 03. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 14 | MerchantID | int | YES | Merchant identifier from FiatTransactions.MerchantId. Populated for card POS and online transactions; NULL for bank transfers and internal transactions. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.3 Transaction Dates

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 15 | TxCreatedDate | date | YES | Date on which the transaction record was created in FiatDwhDB. DWH-derived: CAST(FiatTransactions.Created AS DATE). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 16 | TxCreatedDateID | int | YES | YYYYMMDD integer date key for TxCreatedDate. DWH-derived: CONVERT(VARCHAR(8), FiatTransactions.Created, 112). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 17 | TxLabel | nvarchar(300) | YES | Free-text label from FiatTransactions.Label. Contains merchant names, IBAN references, or internal notes depending on transaction type. May contain PII. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 18 | TxLocalTime | datetime | YES | Local transaction timestamp from FiatTransactions.TransactionLocalTime. The authoritative event time for this transaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 19 | TxLocalDate | date | YES | Date portion of TxLocalTime. DWH-derived: CAST(TransactionLocalTime AS DATE). Used as the reference date for customer snapshots (Step 08) and USD approximation (Step 06). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 20 | TxLocalDateID | int | YES | YYYYMMDD integer date key for TxLocalDate. DWH-derived: CONVERT(VARCHAR(8), TransactionLocalTime, 112). (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.4 Transaction Geography

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 21 | TxLocalCountryNumericISO | varchar(50) | YES | ISO 3166-1 numeric country code for the country where the transaction occurred. Passthrough from FiatTransactions.TransactionCountryIso. NULL for non-card or non-localized transactions. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 22 | TxLocalCountryNameISO | varchar(200) | YES | Country display name for TxLocalCountryNumericISO, resolved via eMoney_Country_Codes_Mapping_ISO bridge to DWH_dbo.Dim_Country.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.5 Transaction References

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 23 | ReferenceNumber | nvarchar(300) | YES | External payment reference from FiatTransactions.ReferenceNumber. Populated for IBAN-based transactions (Faster Payments, SEPA). May contain PII. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 24 | TxCategoryID | int | YES | Transaction category from FiatTransactions.TransactionCategory. 1=CardTransaction, 2=BankingTransaction, 3=TransferTransaction, 4=BalanceAdjustmentTransaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 25 | TxCategory | varchar(50) | YES | Transaction category display name for TxCategoryID, resolved from External_FiatDwhDB_Dictionary_TransactionCategories.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 26 | PaymentSchemaTypeID | int | YES | Payment scheme identifier. 0=Unknown, 1=Transfer, 2=FasterPayments, 3=Chaps, 4=Bacs, 5=SEPAstandart (note: source typo preserved), 6=SEPAinstantTransfer. IDs 8 and 10 exist in data but have no dictionary name (NULL PaymentSchemaType). Also NULL for some transactions. Passthrough from FiatTransactions.PaymentSchemeId. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 27 | PaymentSchemaType | varchar(50) | YES | Payment scheme display name for PaymentSchemaTypeID, resolved from External_FiatDwhDB_Dictionary_PaymentSchemaType.Name. NULL for unknown/unmapped schemes. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 28 | PaymentReference | nvarchar(300) | YES | Payment-specific reference from FiatTransactions.PaymentReference. Bank-side reference for SEPA/Faster Payments. May contain PII. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 29 | MoneyCorrelationID | varchar(2000) | YES | Correlation ID linking this transaction to related money movements. CAST(FiatTransactions.MoneyCorrelationId AS VARCHAR(2000)). Used for cross-transaction tracing. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.6 Provider

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 30 | ProviderID | int | YES | Payment provider identifier from TransactionsProvidersMapping.ProviderId (latest mapping, RN_Desc=1 by TransactionId). Identifies which payment processor handled this transaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 31 | ProviderDesc | varchar(50) | YES | Provider display name for ProviderID, resolved from External_FiatDwhDB_Dictionary_Providers.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 32 | ProviderTransactionID | float | YES | Provider-side transaction identifier from TransactionsProvidersMapping.TransactionProviderId (latest mapping, RN_Desc=1). Used for reconciliation with provider records. Type is float in DDL — cast to BIGINT for equality predicates. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.7 Account Program (Current)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 33 | AccountProgramID | int | YES | Account program type: 0=Unknown, 1=card (default), 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). DWH note: current program at ETL run time, sourced from eMoney_Dim_Account snapshot (not at transaction date). (Tier 1 — dbo.FiatAccount) |
| 34 | AccountProgram | varchar(50) | YES | Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 35 | AccountSubProgramID | int | YES | Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: current sub-program at ETL run time, sourced from eMoney_Dim_Account snapshot (not at transaction date). (Tier 1 — dbo.FiatAccount) |
| 36 | AccountSubProgram | varchar(50) | YES | Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.8 Validity Flags (Current)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 37 | IsValidETM | int | YES | eToro Money validity flag (current at ETL run time from eMoney_Dim_Account snapshot). 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. Standard filter for eTM production analytics. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 38 | IsValidCustomer | int | YES | DWH-computed validity flag at TxLocalDate (from Fact_SnapshotCustomer snapshot, Step 08). 1 when not Internal, not label 30/26, and not CountryID=250 at the time of the transaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.9 Customer Snapshot at Transaction Date

*Columns 39–46 reflect the customer's DWH attributes at `TxLocalDate`, not current values.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 39 | ClubIDTxDate | int | YES | PlayerLevelID from DWH_dbo.Fact_SnapshotCustomer at TxLocalDateID range. Represents the customer's club at the time of the transaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 40 | ClubTxDate | varchar(50) | YES | Club display name for ClubIDTxDate, resolved from DWH_dbo.Dim_PlayerLevel.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 41 | RegulationIDTxDate | int | YES | RegulationID from DWH_dbo.Fact_SnapshotCustomer at TxLocalDateID range. Represents the customer's regulatory entity at the time of the transaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 42 | RegulationTxDate | varchar(50) | YES | Regulation display name for RegulationIDTxDate, resolved from DWH_dbo.Dim_Regulation.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 43 | CountryIDTxDate | int | YES | CountryID from DWH_dbo.Fact_SnapshotCustomer at TxLocalDateID range. Represents the customer's country at the time of the transaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 44 | CountryTxDate | varchar(50) | YES | Country display name for CountryIDTxDate, resolved from DWH_dbo.Dim_Country.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 45 | PlayerStatusIDTxDate | int | YES | PlayerStatusID from DWH_dbo.Fact_SnapshotCustomer at TxLocalDateID range. Represents the customer's compliance/trading status at the time of the transaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 46 | PlayerStatusTxDate | varchar(50) | YES | Player status display name for PlayerStatusIDTxDate, resolved from DWH_dbo.Dim_PlayerStatus.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.10 Transaction Status (Latest)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 47 | IsTxSettled | int | YES | 1 if the current transaction status is Settled (TxStatusID=2), else 0. ETL CASE expression. KEY DIFFERENCE from eMoney_Fact_Transaction_Status (which has FiatTransactionStatusRunningID at this position instead). 98.3% of transactions are Settled. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 48 | TxStatusID | int | YES | Current transaction lifecycle status (latest event, RNDesc=1). 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired, 6=Reserved, 7=Cancelled. Passthrough from FiatTransactionsStatuses.TransactionStatusId. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 49 | TxStatus | varchar(50) | YES | Transaction status display name for TxStatusID, resolved from External_FiatDwhDB_Dictionary_TransactionStatuses.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 50 | CountStatusChanges | int | YES | Total number of status events for this transaction (MAX(RNDesc) from #tx_status per TransactionID). 1 = single-status transaction; >1 = went through multiple states before reaching current status. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 51 | AuthorizationTypeID | int | YES | Authorization method used in the latest status event from FiatTransactionsStatuses. 13 possible values (e.g., PIN, Contactless, Online, 3DS, Chargeback-related). Passthrough from FiatTransactionsStatuses.AuthorizationType. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 52 | AuthorizationType | varchar(50) | YES | Authorization type display name for AuthorizationTypeID, resolved from External_FiatDwhDB_Dictionary_AuthorizationTypes.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 53 | IsTxStatusCBRelevant | int | YES | 1 if this transaction is relevant for chargeback analysis: TxStatusID IN (2,3,4) AND AuthorizationTypeID NOT IN (12,13). Both conditions must hold simultaneously. ETL CASE in Step 04. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 54 | MoneyMoveDirection | varchar(50) | YES | Direction of money flow based on HolderAmount: HolderAmount < 0 = MoneyOut; HolderAmount > 0 = MoneyIn; HolderAmount = 0 = Error. ETL CASE in Step 04. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.11 Amounts & Currency

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 55 | HolderCurrencyISO | varchar(50) | YES | ISO 4217 numeric currency code for the holder's balance currency (e.g., 826=GBP, 978=EUR, 208=DKK). Passthrough from FiatTransactionsStatuses.HolderCurrency (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 56 | HolderCurrencyDesc | varchar(200) | YES | Currency display name for HolderCurrencyISO, resolved via eMoney_Currency_Mapping_ISO.CurrencyAlphaThreeCode from the instrument mapping COALESCE(buy-side, sell-side). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 57 | HolderAmount | numeric(38,4) | YES | Amount debited/credited to the holder's balance in HolderCurrency. Negative = debit (MoneyOut); positive = credit (MoneyIn). Passthrough from FiatTransactionsStatuses.HolderAmount (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 58 | LocalCurrencyISO | varchar(50) | YES | ISO 4217 numeric currency code for the local transaction currency (e.g., the merchant's currency for card transactions). Passthrough from FiatTransactionsStatuses.TransactionCurrency. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 59 | LocalCurrencyDesc | varchar(200) | YES | Currency display name for LocalCurrencyISO, resolved from eMoney_Currency_Mapping_ISO.CurrencyName. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 60 | LocalAmount | numeric(38,4) | YES | Amount in the local transaction currency. May differ from HolderAmount when currency conversion occurs. Passthrough from FiatTransactionsStatuses.TransactionAmount (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 61 | USDAmountApprox | numeric(38,4) | YES | Approximate USD equivalent of HolderAmount at TxLocalDate. ROUND(HolderAmount × (Ask+Bid)/2, 2) using DWH_dbo.Fact_CurrencyPriceWithSplit mid-rate. NULL for DKK (no matching instrument). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 62 | USDRateApprox | numeric(38,4) | YES | USD mid-rate used for USDAmountApprox. ROUND((Ask+Bid)/2, 2) from DWH_dbo.Fact_CurrencyPriceWithSplit at TxLocalDate. NULL for DKK transactions. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 63 | AccumulatedAmount | numeric(38,4) | YES | Running accumulated balance in HolderCurrency at this transaction's status event. Passthrough from FiatTransactionsStatuses.AccumulatedAmount (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 64 | AccumulatedUSDAmountApprox | numeric(38,4) | YES | Approximate USD equivalent of AccumulatedAmount at TxLocalDate. Same mid-rate logic as USDAmountApprox. NULL for DKK. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.12 Status Timestamps

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 65 | TxStatusModificationTime | datetime | YES | Timestamp of the latest status change event (FiatTransactionsStatuses.TransactionOccured, RNDesc=1 by TransactionOccured DESC). The de facto "last updated" timestamp for this transaction's state. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 66 | TxStatusModificationDate | date | YES | Date portion of TxStatusModificationTime. DWH-derived: CAST(TransactionOccured AS DATE). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 67 | TxStatusModificationDateID | int | YES | YYYYMMDD integer date key for TxStatusModificationDate. DWH-derived: CONVERT(VARCHAR(8), TransactionOccured, 112). Has NCI for date-range query acceleration. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 68 | TxStatusCreatedDate | date | YES | Date on which this status event was created in FiatDwhDB. DWH-derived: CAST(FiatTransactionsStatuses.Created AS DATE). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 69 | TxStatusCreatedDateID | int | YES | YYYYMMDD integer date key for TxStatusCreatedDate. DWH-derived: CONVERT(VARCHAR(8), FiatTransactionsStatuses.Created, 112). (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.13 Risk & Compliance

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 70 | TXStatusCorrelationID | varchar(2000) | YES | Correlation ID from the latest status event. CAST(FiatTransactionsStatuses.CorrelationId AS VARCHAR(2000)). Used for tracing status events across systems. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 71 | RiskRuleCodes | varchar(2000) | YES | Risk rule codes triggered for this transaction. CAST(FiatTransactionsStatuses.RiskRuleCodes AS VARCHAR(2000)). NULL when no risk rules were triggered. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 72 | MarkTransactionAsSuspiciousRiskAction | int | YES | Risk action flag: 1 if the risk engine marked this transaction as suspicious. Passthrough from FiatTransactionsStatuses (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 73 | ChangeCardStatusToRiskRiskAction | int | YES | Risk action flag: 1 if the risk engine triggered a card status change to 'Risk' on this transaction. Passthrough from FiatTransactionsStatuses (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 74 | ChangeAccountStatusToSuspendedRiskAction | int | YES | Risk action flag: 1 if the risk engine triggered account suspension on this transaction. Passthrough from FiatTransactionsStatuses (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 75 | RejectTransactionRiskAction | int | YES | Risk action flag: 1 if the risk engine rejected this transaction. Passthrough from FiatTransactionsStatuses (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.14 Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 76 | UpdateDate | datetime | YES | GETDATE() at INSERT time. Marks when the daily ETL refresh ran; not a business timestamp. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 77 | SourceCugTransactionID | int | YES | Source transaction ID in the CUG (eToro Crypto-to-Fiat) system. Added 2025-09-08 (Inessa Ovadia). NULL for transactions created before this feature was deployed or for non-CUG transactions. (Tier 2 — SP_eMoney_DimFact_Transaction) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column Group | Production Source | Source Column(s) | Transform |
|-----------------|-------------------|-----------------|-----------|
| TransactionID | FiatDwhDB.dbo.FiatTransactions | Id | Passthrough |
| AccountID, CardID, CurrencyBalanceID, ExternalBankAccountID | FiatDwhDB.dbo.FiatTransactions | AccountId, CardId, CurrencyBalanceId, ExternalBankAccountId | Passthrough (FK references) |
| GCID, CID, ProviderCardID, ProviderCurrencyBalanceID, AccountProgramID, AccountSubProgramID, IsValidETM | eMoney_dbo.eMoney_Dim_Account snapshot (Step 01) | GCID, CID, ProviderCardID, ProviderCurrencyBalanceID, AccountProgramID, AccountSubProgramID, IsValidETM | Passthrough from latest Dim_Account state |
| TxTypeID, TxType, TxTypeCategory, TxClientBalanceCategory, TxCreatedDate, TxLocalTime, TxLabel, MerchantID, TxCategoryID, PaymentSchemaTypeID, ReferenceNumber, MoneyCorrelationID | FiatDwhDB.dbo.FiatTransactions | TransactionTypeId, Created, TransactionLocalTime, Label, MerchantId, TransactionCategory, PaymentSchemeId, ReferenceNumber, MoneyCorrelationId | Passthrough/CAST/CASE |
| TxStatusID, TxStatus, IsTxSettled, IsTxStatusCBRelevant, MoneyMoveDirection, HolderAmount, HolderCurrencyISO, LocalAmount, LocalCurrencyISO, AccumulatedAmount, TxStatusModificationTime, TXStatusCorrelationID, RiskRuleCodes, Risk* flags, AuthorizationTypeID | FiatDwhDB.dbo.FiatTransactionsStatuses | TransactionStatusId, HolderAmount, HolderCurrency, TransactionAmount, TransactionCurrency, AccumulatedAmount, TransactionOccured, CorrelationId, RiskRuleCodes, AuthorizationType, risk flags | Latest event (RNDesc=1 by TransactionOccured DESC) |
| ProviderID, ProviderDesc, ProviderTransactionID | FiatDwhDB.dbo.TransactionsProvidersMapping | ProviderId, TransactionProviderId | Latest mapping (RN_Desc=1) |
| ClubIDTxDate, RegulationIDTxDate, CountryIDTxDate, PlayerStatusIDTxDate, IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID, RegulationID, CountryID, PlayerStatusID, IsValidCustomer | Snapshot at TxLocalDateID range (Step 08) |
| USDAmountApprox, USDRateApprox, AccumulatedUSDAmountApprox | DWH_dbo.Fact_CurrencyPriceWithSplit | Ask, Bid | Mid-rate at TxLocalDate (Step 06) |

### 5.2 ETL Pipeline

```
FiatDwhDB (eToro Money Fiat DWH)
├── dbo.FiatTransactions ──────────────────────────────┐
├── dbo.FiatTransactionsStatuses (RNDesc=1) ───────────┤
└── dbo.TransactionsProvidersMapping (RN_Desc=1) ──────┤
                                                        │
eMoney_dbo.eMoney_Dim_Account (snapshot, Step 01) ─────┤
                                                        │
                                                        ▼
                               SP_eMoney_DimFact_Transaction (11-step)
                                        │
                          ┌─────────────┼─────────────┐
                          ▼             ▼             ▼
               Fact_SnapshotCustomer  Fact_CurrencyPrice  eMoney_Currency_Instrument_Mapping_ISO
               (customer at TxDate)   (USD mid-rate)      (currency→instrument bridge)
                          │
                          ▼
                   #leveled_txs (all status events, Steps 01-09)
                          │
               ┌──────────┴──────────┐
               ▼                     ▼
    Step 10: WHERE RNDesc=1    Step 11: all rows
    eMoney_Dim_Transaction     eMoney_Fact_Transaction_Status
    (latest status only)       (all status events)
               │
               ▼
    UC: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | eToro trading platform customer |
| AccountID | eMoney_dbo.eMoney_Dim_Account.AccountID | Account dimension |
| CurrencyBalanceID | eMoney_dbo.eMoney_Dim_Account.CurrencyBalanceID | Currency balance dimension |
| CardID | eMoney_dbo.eMoney_Dim_Account.CardID | Card dimension |
| ClubIDTxDate | DWH_dbo.Dim_PlayerLevel.PlayerLevelID | Club level lookup |
| RegulationIDTxDate | DWH_dbo.Dim_Regulation.DWHRegulationID | Regulation lookup |
| CountryIDTxDate | DWH_dbo.Dim_Country.CountryID | Country lookup |
| PlayerStatusIDTxDate | DWH_dbo.Dim_PlayerStatus.PlayerStatusID | Player status lookup |
| AccountProgramID | eMoney_dbo.eMoney_Dictionary_AccountProgram.AccountProgramID | Program type |
| AccountSubProgramID | eMoney_dbo.SubPrograms.Id | Sub-program variant |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| eMoney_dbo.eMoney_Fact_Transaction_Status | TransactionID | Status history for transactions in this table |
| eMoney_dbo.v_eMoney_Dim_Transaction | — | View wrapper for current-day refresh |

---

## 7. Sample Queries

### 7.1 Settled transactions by entity this month

```sql
SELECT
    da.Entity,
    dt.TxTypeCategory,
    COUNT(1) AS TxCount,
    SUM(dt.USDAmountApprox) AS TotalUSD
FROM eMoney_dbo.eMoney_Dim_Transaction dt WITH(NOLOCK)
INNER JOIN eMoney_dbo.eMoney_Dim_Account da WITH(NOLOCK)
    ON dt.CID = da.CID AND da.GCID_Unique_Count = 1
WHERE dt.IsTxSettled = 1
  AND dt.TxLocalDateID BETWEEN 20260401 AND 20260430
GROUP BY da.Entity, dt.TxTypeCategory
ORDER BY da.Entity, TotalUSD DESC;
```

### 7.2 Chargeback-relevant transactions by regulation at transaction date

```sql
SELECT
    dt.RegulationIDTxDate,
    dt.RegulationTxDate,
    dt.AuthorizationType,
    COUNT(1) AS CBRelevantCount,
    SUM(ABS(dt.USDAmountApprox)) AS TotalUSD
FROM eMoney_dbo.eMoney_Dim_Transaction dt WITH(NOLOCK)
WHERE dt.IsTxStatusCBRelevant = 1
  AND dt.TxLocalDateID >= 20260101
GROUP BY dt.RegulationIDTxDate, dt.RegulationTxDate, dt.AuthorizationType
ORDER BY CBRelevantCount DESC;
```

### 7.3 Transactions where status changed multiple times

```sql
SELECT
    dt.TransactionID,
    dt.TxStatus,
    dt.CountStatusChanges,
    dt.TxStatusModificationTime,
    dt.USDAmountApprox
FROM eMoney_dbo.eMoney_Dim_Transaction dt WITH(NOLOCK)
WHERE dt.CountStatusChanges > 2
  AND dt.IsValidETM = 1
ORDER BY dt.CountStatusChanges DESC, dt.TxStatusModificationTime DESC;
```

---

## 8. Validation

### 8.1 Row Count Check

```sql
SELECT COUNT(1) AS RowCount FROM eMoney_dbo.eMoney_Dim_Transaction WITH(NOLOCK);
-- Expected: ~28.5M (as of 2026-04-20); grows daily
```

### 8.2 Grain Check (one row per TransactionID)

```sql
SELECT TransactionID, COUNT(1) AS cnt
FROM eMoney_dbo.eMoney_Dim_Transaction WITH(NOLOCK)
GROUP BY TransactionID
HAVING COUNT(1) > 1;
-- Expected: 0 rows (each TransactionID appears exactly once)
```

### 8.3 IsTxSettled Dominance

```sql
SELECT IsTxSettled, COUNT(1) AS cnt
FROM eMoney_dbo.eMoney_Dim_Transaction WITH(NOLOCK)
GROUP BY IsTxSettled;
-- Expected: IsTxSettled=1 ~98.3%, IsTxSettled=0 ~1.7%
```

---

*Tiers: 8 T1, 69 T2, 0 T3, 0 T4, 0 T5*

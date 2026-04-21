# eMoney_dbo.eMoney_Fact_Transaction_Status

> One row per eToro Money fiat transaction **status event** — retains the complete status history for every transaction. 32,255,255 rows; transactions created 2020-11-10 to 2026-04-20; refreshed daily via DELETE + INSERT (Step 11 of SP_eMoney_DimFact_Transaction). Analytics-optimised CLUSTERED COLUMNSTORE INDEX.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | FiatDwhDB (eToro Money fiat platform DWH) via SP_eMoney_DimFact_Transaction (Step 11) |
| **Refresh** | Daily DELETE + INSERT (Step 11 of SP_eMoney_DimFact_Transaction; shared SP with eMoney_Dim_Transaction) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX (no clustering key; no NCIs) |
| **Row Count** | 32,255,255 (sampled 2026-04-20; ~3.7M more than eMoney_Dim_Transaction due to multi-status transactions) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Fact_Transaction_Status` is the **full status history fact table** for eToro Money (eTM) fiat transactions. Unlike `eMoney_Dim_Transaction` (which retains only the latest status per transaction), this table retains **every status event** from `FiatTransactionsStatuses` — including intermediate states such as Authorized, Reserved, or Rejected — before a transaction reaches its terminal state.

The table is populated by **Step 11** of `SP_eMoney_DimFact_Transaction`, which shares the same 11-step pipeline as `eMoney_Dim_Transaction`. Both tables read from the same `#leveled_txs` staging CTE (all status events), but diverge at the final INSERT step:
- `eMoney_Dim_Transaction` (Step 10): inserts `WHERE RNDesc=1` — latest status per transaction only
- `eMoney_Fact_Transaction_Status` (Step 11): inserts **without RNDesc filter** — all status events

The row count difference (~3.7M more rows than `eMoney_Dim_Transaction`) represents transactions that went through multiple status events (e.g., Authorized → Settled, or Authorized → Rejected).

**Key structural difference from eMoney_Dim_Transaction**: Column 47 is `FiatTransactionStatusRunningID` (the surrogate PK of each individual status event row from `FiatTransactionsStatuses.Id`) rather than `IsTxSettled`. Use `FiatTransactionStatusRunningID` as the unique row key for this table.

**Use this table when**:
- Analysing the transaction lifecycle (how many transactions progressed through 2+ states)
- Building time-series of transaction state changes
- Chargeback analysis requiring the exact sequence of status events
- Any analysis where the intermediate states (Authorized, Reserved) matter, not just the final state

**Use eMoney_Dim_Transaction instead when**:
- Standard transaction analytics (one row per transaction, current state)
- Filtering on `IsTxSettled=1`
- Joining to other CID-level dimensions without duplicating transaction counts

The CLUSTERED COLUMNSTORE INDEX makes this table optimised for large-scale analytics scans (aggregate queries over millions of rows). There are no NCIs — queries on specific TransactionID values will require full columnstore scans or should be redirected to `eMoney_Dim_Transaction` (which has a TransactionID NCI).

---

## 2. Business Logic

### 2.1 Full-Status-History Grain

**What**: The table is at (TransactionID, StatusEvent) grain — multiple rows per TransactionID when a transaction went through more than one status.

**Columns Involved**: `TransactionID`, `FiatTransactionStatusRunningID`, `TxStatusID`, `TxStatusModificationTime`, `CountStatusChanges`

**Rules**:
- `FiatTransactionStatusRunningID = FiatTransactionsStatuses.Id` — the unique surrogate PK of each individual status event record; use this as the unique row key for this table
- `RNDesc = ROW_NUMBER() PARTITION BY TransactionId ORDER BY TransactionOccured DESC` was computed in #tx_status (Step 04) but no RNDesc filter is applied at the final INSERT (Step 11)
- `CountStatusChanges = MAX(RNDesc)` per TransactionID — same value on ALL rows for a given transaction (denormalized)
- The row with `FiatTransactionStatusRunningID` matching the latest status event represents the current state; rows with earlier events represent the history
- To get only the current state per transaction: use `eMoney_Dim_Transaction` directly

### 2.2 Customer Snapshot at Transaction Date vs Current

**What**: Customer attributes (club, regulation, country, player status) reflect the **customer's state at the transaction local date** — not current values. This is identical to the behaviour in eMoney_Dim_Transaction.

**Columns Involved**: `ClubIDTxDate`, `ClubTxDate`, `RegulationIDTxDate`, `RegulationTxDate`, `CountryIDTxDate`, `CountryTxDate`, `PlayerStatusIDTxDate`, `PlayerStatusTxDate`, `IsValidCustomer`

**Rules**:
- Sourced from `DWH_dbo.Fact_SnapshotCustomer` joined at `TxLocalDateID` range (Step 08 of SP)
- `AccountProgramID`, `AccountSubProgramID`, and `IsValidETM` reflect **current values** (from `eMoney_Dim_Account` at ETL run time, NOT at transaction date)

### 2.3 USD Approximation Logic

**What**: `USDAmountApprox` is computed per status event using `FiatTransactionStatusRunningID` as the unique join key to the USD approximation temp table (#usdapprox).

**Columns Involved**: `HolderAmount`, `HolderCurrencyISO`, `USDAmountApprox`, `USDRateApprox`, `AccumulatedUSDAmountApprox`, `FiatTransactionStatusRunningID`

**Rules**:
- `#usdapprox` is joined on `FiatTransactionStatusRunningID` — ensuring each status event gets its own USD approximation based on its own `HolderAmount`
- Same mid-rate logic as `eMoney_Dim_Transaction`: ROUND(HolderAmount × (Ask+Bid)/2, 2) from Fact_CurrencyPriceWithSplit at TxLocalDate
- DKK (ISO 208) has no instrument in Fact_CurrencyPriceWithSplit → NULL for all DKK events
- HolderAmount can differ across status events for the same transaction (e.g., authorization amount may differ from settlement amount)

### 2.4 FiatTransactionStatusRunningID (Row Key)

**What**: The surrogate PK for this table — uniquely identifies each status event row.

**Columns Involved**: `FiatTransactionStatusRunningID`

**Rules**:
- Sourced from `FiatTransactionsStatuses.Id` (the auto-incrementing PK in FiatDwhDB)
- This is the column at position 47, where `eMoney_Dim_Transaction` has `IsTxSettled`
- Use `FiatTransactionStatusRunningID` for row-level joins (e.g., joining to a separate risk event table)
- `IsTxSettled` does NOT exist in this table — compute it as `CASE WHEN TxStatusID=2 THEN 1 ELSE 0` if needed

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table uses `HASH(CID)` distribution — consistent with `eMoney_Dim_Transaction` for join colocation. There are no NCIs; the CLUSTERED COLUMNSTORE INDEX is optimised for large-scale aggregates.

**Segment elimination**: Column store segments are sorted by insertion order (daily batch). Date-range queries using `TxStatusModificationDateID` or `TxLocalDateID` may not benefit from segment elimination since there is no secondary sort order. Include date predicates regardless — they reduce row group scans.

**Direct TransactionID lookups**: The CLUSTERED COLUMNSTORE INDEX does not support efficient single-transaction lookups. For a specific TransactionID's full history, a full columnstore scan is required. For large-scale analytics this is fine; for point lookups, consider routing to `eMoney_Dim_Transaction` (has TransactionID NCI) and joining back.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Transaction status history (all events) | WHERE TransactionID = N ORDER BY TxStatusModificationTime |
| Transactions with >2 status changes | WHERE CountStatusChanges > 2 (any row per TransactionID has this) |
| State transition analysis (Authorized→Settled) | GROUP BY TransactionID, TxStatusID; self-join on TransactionID |
| Chargeback-relevant status events | WHERE IsTxStatusCBRelevant=1 |
| MoneyOut events by status | WHERE MoneyMoveDirection='MoneyOut', GROUP BY TxStatusID |
| Authorization events specifically | WHERE TxStatusID=1 (Authorized) |
| USD volume by status | SUM(USDAmountApprox) GROUP BY TxStatusID, RegulationIDTxDate |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Transaction | ON fts.TransactionID = dt.TransactionID | Current-state context for status event rows |
| eMoney_dbo.eMoney_Dim_Account | ON fts.CID = da.CID AND da.GCID_Unique_Count=1 | Account attributes |
| DWH_dbo.Dim_Customer | ON fts.CID = dc.RealCID | Trading platform customer |
| DWH_dbo.Dim_Regulation | ON fts.RegulationIDTxDate = r.DWHRegulationID | Regulation name at tx date |

### 3.4 Gotchas

- **No IsTxSettled column**: Unlike `eMoney_Dim_Transaction`, this table has `FiatTransactionStatusRunningID` at position 47. Compute settled flag on the fly: `CASE WHEN TxStatusID=2 THEN 1 ELSE 0`.
- **Multiple rows per TransactionID**: Aggregate functions (COUNT, SUM) over this table WITHOUT grouping by FiatTransactionStatusRunningID will double-count multi-status transactions.
- **CountStatusChanges is denormalized**: The same value appears on ALL rows for a given TransactionID; it is NOT the running position of this event.
- **USDAmountApprox NULL for DKK**: ISO 208 (DKK) has no matching instrument; USD fields are NULL for all DKK status events.
- **No NCIs**: Point lookups by TransactionID require full columnstore scans. Use eMoney_Dim_Transaction for NCI-based lookups.
- **Customer snapshot vs current**: Same temporal mismatch as eMoney_Dim_Transaction — `ClubIDTxDate` etc. are at TxLocalDate; `AccountProgramID`, `IsValidETM` are current.
- **ProviderTransactionID is float**: Same DDL issue as eMoney_Dim_Transaction; cast to BIGINT for equality predicates.
- **UpdateDate ≠ business timestamp**: Marks the ETL run date, not any transaction or status event time.

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

*Note: 76 of 77 column descriptions are identical to eMoney_Dim_Transaction (same SP, same source columns). Only column 47 differs.*

### 4.1 Transaction & Account Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TransactionID | int | YES | Surrogate key for the fiat transaction from FiatDwhDB.dbo.FiatTransactions.Id. Each transaction appears on MULTIPLE rows in this table (one row per status event). (Tier 2 — SP_eMoney_DimFact_Transaction) |
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
| 10 | TxTypeID | int | YES | Transaction type identifier. 1=CardPayment, 2=ContactlessPayment, 3=CardCashWithdrawal, 4=CardRefund, 5=Transfer, 6=TransferReceived, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBankAccount, 12=DebitBankAccount, 13=OnlinePayment, 14=DirectDebit (15=CryptoToFiat via dictionary). Passthrough from FiatTransactions.TransactionTypeId. (Tier 2 — SP_eMoney_DimFact_Transaction) |
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
| 18 | TxLocalTime | datetime | YES | Local transaction timestamp from FiatTransactions.TransactionLocalTime. The authoritative event time for the transaction itself (same for all status event rows of the same transaction). (Tier 2 — SP_eMoney_DimFact_Transaction) |
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
| 38 | IsValidCustomer | int | YES | DWH-computed validity flag at TxLocalDate (from Fact_SnapshotCustomer snapshot, Step 08). 1 when not Popular Investor, not label 30/26, and not CountryID=250 at the time of the transaction. (Tier 2 — SP_eMoney_DimFact_Transaction) |

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

### 4.10 Status Event Row Key

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 47 | FiatTransactionStatusRunningID | int | YES | Surrogate PK of this individual status event row, sourced from FiatTransactionsStatuses.Id. Uniquely identifies a single status event for a transaction. Also used as the join key to the USD approximation pipeline (#usdapprox join). KEY DIFFERENCE from eMoney_Dim_Transaction (which has IsTxSettled at this position). (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.11 Transaction Status (This Event)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 48 | TxStatusID | int | YES | Transaction lifecycle status for THIS event (not necessarily the latest). 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired, 6=Reserved, 7=Cancelled. Passthrough from FiatTransactionsStatuses.TransactionStatusId. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 49 | TxStatus | varchar(50) | YES | Transaction status display name for TxStatusID, resolved from External_FiatDwhDB_Dictionary_TransactionStatuses.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 50 | CountStatusChanges | int | YES | Total number of status events for this transaction (MAX(RNDesc) per TransactionID). Denormalized — same value on all rows for a given TransactionID. 1 = single-status transaction; >1 = went through multiple states. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 51 | AuthorizationTypeID | int | YES | Authorization method used in THIS status event from FiatTransactionsStatuses. 13 possible values (e.g., PIN, Contactless, Online, 3DS, Chargeback-related). Passthrough from FiatTransactionsStatuses.AuthorizationType. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 52 | AuthorizationType | varchar(50) | YES | Authorization type display name for AuthorizationTypeID, resolved from External_FiatDwhDB_Dictionary_AuthorizationTypes.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 53 | IsTxStatusCBRelevant | int | YES | 1 if THIS status event is relevant for chargeback analysis: TxStatusID IN (2,3,4) AND AuthorizationTypeID NOT IN (12,13). Both conditions must hold simultaneously. ETL CASE in Step 04. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 54 | MoneyMoveDirection | varchar(50) | YES | Direction of money flow for THIS event based on HolderAmount: HolderAmount < 0 = MoneyOut; HolderAmount > 0 = MoneyIn; HolderAmount = 0 = Error. ETL CASE in Step 04. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.12 Amounts & Currency

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 55 | HolderCurrencyISO | varchar(50) | YES | ISO 4217 numeric currency code for the holder's balance currency (e.g., 826=GBP, 978=EUR, 208=DKK). Passthrough from FiatTransactionsStatuses.HolderCurrency (this event). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 56 | HolderCurrencyDesc | varchar(200) | YES | Currency display name for HolderCurrencyISO, resolved via eMoney_Currency_Mapping_ISO.CurrencyAlphaThreeCode from the instrument mapping COALESCE(buy-side, sell-side). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 57 | HolderAmount | numeric(38,4) | YES | Amount debited/credited to the holder's balance in HolderCurrency for THIS event. Negative = debit (MoneyOut); positive = credit (MoneyIn). Passthrough from FiatTransactionsStatuses.HolderAmount. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 58 | LocalCurrencyISO | varchar(50) | YES | ISO 4217 numeric currency code for the local transaction currency (e.g., the merchant's currency for card transactions). Passthrough from FiatTransactionsStatuses.TransactionCurrency. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 59 | LocalCurrencyDesc | varchar(200) | YES | Currency display name for LocalCurrencyISO, resolved from eMoney_Currency_Mapping_ISO.CurrencyName. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 60 | LocalAmount | numeric(38,4) | YES | Amount in the local transaction currency for THIS event. Passthrough from FiatTransactionsStatuses.TransactionAmount. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 61 | USDAmountApprox | numeric(38,4) | YES | Approximate USD equivalent of HolderAmount at TxLocalDate for THIS status event. Joined via FiatTransactionStatusRunningID. ROUND(HolderAmount × (Ask+Bid)/2, 2). NULL for DKK. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 62 | USDRateApprox | numeric(38,4) | YES | USD mid-rate used for USDAmountApprox for THIS event. ROUND((Ask+Bid)/2, 2) from Fact_CurrencyPriceWithSplit at TxLocalDate. NULL for DKK transactions. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 63 | AccumulatedAmount | numeric(38,4) | YES | Running accumulated balance in HolderCurrency at THIS transaction's status event. Passthrough from FiatTransactionsStatuses.AccumulatedAmount. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 64 | AccumulatedUSDAmountApprox | numeric(38,4) | YES | Approximate USD equivalent of AccumulatedAmount at TxLocalDate for THIS event. Same mid-rate logic as USDAmountApprox. NULL for DKK. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.13 Status Timestamps

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 65 | TxStatusModificationTime | datetime | YES | Timestamp of THIS status change event (FiatTransactionsStatuses.TransactionOccured). The event time for this particular row in the status history. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 66 | TxStatusModificationDate | date | YES | Date portion of TxStatusModificationTime. DWH-derived: CAST(TransactionOccured AS DATE). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 67 | TxStatusModificationDateID | int | YES | YYYYMMDD integer date key for TxStatusModificationDate. DWH-derived: CONVERT(VARCHAR(8), TransactionOccured, 112). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 68 | TxStatusCreatedDate | date | YES | Date on which THIS status event was created in FiatDwhDB. DWH-derived: CAST(FiatTransactionsStatuses.Created AS DATE). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 69 | TxStatusCreatedDateID | int | YES | YYYYMMDD integer date key for TxStatusCreatedDate. DWH-derived: CONVERT(VARCHAR(8), FiatTransactionsStatuses.Created, 112). (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.14 Risk & Compliance

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 70 | TXStatusCorrelationID | varchar(2000) | YES | Correlation ID from THIS status event. CAST(FiatTransactionsStatuses.CorrelationId AS VARCHAR(2000)). Used for tracing status events across systems. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 71 | RiskRuleCodes | varchar(2000) | YES | Risk rule codes triggered for THIS status event. CAST(FiatTransactionsStatuses.RiskRuleCodes AS VARCHAR(2000)). NULL when no risk rules were triggered. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 72 | MarkTransactionAsSuspiciousRiskAction | int | YES | Risk action flag: 1 if the risk engine marked this status event as suspicious. Passthrough from FiatTransactionsStatuses. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 73 | ChangeCardStatusToRiskRiskAction | int | YES | Risk action flag: 1 if the risk engine triggered a card status change to 'Risk' on this status event. Passthrough from FiatTransactionsStatuses. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 74 | ChangeAccountStatusToSuspendedRiskAction | int | YES | Risk action flag: 1 if the risk engine triggered account suspension on this status event. Passthrough from FiatTransactionsStatuses. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 75 | RejectTransactionRiskAction | int | YES | Risk action flag: 1 if the risk engine rejected this status event. Passthrough from FiatTransactionsStatuses. (Tier 2 — SP_eMoney_DimFact_Transaction) |

### 4.15 Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 76 | UpdateDate | datetime | YES | GETDATE() at INSERT time. Marks when the daily ETL refresh ran; not a business timestamp. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 77 | SourceCugTransactionID | int | YES | Source transaction ID in the CUG (eToro Crypto-to-Fiat) system. Added 2025-09-08 (Inessa Ovadia). NULL for transactions created before this feature was deployed or for non-CUG transactions. (Tier 2 — SP_eMoney_DimFact_Transaction) |

---

## 5. Lineage

### 5.1 Production Sources

Identical to eMoney_Dim_Transaction — see `eMoney_Dim_Transaction.lineage.md` for the full column-level source table. The only structural difference is:
- Column 47: `FiatTransactionStatusRunningID` ← `FiatTransactionsStatuses.Id` (here) vs `IsTxSettled` CASE expression (in Dim_Transaction)
- No RNDesc=1 filter at INSERT time (Step 11) — all status events are retained

### 5.2 ETL Pipeline

```
FiatDwhDB (eToro Money Fiat DWH)
├── dbo.FiatTransactions ──────────────────────────────┐
├── dbo.FiatTransactionsStatuses (ALL events) ─────────┤
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
    Step 10: WHERE RNDesc=1    Step 11: all rows (no filter)
    eMoney_Dim_Transaction     eMoney_Fact_Transaction_Status
    (latest status only)       (complete status history)
                               │
                               ▼
              UC: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | eToro trading platform customer |
| AccountID | eMoney_dbo.eMoney_Dim_Account.AccountID | Account dimension |
| CurrencyBalanceID | eMoney_dbo.eMoney_Dim_Account.CurrencyBalanceID | Currency balance dimension |
| ClubIDTxDate | DWH_dbo.Dim_PlayerLevel.PlayerLevelID | Club level lookup |
| RegulationIDTxDate | DWH_dbo.Dim_Regulation.DWHRegulationID | Regulation lookup |
| CountryIDTxDate | DWH_dbo.Dim_Country.CountryID | Country lookup |
| PlayerStatusIDTxDate | DWH_dbo.Dim_PlayerStatus.PlayerStatusID | Player status lookup |
| AccountProgramID | eMoney_dbo.eMoney_Dictionary_AccountProgram.AccountProgramID | Program type |
| AccountSubProgramID | eMoney_dbo.SubPrograms.Id | Sub-program variant |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| eMoney_dbo.eMoney_Dim_Transaction | TransactionID | Current-state lookup joins to status history |

---

## 7. Sample Queries

### 7.1 Full status lifecycle for a specific transaction

```sql
SELECT
    fts.TransactionID,
    fts.FiatTransactionStatusRunningID,
    fts.TxStatusID,
    fts.TxStatus,
    fts.HolderAmount,
    fts.HolderCurrencyISO,
    fts.TxStatusModificationTime
FROM eMoney_dbo.eMoney_Fact_Transaction_Status fts WITH(NOLOCK)
WHERE fts.TransactionID = 123456789
ORDER BY fts.TxStatusModificationTime ASC;
```

### 7.2 Transactions with Authorized → Settled lifecycle count by entity

```sql
SELECT
    da.Entity,
    COUNT(DISTINCT auth.TransactionID) AS AuthToSettledCount
FROM eMoney_dbo.eMoney_Fact_Transaction_Status auth WITH(NOLOCK)
INNER JOIN eMoney_dbo.eMoney_Fact_Transaction_Status sett WITH(NOLOCK)
    ON auth.TransactionID = sett.TransactionID
    AND sett.TxStatusID = 2   -- Settled
INNER JOIN eMoney_dbo.eMoney_Dim_Account da WITH(NOLOCK)
    ON auth.CID = da.CID AND da.GCID_Unique_Count = 1
WHERE auth.TxStatusID = 1   -- Authorized
  AND auth.TxLocalDateID BETWEEN 20260401 AND 20260430
GROUP BY da.Entity;
```

### 7.3 Risk-flagged status events by month

```sql
SELECT
    FORMAT(fts.TxStatusModificationDate, 'yyyy-MM') AS Month,
    COUNT(1) AS RiskEvents
FROM eMoney_dbo.eMoney_Fact_Transaction_Status fts WITH(NOLOCK)
WHERE fts.MarkTransactionAsSuspiciousRiskAction = 1
   OR fts.RejectTransactionRiskAction = 1
GROUP BY FORMAT(fts.TxStatusModificationDate, 'yyyy-MM')
ORDER BY Month DESC;
```

---

## 8. Validation

### 8.1 Row Count Check

```sql
SELECT COUNT(1) AS RowCount FROM eMoney_dbo.eMoney_Fact_Transaction_Status WITH(NOLOCK);
-- Expected: ~32.3M (as of 2026-04-20); exceeds eMoney_Dim_Transaction by ~3.7M (multi-status transactions)
```

### 8.2 Row Key Uniqueness (FiatTransactionStatusRunningID)

```sql
SELECT FiatTransactionStatusRunningID, COUNT(1) AS cnt
FROM eMoney_dbo.eMoney_Fact_Transaction_Status WITH(NOLOCK)
GROUP BY FiatTransactionStatusRunningID
HAVING COUNT(1) > 1;
-- Expected: 0 rows (each status event ID appears exactly once)
```

### 8.3 Row Count vs Dim_Transaction

```sql
SELECT
    (SELECT COUNT(1) FROM eMoney_dbo.eMoney_Fact_Transaction_Status WITH(NOLOCK)) AS FactRows,
    (SELECT COUNT(1) FROM eMoney_dbo.eMoney_Dim_Transaction WITH(NOLOCK)) AS DimRows;
-- Expected: FactRows > DimRows (multi-status transactions inflate Fact count)
```

---

*Tiers: 8 T1, 69 T2, 0 T3, 0 T4, 0 T5*

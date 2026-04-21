# Column Lineage: eMoney_dbo.eMoney_Calculated_Balance

**Generated**: 2026-04-20 | **Batch**: 8 | **Object type**: Table

## ETL Pipeline

```
eMoney_dbo.eMoney_Dim_Account                    ──→  Account identity (CurrencyBalanceID, GCID, CID,
  (CurrencyBalanceCreateDateID < @DateID_NextDay)       AccountProgram, AccountSubProgram, IsTestAccount,
                                                        IsValidETM, ProviderHolderID, ProviderCurrencyBalanceID)
DWH_dbo.Fact_SnapshotCustomer (via Dim_Range)    ──→  Customer attributes (CountryID, PlayerLevelID,
  (SCD: DateRangeID BETWEEN @DateID)                    PlayerStatusID, RegulationID, LabelID, AccountTypeID,
                                                        MifidCategorizationID)
DWH_dbo.Dim_Country, Dim_PlayerLevel,            ──→  AccountType, Label, MifidCategory, Country, Club,
  Dim_AccountType, Dim_Label,                           PlayerStatus, Regulation (label lookups)
  Dim_MifidCategorization, Dim_PlayerStatus,
  Dim_Regulation
eMoney_dbo.eMoney_Fact_Transaction_Status        ──→  All transaction flows; TotalBalance; Correction
  (IsTxStatusCBRelevant=1)
eMoney_dbo.eMoney_Calculated_Balance (self)      ──→  OpeningBalance (prior day ClosingBalance self-join)
  (BalanceDateID = @DateID_PreviousDay)
eMoney_dbo.eMoney_Currency_Instrument_Mapping_   ──→  InstrumentID lookup (SellCurrencyID=1 for USD pairs)
  Static (SellCurrencyID=1)
DWH_dbo.Fact_CurrencyPriceWithSplit              ──→  USDApproxRate = (Ask+Bid)/2
  (OccurredDateID = @DateID)
                         │
                         ▼
         SP_eMoney_Calculated_Balance (@Date DATE)
         Daily DELETE WHERE BalanceDateID=@DateID
         INSERT from #final → 48 columns
         CardID and ProviderCardID always NULL (commented out)
         IsGermanBaFin always NULL (feature not implemented)
                         │
                         ▼
         eMoney_dbo.eMoney_Calculated_Balance
         48 cols | HASH(CID) | CLUSTERED INDEX(BalanceDateID ASC)
         NCI on CurrencyBalanceID
```

*Note: MaxDate = 2025-06-09; table not loaded since ~2025-06-10 (~10 months as of 2026-04-20).*

---

## Column Lineage Map

### Date / ID Dimensions

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 1 | BalanceDateID | int | CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT) | T2 | Integer YYYYMMDD of @Date parameter |
| 2 | BalanceDate | date | @Date parameter | T2 | Business date; also DELETE key for idempotent reload |

### Account Identity (from eMoney_Dim_Account)

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 3 | CurrencyBalanceID | int | eMoney_Dim_Account.CurrencyBalanceID | T2 | DWH account identifier; NCI key |
| 4 | ProviderCurrencyBalanceID | int | eMoney_Dim_Account.ProviderCurrencyBalanceID | T2 | Tribe AccountId (provider's account key) |
| 5 | AccountID | int | eMoney_Dim_Account.AccountID | T2 | Platform account identifier |
| 6 | GCID | int | eMoney_Dim_Account.GCID | T2 | eToro global customer ID |
| 7 | CID | int | eMoney_Dim_Account.CID (as RealCID) | T2 | eToro customer ID; distribution hash key |
| 8 | CurrencyISOCode | int | eMoney_Dim_Account.CurrencyBalanceISOCode | T2 | ISO 4217 numeric currency code |
| 9 | Currency | varchar(50) | eMoney_Dim_Account.CurrencyBalanceISODesc | T2 | ISO currency alpha code (GBP, EUR, AUD, DKK) |
| 10 | AccountProgramID | int | eMoney_Dim_Account.AccountProgramID | T2 | FK to eMoney_Dictionary_AccountProgram (1=card, 2=iban) |
| 11 | AccountProgram | varchar(50) | eMoney_Dim_Account.AccountProgram | T2 | Program label: 'card' or 'iban' |
| 12 | AccountSubProgramID | int | eMoney_Dim_Account.AccountSubProgramID | T2 | FK to eMoney_Dictionary_AccountSubProgram |
| 13 | AccountSubProgram | varchar(50) | eMoney_Dim_Account.AccountSubProgram | T2 | Sub-program label (e.g., 'IBAN Standard UK') |
| 14 | ProviderHolderID | int | eMoney_Dim_Account.ProviderHolderID | T2 | Tribe holder (customer) identifier |
| 15 | CardID | int | NULL (always) | T2 | Commented out in SP; reserved for future card linkage |
| 16 | ProviderCardID | int | NULL (always) | T2 | Commented out in SP; reserved for future card linkage |
| 17 | IsTestAccount | int | eMoney_Dim_Account.IsTestAccount | T2 | 1 if test account |
| 18 | IsValidETM | int | eMoney_Dim_Account.IsValidETM | T2 | 1 if valid eToro Money account |
| 19 | UserType | varchar(50) | CASE: 'TestUser' (IsTestAccount=1) / 'Obsolete Account' (GCID=0) / 'eTorian' (IsValidCustomer=0) / 'RegularUser' | T2 | Computed user classification |

### Customer Attributes (from Fact_SnapshotCustomer via Dim_Range SCD)

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 20 | AccountType | varchar(50) | DWH_dbo.Dim_AccountType.Name (LEFT JOIN) | T2 | Account type label; NULL if no snapshot record |
| 21 | Label | varchar(50) | DWH_dbo.Dim_Label.Name (LEFT JOIN) | T2 | eToro customer label |
| 22 | MifidCategory | varchar(50) | DWH_dbo.Dim_MifidCategorization.Name (LEFT JOIN) | T2 | MiFID II categorization |
| 23 | CountryID | int | DWH_dbo.Fact_SnapshotCustomer.CountryID (INNER JOIN) | T2 | DWH country dimension FK |
| 24 | Country | varchar(50) | DWH_dbo.Dim_Country.Name (INNER JOIN) | T2 | Country name |
| 25 | PlayerLevelID | int | DWH_dbo.Fact_SnapshotCustomer.PlayerLevelID (INNER JOIN) | T2 | Player level FK |
| 26 | Club | varchar(50) | DWH_dbo.Dim_PlayerLevel.Name (INNER JOIN) | T2 | Club tier: Bronze, Silver, Gold, Platinum, Diamond |
| 27 | PlayerStatusID | int | DWH_dbo.Fact_SnapshotCustomer.PlayerStatusID | T2 | Player status FK |
| 28 | PlayerStatus | varchar(50) | DWH_dbo.Dim_PlayerStatus.Name (LEFT JOIN) | T2 | Player status label |
| 29 | RegulationID | int | DWH_dbo.Fact_SnapshotCustomer.RegulationID (INNER JOIN) | T2 | Regulation FK |
| 30 | Regulation | varchar(50) | DWH_dbo.Dim_Regulation.Name (INNER JOIN) | T2 | Regulatory regime |
| 31 | IsGermanBaFin | int | NULL (always) | T2 | Feature not implemented; set to NULL in SP |

### Balance Metrics (from eMoney_Fact_Transaction_Status + self-join)

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 32 | TotalBalance | numeric(38,4) | SUM(HolderAmount) from eMoney_Fact_Transaction_Status WHERE IsTxStatusCBRelevant=1, TxStatusModificationDateID < @DateID+1, TxStatusCreatedDateID < @DateID+1 | T2 | Cumulative all-time balance; equals ClosingBalance |
| 33 | OpeningBalance | numeric(38,4) | eMoney_Calculated_Balance.ClosingBalance WHERE BalanceDateID=@DateID_PreviousDay; ISNULL=0 | T2 | Self-join cascade: prior day's ClosingBalance |
| 34 | Correction | numeric(38,4) | #balance_gap (late-arriving txs: TxStatusCreatedDateID=@DateID AND TxStatusModificationDateID<@DateID) + (TotalBalance - #final.ClosingBalance) | T2 | Late-arriving transaction correction + TotalBalance reconciliation |
| 35 | BankingPaymentsIN | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID=7) from eMoney_Fact_Transaction_Status (TxStatusModificationDateID=@DateID, IsTxStatusCBRelevant=1) | T2 | PaymentReceived (FMO) daily delta |
| 36 | BankingPaymentsOut | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID=8) | T2 | Payment daily delta |
| 37 | CardActivity | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID IN (1,2,3,4,9)) | T2 | CardPayment, Contactless, OnlinePayment, CashWithdrawal, Refund |
| 38 | Loads | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID=5) | T2 | TransferReceived (FMI) |
| 39 | Unloads | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID=6) | T2 | Transfer |
| 40 | BalanceAdjustments | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID IN (11,12)) | T2 | CreditBA, DebitBA |
| 41 | Fee | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID=10) | T2 | Fee transactions |
| 42 | DirectDebit | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID=13) | T2 | DirectDebit |
| 43 | Unknown | numeric(38,4) | SUM(HolderAmount WHERE TxTypeID=0) | T2 | Unknown transaction type |
| 44 | TBD | numeric(38,4) | SUM(HolderAmount WHERE TxClientBalanceCategory='TBD') | T2 | Unmapped types incl. TxTypeID=14 (CryptoToFiat) |
| 45 | ClosingBalance | numeric(38,4) | TotalBalance (inserted directly as ClosingBalance) | T2 | Equals TotalBalance — cumulative all-time sum, NOT incremental daily close |
| 46 | ClosingBalanceUSDApprox | numeric(38,4) | #final.ClosingBalance (incremental: OpeningBalance + daily flows + Correction) × USDApproxRate; ISNULL=0 | T2 | USD-converted incremental closing balance (uses computed sum, not TotalBalance) |
| 47 | USDApproxRate | numeric(38,4) | (Ask+Bid)/2 from DWH_dbo.Fact_CurrencyPriceWithSplit JOIN eMoney_Currency_Instrument_Mapping_Static WHERE SellCurrencyID=1 | T2 | Mid-price USD rate for this account's currency |
| 48 | UpdateDate | datetime | GETDATE() | T2 | Row load timestamp |

---

## Tier Summary

| Tier | Count | % | Notes |
|------|-------|---|-------|
| T1 | 0 | 0% | No upstream FiatDwhDB wiki passthrough (Synapse-native aggregation from Fact_Transaction_Status) |
| T2 | 48 | 100% | All columns traced to SP_eMoney_Calculated_Balance code; CardID, ProviderCardID, IsGermanBaFin are always NULL |
| T4 | 0 | — | — |

*Object summary: 48-col daily per-account cumulative balance table; ~10 months stale (MaxDate=2025-06-09); HASH(CID) + CLUSTERED INDEX(BalanceDateID) + NCI(CurrencyBalanceID); sources eMoney_Fact_Transaction_Status (IsTxStatusCBRelevant=1) + eMoney_Dim_Account + DWH_dbo dimension tables; ClosingBalance = TotalBalance (cumulative all-time sum).*

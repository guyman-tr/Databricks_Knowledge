# Column Lineage: main.bi_output.bi_output_wf_view

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_wf_view` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_wf_view.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_wf_view.json` (rows: 18, mismatches: 18) |
| **Primary upstream** | `main.bi_db.bronze_wealth_france_wealth_france_users_data` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.bi_db.bronze_wealth_france_wealth_france_users_data` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_wealth_france_wealth_france_users_data.md` |
| `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit` | JOIN / referenced | ✗ `(no wiki found)` |

## Lineage Chain

```
main.bi_db.bronze_wealth_france_wealth_france_users_data   ←── primary upstream
  + main.bi_db.bronze_sub_accounts_accounts   (JOIN)
  + main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit   (JOIN)
        │
        ▼
main.bi_output.bi_output_wf_view   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `GCID` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `gcid` | `rename` | — | gcid AS GCID |
| 2 | `ClientID` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `ClientId` | `rename` | — | ClientId AS ClientID |
| 3 | `ContractNumber` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `contractNo` | `rename` | — | contractNo AS ContractNumber |
| 4 | `ProductCode` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `productCode` | `rename` | — | productCode AS ProductCode |
| 5 | `ProductName` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `productName` | `rename` | — | productName AS ProductName |
| 6 | `SubscriptionDate` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `subscriptionDate` | `rename` | — | subscriptionDate AS SubscriptionDate |
| 7 | `ContractStatus` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `contractStatus` | `rename` | — | contractStatus AS ContractStatus |
| 8 | `ReferenceCurrency` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `referenceCurrency` | `rename` | — | referenceCurrency AS ReferenceCurrency |
| 9 | `SavingValue` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `savingsValue` | `rename` | — | savingsValue AS SavingValue |
| 10 | `SavingValueInDollar` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `—` | `arithmetic` | — | ((Bid + Ask) / 2) * savingsValue AS SavingValueInDollar |
| 11 | `SavingsValueDate` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `savingsValueDate` | `rename` | — | savingsValueDate AS SavingsValueDate |
| 12 | `ISIN` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `isin` | `rename` | — | isin AS ISIN |
| 13 | `Percent` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `percent` | `rename` | — | percent AS Percent |
| 14 | `Amount` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `amount` | `rename` | — | amount AS Amount |
| 15 | `AmountInDollar` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `—` | `arithmetic` | — | ((Bid + Ask) / 2) * amount AS AmountInDollar |
| 16 | `NumberOfShares` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `numberOfShares` | `rename` | — | numberOfShares AS NumberOfShares |
| 17 | `Currency` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `currency` | `rename` | — | currency AS Currency |
| 18 | `ExchangeRate` | `main.bi_db.bronze_wealth_france_wealth_france_users_data` | `—` | `unknown` | — | ((Bid + Ask) / 2) AS ExchangeRate |

## Cross-check vs system.access.column_lineage

- Total target columns: **18**
- OK: **0**, WARN: **15**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `GCID` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.gcid` | `main.bi_db.bronze_sub_accounts_accounts.gcid` | WARN |
| `ClientID` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.clientid` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `ContractNumber` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.contractno` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `ProductCode` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.productcode` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `ProductName` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.productname` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `SubscriptionDate` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.subscriptiondate` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `ContractStatus` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.contractstatus` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `ReferenceCurrency` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.referencecurrency` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `SavingValue` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.savingsvalue` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `SavingValueInDollar` | — | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id`, `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit.ask`, `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit.bid` | ERROR |
| `SavingsValueDate` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.savingsvaluedate` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `ISIN` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.isin` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `Percent` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.percent` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `Amount` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.amount` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `AmountInDollar` | — | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id`, `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit.ask`, `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit.bid` | ERROR |
| `NumberOfShares` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.numberofshares` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `Currency` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.currency` | `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_creation_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.file_name`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.insert_date`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.json_text`, `main.bi_db.bronze_wealth_france_wealth_france_users_data.running_id` | WARN |
| `ExchangeRate` | — | `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit.ask`, `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit.bid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN bi_db.bronze_sub_accounts_accounts AS ac ON q0.ClientId = ac.accountId
- `LEFT JOIN` — LEFT JOIN main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit AS cws ON q0.savingsValueDate = cws.etr_ymd AND cws.InstrumentID = 1

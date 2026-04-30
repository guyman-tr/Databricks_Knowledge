# Billing.WireTransferBanks

> Wire transfer bank registry. Each row represents one bank available for wire transfer deposits, linked to a specific payment depot, with a default currency, display visibility, and ordering rank. 16 banks including Banking Circle, JPMorgan, Deutsche Bank, Customers Bank, and historical entries. Parent table for Billing.WireTransferBankInfo which holds full banking details (IBAN, SWIFT, routing numbers, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY(1,1) PRIMARY KEY CLUSTERED |
| **Row Count** | 16 rows |
| **Partition** | N/A - filegroup PRIMARY |
| **Indexes** | 1 CLUSTERED PK on ID |

---

## 1. Business Meaning

`Billing.WireTransferBanks` is the master list of banks available for wire transfer payments. Each entry represents a banking relationship eToro uses to receive wire transfer deposits. The `DepotID` links the bank to its corresponding payment depot in `Billing.Depot`, and `DefaultCurrencyID` defines the primary currency for that bank.

Customers selecting wire transfer as a payment method see banks where `IsVisible=true` (7 currently), ordered by `Rank`. The full banking details needed to execute the transfer (account number, SWIFT/BIC, IBAN, sort code, etc.) are stored in the child table `Billing.WireTransferBankInfo`, joined via `WireTransferBanks.ID = WireTransferBankInfo.BankID`.

**Note**: ID is IDENTITY but has a gap (no ID=11). NOT FOR REPLICATION on IDENTITY.

---

## 2. Live Data

| ID | BankName | DepotID | DefaultCurrencyID | IsVisible | Rank |
|----|----------|---------|-------------------|-----------|------|
| 0 | Not Defined | 10 | 1 (USD) | false | 1 |
| 1 | Baclays Bank | 48 | 1 (USD) | false | 1 |
| 2 | Wirecard | 49 | 2 (EUR) | false | 1 |
| 3 | Sberbank | 51 | 37 (RUB) | **true** | 1 |
| 4 | Westpac | 50 | 5 (AUD) | false | 1 |
| 5 | Zotopay-Cashu | 52 | 1 (USD) | false | 1 |
| 6 | Zotopay-Cup | 53 | 38 (CNY) | false | 1 |
| 7 | Coutts | 57 | 1 (USD) | **true** | 1 |
| 8 | National Australia Bank | 70 | 5 (AUD) | **true** | 1 |
| 9 | Silvergate | 74 | 1 (USD) | **true** | 1 |
| 10 | Banking Circle | 105 | 1 (USD) | **true** | 1 |
| 12 | JPMorgan | 106 | 5 (AUD) | **true** | 1 |
| 13 | Deutsche Bank | 108 | 2 (EUR) | **true** | 2 |
| 14 | Customers Bank | 163 | 1 (USD) | **true** | 1 |
| 15 | Marsheq | 168 | 349 | false | 1 |
| 16 | DBS bank Singapore | 171 | 43 (SGD) | false | 1 |

7 visible banks; 9 historical/inactive. Rank=1 is primary, Rank=2 is secondary (Deutsche Bank).

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **ID** | int IDENTITY(1,1) | NOT NULL | Auto | - | [CODE-BACKED] Surrogate PK. Referenced as `BankID` in `Billing.WireTransferBankInfo` for the parent-child join. NOT FOR REPLICATION. |
| **BankName** | nvarchar(30) | NULL | - | - | [CODE-BACKED] Short display name of the bank. Shown in customer-facing bank selection UI. Examples: "Banking Circle", "JPMorgan", "Deutsche Bank". |
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) | [CODE-BACKED] The payment depot associated with this bank. Explicit FK. Connects the bank to its processing gateway configuration. |
| **DefaultCurrencyID** | int | NOT NULL | - | Dictionary.Currency(CurrencyID) [implicit] | [CODE-BACKED] The primary/default currency for this bank. Used when customer selects this bank without specifying currency. No explicit FK constraint. |
| **IsVisible** | bit | NOT NULL | (1) | - | [CODE-BACKED] Whether this bank is shown to customers. 7 visible, 9 hidden. Default true. Historical banks set to false. |
| **Rank** | int | NOT NULL | - | - | [CODE-BACKED] Display ordering rank. Lower values shown first. All banks Rank=1 except Deutsche Bank (Rank=2). Used in bank selection UI ordering. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_Billing.WireTransferBanks | CLUSTERED | ID ASC | No FILLFACTOR specified. |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.GetWireTransferBankDetails` | Returns full bank details by joining WireTransferBanks -> WireTransferBankInfo filtered by BankID, CurrencyID, RegulationID |
| `Billing.WireTransferBankDetailsGet` | Alternative bank details reader |
| `Billing.GetDepotIdByWireTransferBankInfo` | Resolves DepotID from bank + currency info |
| `Billing.GetWireDepotIdsByRegulationAndCurrency` | Lists depot IDs for wire transfer by regulation + currency |
| `Billing.GetBankIDByRegulation` | Resolves BankID from regulation context |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Depot | Many-to-one | WireTransferBanks.DepotID = Depot.DepotID | Explicit FK. |
| Billing.WireTransferBankInfo | One-to-many | WireTransferBanks.ID = WireTransferBankInfo.BankID | Child table with IBAN, SWIFT, routing numbers, beneficiary details per (bank, currency, regulation). |
| Dictionary.Currency | Many-to-one | WireTransferBanks.DefaultCurrencyID = Currency.CurrencyID | Implicit (no FK). |

---

*Quality: 9.0/10 | 6 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,9,11*

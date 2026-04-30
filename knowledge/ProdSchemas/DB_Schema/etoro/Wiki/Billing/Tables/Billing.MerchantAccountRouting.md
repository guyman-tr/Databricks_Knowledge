# Billing.MerchantAccountRouting

> Merchant account routing table. Each row maps a combination of payment context dimensions (depot, mode, regulation, currency, payment type, country, sub-type) to a specific MerchantAccountID. The application joins this to Billing.MerchantAccountValues to retrieve the actual API credentials for the selected merchant account. 645 routing rules; 94.9% Demo mode.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY(1,1) PRIMARY KEY CLUSTERED; UNIQUE constraint on all 7 routing dimensions |
| **Row Count** | 645 rows |
| **Partition** | N/A - filegroup PRIMARY |
| **Indexes** | 1 CLUSTERED PK on ID; 1 NONCLUSTERED UNIQUE on routing dimensions (FILLFACTOR=95) |

---

## 1. Business Meaning

`Billing.MerchantAccountRouting` is the first half of a two-table merchant account system. It answers the question: "Given these payment context dimensions, which merchant account should I use?" The result (MerchantAccountID) is then passed to `Billing.MerchantAccountValues` to get the actual credentials.

**Use case**: When processing a deposit via depot 92 (Checkout.com) in Demo mode, under CySEC regulation, for any currency, any payment type, from any country - route to MerchantAccountID=1 (EU LTD Checkout key). If the customer is from a specific country (CountryID=13), route to a different merchant account instead.

**Wildcard dimensions**: CurrencyID=0, PaymentTypeID=0, CountryID=0, SubTypeID=0 all mean "match any". Country-specific rules (CountryID!=0) take precedence over generic rules (CountryID=0) via MAX(CountryID) selection in `GetMerchantValues`.

**Distribution**:
- DepotModeID=2 (Demo): 612 rows (94.9%)
- DepotModeID=1 (Live): 33 rows (5.1%)

**Note**: Live data shows a `Trace` column in query results that is not present in the SSDT DDL file - this column was likely added to the database after the SSDT was last updated. It stores JSON metadata about the last modification (hostname, app, user, SPID).

---

## 2. Business Logic

### 2.1 Merchant Account Resolution (GetMerchantValues)

**Procedure**: `Billing.GetMerchantValues(@DepotID, @DepotModeID, @RegulationID, @CurrencyID=0, @PaymentTypeID=0, @BinCode=NULL, @SubTypeID=0, @CountryID=0)`

**Resolution algorithm**:
1. Find all routing rows matching (DepotID, DepotModeID, RegulationID) AND CurrencyID IN (@CurrencyID, 0) AND SubTypeID = @SubTypeID
2. For CountryID: if BinCode provided, resolve to a country via Dictionary.CountryBin; else use @CountryID. Match CountryID exactly OR CountryID=0 (wildcard)
3. Join to MerchantAccountValues to get parameter values
4. Return values where CountryID = MAX(CountryID) from results - i.e., prefer country-specific rules over generic (0) rules

**V2 procedure**: `Billing.GetMerchantValues_V2` - enhanced version with same logic

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **ID** | int IDENTITY(1,1) | NOT NULL | Auto | - | [CODE-BACKED] Surrogate PK. NOT FOR REPLICATION. Physical clustered key. |
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) [implicit] | [CODE-BACKED] Payment depot dimension. No explicit FK. All 645 rows use DepotID=92 (Checkout.com) in first 5 rows - routing table is depot-specific. |
| **DepotModeID** | int | NOT NULL | - | Dictionary.DepotMode(DepotModeID) [implicit] | [CODE-BACKED] Mode dimension. 1=Live (33 rows), 2=Demo (612 rows). No explicit FK. |
| **RegulationID** | int | NOT NULL | - | Dictionary.Regulation(ID) [implicit] | [CODE-BACKED] Regulatory entity dimension (CySEC=1, FCA=2, ASIC=4, etc.). No explicit FK. |
| **CurrencyID** | int | NOT NULL | - | Dictionary.Currency(CurrencyID) [implicit] | [CODE-BACKED] Currency dimension. 0=any currency (wildcard). No explicit FK. |
| **PaymentTypeID** | int | NOT NULL | - | - | [CODE-BACKED] Payment type dimension. 0=any payment type (wildcard). Differentiates routing for deposit vs withdrawal or different payment flows. |
| **CountryID** | int | NOT NULL | - | Dictionary.Country(CountryID) [implicit] | [CODE-BACKED] Customer country dimension. 0=any country (wildcard). Country-specific rules (non-zero) take precedence over wildcards. No explicit FK. |
| **SubTypeID** | int | NOT NULL | - | - | [CODE-BACKED] Sub-type dimension. 0=default. Matches SubTypeID in ProtocolMIDSettings for sub-routing variants. |
| **MerchantAccountID** | int | NOT NULL | - | Billing.MerchantAccountValues(MerchantAccountID) [implicit] | [CODE-BACKED] The resolved merchant account for this routing combination. Joined to MerchantAccountValues to get credentials. |
| **Description** | varchar(100) | NULL | - | - | [NAME-INFERRED] Human-readable label for this routing rule (e.g., which processor/account). NULL in most rows. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_Billing.MerchantAccountRouting | CLUSTERED | ID ASC | FILLFACTOR=95. |
| UQ_MerchantAccountRouting | NONCLUSTERED UNIQUE | (DepotID, DepotModeID, RegulationID, CurrencyID, PaymentTypeID, CountryID, SubTypeID, MerchantAccountID) | FILLFACTOR=95. Prevents duplicate routing rules. |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.GetMerchantValues` | Resolves MerchantAccountID then returns parameter values; country-specific rules win |
| `Billing.GetMerchantValues_V2` | Enhanced version of the same lookup |
| `Billing.GetMerchantValuesByDeposit` | Resolves by DepositID context |
| `Billing.GetMerchantValuesByMerchantID` | Direct lookup by MerchantAccountID |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.MerchantAccountValues | One-to-many | MerchantAccountRouting.MerchantAccountID = MerchantAccountValues.MerchantAccountID | Implicit. Join to get credentials for the selected merchant account. |
| Billing.ProtocolMIDSettings | Sibling | ProtocolMIDSettings.MerchantAccountID = MerchantAccountRouting.MerchantAccountID | 377 ProtocolMIDSettings rows reference a MerchantAccountID - same merchant account system. |

---

*Quality: 9.1/10 | 9 CODE-BACKED, 1 NAME-INFERRED | Phases: 1,2,3,5,6,8,9,11*

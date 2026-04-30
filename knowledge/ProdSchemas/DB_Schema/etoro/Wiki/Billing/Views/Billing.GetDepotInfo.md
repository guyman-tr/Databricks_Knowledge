# Billing.GetDepotInfo

> Complete depot information view joining payment gateway configuration (Billing.Depot), per-currency processing stats (Billing.DepotToCurrency), and protocol class names (Dictionary.Protocol) - returns all active and inactive depot-currency pairs without filtering.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | (DepotID, CurrencyID) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GetDepotInfo` answers the question "what are all configured payment gateways and which currencies do they support, along with their processing history?" It joins each depot (payment gateway endpoint) with its supported currencies and the protocol class name used to instantiate the payment handler.

Unlike `Billing.GetDefaultTerminalForBank` and `Billing.GetTerminalWithBankBinCode` (which filter to IsActive=1 for live routing decisions), this view returns ALL depot-currency pairs including inactive ones (105 of 346 rows are inactive). This makes it suitable for depot management, reporting, and administrative queries where the full configuration history is needed.

`ProcessedAmount` and `LastTransactionDate` from `Billing.DepotToCurrency` provide per-depot-per-currency processing statistics, enabling monitoring of payment gateway utilisation and identifying dormant or retired gateways.

The view is consumed by `Billing.GetCustomerDepositInfo` to look up depot details for specific deposit records, regardless of current active state.

---

## 2. Business Logic

### 2.1 No Active State Filter - All Depots Returned

**What**: Unlike routing views, this view does NOT filter by IsActive - it returns all configured depot-currency combinations.

**Columns/Parameters Involved**: `IsActive`

**Rules**:
- No WHERE IsActive=1 clause is applied
- IsActive is included in the SELECT for callers to filter as needed
- 241 active rows and 105 inactive rows are returned (346 total)
- Inactive depots include retired gateways (e.g., MoneyGram, last transaction 2013) that still have historical data
- Callers requiring only active depots must add `WHERE IsActive = 1`

### 2.2 Old-Style Comma Join Syntax

**What**: The view uses ANSI-89 implicit join syntax (comma-separated tables in FROM with equi-joins in WHERE).

**Columns/Parameters Involved**: `DepotID`, `ProtocolID`

**Rules**:
- `FROM Billing.Depot BDEP, Billing.DepotToCurrency BD2C, Dictionary.Protocol DPRT`
- `WHERE BDEP.DepotID = BD2C.DepotID AND BDEP.ProtocolID = DPRT.ProtocolID`
- Functionally equivalent to INNER JOINs on both conditions
- A depot with no currency entries in DepotToCurrency will not appear (inner join semantics)
- A depot with no matching protocol will not appear (inner join semantics)
- Results are one row per (depot, currency) combination - a multi-currency depot generates multiple rows

### 2.3 Per-Currency Processing Statistics

**What**: ProcessedAmount and LastTransactionDate track cumulative payment volume per depot-currency pair.

**Columns/Parameters Involved**: `ProcessedAmount`, `LastTransactionDate`

**Rules**:
- Sourced from `Billing.DepotToCurrency` - maintained by the billing processing engine
- `ProcessedAmount`: cumulative amount processed through this depot in this currency (in the currency's minor units or major units - context-dependent)
- `LastTransactionDate`: timestamp of the most recent transaction through this depot-currency pair
- `LastTransactionDate = 2000-01-01 00:00:00` indicates no transactions were ever processed (default/initialization value)
- Used to identify active vs dormant gateway-currency combinations beyond the IsActive flag

---

## 3. Data Overview

| DepotID | Name | FundingTypeID | CurrencyID | ProcessedAmount | LastTransactionDate | ClassKey | IsActive | Meaning |
|---------|------|--------------|------------|-----------------|---------------------|----------|----------|---------|
| 1 | MoneyBookers USD | 8 | 1 (USD) | 124,479,812 | 2025-01-15 | MoneyBookersPaymentDll | true | Active Skrill/MoneyBookers gateway, USD, significant volume |
| 1 | MoneyBookers USD | 8 | 4 | 200,000 | 2009-01-07 | MoneyBookersPaymentDll | true | Same gateway, legacy currency, minimal old volume |
| 2 | MoneyGram | 9 | 1 (USD) | 3,207 | 2013-02-28 | MoneyGramPaymentDll | false | Retired gateway, last processed 2013, IsActive=false |
| 2 | MoneyGram | 9 | 3 (GBP) | 0 | 2000-01-01 | MoneyGramPaymentDll | false | Retired gateway, never processed GBP, default date |
| 3 | WebMoney | 10 | 1 (USD) | 3,863,856 | 2020-02-10 | WebMoneyPaymentDll | true | Active WebMoney gateway, USD only |

**Row count**: 346 (all depot-currency combinations, active and inactive)

**IsActive distribution**: 241 active (70%) / 105 inactive (30%)

**Top FundingTypes by row count**:
- FundingTypeID=1 (CreditCard): 106 rows - most currency coverage (multi-currency credit card gateways)
- FundingTypeID=27: 56 rows
- FundingTypeID=2 (WireTransfer): 55 rows
- FundingTypeID=28: 19 rows
- FundingTypeID=3 (PayPal): 14 rows
- FundingTypeID=8 (MoneyBookers/Skrill): 14 rows

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepotID | int | NO | - | CODE-BACKED | Payment depot (gateway endpoint) identifier. PK of Billing.Depot. Central join key - each DepotID can appear multiple times (once per supported currency). FK to Billing.Depot. |
| 2 | ProtocolID | int | NO | - | CODE-BACKED | Payment processing protocol. From Billing.Depot. References Dictionary.Protocol. Identifies which payment SDK/DLL handles this depot's transactions. Multiple depots may share a protocol. |
| 3 | PaymentTypeID | int | NO | - | CODE-BACKED | Payment direction type. From Billing.Depot. 1=Deposit/both directions (all sample data shows PaymentTypeID=1). May distinguish deposit-only vs withdrawal-only vs bidirectional gateways. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Supported currency for this depot. From Billing.DepotToCurrency. One row per (depot, currency) combination. References Dictionary.Currency. 1=USD, 2=EUR, 3=GBP, etc. CreditCard depots (FundingTypeID=1) have the broadest currency coverage. |
| 5 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method category. From Billing.Depot. References Dictionary.FundingType. 1=CreditCard (largest group, 106 rows), 2=WireTransfer, 3=PayPal, 8=MoneyBookers/Skrill, 10=WebMoney, 27/28=newer payment methods. |
| 6 | Name | nvarchar | NO | - | CODE-BACKED | Human-readable depot name. From Billing.Depot. Unique identifier for the gateway endpoint (e.g., "MoneyBookers USD", "MoneyGram", "WebMoney"). Used in admin UIs, reports, and logging. |
| 7 | ProcessedAmount | money | YES | - | CODE-BACKED | Cumulative amount processed through this depot in this currency. From Billing.DepotToCurrency. Updated by the billing engine as transactions are processed. 0 or default date (2000-01-01) indicates no historical transactions. Used to assess gateway utilisation and volume. |
| 8 | LastTransactionDate | datetime | YES | - | CODE-BACKED | Timestamp of the most recent transaction through this depot-currency pair. From Billing.DepotToCurrency. Default value 2000-01-01 indicates the depot-currency was configured but never used. Used to identify dormant gateways. |
| 9 | ClassKey | nvarchar | YES | - | CODE-BACKED | Protocol handler class name from Dictionary.Protocol. String identifier used by the payment processing engine to instantiate the correct DLL/handler (e.g., "MoneyBookersPaymentDll", "MoneyGramPaymentDll", "WebMoneyPaymentDll"). NULL if protocol has no ClassKey. |
| 10 | IsActive | bit | NO | - | CODE-BACKED | Current active status of the depot. From Billing.Depot. 1=active (241 rows, 70%), 0=inactive/retired (105 rows, 30%). NOTE: this view does NOT pre-filter on IsActive - callers must add WHERE IsActive=1 if only operational depots are needed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepotID, ProtocolID, PaymentTypeID, FundingTypeID, Name, IsActive | Billing.Depot | Source (FROM anchor, no active filter) | All depot configurations including inactive |
| DepotID, CurrencyID, ProcessedAmount, LastTransactionDate | Billing.DepotToCurrency | Source (JOIN on DepotID) | Per-currency processing statistics for each depot |
| ProtocolID, ClassKey | Dictionary.Protocol | Source (JOIN on ProtocolID) | Payment protocol class name for handler instantiation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCustomerDepositInfo | DepotID, Name, ClassKey, ... | Reference (JOIN on DepotID) | Looks up depot details for customer deposit records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepotInfo (view)
├── Billing.Depot (table)
├── Billing.DepotToCurrency (table)
└── Dictionary.Protocol (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Depot | Table | FROM anchor: DepotID, ProtocolID, PaymentTypeID, FundingTypeID, Name, IsActive - all depots, no active filter |
| Billing.DepotToCurrency | Table | JOIN on DepotID: CurrencyID, ProcessedAmount, LastTransactionDate - per-currency stats |
| Dictionary.Protocol | Table | JOIN on ProtocolID: ClassKey for payment handler instantiation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCustomerDepositInfo | Stored Procedure | Joins on DepotID to retrieve depot name and protocol for deposit records |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Uses ANSI-89 comma-join style. All join conditions use PK/FK columns (DepotID, ProtocolID) which are indexed in their base tables. 346 rows - small result set, no performance concerns.

### 7.2 Constraints

N/A for view. No SCHEMABINDING (cross-schema). Uses old-style comma join syntax - functionally equivalent to INNER JOIN but less explicit. No active-state filter: returns both active (241) and inactive (105) depot-currency pairs. No NO LOCK hint in the view definition - callers may wish to add WITH (NOLOCK) for read consistency.

---

## 8. Sample Queries

### 8.1 Get all active depots with their currency support

```sql
SELECT DepotID, Name, FundingTypeID, CurrencyID, ClassKey, ProcessedAmount, LastTransactionDate
FROM Billing.GetDepotInfo WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY DepotID, CurrencyID
```

### 8.2 Find depots by funding type with processing stats

```sql
SELECT DepotID, Name, CurrencyID, ProcessedAmount, LastTransactionDate
FROM Billing.GetDepotInfo WITH (NOLOCK)
WHERE FundingTypeID = @FundingTypeID
  AND IsActive = 1
ORDER BY ProcessedAmount DESC
```

### 8.3 Identify dormant gateways (no recent transactions)

```sql
SELECT DepotID, Name, FundingTypeID, MAX(LastTransactionDate) AS MostRecentTransaction
FROM Billing.GetDepotInfo WITH (NOLOCK)
WHERE IsActive = 1
GROUP BY DepotID, Name, FundingTypeID
HAVING MAX(LastTransactionDate) < DATEADD(YEAR, -1, GETDATE())
ORDER BY MostRecentTransaction
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetDepotInfo | Type: View | Source: etoro/etoro/Billing/Views/Billing.GetDepotInfo.sql*

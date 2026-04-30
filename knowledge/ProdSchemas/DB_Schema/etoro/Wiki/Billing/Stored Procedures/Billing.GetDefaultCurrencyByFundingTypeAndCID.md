# Billing.GetDefaultCurrencyByFundingTypeAndCID

> Returns the recommended default deposit currency for each active funding type for a customer, prioritizing their most recently used currency, then their country's regional default, then the funding type's global default.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set: (FundingTypeID, CurrencyID) - one row per active funding type |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDefaultCurrencyByFundingTypeAndCID` determines the best default currency to pre-select in the deposit UI for each available payment method (funding type). When a customer opens the deposit page, the system needs to suggest a currency for each payment option. This procedure implements a three-tier fallback chain to find the most relevant currency: (1) the currency the customer last used with that payment method, (2) the regional default currency for the customer's country if the depot supports it, (3) the funding type's global default currency.

Without this procedure, the deposit UI would either always show a hardcoded default currency (ignoring user history and geography) or require the application to perform multiple round-trips to reconstruct this logic. The procedure encapsulates the full prioritization decision in a single DB call.

It is called by `Billing.GetCustomerDepositInfo` as part of assembling the full deposit setup package for a customer session. It also has execute permission for the `DepositSetupUser` database user, indicating it is invoked during the deposit flow initialization.

---

## 2. Business Logic

### 2.1 Three-Tier Currency Selection Priority

**What**: For each active funding type, the currency is chosen via a three-tier priority: (1) last used by the customer, (2) regional default for the country if the depot supports it, (3) funding type global default.

**Columns/Parameters Involved**: `@CID`, `Billing.Deposit.CurrencyID`, `Billing.Deposit.PaymentDate`, `Dictionary.FundingType.DefaultCurrency`, `Dictionary.Country.DefaultCurrencyID`, `Billing.DepotToCurrency.CurrencyID`, `Billing.DepotToCurrency.IsActive`

**Rules**:
- **Tier 1 (History-based)**: Find the most recent approved or any-status deposit (`Billing.Deposit`) joined to `Billing.Funding` for the customer. Use `ROW_NUMBER() OVER (PARTITION BY FundingTypeID ORDER BY PaymentDate DESC)` to get the latest deposit per funding type. If found, `CurrencyID` comes from that deposit.
- **Tier 2 (Regional default)**: If no deposit history for a funding type (CurrencyID still NULL after Tier 1), check if the customer's country default currency (`Dictionary.Country.DefaultCurrencyID` via `Customer.CustomerStatic`) is supported by any active depot for that funding type (`Billing.DepotToCurrency WHERE IsActive=1`). If yes, use the regional currency.
- **Tier 3 (Funding type global default)**: If neither Tier 1 nor Tier 2 applies (depot does not support regional currency), use `Dictionary.FundingType.DefaultCurrency`.
- Only active funding types (`Dictionary.FundingType.IsFundingTypeActive = 1`) are returned.
- `MAXDOP 1` hints prevent parallelism issues with temp table `@RES` updates.

**Diagram**:
```
@CID
  |
  v
Step 1: Find all active FundingTypes
  |
  +-- LEFT JOIN most recent deposit per FundingType (ROW_NUMBER by PaymentDate DESC)
  |     -> Tier 1: CurrencyID from deposit history (most recently used currency)
  |
  v
Step 2: Get customer's regional default currency
  CustomerStatic.CountryID -> Dictionary.Country.DefaultCurrencyID = @DefaultCurrencyPerRegion
  |
  v
Step 3: Fill NULL CurrencyIDs (no deposit history for that FundingType)
  |
  +-- Does any active depot for this FundingType support @DefaultCurrencyPerRegion?
  |     YES -> CurrencyID = @DefaultCurrencyPerRegion        (Tier 2)
  |     NO  -> CurrencyID = Dictionary.FundingType.DefaultCurrency (Tier 3)
  |
  v
SELECT * FROM @RES  (FundingTypeID, CurrencyID)
```

### 2.2 Active Funding Type Scope

**What**: The procedure only returns active funding types - deactivated payment methods are excluded from the result set.

**Columns/Parameters Involved**: `Dictionary.FundingType.IsFundingTypeActive`

**Rules**:
- Filter `IsFundingTypeActive = 1` is applied in both the history CTE and the final active funding types CTE
- Inactive funding types (e.g., retired payment methods) do not appear in the result set
- Result set size equals the number of currently active funding types, regardless of customer deposit history

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used to filter `Billing.Deposit.CID` for deposit history and `Customer.CustomerStatic.CID` for country/region lookup. |
| 2 | FundingTypeID (output) | INT | NO | - | CODE-BACKED | The active funding type ID. One row per active funding type in `Dictionary.FundingType`. Identifies the payment method (e.g., 1=CreditCard, 2=WireTransfer). |
| 3 | CurrencyID (output) | INT | YES | - | CODE-BACKED | The recommended default currency ID for this funding type for this customer. Null only if no tier resolved (should not occur for active funding types with a DefaultCurrency defined). Resolved via three-tier fallback: deposit history -> regional default -> funding type global default. References `Dictionary.Currency`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | Retrieves deposit history to find last-used currency per funding type |
| @CID | Customer.CustomerStatic.CID | Lookup | Retrieves customer's CountryID for regional currency resolution |
| FundingID | Billing.Funding.FundingID | JOIN | Links deposit to funding record to get FundingTypeID |
| FundingTypeID | Dictionary.FundingType.FundingTypeID | Lookup | Gets active funding types and their DefaultCurrency |
| CountryID | Dictionary.Country.CountryID | Lookup | Gets DefaultCurrencyID for the customer's country |
| DepotID | Billing.Depot.DepotID | JOIN | Links depots to currency support table |
| (CurrencyID, IsActive) | Billing.DepotToCurrency | Lookup | Checks whether a depot supports the regional default currency |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCustomerDepositInfo | EXEC call | Procedure caller | Calls this SP as part of assembling the full deposit page data package |
| DepositSetupUser | GRANT EXECUTE | Permission | Called during deposit flow initialization by the deposit setup service |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin user has execute access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDefaultCurrencyByFundingTypeAndCID (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
├── Customer.CustomerStatic (table)
├── Dictionary.Country (table)
├── Billing.Depot (table)
└── Billing.DepotToCurrency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ - deposit history per customer; provides CurrencyID and PaymentDate for most-recent-currency logic |
| Billing.Funding | Table | READ - JOIN with Deposit on FundingID to obtain FundingTypeID |
| Dictionary.FundingType | Table | READ - source of all active funding types and their DefaultCurrency fallback |
| Customer.CustomerStatic | Table | READ - provides CountryID for regional currency lookup |
| Dictionary.Country | Table | READ - provides DefaultCurrencyID for the customer's country |
| Billing.Depot | Table | READ - depot records for the funding type |
| Billing.DepotToCurrency | Table | READ - checks whether a depot supports the regional currency (IsActive=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCustomerDepositInfo | Stored Procedure | Calls this SP to include per-funding-type currency recommendations in deposit info response |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MAXDOP 1 | Query hint | Applied to both main SELECTs to avoid parallel plan issues with temp table @RES updates |
| SET NOCOUNT ON | Setting | Suppresses row-count messages |
| TRY/CATCH with THROW | Error handling | Any runtime error is re-thrown to the caller |

---

## 8. Sample Queries

### 8.1 Get recommended currencies for a customer's deposit page

```sql
EXEC Billing.GetDefaultCurrencyByFundingTypeAndCID @CID = 12345;
```

### 8.2 Inline equivalent - find last-used currency per funding type for a customer

```sql
SELECT
    F.FundingTypeID,
    D.CurrencyID,
    D.PaymentDate,
    ROW_NUMBER() OVER (PARTITION BY F.FundingTypeID ORDER BY D.PaymentDate DESC) AS RowNum
FROM Billing.Deposit D WITH (NOLOCK)
INNER JOIN Billing.Funding F WITH (NOLOCK) ON D.FundingID = F.FundingID
INNER JOIN Dictionary.FundingType FT WITH (NOLOCK) ON FT.FundingTypeID = F.FundingTypeID
WHERE D.CID = 12345
  AND FT.IsFundingTypeActive = 1;
```

### 8.3 Find customer's country default currency

```sql
SELECT
    CS.CID,
    CS.CountryID,
    C.DefaultCurrencyID
FROM Customer.CustomerStatic CS WITH (NOLOCK)
INNER JOIN Dictionary.Country C WITH (NOLOCK) ON CS.CountryID = C.CountryID
WHERE CS.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Deposit Setup - Trading Eligible Payment Method Types](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13965492225) | Confluence | Describes the deposit setup flow and payment method types; context for active funding type selection (IsFundingTypeActive) |
| [Deposit Info Current Structure and Data](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11701716456) | Confluence | Documents deposit info structure; confirms this SP is part of deposit page initialization |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Billing.GetDefaultCurrencyByFundingTypeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDefaultCurrencyByFundingTypeAndCID.sql*

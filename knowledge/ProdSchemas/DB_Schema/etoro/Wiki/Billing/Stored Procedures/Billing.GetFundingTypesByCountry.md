# Billing.GetFundingTypesByCountry

> Returns the ordered list of available payment methods for a given country, including which currencies each method supports via depot routing, and bank pre-fill data for iDEAL.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CountryID - primary filter; returns ranked funding types for that country |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetFundingTypesByCountry` is the core payment method availability lookup used by the deposit initiation flow. Given a country ID, it returns every payment method available in that country (from `Billing.FundingTypeCountries`), enriched with the supported currency IDs for each method (from `Billing.Depot` and `Billing.DepotToCurrency`), and ordered by display rank.

The procedure exists to answer the fundamental deposit question: "Which payment methods can this customer use, and in which currencies?" It is the primary consumer of `Billing.FundingTypeCountries` (confirmed in that table's documentation) and is called by `Billing.GetCustomerDepositInfo`, the high-level deposit initialization procedure.

Data flows outward only - the procedure is read-only. The optional `@CID` parameter is exclusively used for iDEAL (FundingTypeID=34) bank pre-fill; for all other payment methods the customer ID is irrelevant and NULL is acceptable.

---

## 2. Business Logic

### 2.1 Country-Funding Availability Filter

**What**: Only payment methods explicitly configured for the given country in `Billing.FundingTypeCountries` are returned. The `Rank` column controls display order.

**Columns/Parameters Involved**: `@CountryID`, `ft.CountryID`, `ft.Rank`

**Rules**:
- `Billing.FundingTypeCountries` has 1,276 rows spanning up to 18 funding types per country
- A funding type absent from FundingTypeCountries for the requested country is NOT returned, even if it is globally active
- Results are ordered by `ft.Rank ASC` - lower rank appears first in the UI payment method selector

**Diagram**:
```
@CountryID = 74 (UK)
         |
WHERE ft.CountryID = 74
         |
FundingTypeCountries rows matching UK -> ordered by Rank
         |
Result: FundingTypeID=1(Rank=1), FundingTypeID=7(Rank=2), FundingTypeID=6(Rank=3), ...
```

### 2.2 Depot-Currency Discovery (INNER JOIN Exclusion)

**What**: The CTE `CurrencyPerFunding` resolves which currencies each funding type can process, based on the payment gateway (depot) routing configuration. An INNER JOIN ensures that only funding types WITH depot routing entries appear in the result.

**Columns/Parameters Involved**: `Billing.Depot.FundingTypeID`, `Billing.DepotToCurrency.CurrencyID`, `CurrencyIDs` output column

**Rules**:
- Billing.Depot to Billing.DepotToCurrency join builds (FundingTypeID, CurrencyID) pairs from gateway routing config
- The subquery uses STUFF + FOR XML PATH (pre-STRING_AGG) to aggregate CurrencyIDs into a comma-delimited string per funding type
- The INNER JOIN with this subquery means: if a funding type has NO depot routing at all (no rows in Depot/DepotToCurrency), it is EXCLUDED from results even if present in FundingTypeCountries
- `CurrencyIDs` in the result contains the ordered CSV (e.g., "1,2,3") of Dictionary.Currency IDs this method can process

**Diagram**:
```
Billing.Depot                    Billing.DepotToCurrency
(FundingTypeID, DepotID)   JOIN  (DepotID, CurrencyID)
         |                               |
         +--> CurrencyPerFunding CTE: DISTINCT (FundingTypeID, CurrencyID)
                              |
         Subquery: GROUP BY FundingTypeID -> STUFF(...FOR XML PATH)
                              |
         Result CurrencyIDs: "1,2,3" per FundingTypeID
```

### 2.3 iDEAL Special Case (FundingTypeID=34)

**What**: iDEAL is a Dutch bank payment method (available in ~2 countries). It requires customer-specific extra data - the customer's most recently used bank (BIC and name) - to pre-populate withdrawal forms. This is handled by a conditional call to `Billing.GetFundingExtraData`.

**Columns/Parameters Involved**: `@CID`, `ExtraData` output column, `FundingTypeID=34`

**Rules**:
- `IIF(ft.FundingTypeID = 34, Billing.GetFundingExtraData(@CID, 34), NULL)`
- Only rows where `FundingTypeID = 34` get a non-NULL ExtraData
- All other funding types return NULL for ExtraData
- @CID is only meaningful when the requested country has iDEAL available (FundingTypeID=34 in results); passing NULL for @CID in an iDEAL country causes GetFundingExtraData to return NULL (no historical bank data for unknown customer)
- ExtraData format: JSON `{"LastUsedBank":{"Bic":"...","BankName":"..."}}` or NULL if no historical data

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | INT | NO | - | CODE-BACKED | ID of the country to look up payment methods for. FK to Dictionary.Country. Filters Billing.FundingTypeCountries to return only rows for this country. |
| 2 | @CID | INT | YES | NULL | CODE-BACKED | Customer ID. Optional - only used when FundingTypeID=34 (iDEAL) is in the result set, to retrieve the customer's last-used bank details via Billing.GetFundingExtraData. Pass NULL for non-iDEAL countries or when pre-fill is not required. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method ID from Billing.FundingTypeCountries (mirrors Dictionary.FundingType.FundingTypeID). Identifies the payment method (e.g., 1=CreditCard, 7=PayPal, 34=iDEAL). |
| 4 | CountryID | int | NO | - | CODE-BACKED | Country ID from Billing.FundingTypeCountries. Equals @CountryID input - confirms which country this availability row applies to. |
| 5 | Rank | int (or smallint) | NO | - | CODE-BACKED | Display priority for this payment method in the given country. Lower rank = displayed first in the payment method selector UI. Sourced from Billing.FundingTypeCountries.Rank. |
| 6 | CurrencyIDs | varchar | YES | - | CODE-BACKED | Comma-separated list of Dictionary.Currency IDs that this payment method can process, derived from Billing.Depot->Billing.DepotToCurrency routing. Example: "1,2,3" = USD, EUR, GBP. NULL if no depot routing entries exist (but such rows are excluded by INNER JOIN). |
| 7 | ExtraData | nvarchar(MAX) | YES | NULL | CODE-BACKED | Customer-specific extra data, populated only for FundingTypeID=34 (iDEAL). Returns JSON: `{"LastUsedBank":{"Bic":"...","BankName":"..."}}` from Billing.GetFundingExtraData. NULL for all other funding types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ft (FROM) | Billing.FundingTypeCountries | Direct Read | Core availability matrix - which funding types are available per country with display rank |
| depot (CTE) | Billing.Depot | Direct Read | Payment gateway registry - provides FundingTypeID to DepotID mapping for currency resolution |
| d2c (CTE) | Billing.DepotToCurrency | Direct Read | Depot-currency routing - provides which currencies each depot can process |
| GetFundingExtraData | Billing.GetFundingExtraData | Function Call | Called conditionally for FundingTypeID=34 to retrieve last-used bank BIC and name for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [Billing.GetCustomerDepositInfo](Billing.GetCustomerDepositInfo.md) | EXEC call | Caller | Main deposit initialization procedure that calls this to get available payment methods for the customer's country |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingTypesByCountry (procedure)
├── Billing.FundingTypeCountries (table)
├── Billing.Depot (table)
├── Billing.DepotToCurrency (table)
└── Billing.GetFundingExtraData (scalar function)
      ├── Billing.Funding (table)
      └── Billing.Deposit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeCountries | Table | FROM - provides country-level funding type availability and display rank |
| Billing.Depot | Table | CTE - maps depots to funding types for currency resolution |
| Billing.DepotToCurrency | Table | CTE - maps depots to supported currencies |
| Billing.GetFundingExtraData | Scalar Function | Conditional call (FundingTypeID=34 only) - retrieves last-used iDEAL bank details for @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCustomerDepositInfo | Stored Procedure | Calls this procedure to determine which payment methods are available for the customer's country |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get available payment methods for the UK (CountryID=74)

```sql
EXEC Billing.GetFundingTypesByCountry @CountryID = 74
```

### 8.2 Get available payment methods including iDEAL bank pre-fill for a Netherlands customer

```sql
EXEC Billing.GetFundingTypesByCountry @CountryID = 161, @CID = 12345678
-- Netherlands (CountryID=161) has iDEAL (FundingTypeID=34)
-- @CID provided so ExtraData is populated with last-used bank
```

### 8.3 Equivalent ad-hoc query to inspect country payment methods with currency routing

```sql
WITH CurrencyPerFunding AS (
    SELECT DISTINCT depot.FundingTypeID, d2c.CurrencyID
    FROM Billing.Depot depot WITH (NOLOCK)
    INNER JOIN Billing.DepotToCurrency d2c WITH (NOLOCK) ON depot.DepotID = d2c.DepotID
)
SELECT
    ft.FundingTypeID,
    ft.CountryID,
    ft.[Rank],
    cd.CurrencyIDs
FROM Billing.FundingTypeCountries ft WITH (NOLOCK)
INNER JOIN (
    SELECT t0.FundingTypeID,
        STUFF((SELECT ',' + CAST(t1.CurrencyID AS VARCHAR)
               FROM CurrencyPerFunding t1
               WHERE t1.FundingTypeID = t0.FundingTypeID
               ORDER BY t1.CurrencyID
               FOR XML PATH('')), 1, LEN(','), '') AS CurrencyIDs
    FROM CurrencyPerFunding t0
    GROUP BY t0.FundingTypeID
) cd ON ft.FundingTypeID = cd.FundingTypeID
WHERE ft.CountryID = 74  -- UK
ORDER BY ft.[Rank]
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Deposit Info Current Structure and Data | Confluence | Page found but content unavailable (no page ID in search results). Likely contains deposit flow context. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingTypesByCountry | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingTypesByCountry.sql*

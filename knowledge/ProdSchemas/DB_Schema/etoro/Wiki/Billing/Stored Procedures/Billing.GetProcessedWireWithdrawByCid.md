# Billing.GetProcessedWireWithdrawByCid

> Returns the processed wire transfer withdrawal history for a customer from a given date, including banking country (from the instrument XML), registration country, method type, and amount - used by the withdrawal service for compliance reporting (CCM key: GetWithdrawalHistoryByCid-period-last-months).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns rows from Billing.Withdraw for @CustomerID where CashoutStatusID=3 and FundingTypeID IN wire-type list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetProcessedWireWithdrawByCid` is a compliance report procedure that retrieves a customer's completed wire transfer withdrawal history from a specified date onward. It answers: "What wire transfers has this customer received, from which banking countries, and in what amounts?" - a question asked by compliance teams checking for money laundering indicators such as sending to a bank in a different country than the customer's registration country.

The procedure exists to support AML/compliance workflows (referenced by CCM key `GetWithdrawalHistoryByCid-period-last-months`). The withdrawal service calls it to generate the compliance data package for a customer's withdrawal history. It covers all wire transfer funding types (not just FundingTypeID=2 standard wire, but also local bank variations: 28, 29, 32, 34, 37, 38).

Data flows: the withdrawal service calls this when a compliance check or report is needed for a customer's wire withdrawal history. The procedure joins `Billing.Withdraw` to `Billing.WithdrawToFunding` (for the funding instrument), `Billing.Funding` (for the FundingData XML with bank country), `Dictionary.FundingType` (for method name), and `Customer.Customer` (for registration country). Banking country is extracted from the FundingData XML using a COALESCE pattern: first tries `/Funding[1]/BinCountryIDAsInteger[1]`, then falls back to `/Funding[1]/CountryIDAsInteger[1]`.

---

## 2. Business Logic

### 2.1 Wire Transfer Type Coverage (FundingTypeIDs)

**What**: The procedure covers all wire transfer variants, not just standard wire (FundingTypeID=2).

**Columns/Parameters Involved**: `wid.FundingTypeID`

**Filter**: `wid.FundingTypeID IN (2, 28, 29, 32, 34, 37, 38)`

| FundingTypeID | Type |
|---|---|
| 2 | Standard Wire Transfer |
| 28 | Local bank variant (specific region) |
| 29 | Local bank variant |
| 32 | Local bank variant |
| 34 | Local bank variant |
| 37 | Local bank variant |
| 38 | Local bank variant |

### 2.2 Banking Country Extraction from XML (COALESCE Pattern)

**What**: The banking country where the customer's receiving account is held is extracted from the FundingData XML with a two-field fallback.

**Columns/Parameters Involved**: `fund.FundingData` (XML)

**Rules**:
- Primary: `FundingData.value('/Funding[1]/BinCountryIDAsInteger[1]', 'INTEGER')` - BIN country for card-associated bank accounts
- Fallback: `FundingData.value('/Funding[1]/CountryIDAsInteger[1]', 'INTEGER')` - explicit country ID for standard wire accounts
- `ISNULL(primary, fallback)` - if primary is NULL (most wire transfers), use the fallback
- Result is a CountryID integer (FK to Dictionary.Country, but not joined here - raw ID returned)

### 2.3 Processed Status Filter (CashoutStatusID=3)

**What**: Only finalized (processed) wire withdrawals are returned.

**Rules**:
- `wid.CashoutStatusID = 3` - completed/processed withdrawals only
- Pending, in-progress, or declined withdrawals are excluded
- Combined with `wid.RequestDate >= @FromDate` for date-range filtering

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerID | INT | NO | - | CODE-BACKED | Customer identifier. Filters `Billing.Withdraw.CID` to this customer's withdrawals. |
| 2 | @FromDate | DATE | NO | - | CODE-BACKED | Start date filter. Only withdrawals with `RequestDate >= @FromDate` are returned. Typically set to 1 year ago (per CCM key description: "period-last-months"). |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 3 | Date | Billing.Withdraw.RequestDate | CODE-BACKED | Date when the customer submitted the withdrawal request. |
| 4 | Amount | Billing.Withdraw.Amount | CODE-BACKED | Withdrawal amount (in the withdrawal's currency). |
| 5 | BankingCountry | ISNULL(FundingData/BinCountryIDAsInteger, FundingData/CountryIDAsInteger) | CODE-BACKED | CountryID of the bank where the customer's receiving account is held. Extracted from Billing.Funding.FundingData XML. FK to Dictionary.Country (not joined - raw ID). |
| 6 | RegistrationCountry | Customer.Customer.CountryID | CODE-BACKED | CountryID of the customer's registration country. Used in compliance to compare against BankingCountry. FK to Dictionary.Country. |
| 7 | MopTypeId | Billing.Withdraw.FundingTypeID | CODE-BACKED | Method of Payment type ID (MOP). One of: 2, 28, 29, 32, 34, 37, 38. FK to Dictionary.FundingType. |
| 8 | MopType | Dictionary.FundingType.Name | CODE-BACKED | Human-readable MOP name (e.g., "Wire Transfer", local bank variant names). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CustomerID | Billing.Withdraw.CID | Filter | Customer's processed wire withdrawal requests |
| (JOIN) | Billing.WithdrawToFunding | INNER JOIN | Links withdrawal to funding instrument |
| (JOIN) | Billing.Funding | INNER JOIN | Source of FundingData XML (banking country) |
| (JOIN) | Dictionary.FundingType | INNER JOIN | Resolves FundingTypeID to MOP name |
| (JOIN) | Customer.Customer | INNER JOIN | Source of registration country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawalServiceUser | GRANT EXECUTE | Permission | Withdrawal service calls for compliance reporting (CCM: GetWithdrawalHistoryByCid-period-last-months) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetProcessedWireWithdrawByCid (procedure)
├── Billing.Withdraw (table)
├── Billing.WithdrawToFunding (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table - cross-schema)
└── Customer.Customer (table - cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary source; filtered by CID, CashoutStatusID=3, FundingTypeID IN (2,28,29,32,34,37,38), RequestDate |
| Billing.WithdrawToFunding | Table | INNER JOINed to link withdrawal to funding instrument |
| Billing.Funding | Table | INNER JOINed for FundingData XML (banking country extraction) |
| Dictionary.FundingType | Table | INNER JOINed for MOP type name |
| Customer.Customer | Table | INNER JOINed for registration country (CountryID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WithdrawalServiceUser | DB Security Principal | EXECUTE permission - compliance reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: BankingCountry is returned as a raw CountryID integer (not joined to Dictionary.Country for name resolution). The caller is expected to have the Country lookup table separately. All tables use WITH (NOLOCK). The comment references CCM key `GetWithdrawalHistoryByCid-period-last-months` - this is a configuration key in eToro's compliance/CCM system that likely controls the @FromDate calculation (number of months back).

---

## 8. Sample Queries

### 8.1 Get wire withdrawal compliance data for a customer (last 12 months)
```sql
EXEC [Billing].[GetProcessedWireWithdrawByCid]
    @CustomerID = 12345678,
    @FromDate = '2025-03-18'  -- 1 year ago
```

### 8.2 Find customers with wire withdrawals to banking countries different from registration
```sql
-- Identify potential compliance flags (banking != registration country)
SELECT
    wid.CID,
    wid.RequestDate,
    wid.Amount,
    ISNULL(fund.FundingData.value('/Funding[1]/BinCountryIDAsInteger[1]','INTEGER'),
           fund.FundingData.value('/Funding[1]/CountryIDAsInteger[1]','INTEGER')) AS BankingCountry,
    cust.CountryID AS RegistrationCountry
FROM Billing.Withdraw wid WITH (NOLOCK)
INNER JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wid.WithdrawID = wtf.WithdrawID
INNER JOIN Billing.Funding fund WITH (NOLOCK) ON wtf.FundingID = fund.FundingID
INNER JOIN Customer.Customer cust WITH (NOLOCK) ON cust.CID = wid.CID
WHERE wid.CashoutStatusID = 3
  AND wid.FundingTypeID IN (2, 28, 29, 32, 34, 37, 38)
  AND wid.RequestDate >= DATEADD(YEAR, -1, GETUTCDATE())
  AND ISNULL(fund.FundingData.value('/Funding[1]/BinCountryIDAsInteger[1]','INTEGER'),
             fund.FundingData.value('/Funding[1]/CountryIDAsInteger[1]','INTEGER')) != cust.CountryID
```

### 8.3 Summarize wire withdrawal volumes by funding type
```sql
SELECT wid.FundingTypeID, funt.Name, COUNT(*) AS WithdrawCount, SUM(wid.Amount) AS TotalAmount
FROM Billing.Withdraw wid WITH (NOLOCK)
INNER JOIN Dictionary.FundingType funt WITH (NOLOCK) ON funt.FundingTypeID = wid.FundingTypeID
WHERE wid.CashoutStatusID = 3
  AND wid.FundingTypeID IN (2, 28, 29, 32, 34, 37, 38)
GROUP BY wid.FundingTypeID, funt.Name
ORDER BY TotalAmount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetProcessedWireWithdrawByCid | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetProcessedWireWithdrawByCid.sql*

# Billing.PayoutMetricDataGet

> Fetches a fully enriched payout record for a single WithdrawToFunding entry, joining 13 tables to produce a human-readable metrics row for analytics and back-office reporting.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WTF_ID (Billing.WithdrawToFunding.ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutMetricDataGet` is a read-only reporting procedure that fetches a fully-decorated payout record for a single `Billing.WithdrawToFunding` row. It enriches the core withdrawal-to-funding record with human-readable labels from 13 joined tables - covering funding type, cashout status, cashout type, depot, regulation, currency, country, match status, and merchant account.

The procedure is used by the analytics service (`AnalyticsServiceUser` has EXECUTE grant) to retrieve payout metrics for monitoring, dashboarding, or reconciliation workflows. It is designed for single-record lookups (WHERE WTF.ID = @WTF_ID) and returns one row per call.

Key metric computed: `AmountUSD = CAST(WTF.Amount * WTF.ExchangeRate AS DECIMAL(10,2))` - converts the withdrawal amount from the process currency to USD equivalent.

Note: The output column names contain a consistent typo in the source code: `CachoutType` and `CachoutStatus` (missing 's') - these are the actual column names returned in the result set.

---

## 2. Business Logic

### 2.1 Single WithdrawToFunding Record Fetch

**What**: Retrieves one fully-enriched row for the specified WithdrawToFunding ID.

**Parameters Involved**: `@WTF_ID`

**Rules**:
- Filter: `WHERE WTF.ID = @WTF_ID` - exact single-row lookup
- If not found: returns empty result set (0 rows, no error)
- All WITH (NOLOCK) hints (except Customer.Customer and BackOffice.Customer) - analytics read, dirty reads acceptable

### 2.2 USD Amount Conversion

**What**: Converts the withdrawal amount to USD for normalized reporting.

**Rules**:
- `AmountUSD = CAST(WTF.Amount * WTF.ExchangeRate AS DECIMAL(10,2))`
- WTF.Amount: amount in ProcessCurrencyID denomination
- WTF.ExchangeRate: FX rate to convert to USD
- Result: dollar-denominated amount, 2 decimal precision

### 2.3 Optional / Nullable Enrichments (LEFT JOINs)

**What**: Several enrichment tables are LEFT JOINed with ISNULL fallback to 'NA'.

**Rules**:
- `CashoutType` (DCOT): LEFT JOIN - NULL if WTF.CashoutTypeID IS NULL -> 'NA'
- `Depot` (BD): LEFT JOIN with extra guards (DepotID > 0 AND DepotID IS NOT NULL) -> 'NA' for unassigned
- `CashoutMode` (DCOM): LEFT JOIN - NULL if WTF.CashoutModeID IS NULL -> 'NA'
- `MatchStatus` (DMS): LEFT JOIN - NULL if WTF.MatchStatusID IS NULL -> 'NA'
- `MerchantAccount` (DMA): LEFT JOIN - NULL if WTF.MerchantAccountID IS NULL -> 'NA'

### 2.4 Regulation Lookup via BackOffice.Customer

**What**: Gets the customer's designated regulation via the back-office customer record.

**Rules**:
- `INNER JOIN BackOffice.Customer AS BOC ON BW.CID = BOC.CID`
- `INNER JOIN Dictionary.Regulation AS DR ON DR.ID = BOC.DesignatedRegulationID`
- Uses DesignatedRegulationID (not the live/current regulation) - reflects the regulatory entity assigned to this customer in back-office

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WTF_ID | INTEGER | NO | - | CODE-BACKED | PK of Billing.WithdrawToFunding.ID to retrieve. Returns 0 rows if not found. |
| 2 | WithdrawID | INTEGER | - | - | CODE-BACKED | FK to Billing.Withdraw - the withdrawal request this payout belongs to. |
| 3 | FundingID | INTEGER | - | - | CODE-BACKED | FK to Billing.Funding - the funding method (payment instrument) used. |
| 4 | CashoutStatusID | INTEGER | - | - | CODE-BACKED | Current status of the cashout. FK to Dictionary.CashoutStatus. See CachoutStatus output for name. |
| 5 | ProcessCurrencyID | INTEGER | - | - | CODE-BACKED | Currency of the payout amount. FK to Dictionary.Currency. See Currency output for abbreviation. |
| 6 | ManagerID | INTEGER | - | - | CODE-BACKED | Back-office manager who processed/reviewed this payout. |
| 7 | WithdrawToFundingID | INTEGER | - | - | CODE-BACKED | WTF.ID aliased as WithdrawToFundingID - the same as @WTF_ID input. |
| 8 | CashoutTypeID | INTEGER | - | - | CODE-BACKED | Type of cashout. FK to Dictionary.CashoutType. See CachoutType output for name. |
| 9 | MatchStatusID | INTEGER | - | - | CODE-BACKED | Match status for reconciliation. FK to Dictionary.MatchStatus. See MatchStatus output. |
| 10 | DepotID | INTEGER | - | - | CODE-BACKED | Depot (payment terminal group) for this payout. FK to Billing.Depot. See Depot output. |
| 11 | ProtocolMIDSettingsID | INTEGER | - | - | CODE-BACKED | Protocol MID settings reference for the processing terminal. |
| 12 | CashoutModeID | INTEGER | - | - | CODE-BACKED | Processing mode. FK to Dictionary.CashoutMode. See CashoutModeName output. |
| 13 | MerchantAccountID | INTEGER | - | - | CODE-BACKED | Merchant account used. FK to Dictionary.MerchantAccount. See MerchantAccountName output. |
| 14 | CID | INTEGER | - | - | CODE-BACKED | Customer ID (from Billing.Withdraw). |
| 15 | IPAddress | VARCHAR | - | - | CODE-BACKED | IP address from the withdrawal request (Billing.Withdraw.IPAddress). |
| 16 | GCID | INTEGER | - | - | CODE-BACKED | Global Customer ID from Customer.Customer. Used for cross-system customer identification. |
| 17 | FundingTypeID | INTEGER | - | - | CODE-BACKED | Payment method type (e.g., 1=CreditCard, 2=Wire, 3=PayPal). From Billing.Funding. |
| 18 | FundingName | VARCHAR | - | - | CODE-BACKED | Human-readable funding type name from Dictionary.FundingType.Name. |
| 19 | CachoutType | VARCHAR | - | 'NA' | CODE-BACKED | Cashout type name from Dictionary.CashoutType.CashoutTypeName. 'NA' if CashoutTypeID is NULL. Note: typo in column alias (Cachout vs Cashout). |
| 20 | CachoutStatus | VARCHAR | - | - | CODE-BACKED | Cashout status name from Dictionary.CashoutStatus.Name. Note: typo in column alias (Cachout vs Cashout). |
| 21 | Depot | VARCHAR | - | 'NA' | CODE-BACKED | Depot name from Billing.Depot.Name. 'NA' if DepotID is NULL or 0. |
| 22 | Regulation | VARCHAR | - | - | CODE-BACKED | Regulatory entity name from Dictionary.Regulation.Name via BackOffice.Customer.DesignatedRegulationID. |
| 23 | CashoutModeName | VARCHAR | - | 'NA' | CODE-BACKED | Cashout processing mode from Dictionary.CashoutMode.CashoutModeName. 'NA' if CashoutModeID is NULL. |
| 24 | Currency | VARCHAR | - | - | CODE-BACKED | Currency abbreviation (e.g., 'USD', 'EUR') from Dictionary.Currency.Abbreviation. |
| 25 | MatchStatus | VARCHAR | - | 'NA' | CODE-BACKED | Reconciliation match status from Dictionary.MatchStatus.Name. 'NA' if MatchStatusID is NULL. |
| 26 | Country | VARCHAR | - | - | CODE-BACKED | Customer's country name from Dictionary.Country.Name via Customer.Customer.CountryID. |
| 27 | MerchantAccountName | VARCHAR | - | 'NA' | CODE-BACKED | Merchant account name from Dictionary.MerchantAccount.Name. 'NA' if MerchantAccountID is NULL. |
| 28 | AmountUSD | DECIMAL(10,2) | - | - | CODE-BACKED | Withdrawal amount converted to USD: CAST(WTF.Amount * WTF.ExchangeRate AS DECIMAL(10,2)). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Billing.WithdrawToFunding | READ | Primary entity - the payout record being fetched |
| JOIN | Billing.Withdraw | READ | Parent withdrawal request (CID, IPAddress) |
| JOIN | Customer.Customer | READ | Customer profile (GCID, CountryID) |
| JOIN | Billing.Funding | READ | Payment instrument (FundingTypeID) |
| JOIN | Dictionary.FundingType | Lookup | Funding type name |
| LEFT JOIN | Dictionary.CashoutType | Lookup | Cashout type name (optional) |
| JOIN | Dictionary.CashoutStatus | Lookup | Cashout status name |
| LEFT JOIN | Billing.Depot | Lookup | Depot name (optional) |
| JOIN | BackOffice.Customer | READ | Back-office customer for regulation |
| JOIN | Dictionary.Regulation | Lookup | Regulatory entity name |
| LEFT JOIN | Dictionary.CashoutMode | Lookup | Cashout mode name (optional) |
| JOIN | Dictionary.Currency | Lookup | Currency abbreviation |
| LEFT JOIN | Dictionary.MatchStatus | Lookup | Reconciliation match status (optional) |
| JOIN | Dictionary.Country | Lookup | Customer country name |
| LEFT JOIN | Dictionary.MerchantAccount | Lookup | Merchant account name (optional) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AnalyticsServiceUser (application) | @WTF_ID | EXEC caller | Analytics service fetches payout metrics per WithdrawToFunding record (EXECUTE grant confirmed) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutMetricDataGet (procedure)
├── Billing.WithdrawToFunding (table) - primary
├── Billing.Withdraw (table)
├── Customer.Customer (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── BackOffice.Customer (table)
└── Dictionary.* (FundingType, CashoutType, CashoutStatus, Regulation, CashoutMode, Currency, MatchStatus, Country, MerchantAccount)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FROM - primary payout record |
| Billing.Withdraw | Table | INNER JOIN - withdrawal request (CID, IPAddress) |
| Customer.Customer | Table | INNER JOIN - customer profile (GCID, CountryID) |
| Billing.Funding | Table | INNER JOIN - funding method (FundingTypeID) |
| Billing.Depot | Table | LEFT JOIN - depot assignment |
| BackOffice.Customer | Table | INNER JOIN - designated regulation |
| Dictionary.FundingType | Table | INNER JOIN - funding type name |
| Dictionary.CashoutType | Table | LEFT JOIN - cashout type name |
| Dictionary.CashoutStatus | Table | INNER JOIN - cashout status name |
| Dictionary.Regulation | Table | INNER JOIN - regulation name |
| Dictionary.CashoutMode | Table | LEFT JOIN - cashout mode name |
| Dictionary.Currency | Table | INNER JOIN - currency abbreviation |
| Dictionary.MatchStatus | Table | LEFT JOIN - match status name |
| Dictionary.Country | Table | INNER JOIN - country name |
| Dictionary.MerchantAccount | Table | LEFT JOIN - merchant account name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Analytics service (external) | Application | Reads payout metrics per WithdrawToFunding record |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Read-only - no DML. Most tables use WITH (NOLOCK) for analytics reads. Single-row lookup by WTF.ID. Column name typo: CachoutType/CachoutStatus (missing 's') exists in output column aliases - callers must use these exact names.

---

## 8. Sample Queries

### 8.1 Fetch payout metrics for a specific WithdrawToFunding record

```sql
EXEC Billing.PayoutMetricDataGet @WTF_ID = 1234567;
```

### 8.2 Explore the underlying payout data directly

```sql
SELECT
    wtf.ID AS WithdrawToFundingID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.CashoutStatusID,
    wtf.ProcessCurrencyID,
    CAST(wtf.Amount * wtf.ExchangeRate AS DECIMAL(10,2)) AS AmountUSD,
    wtf.CashoutTypeID,
    wtf.MatchStatusID,
    wtf.DepotID,
    wtf.CashoutModeID,
    wtf.MerchantAccountID
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.ID = 1234567;
```

### 8.3 Find all unmatched payouts (MatchStatusID IS NULL)

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    bw.CID,
    CAST(wtf.Amount * wtf.ExchangeRate AS DECIMAL(10,2)) AS AmountUSD,
    dcos.Name AS CashoutStatus
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
INNER JOIN Billing.Withdraw bw WITH (NOLOCK) ON bw.WithdrawID = wtf.WithdrawID
INNER JOIN Dictionary.CashoutStatus dcos WITH (NOLOCK) ON dcos.CashoutStatusID = wtf.CashoutStatusID
WHERE wtf.MatchStatusID IS NULL
ORDER BY wtf.ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.9/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 1 service with EXECUTE grant (AnalyticsServiceUser) | Corrections: 0 applied*
*Object: Billing.PayoutMetricDataGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutMetricDataGet.sql*

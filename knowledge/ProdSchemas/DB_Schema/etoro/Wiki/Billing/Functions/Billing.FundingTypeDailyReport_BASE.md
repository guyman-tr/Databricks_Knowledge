# Billing.FundingTypeDailyReport_BASE

> Inline table-valued function that returns yesterday-to-today deposit records for a specific FundingTypeID (default 35), enriched with human-readable labels for status, country, MID, depot, regulation, and currency. Serves as the shared data source for 7 FundingTypeDailyReport_* stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | DepositID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_BASE` is the shared data layer for a family of 7 daily operations reports:
- `Billing.FundingTypeDailyReport_All` - raw JSON output
- `Billing.FundingTypeDailyReport_Country` - aggregated by country
- `Billing.FundingTypeDailyReport_Currency` - aggregated by currency
- `Billing.FundingTypeDailyReport_IsFTD` - split by first-time deposit
- `Billing.FundingTypeDailyReport_MID` - aggregated by MID
- `Billing.FundingTypeDailyReport_Regulation` - aggregated by regulation
- `Billing.FundingTypeDailyReport_RiskStatus` - aggregated by risk status
- `Billing.FundingTypeDailyReport_Status` - aggregated by payment status

The function answers "what deposits occurred in the last 24 hours for a given payment method?" by filtering `Billing.Deposit` to `PaymentDate BETWEEN GETDATE()-1 AND GETDATE()` and joining 8 tables to replace IDs with descriptive labels.

Default `@fundingTypeID = 35` (the default payment method for this report family - likely a specific e-wallet or bank transfer type). All 7 consuming procedures accept the same parameter and pass it through.

**60 rows** returned for FundingTypeID=35 in the last 24 hours at time of query.

---

## 2. Business Logic

### 2.1 24-Hour Rolling Window

**What**: The time filter is a dynamic rolling 24-hour window relative to the current time.

**Columns/Parameters Involved**: `PaymentDate`

**Rules**:
- `WHERE PaymentDate BETWEEN GETDATE()-1 AND GETDATE()`
- Returns deposits from exactly yesterday (same time) to right now
- Non-deterministic: result changes with each call as time advances
- Does NOT use PaymentStatusID filter - all statuses included (Approved, Decline, Pending, etc.)
- The sample shows Declined deposits are included alongside Approved ones

### 2.2 FundingTypeID Filter via Funding Table

**What**: Filters to deposits made with a specific payment method type.

**Columns/Parameters Involved**: `@fundingTypeID`, `f.FundingTypeID`

**Rules**:
- `WHERE f.FundingTypeID = @fundingTypeID` (filtered on Billing.Funding, not Billing.Deposit)
- Default: FundingTypeID=35 (the primary payment type for this report family)
- All 7 consuming procedures default to 35 but accept overrides
- INNER JOIN to Billing.Funding means deposits with no matching Funding record are excluded

### 2.3 8-Table Human-Label Enrichment

**What**: Replaces all status/category IDs with human-readable names for direct consumption by operations reporting.

**Columns/Parameters Involved**: `Status`, `Country`, `MID`, `Depot`, `RiskStatus`, `Regulation`, `Currency`

**Rules**:
- `ps.Name AS Status`: PaymentStatusID -> "Decline", "Approved", "Pending", etc. (INNER JOIN - deposit must have valid PaymentStatus)
- `co.Name AS Country`: Customer.CountryID -> country name via Customer.Customer + Dictionary.Country (INNER JOIN - customer must have valid country)
- `pms.Description AS MID`: ProtocolMIDSettingsID -> MID description (e.g., "TrustlyEU") (INNER JOIN - deposit must have valid MID)
- `bd.Name AS Depot`: DepotID -> depot name (e.g., "IXOPAY-powercash") (INNER JOIN - deposit must have valid depot)
- `reg.Name AS Regulation`: ProcessRegulationID -> regulation name (e.g., "CySEC") (INNER JOIN - must have valid regulation)
- `rs.Name AS RiskStatus`: RiskManagementStatusID -> risk status name (LEFT JOIN - NULL if no risk status assigned)
- `cur.Abbreviation AS Currency`: CurrencyID -> currency code (e.g., "EUR") (INNER JOIN)
- All INNER JOINs mean records without complete enrichment data are silently excluded

---

## 3. Data Overview

| DepositID | CID | Amount | PaymentDate | FundingID | Status | Country | MID | Depot | IsFTD | RiskStatus | Regulation | Currency |
|-----------|-----|--------|-------------|-----------|--------|---------|-----|-------|-------|------------|------------|---------|
| 10776162 | 25456522 | 100 | 2026-03-16 19:50:22 | 4146527 | Decline | Netherlands | TrustlyEU | IXOPAY-powercash | false | NULL | CySEC | EUR |
| 10776165 | 25456522 | 100 | 2026-03-16 19:50:33 | 4146527 | Decline | Netherlands | TrustlyEU | IXOPAY-powercash | false | NULL | CySEC | EUR |

**Row count**: 60 rows (FundingTypeID=35, last 24 hours as of query time). Count varies by time of day.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | int | NO | 35 | CODE-BACKED | Input parameter: the payment method type to filter deposits by. Default=35 (the primary FundingType for this report family). Matched against Billing.Funding.FundingTypeID via INNER JOIN. References Dictionary.FundingType. |
| 2 | DepositID | int | NO | - | CODE-BACKED | Unique deposit identifier. From Billing.Deposit. PK. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID. From Billing.Deposit. |
| 4 | Amount | money | NO | - | CODE-BACKED | Deposit amount in the deposit's currency (see Currency). From Billing.Deposit. |
| 5 | PaymentDate | datetime | YES | - | CODE-BACKED | Date/time the payment was processed. From Billing.Deposit. The time-range filter is applied to this column: BETWEEN GETDATE()-1 AND GETDATE(). |
| 6 | FundingID | int | YES | - | CODE-BACKED | FK to Billing.Funding. The payment instrument used. INNER JOIN ensures only deposits with valid Funding records appear. |
| 7 | Status | nvarchar | NO | - | CODE-BACKED | Human-readable payment status name. From Dictionary.PaymentStatus via PaymentStatusID. Examples: "Approved", "Decline", "Pending". INNER JOIN - always populated. |
| 8 | Country | nvarchar | NO | - | CODE-BACKED | Customer's country name. From Dictionary.Country via Customer.Customer.CountryID. Reflects the customer's registered country at the time of the deposit. INNER JOIN - always populated. |
| 9 | MID | nvarchar | YES | - | CODE-BACKED | Merchant ID (MID) description. From Billing.ProtocolMIDSettings via ProtocolMIDSettingsID. Examples: "TrustlyEU". The specific MID used for processing. INNER JOIN - always populated for deposits with a valid MID. |
| 10 | Depot | nvarchar | NO | - | CODE-BACKED | Payment gateway/depot name. From Billing.Depot via DepotID. Examples: "IXOPAY-powercash". INNER JOIN - always populated. |
| 11 | IsFTD | bit | YES | - | CODE-BACKED | First-time deposit flag. From Billing.Deposit. 1=customer's first deposit. Used in FundingTypeDailyReport_IsFTD to split report by new vs returning depositors. |
| 12 | RiskStatus | nvarchar | YES | - | CODE-BACKED | Risk management review status name. From Dictionary.RiskManagementStatus via RiskManagementStatusID. LEFT JOIN - NULL when no risk status has been assigned (most deposits). |
| 13 | Regulation | nvarchar | NO | - | CODE-BACKED | Regulatory jurisdiction name. From Dictionary.Regulation via ProcessRegulationID. Examples: "CySEC", "FCA", "ASIC". INNER JOIN - always populated. Used in FundingTypeDailyReport_Regulation to aggregate by jurisdiction. |
| 14 | Currency | nvarchar(3) | NO | - | CODE-BACKED | ISO currency abbreviation. From Dictionary.Currency via CurrencyID. Examples: "EUR", "USD", "GBP". INNER JOIN - always populated. Used in FundingTypeDailyReport_Currency to aggregate by currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID, CID, Amount, PaymentDate, FundingID, PaymentStatusID, ProtocolMIDSettingsID, DepotID, IsFTD, RiskManagementStatusID, ProcessRegulationID, CurrencyID | Billing.Deposit | Source (FROM anchor, time filter + PaymentDate range) | All deposit records for the last 24 hours |
| FundingTypeID | Billing.Funding | Source (INNER JOIN on FundingID, WHERE FundingTypeID=@fundingTypeID) | Filters to target payment method type |
| PaymentStatusID -> Status | Dictionary.PaymentStatus | Lookup (INNER JOIN) | Payment status name |
| CID -> CountryID | Customer.Customer | Lookup (INNER JOIN) | Customer country for name lookup |
| CountryID -> Country | Dictionary.Country | Lookup (INNER JOIN) | Country name |
| CurrencyID -> Currency | Dictionary.Currency | Lookup (INNER JOIN) | Currency abbreviation |
| ProtocolMIDSettingsID -> MID | Billing.ProtocolMIDSettings | Lookup (INNER JOIN) | MID description |
| DepotID -> Depot | Billing.Depot | Lookup (INNER JOIN) | Depot name |
| ProcessRegulationID -> Regulation | Dictionary.Regulation | Lookup (INNER JOIN) | Regulation name |
| RiskManagementStatusID -> RiskStatus | Dictionary.RiskManagementStatus | Lookup (LEFT JOIN) | Risk status name, nullable |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.FundingTypeDailyReport_All | All columns | Caller (SELECT * ... FOR JSON AUTO) | Raw JSON dump of all deposit records |
| Billing.FundingTypeDailyReport_Country | Country, Amount, Status | Caller (aggregate by Country) | Daily deposits grouped by country |
| Billing.FundingTypeDailyReport_Currency | Currency, Amount, Status | Caller (aggregate by Currency) | Daily deposits grouped by currency |
| Billing.FundingTypeDailyReport_IsFTD | IsFTD, Amount, Status | Caller (aggregate by IsFTD) | Daily deposits split by first-time vs returning |
| Billing.FundingTypeDailyReport_MID | MID, Amount, Status | Caller (aggregate by MID) | Daily deposits grouped by MID |
| Billing.FundingTypeDailyReport_Regulation | Regulation, Amount, Status | Caller (aggregate by Regulation) | Daily deposits grouped by regulatory jurisdiction |
| Billing.FundingTypeDailyReport_RiskStatus | RiskStatus, Amount, Status | Caller (aggregate by RiskStatus) | Daily deposits grouped by risk status |
| Billing.FundingTypeDailyReport_Status | Status, Amount | Caller (aggregate by Status) | Daily deposits grouped by payment status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_BASE (inline TVF)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.ProtocolMIDSettings (table)
├── Billing.Depot (table)
├── Customer.Customer (table, cross-schema)
├── Dictionary.PaymentStatus (table, cross-schema)
├── Dictionary.Country (table, cross-schema)
├── Dictionary.Currency (table, cross-schema)
├── Dictionary.Regulation (table, cross-schema)
└── Dictionary.RiskManagementStatus (table, cross-schema, LEFT JOIN)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FROM anchor: deposit data, time filter (PaymentDate BETWEEN GETDATE()-1 AND GETDATE()) |
| Billing.Funding | Table | INNER JOIN on FundingID: FundingTypeID filter for target payment method |
| Billing.ProtocolMIDSettings | Table | INNER JOIN on ProtocolMIDSettingsID: MID description label |
| Billing.Depot | Table | INNER JOIN on DepotID: Depot name label |
| Customer.Customer | Table | INNER JOIN on CID: customer CountryID for country lookup |
| Dictionary.PaymentStatus | Table | INNER JOIN on PaymentStatusID: Status label |
| Dictionary.Country | Table | INNER JOIN on CountryID: Country name |
| Dictionary.Currency | Table | INNER JOIN on CurrencyID: Currency abbreviation |
| Dictionary.Regulation | Table | INNER JOIN on ProcessRegulationID: Regulation name |
| Dictionary.RiskManagementStatus | Table | LEFT JOIN on RiskManagementStatusID: RiskStatus label (nullable) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_All | Stored Procedure | SELECT * FOR JSON AUTO |
| Billing.FundingTypeDailyReport_Country | Stored Procedure | Aggregates by Country |
| Billing.FundingTypeDailyReport_Currency | Stored Procedure | Aggregates by Currency |
| Billing.FundingTypeDailyReport_IsFTD | Stored Procedure | Aggregates by IsFTD |
| Billing.FundingTypeDailyReport_MID | Stored Procedure | Aggregates by MID |
| Billing.FundingTypeDailyReport_Regulation | Stored Procedure | Aggregates by Regulation |
| Billing.FundingTypeDailyReport_RiskStatus | Stored Procedure | Aggregates by RiskStatus |
| Billing.FundingTypeDailyReport_Status | Stored Procedure | Aggregates by Status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for inline TVF. The rolling time filter `PaymentDate BETWEEN GETDATE()-1 AND GETDATE()` should leverage the PaymentDate index on Billing.Deposit. The additional FundingTypeID filter (via Billing.Funding INNER JOIN) further reduces the result. 8 INNER JOINs to Dictionary/Customer tables are all PK lookups - efficient at daily row counts (~60 rows per day for FundingTypeID=35).

### 7.2 Constraints

Not schema-bound (cross-schema joins). Non-deterministic: result changes each call as GETDATE() advances. All INNER JOINs mean deposits missing any of: PaymentStatus, Customer, Country, Currency, MID, Depot, or Regulation will be silently excluded from the report. Default @fundingTypeID=35 is hardcoded - operational teams must know which FundingTypeID corresponds to their target payment method.

---

## 8. Sample Queries

### 8.1 Get all deposits for FundingTypeID=35 in the last 24 hours

```sql
SELECT DepositID, CID, Amount, PaymentDate, Status, Country, MID, Depot, IsFTD, Regulation, Currency
FROM Billing.FundingTypeDailyReport_BASE(35)
ORDER BY DepositID
```

### 8.2 Use the All report (as called by FundingTypeDailyReport_All)

```sql
SELECT *
FROM Billing.FundingTypeDailyReport_BASE(35)
ORDER BY DepositID
FOR JSON AUTO
```

### 8.3 Aggregate by country (as called by FundingTypeDailyReport_Country)

```sql
SELECT Country, Status, COUNT(*) AS DepositCount, SUM(Amount) AS TotalAmount
FROM Billing.FundingTypeDailyReport_BASE(@fundingTypeID)
GROUP BY Country, Status
ORDER BY TotalAmount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_BASE | Type: Inline TVF | Source: etoro/etoro/Billing/Functions/Billing.FundingTypeDailyReport_BASE.sql*

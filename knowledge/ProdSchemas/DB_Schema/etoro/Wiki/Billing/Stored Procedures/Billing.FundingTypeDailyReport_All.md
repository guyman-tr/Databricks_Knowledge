# Billing.FundingTypeDailyReport_All

> Returns the full set of yesterday's deposits for a given payment type as a JSON array - the base daily report for operations monitoring of a specific funding type.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns JSON array of all deposit rows for @fundingTypeID from yesterday |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_All` is the raw/detail variant of the daily funding type monitoring suite. It delegates entirely to `Billing.FundingTypeDailyReport_BASE`, an inline TVF that joins yesterday's deposits to their funding, payment status, country, currency, MID, depot, regulation, and risk management status data - and returns all rows as a JSON array sorted by DepositID.

The suite of `FundingTypeDailyReport_*` procedures provides operations teams with a one-command JSON API for reviewing how a specific payment method type performed in the last 24 hours. Default @fundingTypeID=35 suggests a specific provider (likely one of the newer payment methods added around when these procedures were created). Each procedure in the suite answers a different cut of the same question: "What happened with this payment type yesterday?"

The BASE function's time window is `GETDATE()-1 to GETDATE()` (sliding 24h window), making these procedures time-sensitive - results change every moment as the window slides.

---

## 2. Business Logic

### 2.1 FundingTypeDailyReport_BASE - The Shared Foundation

**What**: All 8 daily report procedures in this suite delegate to this inline TVF for data retrieval.

**Columns/Parameters Involved**: `@fundingTypeID`, all BASE output columns

**BASE function joins**:
- `Billing.Deposit` (base fact table - yesterday's payments)
- `Billing.Funding` (payment instrument - filtered by @fundingTypeID)
- `Dictionary.PaymentStatus` (deposit status name)
- `Customer.Customer` (to get CountryID)
- `Dictionary.Country` (country name)
- `Dictionary.Currency` (currency abbreviation)
- `Billing.ProtocolMIDSettings` (merchant account description)
- `Billing.Depot` (depot name)
- `Dictionary.Regulation` (regulation name)
- `Dictionary.RiskManagementStatus` (LEFT JOIN - NULL if no risk flag)

**BASE time filter**: `PaymentDate BETWEEN GETDATE()-1 AND GETDATE()` - last 24 hours.

**BASE output columns**: DepositID, CID, Amount, PaymentDate, FundingID, Status, Country, MID, Depot, IsFTD, RiskStatus, Regulation, Currency

### 2.2 Report Variants Summary

| Procedure | Aggregation | Use Case |
|-----------|-------------|----------|
| `_All` (this) | No aggregation - all rows | Full detail view of all deposits |
| `_Country` | GROUP BY Country | Volume breakdown by customer country |
| `_Currency` | GROUP BY Currency | Volume breakdown by currency |
| `_IsFTD` | GROUP BY IsFTD | First-time vs returning depositor split |
| `_MID` | GROUP BY MID | Volume breakdown by merchant account |
| `_Regulation` | GROUP BY Regulation | Volume breakdown by regulatory entity |
| `_RiskStatus` | GROUP BY RiskStatus | Risk flag distribution |
| `_Status` | GROUP BY Status | Deposit status breakdown (Approved, Pending, etc.) |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | INT | NO | 35 | CODE-BACKED | The payment instrument type to report on (FK to Dictionary.FundingType.FundingTypeID). Default 35 = specific payment provider (likely a newer digital payment method). Filters Billing.Funding records used in Billing.Deposit yesterday. |

**Return columns** (from FundingTypeDailyReport_BASE, FOR JSON AUTO):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | DepositID | int | CODE-BACKED | PK of Billing.Deposit. Ordering key for _All variant. |
| R2 | CID | int | CODE-BACKED | Customer ID who made the deposit. |
| R3 | Amount | decimal | CODE-BACKED | Deposit amount in the deposit's currency. |
| R4 | PaymentDate | datetime | CODE-BACKED | When the deposit payment occurred. Within GETDATE()-1 to GETDATE() window. |
| R5 | FundingID | int | CODE-BACKED | The payment instrument used. Matches @fundingTypeID filter. |
| R6 | Status | nvarchar | CODE-BACKED | Deposit payment status name (from Dictionary.PaymentStatus). E.g., "Approved", "Pending", "Declined". |
| R7 | Country | nvarchar | CODE-BACKED | Customer's registered country name (from Dictionary.Country via Customer.Customer). |
| R8 | MID | nvarchar | CODE-BACKED | Merchant account description (from Billing.ProtocolMIDSettings) - identifies which merchant terminal processed the payment. |
| R9 | Depot | nvarchar | CODE-BACKED | Depot (payment gateway configuration) name (from Billing.Depot). |
| R10 | IsFTD | bit | CODE-BACKED | 1 = this is the customer's first-time deposit; 0 = returning depositor. |
| R11 | RiskStatus | nvarchar | CODE-BACKED | Risk management status name (from Dictionary.RiskManagementStatus). NULL if no risk flag. |
| R12 | Regulation | nvarchar | CODE-BACKED | Regulatory entity under which this deposit was processed (from Dictionary.Regulation). |
| R13 | Currency | nvarchar | CODE-BACKED | Currency abbreviation (from Dictionary.Currency). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Billing.FundingTypeDailyReport_BASE | Function call | Entire data retrieval delegated to this inline TVF |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations reporting tools | External | Caller | Called by operations/monitoring dashboards to review daily payment type performance |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_All (procedure)
└── Billing.FundingTypeDailyReport_BASE (inline TVF)
      ├── Billing.Deposit (table)
      ├── Billing.Funding (table)
      ├── Dictionary.PaymentStatus (table)
      ├── Customer.Customer (table)
      ├── Dictionary.Country (table)
      ├── Dictionary.Currency (table)
      ├── Billing.ProtocolMIDSettings (table)
      ├── Billing.Depot (table)
      ├── Dictionary.Regulation (table)
      └── Dictionary.RiskManagementStatus (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_BASE | Inline TVF | Provides all rows; this proc adds ORDER BY DepositID + FOR JSON AUTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations dashboards | External | Calls for full deposit detail view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. No SET NOCOUNT ON. No explicit NOLOCK (inherited from BASE function's underlying table references). FOR JSON AUTO produces a JSON array output. Time window is a live 24h sliding window - results change continuously.

---

## 8. Sample Queries

### 8.1 Get full yesterday deposit detail for funding type 35

```sql
EXEC [Billing].[FundingTypeDailyReport_All] @fundingTypeID = 35;
-- Returns JSON array ordered by DepositID
```

### 8.2 Parse the JSON output

```sql
DECLARE @json NVARCHAR(MAX);
EXEC [Billing].[FundingTypeDailyReport_All] @fundingTypeID = 35;
-- Use OPENJSON to parse the result into rows if needed
```

### 8.3 Query the BASE function directly for ad-hoc analysis

```sql
SELECT *
FROM [Billing].[FundingTypeDailyReport_BASE](35) WITH (NOLOCK)
ORDER BY DepositID;
-- Non-JSON version for SQL-side analysis
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_All | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingTypeDailyReport_All.sql*

# Billing.DepositMetricByIdGet

> Returns a fully human-readable deposit metrics row for a single deposit ID - the query used by the Analytics service (eToro.Payments.Analytics) to enrich raw deposit events before forwarding them to Anodot for payments monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - returns one enriched row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositMetricByIdGet` returns a single enriched deposit record with all lookup values resolved to human-readable names. It is the primary data-retrieval SP for the **eToro.Payments.Analytics service** (`eToro.Payments.Analytics`), which processes deposit status change events from a Service Bus queue and forwards structured metrics to the Anodot analytics platform (metric name: `DepositV2` in production).

When a deposit status changes (e.g., PaymentStatusID=2 = Approved), the Analytics service receives a queue message `{"PaymentStatusId": 2, "DepositId": 12345}`, calls this procedure to get the full enriched deposit details, and sends the result to Anodot as a metric event. The procedure handles the lookup-table resolution so the Analytics service receives ready-to-use named dimensions.

Created for PAYIL-4958 (Elrom B., 18-08-2022). Extended with SessionID (PAYIL-5611, Dec 2022), CID (PAYIL-6793, Jul 2023), and AmountUSD (Dec 2023). The SP evolved from an initial version using strict INNER JOINs on Customer.CustomerStatic and BackOffice.Customer to using OUTER APPLYs for Country and VerificationLevel, making it more resilient when those optional fields are absent.

---

## 2. Business Logic

### 2.1 Anodot Metric Enrichment

**What**: Resolves all FK/ID columns into named dimensions for the Anodot analytics pipeline.

**Columns/Parameters Involved**: `@CountryID`, `@VerificationLevelID`, all output columns

**Rules**:
- The procedure does NOT look up CountryID and VerificationLevelID from the deposit record itself - instead it accepts them as input parameters. This is because the Analytics service fetches them separately from the UserAPI (`api/v2/users/{0}`) before calling this SP.
- The hardcoded output `'BillingService' AS ApplicationIdentifier` identifies the data source in Anodot.
- `AmountUSD = CAST(D.Amount * D.ExchangeRate AS DECIMAL(10,2))` converts the deposit amount to USD using the exchange rate stored at deposit time.
- `IIF(D.IsFTD = 1, 'Yes', 'No') AS FTD` labels First Time Deposits - key metric for acquisition analytics.
- Metric name in production Anodot: `DepositV2`. Integration/Staging uses `DepositV3` (per CCM config `PAYMENTS_DEPOSIT_ANODOT_METRIC_NAME`).

### 2.2 OUTER APPLY for Optional Dimensions

**What**: Country and VerificationLevel are resolved via OUTER APPLY rather than INNER JOIN for resilience.

**Columns/Parameters Involved**: `@CountryID`, `@VerificationLevelID`, `C.Name (Country)`, `VL.Name (VerificationLevel)`

**Rules**:
- `OUTER APPLY (SELECT Name FROM Dictionary.Country WHERE CountryID = @CountryID)` - returns NULL if @CountryID has no match (instead of dropping the row).
- `OUTER APPLY (SELECT Name FROM Dictionary.VerificationLevel WHERE ID = @VerificationLevelID)` - same pattern.
- The commented-out INNER JOIN versions (Customer.CustomerStatic, BackOffice.Customer) were removed - the Analytics service now gets this data from UserAPI directly.
- Depot is LEFT JOINed (may be NULL for some deposits).

### 2.3 Feature Flag Control (PROD Disabled)

**What**: The Analytics service's deposit processing is currently disabled in production via CCM.

**Columns/Parameters Involved**: N/A (application-level control)

**Rules**:
- CCM flag `FF_ENABLE_DEPOSIT_MESSAGES_HANDLING = false` in PROD (true in INT/STG).
- This means the SP is currently NOT being called in production by the Analytics service, but the SP itself is deployed and available.
- Permissions: EXECUTE granted to both `DepositUser` and `AnalyticsServiceUser`. (Per Confluence: Atlassian source MEDIUM confidence - application-level flag status may have changed since 2022.)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | PK of the deposit to enrich. FK to Billing.Deposit.DepositID. The SP returns exactly one row for this deposit (or zero if not found). Passed by the Analytics service from the queue message: {"DepositId": <value>}. |
| 2 | @VerificationLevelID | INT | NO | - | VERIFIED | Verification level ID of the depositing customer. Sourced by Analytics service from UserAPI (api/v2/users/{cid}). Resolved to name via OUTER APPLY on Dictionary.VerificationLevel. NULL-safe: returns NULL name if no match. (Source: Confluence - Analytics service Implementation) |
| 3 | @CountryID | INT | NO | - | VERIFIED | Country ID of the depositing customer. Sourced by Analytics service from UserAPI (api/v2/users/{cid}). Resolved to name via OUTER APPLY on Dictionary.Country. NULL-safe: returns NULL name if no match. (Source: Confluence - Analytics service Implementation) |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | ID | INT | NO | - | CODE-BACKED | Echo of @DepositID. The deposit's primary key. Used by Anodot as the metric identifier. |
| 5 | Country | NVARCHAR | YES | - | VERIFIED | Customer's country name (e.g., 'United Kingdom'). Resolved from @CountryID via Dictionary.Country. NULL if @CountryID has no match. Anodot dimension. (Source: Confluence) |
| 6 | FundingType | NVARCHAR | NO | - | CODE-BACKED | Payment method name (e.g., 'CreditCard', 'PayPal'). Resolved from Billing.Funding.FundingTypeID via Dictionary.FundingType. Anodot dimension. |
| 7 | Mid | VARCHAR | YES | - | CODE-BACKED | MID (Merchant ID / Protocol MID) value from Billing.ProtocolMIDSettings. Identifies the specific payment gateway merchant account used for this deposit. NULL if no ProtocolMIDSettingsID on the deposit. |
| 8 | VerificationLevel | NVARCHAR | YES | - | VERIFIED | Customer's KYC verification level name (e.g., 'Verified', 'Pending'). Resolved from @VerificationLevelID via Dictionary.VerificationLevel. Anodot dimension. (Source: Confluence) |
| 9 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulatory framework under which this deposit was processed (e.g., 'CySEC', 'FCA'). From Billing.Deposit.ProcessRegulationID via Dictionary.Regulation. NULL if not set. |
| 10 | PaymentStatus | NVARCHAR | NO | - | CODE-BACKED | Human-readable payment status name (e.g., 'Approved', 'Declined'). Resolved from Billing.Deposit.PaymentStatusID via Dictionary.PaymentStatus. Key Anodot metric dimension. |
| 11 | RiskManagementStatus | NVARCHAR | YES | - | CODE-BACKED | Risk management status name. Resolved from Billing.Deposit.RiskManagementStatusID via Dictionary.RiskManagementStatus. NULL if no risk hold. |
| 12 | Depot | NVARCHAR | YES | - | CODE-BACKED | Depot (payment provider account / bucket) name. Resolved from Billing.Deposit.DepotID via Billing.Depot. NULL if no depot assigned. |
| 13 | Currency | CHAR(3) | NO | - | CODE-BACKED | ISO currency abbreviation of the deposit (e.g., 'USD', 'EUR'). From Billing.Deposit.CurrencyID via Dictionary.Currency.Abbreviation. |
| 14 | FTD | VARCHAR(3) | NO | - | CODE-BACKED | First Time Deposit flag as text: 'Yes' if Billing.Deposit.IsFTD=1 (customer's first deposit), 'No' otherwise. Key acquisition metric for Anodot. |
| 15 | ApplicationIdentifier | VARCHAR(14) | NO | - | VERIFIED | Hardcoded constant 'BillingService'. Identifies the data source in Anodot metrics. Confirms this SP is owned by the Billing/Payments domain. (Source: Confluence) |
| 16 | SessionID | BIGINT | YES | - | CODE-BACKED | Session identifier from Billing.Deposit.SessionID. Added PAYIL-5611 (Dec 2022). Links the deposit to the user's web/app session at time of payment. |
| 17 | CID | INT | YES | - | CODE-BACKED | Customer ID from Billing.Deposit.CID. Added PAYIL-6793 (Jul 2023). Allows the Analytics service to correlate the deposit metric with a specific customer. |
| 18 | FundingID | INT | NO | - | CODE-BACKED | FK to Billing.Funding.FundingID. The specific funding instrument (card/account) used for this deposit. Allows downstream linking to full funding details. |
| 19 | DepositType | NVARCHAR | YES | - | CODE-BACKED | Deposit type name (e.g., standard, recurring). Resolved from Billing.Deposit.DepositTypeID via Dictionary.DepositType. NULL if not categorized. |
| 20 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method category ID. From Billing.Funding.FundingTypeID. Numeric form of FundingType - allows Anodot filtering by ID in addition to name. |
| 21 | AmountUSD | DECIMAL(10,2) | YES | - | CODE-BACKED | Deposit amount converted to USD: `CAST(D.Amount * D.ExchangeRate AS DECIMAL(10,2))`. Added Dec 2023. ExchangeRate is the rate stored at deposit time. Allows cross-currency amount comparison in Anodot. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | READ (INNER JOIN base) | Primary data source - all deposit fields. |
| FundingID | Billing.Funding | JOIN | Resolves FundingTypeID from the deposit's funding instrument. |
| FundingTypeID | Dictionary.FundingType | JOIN | Resolves payment method name. |
| @CountryID | Dictionary.Country | OUTER APPLY | Resolves country name from parameter (not deposit column). |
| @VerificationLevelID | Dictionary.VerificationLevel | OUTER APPLY | Resolves KYC level name from parameter. |
| PaymentStatusID | Dictionary.PaymentStatus | JOIN | Resolves payment status name. |
| DepotID | Billing.Depot | LEFT JOIN | Resolves depot name (optional). |
| CurrencyID | Dictionary.Currency | JOIN | Resolves currency abbreviation. |
| ProcessRegulationID | Dictionary.Regulation | LEFT JOIN | Resolves regulation name (optional). |
| RiskManagementStatusID | Dictionary.RiskManagementStatus | LEFT JOIN | Resolves risk status name (optional). |
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | LEFT JOIN | Resolves MID value (optional). |
| DepositTypeID | Dictionary.DepositType | LEFT JOIN | Resolves deposit type name (optional). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| eToro.Payments.Analytics service | @DepositID | EXEC | Called when a deposit event message arrives on the Service Bus queue. Enriches the raw deposit ID into named dimensions for Anodot. (Source: Confluence - MEDIUM confidence, feature flag currently disabled in PROD) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositMetricByIdGet (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── Billing.ProtocolMIDSettings (table)
├── Dictionary.FundingType (table)
├── Dictionary.PaymentStatus (table)
├── Dictionary.Currency (table)
├── Dictionary.Regulation (table)
├── Dictionary.RiskManagementStatus (table)
├── Dictionary.Country (table)
├── Dictionary.VerificationLevel (table)
└── Dictionary.DepositType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary source - filtered by @DepositID (INNER JOIN). |
| Billing.Funding | Table | INNER JOIN to resolve FundingTypeID from FundingID. |
| Billing.Depot | Table | LEFT JOIN to resolve depot name from DepotID. |
| Billing.ProtocolMIDSettings | Table | LEFT JOIN to resolve MID value from ProtocolMIDSettingsID. |
| Dictionary.FundingType | Table (cross-schema) | INNER JOIN for payment method name. |
| Dictionary.PaymentStatus | Table (cross-schema) | INNER JOIN for status name. |
| Dictionary.Currency | Table (cross-schema) | INNER JOIN for currency abbreviation. |
| Dictionary.Regulation | Table (cross-schema) | LEFT JOIN for regulation name. |
| Dictionary.RiskManagementStatus | Table (cross-schema) | LEFT JOIN for risk status name. |
| Dictionary.Country | Table (cross-schema) | OUTER APPLY for country name (from @CountryID param). |
| Dictionary.VerificationLevel | Table (cross-schema) | OUTER APPLY for KYC level name (from @VerificationLevelID param). |
| Dictionary.DepositType | Table (cross-schema) | LEFT JOIN for deposit type name. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToro.Payments.Analytics (external service) | External service | EXEC - enriches deposit events for Anodot. Uses AnalyticsServiceUser DB account. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Version history**:
- 18-08-2022 (PAYIL-4958, Elrom B.): Created - base enrichment for Analytics service.
- 27-12-2022 (PAYIL-5611, Shay O.): Added SessionID to SELECT list.
- 03-07-2023 (PAYIL-6793, Dor I.): Added CID column.
- 04-12-2023 (Elrom B.): Added AmountUSD (Amount * ExchangeRate).

---

## 8. Sample Queries

### 8.1 Get enriched metrics for a specific deposit

```sql
EXEC [Billing].[DepositMetricByIdGet]
    @DepositID = 2720454,
    @VerificationLevelID = 3,   -- e.g., from UserAPI
    @CountryID = 82;            -- e.g., from UserAPI (82 = United Kingdom)
```

### 8.2 Verify the output for an approved deposit

```sql
-- First check the deposit exists and its status
SELECT DepositID, PaymentStatusID, CID, Amount, CurrencyID, IsFTD
FROM [Billing].[Deposit] WITH (NOLOCK)
WHERE DepositID = 2720454;

-- Then call the proc to see the enriched output
EXEC [Billing].[DepositMetricByIdGet]
    @DepositID = 2720454,
    @VerificationLevelID = 0,
    @CountryID = 0;
```

### 8.3 Find recent FTD (first-time deposit) approved deposits for metrics testing

```sql
SELECT TOP 5 DepositID, CID, PaymentStatusID, CurrencyID, Amount
FROM [Billing].[Deposit] WITH (NOLOCK)
WHERE IsFTD = 1
  AND PaymentStatusID = 2
ORDER BY DepositID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Analytics service Implementation](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11812634942) | Confluence | Confirmed this SP is called by eToro.Payments.Analytics service; called when deposit events arrive on Service Bus; @CountryID and @VerificationLevelID sourced from UserAPI; ApplicationIdentifier='BillingService' confirmed; Anodot metric name is DepositV2 (PROD) / DepositV3 (INT/STG); FF_ENABLE_DEPOSIT_MESSAGES_HANDLING=false in PROD as of Oct 2022 (may have changed). |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositMetricByIdGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositMetricByIdGet.sql*

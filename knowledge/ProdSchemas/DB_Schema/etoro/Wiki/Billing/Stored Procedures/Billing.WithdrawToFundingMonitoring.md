# Billing.WithdrawToFundingMonitoring

> Returns a window of WithdrawToFunding activity enriched with funding type, status, cashout mode, customer country, and depot for Splunk dashboard monitoring; defaults to the last 5 minutes when no date range is provided.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate + @ToDate window on bwtf.ModificationDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFundingMonitoring` is a Splunk data-feed procedure created for a withdrawal cashout dashboard (KateM, 14/11/2021). It provides a time-windowed view of withdrawal payment leg activity, enriched with human-readable labels from multiple dictionary tables.

The default 5-minute rolling window (when no dates are specified) is designed for periodic polling by a monitoring agent or Splunk forwarder - each call retrieves the most recently modified payment legs for real-time operational visibility: active statuses, funding method breakdown, cashout modes, geographic distribution of withdrawals, and amount values.

The result set deliberately excludes PII (no customer name, email, or account ID) and returns operational/categorical dimensions: funding type, status name, cashout mode, country, country currency abbreviation, depot, and amount - suitable for Splunk aggregations, trend lines, and alerting without data privacy concerns.

**Note**: `Dictionary.Currency` (alias `dpc`) is LEFT JOINed for `ProcessCurrencyID` but none of its columns appear in the SELECT. The `Currency` column in the output is actually the `Abbreviation` field from `Dictionary.Country` (the customer's local currency code derived from their country), not the processing currency. This is the intended behavior for a geographic dashboard dimension.

---

## 2. Business Logic

### 2.1 Rolling 5-Minute Default Window

**What**: When called without parameters, automatically scopes to the last 5 minutes.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `bwtf.ModificationDate`

**Rules**:
- `IF @FromDate IS NULL: SET @FromDate = DATEADD(MINUTE, -5, GETDATE())`
- `IF @ToDate IS NULL: SET @ToDate = GETDATE()`
- Uses `GETDATE()` (local server time), not `GETUTCDATE()` - consistent with Splunk polling integration expectations
- Range is inclusive on both ends: `ModificationDate >= @FromDate AND ModificationDate <= @ToDate`
- Callers can supply explicit dates for historical backfill or broader windows

### 2.2 Multi-Dimension Enrichment JOINs

**What**: Five LEFT JOINs enrich the raw WTF data with categorical labels for dashboard dimensions.

**Columns/Parameters Involved**: `FundingType`, `Status`, `CashoutModeName`, `Country`, `Currency`, `Depot`

**Rules**:
- `Billing.Withdraw` (INNER JOIN on WithdrawID) - provides FundingTypeID and CID
- `Customer.CustomerStatic` (INNER JOIN on CID) - provides CountryID for geographic dimension
- `Dictionary.CashoutMode` (LEFT JOIN on CashoutModeID) - cashout processing mode name
- `Dictionary.FundingType` (LEFT JOIN on FundingTypeID from Billing.Withdraw) - payment method type (card, wire, wallet, etc.)
- `Dictionary.Country` (LEFT JOIN on CountryID) - customer country name and currency abbreviation
- `Dictionary.Currency` (LEFT JOIN on ProcessCurrencyID) - JOINed but not used in SELECT
- `Dictionary.CashoutStatus` (LEFT JOIN on CashoutStatusID) - human-readable status name
- `Billing.Depot` (LEFT JOIN on DepotID) - depot/acquirer name

**Output columns**:
```
FundingType    -> Dictionary.FundingType.Name  (payment method: Card, Wire, etc.)
Status         -> Dictionary.CashoutStatus.Name (1=Pending, 2=InProcess, 3=Processed, ...)
CashoutModeName -> Dictionary.CashoutMode.CashoutModeName (processing mode)
Country        -> Dictionary.Country.Name (customer's country)
Currency       -> Dictionary.Country.Abbreviation (customer's local currency code, e.g., "USD", "EUR")
Depot          -> Billing.Depot.Name (payment acquirer/gateway name)
Value          -> Billing.WithdrawToFunding.Amount (payment amount in ProcessCurrencyID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | datetime | YES | NULL | CODE-BACKED | Start of the monitoring window. NULL defaults to 5 minutes before GETDATE(). Inclusive filter on bwtf.ModificationDate. |
| 2 | @ToDate | datetime | YES | NULL | CODE-BACKED | End of the monitoring window. NULL defaults to GETDATE(). Inclusive filter on bwtf.ModificationDate. |

### Output Columns

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | FundingType | nvarchar | YES | CODE-BACKED | Payment method type name from `Dictionary.FundingType` (e.g., "Credit Card", "Wire Transfer", "Skrill"). Sourced from `Billing.Withdraw.FundingTypeID`. NULL if FundingTypeID is unmapped. |
| 2 | Status | nvarchar | YES | CODE-BACKED | Human-readable cashout status name from `Dictionary.CashoutStatus`. Key values: 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 7=Rejected. NULL if CashoutStatusID is unmapped. |
| 3 | CashoutModeName | nvarchar | YES | CODE-BACKED | Cashout processing mode from `Dictionary.CashoutMode`. Identifies the processing path (e.g., standard, ACH, eToroMoney). NULL if CashoutModeID is NULL (legacy records). |
| 4 | Country | nvarchar | YES | CODE-BACKED | Customer's country name from `Dictionary.Country`. Derived via `Customer.CustomerStatic.CountryID`. NULL if country is unmapped. |
| 5 | Currency | nvarchar | YES | CODE-BACKED | Customer's local currency abbreviation (ISO code) from `Dictionary.Country.Abbreviation`. Represents the customer's home currency, NOT the payment processing currency. NULL if country is unmapped. |
| 6 | Depot | nvarchar | YES | CODE-BACKED | Payment acquirer/gateway depot name from `Billing.Depot`. Identifies which payment provider processed this leg. NULL if DepotID is NULL or unmapped. |
| 7 | Value | money | YES | CODE-BACKED | Payment amount in the processing currency from `Billing.WithdrawToFunding.Amount`. Used for volume monitoring and alerting in the Splunk dashboard. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| bwtf | Billing.WithdrawToFunding | Reader | Primary source, filtered by ModificationDate window |
| bw.WithdrawID | Billing.Withdraw | INNER JOIN | Provides FundingTypeID and CID for enrichment |
| bw.CID | Customer.CustomerStatic | INNER JOIN | Provides CountryID for geographic dimension |
| bwtf.CashoutModeID | Dictionary.CashoutMode | LEFT JOIN | Cashout mode name |
| bw.FundingTypeID | Dictionary.FundingType | LEFT JOIN | Payment method type name |
| ccs.CountryID | Dictionary.Country | LEFT JOIN | Country name + currency abbreviation |
| bwtf.ProcessCurrencyID | Dictionary.Currency | LEFT JOIN | JOINed but not used in SELECT (unused join) |
| bwtf.CashoutStatusID | Dictionary.CashoutStatus | LEFT JOIN | Status name |
| bwtf.DepotID | Billing.Depot | LEFT JOIN | Depot/acquirer name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Splunk monitoring forwarder (application) | @FromDate, @ToDate | Caller | Polls on a scheduled interval (likely every 5 min) to feed cashout monitoring dashboard |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingMonitoring (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Customer.CustomerStatic (table)
├── Dictionary.CashoutMode (table)
├── Dictionary.FundingType (table)
├── Dictionary.Country (table)
├── Dictionary.Currency (table) [unused in SELECT]
├── Dictionary.CashoutStatus (table)
└── Billing.Depot (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary source - filtered by ModificationDate window |
| Billing.Withdraw | Table | INNER JOIN for FundingTypeID and CID |
| Customer.CustomerStatic | Table | INNER JOIN for CountryID |
| Dictionary.CashoutMode | Table | LEFT JOIN for mode name |
| Dictionary.FundingType | Table | LEFT JOIN for payment type name |
| Dictionary.Country | Table | LEFT JOIN for country name and currency abbreviation |
| Dictionary.Currency | Table | LEFT JOIN for ProcessCurrencyID (unused in SELECT) |
| Dictionary.CashoutStatus | Table | LEFT JOIN for status name |
| Billing.Depot | Table | LEFT JOIN for depot name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Splunk monitoring service (application) | External application | Caller - periodic polling for cashout activity dashboard |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No SET NOCOUNT ON | Design | Row count messages are sent to the caller (unusual for read procedures) |
| No transaction | Design | Read-only SELECT; no explicit BEGIN TRAN |
| GETDATE() not GETUTCDATE() | Design | Default window uses local server time. Callers supplying explicit dates should use the same time basis. |
| Unused Dictionary.Currency JOIN | Design | `dpc` (Dictionary.Currency LEFT JOIN on ProcessCurrencyID) is defined but not referenced in SELECT. Likely added for potential future use or was removed from SELECT without removing the JOIN. |
| No NOLOCK hints | Design | Unlike most Billing read procedures, no WITH(NOLOCK) hints are used on the JOINed tables. |

---

## 8. Sample Queries

### 8.1 Run with default 5-minute window (Splunk polling mode)

```sql
EXEC Billing.WithdrawToFundingMonitoring;
-- Returns WTF records modified in the last 5 minutes
```

### 8.2 Run for a specific historical window

```sql
EXEC Billing.WithdrawToFundingMonitoring
    @FromDate = '2021-11-14 12:47:09.100',
    @ToDate   = '2021-11-14 13:22:42.473';
```

### 8.3 Direct equivalent query

```sql
DECLARE @FromDate DATETIME = DATEADD(MINUTE, -5, GETDATE());
DECLARE @ToDate   DATETIME = GETDATE();

SELECT
     dft.[Name]            AS FundingType
    ,dcs.[Name]            AS [Status]
    ,dcm.CashoutModeName
    ,dc.[Name]             AS Country
    ,dc.Abbreviation       AS Currency
    ,bd.[Name]             AS Depot
    ,bwtf.Amount           AS [Value]
FROM Billing.WithdrawToFunding AS bwtf
    INNER JOIN Billing.Withdraw          AS bw  ON bwtf.WithdrawID = bw.WithdrawID
    INNER JOIN Customer.CustomerStatic   AS ccs ON bw.CID = ccs.CID
    LEFT  JOIN Dictionary.CashoutMode    AS dcm ON bwtf.CashoutModeID = dcm.CashoutModeID
    LEFT  JOIN Dictionary.FundingType    AS dft ON bw.FundingTypeID = dft.FundingTypeID
    LEFT  JOIN Dictionary.Country        AS dc  ON ccs.CountryID = dc.CountryID
    LEFT  JOIN Dictionary.CashoutStatus  AS dcs ON bwtf.CashoutStatusID = dcs.CashoutStatusID
    LEFT  JOIN Billing.Depot             AS bd  ON bwtf.DepotID = bd.DepotID
WHERE bwtf.ModificationDate >= @FromDate
  AND bwtf.ModificationDate <= @ToDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT (called from application) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingMonitoring | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingMonitoring.sql*

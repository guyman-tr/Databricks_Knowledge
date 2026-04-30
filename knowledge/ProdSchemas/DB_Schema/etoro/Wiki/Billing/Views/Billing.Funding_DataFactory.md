# Billing.Funding_DataFactory

> Azure Data Factory integration view exposing the core Billing.Funding columns (excluding computed hash/dedup fields) with the pre-computed PaymentDetails trigger column, for ETL pipeline consumption.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | FundingID (from Billing.Funding) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.Funding_DataFactory` is a purpose-built view for Azure Data Factory (ADF) pipeline extraction. It exposes the business-relevant columns from `Billing.Funding` without the heavy computed columns that are internal to the DB engine (FundingDataCheckSum, SecuredCardData, FundingHash, Parameter). It includes the trigger-computed `PaymentDetails` column which provides a pre-computed human-readable payment account identifier.

The view exists to give ADF pipelines a clean, stable interface to payment instrument data that:
1. Excludes internal computed hash/dedup columns not needed by downstream analytics
2. Includes the trigger-maintained `PaymentDetails` (a human-readable account description computed by `Billing.FormatFundingPaymentDetailsForWithdraw` on each Funding change)
3. Exposes the raw FundingData XML (not CAST to NVARCHAR like other views) - allowing ADF to handle XML serialization
4. Has a predictable column list that won't break when internal computed columns are added/changed

Created by Ran Ovadia on 21/02/2023. Used by ADF pipelines for downstream data warehousing, reporting, or external system integration.

---

## 2. Business Logic

No complex business logic. This is a pure column-selection view. The key design decisions are:
- FundingData exposed as native XML type (not CAST to NVARCHAR like in other views)
- PaymentDetails included (trigger-computed, not a view-computed CASE expression)
- Hash/dedup computed columns (FundingDataCheckSum, SecuredCardData, FundingHash, Parameter) excluded

---

## 3. Data Overview

N/A - exposes all ~3.5M rows of Billing.Funding. Matches Billing.Funding data exactly, minus the excluded computed columns. FundingData is XML type, PaymentDetails is the trigger-maintained string column.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Payment instrument PK. From Billing.Funding. IDENTITY(1000,1). |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. From Billing.Funding. 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 33=eToroMoney, etc. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Operations manager ID. NULL=self-registered. From Billing.Funding. |
| 4 | IsBlocked | bit | NO | - | CODE-BACKED | 1=instrument blocked. 0=active. From Billing.Funding. |
| 5 | BlockedDescription | nvarchar | YES | - | CODE-BACKED | Block reason text. From Billing.Funding. |
| 6 | BlockedAt | datetime | YES | - | CODE-BACKED | Block timestamp. From Billing.Funding. |
| 7 | FundingData | xml | YES | - | CODE-BACKED | Provider-specific instrument data as native XML. Not CAST to NVARCHAR (unlike other Funding views). Subject to DDM masking. ADF pipelines must handle XML serialization. |
| 8 | IsRefundExcluded | bit | NO | - | CODE-BACKED | 1=excluded from automatic refund. From Billing.Funding. |
| 9 | DocumentRequired | bit | NO | - | CODE-BACKED | 1=KYC documentation required. From Billing.Funding. |
| 10 | DateCreated | datetime | NO | - | CODE-BACKED | UTC timestamp of instrument registration. From Billing.Funding. |
| 11 | PaymentDetails | nvarchar | YES | - | CODE-BACKED | Pre-computed human-readable payment account identifier. Trigger-maintained column from Billing.Funding (populated by TR_FundingPaymentDetails via Billing.FormatFundingPaymentDetailsForWithdraw on each FundingData change). Unlike other views where PaymentDetails is computed in the view's CASE expression, this is a stored column from the base table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | Billing.Funding | Source (FROM - no JOIN) | Single-table view; all rows from Billing.Funding |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Azure Data Factory pipelines | All columns | ETL source | ADF reads this view as the source for payment instrument data extraction |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Funding_DataFactory (view)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | FROM source: all rows with selected columns (excludes FundingDataCheckSum, SecuredCardData, FundingHash, Parameter) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Azure Data Factory pipelines | ETL consumer | Extracts payment instrument data for analytics/data warehouse |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Key design note: FundingData is exposed as native XML (not NVARCHAR cast), which is the primary difference from other Funding views. This requires ADF to handle XML column types appropriately in the destination dataset. Excluded computed columns: FundingDataCheckSum (CHECKSUM hash), SecuredCardData (card token), FundingHash (dedup hash), Parameter (key identifier function). These are internal DB columns not needed for analytics.

---

## 8. Sample Queries

### 8.1 Extract all active (non-blocked) payment instruments

```sql
SELECT FundingID, FundingTypeID, PaymentDetails, DateCreated
FROM Billing.Funding_DataFactory WITH (NOLOCK)
WHERE IsBlocked = 0
ORDER BY DateCreated DESC
```

### 8.2 Count instruments by payment method type

```sql
SELECT FundingTypeID, COUNT(*) AS InstrumentCount
FROM Billing.Funding_DataFactory WITH (NOLOCK)
GROUP BY FundingTypeID
ORDER BY InstrumentCount DESC
```

### 8.3 Find recently registered instruments

```sql
SELECT FundingID, FundingTypeID, PaymentDetails, DateCreated, IsBlocked
FROM Billing.Funding_DataFactory WITH (NOLOCK)
WHERE DateCreated >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY DateCreated DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Funding_DataFactory | Type: View | Source: etoro/etoro/Billing/Views/Billing.Funding_DataFactory.sql*

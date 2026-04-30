# AffiliateCommission.GetCreditTriggeredEvents

> Claims and returns triggered credit events for commission processing, joining attribution, aggregated customer data, and affiliate configuration to determine eligibility for re-evaluation.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns claimed CreditEvent rows with eligibility context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCreditTriggeredEvents is the most complex queue consumer in the credit commission pipeline. When a credit event's attribution changes (non-organic update, re-attribution, customer aggregated data change, or contract plan modification), this procedure claims the triggered events and returns them enriched with the context needed for commission re-evaluation.

This procedure exists because credit commission calculations depend on multiple data sources that can change independently: the customer's registration metadata may be updated (re-attribution to a different affiliate), the customer's aggregated trading data may change (triggering CPA eligibility), or the affiliate's contract plan may be modified (changing rates). Any of these changes can trigger a commission re-evaluation.

The procedure joins CreditEvent with RegistrationMetaData (for affiliate attribution), CustomerAggregatedData (for trading activity), the affiliate type chain (tblaff_Affiliates -> tblaff_AffiliateTypes), and multiple plan tables (FirstPositionAssetPlan, IOBPlan, ISAPlan) to return a complete picture for the commission engine. The complex WHERE clause determines which events are eligible for re-processing based on change detection across all these data sources.

---

## 2. Business Logic

### 2.1 Multi-Source Change Detection

**What**: Events are eligible for re-processing if ANY of their data sources changed since the last check.

**Columns/Parameters Involved**: `LastCheckDate`, `NonOrganicUpdated`, `ReAttributeUpdated`, `CustomerAggregatedData.DateModified`, `FirstPositionAssetPlan.DateModified`, `TraderFirstAssetPosition.DateAdded`

**Rules**:
- LastCheckDate (computed via dbo.InlineMax) = MAX of all source modification timestamps
- If LastCheckDate > CreditEvent.LastCheckDate, the event has changed and needs re-evaluation
- Change sources: customer aggregated data, non-organic attribution update, contract plan modification, re-attribution, first asset position tracking
- The COALESCE with GETUTCDATE() ensures new events without timestamps still get processed

### 2.2 Eligibility Filtering

**What**: Complex rules determine which credit events qualify for commission processing.

**Columns/Parameters Involved**: `CreditTypeID`, `IsFirstDeposit`, `IOBPlan`, `ISAPlan`, `IsTradeRequired`

**Rules**:
- For CreditTypeID = 1 (deposits): only first deposits qualify (IsFirstDeposit = 1); other credit types always qualify
- Events are eligible if ANY of these conditions hold:
  - IOBPlan or ISAPlan exists for the affiliate type (introduction/ISA commissions always process)
  - Customer has no CustomerAggregatedData AND affiliate type does not require trades (IsTradeRequired = 0)
  - A data source changed since last check (detected via dbo.InlineMax comparison)

### 2.3 Contract Change Detection

**What**: Detects if the affiliate's FirstPositionAssetPlan contract was modified since last check.

**Columns/Parameters Involved**: `ContractChanged` (output), `FirstPositionAssetPlan.DateModified`

**Rules**:
- ContractChanged = 1 if FirstPositionAssetPlan.DateModified > CreditEvent.LastCheckDate
- This signals the commission engine to recalculate using updated rates
- Uses CROSS APPLY with MAX(DateModified) to get the latest plan change for the affiliate type

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExpirationInDays | int (IN) | NO | - | CODE-BACKED | How far back to look for triggered credit events. Events with CreditDate older than this are ignored. |
| 2 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition for concurrent consumer isolation. |
| 3 | @LockDeferredInMinutes | int (IN) | YES | 1 | CODE-BACKED | Minimum age of DateModified before re-claim. Default 1 minute. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | ID | bigint | - | - | CODE-BACKED | CreditEvent primary key. |
| 5 | CreditID | bigint | - | - | CODE-BACKED | The credit record that triggered the event. FK to Credit. |
| 6 | CreditDate | datetime | - | - | CODE-BACKED | When the credit (deposit/chargeback) occurred. |
| 7 | Amount | money | - | - | CODE-BACKED | Credit amount. |
| 8 | IsFirstDeposit | bit | - | - | CODE-BACKED | Whether this was the customer's first deposit. Critical for CPA qualification. |
| 9 | CreditTypeID | int | - | - | CODE-BACKED | Credit type: 1=Deposit, 4/5=Chargeback. Determines processing rules. |
| 10 | CountryID | int | - | - | CODE-BACKED | Customer's country for country-specific commission rates. |
| 11 | ProviderID | bigint | - | - | CODE-BACKED | Current provider in the chain. |
| 12 | RealProviderID | bigint | - | - | CODE-BACKED | Actual executing provider. |
| 13 | OriginalProviderID | bigint | - | - | CODE-BACKED | Original broker/provider entity. |
| 14 | CID | bigint | - | - | CODE-BACKED | Customer ID. |
| 15 | AffiliateID | int | - | - | CODE-BACKED | Attributed affiliate from CreditEvent (resolved via RegistrationMetaData join). |
| 16 | LastCheckDate | datetime | - | - | CODE-BACKED | Computed: MAX across all source modification timestamps. Tells the engine when data last changed. |
| 17 | Source | nvarchar(50) | - | - | CODE-BACKED | Event source identifier. |
| 18 | GCID | bigint | - | - | CODE-BACKED | Global Customer ID. Added PART-3405. |
| 19 | CreditSource | - | - | - | CODE-BACKED | Source system that originated the credit (e.g., payment gateway identifier). |
| 20 | ProductID | int | - | - | CODE-BACKED | ISA product identifier for ISA plan commission matching. Added PART-5458. |
| 21 | ContractChanged | bit | - | - | CODE-BACKED | Computed: 1 if the affiliate's FirstPositionAssetPlan was modified since LastCheckDate. Signals rate recalculation needed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditEvent | READ+WRITE (UPDATE OUTPUT) | Claims triggered events by setting DateModified |
| - | AffiliateCommission.CustomerAggregatedData | READ (LEFT JOIN) | Customer's aggregated trading data for CPA eligibility |
| - | AffiliateCommission.RegistrationMetaData | READ (JOIN) | Attribution data linking customer to affiliate |
| - | dbo.tblaff_Affiliates | READ (JOIN) | Resolves AffiliateID to AffiliateTypeID |
| - | dbo.tblaff_AffiliateTypes | READ (JOIN) | Gets IsTradeRequired and links to plan tables |
| - | AffiliateConfiguration.TraderFirstAssetPosition | READ (LEFT JOIN) | First asset position tracking for DateAdded change detection |
| - | AffiliateConfiguration.ISAPlan | READ (LEFT JOIN) | ISA plan existence check for eligibility |
| - | AffiliateConfiguration.IOBPlan | READ (LEFT JOIN) | IOB plan existence check for eligibility |
| - | AffiliateConfiguration.FirstPositionAssetPlan | READ (CROSS APPLY) | MAX(DateModified) for contract change detection |
| - | dbo.InlineMax | Function call | Computes MAX across nullable datetime columns |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the credit commission re-evaluation service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetCreditTriggeredEvents (procedure)
+-- AffiliateCommission.CreditEvent (table)
+-- AffiliateCommission.CustomerAggregatedData (table)
+-- AffiliateCommission.RegistrationMetaData (table)
+-- dbo.tblaff_Affiliates (table, external)
+-- dbo.tblaff_AffiliateTypes (table, external)
+-- AffiliateConfiguration.TraderFirstAssetPosition (table, external)
+-- AffiliateConfiguration.ISAPlan (table, external)
+-- AffiliateConfiguration.IOBPlan (table, external)
+-- AffiliateConfiguration.FirstPositionAssetPlan (table, external)
+-- dbo.InlineMax (function, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | UPDATE + OUTPUT for event claiming |
| AffiliateCommission.CustomerAggregatedData | Table | LEFT JOIN for CPA eligibility and change detection |
| AffiliateCommission.RegistrationMetaData | Table | JOIN on CID with partition pruning (CID%50) |
| dbo.tblaff_Affiliates | Table (external) | JOIN to resolve AffiliateID to AffiliateTypeID |
| dbo.tblaff_AffiliateTypes | Table (external) | JOIN for IsTradeRequired flag |
| AffiliateConfiguration.TraderFirstAssetPosition | Table (external) | LEFT JOIN for first asset position DateAdded |
| AffiliateConfiguration.ISAPlan | Table (external) | LEFT JOIN for ISA plan existence |
| AffiliateConfiguration.IOBPlan | Table (external) | LEFT JOIN for IOB plan existence |
| AffiliateConfiguration.FirstPositionAssetPlan | Table (external) | CROSS APPLY MAX(DateModified) for contract change detection |
| dbo.InlineMax | Function (external) | Computes MAX across nullable datetime columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit commission re-evaluation service) | External | Consumes triggered events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get triggered credit events for source 'Main'
```sql
EXEC [AffiliateCommission].[GetCreditTriggeredEvents]
    @ExpirationInDays = 30,
    @Source = 'Main',
    @LockDeferredInMinutes = 1
```

### 8.2 Check for pending credit events with triggers
```sql
SELECT ce.ID, ce.CreditID, ce.CID, ce.CreditTypeID, ce.IsFirstDeposit,
       ce.NonOrganicUpdated, ce.ReAttributeUpdated, ce.LastCheckDate
FROM [AffiliateCommission].[CreditEvent] AS ce WITH (NOLOCK)
WHERE ce.CreditDate >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY ce.DateModified ASC
```

### 8.3 Count triggered events by credit type
```sql
SELECT ce.CreditTypeID, COUNT(*) AS EventCount
FROM [AffiliateCommission].[CreditEvent] AS ce WITH (NOLOCK)
WHERE ce.CreditDate >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY ce.CreditTypeID
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-5482: Added DateModified to CustomerAggregatedData (2026-01-13)
- PART-5458: ISA plan support (2026-01-22)
- PART-4763: Return IOB always, handle no-trade-required cases (2025-11-10)
- PART-3405: Added GCID to output (2025-02-23)
- PART-2448: CPA New Compensation Design + CountryID (2023-12-17)
- PART-2889: Fix RegistrationCommission AffiliateID (2023-03-28)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetCreditTriggeredEvents | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetCreditTriggeredEvents.sql*

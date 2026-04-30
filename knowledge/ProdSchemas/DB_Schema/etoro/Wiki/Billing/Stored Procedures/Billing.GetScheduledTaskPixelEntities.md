# Billing.GetScheduledTaskPixelEntities

> Post-deposit scheduler fetch for TaskID=3 (tracking pixel fires): claims pending deposits with PaymentStatusID=2, returns deposit + customer attribution data including DepositRowNumber (rank per customer), DepositCount (total approvals), and AppsFlyerID for pixel construction, then marks claimed rows as TaskState=3.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch (batch cap); returns one row per claimed deposit via OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetScheduledTaskPixelEntities` is the batch-fetch step for the tracking pixel pipeline (TaskID=3). Tracking pixels are small server-to-server requests fired to marketing platforms (Google, Facebook, affiliate networks, etc.) to record that a customer completed a deposit. This procedure selects and claims approved deposits (PaymentStatusID=2) pending pixel fire, then returns the data needed to construct the pixel request.

The result set is richer than other scheduled-task fetch procedures - it includes:
- **DepositRowNumber**: The deposit's rank within this customer's history (ROW_NUMBER over CID ordered by DepositID DESC). DepositRowNumber=1 means this is the customer's most recent deposit.
- **DepositCount**: Total number of approved deposits for this customer (subquery COUNT). Used by pixel logic to determine whether to fire FTD-specific vs repeat-deposit pixels.
- **TransactionID**: The DepositID cast to VARCHAR(20) - used as the transaction identifier in the pixel request.
- **AppsFlyerID**: The customer's AppsFlyer device ID (same field as in AppsFlyer scheduler) - allows pixel to be attributed to the mobile channel.
- **SerialID / SubSerialID**: Affiliate tracking identifiers from Customer.CustomerStatic.

Created 11 May 2017 (Geri Reshef, ticket 45108). Columns IsFTD (Jun 6, 2017) and DepositRowNumber (Jun 12, 2017) were added shortly after launch. The #STS two-stage optimization was added Aug 2020 (PAYUS-1254).

Part of the post-deposit scheduled task framework. Uses the same claim-and-mark pattern as other schedulers.

---

## 2. Business Logic

### 2.1 Two-Stage Claim Pattern (PAYUS-1254 Optimization)

**What**: Pre-selects eligible DepositIDs into #STS before the main data JOIN to reduce lock contention.

**Rules**:
- Stage 1: `INSERT #STS SELECT DepositID FROM ScheduledTaskState WHERE TaskState=0 AND TaskID=3 AND EXISTS (SELECT TOP 1 1 FROM Deposit WHERE PaymentStatusID=2 AND DepositID=BST.DepositID)`
  - TaskID=3 (Pixel) rows only
  - TaskState=0 (Pending) only
  - Only where the deposit has PaymentStatusID=2 (Approved)
- Stage 2: `SELECT TOP (@MaxEntitiesToFetch) ... FROM #STS JOIN Deposit JOIN Funding ... INTO #PostDepositTask` via OUTPUT
- Stage 3: `UPDATE ScheduledTaskState SET TaskState=3, Created=GetDate() FROM #PostDepositTask WHERE TaskID=3`

### 2.2 Deposit Position Analytics

**What**: Computes the deposit's rank and count within the customer's history for pixel segmentation.

**Rules**:
- `DepositRowNumber = ROW_NUMBER() OVER (PARTITION BY D.CID ORDER BY D.DepositID DESC)` - rank 1 = most recent deposit for this CID
  - Note: Ranking is computed at fetch time across all deposits in this batch, partitioned by CID
  - This allows pixel consumers to distinguish "first deposit in this batch for this customer" from subsequent ones
- `DepositCount = (SELECT COUNT(*) FROM Billing.Deposit WITH(NOLOCK) WHERE PaymentStatusID=2 AND CID=D.CID)` - total approved deposits for the customer
  - Combined with IsFTD flag, used to determine pixel type (FTD pixel vs repeat deposit pixel)
  - Computed per row via correlated subquery (performance consideration for large batches)

### 2.3 Amount Conversion to USD

**What**: Amount returned in USD equivalent.

**Rules**:
- `Amount = D.Amount * D.ExchangeRate` - converts from deposit currency to USD
- Same conversion as Mixpanel and AppsFlyer schedulers

### 2.4 Affiliate Attribution Fields

**What**: Returns affiliate tracking identifiers needed for pixel routing.

**Rules**:
- `SerialID = CS.SerialID` - top-level affiliate ID from Customer.CustomerStatic
- `SubSerialID = CS.SubSerialID` - sub-affiliate ID (VARCHAR(1024))
- `TransactionID = CAST(D.DepositID AS VARCHAR(20))` - deposit PK as string transaction reference
- `AppsFlyerID = CONVERT(VARCHAR(300), T.TrackingValue)` from `Customer.TrackingId WHERE TrackingID=1` (LEFT JOIN - NULL if no AppsFlyer tracking)
- `OriginalCID = CS.OriginalCID` - the customer's original CID (used for cross-account attribution)
- `LanguageID = CS.LanguageID` - customer's language (may affect pixel localization)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Maximum batch size. -1 = no limit (uses MAX INT as TOP). Typically loaded from Billing.ScheduledTaskConfig.MaxEntitiesToFetch for TaskID=3. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositID | INT | NO | - | CODE-BACKED | PK of the claimed deposit. |
| 3 | Amount | MONEY | YES | - | CODE-BACKED | `D.Amount * D.ExchangeRate` - deposit amount converted to USD. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer identifier from Billing.Deposit. |
| 5 | OriginalCID | INT | YES | - | CODE-BACKED | Original customer ID from `Customer.CustomerStatic.OriginalCID`. Used for cross-account attribution. |
| 6 | SerialID | INT | YES | - | CODE-BACKED | Top-level affiliate identifier from `Customer.CustomerStatic.SerialID`. Routes pixel to the correct affiliate. |
| 7 | SubSerialID | VARCHAR(1024) | YES | - | CODE-BACKED | Sub-affiliate identifier from `Customer.CustomerStatic.SubSerialID`. Sub-affiliate commission routing. |
| 8 | TransactionID | VARCHAR(20) | YES | - | CODE-BACKED | `CAST(D.DepositID AS VARCHAR(20))` - deposit PK as string. Used as transaction reference in pixel request. |
| 9 | FundingType | INT | YES | - | CODE-BACKED | `Billing.Funding.FundingTypeID` - payment method type identifier (integer). |
| 10 | PaymentMethod | VARCHAR(100) | YES | - | CODE-BACKED | `Dictionary.FundingType.Name` - payment method name string (e.g., "Credit Card", "PayPal"). |
| 11 | LanguageID | INT | YES | - | CODE-BACKED | Customer's language from `Customer.CustomerStatic.LanguageID`. May affect pixel localization/landing page. |
| 12 | AppsFlyerID | VARCHAR(300) | YES | - | CODE-BACKED | Customer's AppsFlyer device ID from `Customer.TrackingId WHERE TrackingID=1`. NULL if no mobile attribution. |
| 13 | DepositRowNumber | INT | YES | - | CODE-BACKED | `ROW_NUMBER() OVER (PARTITION BY D.CID ORDER BY D.DepositID DESC)` - deposit rank within batch, newest first per customer. Used to identify the most recent deposit per customer in this batch. |
| 14 | DepositCount | INT | YES | - | CODE-BACKED | Total approved (PaymentStatusID=2) deposits for this customer as of fetch time. Combined with IsFTD to determine FTD vs repeat pixel type. |
| 15 | IsFTD | BIT | YES | - | CODE-BACKED | First-time deposit flag from `Billing.Deposit.IsFTD`. Triggers FTD-specific pixel/conversion tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.ScheduledTaskState | SELECT + UPDATE | Claim TaskID=3 pending rows; mark TaskState=3 |
| DepositID | Billing.Deposit | INNER JOIN | Amount, CID, IsFTD, DepositCount subquery |
| D.FundingID | Billing.Funding | INNER JOIN | FundingTypeID |
| F.FundingTypeID | Dictionary.FundingType | INNER JOIN | PaymentMethod name |
| D.CID | Customer.CustomerStatic | INNER JOIN | OriginalCID, SerialID, SubSerialID, LanguageID |
| CS.CID | Customer.TrackingId | LEFT JOIN (TrackingID=1) | AppsFlyerID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Pixel firing scheduler (TaskID=3) | @MaxEntitiesToFetch | EXEC | Batch fetch for marketing pixel fire events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskPixelEntities (procedure)
+-- Billing.ScheduledTaskState (table)
+-- Billing.Deposit (table)
+-- Billing.Funding (table)
+-- Dictionary.FundingType (table)
+-- Customer.CustomerStatic (table, cross-schema)
+-- Customer.TrackingId (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | Claim pending TaskID=3 rows; mark TaskState=3 |
| Billing.Deposit | Table | Amount, CID, IsFTD; DepositCount subquery |
| Billing.Funding | Table | FundingTypeID |
| Dictionary.FundingType | Table | PaymentMethod name |
| Customer.CustomerStatic | Table | OriginalCID, SerialID, SubSerialID, LanguageID |
| Customer.TrackingId | Table | AppsFlyerID (TrackingID=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Pixel firing scheduler | External | Deposit batch fetch for marketing conversion pixel firing |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| #STS two-stage optimization (PAYUS-1254) | Performance | Pre-selects DepositIDs before main JOIN to reduce ScheduledTaskState lock contention |
| PaymentStatusID=2 filter | Business rule | Only approved deposits fire pixels |
| DepositCount correlated subquery | Performance consideration | Per-row correlated subquery on Billing.Deposit; acceptable for batch size up to ~1000 |
| ROW_NUMBER partition by CID | Design | Ranks deposits within batch per customer; DepositRowNumber=1 = most recent |
| INSERT...OUTPUT pattern | Design | Returns data via OUTPUT clause while populating #PostDepositTask for subsequent UPDATE |
| Created=GetDate() on UPDATE | Minor inconsistency | Uses local server time; most billing procs use GetUTCDate() |

---

## 8. Sample Queries

### 8.1 Fetch pixel entity batch
```sql
EXEC Billing.GetScheduledTaskPixelEntities @MaxEntitiesToFetch = 1000;
```

### 8.2 Check pending pixel queue depth
```sql
SELECT COUNT(*) AS PendingCount
FROM Billing.ScheduledTaskState WITH (NOLOCK)
WHERE TaskID = 3 AND TaskState = 0;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Ticket 45108 (referenced in DDL comment, Geri Reshef, 11/05/2017) | Jira | Initial creation of deposit pixel scheduler (Jira unavailable for full details) |
| PAYUS-1254 (referenced in DDL comment, Shay Oren, 02/08/2020) | Jira | Added #STS pre-selection optimization to reduce lock contention (same optimization as AppsFlyer scheduler) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskPixelEntities | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskPixelEntities.sql*

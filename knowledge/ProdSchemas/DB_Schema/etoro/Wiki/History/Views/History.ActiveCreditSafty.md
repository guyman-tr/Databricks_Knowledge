# History.ActiveCreditSafty

> Reduced-column view over History.ActiveCredit exposing only the 26 core financial event columns (through StocksOrderID) - omits 9 newer columns added after this view was created (MirrorEquity, MirrorDividendID, MoveMoneyReasonID, BSLRealFunds, PartitionCol, OriginalPositionID, SubCreditTypeID, DepositRollbackID, InterestMonthlyID) - used by fee calculation, interest calculation, and data quality reporting procedures.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | CreditID (bigint) from base History.ActiveCredit |
| **Partition** | N/A (view - base table partitioned) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.ActiveCreditSafty (note: "Safty" is a typo in the view name for "Safety") is a legacy-compatibility projection of History.ActiveCredit. It exposes only the first 26 columns of the 35-column credit schema - the core columns that existed before newer fields were added to the credit table over time.

The DDL contains the comment `"---***procedures to change***---"`, indicating this view was originally created as a transitional measure with the intention of migrating its consumers to the full-column History.ActiveCredit. That migration appears to have been deferred or never completed.

By omitting 9 newer columns (MirrorEquity, MirrorDividendID, MoveMoneyReasonID, BSLRealFunds, PartitionCol, OriginalPositionID, SubCreditTypeID, DepositRollbackID, InterestMonthlyID), this view provides backward compatibility for procedures written against the older 26-column schema. The schema binding (`WITH SCHEMABINDING`) is commented out, indicating the view has been made flexible for underlying schema changes.

The primary consumers are fee and interest calculation procedures (Trade.GetPositionsForFeeProcess, Trade.GetPositionsForFeeBulkGeneral, Trade.InterestGetDailyRawData variants) and data quality checks (Trade.ReportWrongDataInHistoryCredit). These procedures only need the core credit fields (CID, CreditTypeID, Credit, Payment, PositionID, Occurred) and do not require the newer metadata columns.

---

## 2. Business Logic

### 2.1 Column Projection (26 of 35)

**What**: SELECT of the first 26 columns from History.ActiveCredit, stopping at StocksOrderID.

**Columns/Parameters Involved**: 26 included; 9 omitted (MirrorEquity through InterestMonthlyID)

**Rules**:
- All 26 included columns are direct pass-throughs from History.ActiveCredit (and ultimately from History.ActiveCredit_BIGINT)
- No filtering: all rows from History.ActiveCredit are returned (no WHERE clause)
- No memory bucket: unlike History.ActiveCreditBucket_VW and History.ActiveCreditView, this view does NOT include History.ActiveCreditRecentMemoryBucket. Only persistent, flushed credits are visible.
- The omitted 9 columns are: MirrorEquity (mirror portfolio P&L at time of event), MirrorDividendID (dividend source link), MoveMoneyReasonID (reason for fund transfer), BSLRealFunds (Buy Stock Limit real funds field), PartitionCol (hash bucket), OriginalPositionID (for partial-close tracking), SubCreditTypeID (credit sub-classification), DepositRollbackID (rollback reference), InterestMonthlyID (monthly interest batch reference)

### 2.2 No In-Memory Buffer Coverage

**What**: This view omits History.ActiveCreditRecentMemoryBucket, unlike the Bucket_VW and View variants.

**Rules**:
- History.ActiveCreditSafty queries only History.ActiveCredit (the persistent disk table)
- Credits written to the in-memory buffer but not yet flushed are NOT visible here
- This is acceptable for fee/interest calculation procedures which run on batch schedules - by the time they run, the buffer has typically been flushed
- For real-time credit visibility, use History.ActiveCreditBucket_VW or History.ActiveCreditView

### 2.3 Comparison with Related Credit Views

| View | Memory Bucket | Column Count | Omitted Columns |
|------|--------------|-------------|-----------------|
| History.ActiveCredit | No | 35 | (none) |
| History.ActiveCreditSafty | No | 26 | MirrorEquity...InterestMonthlyID (9) |
| History.ActiveCreditBucket_VW | Yes (UNION, 0 PartitionCol) | 35 | (none) |
| History.ActiveCreditView | Yes (UNION ALL, NULL PartitionCol) | 35 | (none) |
| History.Credit | No (but 75+ archive tables) | 35 | (none) |

---

## 3. Data Overview

Same data as History.ActiveCredit but 26 columns. Sample rows (as of 2026-03-21):

| CreditID | CID | CreditTypeID | Credit | Payment | Occurred | TotalCash |
|----------|-----|-------------|--------|---------|----------|-----------|
| 2174752045 | 24860041 | 1 (Deposit) | 400 | 100 | 2026-03-21 | varies |
| 2174752041 | 25158719 | 3 (Open Position) | 232.93 | -20.19 | 2026-03-21 | varies |

Full dataset is the same as History.ActiveCredit (2021+ credits from History.ActiveCredit_BIGINT).

---

## 4. Elements

26 output columns (columns 1-26 of History.ActiveCredit, stopping at StocksOrderID):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CreditID | bigint | NO | CODE-BACKED | Ledger event surrogate PK. Bigint from History.ActiveCredit_BIGINT. |
| 2 | CID | int | NO | CODE-BACKED | Customer account owner. CLUSTERED INDEX key in the base table. |
| 3 | CreditTypeID | int | NO | CODE-BACKED | Financial event type. 1=Deposit, 2=Cashout, 3=OpenPosition, 4=ClosePosition, 6=Compensation, 7=Bonus, etc. |
| 4 | PositionID | bigint | YES | CODE-BACKED | Linked position for position-related credit events (CreditTypeID 3/4/11). NULL for deposits, withdrawals. |
| 5 | ChampionshipID | int | YES | CODE-BACKED | Linked championship if credit is tournament-related. NULL otherwise. |
| 6 | CashoutID | int | YES | CODE-BACKED | Linked cashout operation. NULL for non-cashout events. |
| 7 | PaymentID | int | YES | CODE-BACKED | Linked payment record. NULL for non-payment events. |
| 8 | WithdrawID | int | YES | CODE-BACKED | Linked withdrawal. NULL for non-withdrawal events. |
| 9 | DepositID | int | YES | CODE-BACKED | Linked deposit record. NULL for non-deposit events. |
| 10 | UpdateID | int | YES | CODE-BACKED | Linked balance update operation. NULL if not an update-driven credit. |
| 11 | CampaignID | int | YES | CODE-BACKED | Linked marketing campaign. NULL for non-campaign credits. |
| 12 | BonusTypeID | int | YES | CODE-BACKED | Bonus sub-type for bonus credits. NULL for non-bonus events. |
| 13 | CompensationReasonID | int | YES | CODE-BACKED | Reason code for compensation credits. NULL for non-compensation events. |
| 14 | ManagerID | int | YES | CODE-BACKED | Manager who processed this credit (for manual back-office operations). NULL for automated events. |
| 15 | Credit | money | NO | CODE-BACKED | Running account balance after this event (in USD). Not the delta - the new balance total. |
| 16 | Payment | money | NO | CODE-BACKED | Delta amount for this event. Positive = funds in (deposit/profit). Negative = funds out (loss/withdrawal). |
| 17 | Description | varchar | YES | CODE-BACKED | Free-text description for manual/special credit events. NULL for automated events. |
| 18 | Occurred | datetime | NO | CODE-BACKED | UTC timestamp of the credit event. Partition key in the base table. |
| 19 | WithdrawProcessingID | int | YES | CODE-BACKED | Linked withdrawal processing record. NULL for non-withdrawal events. |
| 20 | MirrorID | int | NO | CODE-BACKED | Copy portfolio ID. 0 = not copy-trading related. Non-zero = event for a copy portfolio position. |
| 21 | TotalCash | money | YES | CODE-BACKED | Total cash balance of the account after this event. |
| 22 | TotalCashChange | money | YES | CODE-BACKED | Delta in total cash. |
| 23 | BonusCredit | money | YES | CODE-BACKED | Bonus balance component of this credit event. |
| 24 | RealizedEquity | money | YES | CODE-BACKED | Realized equity balance at time of this event. |
| 25 | MirrorCash | money | YES | CODE-BACKED | Cash balance attributed to a specific copy portfolio (mirror). |
| 26 | StocksOrderID | int | YES | CODE-BACKED | Linked stock order for equity-related credit events. NULL for non-stock events. |
| **27-35** | **MirrorEquity...InterestMonthlyID** | **N/A** | **N/A** | **N/A** | **NOT PRESENT - these 9 columns were added after this view was created** |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all rows) | History.ActiveCredit | View (SELECT) | Base view - all rows, 26 of 35 columns |
| CreditTypeID | Dictionary.CreditType (implied) | Implicit FK | Credit event type lookup |
| CID | Customer.Customer | Implicit FK | Account owner |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForFeeProcess | CID/CreditTypeID/PositionID | Read | Fee calculation for position events |
| Trade.GetPositionsForFeeBulkGeneral | CID/CreditTypeID/PositionID | Read | Bulk fee calculation |
| Trade.GetPositionsForFeeBulkGeneral_Aus | CID/CreditTypeID/PositionID | Read | Australian-market fee calculation |
| Trade.InterestGetDailyRawData | CID/Credit/Occurred | Read | Daily interest calculation raw data |
| Trade.InterestGetDailyRawDataNEWELAD | CID/Credit/Occurred | Read | Interest calculation variant |
| Trade.ReportWrongDataInHistoryCredit | CreditID/CID | Read | Data quality reporting |
| Trade.ReportWrongDataInHistoryCredit_NewElad | CreditID/CID | Read | Data quality reporting variant |
| BackOffice.UpsertIntoAggregationTables | CID/CreditTypeID | Read | BO aggregation table maintenance |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCreditSafty (view)
+- History.ActiveCredit (view)
   +- History.ActiveCredit_BIGINT (table - partitioned, 7 indexes)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | View | Single source - 26 of 35 columns selected |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForFeeProcess | Stored Procedure | Fee process data source |
| Trade.GetPositionsForFeeBulkGeneral | Stored Procedure | Bulk fee data |
| Trade.GetPositionsForFeeBulkGeneral_Aus | Stored Procedure | AU fee data |
| Trade.InterestGetDailyRawData | Stored Procedure | Daily interest calculation |
| Trade.InterestGetDailyRawDataNEWELAD | Stored Procedure | Interest calculation variant |
| Trade.ReportWrongDataInHistoryCredit | Stored Procedure | Data quality check |
| Trade.ReportWrongDataInHistoryCredit_NewElad | Stored Procedure | Data quality check variant |
| BackOffice.UpsertIntoAggregationTables | Stored Procedure | Aggregation table maintenance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries benefit from History.ActiveCredit_BIGINT indexes:
- CLUSTERED on (CID, Occurred DESC) for per-customer credit queries
- NONCLUSTERED PK on CreditID for direct lookups

### 7.2 Schema Binding

The `WITH SCHEMABINDING` clause is commented out in the DDL. This means:
- The underlying table/view can be altered without dropping this view first
- The view cannot be used as the basis for an indexed view

---

## 8. Sample Queries

### 8.1 Get all fee-eligible credits for a customer
```sql
SELECT
    ac.CreditID,
    ac.CreditTypeID,
    ac.PositionID,
    ac.Credit,
    ac.Payment,
    ac.MirrorID,
    ac.Occurred
FROM History.ActiveCreditSafty ac WITH (NOLOCK)
WHERE ac.CID = 14952810
  AND ac.CreditTypeID IN (3, 4)  -- Open/Close position events
ORDER BY ac.Occurred DESC;
```

### 8.2 Data quality check - find credits with missing PositionID for position-type events
```sql
SELECT
    ac.CreditID,
    ac.CID,
    ac.CreditTypeID,
    ac.Occurred
FROM History.ActiveCreditSafty ac WITH (NOLOCK)
WHERE ac.CreditTypeID IN (3, 4)  -- Open/Close position
  AND ac.PositionID IS NULL
  AND ac.Occurred >= DATEADD(DAY, -7, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.ActiveCreditSafty. Business context inherited from History.ActiveCredit documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.ActiveCreditSafty | Type: View | Source: etoro/etoro/History/Views/History.ActiveCreditSafty.sql*

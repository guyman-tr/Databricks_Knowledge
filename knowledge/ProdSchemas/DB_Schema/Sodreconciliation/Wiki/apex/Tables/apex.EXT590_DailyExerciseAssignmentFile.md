# apex.EXT590_DailyExerciseAssignmentFile

> Options exercise and assignment details from Apex Clearing EXT590 extract: quantities, prices, and settlement info.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily options exercise and assignment data from Apex Clearing's EXT590 extract. Each row represents an option contract that has been exercised (by the holder) or assigned (to the writer), including the option details, underlying security, quantities, trade terms, and settlement information. When a call option is exercised, the holder buys shares at the strike price; when a put is exercised, the holder sells shares. Assignment is the corresponding obligation on the other side.

The EXT590 data is important for position reconciliation because exercises and assignments directly create new stock positions and generate cash movements. After an exercise/assignment event, the account will show a new stock trade and a change in the options position. This data helps reconcile these position changes against the expected outcomes.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT590 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Exercise vs. Assignment

**What**: Each record represents either an exercise or assignment event.

**Columns Involved**: `ExcerciseAssignmentCode`, `ProcessingStatus`, `ExecutionMethod`

**Rules**:
- ExcerciseAssignmentCode distinguishes exercise from assignment (note: column name has typo "Excercise")
- ProcessingStatus tracks the current state of the exercise/assignment
- ExecutionMethod indicates how the exercise was initiated (automatic, manual, etc.)

### 2.2 Underlying Trade Generation

**What**: An exercise/assignment generates a corresponding stock trade.

**Columns Involved**: `UnderlyingQuantity`, `BuySellCodeForUnderlying`, `PriceOfTrade`, `StrikePrice`, `Commission`, `TradeDate`, `SettlementDate`

**Rules**:
- UnderlyingQuantity is the number of underlying shares involved
- BuySellCodeForUnderlying indicates if the resulting stock trade is a buy or sell
- PriceOfTrade is the execution price (typically the strike price)
- Commission is charged on the resulting stock trade

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT590 file import. CASCADE DELETE. |
| 3 | ProcessingStatus | varchar(40) | YES | - | CODE-BACKED | Current processing status of the exercise/assignment. |
| 4 | ExecutionMethod | varchar(3) | YES | - | CODE-BACKED | Method of exercise (automatic at expiration, manual, etc.). |
| 5 | OptionSymbolKey | varchar(8000) | YES | - | NAME-INFERRED | Composite option symbol key for identification. |
| 6 | OptionQuantity | varchar(10) | YES | - | CODE-BACKED | Number of option contracts exercised/assigned (stored as string). |
| 7 | StockIndexIndicator | varchar(4) | YES | - | NAME-INFERRED | Indicator for stock-settled vs. index (cash-settled) options. |
| 8 | DeliveryComponent | varchar(1) | YES | - | NAME-INFERRED | Delivery component indicator for the exercise. |
| 9 | OptionSymbol | varchar(12) | YES | - | CODE-BACKED | Option contract symbol. |
| 10 | UnderlyingSecurityInformation | varchar(16) | YES | - | NAME-INFERRED | Additional underlying security information. |
| 11 | CustomerAccountNumberHoldingOption | varchar(12) | YES | - | CODE-BACKED | Account number holding the option position. MASKED (PII). |
| 12 | OfficeCode | varchar(3) | YES | - | CODE-BACKED | Apex office/branch code. |
| 13 | UnderlyingSymbol | varchar(12) | YES | - | CODE-BACKED | Trading symbol of the underlying security. |
| 14 | StrikePrice | decimal(12,9) | YES | - | CODE-BACKED | Strike price of the option contract. |
| 15 | PayOutComponent | varchar(13) | YES | - | NAME-INFERRED | Payout component details (for cash-settled options). |
| 16 | CustomerAccountNumberActivityToBeRunAgainst | varchar(12) | YES | - | CODE-BACKED | Account number where the resulting stock trade will be booked. |
| 17 | CustomerAccountType | varchar(1) | YES | - | CODE-BACKED | Account type code. |
| 18 | UnderlyingQuantity | decimal(19,5) | YES | - | CODE-BACKED | Number of underlying shares involved in the exercise/assignment. |
| 19 | BuySellCodeForUnderlying | varchar(1) | YES | - | CODE-BACKED | Buy or sell direction for the resulting underlying stock trade. |
| 20 | UnderLyingSymbolAssociatedWithTrade | varchar(12) | YES | - | CODE-BACKED | Underlying symbol associated with the generated trade. |
| 21 | PriceOfTrade | varchar(11) | YES | - | CODE-BACKED | Execution price for the resulting stock trade (stored as string). |
| 22 | TradeMarketCode | varchar(1) | YES | - | NAME-INFERRED | Market code for the resulting trade. |
| 23 | TradeCapacityCode | varchar(1) | YES | - | NAME-INFERRED | Trade capacity code (principal, agency). |
| 24 | ExecutionTimeTradeWillBeAssociatedWith | nvarchar(max) | YES | - | NAME-INFERRED | Execution time for the resulting trade record. |
| 25 | Commission | decimal(19,10) | YES | - | CODE-BACKED | Commission charged on the resulting stock trade. |
| 26 | TradeDate | datetime | YES | - | CODE-BACKED | Trade date for the exercise/assignment. |
| 27 | SettlementDate | datetime | YES | - | CODE-BACKED | Settlement date for the exercise/assignment. |
| 28 | ExcerciseAssignmentCode | varchar(1) | YES | - | CODE-BACKED | Code distinguishing exercise from assignment. Note: column has typo ("Excercise"). |
| 29 | OCCClaimNumber | varchar(5) | YES | - | NAME-INFERRED | OCC (Options Clearing Corporation) claim number for tracking. |
| 30 | AccountType | nvarchar(1) | YES | - | CODE-BACKED | Account type code for the exercise/assignment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT590_DailyExerciseAssignmentFile (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT590_DailyExerciseAssignmentFile | CLUSTERED PK | Id | - | - | Active |
| IX_EXT590_DailyExerciseAssignmentFile_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT590_DailyExerciseAssignmentFile | PRIMARY KEY | Unique Id per row |
| FK_EXT590_DailyExerciseAssignmentFile_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get exercise/assignment activity from the latest import

```sql
SELECT CustomerAccountNumberHoldingOption, OptionSymbol, UnderlyingSymbol,
       StrikePrice, OptionQuantity, UnderlyingQuantity, BuySellCodeForUnderlying,
       ExcerciseAssignmentCode, TradeDate, SettlementDate
FROM apex.EXT590_DailyExerciseAssignmentFile WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 590 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY CustomerAccountNumberHoldingOption;
```

### 8.2 Summarize exercises vs assignments

```sql
SELECT ExcerciseAssignmentCode,
       COUNT(*) AS EventCount,
       SUM(UnderlyingQuantity) AS TotalUnderlyingShares,
       SUM(Commission) AS TotalCommissions
FROM apex.EXT590_DailyExerciseAssignmentFile WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 590 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY ExcerciseAssignmentCode;
```

### 8.3 Find large exercise/assignment events

```sql
SELECT CustomerAccountNumberHoldingOption, OptionSymbol, UnderlyingSymbol,
       StrikePrice, UnderlyingQuantity, ExcerciseAssignmentCode, ProcessingStatus
FROM apex.EXT590_DailyExerciseAssignmentFile WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 590 AND Status = 2 ORDER BY ProcessDate DESC)
  AND ABS(UnderlyingQuantity) > 1000
ORDER BY ABS(UnderlyingQuantity) DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 10 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT590_DailyExerciseAssignmentFile | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT590_DailyExerciseAssignmentFile.sql*

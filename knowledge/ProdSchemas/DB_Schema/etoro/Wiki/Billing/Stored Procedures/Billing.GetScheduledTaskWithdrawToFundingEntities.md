# Billing.GetScheduledTaskWithdrawToFundingEntities

> Post-withdrawal scheduled task batch-fetch for TaskID=6: claims pending WithdrawToFunding entities from ScheduledEntityTaskState, returns withdrawal routing data (CID, GCID, FundingTypeID, MopCountry, BankName) via INSERT...OUTPUT, then marks claimed rows as TaskState=3.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch (batch cap); returns one row per claimed WithdrawToFunding entity |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetScheduledTaskWithdrawToFundingEntities is the batch-fetch step for the Post-Withdrawal-to-Funding (PostWTF) scheduled pipeline (TaskID=6). When a customer creates a withdrawal-to-funding record (`Billing.WithdrawToFunding`), the row is enqueued in `Billing.ScheduledEntityTaskState` with TaskState=0. This procedure claims a batch of those pending entities, returns the routing data needed by the caller to dispatch the withdrawal through the appropriate payment channel, then marks them as In Progress.

Key difference from the deposit-based scheduler procedures (GetScheduledTaskAppsFlyerEntities, GetScheduledTaskRabbitMqFtdEntities): this procedure operates on withdrawal entities rather than deposit events, and uses `Billing.ScheduledEntityTaskState` (entity-level tracking) instead of `Billing.ScheduledTaskState` (deposit-level tracking). The entity ID corresponds to `Billing.WithdrawToFunding.ID`.

The returned routing data supports the caller's channel selection:
- `FundingTypeID`: which payment method to use for the withdrawal routing
- `MopCountry`: geographic origin of the payment method (for regulatory and routing decisions)
- `BankName`: issuing bank for card-based withdrawals

Uses an `INSERT...OUTPUT` pattern - the result is returned atomically from the INSERT statement itself, not via a separate SELECT. This is a single-stage design (no two-stage population like the deposit procedures).

Created 07 Sep 2016 (Geri Reshef, ticket 40729), extended 18 Apr 2018 (Geri Reshef, ticket 51041), BankName changed to NVarChar(128) May 2018 (Ran Ovadia).

---

## 2. Business Logic

### 2.1 INSERT...OUTPUT Claim Pattern

**What**: Uses INSERT...OUTPUT to simultaneously INSERT into the temp table and SELECT the inserted rows as the result set - a single-stage claim (vs. the deposit procedures' two-stage approach).

**Columns/Parameters Involved**: `@MaxEntitiesToFetch`, `#PostWithdrawToFundingTask`, `OUTPUT Inserted.*`

**Rules**:
- `INSERT INTO #PostWithdrawToFundingTask OUTPUT Inserted.* SELECT TOP (cap) ...`
- The `OUTPUT Inserted.*` clause returns all inserted rows immediately - the caller receives results as the INSERT executes
- No separate SELECT statement needed after the INSERT
- This is more concise than the deposit procedure pattern and works well because there is no two-stage GCID/MopCountry population (Customer.CustomerStatic is JOINed directly in Stage 1)

### 2.2 TaskID=6 Entity Queue Processing

**What**: Processes the WithdrawToFunding post-processing queue (TaskID=6) from ScheduledEntityTaskState.

**Columns/Parameters Involved**: `Billing.ScheduledEntityTaskState.TaskID`, `Billing.ScheduledEntityTaskState.TaskState`, `Billing.WithdrawToFunding.ID`

**Rules**:
- Filters: `WHERE BSETS.TaskID=6 AND BSETS.TaskState=0` - only pending (0) WithdrawToFunding tasks
- `BSETS.EntityID` joins to `Billing.WithdrawToFunding.ID` to get the withdrawal funding record
- After batch SELECT: `UPDATE ScheduledEntityTaskState SET TaskState=3, Created=GetUTCDate()` marks the claimed rows as In Progress
- Only the batch rows (matched via `#PostWithdrawToFundingTask`) are updated - not all pending rows

### 2.3 BankName Resolution by Funding Type

**What**: Bank name is resolved differently per payment type, reflecting the different data structures for each method.

**Columns/Parameters Involved**: `FundingTypeID`, `BankName`, `Billing.Funding.FundingData`

**Rules**:
```sql
CASE F.FundingTypeID
    WHEN 1 THEN CB.IssuingBank           -- Credit card: from BIN lookup table
    WHEN 22 THEN NULL                    -- UnionPay: bank name not available/applicable
    ELSE F.FundingData.value(           -- Others: from XML payload in Funding record
        'Funding[1]/BankNameAsString[1]', 'NVarChar(Max)')
END AS BankName
```
- FundingTypeID=1 (CreditCard): issuing bank from Dictionary.CountryBin via BIN code
- FundingTypeID=22 (UnionPay): always NULL - bank name not stored for UnionPay
- All others: bank name from XML `FundingData` stored in Billing.Funding

### 2.4 MopCountry Resolution

**What**: Identifies the geographic origin of the payment method used for this withdrawal.

**Rules**:
```sql
DC.CountryID = CASE
    WHEN F.FundingTypeID=3 AND PayPalXML > 0 THEN PayPalCountryID
    ELSE COALESCE(CB.CountryID, CS.CountryID)   -- BIN country, fallback to customer country
END
```
- PayPal (FT=3): uses country from PayPal `PaymentData` XML (`Deposit[1]/CountryIDAsString[1]`) - sourced from OUTER APPLY on Billing.Deposit for the most recent deposit with this FundingID
- Credit cards: BIN issuing country
- All others: customer's registered country (from Customer.CustomerStatic) as ultimate fallback
- Note: uses COALESCE for both BIN and customer country fallback - unlike the FTD procedure which does this in Stage 2

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Batch size cap. -1 = unlimited (internally 2147483647 via IIF). Applied as TOP in the INSERT SELECT. |
| - | EntityID | INT | NO | - | CODE-BACKED | Primary key of the claimed WithdrawToFunding record. Corresponds to Billing.WithdrawToFunding.ID and Billing.ScheduledEntityTaskState.EntityID. |
| - | CID | INT | NO | - | CODE-BACKED | Customer ID from Billing.ScheduledEntityTaskState.CID. The customer who initiated the withdrawal-to-funding operation. |
| - | GCID | INT | YES | - | CODE-BACKED | Global customer ID from Customer.CustomerStatic. Joined directly (not in a second stage like deposit procedures). NULL if no CustomerStatic record exists. |
| - | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type for the withdrawal's funding record. From Billing.Funding via WithdrawToFunding.FundingID -> Funding.FundingID. Determines routing channel for the withdrawal. |
| - | MopCountry | VARCHAR(50) | YES | - | CODE-BACKED | Method of Payment Country. Resolution priority: PayPal XML country -> BIN issuing country -> customer registered country (COALESCE fallback). NULL only if all sources lack country data. |
| - | BankName | NVarChar(128) | YES | - | CODE-BACKED | Issuing bank for this payment method. For CreditCard (FT=1): from Dictionary.CountryBin.IssuingBank. For UnionPay (FT=22): always NULL. For others: from Billing.Funding.FundingData XML (Funding[1]/BankNameAsString[1]). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TaskID=6, TaskState=0 | Billing.ScheduledEntityTaskState | SELECT + UPDATE | Reads pending entity tasks; claims by updating TaskState=3 |
| EntityID | Billing.WithdrawToFunding | JOIN | Source of FundingID for the withdrawal record |
| CID | Customer.CustomerStatic | JOIN | GCID and fallback country |
| FundingID | Billing.Funding | JOIN | FundingTypeID and FundingData XML |
| FundingData | Dictionary.CountryBin | LEFT JOIN | BIN code -> issuing country + bank name |
| FundingID | Billing.Deposit | OUTER APPLY (TOP 1) | Most recent deposit for this FundingID - used to extract PayPal country from PaymentData XML |
| CountryID | Dictionary.Country | LEFT JOIN | Country name for MopCountry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Post-WTF scheduler service | @MaxEntitiesToFetch | EXEC | Batch claim for withdrawal-to-funding post-processing pipeline |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskWithdrawToFundingEntities (procedure)
+-- Billing.ScheduledEntityTaskState (table) [TaskID=6 queue]
+-- Billing.WithdrawToFunding (table) [EntityID -> withdrawal record]
+-- Customer.CustomerStatic (table) [GCID + country]
+-- Billing.Funding (table) [FundingTypeID + XML data]
+-- Dictionary.CountryBin (table) [BIN -> country + bank]
+-- Billing.Deposit (table) [OUTER APPLY for PayPal country XML]
+-- Dictionary.Country (table) [country name]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledEntityTaskState | Table | Source queue (TaskID=6, TaskState=0); UPDATE to TaskState=3 after claim |
| Billing.WithdrawToFunding | Table | Withdrawal-to-funding record; provides FundingID |
| Customer.CustomerStatic | Table | GCID + CountryID (fallback for MopCountry) |
| Billing.Funding | Table | FundingTypeID + FundingData XML (BIN code + bank name) |
| Dictionary.CountryBin | Table | BIN code -> issuing country and bank name |
| Billing.Deposit | Table | OUTER APPLY TOP 1 to get most recent deposit for PayPal country lookup |
| Dictionary.Country | Table | CountryID -> country name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Post-WTF scheduler service | External | Batch-fetch caller for withdrawal post-processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TaskID=6 hardcoded | Design | Only ScheduledEntityTaskState rows with TaskID=6 are processed |
| TaskState transition | Business rule | UPDATE sets TaskState=3 (In Progress); the caller is responsible for updating to TaskState=2 (Complete) after processing |
| Created = GetUTCDate() | Design | Uses UTC for the claim timestamp (unlike the deposit procedures which use GetDate() - local time) |
| OUTER APPLY TOP 1 on Deposit | Performance | Gets most recent deposit for FundingID to extract PayPal XML - could return different rows on repeated calls if multiple deposits exist; consistent for the same FundingID |

---

## 8. Sample Queries

### 8.1 Execute batch claim for WithdrawToFunding processing

```sql
EXEC [Billing].[GetScheduledTaskWithdrawToFundingEntities] @MaxEntitiesToFetch = 50
-- Returns: EntityID, CID, GCID, FundingTypeID, MopCountry, BankName
-- Side effect: marks claimed rows as TaskState=3 in ScheduledEntityTaskState
```

### 8.2 Check pending WithdrawToFunding tasks

```sql
SELECT
    bsets.TaskState,
    COUNT(*) AS Count,
    MIN(bsets.Created) AS OldestEntry,
    MAX(bsets.Created) AS NewestEntry
FROM [Billing].[ScheduledEntityTaskState] bsets WITH (NOLOCK)
WHERE bsets.TaskID = 6
GROUP BY bsets.TaskState
ORDER BY bsets.TaskState
```

### 8.3 Inspect a specific entity's data before processing

```sql
SELECT
    bsets.EntityID,
    bsets.CID,
    cs.GCID,
    f.FundingTypeID,
    ft.Name AS FundingTypeName,
    wtf.FundingID
FROM [Billing].[ScheduledEntityTaskState] bsets WITH (NOLOCK)
INNER JOIN [Billing].[WithdrawToFunding] wtf WITH (NOLOCK) ON bsets.EntityID = wtf.ID
INNER JOIN [Customer].[CustomerStatic] cs WITH (NOLOCK) ON bsets.CID = cs.CID
INNER JOIN [Billing].[Funding] f WITH (NOLOCK) ON wtf.FundingID = f.FundingID
INNER JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON f.FundingTypeID = ft.FundingTypeID
WHERE bsets.TaskID = 6
  AND bsets.TaskState = 0
ORDER BY bsets.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskWithdrawToFundingEntities | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskWithdrawToFundingEntities.sql*

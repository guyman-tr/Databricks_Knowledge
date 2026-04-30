# Billing.GetScheduledTaskRabbitMqFtdEntities

> Post-deposit scheduler fetch for TaskID=2 (RabbitMQ FTD notification): claims pending first-time deposits (IsFTD=1 + PaymentStatusID=2 + within 7 days), returns DepositID, IsFTD, GCID, PaymentStatusID, CID, FundingTypeID, IsRefundable, MopCountry, BankName via two-stage INSERT (data) + UPDATE (GCID + MopCountry fallback), then marks claimed rows as TaskState=3.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch (batch cap); returns one row per claimed FTD deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetScheduledTaskRabbitMqFtdEntities` is the batch-fetch step for the RabbitMQ first-time deposit (FTD) notification pipeline (TaskID=2). When a customer makes their very first deposit (IsFTD=1), this scheduler claims the pending ScheduledTaskState row, retrieves the FTD data, and enables the caller to publish a message to RabbitMQ. Downstream consumers of this message include:
- CRM systems (trigger welcome sequences, account manager assignment)
- Bonus processing (apply FTD bonuses)
- Compliance systems (KYC triggers, initial risk scoring)
- Marketing attribution (FTD conversion recording)

Three filters narrow the eligible deposits:
1. **IsFTD=1**: Only first-time deposits
2. **PaymentStatusID=2**: Only approved payments
3. **ModificationDate > -7 days**: Only deposits modified within the last 7 days (added Jun 2019 by Adi Cohen to prevent processing stale backlog)

**MOP Country** (Method of Payment Country) is a key output - it identifies the country associated with the payment method:
- For credit cards: the card's issuing country from `Dictionary.CountryBin` (BIN code lookup)
- For PayPal (FundingTypeID=3): the country from the PayPal payment XML data
- Fallback: the customer's registered country (populated in the second UPDATE stage)

The procedure uses a **two-stage data population** pattern:
1. First INSERT: loads all columns except GCID (commented out from Stage 1)
2. Second UPDATE: fills in GCID from Customer.CustomerStatic and fills MopCountry fallback (if NULL from BIN/PayPal lookup, uses customer's country)

Created 07 Sep 2016 (Geri Reshef, ticket 40729). Key evolution: 7-day recency filter (Jun 2019), #STS optimization (Aug 2020, PAYUS-1254), two-stage GCID/MopCountry fill (Sep 2020).

---

## 2. Business Logic

### 2.1 FTD-Only Filter with Recency Gate

**What**: Strict filtering ensures only recent, approved, first-time deposits are processed.

**Rules**:
- Stage 1 #STS: `WHERE TaskState=0 AND TaskID=2 AND EXISTS (SELECT TOP 1 1 FROM Deposit D WHERE D.PaymentStatusID=2 AND D.DepositID=BST.DepositID AND D.ModificationDate > DATEADD(DAY,-7,GETUTCDATE()))`
  - PaymentStatusID=2: Approved deposits only
  - ModificationDate within 7 days: Prevents processing stale FTD events from the backlog
  - IsFTD filter is applied in the Stage 2 JOIN (INNER JOIN Deposit ON IsFTD=1 AND PaymentStatusID=2)
- The 7-day gate was added Jun 2019 because the ScheduledTaskState backlog had accumulated old FTD rows that were no longer relevant to notify about

### 2.2 Two-Stage Data Population

**What**: GCID and MopCountry fallback are populated in a second UPDATE pass after the initial INSERT.

**Stage 1 (INSERT into #PostDepositTask)**:
- Inserts all columns except GCID (left as NULL in Stage 1)
- MopCountry resolved from:
  - PayPal (FundingTypeID=3): `D.PaymentData.value('Deposit[1]/CountryIDAsString[1]', 'VarChar(Max)')` when > 0
  - Credit cards: `Dictionary.CountryBin.CountryID` via BIN code LEFT JOIN `F.FundingData.value('Funding[1]/BinCodeAsString[1]', 'VarChar(Max)')`
  - Other: NULL (filled in Stage 2)
- BankName: `Dictionary.CountryBin.IssuingBank` (issuing bank name from BIN, e.g., "Chase", "HSBC")

**Stage 2 (UPDATE #PostDepositTask)**:
- `SET GCID = CS.GCID` from Customer.CustomerStatic JOIN on CID
- `SET MopCountry = ISNULL(PDT.MopCountry, DC.CountryID)` - if MopCountry is still NULL from Stage 1, use the customer's country from Customer.CustomerStatic -> Dictionary.Country

The two-stage design (added Sep 2020) avoids adding Customer.CustomerStatic to the main INSERT query, reducing JOIN complexity and improving performance on the hot INSERT path.

### 2.3 MopCountry Resolution Logic

**What**: Identifies the country of the payment method used.

**Rules**:
- `MopCountry` is a key risk/analytics field - identifies WHERE the money came from geographically
- Resolution priority:
  1. PayPal deposits: use country from PayPal transaction XML (`CountryIDAsString`)
  2. Card deposits: use issuing country from BIN table (`Dictionary.CountryBin.CountryID`)
  3. Fallback (Stage 2): use customer's registered country
- Returns country name string (VARCHAR(50)) from Dictionary.Country.Name
- `DC.CountryID > 0` filter prevents invalid/default CountryID=0 matches

### 2.4 BankName from BIN Lookup

**What**: Returns the issuing bank name for credit card deposits.

**Rules**:
- `BankName = Dictionary.CountryBin.IssuingBank` (VARCHAR(100))
- Matched via BIN code: `F.FundingData.value('Funding[1]/BinCodeAsString[1]', 'VarChar(Max)') = CB.BinCode`
- NULL for non-card deposits (PayPal, bank transfer, etc.) where no BIN record exists

### 2.5 IsRefundable Flag

**What**: Indicates whether the FTD payment method supports refunds.

**Rules**:
- `IsRefundable = FT.IsRefundable` from Dictionary.FundingType
- Used by downstream FTD processing to determine whether chargebacks/refunds are possible on this method

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Maximum batch size. -1 = no limit (uses MAX INT as TOP). Typically loaded from Billing.ScheduledTaskConfig.MaxEntitiesToFetch for TaskID=2. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositID | INT | NO | - | CODE-BACKED | PK of the claimed FTD deposit. |
| 3 | IsFTD | BIT | YES | - | CODE-BACKED | Always 1 for deposits returned by this procedure (filter ensures IsFTD=1). First-time deposit flag from Billing.Deposit. |
| 4 | GCID | INT | YES | - | CODE-BACKED | Global customer identifier from Customer.CustomerStatic, populated in Stage 2 UPDATE. NULL if CustomerStatic record missing. |
| 5 | PaymentStatusID | INT | YES | - | CODE-BACKED | Always 2 (Approved) per filter criteria. From Billing.Deposit. |
| 6 | CID | INT | NO | - | CODE-BACKED | Customer identifier from Billing.Deposit. |
| 7 | FundingTypeID | INT | YES | - | CODE-BACKED | Payment method type from Billing.Funding via Dictionary.FundingType FK. |
| 8 | IsRefundable | BIT | YES | - | CODE-BACKED | Whether this payment method supports refunds. From Dictionary.FundingType.IsRefundable. |
| 9 | MopCountry | VARCHAR(50) | YES | - | CODE-BACKED | Method-of-Payment country name. Resolved from: PayPal XML > BIN code > customer country (Stage 2 fallback). Identifies geographic origin of payment. |
| 10 | BankName | VARCHAR(100) | YES | - | CODE-BACKED | Issuing bank name from Dictionary.CountryBin.IssuingBank via BIN code match. NULL for non-card deposits. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.ScheduledTaskState | SELECT + UPDATE | Claim TaskID=2 pending rows; mark TaskState=3 |
| DepositID | Billing.Deposit | INNER JOIN | IsFTD=1, PaymentStatusID=2, 7-day recency filter, PaymentData XML |
| D.FundingID | Billing.Funding | INNER JOIN | FundingTypeID; FundingData XML for BIN code |
| F.FundingTypeID | Dictionary.FundingType | INNER JOIN | IsRefundable |
| F.FundingData (XML) | Dictionary.CountryBin | LEFT JOIN | MopCountry (card issuing country), BankName |
| D.PaymentData (XML, FundingTypeID=3) | Dictionary.Country | LEFT JOIN | MopCountry (PayPal country) |
| PDT.CID | Customer.CustomerStatic | JOIN (Stage 2) | GCID; customer country for MopCountry fallback |
| CS.CountryID | Dictionary.Country | LEFT JOIN (Stage 2) | MopCountry fallback value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RabbitMQ FTD notification scheduler (TaskID=2) | @MaxEntitiesToFetch | EXEC | Batch fetch for FTD event publishing to RabbitMQ |
| Billing.GetScheduledEntities | EXEC | EXEC | Called by the orchestrator as one of the registered task fetchers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskRabbitMqFtdEntities (procedure)
+-- Billing.ScheduledTaskState (table)
+-- Billing.Deposit (table)
+-- Billing.Funding (table)
+-- Dictionary.FundingType (table)
+-- Dictionary.CountryBin (table, cross-schema)
+-- Dictionary.Country (table)
+-- Customer.CustomerStatic (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | Claim pending TaskID=2 rows; mark TaskState=3 |
| Billing.Deposit | Table | IsFTD, PaymentStatusID, CID, PaymentData XML; 7-day recency filter |
| Billing.Funding | Table | FundingTypeID, FundingData XML (BIN code) |
| Dictionary.FundingType | Table | IsRefundable |
| Dictionary.CountryBin | Table | MopCountry (card issuing country), BankName via BIN code |
| Dictionary.Country | Table | MopCountry name string (PayPal path + Stage 2 fallback) |
| Customer.CustomerStatic | Table | GCID; customer country for MopCountry fallback (Stage 2) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RabbitMQ FTD notification worker | External | Processes batch to publish FTD events to RabbitMQ |
| Billing.GetScheduledEntities | Stored Procedure | EXEC call to fetch TaskID=2 batch (deferred to Batch 24) |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| #STS two-stage optimization (PAYUS-1254) | Performance | Pre-selects DepositIDs before main JOIN to reduce ScheduledTaskState lock contention |
| 7-day recency gate | Business rule (Jun 2019) | ModificationDate > DATEADD(DAY,-7,GETUTCDATE()): prevents stale FTD backlog processing |
| IsFTD=1 filter | Business rule | Only first-time deposits are RabbitMQ-notified via this pipeline |
| Two-stage INSERT + UPDATE | Performance design | GCID and MopCountry fallback populated in separate UPDATE to keep main INSERT JOIN simple |
| BIN code from XML | Design | Card BIN extracted from Billing.Funding.FundingData XML (not a dedicated column) |
| MopCountry > 0 guard | Data quality | `DC.CountryID > 0` prevents invalid CountryID=0 from matching |
| Created=GetDate() on UPDATE | Minor inconsistency | Uses local server time; ModificationDate filter uses GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Fetch RabbitMQ FTD batch
```sql
EXEC Billing.GetScheduledTaskRabbitMqFtdEntities @MaxEntitiesToFetch = 100;
```

### 8.2 Check pending FTD queue (with recency context)
```sql
SELECT COUNT(*) AS PendingCount,
       MIN(D.ModificationDate) AS OldestPending,
       MAX(D.ModificationDate) AS NewestPending
FROM Billing.ScheduledTaskState STS WITH (NOLOCK)
JOIN Billing.Deposit D WITH (NOLOCK) ON STS.DepositID = D.DepositID
WHERE STS.TaskID = 2 AND STS.TaskState = 0
  AND D.IsFTD = 1 AND D.PaymentStatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Ticket 40729 (referenced in DDL comment, Geri Reshef, 07/09/2016) | Jira | Initial creation as part of ScheduledTask framework (same ticket as GetScheduledTaskConfig) |
| PAYUS-1254 (referenced in DDL comment, Shay Oren, 02/08/2020) | Jira | Added #STS pre-selection optimization for lock contention reduction |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.4/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskRabbitMqFtdEntities | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskRabbitMqFtdEntities.sql*

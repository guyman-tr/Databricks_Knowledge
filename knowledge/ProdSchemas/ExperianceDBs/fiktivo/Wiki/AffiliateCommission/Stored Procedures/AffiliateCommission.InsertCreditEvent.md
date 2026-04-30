# AffiliateCommission.InsertCreditEvent

> Creates a credit event record for commission tracking and re-evaluation, with an idempotency guard that prevents duplicate events for the same credit.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into CreditEvent |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertCreditEvent creates an event record that enables commission re-evaluation for a credit. When a credit is processed and enters the pipeline, an event is created with the credit's financial snapshot. This event can later be picked up by GetCreditTriggeredEvents when attribution or aggregated data changes require commission recalculation.

The WHERE NOT EXISTS guard ensures only one event per CreditID. The event stores all financial data and attribution context needed for standalone re-evaluation. CreditSource and ProductID (PART-5458) were added to support ISA MoneyFarm commission tracking.

---

## 2. Business Logic

### 2.1 Idempotent Event Creation

**What**: Creates one event per credit, silently skipping duplicates.

**Columns/Parameters Involved**: `@CreditID`

**Rules**:
- INSERT ... WHERE NOT EXISTS (SELECT 1 FROM CreditEvent WHERE CreditID = @CreditID)
- If event already exists: no-op
- Captures credit snapshot at creation time

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditID | bigint (IN) | NO | - | CODE-BACKED | Credit identifier. Used for idempotency check and as the event's credit reference. |
| 2 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | Attributed affiliate at event creation time. |
| 3 | @CreditDate | datetime (IN) | NO | - | CODE-BACKED | When the credit occurred. |
| 4 | @Amount | float (IN) | NO | - | CODE-BACKED | Credit amount. |
| 5 | @IsFirstDeposit | bit (IN) | NO | - | CODE-BACKED | Whether this is the customer's first deposit. |
| 6 | @CreditTypeID | tinyint (IN) | NO | - | CODE-BACKED | Credit type: 1=Deposit, 4/5=Chargeback. |
| 7 | @CountryID | bigint (IN) | NO | - | CODE-BACKED | Customer's country. |
| 8 | @ProviderID | bigint (IN) | NO | - | CODE-BACKED | Current provider. |
| 9 | @RealProviderID | bigint (IN) | NO | - | CODE-BACKED | Actual executing provider. |
| 10 | @OriginalProviderID | bigint (IN) | NO | - | CODE-BACKED | Original provider. |
| 11 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID. |
| 12 | @GCID | bigint (IN) | NO | - | CODE-BACKED | Global Customer ID. Added PART-3405. |
| 13 | @LastCheckDate | datetime (IN) | YES | NULL | CODE-BACKED | Initial check date. NULL for new events. |
| 14 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition. |
| 15 | @CreditSource | int (IN) | YES | NULL | CODE-BACKED | Source system that originated the credit. Added PART-5458. |
| 16 | @ProductID | varchar(50) (IN) | YES | NULL | CODE-BACKED | ISA product identifier. Added PART-5458. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditEvent | WRITE (INSERT) + READ (EXISTS check) | Creates event; checks for duplicates |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called after InsertCredit.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.InsertCreditEvent (procedure)
+-- AffiliateCommission.CreditEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | INSERT with NOT EXISTS guard |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit processing pipeline) | External | Creates events for commission tracking |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a credit event
```sql
EXEC [AffiliateCommission].[InsertCreditEvent]
    @CreditID = 100, @AffiliateID = 3, @CreditDate = '2026-04-12',
    @Amount = 500.00, @IsFirstDeposit = 1, @CreditTypeID = 1,
    @CountryID = 1, @ProviderID = 1, @RealProviderID = 1,
    @OriginalProviderID = 1, @CID = 12345, @GCID = 67890,
    @Source = 'Main'
```

### 8.2 Check existing credit events
```sql
SELECT ID, CreditID, AffiliateID, CreditDate, CreditTypeID, [Source]
FROM [AffiliateCommission].[CreditEvent] WITH (NOLOCK)
WHERE CreditID = 100
```

### 8.3 Count credit events by type and source
```sql
SELECT CreditTypeID, [Source], COUNT(*) AS EventCount
FROM [AffiliateCommission].[CreditEvent] WITH (NOLOCK)
GROUP BY CreditTypeID, [Source]
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-5458: Added CreditSource and ProductID (2026-01-14)
- PART-3405: Added GCID (2025-01-19)
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-2889: Fix RegistrationCommission AffiliateID (2023-03-28)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.InsertCreditEvent | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.InsertCreditEvent.sql*

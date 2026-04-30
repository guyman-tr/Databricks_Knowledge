# AffiliateCommission.InsertClosedPositionEvent

> Creates a closed position event record for commission tracking and re-evaluation, with an idempotency guard that prevents duplicate events for the same position.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into ClosedPositionEvent |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertClosedPositionEvent creates an event record that enables commission re-evaluation for a closed position. When a position is closed and enters the commission pipeline, an event is created with the position's financial snapshot. This event can later be picked up by GetClosedPositionTriggeredEvents when attribution changes require commission recalculation.

The WHERE NOT EXISTS guard ensures only one event per ClosedPositionID. If the position already has an event, the insert is silently skipped. The event stores all the financial data (Amount, HedgeCommission, NetProfit, LotCount) and attribution context (AffiliateID, providers, CountryID) needed for standalone re-evaluation without querying the source position.

---

## 2. Business Logic

### 2.1 Idempotent Event Creation

**What**: Creates one event per closed position, silently skipping duplicates.

**Columns/Parameters Involved**: `@ClosedPositionID`

**Rules**:
- INSERT ... WHERE NOT EXISTS (SELECT 1 FROM ClosedPositionEvent WHERE ClosedPositionID = @ClosedPositionID)
- If event already exists: no-op (no error, no insert)
- The event captures a snapshot of position data at creation time
- LastCheckDate defaults to NULL (first evaluation) or a provided value

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ClosedPositionID | bigint (IN) | NO | - | CODE-BACKED | Position identifier. Used for idempotency check and as the event's position reference. |
| 2 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | Attributed affiliate at event creation time. |
| 3 | @Occurred | datetime (IN) | NO | - | CODE-BACKED | When the position was closed (event timestamp). |
| 4 | @Amount | decimal(16,6) (IN) | NO | - | CODE-BACKED | Position trade amount. |
| 5 | @HedgeCommission | decimal(16,6) (IN) | NO | - | CODE-BACKED | Hedge commission deducted. |
| 6 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID. |
| 7 | @GCID | bigint (IN) | NO | - | CODE-BACKED | Global Customer ID. Added PART-3405. |
| 8 | @ProviderID | bigint (IN) | NO | - | CODE-BACKED | Current provider. |
| 9 | @OriginalProviderID | bigint (IN) | NO | - | CODE-BACKED | Original provider. |
| 10 | @RealProviderID | bigint (IN) | NO | - | CODE-BACKED | Actual executing provider. |
| 11 | @CountryID | bigint (IN) | NO | - | CODE-BACKED | Customer's country. |
| 12 | @NetProfit | money (IN) | NO | - | CODE-BACKED | Position net profit/loss. |
| 13 | @LotCount | decimal(16,6) (IN) | NO | - | CODE-BACKED | Trade lot count. |
| 14 | @LastCheckDate | datetime (IN) | YES | NULL | CODE-BACKED | Initial check date. NULL for new events (first evaluation). |
| 15 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPositionEvent | WRITE (INSERT) + READ (EXISTS check) | Creates event; checks for duplicates |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission engine after InsertClosedPosition.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.InsertClosedPositionEvent (procedure)
+-- AffiliateCommission.ClosedPositionEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionEvent | Table | INSERT with NOT EXISTS guard |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission engine) | External | Creates events for commission tracking |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a closed position event
```sql
EXEC [AffiliateCommission].[InsertClosedPositionEvent]
    @ClosedPositionID = 500000, @AffiliateID = 3, @Occurred = '2026-04-12',
    @Amount = 100.00, @HedgeCommission = 2.50, @CID = 12345, @GCID = 67890,
    @ProviderID = 1, @OriginalProviderID = 1, @RealProviderID = 1,
    @CountryID = 1, @NetProfit = 50.00, @LotCount = 1.0,
    @Source = 'Main'
```

### 8.2 Check existing events for a position
```sql
SELECT ID, ClosedPositionID, AffiliateID, Occurred, CID, [Source]
FROM [AffiliateCommission].[ClosedPositionEvent] WITH (NOLOCK)
WHERE ClosedPositionID = 500000
```

### 8.3 Count events by source
```sql
SELECT [Source], COUNT(*) AS EventCount
FROM [AffiliateCommission].[ClosedPositionEvent] WITH (NOLOCK)
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-3405: Added GCID (2025-01-19)
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-2889: Fix RegistrationCommission AffiliateID (2023-03-28)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.InsertClosedPositionEvent | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.InsertClosedPositionEvent.sql*

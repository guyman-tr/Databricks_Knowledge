# Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest

> Test copy of TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId - identical SQL body preserved for testing and verification purposes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID INT (identical to production variant) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a testing copy of `Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId`. The SQL body is **identical** to the production variant - same parameters, same logic, same result sets. It was created as a safe testing sandbox to validate behavior of the public mirror history API without risk to the production procedure.

For full documentation of the business logic, parameters, output columns, and dependencies, see: [Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId](Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId.md).

---

## 2. Business Logic

Identical to `TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId`. See referenced documentation for all logic details:

- CID resolution from @MirrorID via Trade.Mirror / History.Mirror fallback
- RealizedEquity < 0 guard (RAISERROR 60088)
- Privacy block check (RAISERROR 60090)
- Unified #t staging of History.Credit with OFFSET/FETCH pagination
- RS1: Cashflow events (CreditTypeID NOT IN 4,22,24) - IsMoneyOut, HistoryMirrorOperation, MirrorAmountDelta, IsCopyDividend
- RS2: Closed positions (History.Position JOIN #t WHERE CreditTypeID IN 4,22,24) - position-level details with NetProfit as percentage

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

Identical to `TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId`. See [referenced documentation](Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId.md#4-elements).

### Input Parameters (identical)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | Copy session identifier. CID resolved internally. |
| 2 | @StartTime | DATETIME | YES | NULL | CODE-BACKED | Optional look-back start for History.Credit.Occurred. |
| 3 | @PageNumber | INT | NO | - | CODE-BACKED | 1-based page number for unified #t pagination. |
| 4 | @ItemsPerPage | INT | NO | - | CODE-BACKED | Page size for unified #t pagination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Identical to `TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId`:
- Trade.Mirror, Customer.Customer, Customer.BlockedCustomerOperations, History.Mirror, History.Credit, History.Position

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This is a test procedure - use of the production variant is expected for live traffic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest (procedure)
├── Trade.Mirror (table)
├── Customer.Customer (table - cross-schema)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema, fallback CID lookup)
├── History.Credit (table - cross-schema)
└── History.Position (table - cross-schema)
```

### 6.1 Objects This Depends On

Identical to production variant. See [Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId](Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId.md#61-objects-this-depends-on).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId | Procedure | Production counterpart - same SQL, different name. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute identically to the production variant
```sql
EXEC Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest
    @MirrorID = 99999,
    @StartTime = NULL,
    @PageNumber = 1,
    @ItemsPerPage = 20
```

### 8.2 Compare output between Test and Production variants
```sql
-- Run both and compare result sets for the same MirrorID
EXEC Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId    @MirrorID=99999, @StartTime=NULL, @PageNumber=1, @ItemsPerPage=20
EXEC Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest @MirrorID=99999, @StartTime=NULL, @PageNumber=1, @ItemsPerPage=20
```

### 8.3 Verify identical definitions
```sql
SELECT name, OBJECT_DEFINITION(object_id) AS body_length
FROM sys.procedures WITH (NOLOCK)
WHERE name IN (
    'TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId',
    'TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest'
)
AND schema_id = SCHEMA_ID('Trade')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest.sql*

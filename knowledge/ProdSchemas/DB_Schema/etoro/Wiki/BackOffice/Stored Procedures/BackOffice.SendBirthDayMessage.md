# BackOffice.SendBirthDayMessage

> Sends automated birthday greeting messages to all customers whose birthday falls on the current calendar date, provided the birthday event type is currently active.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - targets all customers with today's birthday |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SendBirthDayMessage is a daily scheduled procedure that identifies customers with birthdays today and dispatches a birthday greeting event for each one via Customer.SendEvent. It is designed to be called once per day (typically by the BackOffice scheduler or an external job) and sends EventTypeID=5 (birthday event) to every customer whose BirthDate matches today's day and month.

The procedure implements a feature-flag guard: if EventTypeID=5 is inactive in Dictionary.EventType (IsActive=0), it returns 0 immediately without processing any customers - this allows the birthday messaging feature to be turned off without deploying code changes.

The entire batch runs in a single transaction. If any individual SendEvent call fails, the procedure terminates immediately (without rolling back the transaction - using RETURN rather than ROLLBACK), returns the error code, and leaves partial sends in place. This is a known limitation: the transaction was started but may commit any work done before the failure if the caller does not check the return value.

---

## 2. Business Logic

### 2.1 Birthday Matching Logic

**What**: Identifies customers whose calendar birthday (day + month) matches today, regardless of year.

**Columns/Parameters Involved**: `Customer.Customer.BirthDate`, `GETDATE()`

**Rules**:
- Match condition: `DAY(BirthDate) = DAY(GETDATE()) AND MONTH(BirthDate) = MONTH(GETDATE())`
- Year is intentionally excluded - sends on the annual anniversary regardless of birth year
- Customers with NULL BirthDate are excluded (DAY(NULL)/MONTH(NULL) = NULL, won't match)
- No filter on account status (IsActive, RegulationID) - all customers with matching BirthDate are included

### 2.2 Feature Guard via EventType Registry

**What**: The procedure checks whether birthday messaging is currently enabled before processing any customers.

**Columns/Parameters Involved**: `Dictionary.EventType.EventTypeID`, `Dictionary.EventType.IsActive`

**Rules**:
- Checks: `SELECT * FROM Dictionary.EventType WHERE EventTypeID=5 AND IsActive=1`
- If EventTypeID=5 is not found or IsActive=0 -> RETURN 0 (feature disabled, do nothing)
- EventTypeID=5 is the birthday event type. Other event types serve different purposes (registration confirmation, milestone notifications, etc.)
- This guard allows quick disabling without code deployment

### 2.3 Cursor-Based Batch Processing

**What**: Each birthday customer is processed individually via a CURSOR.

**Columns/Parameters Involved**: `Customer.Customer.CID`, `@CID`, `@Answer`

**Rules**:
- CURSOR type: LOCAL READ_ONLY FORWARD_ONLY STATIC (snapshot of birthday customers at proc start)
- For each CID: EXECUTE @Answer = Customer.SendEvent 5, @CID
- If @Answer != 0 (SendEvent error): close/deallocate cursor, RETURN @Answer immediately
- On error exit: transaction is NOT explicitly rolled back - the BEGIN TRANSACTION was already opened but partial sends from prior CIDs processed successfully may commit if the caller commits the outer transaction
- On success: COMMIT TRANSACTION and RETURN 0

**Diagram**:
```
Check Dictionary.EventType EventTypeID=5 IsActive=1
  -> NO? RETURN 0 (feature disabled)
  -> YES?
      BEGIN TRANSACTION
      CURSOR: SELECT CID FROM Customer.Customer WHERE today's birthday
        FOR EACH @CID:
          EXEC Customer.SendEvent EventTypeID=5, @CID
          IF error -> CLOSE cursor, RETURN error code
      COMMIT TRANSACTION
      RETURN 0
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Internal variables**:

| # | Variable | Type | Description |
|---|----------|------|-------------|
| V1 | @Answer | INTEGER | Captures return value from Customer.SendEvent. 0=success, non-zero=error. Controls abort logic. |
| V2 | @CID | INTEGER | Current customer ID being processed in the birthday cursor loop. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EventTypeID=5 guard | Dictionary.EventType | Lookup | Checks if birthday event type is currently active |
| BirthDate query | Customer.Customer | READER (SELECT) | Queries all customers with today's birthday (day + month match) |
| EXEC Customer.SendEvent | Customer.SendEvent | Procedure call | Dispatches the birthday event for each customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Scheduler / external job | - | Caller | Called once daily to dispatch birthday messages. No SQL caller found in SSDT. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SendBirthDayMessage (procedure)
├── Dictionary.EventType (table)
├── Customer.Customer (table)
└── Customer.SendEvent (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EventType | Table | Guard check: EventTypeID=5 AND IsActive=1 |
| Customer.Customer | Table | Source of CIDs with matching birthday (DAY/MONTH match) |
| Customer.SendEvent | Procedure | Called with EventTypeID=5 and @CID for each birthday customer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Scheduler / external job | External | Calls this procedure daily for birthday messaging |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Known Limitations

- **Partial transaction risk**: If Customer.SendEvent fails mid-cursor, the procedure returns the error but does NOT roll back the already-started transaction. Sends completed before the failure may persist if the outer caller does not handle the non-zero return value.
- **No year filtering**: Customers with February 29 birthdays in non-leap years will not be matched (DAY(Feb 29) = 29, MONTH = 2, but Feb 29 doesn't exist in non-leap years when GETDATE() is used).
- **No status filter**: All customers with matching BirthDate receive the event, including inactive or restricted accounts.

---

## 8. Sample Queries

### 8.1 Preview today's birthday customers (dry run)
```sql
SELECT CID, BirthDate
FROM Customer.Customer WITH (NOLOCK)
WHERE DAY(BirthDate)   = DAY(GETDATE())
  AND MONTH(BirthDate) = MONTH(GETDATE())
ORDER BY CID
```

### 8.2 Check if birthday event type is active
```sql
SELECT EventTypeID, EventTypeName, IsActive
FROM Dictionary.EventType WITH (NOLOCK)
WHERE EventTypeID = 5
```

### 8.3 Count birthday customers by month
```sql
SELECT
    MONTH(BirthDate) AS BirthMonth,
    COUNT(*) AS CustomerCount
FROM Customer.Customer WITH (NOLOCK)
WHERE BirthDate IS NOT NULL
GROUP BY MONTH(BirthDate)
ORDER BY BirthMonth
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SendBirthDayMessage | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SendBirthDayMessage.sql*

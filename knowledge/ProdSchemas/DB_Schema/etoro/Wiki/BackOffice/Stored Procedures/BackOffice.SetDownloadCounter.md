# BackOffice.SetDownloadCounter

> Sets the download counter value for a customer in Customer.Customer, tracking how many times the customer has downloaded the eToro trading application.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetDownloadCounter is a direct-write procedure that updates the DownloadCounter column on Customer.Customer for a given customer. The download counter tracks how many times a customer has downloaded the eToro trading platform application (web, mobile, or desktop installers). This metric is used in customer engagement analysis and sales/retention workflows within BackOffice.

The procedure resides in BackOffice schema despite writing to Customer.Customer, indicating it is called by BackOffice agents or automated BackOffice processes (rather than the trading platform itself). This supports scenarios where BackOffice staff correct or manually set the download count, or where a BackOffice service records application download events.

The design is a simple overwrite - the caller provides the desired final count, not an increment. This means the caller is responsible for fetching the current count and computing the new value before calling.

---

## 2. Business Logic

### 2.1 Direct Counter Overwrite

**What**: Overwrites the DownloadCounter with the exact value provided - not an increment.

**Columns/Parameters Involved**: `@CID`, `@DownloadCounter`

**Rules**:
- UPDATE Customer.Customer SET DownloadCounter=@DownloadCounter WHERE CID=@CID
- No increment logic - the caller passes the desired final counter value
- Returns @@ERROR (0=success, non-zero=SQL error)
- No validation of @DownloadCounter value (negative values are theoretically possible)
- If @CID not found: 0 rows affected, @@ERROR=0, RETURN 0 (silent no-op)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | The customer whose download counter is being set. Must correspond to a valid CID in Customer.Customer. No FK validation in the procedure - invalid CID results in a 0-row-affected no-op. |
| 2 | @DownloadCounter | INTEGER | NO | - | CODE-BACKED | The new download counter value to write to Customer.Customer.DownloadCounter. This is an overwrite - the caller computes the desired final value. Typically incremented by 1 from the current value by the caller before passing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | MODIFIER (UPDATE DownloadCounter) | Sets the download counter for the specified customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application download tracking service | - | Caller | Called to record or correct the download count for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetDownloadCounter (procedure)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | UPDATE: SET DownloadCounter=@DownloadCounter WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice download tracking | External | Calls to record application download events for customers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Set a customer's download counter
```sql
DECLARE @Err INT
EXEC @Err = BackOffice.SetDownloadCounter
    @CID             = 12345678,
    @DownloadCounter = 3
SELECT @Err AS ErrorCode
```

### 8.2 Increment the download counter (fetch current, add 1, then set)
```sql
DECLARE @CurrentCount INT, @Err INT
SELECT @CurrentCount = DownloadCounter
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678

EXEC @Err = BackOffice.SetDownloadCounter
    @CID             = 12345678,
    @DownloadCounter = @CurrentCount + 1
SELECT @Err AS ErrorCode
```

### 8.3 Find customers by download count range
```sql
SELECT CID, DownloadCounter
FROM Customer.Customer WITH (NOLOCK)
WHERE DownloadCounter > 0
ORDER BY DownloadCounter DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetDownloadCounter | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetDownloadCounter.sql*

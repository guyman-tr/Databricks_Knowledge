# Customer.sp_GetNumberOfOpenPositions

> Returns the total count of open trading positions for a customer by querying Trade.Position with NOLOCK.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT - the customer to count positions for |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.sp_GetNumberOfOpenPositions` provides a quick count of how many open trading positions a customer currently holds. It reads from `Trade.Position` (the live open positions table) with NOLOCK to avoid blocking the trading engine. This count is used by the application to determine whether a customer has active exposure in the market - relevant for operations like account closure, trading restrictions, or UI display.

The `sp_` prefix is non-standard for the Customer schema (it's a convention from older SQL Server days suggesting a system procedure), but this is a regular stored procedure.

---

## 2. Business Logic

### 2.1 Open Position Count

**What**: Counts all rows in Trade.Position for the given CID.

**Rules**:
- `SELECT COUNT(*) AS NumberOfOpenPositions FROM Trade.Position WITH(NOLOCK) WHERE CID = @CID`.
- Returns 0 if the customer has no open positions.
- NOLOCK hint used to avoid contention with the high-frequency trading engine writes.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. All rows in Trade.Position WHERE CID = @CID are counted. |

**Returned:**

| Column | Description |
|--------|-------------|
| NumberOfOpenPositions | COUNT(*) of open positions for the customer; 0 if none |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.Position | READ (NOLOCK) | Counts open position rows for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | External call | Caller | Checks customer's open position count |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.sp_GetNumberOfOpenPositions (procedure)
└── Trade.Position (table) [READ NOLOCK - count open positions]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | READ (NOLOCK) - COUNT(*) WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | External | Calls to check open position count before account operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Performance | Avoids blocking trade engine; may read uncommitted inserts/deletes (acceptable for count display) |
| No IsOpen filter | Design | Trade.Position only contains open positions - no status filter needed |

---

## 8. Sample Queries

### 8.1 Check open positions for a customer

```sql
EXEC Customer.sp_GetNumberOfOpenPositions @CID = 12345
```

### 8.2 Manual equivalent query

```sql
SELECT COUNT(*) AS NumberOfOpenPositions
FROM Trade.Position WITH (NOLOCK)
WHERE CID = 12345
```

### 8.3 Find customers with many open positions

```sql
SELECT TOP 20
    CID,
    COUNT(*) AS PositionCount
FROM Trade.Position WITH (NOLOCK)
GROUP BY CID
ORDER BY PositionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.sp_GetNumberOfOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.sp_GetNumberOfOpenPositions.sql*

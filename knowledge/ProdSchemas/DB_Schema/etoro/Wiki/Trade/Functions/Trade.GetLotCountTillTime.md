# Trade.GetLotCountTillTime

> Scalar function that returns the total lot count for a customer across all positions (open and historical) that opened on or before a specified datetime.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIGINT (sum of LotCountDecimal) |
| **Partition** | N/A |
| **Indexes** | N/A for function |

---

## 1. Business Meaning

Trade.GetLotCountTillTime answers: "How many lots had this customer accumulated by a given point in time?" It sums LotCountDecimal from both Trade.Position (currently open positions) and History.Position (closed positions) where InitDateTime is on or before the supplied @DateTime. This is used for liquidity provider contract execution tracking and historical lot-count reconciliation — for example, when the BackOffice cashier history needs to know how much exposure a customer had at a specific past moment.

This function exists because lot count is a key metric for contract execution and margin. Without it, systems could not reconstruct a customer's aggregate lot exposure at historical timestamps. BackOffice.JUNK_CashierHistory uses it to derive lot-based cashier history for credit types 5 and 7.

Data flows: The function is called with @CID (customer) and @DateTime (cutoff). It runs a UNION ALL of Trade.Position and History.Position, filters by CID and InitDateTime <= @DateTime, groups by CID, and returns SUM(LotCountDecimal). The result can be NULL if the subquery returns no rows (customer has no positions by that time).

---

## 2. Business Logic

### 2.1 Open + Historical Aggregate

**What**: Lot count is aggregated from both live and historical positions to reconstruct exposure at any point in time.

**Columns/Parameters Involved**: `@CID`, `@DateTime`, `LotCountDecimal`, `InitDateTime`

**Rules**:
- Trade.Position holds currently open positions; History.Position holds closed positions.
- Only rows with InitDateTime <= @DateTime are included — positions opened after @DateTime are excluded.
- LotCountDecimal is summed per CID. The subquery groups by CID and returns one aggregated value.
- If the customer has no positions by @DateTime, the function returns NULL (SELECT @Total = SUM(...) yields NULL when no rows).

**Diagram**:
```
@CID, @DateTime
        |
        v
  [UNION ALL]
   /        \
Trade.Position   History.Position
(LotCountDecimal, InitDateTime)
        |
        v
WHERE CID = @CID AND InitDateTime <= @DateTime
        |
        v
GROUP BY CID → SUM(LotCountDecimal) → @Total → RETURN
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | integer | NO | - | CODE-BACKED | Customer ID. Filters positions to this customer. References Customer.Customer. |
| 2 | @DateTime | datetime | NO | - | CODE-BACKED | Cutoff timestamp. Only positions with InitDateTime <= @DateTime are included. Used for point-in-time lot reconstruction. |
| 3 | (return value) | bigint | YES | - | CODE-BACKED | Sum of LotCountDecimal from Trade.Position and History.Position for the customer at or before @DateTime. NULL if no positions exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Implicit | Customer whose lot count is computed. |
| (FROM) | Trade.Position | Implicit | Open positions. Inherits LotCountDecimal, InitDateTime from Trade.PositionTbl. |
| (FROM) | History.Position | Implicit | Closed positions. Same structure as Trade.Position. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.JUNK_CashierHistory | SELECT | Reader | Uses IsNull(Trade.GetLotCountTillTime(HCDT.CID, HCDT.Occurred), 0) for credit types 5 and 7. |
| Dealing | GRANT EXECUTE | Permission | Role can execute the function. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLotCountTillTime (function)
├── Trade.Position (view)
│     └── Trade.PositionTbl (table)
└── History.Position (table/view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | FROM — open positions and LotCountDecimal, InitDateTime |
| History.Position | Table | FROM — closed positions for historical lot count |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.JUNK_CashierHistory | View | Calls function for lot-based cashier history (credit types 5, 7) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get lot count for a customer at a specific time
```sql
SELECT Trade.GetLotCountTillTime(14952810, '2026-01-15 12:00:00') AS LotCountTillTime;
```

### 8.2 Lot count at time of each cashier event
```sql
SELECT HCDT.CID, HCDT.Occurred,
       ISNULL(Trade.GetLotCountTillTime(HCDT.CID, HCDT.Occurred), 0) AS LotCountAtTime
FROM   BackOffice.SomeCashierTable HCDT WITH (NOLOCK)
WHERE  HCDT.CreditTypeID IN (5, 7);
```

### 8.3 Compare lot count across multiple cutoff times
```sql
SELECT CID,
       Trade.GetLotCountTillTime(CID, '2026-01-01') AS LotsEndOf2025,
       Trade.GetLotCountTillTime(CID, '2026-03-01') AS LotsEndOfFeb
FROM   Customer.Customer WITH (NOLOCK)
WHERE  CID IN (14952810, 24713264);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLotCountTillTime | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetLotCountTillTime.sql*

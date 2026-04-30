# Trade.GenerateCloseByUnitsPositionsList

> Generates a list of positions to close by units for a given customer and instrument, distributing the requested units across manual positions in FIFO order.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns inserted rows from History.CloseByUnitsRequests via OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements the "Close by Units" feature, which allows a customer to close a specified number of units of a particular instrument without targeting specific positions. Instead of closing individual positions one by one, the customer specifies a total unit amount and the system determines which positions to close (fully or partially) in FIFO (first-in, first-out) order based on the position open date.

The procedure exists to support partial portfolio reduction. A customer holding multiple manual positions on the same instrument can request to close, say, 50 units total, and the system will walk through positions chronologically (oldest first), closing each fully until the total is met, with the last position potentially receiving a partial close.

Data flows from Trade.PositionTbl and Trade.Position (view) where open manual positions are validated and aggregated. The procedure validates the request (positive units, single direction, sufficient units), generates a unique CloseByUnitsID from a sequence, computes the FIFO distribution using a running aggregate CTE, and inserts the resulting close plan into History.CloseByUnitsRequests. The inserted rows are returned via OUTPUT to the caller for execution.

---

## 2. Business Logic

### 2.1 FIFO Close-by-Units Distribution Algorithm

**What**: Distributes the requested close amount across positions in chronological order (oldest first).

**Columns/Parameters Involved**: `@UnitsToCloseDecimal`, `AmountInUnitsDecimal`, `InitDateTime`, `PositionID`

**Rules**:
- Positions are ordered by InitDateTime (open date) ascending - oldest positions close first
- A running sum (AggSum) of AmountInUnitsDecimal is computed over this order
- Each position where `AggSum - AmountInUnitsDecimal < @UnitsToCloseDecimal` is included in the close plan
- If @UnitsToCloseDecimal >= AggSum for a position, it closes fully (IsFullUnitsClose=1)
- The last position may be partially closed: UnitsToClose = @UnitsToCloseDecimal - (AggSum - AmountInUnitsDecimal)

**Diagram**:
```
Positions sorted by InitDateTime (FIFO):
  Pos A: 10 units (AggSum=10)  -> Close ALL 10 (full)
  Pos B: 15 units (AggSum=25)  -> Close ALL 15 (full)
  Pos C: 20 units (AggSum=45)  -> Close 5 of 20 (partial)
  Pos D: 30 units (AggSum=75)  -> NOT included
                                   (AggSum-30=45 >= requested 30)
  Requested: 30 units total = 10 + 15 + 5 = 30
```

### 2.2 Manual-Only Position Filtering

**What**: Only manual (non-copy) positions are eligible for close-by-units.

**Columns/Parameters Involved**: `MirrorID`, `ParentPositionID`, `RedeemStatus`

**Rules**:
- MirrorID = 0 and ParentPositionID = 0 filters to manual positions only (not CopyTrader positions)
- RedeemStatus = 0 ensures only active (non-redeemed) positions are considered
- Positions already pending a full close via Trade.OrdersExit are excluded
- Positions pending a partial close ARE included (to account for opposite direction units)

### 2.3 Validation Rules

**What**: Three pre-flight validations before generating the close list.

**Columns/Parameters Involved**: `@UnitsToCloseDecimal`, `@CID`, `@InstrumentID`

**Rules**:
- @UnitsToCloseDecimal must be > 0 (RAISERROR if negative or zero)
- Customer must have only one direction (all Buy or all Sell) for this instrument - mixed directions are rejected (RAISERROR)
- Customer must have sufficient total units >= @UnitsToCloseDecimal (RAISERROR if insufficient)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose manual positions will be evaluated for closing. |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument (stock, ETF, crypto, etc.) to close units for. Only positions on this specific instrument are considered. |
| 3 | @UnitsToCloseDecimal | DECIMAL(16,8) | NO | - | CODE-BACKED | Total number of units to close across all positions. Must be positive and <= customer's total available manual units on the instrument. |
| 4 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency/tracking GUID from the client. If NULL, the procedure generates a new GUID via NEWID(). Used for request deduplication and audit trails. |

**Output columns (via OUTPUT INSERTED.*):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | CloseByUnitsID | BIGINT | NO | - | CODE-BACKED | Unique batch identifier generated from Trade.SeqCloseByUnitsRequests sequence. Groups all position close entries belonging to the same close-by-units request. |
| 6 | CID | INT | NO | - | CODE-BACKED | Customer ID (copied from @CID parameter). |
| 7 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID (copied from @InstrumentID parameter). |
| 8 | PositionID | BIGINT | NO | - | CODE-BACKED | The specific position to close (fully or partially). Selected by the FIFO algorithm. |
| 9 | IsFullUnitsClose | BIT | NO | - | CODE-BACKED | 1 = close the entire position, 0 = partial close (only the last position in the FIFO chain may be partial). |
| 10 | UnitsToClose | DECIMAL(16,8) | NO | - | CODE-BACKED | Number of units to close for this specific position. For full closes, equals AmountInUnitsDecimal. For the partial (last) position, equals the remaining units needed to fulfill the request. |
| 11 | TotalUnitsToClose | DECIMAL(16,8) | NO | - | CODE-BACKED | The original @UnitsToCloseDecimal value. Same for all rows in the batch - represents the total requested close amount. |
| 12 | CreationDate | DATETIME | NO | - | CODE-BACKED | GETUTCDATE() at time of insertion. Records when the close-by-units plan was generated. |
| 13 | ClientRequestGuid | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The request tracking GUID (provided by caller or auto-generated). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM clause (validation) | Trade.PositionTbl | Direct Read | Reads open positions for validation (direction check, total units check) |
| LEFT JOIN (validation) | Trade.OrdersExit | Direct Read | Checks for existing pending close orders to exclude already-closing positions |
| FROM clause (CTE) | Trade.Position | Direct Read (View) | Reads open positions via the Position view for the FIFO distribution |
| LEFT JOIN (CTE) | Trade.OrdersExit | Direct Read | Excludes positions already pending close from the FIFO distribution |
| INSERT INTO | History.CloseByUnitsRequests | Write | Inserts the generated close plan rows |
| NEXT VALUE FOR | Trade.SeqCloseByUnitsRequests | Sequence | Generates unique CloseByUnitsID batch identifier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not discovered | - | - | No callers found in SQL repo. Likely called by application service directly. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GenerateCloseByUnitsPositionsList (procedure)
├── Trade.PositionTbl (table)
├── Trade.Position (view)
├── Trade.OrdersExit (table)
├── History.CloseByUnitsRequests (table)
└── Trade.SeqCloseByUnitsRequests (sequence)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT for validation (direction, total units) |
| Trade.Position | View | SELECT in CTE for FIFO distribution |
| Trade.OrdersExit | Table | LEFT JOIN to exclude positions already pending close |
| History.CloseByUnitsRequests | Table | INSERT INTO - stores the close plan |
| Trade.SeqCloseByUnitsRequests | Sequence | NEXT VALUE FOR - generates batch ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Validation 1 | RAISERROR | @UnitsToCloseDecimal must be > 0 |
| Validation 2 | RAISERROR | Customer must have single-direction positions only (all Buy or all Sell) |
| Validation 3 | RAISERROR | Total available units must be >= @UnitsToCloseDecimal |

---

## 8. Sample Queries

### 8.1 Close 50 units of instrument 1001 for customer 12345

```sql
EXEC Trade.GenerateCloseByUnitsPositionsList
    @CID = 12345,
    @InstrumentID = 1001,
    @UnitsToCloseDecimal = 50.00000000,
    @ClientRequestGuid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Check available manual positions before calling the procedure

```sql
SELECT  tp.PositionID,
        tp.AmountInUnitsDecimal,
        tp.IsBuy,
        tp.InitDateTime,
        tp.RedeemStatus
FROM    Trade.PositionTbl tp WITH (NOLOCK)
LEFT JOIN Trade.OrdersExit toe WITH (NOLOCK)
    ON tp.PositionID = toe.PositionID
WHERE   tp.CID = 12345
    AND tp.InstrumentID = 1001
    AND tp.MirrorID = 0
    AND tp.ParentPositionID = 0
    AND toe.PositionID IS NULL
    AND tp.RedeemStatus = 0
ORDER BY tp.InitDateTime;
```

### 8.3 Review close-by-units history for a customer

```sql
SELECT  cbur.CloseByUnitsID,
        cbur.PositionID,
        cbur.IsFullUnitsClose,
        cbur.UnitsToClose,
        cbur.TotalUnitsToClose,
        cbur.CreationDate
FROM    History.CloseByUnitsRequests cbur WITH (NOLOCK)
WHERE   cbur.CID = 12345
ORDER BY cbur.CreationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly for this procedure. Related: "US Sell All (Close all) - TDD" found in Confluence but not specific to this close-by-units workflow.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GenerateCloseByUnitsPositionsList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GenerateCloseByUnitsPositionsList.sql*

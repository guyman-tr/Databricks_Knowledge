# Trade.PostPositionOpenForSdrt

> Post-position-open queue for SDRT (Stamp Duty Reserve Tax) processing; captures newly opened UK real-stock positions that qualify for SDRT charges.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PositionID |
| **Partition** | No |
| **Indexes** | 3 (1 clustered PK, 2 NC on CID and StatusID) |

---

## 1. Business Meaning

**WHAT:** Trade.PostPositionOpenForSdrt is a post-position-open queue table. After a position opens, if it qualifies for SDRT (Stamp Duty Reserve Tax) - a UK tax on stock purchases - a row is inserted here for async processing.

**WHY:** SDRT applies to UK-regulated real stock purchases. The position-open flow must complete quickly; applying the SDRT charge can be deferred. This table decouples the fast open path from the SDRT charge application. Without it, position opens would block on tax processing.

**HOW:** When a position opens, the system checks if SDRT applies (UK regulated, real stock, buy direction). If yes, a row is inserted with PositionID, CID, InstrumentID, FeeInDollars, and other context. A background job or procedure (e.g. Trade.PostPositionOpenForSdrtCharge) consumes rows by StatusID, applies the charge, and removes or marks them processed. The table is typically EMPTY when idle because rows are consumed after processing.

---

## 2. Business Logic

### 2.1 SDRT Qualification

**What**: Positions qualify for SDRT when they are UK-regulated real stock purchases (buy direction).

**Columns Involved**: `InstrumentID`, `IsBuy`, `FeeInDollars`, `MirrorIsActive`, `Leverage`

**Rules**:
- Real stock (not CFD) and buy direction -> SDRT applies
- FeeInDollars holds the charge amount to apply
- UK regulation and instrument type determine eligibility

**Diagram**:
```
Position Open
    |
    v
SDRT Check: UK + Real Stock + Buy?
    |
    +-- NO -> skip
    |
    +-- YES -> INSERT into PostPositionOpenForSdrt
                    |
                    v
              Job processes by StatusID
                    |
                    v
              Apply charge, consume row
```

### 2.2 StatusID Processing

**What**: Tracks processing state for the queue consumer.

**Rules**:
- Pending rows have one StatusID value
- Processed rows are consumed (deleted or StatusID updated)
- Live data is EMPTY because queue is consumed after processing

---

## 3. Data Overview

| PositionID | CID | InstrumentID | FeeInDollars | StatusID | Meaning |
|-----------|-----|--------------|--------------|----------|---------|
| (empty) | - | - | - | - | Table is EMPTY (queue table - rows consumed after processing). |

**Selection criteria**: Queue table. Rows exist only briefly between position open and SDRT charge application. Idle state is empty.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Primary key. Position that opened and qualifies for SDRT. |
| 2 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position if this is a copied position. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID who opened the position. |
| 4 | MirrorID | int | YES | - | CODE-BACKED | Mirror ID if position is from copy-trade. |
| 5 | InstrumentID | int | NO | - | CODE-BACKED | Instrument (e.g. UK stock). References Trade.Instrument. |
| 6 | OpenActionType | int | YES | - | CODE-BACKED | How the position was opened (manual, copy, etc). |
| 7 | FeeInDollars | money | NO | - | CODE-BACKED | SDRT charge amount in dollars to apply. |
| 8 | MirrorIsActive | tinyint | YES | - | CODE-BACKED | Mirror active flag at open. |
| 9 | Leverage | int | YES | - | CODE-BACKED | Leverage at open. |
| 10 | IsBuy | bit | YES | - | CODE-BACKED | 1 = buy (long), 0 = sell (short). SDRT typically applies to buys. |
| 11 | StatusID | int | YES | - | CODE-BACKED | Processing status; tracks queue consumption. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | Position that opened. |
| CID | Customer.CustomerStatic | Implicit | Customer who opened. |
| InstrumentID | Trade.Instrument | Implicit | Instrument (UK stock). |
| MirrorID | Trade.Mirror | Implicit | Copy-trade mirror if applicable. |
| ParentPositionID | Trade.PositionTbl | Implicit | Parent position if copied. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PostPositionOpenForSdrtCharge | - | Procedure | Consumes queue, applies SDRT charge. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PostPositionOpenForSdrt (table)
(No code-level dependencies - CREATE TABLE has no FROM/JOIN)
```

### 6.1 Objects This Depends On

No code-level dependencies. Logical references to Trade.Instrument, Trade.PositionTbl, Trade.Mirror are in Section 5.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PostPositionOpenForSdrtCharge | Procedure | Reads and consumes queue for SDRT processing. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PostionID | CLUSTERED PK | PositionID ASC | - | - | Active |
| IX_CID | NONCLUSTERED | CID ASC | - | - | Active |
| IX_StatusID | NONCLUSTERED | StatusID ASC | - | - | Active |

Filegroup: DICTIONARY for PK and indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PostionID | PRIMARY KEY | PositionID ASC (clustered) |

---

## 8. Sample Queries

### 8.1 Check pending SDRT queue

```sql
SELECT PositionID, CID, InstrumentID, FeeInDollars, StatusID
FROM   Trade.PostPositionOpenForSdrt WITH (NOLOCK)
WHERE  StatusID = 0;
```

### 8.2 Count by status

```sql
SELECT StatusID, COUNT(*) AS Cnt
FROM   Trade.PostPositionOpenForSdrt WITH (NOLOCK)
GROUP BY StatusID;
```

### 8.3 Resolve instrument names for pending rows

```sql
SELECT p.PositionID, p.CID, p.FeeInDollars, i.Symbol
FROM   Trade.PostPositionOpenForSdrt p WITH (NOLOCK)
JOIN   Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = p.InstrumentID
WHERE  p.StatusID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + context*
*Sources: DDL, Trade.Instrument doc, PostPositionOpenForSdrtCharge procedure | Corrections: 0 applied*
*Object: Trade.PostPositionOpenForSdrt | Type: Table | Source: etoro/Trade/Tables/PostPositionOpenForSdrt.sql*

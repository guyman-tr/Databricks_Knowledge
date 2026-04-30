# Trade.GetDataForPositionAdjustment

> Retrieves position and customer data needed to adjust (resize/modify) a set of open positions, including instrument, units, rate, hedge server, and effective regulation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @positionsToClose (TVP of PositionIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDataForPositionAdjustment retrieves the data required to perform position adjustments (such as corporate actions, stock splits, or dividend-related resizing) on a batch of positions. For each position, it returns the position details (CID, InstrumentID, units, open rate, hedge server) along with the customer's effective regulation.

This procedure exists because position adjustments need to know the current state of each position and the regulatory context of each customer. The adjustment workflow uses this data to recalculate units, rates, or amounts while ensuring compliance with the customer's regulation.

Data flows from Trade.Position (view - open positions) joined with the @positionsToClose TVP on PositionID, then enriched with BackOffice.Customer for the effective RegulationID.

---

## 2. Business Logic

### 2.1 Batch Position Data Retrieval

**What**: Fetches position and regulatory data for a batch of positions to be adjusted.

**Columns/Parameters Involved**: `@positionsToClose`, `PositionID`, `RegulationID`, `DesignatedRegulationID`

**Rules**:
- Joins Trade.Position (view, StatusID=1 open positions) with the TVP on PositionID
- Enriches with BackOffice.Customer for regulation: ISNULL(DesignatedRegulationID, RegulationID)
- Returns one row per position with all data needed for the adjustment calculation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @positionsToClose | Trade.PositionIDsTbl (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing PositionIDs of positions to adjust. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. From Trade.Position. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID who owns the position. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | Instrument of the position. FK to Trade.Instrument. |
| 4 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Current position size in units/shares. |
| 5 | InitForexRate | float | YES | - | CODE-BACKED | Open rate (instrument price at position open). |
| 6 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server managing this position's hedge. |
| 7 | RegulationID | int | YES | - | CODE-BACKED | Customer's effective regulation: ISNULL(DesignatedRegulationID, RegulationID). FK to Dictionary.Regulation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position (view) | JOIN | Open position data |
| CID | BackOffice.Customer | JOIN | Customer regulation lookup |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDataForPositionAdjustment (procedure)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | JOIN - open position data |
| BackOffice.Customer | Table | JOIN - customer regulation |
| Trade.PositionIDsTbl | User Defined Type | TVP for position IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers discovered |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get adjustment data for specific positions

```sql
DECLARE @positions Trade.PositionIDsTbl;
INSERT INTO @positions (PositionID) VALUES (100001), (100002), (100003);
EXEC Trade.GetDataForPositionAdjustment @positionsToClose = @positions;
```

### 8.2 Direct query equivalent

```sql
SELECT  TP.PositionID, TP.CID, TP.InstrumentID, TP.AmountInUnitsDecimal,
        TP.InitForexRate, TP.HedgeServerID,
        ISNULL(BC.DesignatedRegulationID, BC.RegulationID) AS RegulationID
FROM    Trade.Position TP WITH (NOLOCK)
JOIN    BackOffice.Customer BC WITH (NOLOCK) ON TP.CID = BC.CID
WHERE   TP.PositionID IN (100001, 100002, 100003);
```

### 8.3 Find positions needing adjustment for an instrument

```sql
SELECT  TP.PositionID, TP.CID, TP.AmountInUnitsDecimal
FROM    Trade.Position TP WITH (NOLOCK)
WHERE   TP.InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDataForPositionAdjustment | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDataForPositionAdjustment.sql*

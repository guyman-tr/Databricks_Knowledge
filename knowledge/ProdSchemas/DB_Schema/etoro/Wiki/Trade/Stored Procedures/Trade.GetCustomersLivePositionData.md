# Trade.GetCustomersLivePositionData

> Reconstructs the full position history (both currently open and historically closed) for a set of customers as of a given date, enriched with instrument leverage bounds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs (TVP) + @MaxDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCustomersLivePositionData reconstructs the position portfolio of specified customers as it existed at a given point in time. It combines two sources: (1) positions that were open before @MaxDate but closed after @MaxDate (from History.Position - these were live at that date), and (2) currently open positions that were opened before @MaxDate (from Trade.PositionTbl - still live). Each row is enriched with the instrument's leverage bounds from Dictionary.LeverageType.

This procedure exists to support point-in-time portfolio reconstruction for analytics, compliance, or risk management. It answers: "What positions did these customers hold as of date X?" without requiring a temporal table query. The IsOpen flag distinguishes between positions that are still open vs those that have since been closed.

Data flows from History.Position (closed positions that overlapped with @MaxDate) UNION ALL Trade.PositionTbl (still-open positions opened before @MaxDate), both filtered by the @CIDs TVP. The result is then enriched via Trade.InstrumentMetaData -> Dictionary.LeverageType to add LowLeverageBound and HighLeverageBound per instrument type.

---

## 2. Business Logic

### 2.1 Point-in-Time Portfolio Reconstruction

**What**: Combines historical and current positions to show what was live at a specific moment.

**Columns/Parameters Involved**: `@MaxDate`, `InitDateTime`, `CloseOccurred`, `IsOpen`

**Rules**:
- History positions: CloseOccurred > @MaxDate AND InitDateTime < @MaxDate (was open at @MaxDate, closed after)
- Current positions: InitDateTime < @MaxDate AND StatusID=1 implicitly (Trade.PositionTbl with no end date filter)
- IsOpen = 0 for history positions, IsOpen = 1 for current positions
- InitialAmount is computed as InitialAmountCents / 100 (cents to dollars conversion)
- CloseOccurred for current positions is set to GETUTCDATE() (placeholder - still open)

### 2.2 Leverage Bounds Enrichment

**What**: Adds instrument-type-specific leverage limits to each position.

**Columns/Parameters Involved**: `LowLeverageBound`, `HighLeverageBound`, `InstrumentTypeID`

**Rules**:
- JOIN chain: Position.InstrumentID -> InstrumentMetaData.InstrumentTypeID -> Dictionary.LeverageType
- LowLeverageBound: Minimum leverage allowed for this instrument type
- HighLeverageBound: Maximum leverage allowed for this instrument type

**Diagram**:
```
History.Position (closed after @MaxDate, opened before)  --> IsOpen = 0
  UNION ALL
Trade.PositionTbl (opened before @MaxDate, still open)   --> IsOpen = 1
  |
  JOIN InstrumentMetaData -> Dictionary.LeverageType
  |
  Output: Position data + LowLeverageBound + HighLeverageBound
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | Trade.CidList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing Customer IDs to query. |
| 2 | @MaxDate | datetime | NO | - | CODE-BACKED | Point-in-time date. Positions must have been open at this date. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID who holds the position. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | Instrument traded. FK to Trade.Instrument. |
| 4 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 5 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier on this position. |
| 6 | InitDateTime | datetime | YES | - | CODE-BACKED | When the position was opened. |
| 7 | CloseOccurred | datetime | YES | - | CODE-BACKED | When the position was closed. For still-open positions, set to GETUTCDATE(). |
| 8 | InitialAmount | decimal | YES | - | CODE-BACKED | Position amount in dollars. Computed from InitialAmountCents / 100. |
| 9 | PositionRatio | decimal | YES | - | CODE-BACKED | Ratio for partial close tracking. |
| 10 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. 0 = manual position. |
| 11 | IsOpen | bit | NO | - | CODE-BACKED | 1 = position is currently open; 0 = position has been closed since @MaxDate. |
| 12 | LowLeverageBound | int | YES | - | CODE-BACKED | Minimum leverage allowed for this instrument type. From Dictionary.LeverageType. |
| 13 | HighLeverageBound | int | YES | - | CODE-BACKED | Maximum leverage allowed for this instrument type. From Dictionary.LeverageType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.Position | FROM (CTE) | Closed positions that were live at @MaxDate |
| CID | Trade.PositionTbl | FROM (CTE) | Currently open positions opened before @MaxDate |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Instrument type classification |
| InstrumentTypeID | Dictionary.LeverageType | JOIN | Leverage bounds per instrument type |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomersLivePositionData (procedure)
+-- History.Position (table)
+-- Trade.PositionTbl (table)
+-- Trade.InstrumentMetaData (table)
+-- Dictionary.LeverageType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | CTE - closed positions that overlapped with @MaxDate |
| Trade.PositionTbl | Table | CTE - currently open positions opened before @MaxDate |
| Trade.InstrumentMetaData | Table | JOIN - instrument type lookup |
| Dictionary.LeverageType | Table | JOIN - leverage bounds per instrument type |

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

### 8.1 Get positions live at a specific date

```sql
DECLARE @CIDs Trade.CidList;
INSERT INTO @CIDs (CID) VALUES (12345), (67890);
EXEC Trade.GetCustomersLivePositionData @CIDs, @MaxDate = '2025-12-31';
```

### 8.2 Get yesterday's live positions for a single customer

```sql
DECLARE @CIDs Trade.CidList;
INSERT INTO @CIDs (CID) VALUES (12345);
EXEC Trade.GetCustomersLivePositionData @CIDs, @MaxDate = DATEADD(DAY, -1, GETUTCDATE());
```

### 8.3 Inline equivalent for a specific customer

```sql
SELECT  p.CID, p.PositionID, p.InstrumentID, p.IsBuy, p.Leverage,
        p.InitDateTime, p.CloseOccurred, p.InitialAmountCents / 100 AS InitialAmount,
        0 AS IsOpen, DL.LowLeverageBound, DL.HighLeverageBound
FROM    History.Position p WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON IMD.InstrumentID = p.InstrumentID
INNER JOIN Dictionary.LeverageType DL WITH (NOLOCK) ON DL.InstrumentTypeID = IMD.InstrumentTypeID
WHERE   p.CID = 12345
        AND p.CloseOccurred > '2025-12-31'
        AND p.InitDateTime < '2025-12-31';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomersLivePositionData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomersLivePositionData.sql*

# Trade.GetDividendsByStatus

> Returns dividends filtered by processing status, enriched with the market close time for each instrument's exchange, and the IsSettled flag distinguishing CFD vs real positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @status (dividend processing status) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDividendsByStatus retrieves dividends from Trade.IndexDividends that are in a specific processing state, enriched with the UTC market close time calculated from the instrument's exchange and ex-date. Each instrument dividend has two rows - one for CFD positions (PositionType=0/IsSettled=0) and one for real positions (PositionType=1/IsSettled=1) - since they may have different tax treatments.

This procedure exists because the dividend payment pipeline needs to know which dividends are ready for the next processing step. It is called with different @status values at each pipeline stage (0=pending, 1=processing, 3=snapshot being taken, 4=snapshot ready).

Data flows from Trade.IndexDividends joined with Trade.InstrumentMetaData (for ExchangeID and InstrumentTypeID), using Trade.GetMarketCloseTimeByExDate function to compute the market close UTC time. Rows where MarketCloseDateTimeUtc IS NULL are excluded (exchange schedule not configured).

---

## 2. Business Logic

### 2.1 Dual Position Type Rows

**What**: Each instrument dividend exists as two rows - one for CFD and one for real stock positions.

**Columns/Parameters Involved**: `PositionType`, `IsSettled`

**Rules**:
- PositionType=0, IsSettled=0: dividend for CFD positions (synthetic ownership)
- PositionType=1, IsSettled=1: dividend for real stock positions (actual shareholder)
- Tax rates (BuyTax, SellTax) differ between the two types
- Code comment: "InstrumentTypeID=4 means Index, InstrumentTypeID=5 means Stock"
- For indexes and stocks (InstrumentTypeID IN 4,5), the InstrumentID is passed to GetMarketCloseTimeByExDate

### 2.2 Market Close Time Calculation

**What**: Determines the UTC time when the market closes for a given ex-date, using exchange schedules.

**Columns/Parameters Involved**: `ExchangeID`, `InstrumentID`, `ExDate`, `MarketCloseDateTimeUtc`

**Rules**:
- Trade.GetMarketCloseTimeByExDate(ExchangeID, InstrumentID, ExDate) computes the UTC close time
- InstrumentID is only passed for InstrumentTypeID IN (4,5) - indexes and stocks; NULL otherwise
- If MarketCloseDateTimeUtc IS NULL, the dividend is excluded (exchange schedule missing)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @status | int | NO | - | CODE-BACKED | Dividend processing status filter. 0=pending, 1=processing, 3=snapshot in progress, 4=snapshot ready. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Unique dividend identifier. PK of Trade.IndexDividends. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument paying the dividend. FK to Trade.Instrument. |
| 3 | IsSettled | bit | NO | - | CODE-BACKED | 0=CFD dividend, 1=real stock dividend. Converted from PositionType. |
| 4 | MarketCloseDateTimeUtc | datetime | YES | - | CODE-BACKED | UTC time when the market closes for this instrument on the ex-date. Computed by Trade.GetMarketCloseTimeByExDate. |
| 5 | LastUpdated | datetime | YES | - | CODE-BACKED | SysStartTime from temporal table - when this row was last modified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DividendID | Trade.IndexDividends | FROM | Dividend records |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Exchange and instrument type lookup |
| ExchangeID, ExDate | Trade.GetMarketCloseTimeByExDate | Function call | Market close time computation |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDividendsByStatus (procedure)
+-- Trade.IndexDividends (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.GetMarketCloseTimeByExDate (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | FROM - dividend records filtered by status |
| Trade.InstrumentMetaData | Table | JOIN - exchange and instrument type |
| Trade.GetMarketCloseTimeByExDate | Function | Computed column - market close UTC time |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by dividend pipeline service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get pending dividends

```sql
EXEC Trade.GetDividendsByStatus @status = 0;
```

### 8.2 Get dividends ready for payment

```sql
EXEC Trade.GetDividendsByStatus @status = 4;
```

### 8.3 Direct query for all dividend statuses

```sql
SELECT  TID.DividendID, TID.InstrumentID, TID.Status, TID.PositionType
FROM    Trade.IndexDividends TID WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON IMD.InstrumentID = TID.InstrumentID
ORDER BY TID.Status, TID.DividendID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDividendsByStatus | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDividendsByStatus.sql*

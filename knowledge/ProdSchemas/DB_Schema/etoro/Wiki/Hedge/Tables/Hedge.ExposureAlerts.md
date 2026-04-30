# Hedge.ExposureAlerts

> Legacy hedge execution alert log (2014 archive): captures failed TP/SL hedge close attempts and fractional-lot execution discrepancies; no longer actively written - data spans 2014-01-13 to 2014-03-21 only.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | AlertID IDENTITY (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Hedge.ExposureAlerts is a legacy notification log from the early hedge system (2014). It captured two categories of hedge execution problems:
1. **Failed TP/SL hedge closes** (AlertTypeID=1): When the hedge system attempted to close an exposure for a Take Profit or Stop Loss trigger but failed (e.g., no response from hedge server, execution timeout).
2. **Fractional lot execution alerts** (AlertTypeID=2/3): When hedge execution resulted in a fractional lot amount that could not be executed as whole lots - tracking the residual fractional units.

The table contains 37,705 rows covering a narrow 10-week window (2014-01-13 to 2014-03-21) and has not been written to since. All three writer procedures exist in the schema but are no longer called by active code. The table serves as a historical archive.

Three procedure variants exist, reflecting the evolution of the multi-server architecture:
- `Hedge.AddExpsosureAlert`: Current procedure, writes to local `Hedge.ExposureAlerts`
- `Hedge.AddExpsosureAlert_Child`: 3-part name `etoro.Hedge.ExposureAlerts` (cross-database on same server)
- `Hedge.AddExpsosureAlert_old`: Linked-server insert to `[AO-REAL-DB].etoro.Hedge.ExposureAlerts` (remote server write)

---

## 2. Business Logic

### 2.1 Alert Type Classification

**What**: AlertTypeID classifies the nature of the hedge alert. No dictionary table exists - types are inferred from description patterns.

**Columns/Parameters Involved**: `AlertTypeID`, `Description`, `UnitAmount`

**Observed AlertType values (inferred from data)**:

| AlertTypeID | Inferred Meaning | Count | UnitAmount Meaning |
|------------|-----------------|-------|-------------------|
| 1 | Failed TP/SL hedge close | 1,614 | Exposure size that failed to close (full units) |
| 2 | Fractional lot alert - OPEN (IsOpen=1) | 16,729 | Fractional lot remainder * 1000 |
| 3 | Fractional lot alert - CLOSE (IsOpen=0) | 19,362 | Fractional lot remainder * 1000 |

**AlertType 1 description format**: `"Failed closing exposure on TP/SL for Rate{price}, Fail rason: {reason}"`
- Fail reasons observed: "Failed getting response from Hedge Server", "execution time exceeded"

**AlertType 2/3 description format**: `"ExecutionID: {ID} ExecutionAmountInLots: {N} SumLotDecimal: {N} IsOpen: {0/1}"`
- `SumLotDecimal`: Total lots executed including fractional part (e.g., 23.114 lots)
- `UnitAmount`: The fractional portion * 1000 (e.g., 114 = 0.114 lots remainder)
- The alert fires when `SumLotDecimal` has a decimal part, indicating the executed amount cannot be expressed in whole lots

### 2.2 Direction Encoding

**Columns/Parameters Involved**: `IsBuy`

**Rules**:
- IsBuy = 1: The exposure that triggered the alert was a BUY-side hedge (eToro was net short customer exposure, hedging by buying)
- IsBuy = 0: The exposure was a SELL-side hedge
- For AlertType 1: IsBuy indicates the direction of the TP/SL close that failed

---

## 3. Data Overview

37,705 rows | Archive (2014-01-13 to 2014-03-21 only, no new data since)

| AlertID | NotificationTime | AlertTypeID | HedgeServerID | InstrumentID | UnitAmount | IsBuy | Description |
|---|---|---|---|---|---|---|---|
| 37705 | 2014-03-21 20:29:12 | 3 | 5 | 6 | 114 | false | ExecutionID: 6016463 ExecutionAmountInLots: 23.000000 SumLotDecimal: 23.114000 IsOpen: 0 |
| 36185 | 2014-03-04 (est) | 1 | 11 | 1 | 2000 | false | Failed closing exposure on TP/SL for Rate1.3763, Fail rason: Failed getting response from Hedge Server |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AlertID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment alert identifier. IDENTITY NOT FOR REPLICATION. Clustered PK. |
| 2 | NotificationTime | datetime | NO | - | CODE-BACKED | The datetime when the alert was generated and inserted. Not defaulted - caller must provide. |
| 3 | AlertTypeID | int | NO | - | NAME-INFERRED | Alert category: 1=Failed TP/SL close, 2=Fractional lot (open), 3=Fractional lot (close). No FK to a dictionary table in the schema. |
| 4 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). The hedge server where the problematic execution occurred. |
| 5 | InstrumentID | int | NO | - | CODE-BACKED | The instrument associated with the alert. Implicitly references Trade.Instrument. |
| 6 | UnitAmount | decimal(13,2) | NO | - | CODE-BACKED | For AlertType 1: the full exposure size (in units) that failed to close. For AlertTypes 2/3: the fractional lot amount * 1000 (e.g., 114 = 0.114 lots fractional remainder). Precision (13,2) supports large notional amounts. |
| 7 | IsBuy | bit | NO | - | CODE-BACKED | Direction of the hedge exposure: 1=BUY-side hedge, 0=SELL-side hedge. |
| 8 | Description | varchar(300) | NO | - | CODE-BACKED | Free-text description with structured content. AlertType 1: "Failed closing exposure on TP/SL for Rate{X}, Fail rason: {Y}". AlertTypes 2/3: "ExecutionID: {N} ExecutionAmountInLots: {N} SumLotDecimal: {N} IsOpen: {0/1}". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK | FK_HExpAlert_HSrv |
| InstrumentID | Trade.Instrument | Implicit (no DDL FK) | Instrument for the alert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddExpsosureAlert | - | Writer | Current writer - inserts locally |
| Hedge.AddExpsosureAlert_Child | - | Writer | Legacy cross-db writer (3-part name) |
| Hedge.AddExpsosureAlert_old | - | Writer | Legacy remote server writer via linked server [AO-REAL-DB] |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExposureAlerts (table)
  - FK: Trade.HedgeServer (HedgeServerID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddExpsosureAlert | Procedure | Writer (local) |
| Hedge.AddExpsosureAlert_Child | Procedure | Writer (cross-db) |
| Hedge.AddExpsosureAlert_old | Procedure | Writer (linked server) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_HedgeExposureAlerts | CLUSTERED PK | AlertID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_HedgeExposureAlerts | PRIMARY KEY | AlertID - unique per alert |
| FK_HExpAlert_HSrv | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |

---

## 8. Sample Queries

### 8.1 Failed TP/SL alerts by instrument
```sql
SELECT InstrumentID, COUNT(1) AS FailCount, AVG(UnitAmount) AS AvgUnitsAtRisk
FROM Hedge.ExposureAlerts
WHERE AlertTypeID = 1
GROUP BY InstrumentID
ORDER BY FailCount DESC;
```

### 8.2 Fractional lot alerts by instrument and direction
```sql
SELECT InstrumentID, IsBuy, AlertTypeID,
       COUNT(1) AS AlertCount,
       SUM(UnitAmount) / 1000.0 AS TotalFractionalLots
FROM Hedge.ExposureAlerts
WHERE AlertTypeID IN (2, 3)
GROUP BY InstrumentID, IsBuy, AlertTypeID
ORDER BY AlertCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.ExposureAlerts.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.6/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExposureAlerts | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExposureAlerts.sql*

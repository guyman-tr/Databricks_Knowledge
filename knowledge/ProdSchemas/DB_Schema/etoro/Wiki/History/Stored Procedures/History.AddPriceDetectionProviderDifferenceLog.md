# History.AddPriceDetectionProviderDifferenceLog

> Writer procedure that logs one secondary feed provider's price for a price anomaly event, inserting a detail row into History.PriceDetectionProviderDifferenceLog to record how far that provider's price differed from the active feed.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NotificationLogID + @ProviderID (maps to composite PK of target table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.AddPriceDetectionProviderDifferenceLog` is the third writer in the price anomaly detection event trio. Where `AddPriceDetectionDifferenceLog` records the active provider's outlier price (1 row per event), this procedure records each secondary feed provider's price for the same event (potentially multiple rows per event - one per secondary feed compared). Together, the three writers populate the complete three-table price detection event record.

This procedure exists because one anomaly event can involve multiple secondary feeds, each with its own price. When the active feed at price X is compared against three secondary feeds at prices Y1, Y2, Y3, this procedure is called three times with the same @NotificationLogID - once per secondary provider. This per-provider granularity allows operations to see not only that an anomaly occurred, but exactly which secondary providers disagreed and by how much (computing ProviderPrice - DifferenceLog.ActiveProviderPrice for each row).

The external price detection service calls this procedure once per secondary feed in the comparison set, typically called after both AddPriceDetectionDifferenceLog and AddPriceDetectionNotificationLog have succeeded. From live data, up to 2 secondary providers per event have been observed, meaning this procedure is called 1-2 times per anomaly event.

---

## 2. Business Logic

### 2.1 Third Write in the Three-Table Event Record

**What**: This procedure completes the price anomaly event record by adding the secondary provider price details for comparison with the active provider price.

**Columns/Parameters Involved**: `@NotificationLogID`, `@ProviderID`, `@ProviderPrice`

**Rules**:
- @NotificationLogID must match a row already inserted in History.PriceDetectionDifferenceLog (the composite PK requires this pairing)
- Called once per secondary feed provider being compared in this event
- The active provider price is stored in DifferenceLog; this procedure stores the secondary provider prices
- Price divergence per secondary provider = @ProviderPrice - DifferenceLog.ActiveProviderPrice
- When @ProviderPrice > ActiveProviderPrice: active feed is "Low" ("Low Price Problem Alert")
- When @ProviderPrice < ActiveProviderPrice: active feed is "High" ("High Price Problem Alert")

**Diagram**:
```
Full three-write sequence for one anomaly event:
    1. AddPriceDetectionDifferenceLog(Severity, Instrument, ActiveProviderID=21, Price=518.65, ...)
       -> logID = 1639035

    2. AddPriceDetectionNotificationLog(@ID=1639035, Subject="100024 : Low Price ...", ...)
       -> NotificationLog row 1639035

    3. AddPriceDetectionProviderDifferenceLog(@NotificationLogID=1639035, @ProviderID=102, @ProviderPrice=519.66)
       -> ProviderDifferenceLog row (1639035, 102, 519.66)
       -> Divergence: 519.66 - 518.65 = +1.01 -> "Low" (active is lower)

    [If 2 secondary feeds:]
    4. AddPriceDetectionProviderDifferenceLog(@NotificationLogID=1639035, @ProviderID=103, @ProviderPrice=519.70)
       -> ProviderDifferenceLog row (1639035, 103, 519.70)
```

### 2.2 Error Isolation

**What**: TRY/CATCH ensures composite PK violations or other INSERT failures return -1 rather than propagating.

**Columns/Parameters Involved**: all parameters

**Rules**:
- RETURN(0) on success
- RETURN(-1) on any INSERT failure (e.g., duplicate (NotificationLogID, ProviderID) pair)
- A -1 return means the ProviderDifferenceLog row was not written; the DifferenceLog and NotificationLog rows remain intact

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NotificationLogID | int | NO | - | CODE-BACKED | The shared log ID linking this secondary provider detail to its anomaly event. Must match a NotificationLogID already inserted in History.PriceDetectionDifferenceLog (which generated this ID as IDENTITY). Forms the first part of the composite PK in History.PriceDetectionProviderDifferenceLog. |
| 2 | @ProviderID | int | NO | - | CODE-BACKED | ID of the secondary price feed provider whose price is being recorded. This is a DIFFERENT provider from the ActiveProviderID in the corresponding DifferenceLog row. Forms the second part of the composite PK, enabling one row per (event, secondary provider). Implicit FK to provider lookup. |
| 3 | @ProviderPrice | float | NO | - | CODE-BACKED | The price reported by this secondary provider at the time of the anomaly event. Comparing this value against DifferenceLog.ActiveProviderPrice reveals the direction and magnitude of the divergence. When @ProviderPrice exceeds ActiveProviderPrice, the active feed was "Low" (below market); when lower, it was "High" (above market). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NotificationLogID, @ProviderID, @ProviderPrice | History.PriceDetectionProviderDifferenceLog | Write target | Inserts one secondary provider price row for the anomaly event |
| @NotificationLogID | History.PriceDetectionDifferenceLog | Implicit | @NotificationLogID was generated by this table's IDENTITY; must exist before this insert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External price detection service | (application call) | Application | Called once per secondary feed provider compared in an anomaly event. Not referenced by any SSDT stored procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AddPriceDetectionProviderDifferenceLog (procedure)
└── History.PriceDetectionProviderDifferenceLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PriceDetectionProviderDifferenceLog | Table | INSERT target - one row per (event, secondary provider) pair |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External price detection service | Application | Called once per secondary feed provider in the comparison set for each anomaly event |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None within the procedure. Target table (History.PriceDetectionProviderDifferenceLog) has a clustered composite PK on (NotificationLogID, ProviderID) - calling this procedure twice with the same @NotificationLogID + @ProviderID would trigger RETURN(-1).

---

## 8. Sample Queries

### 8.1 Get all secondary provider prices for a specific anomaly event

```sql
SELECT
    p.NotificationLogID,
    p.ProviderID,
    p.ProviderPrice,
    d.ActiveProviderID,
    d.ActiveProviderPrice,
    (p.ProviderPrice - d.ActiveProviderPrice) AS Divergence,
    d.NotificationSeverityTypeID
FROM History.PriceDetectionProviderDifferenceLog p WITH (NOLOCK)
JOIN History.PriceDetectionDifferenceLog d WITH (NOLOCK)
    ON d.NotificationLogID = p.NotificationLogID
WHERE p.NotificationLogID = 1639034
```

### 8.2 Find events with the largest price divergences

```sql
SELECT TOP 10
    p.NotificationLogID,
    p.ProviderID,
    d.ActiveProviderID,
    d.InstrumentID,
    d.ActiveProviderPrice,
    p.ProviderPrice,
    ABS(p.ProviderPrice - d.ActiveProviderPrice) AS AbsDivergence,
    d.Occurred
FROM History.PriceDetectionProviderDifferenceLog p WITH (NOLOCK)
JOIN History.PriceDetectionDifferenceLog d WITH (NOLOCK)
    ON d.NotificationLogID = p.NotificationLogID
ORDER BY AbsDivergence DESC
```

### 8.3 Count events by secondary provider to identify most frequently compared feeds

```sql
SELECT
    p.ProviderID,
    COUNT(*) AS TimesCompared,
    COUNT(DISTINCT p.NotificationLogID) AS UniqueEvents
FROM History.PriceDetectionProviderDifferenceLog p WITH (NOLOCK)
GROUP BY p.ProviderID
ORDER BY TimesCompared DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.AddPriceDetectionProviderDifferenceLog | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.AddPriceDetectionProviderDifferenceLog.sql*

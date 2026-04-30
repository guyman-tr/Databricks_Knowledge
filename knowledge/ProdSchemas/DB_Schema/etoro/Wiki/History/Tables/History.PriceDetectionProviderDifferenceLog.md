# History.PriceDetectionProviderDifferenceLog

> Detail log storing the secondary feed provider prices for each price anomaly event, providing the comparison data that reveals how much the active feed diverged from each secondary source.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (NotificationLogID, ProviderID) composite clustered PK |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 1 (1 clustered PK) |

---

## 1. Business Meaning

`History.PriceDetectionProviderDifferenceLog` is the secondary-feed detail extension of the price anomaly detection system. While `History.PriceDetectionDifferenceLog` records the active feed's price (the outlier), this table records the secondary feed providers' prices that the active feed was compared against. Together, the three tables form a complete record of every price detection event:

- `PriceDetectionDifferenceLog`: active provider, its price, severity, instrument (1 row per event)
- `PriceDetectionNotificationLog`: alert subject and body (1 row per event)
- `PriceDetectionProviderDifferenceLog` (this table): secondary provider prices (1-N rows per event, one per secondary feed)

For a given anomaly event (NotificationLogID), if ProviderID=21 is the active provider at price 518.65 and ProviderID=102 is a secondary provider at 519.66, this table has the row `(NotificationLogID, 102, 519.66)`. The difference (519.66 - 518.65 = 1.01) explains why a "Low Price Problem Alert" was triggered - the active feed was 1.01 below the secondary.

The composite PK `(NotificationLogID, ProviderID)` allows multiple secondary providers to be recorded per anomaly event - when two secondary feeds both disagree with the active feed, both appear here. From live data, up to 2 secondary providers per event have been observed.

---

## 2. Business Logic

### 2.1 Active vs Secondary Provider Price Comparison

**What**: Each row stores one secondary provider's price for the corresponding anomaly event, enabling calculation of the exact price divergence.

**Columns/Parameters Involved**: `NotificationLogID`, `ProviderID`, `ProviderPrice`

**Rules**:
- `NotificationLogID` FK links to PriceDetectionDifferenceLog which has the ACTIVE provider's price
- `ProviderID` here is the SECONDARY provider (different from `ActiveProviderID` in DifferenceLog)
- Price divergence = ABS(ActiveProviderPrice - ProviderPrice) or direction: ProviderPrice - ActiveProviderPrice
- When ProviderPrice > ActiveProviderPrice: active feed is "Low" (active shows lower price than secondary)
- When ProviderPrice < ActiveProviderPrice: active feed is "High" (active shows higher price than secondary)
- Multiple rows per NotificationLogID = multiple secondary feeds were compared; all disagreed with active

**Diagram**:
```
Anomaly Event (NotificationLogID = 1639034)
    |
    +-> PriceDetectionDifferenceLog:
    |       ActiveProviderID=21, ActiveProviderPrice=518.65  <- the outlier
    |
    +-> PriceDetectionProviderDifferenceLog: (this table)
            ProviderID=102, ProviderPrice=519.66  <- secondary feed
            Divergence: 519.66 - 518.65 = +1.01
            -> Active feed is LOW -> "Low Price Problem Alert"
```

---

## 3. Data Overview

213,120 rows. Multiple rows per NotificationLogID when 2 secondary feeds report different prices.

| NotificationLogID | ProviderID | ProviderPrice | Context |
|---|---|---|---|
| 1639034 | 102 | 519.66 | Secondary provider 102 price for anomaly #1639034. Active provider had 518.65, making it 1.01 lower than this secondary. "Low Price Problem Alert" |
| 1639033 | 102 | 519.66 | Same secondary price for adjacent anomaly - same feeds, same instrument in continuous monitoring |
| 1638261 | 102 | 519.XX | First secondary provider for dual-feed comparison event |
| 1638261 | (2nd) | 519.XX | Second secondary provider same event - 2 secondary feeds compared |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationLogID | int | NO | - | VERIFIED | FK to History.PriceDetectionDifferenceLog(NotificationLogID). Identifies which price anomaly event this secondary provider data belongs to. Part of the composite PK. The corresponding DifferenceLog row has the active provider, its price, instrument, severity, and timestamp. |
| 2 | ProviderID | int | NO | - | VERIFIED | ID of the secondary price feed provider whose price is stored in this row. This is a DIFFERENT provider from DifferenceLog.ActiveProviderID - it is one of the feeds the active provider was compared against. Part of the composite PK, enabling one row per (event, secondary provider). Implicit FK to provider lookup. |
| 3 | ProviderPrice | float | NO | - | VERIFIED | The price reported by this secondary provider at the time of the anomaly. The divergence between this price and DifferenceLog.ActiveProviderPrice is what triggered the alert. When ProviderPrice > ActiveProviderPrice: active feed is "Low" (alerts labelled "Low Price Problem"). When ProviderPrice < ActiveProviderPrice: active feed is "High" ("High Price Problem"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NotificationLogID | History.PriceDetectionDifferenceLog | FK (FK_PriceDetectionProviderDifferenceLog_PriceDetectionDifferenceLog) | The parent anomaly event this secondary price belongs to |
| ProviderID | Provider lookup | Implicit | The secondary feed provider whose price is recorded |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price detection service (external) | INSERT | WRITER | External application writes rows with each anomaly event |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PriceDetectionProviderDifferenceLog (table)
(leaf - no code-level dependencies)
```

FK dependency: History.PriceDetectionDifferenceLog (NotificationLogID).

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PriceDetectionDifferenceLog | Table | FK parent - the anomaly event this detail row extends |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Price detection service) | External | WRITER - not represented in SSDT |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PriceDetectionProviderDifferenceLog | CLUSTERED PK | NotificationLogID ASC, ProviderID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PriceDetectionProviderDifferenceLog_PriceDetectionDifferenceLog | FK | NotificationLogID -> History.PriceDetectionDifferenceLog(NotificationLogID) |

---

## 8. Sample Queries

### 8.1 Full price comparison for a specific anomaly event

```sql
SELECT
    pdl.NotificationLogID,
    pdl.InstrumentID,
    pdl.ActiveProviderID,
    pdl.ActiveProviderPrice AS ActivePrice,
    ppdl.ProviderID AS SecondaryProviderID,
    ppdl.ProviderPrice AS SecondaryPrice,
    ppdl.ProviderPrice - pdl.ActiveProviderPrice AS Divergence,
    pdl.Occurred
FROM History.PriceDetectionDifferenceLog pdl WITH (NOLOCK)
JOIN History.PriceDetectionProviderDifferenceLog ppdl WITH (NOLOCK)
    ON ppdl.NotificationLogID = pdl.NotificationLogID
WHERE pdl.NotificationLogID = @NotificationLogID
```

### 8.2 Recent anomalies with full comparison for an instrument

```sql
SELECT
    pdl.NotificationLogID,
    pdl.ActiveProviderID,
    pdl.ActiveProviderPrice,
    ppdl.ProviderID AS SecondaryProviderID,
    ppdl.ProviderPrice,
    ABS(ppdl.ProviderPrice - pdl.ActiveProviderPrice) AS AbsDivergence,
    pdl.Occurred
FROM History.PriceDetectionDifferenceLog pdl WITH (NOLOCK)
JOIN History.PriceDetectionProviderDifferenceLog ppdl WITH (NOLOCK)
    ON ppdl.NotificationLogID = pdl.NotificationLogID
WHERE pdl.InstrumentID = @InstrumentID
  AND pdl.Occurred >= DATEADD(HOUR, -24, GETDATE())
ORDER BY pdl.Occurred DESC
```

### 8.3 Secondary provider involvement frequency

```sql
SELECT
    ProviderID,
    COUNT(*) AS TimesInAnomaly,
    AVG(ProviderPrice) AS AvgPrice
FROM History.PriceDetectionProviderDifferenceLog WITH (NOLOCK)
GROUP BY ProviderID
ORDER BY TimesInAnomaly DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PriceDetectionProviderDifferenceLog | Type: Table | Source: etoro/etoro/History/Tables/History.PriceDetectionProviderDifferenceLog.sql*

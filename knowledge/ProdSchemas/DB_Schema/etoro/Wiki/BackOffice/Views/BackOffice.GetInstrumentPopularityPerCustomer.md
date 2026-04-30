# BackOffice.GetInstrumentPopularityPerCustomer

> Shows the chronological trading history of each customer by grouping their positions by open-date slot, concatenating the instruments traded in each slot, and ranking the slots from earliest to latest.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (CID, Place) - composite from GROUP BY + RANK |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetInstrumentPopularityPerCustomer` aggregates `History.GetPositionInfo` to produce a chronological timeline of which instruments each customer traded. For each distinct (CID, InitDateTime) combination, it uses a CLR aggregate function (`CLR.Concatenate`) to concatenate the names of all instruments opened at that timestamp, and assigns a chronological rank (`Place`) per customer where Place=1 is the customer's earliest recorded trading activity.

This view answers the question: "Which instruments did a given customer trade at each point in their trading history, ordered by when they first traded them?" It is used upstream by `BackOffice.JUNK_GetCustomerAggregations` to build a broader customer activity profile.

The view relies on `History.GetPositionInfo` from a cross-schema source (which accesses the EtoroArchive database). The `CLR.Concatenate` function is a CLR aggregate that joins multiple string values into a comma-separated list within a GROUP BY clause - producing a single string like `"AAPL,GOOG,BTC"` for all instruments opened at the same timestamp by the same customer.

---

## 2. Business Logic

### 2.1 Chronological Instrument Slot Ranking

**What**: Each (CID, InitDateTime) pair defines a "slot" - a moment when a customer opened one or more positions. All instrument names within a slot are concatenated. Slots are ranked 1, 2, 3... for each customer by ascending InitDateTime.

**Columns/Parameters Involved**: `CID`, `Instruments`, `Place`

**Rules**:
- GROUP BY (CID, InitDateTime) - a single customer can have multiple rows if they opened positions at different times
- `CLR.Concatenate(InstrumentName)` - aggregates all instrument names in the same (CID, InitDateTime) bucket into a comma-separated string
- `RANK() OVER (PARTITION BY CID ORDER BY InitDateTime ASC)` - Place=1 is the earliest activity, Place=N is the most recent
- Ties in InitDateTime within the same CID receive the same Place (RANK, not DENSE_RANK)

**Diagram**:
```
Customer CID=12345:
  InitDateTime=2021-01-05  -->  Instruments="BTC,ETH"      -->  Place=1  (earliest)
  InitDateTime=2021-03-15  -->  Instruments="AAPL"         -->  Place=2
  InitDateTime=2022-07-01  -->  Instruments="TSLA,GOOG,S&P" --> Place=3  (latest)
```

---

## 3. Data Overview

*Live data not available - History.GetPositionInfo references EtoroArchive database which is not accessible in current environment.*

| CID | Instruments | Place | Meaning |
|-----|-------------|-------|---------|
| (example) | "BTC,ETH" | 1 | The first time this customer opened positions, they traded Bitcoin and Ethereum simultaneously |
| (example) | "AAPL" | 2 | Their second trading session was in Apple stock only |
| (example) | "TSLA,GOOG" | 3 | In their third session they opened positions in Tesla and Alphabet |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | (inherited from History.GetPositionInfo) | - | - | CODE-BACKED | Customer identifier. Groups all trading activity for a single eToro account. Partitions the RANK() window - each customer gets their own independent chronological sequence. |
| 2 | Instruments | NVARCHAR (CLR aggregate result) | YES | - | CODE-BACKED | Comma-separated list of instrument names opened by this customer at the corresponding InitDateTime. Produced by `CLR.Concatenate(InstrumentName)` - a CLR aggregate function that concatenates strings within a GROUP BY group. Example: "BTC,ETH,AAPL". |
| 3 | Place | INT (RANK result) | NO | - | CODE-BACKED | Chronological rank of this trading slot within the customer's history. Place=1 = the earliest InitDateTime group, Place=2 = the second earliest, etc. Computed as `RANK() OVER (PARTITION BY CID ORDER BY InitDateTime ASC)`. Ties (same CID + same InitDateTime) receive the same rank with a gap after. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, InstrumentName | History.GetPositionInfo | JOIN (single source) | All data originates from this cross-schema view/function in the History schema. References EtoroArchive database. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.JUNK_GetCustomerAggregations | BackOffice.GetInstrumentPopularityPerCustomer AS BISP | JOIN | Used as a data source in the legacy aggregations view to include instrument popularity data in a broader customer profile. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetInstrumentPopularityPerCustomer (view)
└── History.GetPositionInfo (cross-schema view/function - EtoroArchive)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.GetPositionInfo | Cross-schema View/Function | FROM clause - sole data source. Provides CID, InstrumentName, and InitDateTime columns. Accesses EtoroArchive database. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.JUNK_GetCustomerAggregations | View | JOINs this view as alias BISP to include instrument timeline in customer aggregations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get instrument timeline for a specific customer

```sql
SELECT CID, Place, Instruments
FROM BackOffice.GetInstrumentPopularityPerCustomer WITH (NOLOCK)
WHERE CID = 123456
ORDER BY Place ASC
```

### 8.2 Find customers whose first traded instrument (Place=1) included BTC

```sql
SELECT CID, Instruments
FROM BackOffice.GetInstrumentPopularityPerCustomer WITH (NOLOCK)
WHERE Place = 1
  AND Instruments LIKE '%BTC%'
```

### 8.3 Count how many distinct trading sessions each customer had

```sql
SELECT CID, MAX(Place) AS TradingSessionCount
FROM BackOffice.GetInstrumentPopularityPerCustomer WITH (NOLOCK)
GROUP BY CID
ORDER BY TradingSessionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7 (Phase 2 blocked - EtoroArchive access)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetInstrumentPopularityPerCustomer | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetInstrumentPopularityPerCustomer.sql*

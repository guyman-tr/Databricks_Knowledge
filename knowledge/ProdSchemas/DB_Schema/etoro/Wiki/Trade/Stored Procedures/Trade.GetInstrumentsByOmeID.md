# Trade.GetInstrumentsByOmeID

> Returns all instrument IDs assigned to a specific Order Matching Engine (OME) instance, enabling OME processes to discover their instrument workload.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID filtered by OME instance number |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsByOmeID is a getter procedure that returns all instruments assigned to a specific Order Matching Engine (OME) instance. The eToro platform runs multiple OME instances, each responsible for matching orders on a subset of instruments. Trade.InstrumentsOmeID maps each instrument to its OME instance, and this procedure retrieves that mapping filtered by instance number.

This procedure exists because each OME process needs to know which instruments it is responsible for at startup. The OME engine calls this procedure with its own instance number to discover its instrument set, then loads order books and begins matching for those instruments only.

The procedure reads from Trade.InstrumentsOmeID (a view) filtered by OMEID. It hardcodes InstrumentTypeID as -1 in the output, indicating the actual instrument type is not resolved here - callers obtain type information separately.

---

## 2. Business Logic

### 2.1 OME Instance-to-Instrument Assignment

**What**: Maps OME engine instances to their assigned instruments for workload partitioning.

**Columns/Parameters Involved**: `@InstanceNumber`, `Trade.InstrumentsOmeID.OMEID`, `Trade.InstrumentsOmeID.InstrumentID`

**Rules**:
- Each instrument is assigned to exactly one OME instance (OMEID)
- @InstanceNumber identifies the calling OME process
- The returned InstrumentTypeID is hardcoded to -1 (sentinel value) - actual type information is not part of this lookup
- No validation on @InstanceNumber; a non-existent OMEID returns an empty result set

**Diagram**:
```
OME Instance 1       OME Instance 2       OME Instance 3
+-----------+        +-----------+        +-----------+
| EURUSD    |        | AAPL      |        | BTC       |
| GBPUSD    |        | MSFT      |        | ETH       |
| USDJPY    |        | GOOGL     |        | XRP       |
+-----------+        +-----------+        +-----------+

GetInstrumentsByOmeID(@InstanceNumber=2) -> AAPL, MSFT, GOOGL
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstanceNumber | int | NO | - | CODE-BACKED | The OME instance number to look up. Each OME process has a unique instance ID. Matched against Trade.InstrumentsOmeID.OMEID to retrieve that instance's instrument assignments. |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.InstrumentsOmeID.InstrumentID | CODE-BACKED | Instrument assigned to this OME instance. FK to Trade.Instrument. The OME loads order books for these instruments. |
| R2 | InstrumentTypeID | int | Hardcoded -1 | CODE-BACKED | Always returns -1 (sentinel). The actual instrument type is not resolved by this procedure - callers look it up separately from Trade.Instrument or ProviderToInstrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.InstrumentsOmeID | Read (SELECT) | View mapping instruments to OME instances; filtered by OMEID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| OME Engine | (application) | Consumer | OME processes call this at startup to discover their instrument workload |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsByOmeID (procedure)
+-- Trade.InstrumentsOmeID (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentsOmeID | View | SELECT WHERE OMEID = @InstanceNumber - source of instrument-to-OME mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| OME Engine instances | Application | Call at startup to load their instrument set for order matching |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No validation on @InstanceNumber.

---

## 8. Sample Queries

### 8.1 Get instruments for OME instance 1

```sql
EXEC Trade.GetInstrumentsByOmeID @InstanceNumber = 1;
```

### 8.2 View all OME instance assignments

```sql
SELECT  OMEID,
        InstrumentID
FROM    Trade.InstrumentsOmeID WITH (NOLOCK)
ORDER BY OMEID, InstrumentID;
```

### 8.3 Count instruments per OME instance

```sql
SELECT  OMEID,
        COUNT(*) AS InstrumentCount
FROM    Trade.InstrumentsOmeID WITH (NOLOCK)
GROUP BY OMEID
ORDER BY OMEID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsByOmeID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsByOmeID.sql*

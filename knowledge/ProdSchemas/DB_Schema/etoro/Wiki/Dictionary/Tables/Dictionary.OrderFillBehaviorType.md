# Dictionary.OrderFillBehaviorType

> Lookup table defining order fill behavior strategies — BestEffort (partial fills allowed) vs FillOrKill (all-or-nothing execution) — for instrument trading configuration.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OrderFillBehaviorTypeID (TINYINT, no PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 0 active (no PK, no indexes) |

---

## 1. Business Meaning

Dictionary.OrderFillBehaviorType defines the two order fill strategies available for instrument trading on the eToro platform. Each instrument can be configured with a fill behavior that determines whether partial order fills are acceptable or whether the entire order must execute in full or be rejected.

This table exists because different financial instruments and trading scenarios require different fill semantics. Highly liquid instruments may use BestEffort to maximize execution, while illiquid or block-trade instruments may require FillOrKill to prevent partial fills that could leave a position in an undesirable state.

The OrderFillBehaviorTypeID is stored per instrument in Trade.ProviderToInstrument and referenced during instrument configuration by procedures like Trade.InsertInstrumentRealTable, Trade.InsertInstrumentTradingData, Trade.CheckValidInstruments, and Trade.GetInstrumentDataForAPI. The value flows from instrument setup into execution logic.

---

## 2. Business Logic

### 2.1 Fill Strategy Selection

**What**: Two mutually exclusive strategies control whether partial order fills are permitted for an instrument.

**Columns/Parameters Involved**: `OrderFillBehaviorTypeID`, `OrderFillBehaviorTypeName`

**Rules**:
- **BestEffort (0)** — The execution engine attempts to fill as much of the order as possible at the requested price. Partial fills are accepted. This is the standard mode for most liquid instruments.
- **FillOrKill (1)** — The order must be filled in its entirety or not at all. If the full quantity cannot be executed immediately, the entire order is rejected. Used for instruments or scenarios where partial fills are unacceptable.
- The fill behavior is configured per instrument in Trade.ProviderToInstrument and inherited by History.TradeProviderToInstrument for audit purposes.

**Diagram**:
```
Order Submitted
      │
      ├── BestEffort (0)              FillOrKill (1)
      │     │                              │
      │     ▼                              ▼
      │   Can fill partial?          Can fill ALL?
      │     │                              │
      │   YES → Fill what's          YES → Fill entire order
      │          available            NO  → Reject entire order
      │   NO  → Reject
```

---

## 3. Data Overview

| OrderFillBehaviorTypeID | OrderFillBehaviorTypeName | Meaning |
|---|---|---|
| 0 | BestEffort | Default fill strategy — the execution engine fills as much as possible, accepting partial fills. Used for most liquid instruments where getting some execution is preferable to none. |
| 1 | FillOrKill | All-or-nothing fill strategy — the order must execute in full or is entirely rejected. Used for instruments or trading scenarios where partial positions are operationally problematic. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderFillBehaviorTypeID | tinyint | NO | - | VERIFIED | Identifier for the fill behavior strategy. 0=BestEffort (partial fills allowed), 1=FillOrKill (all-or-nothing). Referenced by Trade.ProviderToInstrument per instrument and used in Trade.InsertInstrumentRealTable, Trade.CheckValidInstruments, and Trade.GetInstrumentDataForAPI. |
| 2 | OrderFillBehaviorTypeName | char(50) | NO | - | VERIFIED | Display name of the fill behavior. Fixed-width CHAR(50) padded with spaces. "BestEffort" = partial fills OK, "FillOrKill" = complete fill or reject. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | OrderFillBehaviorTypeID | Implicit | Stores the fill behavior configured for each instrument-provider combination |
| History.TradeProviderToInstrument | OrderFillBehaviorTypeID | Implicit | Historical audit of instrument fill behavior settings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Stores OrderFillBehaviorTypeID per instrument |
| History.TradeProviderToInstrument | Table | Historical copy of instrument configuration |
| Trade.InsertInstrumentRealTable | Stored Procedure | Writer — sets fill behavior during instrument creation |
| Trade.InsertInstrumentTradingData | Stored Procedure | Writer — sets fill behavior during trading data setup |
| Trade.CheckValidInstruments | Stored Procedure | Reader — validates instrument configuration including fill behavior |
| Trade.GetInstrumentDataForAPI | Stored Procedure | Reader — returns fill behavior in API instrument data |
| Trade.GetInstrumentDataForAPITest | Stored Procedure | Reader — test variant of API instrument data |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Table has no primary key constraint.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all fill behavior types
```sql
SELECT  OrderFillBehaviorTypeID,
        RTRIM(OrderFillBehaviorTypeName) AS OrderFillBehaviorTypeName
FROM    [Dictionary].[OrderFillBehaviorType] WITH (NOLOCK)
ORDER BY OrderFillBehaviorTypeID;
```

### 8.2 Find instruments using FillOrKill behavior
```sql
SELECT  pti.InstrumentID,
        RTRIM(fb.OrderFillBehaviorTypeName) AS FillBehavior
FROM    [Trade].[ProviderToInstrument] pti WITH (NOLOCK)
JOIN    [Dictionary].[OrderFillBehaviorType] fb WITH (NOLOCK)
        ON pti.OrderFillBehaviorTypeID = fb.OrderFillBehaviorTypeID
WHERE   fb.OrderFillBehaviorTypeID = 1;
```

### 8.3 Count instruments by fill behavior type
```sql
SELECT  RTRIM(fb.OrderFillBehaviorTypeName) AS FillBehavior,
        COUNT(*) AS InstrumentCount
FROM    [Trade].[ProviderToInstrument] pti WITH (NOLOCK)
JOIN    [Dictionary].[OrderFillBehaviorType] fb WITH (NOLOCK)
        ON pti.OrderFillBehaviorTypeID = fb.OrderFillBehaviorTypeID
GROUP BY fb.OrderFillBehaviorTypeName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrderFillBehaviorType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrderFillBehaviorType.sql*

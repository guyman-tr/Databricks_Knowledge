# Price.UpdateActiveOMPDThresholdByInstrumentId

> Switches the active OMPD threshold type (Pips or Percentage) for a specific instrument in Price.OMPDActiveThreshold, and returns the updated configuration record.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Price.OMPDActiveThreshold WHERE InstrumentID; returns (InstrumentId, ThresholdType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.UpdateActiveOMPDThresholdByInstrumentId changes which OMPD (Order Management Price Deviation) threshold enforcement mode is active for an instrument. OMPD is a price protection system that rejects or flags orders when the market price has moved beyond a tolerance threshold from the order-creation price. Each instrument can be configured with two threshold types - Pips (type=1) or Percentage (type=2) - and this procedure switches the "selector switch" (`OMPDActiveThreshold.ThresholdType`) from one to the other.

When called, it validates that the instrument already has an active threshold record (raises an error if not found). It then updates the ThresholdType and returns the post-update state. This is a pure type-switch: it does not touch the actual threshold values stored in `Price.OMPDThresholdValues`; both threshold values remain intact. Switching from Pips to Percentage simply tells the order system to apply the Percentage value from that point forward.

This procedure is the partner to `Price.CreateActiveOMPDThresholdByInstrumentId` (which inserts the first active threshold record for a new instrument) and `Price.UpdateInstrumentOMPDThresholdByInstrumentId` (which updates the numeric value, not the active type).

---

## 2. Business Logic

### 2.1 Active Threshold Type Switch

**What**: Updates ThresholdType for an existing InstrumentID in OMPDActiveThreshold. Raises an error if the instrument has no active threshold record.

**Columns/Parameters Involved**: `@InstrumentID`, `@ThresholdType`

**Rules**:
- UPDATE Price.OMPDActiveThreshold SET ThresholdType = @ThresholdType WHERE InstrumentID = @InstrumentID
- IF @@ROWCOUNT = 0 after UPDATE -> RAISERROR ('Not Found. No active threshold found for the specified InstrumentID.', 16, 1)
- No validation that @ThresholdType exists in Dictionary.OMPDThresholdType (contrast with UpdateInstrumentOMPDThresholdByInstrumentId which does validate)
- Returns: SELECT InstrumentID AS InstrumentId, ThresholdType FROM OMPDActiveThreshold WHERE InstrumentID = @InstrumentID

**Threshold type values** (from Dictionary.OMPDThresholdType, inherited from Price.OMPDActiveThreshold doc):
- 1 = Pips: absolute price deviation in pip units (natural for forex instruments)
- 2 = Percentage: proportional price deviation as a percentage (natural for equities, crypto)

**Diagram**:
```
Price.OMPDActiveThreshold (selector)      Price.OMPDThresholdValues (value store)
InstrumentID=1, ThresholdType=1           InstrumentID=1, ThresholdType=1, Value=40 (Pips) <- ACTIVE
                                          InstrumentID=1, ThresholdType=2, Value=50 (%)    <- inactive

AFTER: UpdateActiveOMPDThresholdByInstrumentId(@InstrumentID=1, @ThresholdType=2)

InstrumentID=1, ThresholdType=2           InstrumentID=1, ThresholdType=1, Value=40 (Pips) <- now inactive
                                          InstrumentID=1, ThresholdType=2, Value=50 (%)    <- ACTIVE
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument whose active OMPD threshold type is being changed. Must already have a row in Price.OMPDActiveThreshold; raises error 'Not Found' if missing. FK logic aligns with OMPDActiveThreshold.InstrumentID -> Trade.InstrumentMetaData. |
| 2 | @ThresholdType | INT | NOT NULL | - | CODE-BACKED | The new active threshold type to set: 1=Pips, 2=Percentage. Written to OMPDActiveThreshold.ThresholdType. Note: no dictionary validation in this procedure - caller must pass a valid type (see Dictionary.OMPDThresholdType). |

**Return columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| R1 | InstrumentId | INT | CODE-BACKED | The instrument ID (aliased to InstrumentId in result). Same as @InstrumentID. |
| R2 | ThresholdType | INT | CODE-BACKED | The newly active threshold type (1=Pips, 2=Percentage) after the update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Price.OMPDActiveThreshold | MODIFIER | Updates ThresholdType for the matching InstrumentID row |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. Called externally by the OMPD configuration API or administration tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.UpdateActiveOMPDThresholdByInstrumentId (procedure)
└── Price.OMPDActiveThreshold (table - UPDATE target and SELECT return)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.OMPDActiveThreshold | Table | UPDATE target (ThresholdType); SELECT source for return value |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Not Found guard | Validation | @@ROWCOUNT = 0 after UPDATE raises error 16 - instrument must have an existing active threshold row |
| No type validation | Note | Unlike UpdateInstrumentOMPDThresholdByInstrumentId, this proc does NOT validate @ThresholdType against Dictionary.OMPDThresholdType. Caller responsibility. |
| Print artifact | Note | DDL file contains `print 'Price.UpdateInstrumentOMPDThresholdByInstrumentId.sql'` at end - a copy-paste artifact from the file used as template; has no runtime effect. |

---

## 8. Sample Queries

### 8.1 Switch instrument 1 from Pips to Percentage OMPD enforcement

```sql
EXEC Price.UpdateActiveOMPDThresholdByInstrumentId
    @InstrumentID = 1,
    @ThresholdType = 2;  -- 2 = Percentage
-- Returns: InstrumentId=1, ThresholdType=2
```

### 8.2 Switch back to Pips enforcement

```sql
EXEC Price.UpdateActiveOMPDThresholdByInstrumentId
    @InstrumentID = 1,
    @ThresholdType = 1;  -- 1 = Pips
```

### 8.3 Verify the active threshold type after switching

```sql
SELECT
    AT.InstrumentID,
    AT.ThresholdType,
    OTT.Name AS ActiveTypeName,
    TV.Value AS ActiveValue
FROM Price.OMPDActiveThreshold AT WITH (NOLOCK)
JOIN Dictionary.OMPDThresholdType OTT WITH (NOLOCK)
    ON OTT.ThresholdTypeID = AT.ThresholdType
JOIN Price.OMPDThresholdValues TV WITH (NOLOCK)
    ON TV.InstrumentID = AT.InstrumentID
    AND TV.ThresholdType = AT.ThresholdType
WHERE AT.InstrumentID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.UpdateActiveOMPDThresholdByInstrumentId | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.UpdateActiveOMPDThresholdByInstrumentId.sql*

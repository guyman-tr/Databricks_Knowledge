# Trade.Tv_ProviderMarginMarkupByInstrument

> TVP for bulk upsert of provider margin markup percentages by instrument - markup per provider-instrument pair.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int), ProviderID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Tv_ProviderMarginMarkupByInstrument carries provider-specific margin markup percentages per instrument. Each row defines InstrumentID, ProviderID, and MarkupPercentage - representing how much extra margin a given provider applies for a given instrument.

The type exists to support bulk configuration of margin markups. Admin or margin management procedures pass batches to Trade.UpsertProviderMarginMarkupByInstrument, which upserts the markup configuration.

The type flows from margin config services into Trade.UpsertProviderMarginMarkupByInstrument. The procedure JOINs the TVP against existing markup tables and INSERTs/UPDATEs as needed.

---

## 2. Business Logic

InstrumentID + ProviderID + MarkupPercentage triplet. Each row is one provider-instrument markup; the pair (InstrumentID, ProviderID) identifies the configuration.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier |
| 2 | ProviderID | int | NO | - | CODE-BACKED | Provider identifier |
| 3 | MarkupPercentage | decimal(10,2) | NO | - | CODE-BACKED | Margin markup percentage applied by this provider for this instrument |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpsertProviderMarginMarkupByInstrument | @ProviderMarginMarkupByInstrument | Parameter (TVP) | Upserts provider margin markup by instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpsertProviderMarginMarkupByInstrument | Stored Procedure | READONLY parameter for margin markup upsert |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and upsert single provider-instrument
```sql
DECLARE @ProviderMarginMarkupByInstrument Trade.Tv_ProviderMarginMarkupByInstrument;
INSERT INTO @ProviderMarginMarkupByInstrument (InstrumentID, ProviderID, MarkupPercentage)
VALUES (12345, 1, 2.50);
EXEC Trade.UpsertProviderMarginMarkupByInstrument @ProviderMarginMarkupByInstrument = @ProviderMarginMarkupByInstrument;
```

### 8.2 Batch upsert multiple provider-instruments
```sql
DECLARE @ProviderMarginMarkupByInstrument Trade.Tv_ProviderMarginMarkupByInstrument;
INSERT INTO @ProviderMarginMarkupByInstrument (InstrumentID, ProviderID, MarkupPercentage)
VALUES (100, 1, 1.50), (100, 2, 2.00), (101, 1, 3.25);
EXEC Trade.UpsertProviderMarginMarkupByInstrument @ProviderMarginMarkupByInstrument = @ProviderMarginMarkupByInstrument;
```

### 8.3 Build from existing table
```sql
DECLARE @ProviderMarginMarkupByInstrument Trade.Tv_ProviderMarginMarkupByInstrument;
INSERT INTO @ProviderMarginMarkupByInstrument (InstrumentID, ProviderID, MarkupPercentage)
SELECT InstrumentID, ProviderID, MarkupPercentage FROM Staging.ProviderMarginMarkup;
EXEC Trade.UpsertProviderMarginMarkupByInstrument @ProviderMarginMarkupByInstrument = @ProviderMarginMarkupByInstrument;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Tv_ProviderMarginMarkupByInstrument | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Tv_ProviderMarginMarkupByInstrument.sql*

# Hedge.GetReferenceCustomerOpenPositions_SS

> Functionally identical to Hedge.GetReferenceCustomerOpenPositions_NewData - returns the most recent customer open position snapshot per (HedgeServerID, InstrumentID) from CustomerOpenPositions_New using the same STRING_SPLIT and temp table approach.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartReferenceDate + @EndReferenceDate + @HedgeServerIDs - date window and server filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetReferenceCustomerOpenPositions_SS` is byte-for-byte identical to `Hedge.GetReferenceCustomerOpenPositions_NewData`. Both procedures perform the same logic: parse @HedgeServerIDs via STRING_SPLIT, find MAX(OccurredAt) per (HedgeServerID, InstrumentID) from `Hedge.CustomerOpenPositions_New`, then retrieve the full snapshot rows at those timestamps.

The `_SS` suffix meaning is not documented in the DDL. The most likely interpretations are "Same Store" (a reporting context distinction), "Server-Side" (indicating server-side processing vs. client-side aggregation), or simply a sequential naming artifact when the procedure was forked from `_NewData` without functional changes.

Both procedures exist as separate objects to allow different callers to reference them independently - if one procedure needs to be modified in the future, the other is not affected. In the current state, any change to one should be applied to the other to maintain consistency.

For full business meaning, logic, and column descriptions, see [Hedge.GetReferenceCustomerOpenPositions_NewData](Hedge.GetReferenceCustomerOpenPositions_NewData.md).

---

## 2. Business Logic

Identical to `Hedge.GetReferenceCustomerOpenPositions_NewData`. See that procedure's documentation for the full two-pass MAX(OccurredAt) logic and STRING_SPLIT pattern.

### Key points (summary):
- STRING_SPLIT(@HedgeServerIDs, ',') -> #HedgeServers temp table
- MAX(OccurredAt) per (HedgeServerID, InstrumentID) -> #HedgeServersInstruments temp table
- INNER JOIN back to CustomerOpenPositions_New on (HedgeServerID, InstrumentID, OccurredAt)
- Per-instrument snapshot granularity (each instrument has its own most-recent timestamp)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*(Identical to Hedge.GetReferenceCustomerOpenPositions_NewData)*

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartReferenceDate | datetime | NO | - | VERIFIED | Start of reference date window. See GetReferenceCustomerOpenPositions_NewData. |
| 2 | @EndReferenceDate | datetime | NO | - | VERIFIED | End of reference date window. See GetReferenceCustomerOpenPositions_NewData. |
| 3 | @HedgeServerIDs | varchar(4000) | NO | - | VERIFIED | Comma-separated HedgeServerIDs; parsed via STRING_SPLIT. See GetReferenceCustomerOpenPositions_NewData. |

**Output columns** (identical to GetReferenceCustomerOpenPositions_NewData):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | HedgeServerID | int | NO | - | VERIFIED | Hedge server identifier. |
| 5 | InstrumentID | int | NO | - | VERIFIED | Financial instrument - per-instrument most-recent snapshot. |
| 6 | OccurredAt | datetime | NO | - | VERIFIED | Most recent snapshot timestamp for this (HedgeServerID, InstrumentID) in the date window. |
| 7 | UnrealizedPL | decimal | YES | - | VERIFIED | Actual unrealized customer P&L for this instrument. |
| 8 | CommissionOnOpen | decimal | YES | - | VERIFIED | Commission collected on customer open positions. |
| 9 | UnrealizedZeroPL | decimal | YES | - | VERIFIED | Theoretical unrealized P&L (no spread/swap); hedge cost baseline. |
| 10 | OpenedUnits | decimal | YES | - | VERIFIED | Total customer open position units in eToro denomination. |
| 11 | PriceRateID | int | YES | - | VERIFIED | Reference price snapshot ID for valuation. |
| 12 | NetOpenInUSD | decimal | YES | - | VERIFIED | Net USD value of customer open positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.CustomerOpenPositions_New | SELECT | Same source as GetReferenceCustomerOpenPositions_NewData. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge reporting / reconciliation | - | Caller | Different caller reference than _NewData but same functional output. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetReferenceCustomerOpenPositions_SS (procedure)
└── Hedge.CustomerOpenPositions_New (table)
      - Same source as Hedge.GetReferenceCustomerOpenPositions_NewData
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerOpenPositions_New | Table | Two-pass SELECT - MAX(OccurredAt) then full row fetch. Identical to _NewData variant. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge reporting application | External | READER - separate named entry point for the same customer open positions reference data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Identical implementation to _NewData. Same temp table creation pattern.

### 7.2 Constraints

N/A for Stored Procedure. The `_SS` and `_NewData` procedures are byte-for-byte identical. Both are active and may be referenced by different callers. Any future schema or logic change must be applied to both procedures simultaneously to maintain consistency. A code review recommendation would be to consolidate these into a single procedure and update callers.

---

## 8. Sample Queries

### 8.1 Get customer reference open positions (_SS version)
```sql
EXEC [Hedge].[GetReferenceCustomerOpenPositions_SS]
    @StartReferenceDate = '2026-03-18 00:00:00',
    @EndReferenceDate   = '2026-03-18 23:59:59',
    @HedgeServerIDs     = '1,2,3';
```

### 8.2 Verify identical output to _NewData
```sql
-- Both should return identical results for the same parameters:
EXEC [Hedge].[GetReferenceCustomerOpenPositions_NewData]
    @StartReferenceDate = '2026-03-18', @EndReferenceDate = '2026-03-19', @HedgeServerIDs = '1';

EXEC [Hedge].[GetReferenceCustomerOpenPositions_SS]
    @StartReferenceDate = '2026-03-18', @EndReferenceDate = '2026-03-19', @HedgeServerIDs = '1';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetReferenceCustomerOpenPositions_SS | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetReferenceCustomerOpenPositions_SS.sql*

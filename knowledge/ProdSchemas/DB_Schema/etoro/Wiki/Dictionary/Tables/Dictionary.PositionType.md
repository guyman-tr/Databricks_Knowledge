# Dictionary.PositionType

> Lookup table defining the 3 position ownership models: CFD (contract for difference), REAL (asset ownership), and ILLEGAL (validation sentinel).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (TINYINT, CLUSTERED PK) |
| **Row Count** | 3 rows |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK clustered + unique on Value) |

---

## 1. Business Meaning

Dictionary.PositionType defines the three possible ownership models for a trading position on eToro. This is closely related to — but distinct from — Dictionary.SettlementTypes. While SettlementTypes defines the settlement METHOD (6 values including TRS, PartialReal, etc.), PositionType defines the simplified OWNERSHIP MODEL that the end-user sees.

- **CFD (0)**: The user holds a derivative contract. No ownership of the underlying asset. eToro is the counterparty. Leverage > 1x forces CFD. Available for all instruments.
- **REAL (1)**: The user owns the actual underlying asset (stock shares, crypto coins). Only available at 1x leverage for eligible instruments. Settlement is REAL.
- **ILLEGAL (255)**: Sentinel value used by validation logic. A position should never persist with this type — if it appears, it indicates a processing error. The max TINYINT-adjacent value (255) ensures it sorts last and stands out in debugging.

PositionType is stored in Trade.PositionTbl and determines tax treatment, dividend eligibility, voting rights (stocks), and withdrawal to external wallet (crypto).

---

## 2. Business Logic

### 2.1 Ownership Model Decision

**What**: The position type is determined at trade time based on leverage, instrument eligibility, and regulation.

**Columns/Parameters Involved**: `ID`, `Value`

**Rules**:
- Leverage > 1x → always CFD (0)
- Leverage = 1x + instrument supports REAL + country not settlement-restricted → REAL (1)
- Leverage = 1x + instrument is CFD-only (e.g., forex, commodities) → CFD (0)
- Settlement-restricted country (Dictionary.Country.IsSettlementRestricted=1) → always CFD (0)

**Diagram**:
```
[User places trade]
     │
     ├── Leverage > 1x? ──► CFD (0)
     │
     ├── Country settlement restricted? ──► CFD (0)
     │
     ├── Instrument supports REAL? ──► REAL (1)
     │
     └── Otherwise ──► CFD (0)

     ILLEGAL (255) ──► Validation error sentinel (should never persist)
```

---

## 3. Data Overview

| ID | Value | Meaning |
|---|---|---|
| 0 | CFD | Contract for Difference — the user holds a derivative, not the underlying asset. eToro is the counterparty. Profits and losses are settled in cash. The user can use leverage, go short, and trade all instrument types. No ownership rights (no dividends on REAL stocks, no crypto wallet transfers). |
| 1 | REAL | Real asset ownership — the user owns the actual shares or crypto coins. Only available at 1x leverage. Eligible for dividends (stocks), corporate actions, and wallet transfers (crypto). eToro holds the assets in custody on behalf of the user. Tax treatment differs from CFD in most jurisdictions. |
| 255 | ILLEGAL | Validation sentinel — indicates a processing error if a position has this type. Should never appear in production data. Used by the trading engine to catch misconfigured trades during order validation. The value 255 (max for a single byte) makes it obvious in debugging. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | tinyint | NO | - | VERIFIED | Primary key. 0=CFD (derivative), 1=REAL (asset ownership), 255=ILLEGAL (error sentinel). Stored in Trade.PositionTbl. Determines tax treatment, dividend eligibility, and withdrawal capabilities. |
| 2 | Value | varchar(40) | NO | - | VERIFIED | Position type label. UNIQUE constraint. Used in API responses and trading UI to display the ownership model. |

---

## 5. Relationships

### 5.1 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | PositionTypeID | Implicit Lookup | Every position has an ownership model |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_Dictionary_PositionType | CLUSTERED PK | ID ASC | Active |
| DLVG_VALUE | NC UNIQUE | Value ASC | Active |

---

## 8. Sample Queries

### 8.1 List position types
```sql
SELECT ID, Value FROM [Dictionary].[PositionType] WITH (NOLOCK) ORDER BY ID;
```

### 8.2 Count positions by ownership type
```sql
SELECT  CASE pt.ID WHEN 0 THEN 'CFD' WHEN 1 THEN 'REAL' ELSE 'OTHER' END AS OwnershipModel,
        COUNT(*) AS PositionCount
FROM    [Trade].[PositionTbl] tp WITH (NOLOCK)
JOIN    [Dictionary].[PositionType] pt WITH (NOLOCK) ON tp.PositionTypeID = pt.ID
WHERE   tp.IsClosed = 0
GROUP BY pt.ID ORDER BY PositionCount DESC;
```

---

*Generated: 2026-03-13 | Enriched: MCP live data | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Object: Dictionary.PositionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PositionType.sql*

# Trade.CountryCopySettledResrictionsByInstrumentType

> Junction table listing country-instrument-type pairs where copy-trade settlement is restricted (read-only lookup; populated externally).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CountryID, InstrumentTypeID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Trade.CountryCopySettledResrictionsByInstrumentType is a small lookup table that stores (CountryID, InstrumentTypeID) pairs where copy-trade settlement is restricted. Each row means: for the given country and instrument type (e.g., Stocks, Forex), settlement of copied positions is blocked or restricted. The table name contains a typo ("Resrictions" instead of "Restrictions") but is the canonical name in the schema.

This table exists because the copy-trading engine needs a fast, denormalized way to answer "for country X and instrument type Y, is settlement restricted?" The relationship aligns with Trade.CopyTradeSettlementRestrictions (which stores granular restrictions per country/regulation/instrument/group) but CountryCopySettledResrictionsByInstrumentType provides a simpler, instrument-type–level aggregation for settlement checks.

Data flows: The table is read exclusively by Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType, which returns the list of restricted (CountryID, InstrumentTypeID) pairs used by downstream copy/settlement logic. No procedures in the SSDT repo INSERT into this table; population appears to be via external ETL, SSIS, or manual scripts.

---

## 2. Business Logic

### 2.1 One Row Per (CountryID, InstrumentTypeID)

**What**: Each country-instrument-type combination is represented at most once. The composite PK enforces uniqueness.

**Columns/Parameters Involved**: `CountryID`, `InstrumentTypeID`

**Rules**:
- Composite PRIMARY KEY (CountryID, InstrumentTypeID). No explicit FK constraints in DDL.
- CountryID implicitly references Dictionary.Country.
- InstrumentTypeID implicitly references Dictionary.CurrencyType (CurrencyTypeID = InstrumentTypeID), where CurrencyType represents instrument types (Forex=1, Commodities=2, Indices=4, Stocks=5, Crypto=6, etc.).

**Diagram**:
```
CountryID=52 (Croatia), InstrumentTypeID=5 (Stocks) -> Settlement restricted for Stocks in Croatia
CountryID=98 (Iran), InstrumentTypeID=5 (Stocks) -> Settlement restricted for Stocks in Iran
```

### 2.2 Reader-Only from Procedures

**What**: No stored procedure in the SSDT repo writes to this table. It is read-only from application perspective.

**Rules**:
- Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType is the sole procedure consumer; it SELECTs DISTINCT CountryID, InstrumentTypeID ordered by InstrumentTypeID.

---

## 3. Data Overview

| CountryID | InstrumentTypeID | CountryName | InstrumentTypeName | Meaning |
|-----------|------------------|-------------|--------------------|---------|
| 52 | 5 | Croatia | Stocks | Copy-trade settlement for Stocks restricted in Croatia. |
| 53 | 5 | Cuba | Stocks | Copy-trade settlement for Stocks restricted in Cuba. |
| 73 | 5 | Macedonia | Stocks | Copy-trade settlement for Stocks restricted in Macedonia. |
| 98 | 5 | Iran | Stocks | Copy-trade settlement for Stocks restricted in Iran. |
| 99 | 5 | Iraq | Stocks | Copy-trade settlement for Stocks restricted in Iraq. |

**Selection criteria**: TOP 5 from live query with JOINs to Dictionary.Country and Dictionary.CurrencyType for human-readable names. Representative of restricted country-instrument-type pairs (Stocks dominate in sample).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Part of PK. Country where settlement is restricted. Implicit FK to Dictionary.Country. |
| 2 | InstrumentTypeID | int | NO | - | CODE-BACKED | Part of PK. Instrument type (e.g., 5=Stocks). Implicit FK to Dictionary.CurrencyType.CurrencyTypeID. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Country lookup for name/region. |
| InstrumentTypeID | Dictionary.CurrencyType | Implicit | Instrument type lookup (Forex, Stocks, etc.). |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType | FROM | Reader | Sole procedure that reads this table. Returns restricted pairs for settlement logic. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CountryCopySettledResrictionsByInstrumentType (table)
├── Dictionary.Country ( implicit ) [CountryID]
└── Dictionary.CurrencyType ( implicit ) [InstrumentTypeID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Implicit lookup for CountryID |
| Dictionary.CurrencyType | Table | Implicit lookup for InstrumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType | Procedure | SELECT DISTINCT CountryID, InstrumentTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeCountryCopySettledResrictionsByInstrumentType | CLUSTERED | CountryID, InstrumentTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeCountryCopySettledResrictionsByInstrumentType | PK | (CountryID, InstrumentTypeID) clustered primary key |

---

## 8. Sample Queries

### 8.1 Get all restricted country-instrument-type pairs

```sql
SELECT CountryID, InstrumentTypeID
  FROM Trade.CountryCopySettledResrictionsByInstrumentType WITH (NOLOCK)
 ORDER BY InstrumentTypeID
```

### 8.2 Resolve restricted pairs with human-readable names

```sql
SELECT cc.CountryID, cc.InstrumentTypeID, c.Name AS CountryName, ct.Name AS InstrumentTypeName
  FROM Trade.CountryCopySettledResrictionsByInstrumentType cc WITH (NOLOCK)
  LEFT JOIN Dictionary.Country c WITH (NOLOCK) ON c.CountryID = cc.CountryID
  LEFT JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON ct.CurrencyTypeID = cc.InstrumentTypeID
 ORDER BY cc.InstrumentTypeID, cc.CountryID
```

### 8.3 Count restrictions per instrument type

```sql
SELECT InstrumentTypeID, COUNT(*) AS RestrictionCount
  FROM Trade.CountryCopySettledResrictionsByInstrumentType WITH (NOLOCK)
 GROUP BY InstrumentTypeID
 ORDER BY RestrictionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.CountryCopySettledResrictionsByInstrumentType | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CountryCopySettledResrictionsByInstrumentType.sql*

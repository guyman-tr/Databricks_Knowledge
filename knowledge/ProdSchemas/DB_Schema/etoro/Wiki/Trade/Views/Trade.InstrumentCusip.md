# Trade.InstrumentCusip

> Thin projection of Trade.InstrumentMetaData exposing InstrumentID, CUSIP (aliased from Cusip), and ISINCode for compliance and lookup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentCusip provides a minimal interface to regulatory identifiers (CUSIP and ISIN) per instrument. CUSIP (Committee on Uniform Securities Identification Procedures) is used primarily for US and Canadian securities; ISIN (International Securities Identification Number) is the global standard. This view exists to simplify lookups where only these identifiers are needed - for example SalesForce integration, Trade.CheckValidInstruments validation, or Trade.UpdateCusip bulk updates - without selecting the full InstrumentMetaData row.

Without this view, callers would SELECT InstrumentID, Cusip, ISINCode directly from InstrumentMetaData. The view adds the CUSIP alias (Cusip -> CUSIP) for consistency with external systems that expect uppercase CUSIP as the column name.

---

## 2. Business Logic

### 2.1 Regulatory Identifier Projection

**What**: Expose InstrumentID and the two main regulatory codes (CUSIP, ISIN) from InstrumentMetaData.

**Columns/Parameters Involved**: `InstrumentID`, `CUSIP`, `ISINCode`

**Rules**:
- Direct SELECT from Trade.InstrumentMetaData with no filters.
- CUSIP is an alias for the Cusip column (CUSIP = Cusip).
- ISINCode is passed through unchanged.
- Both CUSIP and ISINCode are nullable; stocks typically have ISIN, US/Canada securities may have CUSIP. Forex and crypto usually have NULL for both.

**Diagram**:
```
Trade.InstrumentMetaData
    |-- InstrumentID
    |-- Cusip -> aliased as CUSIP
    |-- ISINCode
    v
Trade.InstrumentCusip (InstrumentID, CUSIP, ISINCode)
```

---

## 3. Data Overview

| InstrumentID | CUSIP | ISINCode | Meaning |
|--------------|-------|----------|---------|
| 1 | aaa123 | ccc345 | Sample/test data with both codes |
| 2 | NULL | NULL | Forex or non-equity; no regulatory IDs |
| 3 | NULL | NULL | Same pattern |
| 4 | NULL | NULL | Same pattern |
| 5 | NULL | NULL | Same pattern |

**Selection criteria for the 5 rows:** TOP 5 from live query. InstrumentID 1 has both CUSIP and ISINCode (likely test data). InstrumentIDs 2-5 have NULL for both - typical for forex or instruments without regulatory identifiers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | PK of Trade.Instrument. Same as InstrumentMetaData.InstrumentID. Identifies the tradeable instrument. |
| 2 | CUSIP | varchar(255) | YES | - | CODE-BACKED | Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments. |
| 3 | ISINCode | varchar(30) | YES | - | CODE-BACKED | International Securities Identification Number. From InstrumentMetaData.ISINCode. Required for stocks in many jurisdictions. NULL for forex, crypto. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Via InstrumentMetaData.InstrumentID |

### 5.2 Base Tables (FROM)

| Table | How Used |
|-------|----------|
| Trade.InstrumentMetaData | Direct SELECT of InstrumentID, Cusip (as CUSIP), ISINCode |

### 5.3 Referenced By (other objects point to this)

| Source Object | Role | Description |
|---------------|------|-------------|
| SalesForce.GetInstruments | READER | LEFT JOIN Trade.InstrumentCusip TC for CUSIP/ISIN in instrument list |
| Trade.CheckValidInstruments | READER | UNION ALL includes SELECT TOP 1 1 FROM Trade.InstrumentCusip WHERE InstrumentID=@InstrumentID for validation |
| Trade.UpdateCusip | MODIFIER | Reads from Trade.InstrumentCusip (alias a) as part of CUSIP update logic |
| Trade.GetInstrumentCusip | Procedure | Different object - reads InstrumentMetaData directly; returns Cusip, SEDOL. Not a consumer of this view. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentCusip (view)
    |
    +-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - source of InstrumentID, Cusip, ISINCode |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SalesForce.GetInstruments | Procedure | LEFT JOIN for CUSIP/ISIN |
| Trade.CheckValidInstruments | Procedure | EXISTS-style validation |
| Trade.UpdateCusip | Procedure | FROM in update logic |

---

## 7. Technical Details

### 7.1 DDL Summary

- **Base table**: Trade.InstrumentMetaData
- **Logic**: SELECT InstrumentID, CUSIP = Cusip, ISINCode. No WHERE, no JOINs.
- **Output**: InstrumentID, CUSIP, ISINCode

### 7.2 Column Sources

| Output Column | Source Table | Source Column |
|---------------|--------------|---------------|
| InstrumentID | Trade.InstrumentMetaData | InstrumentID |
| CUSIP | Trade.InstrumentMetaData | Cusip (aliased) |
| ISINCode | Trade.InstrumentMetaData | ISINCode |

---

## 8. Sample Queries

### 8.1 Get CUSIP and ISIN for instruments
```sql
SELECT InstrumentID, CUSIP, ISINCode
FROM Trade.InstrumentCusip WITH (NOLOCK)
WHERE InstrumentID IN (1, 1001, 1002)
ORDER BY InstrumentID;
```

### 8.2 Instruments with CUSIP populated
```sql
SELECT InstrumentID, CUSIP, ISINCode
FROM Trade.InstrumentCusip WITH (NOLOCK)
WHERE CUSIP IS NOT NULL
ORDER BY InstrumentID;
```

### 8.3 Join with instrument metadata for full context
```sql
SELECT tc.InstrumentID, tc.CUSIP, tc.ISINCode,
       imd.InstrumentDisplayName, imd.SymbolFull
FROM Trade.InstrumentCusip tc WITH (NOLOCK)
JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON tc.InstrumentID = imd.InstrumentID
WHERE tc.ISINCode IS NOT NULL
ORDER BY tc.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentCusip | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentCusip.sql*

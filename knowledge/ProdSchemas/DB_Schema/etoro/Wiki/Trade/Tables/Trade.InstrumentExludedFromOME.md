# Trade.InstrumentExludedFromOME

> Exemption list of instruments that are excluded from OME (Order Matching Engine) routing. Instruments in this table bypass the normal OME distribution logic used in Trade.Instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, PK CLUSTERED) |
| **Row Count** | 0 (empty) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Trade.InstrumentExludedFromOME is a whitelist/exclusion table that identifies which instruments should **not** be routed to the Order Matching Engine (OME). Trade.Instrument assigns instruments to OMEID 2–5 for load balancing across multiple OME instances; instruments listed here are explicitly excluded from that distribution logic.

The table exists to support instruments that require special handling or are not suitable for standard OME order matching—for example, instruments under corporate actions (splits), instruments in maintenance, or instruments processed by alternate matching paths. By maintaining a separate exclusion list, the platform can keep OMEID/ShardID logic in Trade.Instrument intact while carving out specific instruments.

No stored procedures in the Trade schema reference this table in the codebase. Population and consumption may occur via application code, external services, or operational scripts outside the SSDT repo. The table is currently empty (0 rows).

---

## 2. Business Logic

### 2.1 OME Exclusion by InstrumentID

**What**: Instruments present in this table are excluded from OME routing.

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- Each row represents a single instrument excluded from OME
- InstrumentID must exist in Trade.Instrument (logical FK; no explicit constraint in DDL)
- Table is a simple keyed list—no additional attributes
- Empty table implies no instruments are currently excluded

**Diagram**:
```
Trade.Instrument (OMEID 2–5) ──► OME Servers
        │
        └── Trade.InstrumentExludedFromOME ──► Excluded (no OME routing)
```

---

## 3. Data Overview

| InstrumentID | Meaning |
|--------------|---------|
| *(no rows)* | Table is empty; no instruments are currently excluded from OME |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Instrument to exclude from OME routing. References Trade.Instrument.InstrumentID (logical) |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Column | Relationship |
|------------------|--------|--------------|
| Trade.Instrument | InstrumentID | Implicit; instruments in this table should exist in Trade.Instrument |

### 5.2 Referenced By

| Referencing Object | Column | Type |
|--------------------|--------|------|
| *(none found in Stored Procedures)* | - | - |

---

## 6. Dependencies

### 6.0 Chain

```
Trade.Instrument
    └── Trade.InstrumentExludedFromOME (exclusion list)
```

### 6.1 Depends On

| Object | Purpose |
|--------|---------|
| Trade.Instrument | InstrumentID domain; instruments listed here are defined there |

### 6.2 Depended On By

| Object | Purpose |
|--------|---------|
| *(no code references in SSDT)* | Application/external consumers may use this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included | Fill Factor | Status |
|------------|------|-------------|----------|-------------|--------|
| PK_TradeInstrumentExludedFromOME | CLUSTERED | InstrumentID ASC | - | default | Active |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_TradeInstrumentExludedFromOME | PRIMARY KEY | InstrumentID |

---

## 8. Sample Queries

```sql
SELECT COUNT(*) AS ExcludedCount
FROM Trade.InstrumentExludedFromOME WITH (NOLOCK);

SELECT ie.InstrumentID, i.InstrumentDisplayID
FROM Trade.InstrumentExludedFromOME ie WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = ie.InstrumentID;

SELECT *
FROM Trade.InstrumentExludedFromOME WITH (NOLOCK)
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

- No Jira/Confluence references found in this documentation pass.

---

*Generated: 2026-03-14 | Quality: 6.5/10 (Elements: 7/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*

# Customer.GetActiveInstruments

> Returns the distinct set of instruments a customer is currently trading manually (non-copy positions only, MirrorID=0), used by the recommendation engine to understand the customer's self-selected trading preferences.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to query) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetActiveInstruments returns the set of instruments a customer is actively trading under their own initiative. It queries Trade.PositionTbl filtered to manual positions only (MirrorID=0), returning each unique InstrumentID currently held open.

The procedure exists to feed the eToro recommendation engine (granted EXECUTE to `Recom_user` service role). By knowing which instruments a customer already trades manually, the recommendation engine can suggest correlated or complementary instruments while avoiding redundant recommendations for positions already held.

The MirrorID=0 filter is critical: it excludes copy-trading positions (MirrorID > 0 in Trade.PositionTbl indicates the position was opened as part of copying another trader). Copy-traded instruments reflect the copied trader's preferences, not the customer's own. For recommendation purposes, only the customer's self-directed choices are relevant signals.

---

## 2. Business Logic

### 2.1 Manual Position Instrument Set

**What**: Returns distinct InstrumentIDs from currently open positions the customer opened themselves.

**Columns/Parameters Involved**: `@CID`, `Trade.PositionTbl.InstrumentID`, `Trade.PositionTbl.MirrorID`, `Trade.PositionTbl.CID`

**Rules**:
- WHERE CID = @CID: filter to this customer
- WHERE MirrorID = 0: manual positions only (MirrorID = 0 means the customer opened this position directly; MirrorID > 0 means it was opened via copy-trading)
- SELECT DISTINCT InstrumentID: each instrument appears once regardless of how many open positions the customer has in it
- NOLOCK hint: read-only, non-blocking (stale reads acceptable for recommendation)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to query. Returns instruments for open positions where CID = @CID AND MirrorID = 0. |

**Result set:**

| Column | Type | Description |
|--------|------|-------------|
| InstrumentID | INT | Distinct instrument identifier from Trade.PositionTbl. Each row is a unique instrument the customer currently holds in a manually-opened position. Zero rows if customer has no manual open positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.PositionTbl | Read | Queries open positions filtered to manual (MirrorID=0) for this customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recom_user (service role) | GRANT EXECUTE | Caller | Recommendation engine service - uses instrument list to drive personalized suggestions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetActiveInstruments (procedure)
+-- Trade.PositionTbl (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of open positions; filtered by CID and MirrorID=0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recom_user service | External service | Queries active manual instrument set for recommendation logic |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MirrorID = 0 | Business filter | Excludes copy-trading positions (MirrorID > 0 = copy of another trader's position) |
| DISTINCT InstrumentID | Deduplication | One row per instrument regardless of position count |
| WITH (NOLOCK) | Hint | Non-blocking read; acceptable for recommendation latency requirements |

---

## 8. Sample Queries

### 8.1 Get active instruments for a customer

```sql
EXEC Customer.GetActiveInstruments @CID = 12345678
```

### 8.2 Equivalent direct query

```sql
SELECT DISTINCT InstrumentID
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE CID = 12345678
  AND MirrorID = 0
```

### 8.3 Count instruments per customer (recommendation analytics)

```sql
SELECT CID, COUNT(DISTINCT InstrumentID) AS ManualInstrumentCount
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE MirrorID = 0
GROUP BY CID
ORDER BY ManualInstrumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetActiveInstruments | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetActiveInstruments.sql*

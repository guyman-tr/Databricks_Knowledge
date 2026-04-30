# Trade.CM_UpdateLeveragesRestrictionsWhiteListTable

> A table-valued parameter type for batch-updating leverage restriction whitelist entries - specifying per-customer per-instrument leverage bounds (min, max, default) and optional comments for Compliance Manager (CM) operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | GCID, InstrumentID |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.CM_UpdateLeveragesRestrictionsWhiteListTable is a table-valued parameter (TVP) type used by Compliance Manager (CM) to batch-update leverage restriction whitelist entries. Regulation limits leverage by default; the whitelist lets compliance override those limits for specific customers on specific instruments when justified (e.g., professional status, jurisdiction exceptions).

Without this type, compliance would need to update whitelist entries one at a time. The TVP enables bulk updates from admin tools or batch jobs, specifying min, max, and default leverage plus optional audit comments per GCID-Instrument pair.

Application or job logic collects the whitelist changes, populates the TVP, and passes it to Trade.CM_UpdateLeveragesRestrictionsWhiteList. The procedure merges the rows into the leverage restriction whitelist table.

---

## 2. Business Logic

### 2.1 GCID-Instrument Leverage Bounds

**What**: Per-customer per-instrument leverage override with explicit bounds.

**Columns/Parameters Involved**: `GCID`, `InstrumentID`, `MinLeverage`, `MaxLeverage`, `DefaultLeverage`, `Comments`

**Rules**:
- Each row defines one whitelist entry for one customer (GCID) and one instrument (InstrumentID).
- MinLeverage and MaxLeverage define the allowed range; DefaultLeverage is the default used when opening positions.
- Comments is optional audit text (e.g., "Professional client exemption per ESMA").
- Consuming procedure merges or updates the corresponding whitelist rows.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID - uniquely identifies the customer across the eToro platform. Points to Customer.CustomerTbl (GCID). The customer for whom this whitelist leverage override applies. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier. Points to Instrument.InstrumentTbl. The financial instrument (e.g., FX pair, crypto, stock) for which leverage limits are overridden. |
| 3 | MinLeverage | int | NO | - | CODE-BACKED | Minimum allowed leverage (e.g., 1 means 1:1). Lower bound of the whitelist override range. |
| 4 | MaxLeverage | int | NO | - | CODE-BACKED | Maximum allowed leverage (e.g., 500 means 500:1). Upper bound of the whitelist override range. |
| 5 | DefaultLeverage | int | NO | - | CODE-BACKED | Default leverage used when opening positions for this customer-instrument pair. Must fall within MinLeverage and MaxLeverage. |
| 6 | Comments | varchar(500) | YES | - | CODE-BACKED | Optional audit or explanatory text (e.g., exemption reason, ticket reference). Stored for compliance and audit trails. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Customer.CustomerTbl | Implicit Lookup | Identifies the customer for whitelist override |
| InstrumentID | Instrument.InstrumentTbl | Implicit Lookup | Identifies the instrument for whitelist override |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CM_UpdateLeveragesRestrictionsWhiteList | @Table parameter | Parameter (TVP) | Batch-updates leverage restriction whitelist entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CM_UpdateLeveragesRestrictionsWhiteList | Stored Procedure | READONLY parameter for bulk whitelist updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate CM_UpdateLeveragesRestrictionsWhiteListTable

```sql
DECLARE @T Trade.CM_UpdateLeveragesRestrictionsWhiteListTable;
INSERT INTO @T (GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, Comments)
VALUES
  (12345, 100, 1, 500, 100, 'Professional client exemption'),
  (67890, 200, 1, 100, 50, NULL);

EXEC Trade.CM_UpdateLeveragesRestrictionsWhiteList @Table = @T;
```

### 8.2 Batch update from a compliance workflow table

```sql
DECLARE @T Trade.CM_UpdateLeveragesRestrictionsWhiteListTable;
INSERT INTO @T (GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, Comments)
SELECT GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, Comments
FROM   Compliance.LeverageWhitelistChanges WITH (NOLOCK)
WHERE  Approved = 1;

EXEC Trade.CM_UpdateLeveragesRestrictionsWhiteList @Table = @T;
```

### 8.3 Update with resolved instrument IDs

```sql
DECLARE @T Trade.CM_UpdateLeveragesRestrictionsWhiteListTable;
INSERT INTO @T (GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, Comments)
SELECT c.GCID, i.InstrumentID, 1, 500, 100, 'Exemption per approval'
FROM   Compliance.PendingExemptions c WITH (NOLOCK)
JOIN   Instrument.InstrumentTbl i WITH (NOLOCK) ON i.Symbol = c.Symbol
WHERE  c.Status = 'Approved';

EXEC Trade.CM_UpdateLeveragesRestrictionsWhiteList @Table = @T;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CM_UpdateLeveragesRestrictionsWhiteListTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CM_UpdateLeveragesRestrictionsWhiteListTable.sql*

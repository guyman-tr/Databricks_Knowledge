# Trade.UpdateInstrumentType

> Single-column point update that sets InstrumentTypeID on Trade.InstrumentMetaData for a specific instrument, used for administrative reclassification of an instrument's type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InstrumentTypeID on Trade.InstrumentMetaData determines what category an instrument belongs to (e.g., stock, crypto, ETF, index, commodity, currency). This classification drives core platform behavior: which fee calculation rules apply, which order types are available, which settlement types are valid, and how the instrument is displayed and grouped for customers.

This procedure provides a direct, minimal update path for changing an instrument's type classification. No transaction, no sync event, no audit - it is a raw single-column UPDATE. This suggests it is used in controlled administrative contexts (data fixes, migrations, new instrument onboarding) where the caller manages orchestration externally.

No internal callers were found within the Trade stored procedure layer, confirming this is called directly from administrative tooling or data management scripts.

---

## 2. Business Logic

### 2.1 Direct InstrumentTypeID Update

**What**: Sets the InstrumentTypeID column on Trade.InstrumentMetaData to the supplied value for the specified instrument.

**Columns/Parameters Involved**: `@InstrumentID`, `@InstrumentTypeID`, `Trade.InstrumentMetaData.InstrumentTypeID`

**Rules**:
- Simple UPDATE: `SET InstrumentTypeID = @InstrumentTypeID WHERE InstrumentID = @InstrumentID`
- No validation of the new InstrumentTypeID (no FK check enforced at procedure level)
- No transaction wrapper - runs in implicit auto-commit mode
- No SyncConfiguration event - downstream systems are not notified via this procedure
- No audit trail - UpdatedByUser / timestamp not recorded here

**Downstream Impact of InstrumentTypeID**:
- Fee calculation: InstrumentTypeID used by Trade.GetInstrumentTypeIDsForCFDFee and fee config procedures
- Order type permissions: various configuration procedures check InstrumentTypeID for permitted operations
- Instrument grouping: affects which groups an instrument appears in for customers

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | Identifies the instrument to update. Maps to Trade.InstrumentMetaData.InstrumentID (primary key). If no row exists for this ID, the UPDATE affects 0 rows (no error). |
| 2 | @InstrumentTypeID | int | NO | - | CODE-BACKED | The new instrument type classification to assign. Maps to Trade.InstrumentMetaData.InstrumentTypeID. Common values correspond to stock (1), ETF (2), crypto (5), commodity (6), currency (7), index (10) etc. - exact values defined in the Dictionary schema. No FK validation at procedure level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentMetaData | UPDATE | Sets InstrumentTypeID for the specified instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External administrative tooling | Application call | Caller | No internal SP callers found; used from data management scripts or admin tools for instrument reclassification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentType (procedure)
+-- Trade.InstrumentMetaData (table) [UPDATE - InstrumentTypeID column]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | UPDATEd: InstrumentTypeID set for the specified InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External data management tooling | Application | Calls this procedure to reclassify instrument type during onboarding or data fixes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No transaction | Design | Auto-commit mode; no BEGIN TRAN / COMMIT wrapper |
| No sync event | Design | SyncConfiguration not written; downstream systems not notified |
| No audit | Design | UpdatedByUser and timestamp not recorded |
| Silent no-op | Behavior | If InstrumentID does not exist, UPDATE affects 0 rows with no error |

---

## 8. Sample Queries

### 8.1 Change instrument type

```sql
-- Reclassify instrument 1234 to a new type
EXEC Trade.UpdateInstrumentType
    @InstrumentID = 1234,
    @InstrumentTypeID = 5  -- e.g., 5 = Crypto
```

### 8.2 Verify the change

```sql
SELECT
    imd.InstrumentID,
    imd.InstrumentDisplayName,
    imd.InstrumentTypeID,
    imd.Symbol
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
WHERE imd.InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentType | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentType.sql*

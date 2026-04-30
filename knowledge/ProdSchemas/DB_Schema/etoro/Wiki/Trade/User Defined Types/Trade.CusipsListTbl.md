# Trade.CusipsListTbl

> A simple list type for passing CUSIP identifiers. Used to convert CUSIP codes to eToro InstrumentIDs via Trade.CusipsToInstrumentIDs. CUSIP is the US standard 9-character security identifier used by clearing brokers like Apex.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | Cusip (single column) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.CusipsListTbl is a minimal TVP for passing lists of CUSIP codes. CUSIP (Committee on Uniform Securities Identification Procedures) is the US standard 9-character security identifier - the primary identifier used by US clearing brokers such as Apex for settlement and position reconciliation.

This type enables bulk lookups: callers pass a set of CUSIPs and receive back the corresponding eToro InstrumentIDs. Without it, each CUSIP would require a separate lookup or a comma-delimited string with parsing overhead.

The consuming procedure Trade.CusipsToInstrumentIDs receives a populated instance and returns the InstrumentID mapping for each CUSIP. Duplicate CUSIPs in the input may result in duplicate rows in the output or be collapsed depending on procedure logic.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column utility type for CUSIP domain.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Cusip | varchar(100) | NO | - | CODE-BACKED | CUSIP code - the US standard 9-character security identifier. Used to resolve to eToro InstrumentID via Trade.CusipsToInstrumentIDs. Required. Used by clearing brokers like Apex for US securities. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Cusip is an external standard code, not an FK.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CusipsToInstrumentIDs | @Cusips or similar parameter | Parameter (TVP) | Receives CUSIP list and returns InstrumentID mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CusipsToInstrumentIDs | Stored Procedure | READONLY parameter - resolve CUSIPs to InstrumentIDs |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Resolve CUSIPs to InstrumentIDs

```sql
DECLARE @Cusips Trade.CusipsListTbl;
INSERT INTO @Cusips (Cusip) VALUES ('037833100'), ('594918104'), ('88160R101');
EXEC Trade.CusipsToInstrumentIDs @Cusips = @Cusips;
```

### 8.2 Build CUSIP list from external feed

```sql
DECLARE @Cusips Trade.CusipsListTbl;
INSERT INTO @Cusips (Cusip)
SELECT  DISTINCT CUSIP
FROM    ExternalFeed.ApexPositionReconciliation WITH (NOLOCK)
WHERE   ReconciliationDate = CAST(GETUTCDATE() AS DATE);
EXEC Trade.CusipsToInstrumentIDs @Cusips = @Cusips;
```

### 8.3 Single CUSIP lookup

```sql
DECLARE @Cusips Trade.CusipsListTbl;
INSERT INTO @Cusips (Cusip) VALUES ('037833100');
EXEC Trade.CusipsToInstrumentIDs @Cusips = @Cusips;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CusipsListTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CusipsListTbl.sql*

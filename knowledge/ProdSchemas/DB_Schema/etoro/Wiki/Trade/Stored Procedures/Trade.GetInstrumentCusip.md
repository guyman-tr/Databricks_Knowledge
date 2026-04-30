# Trade.GetInstrumentCusip

> Returns CUSIP and SEDOL identifiers for all instruments - used for regulatory reporting and security identification.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the CUSIP and SEDOL regulatory identifiers for every instrument in Trade.InstrumentMetaData. CUSIP (Committee on Uniform Security Identification Procedures) identifies US and Canadian securities; SEDOL (Stock Exchange Daily Official List) identifies UK and international securities. These are needed for regulatory reporting, trade reconciliation, and external system integration.

The procedure exists to provide a bulk dump of regulatory identifiers. Compliance systems and reporting tools query this to map eToro instrument IDs to standard financial identifiers.

Data flow: no parameters. Returns all InstrumentID, Cusip, SEDOL rows from Trade.InstrumentMetaData.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple full-table read. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 2 | Cusip (output) | VARCHAR | YES | - | CODE-BACKED | CUSIP identifier for US/Canadian securities. 9-character alphanumeric. NULL for non-US instruments. |
| 3 | SEDOL (output) | VARCHAR | YES | - | CODE-BACKED | SEDOL identifier for UK/international securities. 7-character alphanumeric. NULL for non-applicable instruments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentMetaData | FROM | Source of CUSIP and SEDOL identifiers |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentCusip (procedure)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - reads all CUSIP and SEDOL values |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute to get all identifiers

```sql
EXEC Trade.GetInstrumentCusip;
```

### 8.2 Find instruments with CUSIP

```sql
SELECT  InstrumentID, Cusip, SEDOL
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   Cusip IS NOT NULL;
```

### 8.3 Look up by CUSIP

```sql
SELECT  InstrumentID, InstrumentDisplayName, Cusip, SEDOL
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   Cusip = '037833100';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentCusip | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentCusip.sql*

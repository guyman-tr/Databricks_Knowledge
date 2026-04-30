# Trade.CusipsToInstrumentIDs

> Resolves a list of CUSIP identifiers (US securities identification numbers) to eToro internal InstrumentIDs by looking up the instrument metadata table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + Cusip result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CusipsToInstrumentIDs translates external CUSIP identifiers into eToro's internal InstrumentID values. CUSIP (Committee on Uniform Securities Identification Procedures) is the standard 9-character identifier for US and Canadian securities. When external systems (clearing firms like Apex, regulatory feeds, corporate actions providers) send data using CUSIPs, this procedure maps them to eToro's internal instrument references.

This procedure was created for the US brokerage project (TRADCD-753, August 2021) when eToro expanded into US securities trading through the Apex Clearing partnership. External data from Apex uses CUSIPs, while eToro's internal systems use InstrumentIDs. This bridge is essential for reconciliation, corporate actions processing, and regulatory reporting.

The procedure uses a LEFT JOIN, meaning CUSIPs that don't match any instrument will still appear in the output with a NULL InstrumentID - allowing the caller to identify unmatched securities.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a straightforward lookup procedure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CusipsList | Trade.CusipsListTbl (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing CUSIP identifiers to resolve. Each row has a Cusip column. CUSIPs not found in InstrumentMetaData return NULL InstrumentID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CUSIP lookup | Trade.InstrumentMetaData | Reader | LEFT JOINs on Cusip column to resolve CUSIP to InstrumentID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | API call | Consumer | Called by US brokerage services when processing external CUSIP-based data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CusipsToInstrumentIDs (procedure)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | LEFT JOIN on Cusip column for CUSIP-to-InstrumentID resolution |
| Trade.CusipsListTbl | User Defined Type | TVP type for the CUSIP list parameter |

### 6.2 Objects That Depend On This

No dependents found in the Trade schema. Called from the application layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check CUSIP mappings in InstrumentMetaData
```sql
SELECT InstrumentID, Cusip, SymbolFull
FROM   Trade.InstrumentMetaData WITH (NOLOCK)
WHERE  Cusip IS NOT NULL
ORDER BY Cusip
```

### 8.2 Find instruments with missing CUSIPs
```sql
SELECT InstrumentID, SymbolFull, InstrumentTypeID
FROM   Trade.InstrumentMetaData WITH (NOLOCK)
WHERE  Cusip IS NULL
       AND InstrumentTypeID IN (SELECT InstrumentTypeID FROM Dictionary.CurrencyType WITH (NOLOCK) WHERE Name = 'Stocks')
```

### 8.3 Check for duplicate CUSIPs
```sql
SELECT Cusip, COUNT(*) AS InstrumentCount
FROM   Trade.InstrumentMetaData WITH (NOLOCK)
WHERE  Cusip IS NOT NULL
GROUP BY Cusip
HAVING COUNT(*) > 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [TRADCD-753](https://etoro-jira.atlassian.net/browse/TRADCD-753) | Jira | Created August 2021 as part of the US brokerage project to map CUSIP identifiers to internal InstrumentIDs |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CusipsToInstrumentIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CusipsToInstrumentIDs.sql*

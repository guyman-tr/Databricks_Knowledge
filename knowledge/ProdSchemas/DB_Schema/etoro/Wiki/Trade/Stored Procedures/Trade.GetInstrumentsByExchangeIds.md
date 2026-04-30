# Trade.GetInstrumentsByExchangeIds

> Returns all instrument IDs that belong to a set of stock exchanges, enabling exchange-scoped instrument filtering for the Trade API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID filtered by ExchangeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsByExchangeIds is a getter procedure that accepts a comma-separated list of exchange IDs and returns all instrument IDs belonging to those exchanges. Stock instruments are listed on specific exchanges (NYSE, NASDAQ, LSE, etc.) tracked by ExchangeID in Trade.InstrumentMetaData. This procedure enables callers to retrieve the full instrument set for one or more exchanges in a single call.

This procedure exists because the Trade API needs to filter tradable instruments by exchange - for example, to show "all NASDAQ stocks" or "all instruments on exchanges 1,5,12". Without it, API consumers would need to query InstrumentMetaData directly with custom filtering.

The procedure is called by PROD\SQL_Trade-API-RO (read-only Trade API user). It uses STRING_SPLIT to parse the comma-delimited input, making it callable from simple HTTP query strings or configuration values. No validation is performed on exchange IDs; non-existent IDs simply return no matching rows.

---

## 2. Business Logic

### 2.1 Comma-Separated Exchange ID Parsing

**What**: Accepts a flexible comma-delimited string of exchange IDs and converts them to a joinable set using STRING_SPLIT.

**Columns/Parameters Involved**: `@Exchanges`, `Trade.InstrumentMetaData.ExchangeID`

**Rules**:
- Input format: "1,5,12" (comma-separated integers as NVARCHAR(MAX))
- STRING_SPLIT converts to a derived table of ExchangeID values
- INNER JOIN against InstrumentMetaData filters to instruments on those exchanges
- Non-existent ExchangeIDs silently produce no rows (no validation/error)
- Returns only InstrumentID (no additional metadata)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Exchanges | nvarchar(MAX) | NO | - | CODE-BACKED | Comma-separated list of exchange IDs to filter by (e.g., "1,5,12"). Parsed by STRING_SPLIT into individual ExchangeID values, then joined against Trade.InstrumentMetaData.ExchangeID. ExchangeID references the stock exchange where instruments are listed. |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.InstrumentMetaData.InstrumentID | CODE-BACKED | Instrument identifier for each instrument listed on the specified exchange(s). FK to Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM/JOIN | Trade.InstrumentMetaData | Read (SELECT) | Source of InstrumentID and ExchangeID; filtered by exchange membership |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD\SQL_Trade-API-RO | EXECUTE | Permission | Read-only Trade API service account |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsByExchangeIds (procedure)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | INNER JOIN on ExchangeID - source of InstrumentID filtered by exchange |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD\SQL_Trade-API-RO | DB User | EXECUTE permission for Trade API exchange-based instrument lookups |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No validation on @Exchanges input.

---

## 8. Sample Queries

### 8.1 Get instruments on a single exchange

```sql
EXEC Trade.GetInstrumentsByExchangeIds @Exchanges = '1';
```

### 8.2 Get instruments on multiple exchanges

```sql
EXEC Trade.GetInstrumentsByExchangeIds @Exchanges = '1,5,12';
```

### 8.3 Verify exchange-to-instrument mapping with names

```sql
SELECT  imd.ExchangeID,
        imd.InstrumentID,
        imd.InstrumentDisplayName
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
WHERE   imd.ExchangeID IN (1, 5, 12)
ORDER BY imd.ExchangeID, imd.InstrumentDisplayName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsByExchangeIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsByExchangeIds.sql*

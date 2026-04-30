# Trade.GetFundMetaData

> Returns fund metadata for a specific fund account: FundName, FundAccountID, IsPublic, HasCrypto, MinCopyAmount, RefreshIntervalMonths. Called by Trade.GetFundInfo.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | FundAccountID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns metadata for a single fund account. It provides the fund name, public/private flag, crypto inclusion flag, minimum copy amount, and refresh interval. This supports fund discovery, copy-trading setup, and fund administration UIs.

The procedure exists to centralize fund metadata retrieval. Trade.GetFundInfo calls it as part of a broader fund information flow. Without it, each consumer would need to query Trade.Fund directly with varying column sets.

Data is read from Trade.Fund filtered by @FundAccountID. A single row is returned when the fund exists.

---

## 2. Business Logic

### 2.1 Single-Fund Lookup by FundAccountID

**What**: Exactly one fund is returned when FundAccountID exists. No rows when the fund does not exist.

**Columns/Parameters Involved**: `@FundAccountID`

**Rules**:
- @FundAccountID is the primary filter
- Returns FundName, FundAccountID, IsPublic, HasCrypto, MinCopyAmount, RefreshIntervalMonths
- No pagination - single-row result set

### 2.2 Consumer Relationship

**What**: Trade.GetFundInfo is a known caller. This procedure serves as a building block for composite fund info.

**Columns/Parameters Involved**: N/A

**Rules**:
- Designed for inclusion in broader fund info flows
- Output columns chosen for API and admin consumption

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundAccountID | INT | NO | - | CODE-BACKED | Fund account identifier. Primary key of Trade.Fund. Filters to this fund. |
| 2 | FundName | VARCHAR | NO | - | CODE-BACKED | Display name of the fund. |
| 3 | FundAccountID | INT | NO | - | CODE-BACKED | Fund account ID (echo of input). Primary key. |
| 4 | IsPublic | BIT | NO | - | CODE-BACKED | 1 = fund is publicly listable/searchable; 0 = private/invite-only. |
| 5 | HasCrypto | BIT | NO | - | CODE-BACKED | 1 = fund includes crypto instruments; 0 = no crypto. |
| 6 | MinCopyAmount | MONEY | NO | - | CODE-BACKED | Minimum amount required to copy this fund. |
| 7 | RefreshIntervalMonths | INT | NO | - | CODE-BACKED | How often fund data is refreshed, in months. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.Fund | FROM | Source of fund metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetFundInfo | EXEC | Caller | Calls this procedure as part of fund info assembly |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetFundMetaData (procedure)
+-- Trade.Fund (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Fund | Table | FROM - fund metadata by FundAccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetFundInfo | Procedure | EXEC - calls for fund metadata |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for a fund

```sql
EXEC Trade.GetFundMetaData @FundAccountID = 5001;
```

### 8.2 Use in a batch over multiple funds

```sql
DECLARE @FundIds TABLE (FundAccountID INT);
INSERT INTO @FundIds VALUES (5001), (5002), (5003);

DECLARE @fid INT;
DECLARE c CURSOR FOR SELECT FundAccountID FROM @FundIds;
OPEN c;
FETCH NEXT FROM c INTO @fid;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC Trade.GetFundMetaData @FundAccountID = @fid;
    FETCH NEXT FROM c INTO @fid;
END;
CLOSE c; DEALLOCATE c;
```

### 8.3 Query source table directly

```sql
SELECT  FundName, FundAccountID, IsPublic, HasCrypto, MinCopyAmount, RefreshIntervalMonths
FROM    Trade.Fund WITH (NOLOCK)
WHERE   FundAccountID = 5001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetFundMetaData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetFundMetaData.sql*

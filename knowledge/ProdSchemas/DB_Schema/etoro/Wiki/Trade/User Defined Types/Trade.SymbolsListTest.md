# Trade.SymbolsListTest

> A test-oriented table-valued parameter type for passing instrument ticker symbols, structurally identical to Trade.SymbolsList with a test-specific name.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | Symbol (nvarchar(100)) - clustered PK |
| **Partition** | N/A |
| **Indexes** | Clustered PK on Symbol |

---

## 1. Business Meaning

Trade.SymbolsListTest is a table-valued parameter (TVP) type that carries instrument ticker symbols (e.g., "AAPL", "BTCUSD"). The name indicates it is intended for test scenarios rather than production. It uses Latin1_General_BIN collation for case-sensitive matching and has a clustered PK with IGNORE_DUP_KEY=ON to silently deduplicate symbols.

This type likely exists as a parallel to Trade.SymbolsList for test harnesses or QA procedures. No stored procedures in the Trade Stored Procedures folder were found that accept this type. It may be used by test code, automation, or procedures outside the main schema.

Application or test services would populate the type with symbol strings and pass it to procedures that accept it (exact consumers not identified in repo search).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column symbol list with deduplication via IGNORE_DUP_KEY.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Symbol | nvarchar(100) | NO | - | CODE-BACKED | Instrument ticker symbol. Latin1_General_BIN for case-sensitive matching. Clustered PK with IGNORE_DUP_KEY=ON. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Symbol semantically references Trade.Instrument.SymbolFull; no declared FKs.

### 5.2 Referenced By (other objects point to this)

No stored procedures in Trade/Stored Procedures were found that accept this type. Likely used in test or non-Trade procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No consumers found in the Trade schema. Type exists in project; usage may be in test or application code.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| (PK) | CLUSTERED | Symbol ASC | IGNORE_DUP_KEY = ON - duplicates silently dropped |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Declare and populate for test scenario

```sql
DECLARE @Symbols Trade.SymbolsListTest;
INSERT INTO @Symbols (Symbol) VALUES (N'TEST1'), (N'TEST2');
```

### 8.2 Demonstrate deduplication

```sql
DECLARE @S Trade.SymbolsListTest;
INSERT INTO @S (Symbol) VALUES (N'AAPL'), (N'AAPL'), (N'TSLA');
SELECT * FROM @S;
-- Returns 2 rows: AAPL, TSLA
```

### 8.3 Populate from instrument table

```sql
DECLARE @Symbols Trade.SymbolsListTest;
INSERT INTO @Symbols (Symbol)
SELECT TOP 10 SymbolFull FROM Trade.Instrument WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SymbolsListTest | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.SymbolsListTest.sql*

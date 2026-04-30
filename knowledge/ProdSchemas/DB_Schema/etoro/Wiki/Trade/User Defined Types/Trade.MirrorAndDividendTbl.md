# Trade.MirrorAndDividendTbl

> A table-valued parameter type for linking dividend events to copy-trade mirrors, used when applying dividend payments to mirror positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | DividendID, MirrorID |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.MirrorAndDividendTbl is a table-valued parameter (TVP) type that pairs DividendID with MirrorID. It represents the association between a dividend event and the copy-trade mirrors that are eligible to receive or are affected by that dividend. Each row links one dividend to one mirror.

This type exists to support dividend processing workflows where the system must know which mirrors are tied to a given dividend. Procedures can filter or join on these pairs when calculating dividend payments for copy-trade positions.

No stored procedure consumers were found in the Trade Stored Procedures folder for this type. It may be used in procedures outside the searched path or reserved for future dividend-mirror logic.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. DividendID + MirrorID pairs for associating dividends with copy-trade mirrors.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Dividend event identifier. References the dividend entity. |
| 2 | MirrorID | int | NO | - | CODE-BACKED | Copy-trade mirror identifier. The leader-to-copier relationship affected by the dividend. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. DividendID semantically references dividend entities; MirrorID references copy-trade mirror entities. There are no declared FKs on the type.

### 5.2 Referenced By (other objects point to this)

No consumers found in Trade.Stored Procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No consumers found in the searched scope.

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate dividend-mirror pairs

```sql
DECLARE @Pairs Trade.MirrorAndDividendTbl;
INSERT INTO @Pairs (DividendID, MirrorID) VALUES (100, 1), (100, 2), (101, 1);
-- Pass to dividend processing procedure
```

### 8.2 Load from dividend-affected mirrors query

```sql
DECLARE @Pairs Trade.MirrorAndDividendTbl;
INSERT INTO @Pairs (DividendID, MirrorID)
SELECT d.DividendID, p.MirrorID
FROM Trade.DividendTbl d
JOIN Trade.PositionTbl p ON p.InstrumentID = d.InstrumentID AND p.MirrorID IS NOT NULL
WHERE d.ExDate = @TargetDate;
```

### 8.3 Single dividend-mirror association

```sql
DECLARE @Pairs Trade.MirrorAndDividendTbl;
INSERT INTO @Pairs (DividendID, MirrorID) VALUES (42, 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.MirrorAndDividendTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.MirrorAndDividendTbl.sql*

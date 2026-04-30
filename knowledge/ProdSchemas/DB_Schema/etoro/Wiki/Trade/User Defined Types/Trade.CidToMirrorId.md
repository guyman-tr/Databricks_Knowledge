# Trade.CidToMirrorId

> A table-valued parameter type for mapping customer IDs to their copy-trade mirror IDs, used when retrieving unrealized equity data for specific CID-to-mirror combinations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID, MirrorID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.CidToMirrorId is a table-valued parameter (TVP) type that pairs Customer IDs (CIDs) with their corresponding Mirror IDs. A mirror represents a copy-trade relationship where a copier follows a leader - each mirror ID identifies a specific leader-to-copier link. This type enables procedures to retrieve unrealized equity data for only the requested CID-mirror pairs.

This type exists to support equity calculations and reporting for copy-trade portfolios. Without it, procedures would need to process all mirrors for all customers or accept separate CID and MirrorID lists that could be misaligned.

The application or reporting layer builds a CidToMirrorId table with the CID-mirror pairs of interest and passes it to procedures such as GetUsersUnrealizedEquityData. The procedure JOINs against the TVP to limit its processing to the specified pairs.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type pairs two identifiers for filtering; the business meaning is in the consuming procedure logic.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - the primary account identifier. Each row links one customer to one of their copy-trade mirrors. |
| 2 | MirrorID | int | NO | - | CODE-BACKED | Mirror ID - identifies a specific copy-trade relationship (leader-to-copier link). Used with CID to scope unrealized equity lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID semantically references Customer.CustomerTbl and MirrorID references copy-trade mirror entities; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUsersUnrealizedEquityDataJunk | Parameter (TVP) | Parameter (TVP) | Test/junk version of unrealized equity retrieval |
| Trade.GetUsersUnrealizedEquityData | Parameter (TVP) | Parameter (TVP) | Retrieves unrealized equity data for CID-mirror pairs |
| Trade.DBtestMot | Parameter (TVP) | Parameter (TVP) | Development/test procedure for MOT scenarios |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUsersUnrealizedEquityDataJunk | Stored Procedure | READONLY parameter for unrealized equity test |
| Trade.GetUsersUnrealizedEquityData | Stored Procedure | READONLY parameter for unrealized equity retrieval |
| Trade.DBtestMot | Stored Procedure | READONLY parameter for MOT development tests |

---

## 7. Technical Details

### 7.1 Indexes

None. No clustered index or primary key on the type.

### 7.2 Constraints

None declared on the type definition.

---

## 8. Sample Queries

### 8.1 Declare and populate CidToMirrorId for unrealized equity lookup

```sql
DECLARE @CidMirrors Trade.CidToMirrorId;
INSERT INTO @CidMirrors (CID, MirrorID) VALUES (12345, 100), (12345, 101), (67890, 200);
EXEC Trade.GetUsersUnrealizedEquityData @CidMirrors = @CidMirrors;
```

### 8.2 Build CidToMirrorId from active copy positions

```sql
DECLARE @Pairs Trade.CidToMirrorId;
INSERT INTO @Pairs (CID, MirrorID)
SELECT  DISTINCT CID, MirrorID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   MirrorID IS NOT NULL AND IsOpen = 1;
```

### 8.3 Single CID-mirror pair for focused lookup

```sql
DECLARE @Pair Trade.CidToMirrorId;
INSERT INTO @Pair (CID, MirrorID) VALUES (50001, 42);
EXEC Trade.GetUsersUnrealizedEquityData @CidMirrors = @Pair;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CidToMirrorId | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CidToMirrorId.sql*

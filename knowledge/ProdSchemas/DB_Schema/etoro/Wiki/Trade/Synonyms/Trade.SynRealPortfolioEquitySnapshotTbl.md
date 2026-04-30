# Trade.SynRealPortfolioEquitySnapshotTbl

> Synonym pointing to the PortfolioEquitySnapshotTbl table in the Pnl database, enabling the Trade schema to access portfolio equity snapshots for unrealized equity calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [Pnl].[Trade].[PortfolioEquitySnapshotTbl] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SynRealPortfolioEquitySnapshotTbl is a synonym that provides local access to the PortfolioEquitySnapshotTbl table in the Pnl (Profit and Loss) database. This table stores periodic snapshots of customer portfolio equity values - the total value of all open positions plus available cash at a given point in time. These snapshots are used to calculate unrealized equity, track portfolio performance over time, and generate equity-based reports.

The synonym exists because PnL calculations and equity tracking are handled in a separate database (Pnl) for performance isolation. The computationally intensive equity snapshot process runs independently, and the Trade schema reads the results through this synonym when it needs current or historical equity data.

The primary consumers are Trade.GetUsersUnrealizedEquityData and Trade.GetUsersUnrealizedEquityDataJunk. These procedures read equity snapshots to determine users' current unrealized equity positions, which feeds into margin calculations, risk monitoring, and user-facing portfolio displays.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Equity calculation logic resides in the Pnl database.

---

## 3. Data Overview

N/A for synonym (targets a table in an external database).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Three-part name | - | - | CODE-BACKED | Points to [Pnl].[Trade].[PortfolioEquitySnapshotTbl]. A table storing periodic snapshots of customer portfolio equity values (total position value + cash). Used for unrealized equity calculations, margin monitoring, and portfolio performance tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [Pnl].[Trade].[PortfolioEquitySnapshotTbl] | Synonym target | Cross-database reference to the portfolio equity snapshot table in the PnL database |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUsersUnrealizedEquityData | SELECT | Reader | Reads equity snapshots for unrealized equity calculations |
| Trade.GetUsersUnrealizedEquityDataJunk | SELECT | Reader | Legacy/variant version of unrealized equity data retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynRealPortfolioEquitySnapshotTbl (synonym)
  +-- [Pnl].[Trade].[PortfolioEquitySnapshotTbl] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Pnl].[Trade].[PortfolioEquitySnapshotTbl] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUsersUnrealizedEquityData | Stored Procedure | Reads equity snapshots for unrealized equity |
| Trade.GetUsersUnrealizedEquityDataJunk | Stored Procedure | Legacy equity data retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

N/A for synonym.

---

## 8. Sample Queries

### 8.1 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms WITH (NOLOCK)
WHERE  name = 'SynRealPortfolioEquitySnapshotTbl'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SynRealPortfolioEquitySnapshotTbl') AS ObjectID
```

### 8.3 Preview equity snapshot data (if accessible)
```sql
SELECT TOP 10 *
FROM   Trade.SynRealPortfolioEquitySnapshotTbl WITH (NOLOCK)
ORDER BY 1 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynRealPortfolioEquitySnapshotTbl | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SynRealPortfolioEquitySnapshotTbl.sql*

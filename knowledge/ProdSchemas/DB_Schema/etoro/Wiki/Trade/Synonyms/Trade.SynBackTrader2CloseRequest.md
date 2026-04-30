# Trade.SynBackTrader2CloseRequest

> Synonym pointing to the CloseRequest table in the BackTraderPaas2 database, enabling the Trade schema to access back-office close request data for reporting during system downtime.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [BackTraderPaas2].[BackTrader2].[Trade].[CloseRequest] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SynBackTrader2CloseRequest is a synonym that provides local access to the CloseRequest table in the BackTraderPaas2 database. BackTrader2 is eToro's back-office trading engine (PaaS version 2) that handles position close requests - instructions to close trading positions that may originate from users, automated systems, or administrative actions.

The synonym exists because the BackTrader2 system runs in a separate Azure database for architectural isolation. The Trade schema needs to read close request data when generating downtime reports and reconciliation analytics. This cross-database access pattern is typical for the platform's distributed architecture.

The primary consumer is Trade.SSRS_DuringDowntimeReport, which reads close request data through this synonym to generate SQL Server Reporting Services (SSRS) reports showing trading activity during planned or unplanned downtime windows.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The close request processing logic resides in the BackTrader2 system.

---

## 3. Data Overview

N/A for synonym (targets a table in an external database).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [BackTraderPaas2].[BackTrader2].[Trade].[CloseRequest]. A table storing position close requests processed by the BackTrader2 back-office trading engine. Used for downtime reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [BackTraderPaas2].[BackTrader2].[Trade].[CloseRequest] | Synonym target | Cross-database reference to the close request table in the BackTrader2 PaaS database |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SSRS_DuringDowntimeReport | SELECT | Reader | Reads close request data for SSRS downtime activity reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynBackTrader2CloseRequest (synonym)
  +-- [BackTraderPaas2].[BackTrader2].[Trade].[CloseRequest] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackTraderPaas2].[BackTrader2].[Trade].[CloseRequest] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SSRS_DuringDowntimeReport | Stored Procedure | Reads close request data for downtime reporting |

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
WHERE  name = 'SynBackTrader2CloseRequest'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SynBackTrader2CloseRequest') AS ObjectID
```

### 8.3 Preview close request data (if accessible)
```sql
SELECT TOP 10 *
FROM   Trade.SynBackTrader2CloseRequest WITH (NOLOCK)
ORDER BY 1 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynBackTrader2CloseRequest | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SynBackTrader2CloseRequest.sql*

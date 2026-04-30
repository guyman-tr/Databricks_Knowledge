# Trade.ApexSYN_EXT869_CashActivity

> Synonym pointing to the Apex SOD reconciliation cash activity report table in the SodreconciliationAzure linked server, used for dividend/airdrop payment verification.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT869_CashActivity] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ApexSYN_EXT869_CashActivity is a synonym that provides local access to the EXT869_CashActivity table in the Apex SOD (Start-of-Day) reconciliation database hosted on the SodreconciliationAzure linked server. EXT869 refers to an Apex Clearing report format for cash activity transactions.

This synonym exists to abstract the cross-database/linked-server path, allowing stored procedures in the etoro database to reference cash activity data using a simple two-part name (Trade.ApexSYN_EXT869_CashActivity) instead of the four-part linked server name. It is used in dividend and airdrop payment processing to verify or reconcile cash movements.

Used by Trade.PayCashAirdropByPayDateAndTerminalID for airdrop cash payment reconciliation against Apex clearing records.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym - a transparent alias to a remote table.

---

## 3. Data Overview

N/A for synonym. Data resides in the target SodreconciliationAzure database.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT869_CashActivity]. The target table stores Apex EXT869 report data for cash activity transactions including dividends, interest, and other cash events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT869_CashActivity] | Synonym target | Cross-database reference to Apex cash activity reconciliation table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PayCashAirdropByPayDateAndTerminalID | FROM/JOIN | Reader | Reads cash activity data for airdrop payment processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ApexSYN_EXT869_CashActivity (synonym)
  +-- [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT869_CashActivity] (remote table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT869_CashActivity] | Remote Table | Synonym target - all queries against this synonym are redirected to this table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PayCashAirdropByPayDateAndTerminalID | Stored Procedure | Reads cash activity data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query cash activity through synonym
```sql
SELECT TOP 10 *
FROM   Trade.ApexSYN_EXT869_CashActivity WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms
WHERE  name = 'ApexSYN_EXT869_CashActivity'
  AND  schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check linked server connectivity
```sql
SELECT TOP 1 1 AS IsReachable
FROM   Trade.ApexSYN_EXT869_CashActivity WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ApexSYN_EXT869_CashActivity | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.ApexSYN_EXT869_CashActivity.sql*

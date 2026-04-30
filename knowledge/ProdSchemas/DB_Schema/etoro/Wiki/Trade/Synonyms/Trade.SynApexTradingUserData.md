# Trade.SynApexTradingUserData

> Synonym pointing to the Apex TradingUserData table in the USABrokerAzure database, enabling the Trade schema to access Apex Clearing user identity data for US brokerage operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [USABrokerAzure].[USABroker].[Apex].[TradingUserData] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SynApexTradingUserData is a synonym that provides local access to the TradingUserData table in the USABrokerAzure database. Apex Clearing is the third-party clearing firm used for US securities trading. This table maps eToro customer IDs to their Apex account identifiers, enabling cross-system reconciliation between eToro's trading platform and Apex's clearing and settlement infrastructure.

The synonym exists because US brokerage operations are managed in a separate Azure database (USABrokerAzure), and the Trade schema needs to look up Apex identifiers when processing US stock trades. Without this mapping, the system cannot reconcile positions with the clearing firm.

The primary consumers are Trade.UpdateApexID and Trade.UpdateApexIDOld, which synchronize Apex account identifiers with eToro's trading records.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The Apex ID mapping logic resides in the consuming procedures.

---

## 3. Data Overview

N/A for synonym (targets a table in an external database).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [USABrokerAzure].[USABroker].[Apex].[TradingUserData]. A table mapping eToro customer IDs to Apex Clearing account identifiers for US securities trading and settlement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [USABrokerAzure].[USABroker].[Apex].[TradingUserData] | Synonym target | Cross-database reference to the Apex Clearing user identity table in the US brokerage database |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateApexID | SELECT/UPDATE | Consumer | Reads Apex user data to synchronize Apex account IDs with trading records |
| Trade.UpdateApexIDOld | SELECT/UPDATE | Consumer | Legacy version of the Apex ID synchronization procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynApexTradingUserData (synonym)
  +-- [USABrokerAzure].[USABroker].[Apex].[TradingUserData] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [USABrokerAzure].[USABroker].[Apex].[TradingUserData] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateApexID | Stored Procedure | Reads Apex user data for ID synchronization |
| Trade.UpdateApexIDOld | Stored Procedure | Legacy Apex ID synchronization |

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
WHERE  name = 'SynApexTradingUserData'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SynApexTradingUserData') AS ObjectID
```

### 8.3 Preview Apex user data (if accessible)
```sql
SELECT TOP 10 *
FROM   Trade.SynApexTradingUserData WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynApexTradingUserData | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SynApexTradingUserData.sql*

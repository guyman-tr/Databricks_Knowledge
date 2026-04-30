# History.ListenerRedeemPosition

> Synonym aliasing the HedgeRedeem database table that logs redeem position events received by the hedge redemption listener service, bridging the main etoro schema to the dedicated hedge redemption system's audit log.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [HedgeRedeem].[HedgeRedeemDB].[History].[ListenerRedeemPosition] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.ListenerRedeemPosition` is a synonym pointing to `[HedgeRedeem].[HedgeRedeemDB].[History].[ListenerRedeemPosition]` on the `HedgeRedeem` linked server. This is the only History-schema synonym that targets the `HedgeRedeemDB` system, which is the dedicated database for the hedge redemption platform.

A "redeem position" event occurs when a hedged position is redeemed - typically when eToro's hedge positions with liquidity providers are unwound as part of the redemption lifecycle (e.g., a provider-side stock redemption, an airdrop redemption, or a structured product redemption). The `ListenerRedeemPosition` table logs events received by the listener service that processes these redemption events.

The synonym provides a local name within the main `etoro` database for procedures or views that need to query the redemption listener log alongside other History-schema data, without exposing the full four-part cross-server path.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). The redemption listener writes events to the target table in the HedgeRedeem system. See `[HedgeRedeem].[HedgeRedeemDB].[History].[ListenerRedeemPosition]` for the full event structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[HedgeRedeem].[HedgeRedeemDB].[History].[ListenerRedeemPosition]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table in HedgeRedeemDB.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [HedgeRedeem].[HedgeRedeemDB].[History].[ListenerRedeemPosition] | Synonym | Points to the redemption listener event log on the HedgeRedeem linked server |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ListenerRedeemPosition (synonym)
+-- [HedgeRedeem].[HedgeRedeemDB].[History].[ListenerRedeemPosition] (external table - HedgeRedeem linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [HedgeRedeem].[HedgeRedeemDB].[History].[ListenerRedeemPosition] | External Table | Target on the HedgeRedeem linked server |

### 6.2 Objects That Depend On This

No dependents found in local schema analysis.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query through the synonym

```sql
SELECT TOP 10 *
FROM History.ListenerRedeemPosition WITH (NOLOCK)
```

### 8.2 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'ListenerRedeemPosition'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.3 Identify all non-DB_Logs external synonyms in History schema

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.base_object_name NOT LIKE '%DB_Logs%'
ORDER BY s.name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ListenerRedeemPosition | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.ListenerRedeemPosition.sql*

# Trade.GuarenteedSLTP_CIDBlacklist

> Blacklist of client IDs (CIDs) excluded from guaranteed Stop-Loss/Take-Profit features. Clients on the list cannot use guaranteed SL/TP; clearing sets them to enabled.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK) |

---

## 1. Business Meaning

Trade.GuarenteedSLTP_CIDBlacklist (note: typo "Guarenteed" in schema) stores client IDs that are excluded from guaranteed Stop-Loss and Take-Profit functionality. When GuarenteedSLTP=0, the client is blacklisted and cannot use guaranteed SL/TP. When GuarenteedSLTP=1 (or row cleared), the client regains access. Occurred and ModificationDate track when the client was blacklisted and when they were cleared.

This table exists because some clients abuse or trigger edge cases with guaranteed SL/TP; eToro needs a way to disable the feature per client without code changes. Created for Jira 41586 (Geri Reshef, 01/11/2016). SetGuarenteedSLTP_CIDBlacklist adds/updates blacklist; ClearGuarenteedSLTP_CIDBlacklist removes a client from blacklist; GetGuarenteedSLTP_CIDBlacklist returns blacklisted clients (GuarenteedSLTP=0).

Data flows: MERGE in Trade.SetGuarenteedSLTP_CIDBlacklist (add or set GuarenteedSLTP=0), UPDATE in Trade.ClearGuarenteedSLTP_CIDBlacklist (set GuarenteedSLTP=1, ModificationDate=GetDate()). Live count: 0 rows — table is currently empty but structure and procedures are active.

---

## 2. Business Logic

### 2.1 Blacklist State: GuarenteedSLTP

**What**: GuarenteedSLTP controls whether the client is excluded from guaranteed SL/TP.

**Columns/Parameters Involved**: `GuarenteedSLTP`, `CID`

**Rules**:
- GuarenteedSLTP=0: Client is blacklisted (cannot use guaranteed SL/TP). GetGuarenteedSLTP_CIDBlacklist returns these rows.
- GuarenteedSLTP=1: Client is cleared; guaranteed SL/TP enabled. Set by ClearGuarenteedSLTP_CIDBlacklist.
- Default 0 (Df_Trade_GuarenteedSLTP_CIDBlacklist_GuarenteedSLTP).

**Diagram**:
```
SetGuarenteedSLTP_CIDBlacklist(@CID) → MERGE: if matched set GuarenteedSLTP=0, if not matched INSERT
ClearGuarenteedSLTP_CIDBlacklist(@CID) → UPDATE set GuarenteedSLTP=1, ModificationDate=GetDate()
GetGuarenteedSLTP_CIDBlacklist → SELECT * WHERE GuarenteedSLTP=0
```

### 2.2 Occurred vs ModificationDate

**What**: Occurred = when blacklisted; ModificationDate = when last cleared or updated.

**Rules**:
- Occurred: DEFAULT getdate() on insert.
- ModificationDate: Set by ClearGuarenteedSLTP_CIDBlacklist on clear; NULL until first clear.

---

## 3. Data Overview

| CID | Occurred | GuarenteedSLTP | ModificationDate | Meaning |
|-----|----------|----------------|------------------|---------|
| *(Empty table)* | - | - | - | No clients currently blacklisted. |

**Selection criteria**: Table has 0 rows. Sample logic inferred from procedures.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Client ID. PK. FK to Customer (inferred). |
| 2 | Occurred | datetime | YES | getdate() | CODE-BACKED | When client was blacklisted. |
| 3 | GuarenteedSLTP | int | YES | 0 | CODE-BACKED | 0=blacklisted, 1=cleared. |
| 4 | ModificationDate | datetime | YES | - | CODE-BACKED | Set on clear by ClearGuarenteedSLTP_CIDBlacklist. |

---

## 5. Relationships

### 5.1 References To

- **Customer** (CID) — inferred; not declared FK in DDL.

### 5.2 Referenced By

- Trade.GetGuarenteedSLTP_CIDBlacklist (read)
- Trade.SetGuarenteedSLTP_CIDBlacklist (merge)
- Trade.ClearGuarenteedSLTP_CIDBlacklist (update)

---

## 6. Dependencies

### 6.0 Chain

```
(Standalone blacklist; no FK dependencies in DDL)
```

### 6.1 Depends On

- None (CID references Customer by convention only)

### 6.2 Depended On By

- Trade.GetGuarenteedSLTP_CIDBlacklist
- Trade.SetGuarenteedSLTP_CIDBlacklist
- Trade.ClearGuarenteedSLTP_CIDBlacklist

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Columns |
|------|------|---------|
| PK_Trade_GuarenteedSLTP_CIDBlacklist | CLUSTERED | CID |

### 7.2 Constraints

- PK_Trade_GuarenteedSLTP_CIDBlacklist: PRIMARY KEY (CID)
- Df_Trade_GuarenteedSLTP_CIDBlacklist_Occurred: DEFAULT getdate() FOR Occurred
- Df_Trade_GuarenteedSLTP_CIDBlacklist_GuarenteedSLTP: DEFAULT 0 FOR GuarenteedSLTP

---

## 8. Sample Queries

```sql
-- Row count
SELECT COUNT(*) AS Cnt FROM Trade.GuarenteedSLTP_CIDBlacklist WITH (NOLOCK);

-- Blacklisted clients (GuarenteedSLTP=0)
SELECT * FROM Trade.GuarenteedSLTP_CIDBlacklist WITH (NOLOCK) WHERE GuarenteedSLTP = 0;

-- Check if client is blacklisted
SELECT 1 FROM Trade.GuarenteedSLTP_CIDBlacklist WITH (NOLOCK) WHERE CID = @CID AND GuarenteedSLTP = 0;
```

---

## 9. Atlassian Knowledge Sources

*None discovered. Jira 41586 (DB stuff for BlackList for GuarenteedSLTP) cited in procedure comments.*

---

*Generated: 2026-03-14 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*

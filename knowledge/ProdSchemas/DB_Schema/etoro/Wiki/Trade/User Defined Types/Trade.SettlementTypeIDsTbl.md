# Trade.SettlementTypeIDsTbl

> A table-valued parameter type for passing settlement type IDs to procedures, used when calculating fees or filtering by settlement type (e.g., T+0, T+1, T+2).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | SettlementTypeID (clustered PK) |
| **Partition** | N/A |
| **Indexes** | Clustered PK on SettlementTypeID |

---

## 1. Business Meaning

Trade.SettlementTypeIDsTbl is a table-valued parameter (TVP) type for passing sets of settlement type IDs. Settlement type controls when trades settle (T+0, T+1, T+2, etc.) and affects fee calculations. The type enables procedures to accept a list of settlement types - for example, when computing fee config for multiple settlement cycles.

This type exists to support fee configuration and settlement-aware logic. Trade.GetCalculatedFeesConfig_TRDOPS accepts a settlement type list; the TVP allows callers to request fees for specific settlement types without hardcoding. IGNORE_DUP_KEY=OFF means duplicates raise an error (caller must deduplicate).

Application or fee-calculation services populate the type from configuration or user selection and pass it to GetCalculatedFeesConfig_TRDOPS.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column ID list; deduplication is the caller's responsibility.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SettlementTypeID | tinyint | NO | - | CODE-BACKED | Settlement type ID - identifies the settlement cycle (e.g., T+0, T+1, T+2). References Dictionary or config. Clustered PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. SettlementTypeID semantically references settlement type dictionary/config; no declared FKs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCalculatedFeesConfig_TRDOPS | @settlementtypeid_list | Parameter (TVP) | Calculates fee config for the given settlement types; list can be empty |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCalculatedFeesConfig_TRDOPS | Stored Procedure | READONLY parameter for fee config by settlement types |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| (PK) | CLUSTERED | SettlementTypeID ASC | IGNORE_DUP_KEY = OFF - duplicates cause error |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Get fee config for specific settlement types

```sql
DECLARE @SettlementTypes Trade.SettlementTypeIDsTbl;
INSERT INTO @SettlementTypes (SettlementTypeID) VALUES (0), (1), (2);
EXEC Trade.GetCalculatedFeesConfig_TRDOPS @settlementtypeid_list = @SettlementTypes;
```

### 8.2 Empty list (procedure accepts empty)

```sql
DECLARE @Types Trade.SettlementTypeIDsTbl;
-- No rows; procedure handles empty list
EXEC Trade.GetCalculatedFeesConfig_TRDOPS @settlementtypeid_list = @Types;
```

### 8.3 Single settlement type

```sql
DECLARE @T Trade.SettlementTypeIDsTbl;
INSERT INTO @T (SettlementTypeID) VALUES (1);
EXEC Trade.GetCalculatedFeesConfig_TRDOPS @settlementtypeid_list = @T;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SettlementTypeIDsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.SettlementTypeIDsTbl.sql*

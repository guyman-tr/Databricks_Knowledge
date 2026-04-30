# RecurringInvestment.BlackListCopyParentCID

> Blacklist table blocking specific traders (by CID) from being copied via recurring investment plans.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | CopyParentCID (BIGINT, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table maintains a blacklist of specific traders (identified by their CID) who cannot be copied via recurring investment plans. When a user attempts to create a Copy-type plan (PlanType=2) targeting a blacklisted trader, the eligibility check blocks the operation. This applies regardless of the copier's country or the copy type (PI or SmartPortfolio).

Without this table, the system could not block specific problematic traders from being targets of recurring copy investments - for example, traders under investigation, suspended PIs, or those who have opted out.

System-versioned with history in History.RecurringInvestmentBlackListCopyParentCID. Currently contains 22 blacklisted traders.

---

## 2. Business Logic

No complex multi-column business logic. Single-column blacklist: if a CopyParentCID is present, that trader cannot be the target of any copy trading recurring investment plan.

---

## 3. Data Overview

| CopyParentCID | Meaning |
|---------------|---------|
| 2988943 | This trader (CID 2988943) is blocked from being copied via recurring investment. Added 2025-09-17. May be under review or suspended from the PI program. |
| 4657429 | Blocked trader added 2025-05-29 as part of a batch of traders (several added simultaneously), suggesting a policy enforcement action. |
| 7160826 | Another trader blocked in the same 2025-05-29 batch. The simultaneous addition of multiple traders indicates a systematic review. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CopyParentCID | bigint | NO | - | VERIFIED | CID of the trader who is blocked from being copied via recurring investment plans. References the external user/trader system. Maps to Plans.CopyParentCID. |
| 2 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName. |
| 3 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. When this trader was added to the blacklist. |
| 4 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end. 9999-12-31 for currently blacklisted traders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CopyParentCID references the external user system.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.BlacklistCopyParentCIDGetAll | - | Reader | Reads all blacklisted copy parent CIDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlacklistCopyParentCIDGetAll | Stored Procedure | Reads all entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlackListCopyParentCID | NONCLUSTERED PK | CopyParentCID | - | - | Active |

### 7.2 Constraints

None.

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentBlackListCopyParentCID`.

---

## 8. Sample Queries

### 8.1 List all blacklisted copy parents
```sql
SELECT CopyParentCID FROM [RecurringInvestment].[BlackListCopyParentCID] WITH (NOLOCK) ORDER BY CopyParentCID
```

### 8.2 Check if a trader is blacklisted
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListCopyParentCID] WITH (NOLOCK) WHERE CopyParentCID = @CID) THEN 1 ELSE 0 END AS IsBlacklisted
```

### 8.3 View blacklist history
```sql
SELECT CopyParentCID, ValidFrom, ValidTo FROM [RecurringInvestment].[BlackListCopyParentCID] FOR SYSTEM_TIME ALL ORDER BY CopyParentCID, ValidFrom
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists are used for eligibility configuration |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlackListCopyParentCID | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.BlackListCopyParentCID.sql*

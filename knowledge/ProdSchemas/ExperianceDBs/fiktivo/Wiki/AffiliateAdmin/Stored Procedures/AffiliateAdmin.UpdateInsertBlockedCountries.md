# AffiliateAdmin.UpdateInsertBlockedCountries

> Synchronizes the blocked countries list for an affiliate using a MERGE pattern, with audit logging when the country list changes.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Rows affected in Affiliate.BlockedCountries |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertBlockedCountries synchronizes the set of blocked countries for a specific affiliate using a MERGE pattern on `Affiliate.BlockedCountries`. The procedure compares the current blocked country list against the provided list and efficiently adds, removes, or retains country entries as needed. When the overall list changes, an audit log entry is created.

**WHY:** Country blocking restricts an affiliate from receiving referrals or generating commissions from specific geographic regions. This is used for regulatory compliance (certain countries may be restricted for licensing reasons), fraud prevention (blocking high-risk regions), and business strategy (limiting affiliate reach to targeted markets). The MERGE pattern ensures efficient synchronization without requiring a DELETE-then-INSERT approach.

**HOW:** The procedure accepts the @AffiliateID and @BlockedCountries TVP containing the desired set of blocked country IDs. It uses a MERGE statement targeting `Affiliate.BlockedCountries` for the specified affiliate: new countries are inserted, removed countries are deleted, and matching countries are left unchanged. Before the MERGE, it captures the current country list. After the MERGE, it compares old vs. new lists, and if they differ, creates an audit log entry recording the change.

---

## 2. Business Logic

### 2.1 MERGE Pattern
The MERGE statement operates on `Affiliate.BlockedCountries` for the given @AffiliateID:
- **WHEN NOT MATCHED BY TARGET:** INSERT new blocked countries from @BlockedCountries
- **WHEN NOT MATCHED BY SOURCE:** DELETE countries that are no longer in the blocked list
- **WHEN MATCHED:** No action (country already blocked)

### 2.2 Change Detection for Audit
The procedure compares the old and new country lists to determine if the overall set has changed. The comparison is done before and after the MERGE. Only when the lists differ is an audit log entry created, avoiding noise from no-op calls.

### 2.3 Audit Logging
When the blocked country list changes, a single audit log entry is created (not per-country) recording:
- The affiliate ID
- The old country list
- The new country list
- The performing user (@UserEmail)

### 2.4 Empty List Support
If @BlockedCountries is empty, the MERGE effectively removes all blocked countries for the affiliate, unblocking all regions.

### 2.5 Optional User Email
The @UserEmail parameter defaults to NULL, making audit attribution optional. When NULL, the audit entry records no specific user.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | No | - | CODE-BACKED | The affiliate whose blocked countries are being synchronized |
| 2 | @BlockedCountries | dbo.IDTableType READONLY | No | - | CODE-BACKED | TVP containing the desired set of blocked country IDs |
| 3 | @UserEmail | NVARCHAR(250) | Yes | NULL | CODE-BACKED | Admin user performing the change (optional, for audit) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `Affiliate.BlockedCountries` | Table | MERGE blocked country assignments |
| `dbo.AuditLog` | Table | INSERT audit entry when list changes |
| `dbo.IDTableType` | User-Defined Table Type | Input type for country ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| `AffiliateAdmin.UpdateInsertAffiliate` | Stored Procedure | Called as part of affiliate save |
| Affiliate configuration screen | Application | Manage blocked countries per affiliate |
| Compliance management | Application | Restrict affiliate reach by country |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertBlockedCountries` -> capture old list -> MERGE `Affiliate.BlockedCountries` -> compare old vs new -> `AuditLog` (INSERT if changed)

### 6.1 Depends On
- `Affiliate.BlockedCountries` - Target table for blocked country entries
- `dbo.AuditLog` - Audit trail storage
- `dbo.IDTableType` - User-defined table type for country ID list input

### 6.2 Depend On This
Called by `AffiliateAdmin.UpdateInsertAffiliate` as part of composite affiliate save operations.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Set blocked countries for an affiliate
DECLARE @Countries dbo.IDTableType;
INSERT INTO @Countries (ID) VALUES (1), (5), (12), (25);
EXEC AffiliateAdmin.UpdateInsertBlockedCountries
    @AffiliateID = 100,
    @BlockedCountries = @Countries,
    @UserEmail = N'compliance@company.com';
```

```sql
-- 2. Remove all blocked countries (unblock all)
DECLARE @EmptyCountries dbo.IDTableType;
EXEC AffiliateAdmin.UpdateInsertBlockedCountries
    @AffiliateID = 100,
    @BlockedCountries = @EmptyCountries,
    @UserEmail = N'admin@company.com';
```

```sql
-- 3. Update blocked countries and verify
DECLARE @Countries dbo.IDTableType;
INSERT INTO @Countries (ID) VALUES (3), (7);
EXEC AffiliateAdmin.UpdateInsertBlockedCountries
    @AffiliateID = 200,
    @BlockedCountries = @Countries,
    @UserEmail = N'admin@company.com';
-- Verify:
SELECT * FROM Affiliate.BlockedCountries WHERE AffiliateID = 200;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-3147, PART-2714.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertBlockedCountries | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertBlockedCountries.sql*

# Billing.GetBonusType

> Filtered view of active bonus type definitions from BackOffice.BonusType, exposing only currently active bonus types for use by Billing schema operations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | BonusTypeID (from BackOffice.BonusType) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GetBonusType` is a filtered cross-schema view that exposes active bonus types from `BackOffice.BonusType` to the Billing schema. It answers "what types of bonuses are currently available for issuance?" by filtering to IsActive=1 and exposing the bonus type's key configuration attributes.

The view exists to give Billing schema code a clean, schema-local interface to bonus type definitions without directly coupling to the BackOffice schema. Billing procedures can query `Billing.GetBonusType` to validate bonus type IDs, check withdrawability, or retrieve configuration for bonus issuance workflows.

The view also implicitly acts as a soft-delete filter - bonus types that have been deactivated (IsActive=0) are hidden from callers, preventing issuance of obsolete bonus types.

---

## 2. Business Logic

### 2.1 Active Bonus Type Filter

**What**: Only bonus types currently enabled for issuance are returned.

**Columns/Parameters Involved**: `IsActive`

**Rules**:
- WHERE IsActive=1: Only returns bonus types that are currently active
- Inactive bonus types (IsActive=0) are hidden - historical records remain in BackOffice.BonusType but are inaccessible via this view
- The view always returns IsActive=1 for all its rows (the filter is applied in WHERE, not exposed as a variable field for filtering)

---

## 3. Data Overview

| BonusTypeID | ParentID | Name | IsWithdrawable | Meaning |
|---|---|---|---|---|
| 1 | 44 | First Registration Bonus | false | Bonus awarded on first account registration. Non-withdrawable. Child of parent type 44. |
| 2 | 26 | Sales First Deposit Bonus | false | Bonus issued by sales team upon customer's first deposit. Non-withdrawable. |
| 3 | NULL | Custom | false | Generic/custom bonus with no parent type - ad-hoc grants. Configuration varies per campaign. |
| 4 | 10 | Championship Winner | false | Bonus awarded to trading championship winners. Non-withdrawable. Child of parent type 10. |
| 5 | 10 | Retention Deposit Bonus | false | Bonus offered to retain customers who make a deposit. Non-withdrawable. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BonusTypeID | int | NO | - | CODE-BACKED | Unique bonus type identifier from BackOffice.BonusType. Referenced by Billing operations when issuing or validating bonuses. |
| 2 | ParentID | int | YES | - | CODE-BACKED | Parent bonus type in the hierarchy. NULL for root-level types. Non-null indicates this is a child/variant of a parent bonus concept (e.g., "Championship Winner" is a child of parent type 10). Supports multi-level bonus type trees. |
| 3 | Name | nvarchar | NO | - | CODE-BACKED | Human-readable bonus type name (e.g., "First Registration Bonus", "Sales First Deposit Bonus"). Used in admin UIs and reporting to identify bonus types. |
| 4 | Configuration | nvarchar/varchar | YES | - | CODE-BACKED | JSON or structured configuration string defining default behavior for this bonus type (e.g., default amount, expiry days, conditions). May be overridden per campaign in BackOffice.CampaignToBonusType.Configuration. |
| 5 | IsWithdrawable | bit | NO | - | CODE-BACKED | 1=the bonus amount can be withdrawn by the customer after meeting conditions. 0=non-withdrawable (credit usable for trading only). All current active types have IsWithdrawable=0, suggesting bonuses are trading credits rather than cash bonuses. |
| 6 | IsActive | bit | NO | - | CODE-BACKED | Always 1 in this view (WHERE IsActive=1 filter). Included in SELECT to confirm the active status to callers without requiring them to know the filter was applied. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BonusTypeID, Name, Configuration, ... | BackOffice.BonusType | Source (FROM + WHERE IsActive=1) | Bonus type master data; filtered to active records only |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CampaignBonuses | BonusTypeID | Related | CampaignBonuses view also reads BackOffice.BonusType directly; GetBonusType provides same data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetBonusType (view)
└── BackOffice.BonusType (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BonusType | Table | FROM source: bonus type definitions, filtered to IsActive=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered in Billing schema | - | Available for Billing SP bonus validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING (cross-schema). WITH (NOLOCK) applied directly in the view definition on the base table. IsActive column appears in both WHERE filter and SELECT list.

---

## 8. Sample Queries

### 8.1 List all active bonus types with withdrawability

```sql
SELECT BonusTypeID, Name, IsWithdrawable, ParentID
FROM Billing.GetBonusType WITH (NOLOCK)
ORDER BY BonusTypeID
```

### 8.2 Find top-level bonus types (no parent)

```sql
SELECT BonusTypeID, Name, Configuration
FROM Billing.GetBonusType WITH (NOLOCK)
WHERE ParentID IS NULL
ORDER BY BonusTypeID
```

### 8.3 Validate a bonus type ID is active before issuance

```sql
IF EXISTS (SELECT 1 FROM Billing.GetBonusType WITH (NOLOCK) WHERE BonusTypeID = @BonusTypeID)
    PRINT 'Bonus type is active - can issue'
ELSE
    PRINT 'Bonus type not active or does not exist'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 3/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetBonusType | Type: View | Source: etoro/etoro/Billing/Views/Billing.GetBonusType.sql*

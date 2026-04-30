# BackOffice.SetDefaultSpreadGroup

> Sets the spread group assignment for a specific affiliate in BackOffice.Affiliate, directly updating the SpreadGroupID without triggering CRM synchronization or cascading to referred customers.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID - the affiliate to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetDefaultSpreadGroup is a lightweight spread group assignment procedure for affiliates. It directly updates the SpreadGroupID column on BackOffice.Affiliate for the specified affiliate - setting which trading spread conditions they are assigned to.

Compared to BackOffice.AffiliateEdit (the full affiliate management procedure), SetDefaultSpreadGroup is a targeted single-column update with no side effects: it does NOT trigger a Dynamics CRM sync via Service Broker, and it does NOT cascade the new spread group to referred customers via Customer.Customer. It is intended for direct/administrative assignments where the secondary effects of AffiliateEdit are not desired.

SpreadGroupID determines the bid/ask spread rates an affiliate and their referred traders receive. SpreadGroupID=0 is the default standard spread (99.996% of affiliates). Non-zero values indicate custom premium spreads negotiated with specific affiliate partners.

---

## 2. Business Logic

### 2.1 Direct SpreadGroup Assignment (No Cascade)

**What**: Simple UPDATE with no CRM sync and no referred-customer cascade.

**Columns/Parameters Involved**: `@AffiliateID`, `@SpreadGroupID`

**Rules**:
- UPDATE BackOffice.Affiliate SET SpreadGroupID=@SpreadGroupID WHERE AffiliateID=@AffiliateID
- Returns @@ERROR (0 on success, non-zero on SQL error)
- NO Service Broker message fired to svcDynamics (contrast with AffiliateEdit which syncs to Dynamics CRM)
- NO cascade to Customer.Customer.SpreadGroupID (contrast with AffiliateEdit which updates referred customers)
- If @AffiliateID not found: 0 rows affected, @@ERROR=0, RETURN 0 (no error signaled)
- SpreadGroupID value must be valid per Trade.SpreadGroup (FK WITH CHECK enforced at table level)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INTEGER | NO | - | VERIFIED | The affiliate whose spread group is being set. Maps to BackOffice.Affiliate.AffiliateID (same as the affiliate's customer SerialID/CID in the trading system). No explicit FK validation in the procedure - invalid AffiliateID results in a no-op. |
| 2 | @SpreadGroupID | INTEGER | NO | - | VERIFIED | The spread group to assign. FK (WITH CHECK) to Trade.SpreadGroup at the table level. Common values: 0=default standard spread (99.996% of affiliates), 3=custom premium spread (2 affiliates). Value 0 is the "reset to default" value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | BackOffice.Affiliate | MODIFIER (UPDATE SpreadGroupID) | Sets the spread group for the affiliate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice UI (Affiliate management) | - | Caller | Called by BackOffice agents to assign or reset spread groups for affiliates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetDefaultSpreadGroup (procedure)
└── BackOffice.Affiliate (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Affiliate | Table | UPDATE: SET SpreadGroupID=@SpreadGroupID WHERE AffiliateID=@AffiliateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice UI (Affiliate management) | External | Administrative spread group assignment for affiliates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Set a custom spread group for an affiliate
```sql
DECLARE @Err INT
EXEC @Err = BackOffice.SetDefaultSpreadGroup
    @AffiliateID  = 1234567,
    @SpreadGroupID = 3
SELECT @Err AS ErrorCode
```

### 8.2 Reset an affiliate to the default spread group
```sql
EXEC BackOffice.SetDefaultSpreadGroup
    @AffiliateID  = 1234567,
    @SpreadGroupID = 0
```

### 8.3 Find affiliates with non-default spread groups
```sql
SELECT
    a.AffiliateID,
    a.SpreadGroupID,
    sg.SpreadGroupName
FROM BackOffice.Affiliate a WITH (NOLOCK)
JOIN Trade.SpreadGroup sg WITH (NOLOCK) ON sg.SpreadGroupID = a.SpreadGroupID
WHERE a.SpreadGroupID <> 0
ORDER BY a.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetDefaultSpreadGroup | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetDefaultSpreadGroup.sql*

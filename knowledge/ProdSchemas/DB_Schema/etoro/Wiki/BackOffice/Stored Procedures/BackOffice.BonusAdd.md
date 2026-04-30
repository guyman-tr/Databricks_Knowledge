# BackOffice.BonusAdd

> Creates a new bonus type in the BackOffice.BonusType catalog, returning the new BonusTypeID via both an OUTPUT parameter and a result set.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BonusTypeID (OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the write path for adding new entries to the BackOffice.BonusType catalog - the master list of bonus categories used to classify customer credit adjustments. It is called by BackOffice administrators when a new bonus program, promotional campaign type, or operational adjustment category needs to be registered before it can be issued to customers.

The BonusType catalog is hierarchical: root nodes represent departments (Sales, Marketing, Retention, Accounting/Ops, R&D, MT4, etc.) and child nodes represent specific bonus programs within each department. BonusAdd creates child nodes by requiring a ParentID linking the new type to its owning department root.

Once created, the new BonusTypeID can be immediately used in BackOffice.BonusLinkToCampaign (to associate the type with a campaign) and in BackOffice.Bonus grants (to issue credits of this type to customers). The returned ID is provided via both an OUTPUT parameter (for programmatic use without a result set) and a SELECT (for direct query use).

---

## 2. Business Logic

### 2.1 Bonus Type Creation

**What**: Inserts a new row into BackOffice.BonusType and returns the generated ID.

**Columns/Parameters Involved**: `@ParentID`, `@Name`, `@Configuration`, `@IsWithdrawable`, `@IsActive`, `@BonusTypeID OUTPUT`

**Rules**:
- INSERT sets exactly the 5 provided fields; BonusTypeID is IDENTITY auto-generated (SCOPE_IDENTITY)
- BonusTypeID is returned BOTH as an OUTPUT param AND as a single-column SELECT result set
- No existence check on ParentID - FK constraint (FK_BBNT_BBNT) enforces that ParentID references a valid BonusTypeID; invalid ParentID causes FK violation
- No transaction - single INSERT is atomic
- Columns NOT set by this procedure: HideFromAffwiz (defaults to 0 - visible in AffWiz), DisplayName (NULL), IsDepositRelated (defaults to 0)
- Callers must separately set HideFromAffwiz and DisplayName via BackOffice.BonusEdit if needed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BonusTypeID | INTEGER OUTPUT | NO | - | CODE-BACKED | OUTPUT parameter that receives the SCOPE_IDENTITY() of the newly created bonus type. Allows callers to capture the new ID without reading the result set. |
| 2 | @ParentID | INTEGER | NO | - | VERIFIED | Department-level parent BonusTypeID. Required to place the new type under its owning department root (e.g., 8=Accounting/Ops, 10=Retention, 26=Sales, 44=Marketing/IB). FK-enforced against BackOffice.BonusType.BonusTypeID. |
| 3 | @Name | VARCHAR(50) | NO | - | VERIFIED | Internal name for BackOffice staff identification and reporting (e.g., "Satisfaction Bonus", "Dormant Fee"). NOT the customer-facing label - DisplayName must be set via BonusEdit. Max 50 chars. Indexed (BBNT_NAME). |
| 4 | @Configuration | XML | YES | - | CODE-BACKED | Optional XML configuration for parameterized bonus types. In practice only BonusTypeID=2 uses this (value: `<DepositBonus/>`). Pass NULL for standard non-parameterized bonus types. |
| 5 | @IsWithdrawable | BIT | NO | - | CODE-BACKED | Whether the bonus amount is customer-withdrawable. Currently 0 (false) for all 70 active bonus types in production - this should be passed as 0 for new types unless a new withdrawable bonus program is being created. |
| 6 | @IsActive | BIT | NO | - | CODE-BACKED | Whether the new type is immediately active and issuable. Pass 1 to activate the type for use in bonus grants. Pass 0 to create an inactive/planned type not yet available for selection. |

**Result Set:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 7 | (column 1) | INT | NO | - | CODE-BACKED | The new BonusTypeID (SCOPE_IDENTITY after INSERT). Single row, single column. Same value as @BonusTypeID OUTPUT param. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ParentID | BackOffice.BonusType | WRITER | INSERT target - creates a new bonus type record. @ParentID must reference an existing BonusTypeID (FK enforced). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application layer | - | Caller | Called by BackOffice admins when registering a new bonus program or adjustment category |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BonusAdd (procedure)
+-- BackOffice.BonusType (table) [INSERT target; ParentID FK enforced]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BonusType | Table | INSERT target; SCOPE_IDENTITY() captures the new BonusTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Calls to register new bonus types before they can be used in campaigns or grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| FK_BBNT_BBNT (on table) | Referential Integrity | @ParentID must reference a valid BackOffice.BonusType.BonusTypeID - invalid values cause FK violation |
| Dual return | Design | BonusTypeID returned both as OUTPUT param and SELECT result set - callers can use whichever is convenient |
| No HideFromAffwiz/DisplayName | Design | These columns are not set by BonusAdd (they use table defaults: 0 and NULL respectively). Callers must use BonusEdit to set them if needed. |

---

## 8. Sample Queries

### 8.1 Add a new bonus type under Accounting/Ops

```sql
DECLARE @newId INTEGER
EXEC BackOffice.BonusAdd
    @BonusTypeID = @newId OUTPUT,
    @ParentID = 8,              -- 8 = Accounting / Ops
    @Name = 'Wire Fee Refund',
    @Configuration = NULL,
    @IsWithdrawable = 0,
    @IsActive = 1
SELECT @newId AS NewBonusTypeID
```

### 8.2 Add a deposit-related retention bonus type

```sql
DECLARE @newId INTEGER
EXEC BackOffice.BonusAdd
    @BonusTypeID = @newId OUTPUT,
    @ParentID = 10,             -- 10 = Retention
    @Name = 'Loyalty Deposit Reward',
    @Configuration = NULL,
    @IsWithdrawable = 0,
    @IsActive = 1
-- Set DisplayName and mark as deposit-related via BonusEdit if needed
```

### 8.3 Verify the new type was created

```sql
SELECT BonusTypeID, ParentID, Name, DisplayName, IsWithdrawable, IsActive, HideFromAffwiz
FROM BackOffice.BonusType WITH (NOLOCK)
WHERE BonusTypeID = @newId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BonusAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.BonusAdd.sql*

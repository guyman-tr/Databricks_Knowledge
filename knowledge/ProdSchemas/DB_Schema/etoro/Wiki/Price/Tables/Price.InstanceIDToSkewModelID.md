# Price.InstanceIDToSkewModelID

> Configuration table that maps each SkewModelService instance ID to the skew algorithm model it runs, enabling the service host to load the correct algorithm implementation per instance at startup.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (InstanceId, ModelID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

InstanceIDToSkewModelID assigns SkewModelService instances to their designated skew algorithm implementations. Each SkewModelService instance (identified by InstanceId) is responsible for running one or more skew models. This table tells the service host which algorithm DLL to load (via the ModelID FK to `Price.SkewModels`) for each deployed instance.

Currently 2 rows exist:
- **InstanceId=1** -> **ModelID=1 (BuyRatio)**: Service instance 1 runs the BuyRatio skew algorithm
- **InstanceId=2** -> **ModelID=2 (PriceAlgo)**: Service instance 2 runs the PriceAlgo skew algorithm

This 1:1 mapping (one instance per model) reflects a deployment topology where each algorithm runs in its own isolated service instance. The composite PK technically allows a single InstanceId to be assigned multiple models, enabling future multi-model instances.

The table has temporal versioning and standard computed audit columns. InstanceId has no FK constraint (instance IDs are managed by the deployment infrastructure, not the database).

---

## 2. Business Logic

### 2.1 Service Instance to Algorithm Assignment

**What**: Declares which skew algorithm each SkewModelService instance executes.

**Columns/Parameters Involved**: `InstanceId`, `ModelID`

**Rules**:
- Composite PK (InstanceId, ModelID) - one assignment per (instance, model) pair
- ModelID FK -> Price.SkewModels: 1=BuyRatio, 2=PriceAlgo
- InstanceId has no FK - deployment-defined
- Current topology: 2 instances, each assigned to a distinct model
- The SkewModelService reads this table at startup to determine which algorithm to instantiate using the Assembly and Class from Price.SkewModels

---

## 3. Data Overview

| InstanceId | ModelID | Model Name | Meaning |
|---|---|---|---|
| 1 | 1 | BuyRatio | Service instance 1 runs the BuyRatio skew algorithm (SkewModelService.BuyRatioModel.dll) |
| 2 | 2 | PriceAlgo | Service instance 2 runs the PriceAlgo skew algorithm (SkewModelService.PriceAlgoModel.dll) |

2 rows. Last configured: 2021-09-13.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceId | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. The SkewModelService instance identifier. Assigned by deployment infrastructure (no FK constraint). Current values: 1 (BuyRatio instance) and 2 (PriceAlgo instance). |
| 2 | ModelID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. FK to Price.SkewModels. The skew algorithm assigned to this instance: 1=BuyRatio, 2=PriceAlgo. The SkewModels.Assembly and SkewModels.Class columns provide the DLL to load. (Price.SkewModels) |
| 3 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. |
| 4 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 5 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 6 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical versions in History.InstanceIDToSkewModelID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ModelID | Price.SkewModels | FK (unnamed) | The skew algorithm assigned to this service instance |
| InstanceId | (external) | No FK | Service instance IDs managed by deployment infrastructure |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views in the Price schema SSDT repo currently reference this table. The SkewModelService reads it at startup via application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstanceIDToSkewModelID (table)
|- Price.SkewModels (table, FK target: ModelID=1 BuyRatio, ModelID=2 PriceAlgo)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.SkewModels | Table | FK target - ModelID must reference a registered skew algorithm |

### 6.2 Objects That Depend On This

No DB-level dependents found. Used by SkewModelService application code at startup.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | InstanceId ASC, ModelID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (unnamed) | PRIMARY KEY | Composite PK - one assignment per (service instance, model) |
| FK (unnamed) | FK | ModelID -> Price.SkewModels(ModelID) |
| DF_InstanceIDToSkewModelID_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstanceIDToSkewModelID_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.InstanceIDToSkewModelID |
| TRG_T_InstanceIDToSkewModelID | TRIGGER (INSERT) | ASM no-op: self-update on InstanceId after insert |

---

## 8. Sample Queries

### 8.1 View all instance-to-model assignments with model details

```sql
SELECT
    I.InstanceId,
    I.ModelID,
    SM.Name AS ModelName,
    SM.Assembly,
    SM.Class,
    I.SysStartTime AS AssignedSince
FROM Price.InstanceIDToSkewModelID I WITH (NOLOCK)
JOIN Price.SkewModels SM WITH (NOLOCK)
    ON SM.ModelID = I.ModelID
ORDER BY I.InstanceId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 4, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstanceIDToSkewModelID | Type: Table | Source: etoro/etoro/Price/Tables/Price.InstanceIDToSkewModelID.sql*

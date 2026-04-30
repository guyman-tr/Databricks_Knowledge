# Dictionary.PromotionType

> Lookup table defining 2 promotion categories — Replaceable Promotion and Deposit Bonus — controlling how marketing promotions interact with the eToro messaging system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PromotionTypeID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 (PK clustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.PromotionType classifies marketing promotions into categories that determine how they interact with message templates and whether they can be replaced by newer promotions. The platform sends promotional messages to users, and some promotions are "replaceable" (a newer campaign supersedes the old one) while others like deposit bonuses persist independently.

This table is consumed by Maintenance.MessageTemplate (PromotionTypeID column), managed by Maintenance.PromotionTypeAdd/Edit/Delete procedures, used in Customer.SendMessage for message delivery, displayed via BackOffice.GetEnglishMessageTemplate view, and resolved by Internal.GetPromotionTypeID.

---

## 2. Business Logic

### 2.1 Promotion Replaceability

**What**: The IsReplaceable flag controls whether a newer promotion of the same type automatically replaces an older one.

**Columns/Parameters Involved**: `PromotionTypeID`, `IsReplaceable`, `Name`

**Rules**:
- **1 = Replaceable Promotion** (IsReplaceable=true) — Generic promotions that can be superseded. When a new replaceable promotion is created, it replaces any existing active replaceable promotion for the same target audience.
- **2 = Deposit Bonus** (IsReplaceable=false) — Bonus promotions tied to deposit actions. These persist independently and are NOT replaced by newer promotions. Multiple deposit bonuses can coexist.
- The replaceability logic is enforced in the Customer.SendMessage and Maintenance.MessageTemplate* procedures.

**Diagram**:
```
Promotion Types
├── 1 = Replaceable Promotion (IsReplaceable = true)
│   └── New promotion replaces existing one
│
└── 2 = Deposit Bonus (IsReplaceable = false)
    └── Multiple can coexist independently
```

---

## 3. Data Overview

| PromotionTypeID | IsReplaceable | Name | Meaning |
|---|---|---|---|
| 1 | true | Replaceable Promotion | General marketing promotion — newer campaigns automatically supersede older ones of this type. |
| 2 | false | Deposit Bonus | Deposit-linked bonus promotion — persists independently and is not replaced by newer promotions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PromotionTypeID | int | NO | - | VERIFIED | Primary key. 1=Replaceable Promotion, 2=Deposit Bonus. Referenced by Maintenance.MessageTemplate. |
| 2 | IsReplaceable | bit | NO | - | VERIFIED | Controls promotion coexistence behavior. 1=new promotion replaces existing active promotion; 0=promotions persist independently. |
| 3 | Name | varchar(50) | NO | - | VERIFIED | Human-readable promotion category name. Unique index enforces no duplicates. Used in BackOffice UI and resolved by Internal.GetPromotionTypeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.MessageTemplate | PromotionTypeID | Implicit | Links message templates to promotion categories |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.MessageTemplate | Table | Stores PromotionTypeID per message template |
| Maintenance.PromotionTypeAdd | Stored Procedure | Writer — creates new promotion types |
| Maintenance.PromotionTypeEdit | Stored Procedure | Modifier — updates promotion types |
| Maintenance.PromotionTypeDelete | Stored Procedure | Deleter — removes promotion types |
| Internal.GetPromotionTypeID | Stored Procedure | Reader — name-to-ID resolver |
| Customer.SendMessage | Stored Procedure | Reader — checks replaceability during message delivery |
| Maintenance.MessageTemplateAdd | Stored Procedure | Writer — associates templates with promotion types |
| Maintenance.MessageTemplateEdit | Stored Procedure | Modifier — updates template promotion type |
| BackOffice.GetEnglishMessageTemplate | View | Displays promotion type in template listing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPMT | CLUSTERED PK | PromotionTypeID ASC | - | - | Active (FF=90) |
| DPMT_NAME | UNIQUE NONCLUSTERED | Name ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPMT | PRIMARY KEY | Unique promotion type identifier |
| DPMT_NAME | UNIQUE INDEX | Prevents duplicate promotion type names |

---

## 8. Sample Queries

### 8.1 List all promotion types
```sql
SELECT  PromotionTypeID,
        Name,
        IsReplaceable
FROM    [Dictionary].[PromotionType] WITH (NOLOCK)
ORDER BY PromotionTypeID;
```

### 8.2 Find message templates by promotion type
```sql
SELECT  mt.TemplateID,
        pt.Name AS PromotionType,
        pt.IsReplaceable
FROM    [Maintenance].[MessageTemplate] mt WITH (NOLOCK)
JOIN    [Dictionary].[PromotionType] pt WITH (NOLOCK) ON mt.PromotionTypeID = pt.PromotionTypeID;
```

### 8.3 Find non-replaceable promotion types
```sql
SELECT  PromotionTypeID,
        Name
FROM    [Dictionary].[PromotionType] WITH (NOLOCK)
WHERE   IsReplaceable = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PromotionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PromotionType.sql*

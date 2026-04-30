# Dictionary.PrizeType

> Lookup table defining 4 championship prize calculation methods — Unknown, Fix, Percent, and Product — used by the eToro championship/competition system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PrizeTypeID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 (PK clustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.PrizeType defines how prizes are calculated and awarded in eToro's championship (trading competition) system. Championships allow users to compete in simulated or real trading environments, and prizes can be awarded as fixed amounts, percentage-based rewards, or physical/digital products.

This table is consumed by Championship.Championship and History.Championship tables (PrizeTypeID column), the Championship.ChampionshipStart and Championship.ChampionshipSetupAdd stored procedures for creating competitions, the Championship.GetChampionship and Championship.GetChampionshipHistory views for displaying results, and Internal.GetPrizeTypeID for name-to-ID resolution.

---

## 2. Business Logic

### 2.1 Prize Calculation Methods

**What**: Each prize type defines a different method for calculating the championship reward.

**Columns/Parameters Involved**: `PrizeTypeID`, `Name`

**Rules**:
- **0 = Unknown** — Default/unset state for championships without configured prizes.
- **1 = Fix** — A fixed monetary amount (e.g., $10,000 first prize).
- **2 = Percent** — Prize is a percentage of something (e.g., % of entry fees or account equity).
- **3 = Product** — Non-monetary prize (e.g., iPad, trading credits, merchandise).
- Prize type is set at championship creation via Championship.ChampionshipSetupAdd and Championship.ChampionshipStart.

**Diagram**:
```
Prize Types
├── 0 = Unknown     (not configured)
├── 1 = Fix         (fixed monetary amount)
├── 2 = Percent     (percentage-based calculation)
└── 3 = Product     (physical/digital product)
```

---

## 3. Data Overview

| PrizeTypeID | Name | Meaning |
|---|---|---|
| 0 | Unknown | Default/placeholder — championship prize has not been configured. |
| 1 | Fix | Fixed amount prize — a specific monetary value awarded to winners. |
| 2 | Percent | Percentage-based prize — calculated as a percentage of a pool or metric. |
| 3 | Product | Non-monetary prize — physical product, digital credits, or merchandise. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PrizeTypeID | int | NO | - | VERIFIED | Primary key identifying the prize calculation method. Values 0-3 are the 4 supported types. Referenced by Championship.Championship and History.Championship tables. |
| 2 | Name | char(50) | NO | - | VERIFIED | Human-readable label for the prize type. Padded to 50 chars (CHAR type). Used in championship configuration UI and resolved by Internal.GetPrizeTypeID. Unique index enforces no duplicate names. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Championship.Championship | PrizeTypeID | Implicit | Defines how prizes are calculated for active championships |
| History.Championship | PrizeTypeID | Implicit | Historical record of championship prize types |
| Championship.GetChampionship | PrizeTypeID | View | Exposes prize type in championship listing view |
| Championship.GetChampionshipHistory | PrizeTypeID | View | Exposes prize type in championship history view |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Championship.Championship | Table | Stores PrizeTypeID per championship |
| History.Championship | Table | Historical championship records |
| Championship.ChampionshipStart | Stored Procedure | Sets prize type at championship start |
| Championship.ChampionshipSetupAdd | Stored Procedure | Configures prize type during setup |
| Internal.GetPrizeTypeID | Stored Procedure | Name-to-ID lookup resolver |
| OldStyle.ChampionshipAdd | Stored Procedure | Legacy championship creation |
| Championship.GetChampionship | View | Championship listing |
| Championship.GetChampionshipHistory | View | Historical championship listing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPZT | CLUSTERED PK | PrizeTypeID ASC | - | - | Active (FF=90) |
| DPZT_NAME | UNIQUE NONCLUSTERED | Name ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPZT | PRIMARY KEY | Unique prize type identifier |
| DPZT_NAME | UNIQUE INDEX | Prevents duplicate prize type names |

---

## 8. Sample Queries

### 8.1 List all prize types
```sql
SELECT  PrizeTypeID,
        RTRIM(Name) AS Name
FROM    [Dictionary].[PrizeType] WITH (NOLOCK)
ORDER BY PrizeTypeID;
```

### 8.2 Find championships by prize type
```sql
SELECT  c.ChampionshipID,
        RTRIM(pt.Name) AS PrizeType
FROM    [Championship].[Championship] c WITH (NOLOCK)
JOIN    [Dictionary].[PrizeType] pt WITH (NOLOCK) ON c.PrizeTypeID = pt.PrizeTypeID
ORDER BY c.ChampionshipID;
```

### 8.3 Resolve prize type by name
```sql
SELECT  PrizeTypeID
FROM    [Dictionary].[PrizeType] WITH (NOLOCK)
WHERE   Name = 'Fix';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PrizeType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PrizeType.sql*

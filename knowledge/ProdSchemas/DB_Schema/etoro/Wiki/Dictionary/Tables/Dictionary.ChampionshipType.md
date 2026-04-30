# Dictionary.ChampionshipType

> Lookup table defining the 3 types of trading championships — NULL (unset), Public (open to all), and Private (invitation-only).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ChampionshipTypeID (int, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (clustered PK + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.ChampionshipType classifies trading championships by their accessibility — whether they are open to all platform users or restricted to invited participants. This distinction affects eligibility rules, visibility on the platform, and how the championship is promoted.

The Championship module references this table extensively. The `Championship.Championship` table stores the ChampionshipTypeID for each event. Setup procedures (`Championship.ChampionshipSetupAdd`, `Championship.ChampionshipSetupUpdate`) configure the type. The `Championship.ChampionshipStart` procedure uses the type during initialization. Views like `Championship.GetChampionship` and `Championship.GetChampionshipHistory` expose the type for querying. Historical championship records in `History.Championship` also reference this type. The `Internal.GenChampionshipTypeID` table and `Internal.GetChampionshipTypeID` procedure provide ID generation support.

---

## 2. Business Logic

### 2.1 Championship Accessibility

**What**: Two accessibility levels for trading championships.

**Columns/Parameters Involved**: `ChampionshipTypeID`, `Name`

**Rules**:
- **NULL (ID=0)**: Default/unset placeholder. Exists for data integrity when a championship hasn't been fully configured yet.
- **Public (ID=1)**: Championship is visible to all users and anyone can register. Used for promotional events, platform-wide competitions, and community engagement campaigns.
- **Private (ID=2)**: Championship is invitation-only. Only specifically invited users can see and register for the event. Used for VIP competitions, partner events, or targeted engagement campaigns for specific customer segments.

---

## 3. Data Overview

| ChampionshipTypeID | Name | Meaning |
|---|---|---|
| 0 | NULL | Default placeholder — championship exists but type not yet assigned. Likely represents an incomplete setup or a migration artifact. |
| 1 | Public | Open championship visible to all platform users — anyone meeting basic eligibility requirements can join. Used for broad community engagement and marketing events. |
| 2 | Private | Invitation-only championship — only users who receive a specific invitation can see and register. Used for VIP, partner, or targeted segment competitions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChampionshipTypeID | int | NO | - | VERIFIED | Primary key identifying the championship type. Values: 0=NULL, 1=Public, 2=Private. Referenced by `Championship.Championship.ChampionshipTypeID` and `History.Championship.ChampionshipTypeID`. Also used by `Internal.GetChampionshipTypeID` for ID generation. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Type label ('NULL', 'Public', 'Private'). Enforced unique via `DCHT_NAME` index. Used in views and procedures for display and filtering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Championship.Championship | ChampionshipTypeID | Implicit FK | Each championship event has a type (Public/Private) |
| History.Championship | ChampionshipTypeID | Implicit FK | Historical championship records preserve the type |
| Championship.ChampionshipSetupAdd | Parameter | Procedure | Sets championship type during initial setup |
| Championship.ChampionshipSetupUpdate | Parameter | Procedure | Updates championship type during configuration |
| Championship.GetChampionship | Read | View | Exposes championship type for querying |
| Championship.GetChampionshipHistory | Read | View | Shows type in historical championship listings |
| History.GetPlayerRankWithChampType | Read | View | Joins championship type for ranking reports |
| History.GetChampionshipInfoWithChampType | Read | View | Joins championship type for info reports |
| Internal.GetChampionshipTypeID | Read | Procedure | ID generation/lookup for championship types |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Championship.Championship | Table | Stores championship type |
| History.Championship | Table | Historical type reference |
| Championship.ChampionshipSetupAdd | Procedure | Configures type |
| Championship.ChampionshipSetupUpdate | Procedure | Updates type |
| Championship.GetChampionship | View | Reads type |
| Championship.GetChampionshipHistory | View | Reads type for history |
| History.GetPlayerRankWithChampType | View | Joins type for rankings |
| History.GetChampionshipInfoWithChampType | View | Joins type for info |
| Internal.GetChampionshipTypeID | Procedure | ID lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCHT | CLUSTERED PK | ChampionshipTypeID ASC | - | - | Active |
| DCHT_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

None beyond PK and unique index.

---

## 8. Sample Queries

### 8.1 List all championship types
```sql
SELECT  ChampionshipTypeID,
        Name
FROM    Dictionary.ChampionshipType WITH (NOLOCK)
ORDER BY ChampionshipTypeID;
```

### 8.2 Count championships by type
```sql
SELECT  DCT.ChampionshipTypeID,
        DCT.Name AS TypeName,
        COUNT(CC.ChampionshipID) AS ChampionshipCount
FROM    Dictionary.ChampionshipType DCT WITH (NOLOCK)
LEFT JOIN Championship.Championship CC WITH (NOLOCK)
        ON CC.ChampionshipTypeID = DCT.ChampionshipTypeID
GROUP BY DCT.ChampionshipTypeID, DCT.Name
ORDER BY DCT.ChampionshipTypeID;
```

### 8.3 Find all public championships
```sql
SELECT  CC.*
FROM    Championship.Championship CC WITH (NOLOCK)
WHERE   CC.ChampionshipTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ChampionshipType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ChampionshipType.sql*

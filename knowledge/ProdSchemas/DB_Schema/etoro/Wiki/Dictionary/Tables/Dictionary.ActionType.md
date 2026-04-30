# Dictionary.ActionType

> Legacy lookup table defining 16 user activity types — registrations, logins, game sessions, and championship events — from the platform's early social trading/gaming era.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionTypeID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.ActionType classifies user activity events from the platform's early period when eToro included social gaming and championship features alongside trading. Each row represents a type of user action that was tracked for analytics, engagement scoring, and activity logging.

The table predates the current trading-focused platform architecture. Many values reference "Game" concepts (Join Game, Leave Game, Play Game, End Game, Start Game) and "Championship" events (Reg Champ, Win Champ) that reflect eToro's original social trading gamification model. The ActionTypeID=0 "NULL" entry serves as a default/unknown placeholder.

Referenced by Customer.PostRegisterOperations and Customer.RegisterDemo for tracking registration events. The char(50) data type on Name (fixed-width, padded with spaces) is a legacy artifact — modern Dictionary tables use varchar.

---

## 2. Business Logic

### 2.1 Activity Type Categories

**What**: Classification of user activities tracked by the platform.

**Columns/Parameters Involved**: `ActionTypeID`, `Name`

**Rules**:
- **Registration events (1, 2, 15)**: Registration Real (1), Registration Demo (2), Registration IB (15) — tracks how a user joined the platform (real account, demo, or introducing broker)
- **Session events (3, 4)**: Login (3), Logout (4) — user session start and end
- **Game lifecycle (5-8, 11-14)**: Join Game (5), Leave Game (6), Play Game (7), End Game (8), Start Game (11), Leave Game with open positions (12), Leave Game with open games (13), Session auto close (14) — legacy social trading game session tracking
- **Championship events (9, 10)**: Reg Champ (9), Win Champ (10) — championship tournament participation
- **Null/Unknown (0)**: NULL — default placeholder for unclassified actions

**Diagram**:
```
User Activity Tracking:

  Registration           Session          Game (Legacy)        Championship
  ────────────           ───────          ────────────         ────────────
  1 = Real               3 = Login        5 = Join Game        9 = Reg Champ
  2 = Demo               4 = Logout       6 = Leave Game      10 = Win Champ
 15 = IB                                  7 = Play Game
                                          8 = End Game
                                         11 = Start Game
                                         12 = Leave w/positions
                                         13 = Leave w/games
                                         14 = Auto close
```

---

## 3. Data Overview

| ActionTypeID | Name | Meaning |
|---|---|---|
| 0 | NULL | Default/unknown action type placeholder. Used when the specific action type is not applicable or was not recorded. |
| 1 | Registration Real | User created a real money trading account. Triggers KYC requirements, compliance review, and CRM sync. |
| 3 | Login | User authenticated and started a platform session. Used for session tracking, security monitoring, and activity metrics. |
| 5 | Join Game | Legacy: user entered a social trading game room. Part of eToro's original gamified trading model where users competed in virtual trading games. |
| 15 | Registration IB | User registered through an Introducing Broker partner. Triggers affiliate commission tracking and special onboarding flows. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTypeID | int | NO | - | CODE-BACKED | Primary key identifying the activity type. 0=NULL/Unknown, 1=Registration Real, 2=Registration Demo, 3=Login, 4=Logout, 5-14=Game/Championship events, 15=Registration IB. Referenced by Customer.PostRegisterOperations and Customer.RegisterDemo for registration tracking. |
| 2 | Name | char(50) | NO | - | CODE-BACKED | Fixed-width human-readable name (padded with spaces). Legacy data type — modern tables use varchar. Unique index enforced (DACP_NAME). Trim trailing spaces when displaying. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.PostRegisterOperations | ActionTypeID | Implicit | Sets registration action type during post-registration processing |
| Customer.RegisterDemo | ActionTypeID | Implicit | Tracks demo registration events |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.PostRegisterOperations | Stored Procedure | Reader — registration event tracking |
| Customer.RegisterDemo | Stored Procedure | Reader — demo registration tracking |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DACP | CLUSTERED PK | ActionTypeID ASC | - | - | Active (FILLFACTOR 90) |
| DACP_NAME | NC UNIQUE | Name ASC | - | - | Active (FILLFACTOR 90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DACP | PRIMARY KEY | Unique action type identifier |
| DACP_NAME | UNIQUE INDEX | Prevents duplicate action type names |

---

## 8. Sample Queries

### 8.1 List all action types
```sql
SELECT  ActionTypeID,
        RTRIM(Name) AS Name
FROM    Dictionary.ActionType WITH (NOLOCK)
ORDER BY ActionTypeID;
```

### 8.2 Find registration-related action types
```sql
SELECT  ActionTypeID,
        RTRIM(Name) AS Name
FROM    Dictionary.ActionType WITH (NOLOCK)
WHERE   RTRIM(Name) LIKE 'Registration%';
```

### 8.3 Categorize action types
```sql
SELECT  ActionTypeID,
        RTRIM(Name) AS Name,
        CASE
            WHEN ActionTypeID IN (1, 2, 15)  THEN 'Registration'
            WHEN ActionTypeID IN (3, 4)      THEN 'Session'
            WHEN ActionTypeID IN (5,6,7,8,11,12,13,14) THEN 'Game (Legacy)'
            WHEN ActionTypeID IN (9, 10)     THEN 'Championship'
            ELSE 'Other'
        END AS Category
FROM    Dictionary.ActionType WITH (NOLOCK)
ORDER BY ActionTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ActionType.sql*

# History.Championship

> Complete archive of all trading championships that have run - inserted at championship start with setup snapshot, updated at end with CompletionStatus and Result.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ChampionshipID - int PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 5 active (1 PK clustered + 4 nonclustered on FK columns) |

---

## 1. Business Meaning

History.Championship is the permanent record of every trading championship that has ever run on eToro's game platform. A championship is a time-bounded trading competition where customers play trading games (Horse Race, Car Race, Forex Marathon, Dollar Trend, Globe Trader, etc.) against each other and compete for prizes.

**Lifecycle**:
- **Championship.ChampionshipStart**: Creates the row with a full snapshot of the championship setup (ChampionshipTypeID, GameTypeID, GameServerID, PrizeTypeID, dates, prize structure, player limits) and CompletionStatus=NULL.
- **Championship.ChampionshipEnd**: Updates the row with CompletionStatus, Result, and EndDateTime when the championship concludes.

The row is immutable at start time except for the three end-state columns (CompletionStatus, Result, EndDateTime). This design preserves the exact setup parameters that were active when the championship ran, regardless of subsequent changes to Championship.Championship.

267 rows spanning 2012 (all from the game platform era). The gaming feature has been inactive in production for many years; the last championship in this environment ended in 2012.

---

## 2. Business Logic

### 2.1 Championship Start Snapshot

**What**: On championship start, a full snapshot of the setup is captured here.

**Columns/Parameters Involved**: All columns except CompletionStatus, Result, EndDateTime

**Rules**:
- Inserted by Championship.ChampionshipStart when a championship cycle begins
- ChampionshipID is assigned by Internal.GetChampionshipID
- CompletionStatus=NULL, Result=NULL, EndDateTime=NULL at insert time
- StartDateTime reflects the actual wall-clock time the championship started

### 2.2 Championship End Update

**What**: On championship end, the result is written here.

**Columns/Parameters Involved**: `CompletionStatus`, `Result`, `EndDateTime`

**Rules**:
- Updated by Championship.ChampionshipEnd(@ChampionshipID, @Result, @CompletionStatus)
- EndDateTime = GETDATE() at end time
- Result (varchar 500) = serialized result data (rankings, scores, or error description)
- CompletionStatus values (observed in data):
  - NULL: championship in progress or never formally ended
  - 0: completed normally (229 rows - most common)
  - 2: non-standard completion (1 row)
  - 3: alternative completion type (28 rows)

### 2.3 WinPayoff Configuration

WinPayoff (varchar 4096) stores a comma-separated prize list consumed by Internal.ConvertListToTable() during auto-payoff processing. Each element is a monetary amount corresponding to a ranking position: position 1 gets WinPayoff[1], position 2 gets WinPayoff[2], etc.

### 2.4 Redundant Datetime Fields

StartYear/Month/Day/Hour/Minute and EndYear/Month/Day/Hour/Minute duplicate StartDateTime and EndDateTime as separate integer components. This is a legacy pattern likely used by game clients that could not parse datetime natively.

---

## 3. Data Overview

| ChampionshipID | ChampionshipTypeID | GameTypeID | PrizeTypeID | StartDateTime | EndDateTime | CompletionStatus |
|---------------|--------------------|-----------|-------------|--------------|------------|-----------------|
| 270 | 1 (Public) | 0 (NULL) | 1 (Fix) | 2012-02-26 | 2012-03-04 | 0 (Completed) |
| 268 | 1 (Public) | 0 (NULL) | 1 (Fix) | 2012-02-12 | 2012-02-19 | 0 (Completed) |

267 rows total | Data from 2012 | All ChampionshipTypeID=1 (Public) in observed sample | All PrizeTypeID=1 (Fix) | Gaming feature now inactive.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChampionshipID | int | NO | - | VERIFIED | Unique identifier for this championship run. Assigned by Internal.GetChampionshipID at start. PK. Shared between History.Championship and History.ChampionshipPlayer to link players to their championship. |
| 2 | ChampionshipSetupID | int | NO | 0 | VERIFIED | ID of the setup template in Championship.Championship from which this championship was launched. Links to ChampionshipSetupAdd configuration. DEFAULT=0. |
| 3 | ChampionshipTypeID | int | NO | 0 | VERIFIED | Type of championship. FK to Dictionary.ChampionshipType. Values: 0=NULL, 1=Public, 2=Private. DEFAULT=0. |
| 4 | GameTypeID | int | NO | 0 | VERIFIED | The game type played in this championship. FK to Dictionary.GameType. Values: 0=NULL, 1=Horse Race, 2=Car Race, 3=Forex Marathon, 4=Dollar Trend, 11=Slot, 21=Poker, 31=Globe Trader, 32=IB Trades, 33=Trade Box, 34=eToro Trading, 41=Race Pro, 51/52=Forex Charts. DEFAULT=0. |
| 5 | GameServerID | int | NO | 0 | VERIFIED | Game server that hosted this championship. FK to Dictionary.GameServer. Values: 0=Unknown, 1=GAME1. DEFAULT=0. |
| 6 | PrizeTypeID | int | NO | 0 | VERIFIED | How prizes are calculated. FK to Dictionary.PrizeType. Values: 0=Unknown, 1=Fix (fixed amounts), 2=Percent (% of pot), 3=Product. DEFAULT=0. |
| 7 | StartDateTime | datetime | YES | - | VERIFIED | Wall-clock datetime when the championship started. Set by Championship.ChampionshipStart = GETDATE(). |
| 8 | DurationType | int | NO | - | CODE-BACKED | Encoded championship duration. Not a FK to a Dictionary table - values managed in game server logic. |
| 9 | PlayerBet | int | NO | - | CODE-BACKED | Amount each player bets/pays to enter (in game credits). Part of the prize pool economics. |
| 10 | CompanyBetToPlayer | int | NO | - | CODE-BACKED | Company-funded contribution per player to the prize pool. Part of the prize pool economics. |
| 11 | InitCredit | int | NO | - | CODE-BACKED | Initial trading credit allocated to each player at championship start (virtual trading capital). |
| 12 | MinPlayers | int | NO | - | CODE-BACKED | Minimum number of players required for the championship to be valid. 0 = no minimum. |
| 13 | MaxPlayers | int | NO | - | CODE-BACKED | Maximum player capacity. 0 = unlimited. |
| 14 | StartYear | int | NO | - | CODE-BACKED | Year component of scheduled start time. Redundant with StartDateTime - legacy client support. |
| 15 | StartMonth | int | NO | - | CODE-BACKED | Month component of scheduled start time. |
| 16 | StartDay | tinyint | NO | - | CODE-BACKED | Day component of scheduled start time. |
| 17 | StartHour | tinyint | NO | - | CODE-BACKED | Hour component of scheduled start time. |
| 18 | StartMinute | tinyint | NO | - | CODE-BACKED | Minute component of scheduled start time. |
| 19 | EndYear | int | NO | - | CODE-BACKED | Year component of scheduled end time. Redundant with EndDateTime. |
| 20 | EndMonth | int | NO | - | CODE-BACKED | Month component of scheduled end time. |
| 21 | EndDay | tinyint | NO | - | CODE-BACKED | Day component of scheduled end time. |
| 22 | EndHour | tinyint | NO | - | CODE-BACKED | Hour component of scheduled end time. |
| 23 | EndMinute | tinyint | NO | - | CODE-BACKED | Minute component of scheduled end time. |
| 24 | WinPayoff | varchar(4096) | NO | - | CODE-BACKED | Comma-separated prize amounts by ranking position. Parsed by Internal.ConvertListToTable() during auto-payoff. Format: "amount1,amount2,...". |
| 25 | IsAutoPayoff | bit | NO | - | VERIFIED | Whether winners are automatically paid out when championship ends (1) or require manual approval (0). Controls Championship.ChampionshipEnd auto-payoff path. |
| 26 | MaxGames | int | NO | - | CODE-BACKED | Maximum number of individual game rounds allowed per player. 0 = unlimited. |
| 27 | CompletionStatus | int | YES | - | CODE-BACKED | Final state of the championship. NULL=in progress/no formal end; 0=completed normally (229/267 rows); 2=non-standard end (1 row); 3=alternative completion (28 rows). Values passed from caller to Championship.ChampionshipEnd. |
| 28 | Result | varchar(500) | YES | - | CODE-BACKED | Serialized result data from Championship.ChampionshipEnd. Contains final rankings or completion details. NULL until end. |
| 29 | EndDateTime | datetime | YES | - | VERIFIED | Wall-clock datetime when the championship ended. Set by Championship.ChampionshipEnd = GETDATE(). NULL until end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ChampionshipTypeID | Dictionary.ChampionshipType | FK (FK_TDCPT_TSCMP) | Type: 0=NULL, 1=Public, 2=Private. |
| GameTypeID | Dictionary.GameType | FK (FK_TDGMT_TSCMP) | Game format played (Horse Race, Forex Marathon, etc.). |
| GameServerID | Dictionary.GameServer | FK (FK_TDGMS_TSCMP) | Game server that ran this championship. |
| PrizeTypeID | Dictionary.PrizeType | FK (FK_TDPZT_TSCMP) | Prize calculation method: Fix/Percent/Product. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Championship.ChampionshipStart | ChampionshipID | Writer | Inserts the snapshot row at championship start. |
| Championship.ChampionshipEnd | ChampionshipID | Writer/Reader | Updates completion fields; reads WinPayoff for auto-payoff processing. |
| History.ChampionshipPlayer | ChampionshipID | Child | Player participation records reference this championship. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Championship (table)
  -> Dictionary.ChampionshipType (FK)
  -> Dictionary.GameType (FK)
  -> Dictionary.GameServer (FK)
  -> Dictionary.PrizeType (FK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ChampionshipType | Table | FK lookup for championship type |
| Dictionary.GameType | Table | FK lookup for game type |
| Dictionary.GameServer | Table | FK lookup for game server |
| Dictionary.PrizeType | Table | FK lookup for prize calculation method |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Championship.ChampionshipStart | Stored Procedure | Writer - inserts championship snapshot at start |
| Championship.ChampionshipEnd | Stored Procedure | Writer/Reader - updates completion state; reads WinPayoff |
| History.ChampionshipPlayer | Table | Child table - players reference this championship |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HCMS | CLUSTERED PK | ChampionshipID ASC | - | - | Active |
| HCMS_CHAMPTYPE | NONCLUSTERED | ChampionshipTypeID ASC | - | - | Active |
| HCMS_GAMESERVER | NONCLUSTERED | GameServerID ASC | - | - | Active |
| HCMS_GAMETYPE | NONCLUSTERED | GameTypeID ASC | - | - | Active |
| HCMS_PRIZETYPE | NONCLUSTERED | PrizeTypeID ASC | - | - | Active |

All indexes: FILLFACTOR=90, on [HISTORY] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCMS | PRIMARY KEY CLUSTERED | ChampionshipID, FILLFACTOR=90 |
| FK_TDCPT_TSCMP | FOREIGN KEY | ChampionshipTypeID -> Dictionary.ChampionshipType |
| FK_TDGMS_TSCMP | FOREIGN KEY | GameServerID -> Dictionary.GameServer |
| FK_TDGMT_TSCMP | FOREIGN KEY | GameTypeID -> Dictionary.GameType |
| FK_TDPZT_TSCMP | FOREIGN KEY | PrizeTypeID -> Dictionary.PrizeType |
| HCMS_NULLCHAMPIONSHIPSETUP | DEFAULT | ChampionshipSetupID = 0 |
| HCMS_NULLCHAMPIONSHIPTYPE | DEFAULT | ChampionshipTypeID = 0 |
| HCMS_NULLGAMETYPE | DEFAULT | GameTypeID = 0 |
| HCMS_NULLGAMESERVER | DEFAULT | GameServerID = 0 |
| HCMS_NULLPRIZETYPE | DEFAULT | PrizeTypeID = 0 |

---

## 8. Sample Queries

### 8.1 Get all championships with their type and prize info
```sql
SELECT h.ChampionshipID, h.StartDateTime, h.EndDateTime,
       ct.Name AS ChampionshipType, gt.Name AS GameType, pt.Name AS PrizeType,
       h.CompletionStatus, h.MaxPlayers, h.InitCredit
FROM History.Championship h WITH (NOLOCK)
INNER JOIN Dictionary.ChampionshipType ct ON h.ChampionshipTypeID = ct.ChampionshipTypeID
INNER JOIN Dictionary.GameType gt ON h.GameTypeID = gt.GameTypeID
INNER JOIN Dictionary.PrizeType pt ON h.PrizeTypeID = pt.PrizeTypeID
ORDER BY h.StartDateTime DESC;
```

### 8.2 Get all players for a championship
```sql
SELECT p.CID, p.ChampProfit, p.WinPos, p.PayOff
FROM History.ChampionshipPlayer p WITH (NOLOCK)
WHERE p.ChampionshipID = 270
ORDER BY p.WinPos;
```

### 8.3 Championship completion summary
```sql
SELECT CompletionStatus, COUNT(*) AS Total
FROM History.Championship WITH (NOLOCK)
GROUP BY CompletionStatus
ORDER BY CompletionStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Championship | Type: Table | Source: etoro/etoro/History/Tables/History.Championship.sql*

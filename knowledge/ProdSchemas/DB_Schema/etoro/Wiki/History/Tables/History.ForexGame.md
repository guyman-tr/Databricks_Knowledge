# History.ForexGame

> Application-managed SCD Type 2 audit log for Game.ForexGame, recording each version of a ForexGame configuration with ValidFrom/ValidTo validity windows - a legacy gaming system where customers participated in simulated forex trading tournaments.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PK_HFXG: CLUSTERED on ForexGameVersionID (IDENTITY) |
| **Partition** | No (stored on [HISTORY] filegroup) |
| **Indexes** | 6 (1 CLUSTERED PK + 5 NONCLUSTERED, all FILLFACTOR=90) |

---

## 1. Business Meaning

This table is an application-managed SCD (Slowly Changing Dimension) Type 2 history log for `Game.ForexGame`. Unlike most History schema tables, it does NOT use SQL Server system-versioning (SYSTEM_VERSIONING = ON). Instead, ValidFrom/ValidTo datetime columns track version validity with application-controlled timestamps.

`Game.ForexGame` stores configuration for eToro's ForexGame system - a legacy trading tournament feature where customers could participate in simulated forex trading competitions. Each game had a primary currency pair, a scheduled run window (day-of-week + hour/minute start and end), player limits, betting amounts, and multi-round configuration. When a game configuration changes, the previous version is preserved here with ValidTo set to the change time, and a new row is added with ValidFrom = change time.

The table is empty in this environment, indicating no ForexGame configuration changes have been tracked. The rich index set (5 nonclustered indexes covering GameTypeID, GameServerID, DurationID, PrimaryCurrencyID, and ForexGameID) reflects the historical read patterns when the feature was active - querying game history by type, server, duration, or currency.

**Note on schema discrepancy**: The current source table `Game.ForexGame` has a `GameSubTypeID` column, while this history table records `GameTypeID`. This reflects a column rename: the history table preserves the original name `GameTypeID` from when the feature was designed, while the source table was later updated to use `GameSubTypeID`. Functionally they reference the same dictionary lookup.

---

## 2. Business Logic

### 2.1 ForexGame Tournament Configuration

**What**: Each row represents one version of a ForexGame definition - the rules for how a specific game runs, when it runs, and how players participate.

**Columns/Parameters Involved**: `ForexGameID`, `GameTypeID`, `GameServerID`, `DurationID`, `PrimaryCurrencyID`, `CurrencySet`, timing columns, player limits, bet/commission parameters

**Rules**:
- ForexGameID is the logical identifier for the game (matches Game.ForexGame.ForexGameID - not IDENTITY in source)
- ForexGameVersionID is the IDENTITY surrogate key that uniquely identifies each version (used as FK in History.ForexGameToInstrument)
- ValidFrom/ValidTo track the application-managed validity window for each game configuration version
- GameTypeID/GameServerID/DurationID/PrimaryCurrencyID all reference Dictionary lookup tables via FKs on the source table
- CurrencySet is a bigint bitmask representing which currency pairs are included in the game (bit field)

### 2.2 Game Scheduling Parameters

**What**: Games are scheduled on a weekly repeating pattern using day-of-week + time fields.

**Columns/Parameters Involved**: `StartDay`, `StartHour`, `StartMinute`, `EndDay`, `EndHour`, `EndMinute`, `SecondsBetweenGames`, `DelayBetweenGamesSec`, `Repeat`

**Rules**:
- StartDay/EndDay: 0-6 representing day of week (0=Sunday or Monday depending on convention)
- StartHour/EndHour: 0-23 (hour of day)
- StartMinute/EndMinute: 0-59 (minute of hour)
- SecondsBetweenGames: delay between consecutive game instances
- DelayBetweenGamesSec: separate delay parameter (purpose similar to SecondsBetweenGames)
- Repeat: number of times the game repeats on its schedule (0 likely = indefinite)

### 2.3 Player Participation and Betting

**What**: Each game has a fixed bet, commission structure, and player count limits defining the tournament economics.

**Columns/Parameters Involved**: `GameBet`, `BreakoutCommission`, `MinPlayers`, `MaxPlayers`, `Rounds`, `StopLostRange`, `TakeProfitRange`

**Rules**:
- GameBet: the bet amount players place to enter the game (in the game's currency)
- BreakoutCommission: eToro's commission percentage (dbo.dtPercentage type) taken from the prize pool
- MinPlayers: minimum players required for the game to start
- MaxPlayers: maximum player cap for the game
- Rounds: number of rounds in the game
- StopLostRange: varchar(50) expressing the stop-loss pip range (e.g., "10-50"), player-selectable within this range
- TakeProfitRange: varchar(50) expressing the take-profit pip range, player-selectable within this range

### 2.4 Application-Managed SCD Type 2 History Pattern

**What**: History records are inserted by application code (not SQL Server triggers) when a ForexGame configuration is modified.

**Columns/Parameters Involved**: `ForexGameVersionID`, `ValidFrom`, `ValidTo`

**Rules**:
- ValidFrom: datetime when this version became active (set by the application)
- ValidTo: datetime when this version was superseded (set when a new version is created); open-ended current rows would use a sentinel value
- ForexGameVersionID is IDENTITY(1,1) NOT FOR REPLICATION - prevents ID re-seeding during database replication scenarios
- History.ForexGameToInstrument.ForexGameVersionID references this table's PK - each game version can have a specific instrument list

---

## 3. Data Overview

| ForexGameVersionID | ForexGameID | GameTypeID | PrimaryCurrencyID | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|
| (empty) | (empty) | (empty) | (empty) | (empty) | (empty) | Table currently has 0 rows. No ForexGame configuration history has been recorded in this environment. The feature may be inactive or history was not seeded. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ForexGameVersionID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK for this version record. Auto-incrementing identity. NOT FOR REPLICATION prevents ID re-seeding during replication. Referenced as FK by History.ForexGameToInstrument to link instrument lists to specific game configuration versions. |
| 2 | ValidFrom | datetime | NO | - | CODE-BACKED | Application-set datetime when this game configuration version became active. Start of the validity window for this version. Set by the application when a new version is created. |
| 3 | ValidTo | datetime | NO | - | CODE-BACKED | Application-set datetime when this version was superseded. End of the validity window. Open-ended (current) versions would use a sentinel value (e.g., '9999-12-31' or similar). Set to the change time when the game configuration is modified. |
| 4 | ForexGameID | int | NO | - | CODE-BACKED | The logical identifier of the game being versioned. Matches Game.ForexGame.ForexGameID (PK in source, not IDENTITY). ForexGameID != 0 is a documented filter (OldStyle.GetForexGame excludes ID=0). Multiple history rows with the same ForexGameID represent successive configuration versions. |
| 5 | GameTypeID | int | NO | - | CODE-BACKED | Game type classification. References Dictionary.GameSubType (note: source table now calls this column GameSubTypeID reflecting a rename after history table was created). Indexed by HFXG_GAMETYPE for history queries by game type. |
| 6 | GameServerID | int | NO | - | CODE-BACKED | The game server hosting this game. References Dictionary.GameServer. Indexed by HFXG_GAMESERVER. Default 0 in source table for unspecified server. |
| 7 | DurationID | int | NO | - | CODE-BACKED | The game duration type. References Dictionary.Duration (which has Interval and IsFixDuration attributes). Indexed by HFXG_DURATION. Default 0 in source table. |
| 8 | PrimaryCurrencyID | int | NO | - | CODE-BACKED | The primary currency pair for this game. References Dictionary.Currency. Players predict the direction (up/down) of this currency. Indexed by HFXG_CURRENCY. Default 0 in source table. |
| 9 | CurrencySet | bigint | NO | - | CODE-BACKED | Bitmask representing the set of currency pairs available in this game. Each bit position corresponds to a currency pair. Used in History.GetForexResult view to reconstruct game parameters for result analysis. |
| 10 | StartDay | tinyint | NO | - | CODE-BACKED | Day of week when the game schedule starts (0-6). Part of the weekly game schedule definition. |
| 11 | StartHour | tinyint | NO | - | CODE-BACKED | Hour of day (0-23) when the game starts on StartDay. |
| 12 | StartMinute | tinyint | NO | - | CODE-BACKED | Minute (0-59) within StartHour when the game starts. |
| 13 | EndDay | tinyint | NO | - | CODE-BACKED | Day of week when the game schedule ends (0-6). |
| 14 | EndHour | tinyint | NO | - | CODE-BACKED | Hour of day (0-23) when the game ends on EndDay. |
| 15 | EndMinute | tinyint | NO | - | CODE-BACKED | Minute (0-59) within EndHour when the game ends. |
| 16 | SecondsBetweenGames | int | NO | - | CODE-BACKED | Number of seconds between consecutive game instances in the schedule. Controls the gap between one game ending and the next starting. |
| 17 | Repeat | int | NO | - | CODE-BACKED | Number of times the game repeats on its scheduled pattern. 0 likely indicates indefinite repeat. |
| 18 | GameBet | int | NO | - | CODE-BACKED | The bet amount (in game currency units) that players place to enter the game. Defines the prize pool size per player entry. |
| 19 | BreakoutCommission | dbo.dtPercentage | NO | - | CODE-BACKED | eToro's commission percentage (user-defined type dtPercentage) deducted from the prize pool. Called "BreakRake" in OldStyle.GetForexGame. |
| 20 | StopLostRange | varchar(50) | NO | - | CODE-BACKED | Expression defining the valid range for player-selected stop-loss levels (e.g., pip range). Players choose their stop-loss within this range during the game. |
| 21 | TakeProfitRange | varchar(50) | NO | - | CODE-BACKED | Expression defining the valid range for player-selected take-profit levels (e.g., pip range). Players choose their take-profit within this range during the game. |
| 22 | MinPlayers | int | NO | - | CODE-BACKED | Minimum number of players required for the game to start. If fewer players join by start time, the game may be cancelled. |
| 23 | MaxPlayers | int | NO | - | CODE-BACKED | Maximum player capacity for the game. Prevents over-subscription. |
| 24 | Rounds | int | NO | - | CODE-BACKED | Number of rounds in this game. Multi-round games track progress across rounds. |
| 25 | DelayBetweenGamesSec | int | NO | - | CODE-BACKED | Additional delay in seconds between game rounds or instances. Distinct from SecondsBetweenGames - may apply to intra-game delays between rounds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ForexGameID | Game.ForexGame | Implicit | Logical FK back to the source game configuration (no FK constraint). |
| GameTypeID | Dictionary.GameSubType | Implicit | Game type lookup (column renamed in source to GameSubTypeID). FK enforced on source table, not on history. |
| GameServerID | Dictionary.GameServer | Implicit | Game server lookup. FK enforced on source table. |
| DurationID | Dictionary.Duration | Implicit | Game duration type lookup. FK enforced on source table. |
| PrimaryCurrencyID | Dictionary.Currency | Implicit | Primary currency pair lookup. FK enforced on source table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [History.ForexGameToInstrument](History.ForexGameToInstrument.md) | ForexGameVersionID | Explicit FK | Links specific instrument assignments to a particular game configuration version. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ForexGame (table)
- no code-level dependencies (leaf table, application-managed history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ForexGameToInstrument | Table | FK: ForexGameVersionID links instrument assignments to specific game versions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HFXG | CLUSTERED | ForexGameVersionID ASC | - | - | Active (FILLFACTOR=90, on [HISTORY] filegroup) |
| HFXG_CURRENCY | NONCLUSTERED | PrimaryCurrencyID ASC | - | - | Active (FILLFACTOR=90, on [HISTORY] filegroup) |
| HFXG_DURATION | NONCLUSTERED | DurationID ASC | - | - | Active (FILLFACTOR=90, on [HISTORY] filegroup) |
| HFXG_GAMESERVER | NONCLUSTERED | GameServerID ASC | - | - | Active (FILLFACTOR=90, on [HISTORY] filegroup) |
| HFXG_GAMETYPE | NONCLUSTERED | GameTypeID ASC | - | - | Active (FILLFACTOR=90, on [HISTORY] filegroup) |
| HFXG_ID | NONCLUSTERED | ForexGameID ASC | ForexGameVersionID | - | Active (FILLFACTOR=90, on [HISTORY] filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HFXG | CLUSTERED PK | ForexGameVersionID - identity-based version surrogate key |

---

## 8. Sample Queries

### 8.1 Full version history for a specific game

```sql
SELECT
    h.ForexGameVersionID,
    h.ForexGameID,
    h.GameTypeID,
    h.GameServerID,
    h.PrimaryCurrencyID,
    h.ValidFrom,
    h.ValidTo,
    DATEDIFF(DAY, h.ValidFrom, h.ValidTo) AS DaysActive
FROM History.ForexGame h WITH (NOLOCK)
WHERE h.ForexGameID = @ForexGameID
ORDER BY h.ValidFrom;
```

### 8.2 What game configuration was active on a specific date?

```sql
SELECT
    h.ForexGameVersionID,
    h.ForexGameID,
    h.GameTypeID,
    h.PrimaryCurrencyID,
    h.GameBet,
    h.MinPlayers,
    h.MaxPlayers,
    h.ValidFrom,
    h.ValidTo
FROM History.ForexGame h WITH (NOLOCK)
WHERE h.ForexGameID = @ForexGameID
  AND h.ValidFrom <= @AsOfDate
  AND h.ValidTo > @AsOfDate;
```

### 8.3 All game versions with their instrument lists

```sql
SELECT
    hfg.ForexGameVersionID,
    hfg.ForexGameID,
    hfg.GameTypeID,
    hfg.PrimaryCurrencyID,
    hfg.ValidFrom,
    hfg.ValidTo,
    hfgi.InstrumentID
FROM History.ForexGame hfg WITH (NOLOCK)
JOIN History.ForexGameToInstrument hfgi WITH (NOLOCK)
    ON hfgi.ForexGameVersionID = hfg.ForexGameVersionID
ORDER BY hfg.ForexGameID, hfg.ValidFrom, hfgi.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Game.GameOpen, OldStyle.GetForexGame) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ForexGame | Type: Table | Source: etoro/etoro/History/Tables/History.ForexGame.sql*

# History.ForexGameToInstrument

> Versioned junction table linking specific ForexGame configuration versions to the instrument versions they include, recording the instrument set for each historical game configuration snapshot.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PK_GFGI: CLUSTERED on (ForexGameVersionID, InstrumentVersionID) |
| **Partition** | No (stored on [HISTORY] filegroup) |
| **Indexes** | 1 (CLUSTERED PK, FILLFACTOR=90) |

---

## 1. Business Meaning

This table is the historical version of `Game.ForexGameToInstrument`, linking ForexGame configuration versions to the specific instrument versions that were included in each game.

`Game.ForexGameToInstrument` is a simple junction table linking a `ForexGameID` to an `InstrumentID`, defining which instruments (currency pairs) are available for trading in each game. The History version uses versioned surrogate keys on both sides: `ForexGameVersionID` (from `History.ForexGame`) and `InstrumentVersionID` (a versioned instrument reference). This allows precise reconstruction of exactly which instruments were in a game at a specific point in time, even if both the game configuration and the instrument definition have subsequently changed.

The table has 0 rows in this environment, consistent with History.ForexGame also being empty - both are part of the legacy ForexGame tournament system.

---

## 2. Business Logic

### 2.1 Version-to-Version Junction Pattern

**What**: Both sides of the junction use version IDs (not the current logical IDs), enabling point-in-time reconstruction of exact game-instrument combinations.

**Rules**:
- ForexGameVersionID references History.ForexGame.ForexGameVersionID - the specific game configuration version
- InstrumentVersionID references a versioned instrument record - linking to the instrument as it was defined at that time (not the current instrument)
- Composite PK (ForexGameVersionID, InstrumentVersionID) ensures each instrument appears once per game version
- ValidFrom/ValidTo track when this particular game-instrument linkage was valid
- Source Game.ForexGameToInstrument uses the current logical IDs (ForexGameID, InstrumentID); this history table elevates both to versioned surrogate keys

### 2.2 Instrument List Reconstruction

**What**: The full instrument set for a ForexGame version can be queried by joining to History.ForexGame on ForexGameVersionID.

**Rules**:
- Views like OldStyle.GetForexGameInstrumentList and Internal.GetInstrumentList(ForexGameID) reconstruct the instrument list for a game
- History.GetForexResult reads Game.ForexGame (current, not history) for game parameters
- Historical instrument list reconstruction requires joining History.ForexGame -> History.ForexGameToInstrument

---

## 3. Data Overview

| ForexGameVersionID | InstrumentVersionID | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|
| (empty) | (empty) | (empty) | (empty) | Table currently has 0 rows. No ForexGame instrument assignment history recorded in this environment. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ForexGameVersionID | int | NO | - | CODE-BACKED | FK to History.ForexGame.ForexGameVersionID. Identifies the specific game configuration version that included this instrument. Part of the composite PK. |
| 2 | InstrumentVersionID | int | NO | - | CODE-BACKED | Versioned instrument identifier. References a specific instrument version (the instrument as it was defined at that point in time). Part of the composite PK. Corresponds to InstrumentID in the current source Game.ForexGameToInstrument. |
| 3 | ValidFrom | datetime | NO | - | CODE-BACKED | Application-set datetime when this game-instrument linkage became active. |
| 4 | ValidTo | datetime | NO | - | CODE-BACKED | Application-set datetime when this linkage was superseded. Sentinel value for open-ended (currently active) linkages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ForexGameVersionID | [History.ForexGame](History.ForexGame.md) | Explicit FK via PK_GFGI | Links to the game configuration version that owns this instrument set. |
| InstrumentVersionID | History.Instrument (implicit) | Implicit | Versioned instrument reference. No FK constraint in history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Game.ForexGameToInstrument | - | Application history source | Current junction table whose historical versions are tracked here via application-managed SCD pattern. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ForexGameToInstrument (table)
-> History.ForexGame (FK: ForexGameVersionID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ForexGame | Table | ForexGameVersionID FK - identifies the game configuration version |

### 6.2 Objects That Depend On This

No objects directly depend on this history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_GFGI | CLUSTERED | ForexGameVersionID ASC, InstrumentVersionID ASC | - | - | Active (FILLFACTOR=90, on [HISTORY] filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_GFGI | CLUSTERED PK | (ForexGameVersionID, InstrumentVersionID) - one instrument per game version |

---

## 8. Sample Queries

### 8.1 All instruments for a specific game configuration version

```sql
SELECT
    fgi.ForexGameVersionID,
    fgi.InstrumentVersionID,
    fgi.ValidFrom,
    fgi.ValidTo
FROM History.ForexGameToInstrument fgi WITH (NOLOCK)
WHERE fgi.ForexGameVersionID = @ForexGameVersionID
ORDER BY fgi.InstrumentVersionID;
```

### 8.2 Instrument list for a game as of a specific date

```sql
SELECT
    fg.ForexGameID,
    fg.ForexGameVersionID,
    fg.PrimaryCurrencyID,
    fgi.InstrumentVersionID,
    fg.ValidFrom AS GameVersionFrom,
    fg.ValidTo AS GameVersionTo
FROM History.ForexGame fg WITH (NOLOCK)
JOIN History.ForexGameToInstrument fgi WITH (NOLOCK)
    ON fgi.ForexGameVersionID = fg.ForexGameVersionID
WHERE fg.ForexGameID = @ForexGameID
  AND fg.ValidFrom <= @AsOfDate
  AND fg.ValidTo > @AsOfDate
ORDER BY fgi.InstrumentVersionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ForexGameToInstrument | Type: Table | Source: etoro/etoro/History/Tables/History.ForexGameToInstrument.sql*

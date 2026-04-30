# Dictionary.GameServer

> Configuration table defining the trading/game server instances — their network addresses, server types, and online status — used for server routing and championship/game platform management.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | GameServerID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 3 active (PK + unique Name + ServerTypeID NC) |

---

## 1. Business Meaning

Dictionary.GameServer stores the network configuration for eToro's trading server instances. Despite the "Game" prefix (a legacy from eToro's early days as a gamified trading platform), these servers handle real trading operations. Each server entry defines a network endpoint (IP + port), its server type classification, and whether it is currently online.

This table exists because eToro's trading infrastructure runs across multiple server instances, each potentially handling different instrument types or geographical regions. The system needs to know which servers are available, what type of trading they handle, and how to connect to them. The Championship and Game tables reference GameServerID to record which server hosted a particular trading competition or game session.

GameServerID is referenced by Championship.Championship, Game.ForexGame, History.Championship, and the History.GetPositionInfo view. The table has an FK to Dictionary.ServerType, which classifies the server role.

---

## 2. Business Logic

### 2.1 Server Configuration Model

**What**: Each server instance has a unique identity, network address, type classification, and availability status.

**Columns/Parameters Involved**: `GameServerID`, `ServerTypeID`, `Name`, `Port`, `IP`, `IsOnline`

**Rules**:
- GameServerID 0 ("Unknown") is a fallback entry with loopback IP 127.0.0.1 and IsOnline=false — used when the actual server is not identified
- Real server entries have IsOnline=true and valid internal network IPs
- Default port is 6010, but can be overridden per server
- ServerTypeID links to Dictionary.ServerType to classify the server's role
- The Passport column (timestamp) provides row-level concurrency tracking

**Diagram**:
```
Dictionary.GameServer
├── ServerTypeID → Dictionary.ServerType (server role classification)
├── IP:Port → Network endpoint for client connections
├── IsOnline → Availability flag for routing decisions
└── Referenced by:
    ├── Championship.Championship (which server hosts the competition)
    ├── Game.ForexGame (which server runs the game)
    └── History.GetPositionInfo (server context in position history)
```

---

## 3. Data Overview

| GameServerID | Name | ServerTypeID | IP | Port | IsOnline | Meaning |
|---|---|---|---|---|---|---|
| 0 | Unknown | 0 | 127.0.0.1 | 0 | false | Fallback server entry for unidentified server contexts. Loopback address with no active port — never actually connected to. Used as a default when the originating server cannot be determined. |
| 1 | GAME1 | 5 | 192.168.10.204 | 6000 | true | Primary trading server instance on the internal network. ServerType 5 indicates its operational role. Active and accepting connections on port 6000. Referenced by game and championship records as the hosting server. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GameServerID | int | NO | - | VERIFIED | Primary key identifying the server instance. 0=Unknown (fallback). Referenced by Championship.Championship, Game.ForexGame, and History tables to record which server hosted a trading session or competition. |
| 2 | ServerTypeID | int | NO | 0 | VERIFIED | FK to Dictionary.ServerType classifying the server's operational role. Defaults to 0 (Unknown). Determines what type of trading/game operations this server handles. |
| 3 | Name | char(50) | NO | - | VERIFIED | Unique human-readable server name (e.g., "GAME1"). Fixed-width char(50). Used in server management, monitoring, and audit logs. Enforced unique via DGMS_NAME index. |
| 4 | Port | int | NO | 6010 | VERIFIED | Network port for client connections to this server. Defaults to 6010 — the standard eToro trading server port. Override per server when non-standard ports are needed. |
| 5 | IP | varchar(15) | NO | - | VERIFIED | IPv4 address of the server on the internal network. Used for routing trading connections. The "Unknown" server uses 127.0.0.1 (loopback) as a safe fallback. |
| 6 | IsOnline | bit | NO | - | VERIFIED | Server availability flag. 1=online and accepting connections, 0=offline or decommissioned. Used by routing logic to exclude offline servers from active service. The Unknown server (ID 0) is permanently offline. |
| 7 | Passport | timestamp | NO | - | VERIFIED | SQL Server rowversion/timestamp column for optimistic concurrency control. Automatically updated on each row modification. Named "Passport" as a legacy convention. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ServerTypeID | Dictionary.ServerType | FK | Classifies the server by its operational role |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Championship.Championship | GameServerID | Implicit Lookup | Records which server hosts a trading competition |
| Game.ForexGame | GameServerID | Implicit Lookup | Records which server runs a game session |
| History.Championship | GameServerID | Implicit Lookup | Historical championship records reference hosting server |
| History.GetPositionInfo | GameServerID | JOIN | Position history view includes server context |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (FK to ServerType is a simple lookup).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ServerType | Table | FK — classifies server by operational role |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Championship.Championship | Table | References GameServerID for competition hosting |
| Game.ForexGame | Table | References GameServerID for game session hosting |
| History.Championship | Table | Historical competition server reference |
| History.GetPositionInfo | View | JOINs for server context in position history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DGMS | CLUSTERED PK | GameServerID ASC | - | - | Active |
| DGMS_NAME | UNIQUE NC | Name ASC | - | - | Active |
| DGMS_SERVERTYPE | NONCLUSTERED | ServerTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DGMS | PRIMARY KEY | Unique server identifier |
| DGMS_NAME | UNIQUE INDEX | Each server has a unique name |
| DGMS_NULLSERVERTYPE | DEFAULT | ServerTypeID defaults to 0 |
| TDGMS_PORT | DEFAULT | Port defaults to 6010 |
| FK_TDSVT_TDGSV | FOREIGN KEY | ServerTypeID → Dictionary.ServerType.ServerTypeID |

---

## 8. Sample Queries

### 8.1 List all servers with their types
```sql
SELECT  gs.GameServerID,
        RTRIM(gs.Name)      AS ServerName,
        gs.IP,
        gs.Port,
        gs.IsOnline,
        st.ServerTypeName
FROM    [Dictionary].[GameServer] gs WITH (NOLOCK)
LEFT JOIN [Dictionary].[ServerType] st WITH (NOLOCK)
        ON gs.ServerTypeID = st.ServerTypeID
ORDER BY gs.GameServerID;
```

### 8.2 Find online servers only
```sql
SELECT  GameServerID,
        RTRIM(Name) AS ServerName,
        IP,
        Port
FROM    [Dictionary].[GameServer] WITH (NOLOCK)
WHERE   IsOnline = 1
ORDER BY GameServerID;
```

### 8.3 Count championships hosted per server
```sql
SELECT  RTRIM(gs.Name)  AS ServerName,
        COUNT(*)        AS ChampionshipCount
FROM    [Championship].[Championship] c WITH (NOLOCK)
JOIN    [Dictionary].[GameServer] gs WITH (NOLOCK)
        ON c.GameServerID = gs.GameServerID
GROUP BY RTRIM(gs.Name)
ORDER BY ChampionshipCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GameServer | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.GameServer.sql*

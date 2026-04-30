# Billing.DepotValue

> Per-depot key-value configuration store. Each row stores a specific parameter value for a (depot, parameter, mode) combination using sql_variant. 126 configuration entries covering depot API credentials, account emails, card type lists, and other protocol-specific settings for Live and Demo modes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (DepotID, ParameterID, DepotModeID) - PRIMARY KEY CLUSTERED |
| **Row Count** | 126 rows |
| **Partition** | N/A - filegroup PRIMARY |
| **Indexes** | 1 CLUSTERED composite PK (FILLFACTOR=97) |

---

## 1. Business Meaning

`Billing.DepotValue` is a flexible key-value store for per-depot protocol configuration. Rather than adding a new column to `Billing.Depot` for every payment gateway setting, this table stores parameter values as `sql_variant`, keyed by (DepotID, ParameterID, DepotModeID). This allows each depot to have different values for Live vs Demo environments (mode separation).

Stored values include:
- Email addresses (e.g., mbusd@etoro.com for depot 1, ParameterID=4, Live)
- Card type lists (e.g., "WLT,JCB,DIN,AMX,CSI,MAE,GCB,EBT,SO2,SLO,VSD,VSE,PSP" for ParameterID=10)
- MID/account numbers (e.g., "5075493" for ParameterID=29)
- API credentials/usernames (e.g., "usssjedan" for ParameterID=34)
- Base64-encoded authorization headers (ParameterID=158)

The separation between `Billing.DepotValue` (general per-depot parameters) and `Billing.ProtocolMIDSettings` (regulation+currency-specific MID routing) is: DepotValue stores depot-level defaults/credentials, while ProtocolMIDSettings stores the per-regulation-per-currency MID routing table.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) [implicit] | [CODE-BACKED] Payment depot; part of composite PK. No explicit FK constraint defined. |
| **ParameterID** | int | NOT NULL | - | Billing.Parameter(ParameterID) [implicit] | [CODE-BACKED] Parameter type; part of composite PK. Defines what this value represents (email, card list, MID, etc.). |
| **Value** | sql_variant | NULL | - | - | [CODE-BACKED] The parameter value. Type varies by parameter: VARCHAR for emails/strings, INT for numeric IDs, etc. Stored as sql_variant for flexibility. |
| **DepotModeID** | tinyint | NOT NULL | (0) | Dictionary.DepotMode(DepotModeID) [implicit] | [CODE-BACKED] Environment mode; part of composite PK. 0=General, 1=Live, 2=Demo. Allows separate values for live and sandbox environments. |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_DepotValue | CLUSTERED | (DepotID, ParameterID, DepotModeID) ASC | FILLFACTOR=97. Direct lookup by all three key dimensions. |

---

## 4. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Depot | Many-to-one | DepotValue.DepotID = Depot.DepotID | Implicit (no FK). |
| Billing.Parameter | Many-to-one | DepotValue.ParameterID = Parameter.ParameterID | Implicit (no FK). Parameter table defines the name/type of each parameter. |

---

*Quality: 8.9/10 | 4 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,6,11*

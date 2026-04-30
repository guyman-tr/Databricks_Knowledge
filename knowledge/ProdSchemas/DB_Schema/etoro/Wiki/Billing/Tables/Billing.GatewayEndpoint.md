# Billing.GatewayEndpoint

> Payment gateway URL endpoint configuration table. Each row defines an endpoint URL for a specific depot and parameter type. Currently empty (0 rows) - designed for dynamic gateway endpoint management but not yet populated in production.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (DepotID, Value, ParameterID) - PRIMARY KEY CLUSTERED |
| **Row Count** | 0 rows (empty) |
| **Partition** | N/A - filegroup PRIMARY; DATA_COMPRESSION = PAGE |
| **Indexes** | 1 CLUSTERED composite PK (FILLFACTOR=90) |

---

## 1. Business Meaning

`Billing.GatewayEndpoint` was designed to store dynamic payment gateway endpoint URLs - the network addresses used when communicating with payment processors. Each row would represent a specific endpoint (Value = URL or connection string) for a depot+parameter combination, with `IsAvailable` tracking whether the endpoint is currently reachable.

The `IsAvailable` default of 1 suggests this was intended to support health-check-based failover: endpoints could be marked unavailable when unreachable, and the application would skip them. However, the table is currently empty - gateway endpoints are likely configured via `Billing.DepotValue` or `Billing.Parameter` instead.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) | [CODE-BACKED] Payment gateway depot; part of composite PK. Explicit FK. |
| **Value** | varchar(250) | NOT NULL | - | - | [CODE-BACKED] The endpoint value (URL, hostname, connection string). Part of composite PK. |
| **Name** | varchar(50) | NULL | - | - | [NAME-INFERRED] Human-readable label for this endpoint (e.g., "Primary", "Backup"). |
| **IsAvailable** | bit | NOT NULL | (1) | - | [NAME-INFERRED] Health/availability flag. Default true. Intended for health-check-based failover; if false, endpoint is skipped. |
| **ParameterID** | int | NOT NULL | - | Billing.Parameter(ParameterID) | [CODE-BACKED] Parameter type defining what kind of endpoint this is. Part of composite PK. Explicit FK. |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_Billing_GatewayEndpoint | CLUSTERED | (DepotID, Value, ParameterID) ASC | FILLFACTOR=90; DATA_COMPRESSION=PAGE. |

---

## 4. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Depot | Many-to-one | GatewayEndpoint.DepotID = Depot.DepotID | Explicit FK. |
| Billing.Parameter | Many-to-one | GatewayEndpoint.ParameterID = Parameter.ParameterID | Explicit FK. |

---

*Quality: 8.5/10 | 3 CODE-BACKED, 2 NAME-INFERRED | Phases: 1,2,11 | Empty table in production*

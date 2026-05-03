# Downstream column comments — execution report

| Field | Value |
|--------|--------|
| **When** | 2026-05-03 07:13:26 UTC |
| **SQL file** | `knowledge\synapse\Wiki\_downstream_column_comments.sql` |
| **Statements attempted** | 2573 |
| **Succeeded** | 2570 |
| **Failed** | 3 |

## Failures

Total failures: **3** (full `ALTER` text + error).

### 1

**Error:**

```text
PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output.bizops_output_spaceship_dim_customers'.
```

**Statement:**

```sql
ALTER TABLE main.bizops_output.bizops_output_spaceship_dim_customers ALTER COLUMN `GCID` COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
```

### 2

**Error:**

```text
PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output_stg.bizops_output_moneyfarm_dim_customers'.
```

**Statement:**

```sql
ALTER TABLE main.bizops_output_stg.bizops_output_moneyfarm_dim_customers ALTER COLUMN `GCID` COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
```

### 3

**Error:**

```text
PERMISSION_DENIED: User does not have MODIFY on Table 'main.bizops_output_stg.bizops_output_spaceship_dim_customers'.
```

**Statement:**

```sql
ALTER TABLE main.bizops_output_stg.bizops_output_spaceship_dim_customers ALTER COLUMN `GCID` COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
```


# Extending BladeBridge Configurations

> **Source:** <https://databrickslabs.github.io/lakebridge/docs/transpile/pluggable_transpilers/bladebridge/bladebridge_configuration/>
> **Ingested:** 2026-04-29
> **Local applied config:** [`tools/lakebridge/etoro_synapse2databricks.json`](../../tools/lakebridge/etoro_synapse2databricks.json) — see [`tools/lakebridge/README.md`](../../tools/lakebridge/README.md)

## Overview

The **BladeBridge** transpiler relies heavily on rules defined inside configuration files provided with the converter. These configurations are comprised of a set of layered JSON files and code templates that drive the generation of output files and application of conversion rules.

Similar configuration concepts are applicable across all BladeBridge conversion paths, although the structure of SQL‑to‑SQL configuration files and ETL‑to‑PySpark/SparkSQL/DBSQL is somewhat different, since ETL conversions typically deal with both the ETL logic translations as well as the translation of embedded SQL statements (sourcing data, pre/post/inline SQL statements).

In some migration projects, users may want to augment / override the conversion rules provided with the BladeBridge converter. For this reason, engineers should know how to:

- Extend the converter logic
- Provide their own conversion rules
- Custom‑control the output
- Troubleshoot issues

---

## Supplying a custom configuration file

When running the BladeBridge converter from Lakebridge, a custom configuration file can be supplied to the converter. To register a custom configuration file for transpilation, run the `install-transpile` command and at one of the prompts specify the custom configuration file path:

```text
databricks labs lakebridge install-transpile
Do you want to override the existing installation? (default: no): yes
Specify the config file to override the default[Bladebridge] config - press <enter> for none (default: <none>):
<local_full_path>/custom_<source>2databricks.json
```

---

## Creating the custom configuration file

If you want to start from scratch and only use your new custom file (not the provided configurations), create an empty `.json` file and specify the configurations needed following the guidance below.

If you want to **augment / override** the existing configurations:

- The provided configurations live at:
  ```
  <user_home_directory>/.databricks/labs/remorph-transpilers/bladebridge/lib/.venv/lib/python3.10/site-packages/databricks/labs/bladebridge/Converter/Configs
  ```
- Specify that your file inherits from one of the supplied configurations. This enables layered rule definitions and promotes reuse.

`inherit_from` is an array pointing to JSON filenames the current file inherits from. Multiple file inheritances are allowed. If a full path with a forward slash is supplied, the converter reads that file by absolute path; otherwise it looks for the file in the same folder as the current JSON file.

```json
"inherit_from": [
  "/Users/user.name/.databricks/labs/remorph-transpilers/bladebridge/lib/.venv/lib/python3.10/site-packages/databricks/labs/bladebridge/Converter/Configs/base_oracle2databricks_sql.json"
]
```

### Base config files per source dialect

| Source       | Target          | Base config file                              |
| ------------ | --------------- | --------------------------------------------- |
| DataStage    | Spark SQL       | `base_datastage2databricks_sparksql.json`     |
| DataStage    | PySpark         | `base_datastage2databricks_pyspark.json`      |
| **Synapse**  | **DBSQL**       | **`base_synapse2databricks_sql.json`**        |
| Oracle       | DBSQL           | `base_oracle2databricks_sql.json`             |
| MSSQL        | DBSQL           | `base_sqlserver2databricks_sql.json`          |
| Netezza      | DBSQL           | `base_netezza2databricks_sql.json`            |
| Teradata     | DBSQL           | `base_teradata2databricks_sql.json`           |

### Practical example: renaming tables and schema mapping

For scenarios where you need to rename tables or ensure they follow the UC three‑level namespace paradigm:

1. Inherit from a base config:
   ```json
   "inherit_from": [
     "/Users/user.name/.databricks/labs/remorph-transpilers/bladebridge/lib/.venv/lib/python3.10/site-packages/databricks/labs/bladebridge/Converter/Configs/base_mssql2databricks_sql.json"
   ]
   ```
2. Add a `target_sql_file_header` to define the catalog:
   ```json
   "target_sql_file_header": "USE CATALOG catalog01;"
   ```
3. Add `line_subst` rules to remap source schemas:
   ```json
   "line_subst": [
     { "from": "\\bschema01\\b\\.", "to": "gold." },
     { "from": "\\bschema02\\b\\.", "to": "silver." }
   ]
   ```

With this configuration:

- Any reference to `schema01.` is replaced with `gold.`
- Any reference to `schema02.` is replaced with `silver.`
- Generated SQL files automatically include the catalog declaration at the top.

### Putting it all together

`my_custom_config.json`:

```json
{
  "inherit_from": [
    "/Users/user.name/.databricks/labs/remorph-transpilers/bladebridge/lib/.venv/lib/python3.10/site-packages/databricks/labs/bladebridge/Converter/Configs/base_mssql2databricks_sql.json"
  ],
  "target_sql_file_header": "USE CATALOG catalog01;",
  "line_subst": [
    { "from": "\\bschema01\\b\\.", "to": "gold." },
    { "from": "\\bschema02\\b\\.", "to": "silver." }
  ]
}
```

Register it via `databricks labs lakebridge install-transpile`.

---

## Basic converter rules

When converting individual SQL code snippets or ETL expressions, BladeBridge uses three basic rule types, applied in this order:

1. `line_subst`
2. `block_subst`
3. `function_subst`

Within each section, rules execute in array order. **Longer / more specific patterns should precede shorter / more generic ones** (e.g. `varchar` must come before `char`).

Sample snippet:

```json
{
  "line_subst": [
    { "from": "\\bvarchar\\b", "to": "string" },
    { "from": "\\bSYSDATE\\b",  "to": "CURRENT_TIMESTAMP()" }
  ],
  "block_subst": [
    { "from": "\\bSET\\s+\\w+\\s+ON\\b", "to": "" },
    { "from": "\\bCREATE\\s+VIEW\\b",      "to": "CREATE OR REPLACE VIEW" }
  ],
  "function_subst": [
    { "from": "CONVERT", "output_template": "CAST($2 AS $1)", "num_args": 2 },
    { "from": "ISNULL",  "to": "COALESCE" }
  ]
}
```

### `line_subst`

An array of substitution instructions performed on a single line. The converter applies all matching substitutions on each line.

| Attribute                     | Purpose                                                                                                                            | Example                                                                          |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `from`                        | Pattern to capture. Use parentheses to capture tokens.                                                                              | `"CREATE TABLE\\s+(\\w+)"` — `(\\w+)` is token 1                                  |
| `to`                          | Replacement pattern. `$1`–`$9` reference captured tokens.                                                                          | `"CREATE OR REPLACE TABLE $1"`                                                   |
| `statement_categories`        | Array of statement categories the rule applies to. Omitted = all categories.                                                       | `["TABLE_DDL", "VIEW_DDL"]`                                                      |
| `exact_match`                 | `"1"` = case‑insensitive exact match instead of regex.                                                                             |                                                                                  |
| `first_match`                 | `"1"` = stop checking subsequent rules once this one matches the line.                                                             |                                                                                  |
| `exclude_categories`          | Inverse of `statement_categories`.                                                                                                 |                                                                                  |
| `extension_call`              | Invokes an external Perl routine instead of using `to`. See *Advanced Conversion Rules*.                                           |                                                                                  |
| `relative_fragment_pattern`   | Restricts pattern matching to specific code fragments identified by `relative_fragment_offset`.                                    | `"ACTIVITYCOUNT = 0"`                                                            |
| `relative_fragment_offset`    | List of fragment offsets to search when using `relative_fragment_pattern`.                                                         | `"1,2"`                                                                          |
| `upcase_string`               | Upcases the output string.                                                                                                         | `{"from":"#(\\w+)#","to":"${$1}","upcase_string":true}`                          |

> In `to`, tokens `$1`–`$9` refer to regex capture groups.

**Example:**

- Source: `#my_var# + 10 + p_curr_date_of_month`
- Rule: `{"from": "#(\\w+)#", "to": "${$1}", "upcase_string": true}`
- Result: `${MY_VAR} + 10 + p_curr_date_of_month`

### `block_subst`

Substitutions performed on a statement block (e.g. an entire SQL statement, a DML inside a stored procedure, or a view/table definition). Useful when restructuring is needed or when patterns may span multiple lines. BladeBridge splits multi‑statement content into blocks before applying these rules.

> `block_subst` is costlier than `line_subst`; reserve it for rules that genuinely need block context. Convert simple things like `varchar` → `string` in `line_subst` instead.

| Attribute                     | Purpose                                                                                                                            | Example                                                                       |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `from`                        | Pattern to capture (capture groups allowed).                                                                                       | `"CREATE TABLE\\s+(\\w+)"`                                                     |
| `to`                          | Replacement pattern, with `$1`–`$9`.                                                                                               | `"CREATE OR REPLACE TABLE $1"`                                                |
| `statement_categories`        | Array of categories the rule applies to.                                                                                           | `["TABLE_DDL","VIEW_DDL"]`                                                    |
| `first_match`                 | `"1"` = stop processing further rules in this section once matched.                                                                |                                                                               |
| `extension_call`              | Invokes an external custom routine instead of `to`. See *Advanced Conversion Rules*.                                               |                                                                               |
| `force_alias_usage`           | Enforces use of aliases in WHERE/SELECT/JOIN where required by the target.                                                         |                                                                               |
| `relative_fragment_pattern`   | Restricts to fragments matched by `relative_fragment_offset`.                                                                      | `"ACTIVITYCOUNT = 0"`                                                         |
| `relative_fragment_offset`    | List of fragment offsets used with `relative_fragment_pattern`.                                                                    | `"1,2"`                                                                       |
| `debug_tag`                   | Tag emitted in verbose log when this rule fires.                                                                                   | `"RULE001"`                                                                   |

**Example:**

- Source: `SELECT V_TOTAL = COUNT(*) FROM orders;`
- Rule: `{"from":"\\bSELECT\\s+(V_\\w+)\\s*\\=(.*)\\;","to":"SET $1 = (SELECT $2 limit 1);"}`
- Result: `SET V_TOTAL = (SELECT COUNT(*) FROM orders limit 1);`

### `function_subst`

Alters function calls. Use when function names change and/or arguments need to be reordered/transformed.

| Attribute                     | Purpose                                                                                                                            | Example                          |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| `from`                        | Source function name.                                                                                                              | `"ISNULL"`                       |
| `to`                          | Target function name (signature unchanged).                                                                                        | `"COALESCE"`                     |
| `output_template`             | Template for the entire output call. Supports `$1`–`$9`, `%ALL_ARGS%`, etc. Use this when `to` alone isn't enough.                 | `"CAST($2 AS $1)"`               |
| `statement_categories`        | Array of categories the rule applies to.                                                                                           | `["SELECT","UPDATE"]`            |
| `placement`                   | Placement of the converted clause. `append_inside_ddl` or `append_after_ddl`.                                                      | `"append_inside_ddl"`            |
| `extension_call`              | Invokes an external routine to generate the call. See *Advanced Conversion Rules*.                                                 | `"custom_subst_routine"`         |
| `num_args`                    | Only fires when the call's argument count matches.                                                                                 | `2`                              |
| `date_format_arg`             | Argument position holding a date‑part keyword (e.g. `MM`, `YYYY`). Works with `datepart_translations`.                             | `2`                              |
| `arg_pattern`                 | Hash where keys are 1‑based arg positions and values are regex patterns the args must match.                                       | `{1: "^\\d+$"}`                  |
| `upcase_args`                 | List of arg positions to uppercase.                                                                                                | `[1, 2]`                         |
| `lowcase_args`                | List of arg positions to lowercase.                                                                                                | `[3]`                            |
| `skip_files`                  | Filenames (basenames) to skip for this rule.                                                                                       | `["legacy_job.sql"]`             |
| `relative_fragment_pattern`   | Restricts rule to when this pattern is found in a nearby fragment.                                                                 | `"ACTIVITYCOUNT = 0"`            |
| `relative_fragment_offset`    | Comma‑separated offsets relative to the current line.                                                                              | `"1,2"`                          |
| `arg_placement`               | Hash to remap or reposition arguments; supports fallbacks like `2||default`. *(Prefer `output_template`.)*                         | `{1: "2", 2: "1||NULL"}`         |
| `full_subst`                  | Full template using `__ARG1__`, `__ARG2__`. Overrides normal arg logic.                                                            | `"IFNULL(__ARG1__, __ARG2__)"`   |
| `arg_token_output`            | Token positions to output when using token‑based splitting.                                                                        | `"1,3"`                          |
| `split_string`                | Delimiter used to split arguments when using `arg_token_output`.                                                                   | `";"`                            |
| `new_arg_separator`           | Overrides the default `,` separator when joining arguments.                                                                        | `" "`                            |
| `each_arg_routine`            | A Perl routine applied to each argument.                                                                                           | `"uc"`                           |
| `ending`                      | String appended after the function call.                                                                                           | `";"`                            |

#### Special keywords

- **`__BLANK__`** — blanks out the entire call (including the function name).
  ```json
  {"from":"INDEX","to":"__BLANK__","statement_categories":["TABLE_DDL","TABLE_DDL_LIKE","TABLE_DDL_AS_SELECT"]}
  ```
- **`__ELIMINATE_CALL__`** — removes the function name and surrounding parens, keeping the inner arguments.
  ```json
  {"from":"TRANSLATE","to":"__ELIMINATE_CALL__"}
  ```

> In `output_template`, `$1`–`$9` refer to direct arguments of the function call (which can be expressions or nested calls).

Example for `SUBSTR`:

```sql
SELECT SUBSTR(
    UPPER( first_name || ' ' || last_name ),  -- arg $1
    10,                                       -- arg $2
    20                                        -- arg $3
)
```

---

## Extended converter rules

### `stmt_categorization_patterns`

Associates code patterns with statement categories so the converter can include / exclude rules or dispatch to custom routines.

```json
"stmt_categorization_patterns": [
  {"category": "TABLE_DDL_AS_SELECT", "patterns": ["CREATE(.*?)TABLE(.*?)AS\\s*(.*SELECT", "CREATE(.*?)TABLE(.*?)AS\\s*SELECT"]},
  {"category": "TABLE_DDL_LIKE",      "patterns": ["CREATE(.*?)TABLE(.*?)AS(.*?)WITH\\s+NO\\s+DATA", "CREATE(.*?)TABLE(.*?)LIKE(.*)"]},
  {"category": "TABLE_DDL",           "patterns": ["CREATE(.*?)\\sTABLE"]},
  {"category": "TABLE_DROP",          "patterns": ["DROP(.*?)\\sTABLE"]},
  {"category": "VIEW_DDL",            "patterns": ["CREATE(.*?)VIEW", "REPLACE(.*?)VIEW"]}
]
```

Each category may have multiple patterns. `stmt_categorization_patterns` can be repeated and extended in inherited files. Provided in the base file `general_sql_specs.json`.

### `datepart_translations`

Maps source datepart format tokens to target tokens.

```json
"datepart_translations": {
  "YYYY": "yyyy",
  "mm":   "MM",
  "DD":   "dd",
  "hh24": "hh",
  "HH":   "hh",
  "mi":   "mm",
  "MI":   "mm",
  "FF":   "SSSS",
  "SS":   "ss",
  "AM":   "a"
}
```

> Case‑sensitive. Longer patterns are processed first (so `yyyy` precedes `DD`). Used together with `function_subst.date_format_arg`.

---

## Advanced conversion rules

The converter can delegate logic to externally defined Perl subroutines. Common when converting wrapper or flow‑control elements (e.g. converting Netezza or Oracle procedures with conditional statements, loops, and variables to Snowflake's JavaScript procedures). Subroutines live in a Perl file (or files) registered with:

```json
"CUSTOM_CONVERTER_MODULES": ["my_handlers.pl", "globals.pl"]
```

The dispatch table is `fragment_handling`:

```json
"fragment_handling": {
  "PROGRAM_DECLARATION":   "::create_procedure_from_oracle",
  "CREATE_PROCEDURE":      "::create_procedure_from_oracle",
  "END_PROCEDURE":         "::end_procedure",
  "COMMENT":               "::convert_comment",
  "VAR_ASSIGNMENT":        "::convert_assignment",
  "EXECUTE_INTO":          "::execute_into",
  "READ_DML_INTO_VAR":     "::convert_assignment",
  "WRITE_DML":             "::convert_dml",
  "UTIL_CALL":             "::convert_dml",
  "TABLE_DDL":             "::convert_dml",
  "DEFAULT_HANDLER":       "::oracle_default_statement_handler"
}
```

The double‑colon prefix tells the processor the routine lives in the main namespace (not inside a class). You can extend `stmt_categorization_patterns` anywhere in inherited files to define custom fragment categories.

### Hook and extension configuration

#### `initialize_hooks_call`

Invokes a subroutine and passes the configuration structure plus an instance of the converter class.

```json
"initialize_hooks_call": "::init_hooks"
```

Receives:

```perl
{
  CONFIG    => $config_entries_pointer,
  CONVERTER => $converter_class_instance
}
```

Sample:

```perl
sub init_hooks {
  my $param = shift;
  %CFG       = %{$param->{CONFIG}};
  $CONVERTER = $param->{CONVERTER};
  print "INIT_HOOKS Called. config:\n" . Dumper(%CFG);
}
```

#### `prescan_and_collect_info_hook`

Pre‑scans the input file before per‑fragment handlers run. Useful for extracting procedure parameters or other metadata.

```json
"prescan_and_collect_info_hook": "::prescan_code_oracle"
```

```perl
sub prescan_code_oracle {
  my $filename = shift;
  my $cf       = shift;
  print "******** prescan_code_oracle $filename *********\n";
  # Open and analyze the file...
}
```

#### Fragment‑handling subroutines

Each routine in `fragment_handling` receives a pointer to the array of code lines for the matched fragment.

For:

```sql
UPDATE DIM_CUST
SET CUST_FULL_NAME = FIRSTNAME || ' ' || LASTNAME
```

categorised as `WRITE_DML`, the handler could be:

```perl
sub convert_dml {
  my $ar  = shift;            # pointer to array of code lines
  my $sql = join("\n", @$ar); # full SQL block
  # Custom logic here
}
```

> The SQL Converter ships with working extension samples that can serve as templates.

#### `pre_finalization_handler`

Runs **after** all fragment‑handling routines complete.

```json
"pre_finalization_handler": "::finalize_content"
```

#### `post_conversion_adjustment_hook`

Runs **after** `pre_finalization_handler`.

```json
"post_conversion_adjustment_hook": "::post_conversion_adjustment"
```

#### `preprocess_file`

Enables pre‑processing of the input file by triggering the routine in `preprocess_routine`.

```json
"preprocess_file": "1"
```

#### `preprocess_routine`

The subroutine to use when `preprocess_file` is enabled.

```json
"preprocess_routine": "::mssql_preprocess"
```

---

## ETL configuration files

ETL configuration files are typically more complex than plain SQL ones. They may contain:

- Instructions for **output code generation**, including support for multiple target languages such as **Spark SQL** or **PySpark**
- Rules for **styling the output**:
  - Including or omitting header comments
  - Replicating the ETL job's original folder/directory structure
- Guidance for handling **external sources and targets** (e.g. flat files, external tables)
- Embedded logic that instructs the converter **how to assemble the generated code**

ETL configuration files often point to **additional JSON files** that define how to process:

- **ETL expressions** (transformation functions, variable assignments)
- **Embedded SQL** inside ETL components, e.g.:
  - SQL within a `SELECT` of a source component
  - `pre-SQL` / `post-SQL` snippets executed before/after data movement

These supporting files closely resemble plain SQL configs, but are scoped to **fragment‑level transformations**, **function handling**, and **data‑manipulation tasks** typical of visual ETL platforms such as IBM DataStage.

ETL configuration thus serves as the **orchestration layer** combining rule‑based transformation with output formatting, system integration, and extensibility.

### ETL configuration tags

| Attribute                                  | Description                                                                                                                                          | Sample                                                                                                                                 |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `code_generation_module`                   | Which module to use for code generation.                                                                                                             | `"CodeGeneration::SQL"` or `"CodeGeneration::PySpark"`                                                                                 |
| `target_file_extension`                    | Extension of the generated code file.                                                                                                                | `"py"`                                                                                                                                 |
| `use_notebook_md`                          | Whether Databricks notebook markdown should be used.                                                                                                 | `1`                                                                                                                                    |
| `script_header`                            | Code block prepended to the generated script (often imports / metadata).                                                                             | `"# Databricks notebook source\nfrom datetime import datetime"`                                                                        |
| `script_footer`                            | Code block appended to the generated script.                                                                                                         | `"quit()"`                                                                                                                             |
| `rowid_expression`                         | Expression to compute a row ID.                                                                                                                      | `"xxhash64(%DELIMITED_COLUMN_LIST%) as %ROWID_COL_NAME%"`                                                                              |
| `rowid_column_name`                        | Name of the row‑ID column.                                                                                                                           | `"source_record_id"`                                                                                                                   |
| `dataset_creation_method`                  | `TABLE` (typical lift‑and‑shift) or `CTE` (custom dbt outputs).                                                                                      | `"TABLE"` / `"CTE"`                                                                                                                    |
| `table_creation_statement`                 | Template for creating a temporary table from a SQL block.                                                                                            | `"%TABLE_NAME% = spark.sql(rf\"\"\"%INNER_SQL%\"\"\"%FORMAT_SPEC%)\n%TABLE_NAME%.createOrReplaceTempView(\"%TABLE_NAME%\")"`           |
| `ddl_statement_wrap`                       | Wraps DDL statements in a Spark SQL invocation.                                                                                                      | `"spark.sql(f\"\"\"%INNER_SQL%\"\"\"%FORMAT_SPEC%).display()"`                                                                         |
| `etl_converter_config_file`                | Secondary config for ETL expression conversion.                                                                                                      | `"base_datastage2databricks_pyspark.json"`                                                                                             |
| `commands`                                 | Templates for read/write statements per system class.                                                                                                | (see *commands section* below)                                                                                                         |
| `use_native_database_connections_source`   | When `true`, Source components use native JDBC/ODBC connection templates instead of default commands.                                                | `true`                                                                                                                                 |
| `use_native_database_connections_lookup`   | When `true`, Lookup components use native JDBC/ODBC connection templates.                                                                            | `true`                                                                                                                                 |
| `use_native_database_connections_target`   | When `true`, Target components use native JDBC/ODBC connection templates.                                                                            | `true`                                                                                                                                 |
| `native_database_connection_commands`      | JDBC/ODBC connection templates per database type (e.g. `READER_ORACLE`, `WRITER_MSSQL`).                                                             | (see *Native Database Connection Support*)                                                                                             |
| `system_type_class`                        | Maps system types to class names used in `commands`.                                                                                                 | (see below)                                                                                                                            |
| `conform_source_columns`                   | Instructs the writer to generate a column‑conforming statement for sources.                                                                          |                                                                                                                                        |
| `conform_columns_call_template`            | Template for the column‑conforming call.                                                                                                             | `"%DF%_conformed_cols = [%COLUMN_LIST%]\n%DF% = DatabricksConversionSupplements.conform_df_columns(%DF%,%DF%_conformed_cols)"`         |
| `mapplet_class_name`                       | Class name used for mapplet functions.                                                                                                               | `"Mapplets"`                                                                                                                           |
| `mapplet_function_name`                    | Function‑name format for mapplets.                                                                                                                   | `"%MAPPLET_NAME%"`                                                                                                                     |
| `mapplet_code_indent`                      | General code indentation for mapplets.                                                                                                               | (8 spaces)                                                                                                                             |
| `mapplet_pyspark_code_indent`              | Indentation for multiline SQL inside mapplets.                                                                                                       | (4 spaces)                                                                                                                             |
| `mapplet_header_template`                  | Path to the file containing the mapplet header template.                                                                                             | `"python_mapplet_header_template.py"`                                                                                                  |
| `mapplet_input_declaration`                | Format string for the mapplet's Python function declaration.                                                                                         | `"\ndef %MAPPLET_NAME%(%INPUT%):"`                                                                                                     |
| `mapplet_conclusion`                       | Code snippet appended to conclude the mapplet.                                                                                                       | `"#Implementation %MAPPLET_NAME% concluded\n\n"`                                                                                       |
| `mapplet_object_var_inject_format`         | Format for injecting object variables (typically wrapping dynamic names).                                                                            | `"\"\"\" + %OBJECT_NAME% + \"\"\""`                                                                                                    |
| `mapplet_function_invocation`              | Format used to invoke the mapplet function.                                                                                                          | `"Mapplets.%MAPPLET_NAME%(%INPUT%)"`                                                                                                   |
| `mapplet_instance_prefixes`                | Instance‑name prefixes used to identify mapplet connection info.                                                                                     | `["sc_"]`                                                                                                                              |

### `system_type_class` section

Maps a system type to a class name used in the `commands` section.

```json
"system_type_class": {
  "ORACLE":       "RELATIONAL",
  "MySQL":        "RELATIONAL",
  "HIVE":         "RELATIONAL",
  "DB2":          "RELATIONAL",
  "TERADATA":     "RELATIONAL",
  "REDSHIFT":     "RELATIONAL",
  "Salesforce":   "SALEFORCE",
  "TOOLKIT":      "RELATIONAL",
  "FLATFILE":     "FILE_DELIMITED",
  "FLAT FILE":    "FILE",
  "FLAT_FILE":    "FILE",
  "FILE WRITER":  "FILE",
  "DEFAULT":      "FILE_DELIMITED"
}
```

### `commands` section

Templates for read/write statements per system class.

```json
"commands": {
  "READER_FILE_DELIMITED":           "spark.read.format('csv').option('header','true').load(rf'''%PATH%''')",
  "READER_FILE_DELIMITED_EXTERNAL":  "%NODE_NAME%_External = spark.read.format('csv').option('header','true').load(%PATH%)",
  "READER_FILE_FIXED_WIDTH":         "raw_%NODE_NAME% = spark.read.text(f\"%PATH%\")\n%NODE_NAME% = raw_%NODE_NAME%.select(%SUBSTRING_SPEC%)",
  "READER_RELATIONAL":               "%NODE_NAME% = %SQL%\n%NODE_NAME% = spark.sql(%NODE_NAME%)",
  "WRITER_FILE_DELIMITED":           "%DF%.write.format('csv').option('header','%HEADER%').mode('overwrite').option('sep','%DELIMITER%').csv('%PATH%')",
  "WRITER_RELATIONAL":               "my_end_point.write_to_db(%DF%, \"%TABLE_NAME%\", username=\"%LOGIN%\", password=\"%PASSWORD%\")"
}
```

### Native Database Connection Support

When converting ETL components that connect to external databases (Oracle, SQL Server, Redshift, Synapse, etc.), the converter can use native JDBC/ODBC connections instead of Databricks‑native connectors. This is useful when migrating from Informatica Cloud or DataStage and direct database access is required.

#### Configuration flags

```json
{
  "use_native_database_connections_source": true,
  "use_native_database_connections_lookup": true,
  "use_native_database_connections_target": true
}
```

- `use_native_database_connections_source` — Source components use native templates instead of default `commands`.
- `use_native_database_connections_lookup` — Lookup components use native templates.
- `use_native_database_connections_target` — Target components use native templates.

> Native connections are only used when the flag is enabled **and** the component's `SYSTEM_TYPE` is not `'DATABRICKS'`. The converter falls back to the default `commands` section if no native template is found.

#### Native connection command templates

Templates follow `READER_<SYSTEM_TYPE>` (readers) and `WRITER_<SYSTEM_TYPE>` (writers), where `<SYSTEM_TYPE>` matches the component's system type (e.g. `ORACLE`, `MSSQL`, `SYNAPSE`, `REDSHIFT`):

```json
{
  "native_database_connection_commands": {
    "READER_ORACLE":  "spark.read \\\n  .format(\"jdbc\") \\\n  .option(\"url\", \"%URL%\") \\\n  .option(\"dbtable\", f\"\"\"(%SQL%) t\"\"\") \\\n  .option(\"user\", \"%USERNAME%\") \\\n  .option(\"password\", \"%PASSWORD%\") \\\n  .option(\"driver\", \"oracle.jdbc.driver.OracleDriver\") \\\n  .load()",

    "WRITER_ORACLE":  "%DF%.write \\\n  .format(\"jdbc\") \\\n  .option(\"url\", \"%URL%\") \\\n  .option(\"dbtable\", \"%TABLE_NAME%\") \\\n  .option(\"user\", \"%USERNAME%\") \\\n  .option(\"password\", \"%PASSWORD%\") \\\n  .option(\"driver\", \"oracle.jdbc.driver.OracleDriver\") \\\n  .mode(\"%WRITE_MODE%\") \\\n  .save()",

    "READER_MSSQL":   "spark.read \\\n  .format(\"jdbc\") \\\n  .option(\"url\", \"jdbc:sqlserver://%HOST%:%PORT%;databaseName=%DATABASE%\") \\\n  .option(\"dbtable\", f\"\"\"(%SQL%) t\"\"\") \\\n  .option(\"user\", \"%USERNAME%\") \\\n  .option(\"password\", \"%PASSWORD%\") \\\n  .option(\"driver\", \"com.microsoft.sqlserver.jdbc.SQLServerDriver\") \\\n  .load()",

    "WRITER_MSSQL":   "%DF%.write \\\n  .format(\"jdbc\") \\\n  .option(\"url\", \"jdbc:sqlserver://%HOST%:%PORT%;databaseName=%DATABASE%\") \\\n  .option(\"dbtable\", \"%TABLE_NAME%\") \\\n  .option(\"user\", \"%USERNAME%\") \\\n  .option(\"password\", \"%PASSWORD%\") \\\n  .option(\"driver\", \"com.microsoft.sqlserver.jdbc.SQLServerDriver\") \\\n  .mode(\"%WRITE_MODE%\") \\\n  .save()"
  }
}
```

#### Available template tokens

| Token             | Description                                                              |
| ----------------- | ------------------------------------------------------------------------ |
| `%URL%`           | JDBC connection URL (e.g. `jdbc:oracle:thin:@//host:port/service`)       |
| `%HOST%`          | Database hostname                                                        |
| `%PORT%`          | Database port number                                                     |
| `%DATABASE%`      | Database name                                                            |
| `%SERVICE_NAME%`  | Oracle service name                                                      |
| `%SQL%`           | SQL query for readers (the SELECT statement)                             |
| `%TABLE_NAME%`    | Target table name for writers                                            |
| `%USERNAME%`      | Database username                                                        |
| `%PASSWORD%`      | Database password                                                        |
| `%WRITE_MODE%`    | Write mode for targets (`overwrite`, `append`, `ignore`)                 |
| `%DF%`            | DataFrame variable name                                                  |

### Substitution tokens (general)

Templates above use the following placeholders that get substituted at conversion time:

| Token              | Description                                                                |
| ------------------ | -------------------------------------------------------------------------- |
| `%DF%`             | Name of the dataframe                                                      |
| `%SQL%`            | SQL content (e.g. the SELECT statement)                                    |
| `%PATH%`           | Path of the file being processed                                           |
| `%SUBSTRING_SPEC%` | Specifications generated by the converter for splitting positional strings |
| `%HEADER%`         | Header specification                                                       |
| `%LOGIN%`          | System login                                                               |
| `%PASSWORD%`       | System password                                                            |

### Mapplet, Joblet and Shared Containers handling

In ETL systems, reusable logic is commonly encapsulated in modular components (mapplets, joblets, shared containers). To preserve reusability the converter replicates the structure and behaviour of these components in the generated code.

Configuration tags prefixed with `mapplet` define how this reusable logic should be represented and rendered in the output.

The converter will generate a single class — specified by `mapplet_class_name` — in which all reusable code is consolidated. This class serves as the container for all mapplet‑level function definitions and logic.

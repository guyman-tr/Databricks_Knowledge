# Wiki vs alter.sql column COMMENT parity audit

Automated scan: typed **Elements** rows in `.md` (same rules as merge script) vs `ALTER COLUMN ... COMMENT` lines in paired `.alter.sql`.

**Caveats:**
- Wiki side uses the same **typed Elements** parser as `merge_wiki_column_comments_into_alter.py` (ordinal + column + SQL type + description). Value-map / narrative tables are ignored.
- Odd column names (`+`, `%`, spaces in name) may be omitted from wiki counts — verify manually.
- Alter side matches `ALTER COLUMN … COMMENT` even if `ALTER TABLE` reference is malformed.
- **No `.alter.sql` expected** when `_generic_pipeline_mapping.json` lists no UC row for that Synapse `(schema_name, table_name)` (same stem as the wiki file). Mapping is a static snapshot (`exported_at` in JSON). **Database:** `sql_dp_prod_we` only.
- If the mapping file is missing, only **Views/Functions** without alter are skipped (legacy); tables without alter still need attention.
- Objects with a paired `.alter.sql` are always audited (including manually maintained view alters).

## Summary

| Metric | Count |
|--------|------:|
| Wiki objects with parsed catalog columns | 262 |
| Skipped (no .alter — not in Generic UC mapping or legacy Views/Functions) | 138 |
| Parity OK (has `.alter.sql`, wiki vs parsed COMMENT columns match) | 124 |
| Needs attention | 0 |

### Skipped breakdown

| Kind | Count |
|------|------:|
| Tables | 127 |
| Views | 11 |


## By schema (needs attention)

## Detail: missing and extra columns

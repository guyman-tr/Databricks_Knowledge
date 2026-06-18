#!/usr/bin/env python3
"""Validate UC external table naming against anti-purge formula."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.skill_suggestions.naming import required_storage_for_schema, validate_table_name_and_location


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--schema", required=True, help="UC schema name")
    ap.add_argument("--table-name", required=True, help="UC table name")
    ap.add_argument("--location", required=True, help="ABFSS location for CREATE EXTERNAL TABLE")
    ap.add_argument("--json", action="store_true", help="Emit JSON output")
    args = ap.parse_args()

    result = validate_table_name_and_location(
        schema=args.schema,
        table_name=args.table_name,
        location=args.location,
    )

    payload = {
        "schema": args.schema,
        "table_name": args.table_name,
        "location": args.location,
        "is_abfss": result.is_abfss,
        "expected_table_name": result.expected_table_name,
        "table_name_ok": result.table_name_ok,
        "storage_account": result.storage_account,
        "required_storage_account": required_storage_for_schema(args.schema),
        "env_ok": result.env_ok,
        "schema_ok": result.schema_ok,
        "is_valid": result.is_valid,
    }

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(f"schema={payload['schema']}")
        print(f"table_name={payload['table_name']}")
        print(f"expected_table_name={payload['expected_table_name']}")
        print(f"location={payload['location']}")
        print(f"is_abfss={payload['is_abfss']}")
        print(f"storage_account={payload['storage_account']}")
        print(f"required_storage_account={payload['required_storage_account']}")
        print(f"table_name_ok={payload['table_name_ok']}")
        print(f"env_ok={payload['env_ok']}")
        print(f"schema_ok={payload['schema_ok']}")
        print(f"is_valid={payload['is_valid']}")

    return 0 if result.is_valid else 1


if __name__ == "__main__":
    sys.exit(main())

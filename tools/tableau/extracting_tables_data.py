import argparse
import datetime
import os
import uuid
from typing import Any, Dict, List, Optional, Set, Tuple

import jwt
import tableauserverclient as tsc
from dotenv import load_dotenv

load_dotenv()

TABLEAU_SERVER = os.getenv("TABLEAU_SERVER")
SITE_NAME = os.getenv("TABLEAU_SITE_NAME")
CONNECTED_APP_CLIENT_ID = os.getenv("TABLEAU_CLIENT_ID")
CONNECTED_APP_SECRET_ID = os.getenv("TABLEAU_SECRET_ID")
CONNECTED_APP_SECRET_VALUE = os.getenv("TABLEAU_SECRET_VALUE")
TABLEAU_USERNAME = os.getenv("TABLEAU_USERNAME")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract custom SQL and downstream calculated fields for a Tableau table"
    )
    parser.add_argument(
        "--table-name",
        type=str,
        required=True,
        help="Exact table name to match against metadata field `name`",
    )
    parser.add_argument(
        "--output-md",
        type=str,
        default="custom_sql_results.md",
        help="Path for the generated Markdown report",
    )
    return parser.parse_args()


def validate_env() -> None:
    required_vars = [
        "TABLEAU_SERVER",
        "TABLEAU_CLIENT_ID",
        "TABLEAU_SECRET_ID",
        "TABLEAU_SECRET_VALUE",
        "TABLEAU_USERNAME",
    ]
    missing = [name for name in required_vars if not os.getenv(name)]
    if missing:
        raise ValueError(f"Missing required environment variables: {', '.join(missing)}")


def sign_out(server: tsc.Server) -> None:
    server.auth.sign_out()
    print("Successfully signed out from Tableau Server")


def generate_jwt_token(
    client_id: str,
    secret_id: str,
    secret_value: str,
    username: str,
    scopes: Optional[List[str]] = None,
    expiration_minutes: int = 5,
) -> str:
    if scopes is None:
        scopes = ["tableau:content:*"]

    payload: Dict[str, Any] = {
        "iss": client_id,
        "exp": datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=expiration_minutes),
        "jti": str(uuid.uuid4()),
        "aud": "tableau",
        "sub": username,
        "scp": scopes,
    }
    headers = {"kid": secret_id, "iss": client_id}

    token = jwt.encode(payload, secret_value, algorithm="HS256", headers=headers)
    print(f"Generated JWT token for user: {username}")
    return token


def sign_in_with_jwt(
    server_url: str,
    client_id: str,
    secret_id: str,
    secret_value: str,
    username: str,
    site_name: Optional[str] = None,
    scopes: Optional[List[str]] = None,
) -> tsc.Server:
    jwt_token = generate_jwt_token(
        client_id=client_id,
        secret_id=secret_id,
        secret_value=secret_value,
        username=username,
        scopes=scopes,
    )
    server = tsc.Server(server_url, use_server_version=True, http_options={"verify": False})
    jwt_auth = tsc.JWTAuth(jwt_token, site_id=site_name)
    server.auth.sign_in(jwt_auth)
    print(f"Successfully signed in to Tableau Server using JWT: {server_url}")
    return server


def query_database_tables(server: tsc.Server, table_name: str) -> List[Dict[str, Any]]:
    query = """
    query tables($tableName: String!) {
      databaseTablesConnection(filter: {name: $tableName}) {
        nodes {
          name
          schema
          connectionType
          referencedByQueries {
            name
            query
          }
          downstreamWorkbooks {
            embeddedDatasources {
              fields {
                __typename
                name
                ... on CalculatedField {
                  formula
                }
              }
            }
          }
        }
      }
    }
    """

    response = server.metadata.query(query, variables={"tableName": table_name})

    if response.get("errors"):
        print("GraphQL errors:")
        for err in response["errors"]:
            print(f"  - {err.get('message', err)}")

    connection = response.get("data", {}).get("databaseTablesConnection")
    if not connection:
        print("No databaseTablesConnection returned from metadata API")
        return []

    nodes = connection.get("nodes", [])
    print(f"Fetched {len(nodes)} database table node(s) for filter name '{table_name}'.")

    return nodes


def filter_matching_tables(nodes: List[Dict[str, Any]], table_name: str) -> List[Dict[str, Any]]:
    allowed_connection_types = {"sqlserver", "databricks"}
    filtered_nodes: List[Dict[str, Any]] = []
    for node in nodes:
        node_name = str(node.get("name") or "")
        connection_type = str(node.get("connectionType") or "").lower()
        if node_name == table_name and connection_type in allowed_connection_types:
            filtered_nodes.append(node)
    return filtered_nodes


def extract_custom_sql_queries(matching_tables: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    custom_sql_queries: List[Dict[str, Any]] = []
    seen: Set[Tuple[str, str, str]] = set()

    for table in matching_tables:
        table_name = str(table.get("name") or "")
        table_full_name = str(table.get("fullName") or "")
        for query_item in table.get("referencedByQueries", []) or []:
            query_name = str(query_item.get("name") or "")
            query_text = str(query_item.get("query") or "")
            dedupe_key = (table_name, query_name, query_text)
            if dedupe_key in seen:
                continue
            seen.add(dedupe_key)
            custom_sql_queries.append(
                {
                    "tableName": table_name,
                    "tableFullName": table_full_name,
                    "queryName": query_name,
                    "query": query_text,
                }
            )

    return custom_sql_queries


def extract_downstream_calculated_fields(matching_tables: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    calculated_fields: List[Dict[str, Any]] = []
    seen: Set[Tuple[str, str]] = set()

    for table in matching_tables:
        table_name = str(table.get("name") or "")
        table_full_name = str(table.get("fullName") or "")
        downstream_workbooks = table.get("downstreamWorkbooks", []) or []
        for workbook in downstream_workbooks:
            embedded_datasources = workbook.get("embeddedDatasources", []) or []
            for datasource in embedded_datasources:
                fields = datasource.get("fields", []) or []
                for field in fields:
                    if field.get("__typename") != "CalculatedField":
                        continue
                    field_name = str(field.get("name") or "")
                    formula = str(field.get("formula") or "")
                    dedupe_key = (field_name, formula)
                    if dedupe_key in seen:
                        continue
                    seen.add(dedupe_key)
                    calculated_fields.append(
                        {
                            "fieldName": field_name,
                            "formula": formula,
                        }
                    )

    return calculated_fields


def print_results(
    table_name: str,
    matching_tables: List[Dict[str, Any]],
    custom_sql_queries: List[Dict[str, Any]],
    calculated_fields: List[Dict[str, Any]],
) -> None:
    print("=" * 80)
    print(f"Requested table name: {table_name}")
    print(f"Matched tables (connectionType in sqlserver/databricks): {len(matching_tables)}")
    print("=" * 80)
    print()

    print("PART 1 - Custom SQL queries using this table")
    if not custom_sql_queries:
        print("  No custom SQL queries found.")
    else:
        for i, item in enumerate(custom_sql_queries, start=1):
            print(f"  [{i}] Query Name: {item['queryName'] or '<unnamed query>'}")
            print(f"      Table: {item['tableName']} ({item['tableFullName']})")
            print(f"      SQL: {item['query'] or '<empty query>'}")
    print()

    print("PART 2 - Downstream calculated fields")
    if not calculated_fields:
        print("  No downstream calculated fields found.")
    else:
        for i, item in enumerate(calculated_fields, start=1):
            print(f"  [{i}] Field: {item['fieldName'] or '<unnamed field>'}")
            print(f"      Formula: {item['formula'] or '<empty formula>'}")


def write_markdown_report(
    output_path: str,
    table_name: str,
    matching_tables: List[Dict[str, Any]],
    custom_sql_queries: List[Dict[str, Any]],
    calculated_fields: List[Dict[str, Any]],
) -> None:
    lines: List[str] = []
    lines.append("# Custom SQL & Downstream Calculated Fields Report")
    lines.append("")
    lines.append(f"- Requested table name: `{table_name}`")
    lines.append(f"- Matched tables: `{len(matching_tables)}`")
    lines.append("")

    lines.append("## Part 1 - Custom SQL queries using this table")
    lines.append("")
    if not custom_sql_queries:
        lines.append("No custom SQL queries found.")
    else:
        for idx, item in enumerate(custom_sql_queries, start=1):
            lines.append(f"### Query {idx}: {item['queryName'] or '<unnamed query>'}")
            lines.append(f"- Table: `{item['tableName']}`")
            lines.append(f"- Full name: `{item['tableFullName']}`")
            lines.append("- SQL:")
            lines.append("```sql")
            lines.append(item["query"] or "-- empty query")
            lines.append("```")
            lines.append("")

    lines.append("## Part 2 - Downstream calculated fields")
    lines.append("")
    if not calculated_fields:
        lines.append("No downstream calculated fields found.")
    else:
        for idx, item in enumerate(calculated_fields, start=1):
            lines.append(f"### Calculated Field {idx}: {item['fieldName'] or '<unnamed field>'}")
            lines.append("- Formula:")
            lines.append("```text")
            lines.append(item["formula"] or "<empty formula>")
            lines.append("```")
            lines.append("")

    with open(output_path, "w", encoding="utf-8") as file:
        file.write("\n".join(lines))


def main() -> None:
    validate_env()
    args = parse_args()

    print("Signing in to Tableau with JWT...")
    server = sign_in_with_jwt(
        server_url=TABLEAU_SERVER or "",
        client_id=CONNECTED_APP_CLIENT_ID or "",
        secret_id=CONNECTED_APP_SECRET_ID or "",
        secret_value=CONNECTED_APP_SECRET_VALUE or "",
        username=TABLEAU_USERNAME or "",
        site_name=SITE_NAME,
        scopes=["tableau:content:*"],
    )

    try:
        print(f"Querying database tables for table name: '{args.table_name}'")
        all_tables = query_database_tables(server=server, table_name=args.table_name)
        matching_tables = filter_matching_tables(all_tables, table_name=args.table_name)
        custom_sql_queries = extract_custom_sql_queries(matching_tables)
        calculated_fields = extract_downstream_calculated_fields(matching_tables)

        print_results(
            table_name=args.table_name,
            matching_tables=matching_tables,
            custom_sql_queries=custom_sql_queries,
            calculated_fields=calculated_fields,
        )

        write_markdown_report(
            output_path=args.output_md,
            table_name=args.table_name,
            matching_tables=matching_tables,
            custom_sql_queries=custom_sql_queries,
            calculated_fields=calculated_fields,
        )
        print(f"Markdown report saved to {args.output_md}")
    finally:
        sign_out(server)


if __name__ == "__main__":
    main()
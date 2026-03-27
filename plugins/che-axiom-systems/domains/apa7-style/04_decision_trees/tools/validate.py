#!/usr/bin/env python3
"""
Validate YAML decision trees against JSON Schema.

Usage:
    python validate.py                    # Validate all trees
    python validate.py trees/article_type.yaml  # Validate specific file
"""

import json
import sys
from pathlib import Path

try:
    import yaml
    import jsonschema
except ImportError:
    print("Required packages not found. Install with:")
    print("  pip install pyyaml jsonschema")
    sys.exit(1)


def load_schema():
    """Load the JSON Schema for decision trees."""
    schema_path = Path(__file__).parent.parent / "schemas" / "decision_tree.schema.json"
    with open(schema_path, 'r') as f:
        return json.load(f)


def validate_tree(yaml_path: Path, schema: dict) -> tuple[bool, list[str]]:
    """
    Validate a YAML decision tree against the schema.

    Returns:
        (is_valid, list_of_errors)
    """
    errors = []

    # Load YAML
    try:
        with open(yaml_path, 'r') as f:
            tree = yaml.safe_load(f)
    except yaml.YAMLError as e:
        return False, [f"YAML parsing error: {e}"]

    # Validate against schema
    try:
        jsonschema.validate(tree, schema)
    except jsonschema.ValidationError as e:
        errors.append(f"Schema validation error: {e.message}")
        return False, errors

    # Additional semantic validations
    if 'decision_tree' in tree:
        dt = tree['decision_tree']
        nodes = dt.get('nodes', {})
        root = dt.get('root')

        # Check root exists
        if root not in nodes:
            errors.append(f"Root node '{root}' not found in nodes")

        # Check all referenced nodes exist
        for node_id, node in nodes.items():
            for branch in ['yes', 'no']:
                target = node.get(branch)
                if isinstance(target, str) and target not in nodes:
                    # Check if it's a valid result node reference
                    if not any(n.get('type') == 'result' and n.get('result') == target for n in nodes.values()):
                        errors.append(f"Node '{node_id}' references non-existent node '{target}'")

    return len(errors) == 0, errors


def main():
    schema = load_schema()
    trees_dir = Path(__file__).parent.parent / "trees"

    # Determine files to validate
    if len(sys.argv) > 1:
        files = [Path(sys.argv[1])]
    else:
        files = list(trees_dir.glob("*.yaml"))

    all_valid = True

    for yaml_path in files:
        print(f"\nValidating: {yaml_path.name}")
        is_valid, errors = validate_tree(yaml_path, schema)

        if is_valid:
            print(f"  ✓ Valid")
        else:
            all_valid = False
            print(f"  ✗ Invalid")
            for error in errors:
                print(f"    - {error}")

    print("\n" + "=" * 50)
    if all_valid:
        print("All decision trees are valid!")
        return 0
    else:
        print("Some decision trees have errors.")
        return 1


if __name__ == "__main__":
    sys.exit(main())

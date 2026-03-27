#!/usr/bin/env python3
"""
Convert YAML decision trees to Mermaid flowchart format.

Usage:
    python to_mermaid.py trees/article_type.yaml
    python to_mermaid.py trees/article_type.yaml -o output.md

The output can be embedded in Markdown for GitHub rendering.
"""

import argparse
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Required package not found. Install with:")
    print("  pip install pyyaml")
    sys.exit(1)


def yaml_to_mermaid(yaml_path: Path) -> str:
    """
    Convert a YAML decision tree to Mermaid flowchart syntax.
    """
    with open(yaml_path, 'r') as f:
        tree = yaml.safe_load(f)

    dt = tree['decision_tree']
    nodes = dt.get('nodes', {})
    root = dt.get('root')
    name = dt.get('name', 'Decision Tree')

    lines = [
        f"```mermaid",
        f"flowchart TD",
        f"    %% {name}",
        f"    %% Auto-generated from {yaml_path.name}",
        f"",
    ]

    # Track which nodes we've defined
    defined = set()

    def get_node_label(node_id: str, node: dict) -> str:
        """Generate node label based on type."""
        if node.get('type') == 'decision':
            question = node.get('question', node_id)
            # Escape quotes for Mermaid
            question = question.replace('"', "'")
            return f'{node_id}{{"{question}"}}'
        elif node.get('type') == 'result':
            result = node.get('result', node_id)
            return f'{node_id}["{result}"]'
        elif node.get('type') == 'action':
            action = node.get('action', node_id)
            action = action.replace('"', "'")
            return f'{node_id}[/"{action}"/]'
        return f'{node_id}["{node_id}"]'

    def process_branch(source_id: str, target, branch_label: str):
        """Process a yes/no branch."""
        if isinstance(target, dict):
            # Inline result
            result = target.get('result', 'Result')
            result_id = f"{source_id}_{branch_label}_result"
            lines.append(f'    {result_id}["{result}"]')
            lines.append(f'    {source_id} -->|{branch_label}| {result_id}')
        elif isinstance(target, str):
            if target in nodes:
                if target not in defined:
                    target_node = nodes[target]
                    lines.append(f'    {get_node_label(target, target_node)}')
                    defined.add(target)
                lines.append(f'    {source_id} -->|{branch_label}| {target}')
            else:
                # Assume it's a result value
                result_id = f"{source_id}_{branch_label}_result"
                lines.append(f'    {result_id}["{target}"]')
                lines.append(f'    {source_id} -->|{branch_label}| {result_id}')

    # Start with root node
    if root and root in nodes:
        root_node = nodes[root]
        lines.append(f'    {get_node_label(root, root_node)}')
        defined.add(root)

    # Process all nodes
    for node_id, node in nodes.items():
        if node_id not in defined:
            lines.append(f'    {get_node_label(node_id, node)}')
            defined.add(node_id)

        # Process branches (handle YAML boolean key interpretation)
        if node.get('type') == 'decision':
            yes_target = node.get('yes') or node.get(True)
            no_target = node.get('no') or node.get(False)
            if yes_target:
                process_branch(node_id, yes_target, 'Yes')
            if no_target:
                process_branch(node_id, no_target, 'No')
        elif node.get('type') == 'action':
            next_target = node.get('yes') or node.get(True)
            if next_target:
                process_branch(node_id, next_target, '')

    lines.append("```")

    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(
        description='Convert YAML decision trees to Mermaid format'
    )
    parser.add_argument('yaml_file', type=Path, help='YAML decision tree file')
    parser.add_argument('-o', '--output', type=Path, help='Output file (default: stdout)')

    args = parser.parse_args()

    if not args.yaml_file.exists():
        print(f"Error: File not found: {args.yaml_file}")
        return 1

    mermaid = yaml_to_mermaid(args.yaml_file)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(mermaid)
        print(f"Written to {args.output}")
    else:
        print(mermaid)

    return 0


if __name__ == "__main__":
    sys.exit(main())

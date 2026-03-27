#!/usr/bin/env python3
"""
Interactive JARS compliance checker using decision trees.

Usage:
    python checker.py                     # Interactive mode
    python checker.py --type quant        # Start with specific type

This tool walks through the decision trees interactively,
asking questions and recording compliance status.
"""

import argparse
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

try:
    import yaml
except ImportError:
    print("Required package not found. Install with:")
    print("  pip install pyyaml")
    sys.exit(1)


@dataclass
class ComplianceResult:
    """Result of compliance check."""
    article_type: str = ""
    universal_compliance: dict = field(default_factory=dict)
    type_compliance: dict = field(default_factory=dict)
    missing_elements: list = field(default_factory=list)
    overall_compliant: bool = False


def load_tree(tree_name: str) -> dict:
    """Load a decision tree by name."""
    trees_dir = Path(__file__).parent.parent / "trees"
    yaml_path = trees_dir / f"{tree_name}.yaml"
    with open(yaml_path, 'r') as f:
        return yaml.safe_load(f)['decision_tree']


def ask_yes_no(question: str) -> bool:
    """Ask a yes/no question interactively."""
    while True:
        response = input(f"\n{question}\n[y/n]: ").strip().lower()
        if response in ('y', 'yes'):
            return True
        elif response in ('n', 'no'):
            return False
        print("Please enter 'y' or 'n'")


def show_evidence(node: dict):
    """Display evidence/verification methods for a node."""
    evidence = node.get('evidence', [])
    if evidence:
        print("\n  Evidence to check:")
        for e in evidence:
            print(f"    - {e}")


def walk_tree(tree: dict, verbose: bool = True) -> tuple[str, list]:
    """
    Walk through a decision tree interactively.

    Returns:
        (result, list_of_failed_checks)
    """
    nodes = tree['nodes']
    current = tree['root']
    failed = []

    while current and current in nodes:
        node = nodes[current]
        node_type = node.get('type')

        if node_type == 'result':
            result = node.get('result', 'Complete')
            if verbose:
                print(f"\n✓ Result: {result}")
            return result, failed

        elif node_type == 'decision':
            question = node.get('question', 'Proceed?')
            if verbose:
                show_evidence(node)

            answer = ask_yes_no(question)

            # Handle YAML boolean key interpretation (yes/no become True/False)
            if answer:
                target = node.get('yes') or node.get(True)
            else:
                target = node.get('no') or node.get(False)
                axioms = node.get('axioms', [])
                if axioms:
                    failed.append({
                        'question': question,
                        'axioms': axioms
                    })

            # Handle inline results
            if isinstance(target, dict):
                result = target.get('result', 'Complete')
                if verbose:
                    print(f"\n✓ Result: {result}")
                return result, failed
            else:
                current = target

        elif node_type == 'action':
            action = node.get('action', 'Perform action')
            if verbose:
                print(f"\n→ Action: {action}")
            input("Press Enter to continue...")
            # Handle YAML boolean key interpretation
            current = node.get('yes') or node.get(True)

    return "Unknown", failed


def determine_article_type() -> str:
    """Determine article type using the article_type decision tree."""
    print("\n" + "=" * 50)
    print("STEP 1: Determine Article Type")
    print("=" * 50)

    tree = load_tree("article_type")
    result, _ = walk_tree(tree)

    return result


def check_method_section(article_type: str) -> ComplianceResult:
    """Check method section compliance based on article type."""
    print("\n" + "=" * 50)
    print("STEP 2: Check Method Section")
    print("=" * 50)

    result = ComplianceResult(article_type=article_type)

    if article_type == "JARS-Quant":
        tree = load_tree("method_quant")
    elif article_type == "JARS-Qual":
        tree = load_tree("method_qual")
    elif article_type == "JARS-Mixed":
        tree = load_tree("method_mixed")
    else:
        print(f"Unknown article type: {article_type}")
        return result

    check_result, failed = walk_tree(tree)
    result.type_compliance = {'result': check_result, 'failed': failed}
    result.missing_elements = [f['question'] for f in failed]
    result.overall_compliant = len(failed) == 0

    return result


def print_report(result: ComplianceResult):
    """Print compliance report."""
    print("\n" + "=" * 50)
    print("COMPLIANCE REPORT")
    print("=" * 50)

    print(f"\nArticle Type: {result.article_type}")
    print(f"Overall Compliant: {'Yes ✓' if result.overall_compliant else 'No ✗'}")

    if result.missing_elements:
        print("\nMissing Elements:")
        for item in result.missing_elements:
            print(f"  ✗ {item}")


def main():
    parser = argparse.ArgumentParser(
        description='Interactive JARS compliance checker'
    )
    parser.add_argument(
        '--type',
        choices=['quant', 'qual', 'mixed'],
        help='Skip type detection and use specified type'
    )

    args = parser.parse_args()

    print("\n" + "=" * 50)
    print("JARS COMPLIANCE CHECKER")
    print("Based on APA 7 Axiomatization Decision Trees")
    print("=" * 50)

    # Determine article type
    if args.type:
        type_map = {
            'quant': 'JARS-Quant',
            'qual': 'JARS-Qual',
            'mixed': 'JARS-Mixed'
        }
        article_type = type_map[args.type]
        print(f"\nUsing specified type: {article_type}")
    else:
        article_type = determine_article_type()

    # Check method section
    result = check_method_section(article_type)

    # Print report
    print_report(result)

    return 0 if result.overall_compliant else 1


if __name__ == "__main__":
    sys.exit(main())

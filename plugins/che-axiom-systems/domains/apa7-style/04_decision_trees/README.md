# Machine-Readable Decision Trees

This directory contains YAML-formatted decision trees for the APA 7 axiomatization system. These trees are designed to be:

1. **Machine-readable** - Parsable by Python, R, or any YAML-compatible tool
2. **Validatable** - Verified against JSON Schema
3. **Convertible** - Can generate Mermaid diagrams for visualization
4. **Interactive** - Can power compliance checking tools

## Directory Structure

```
07_decision_trees/
├── README.md                    # This file
├── schemas/
│   └── decision_tree.schema.json  # JSON Schema for validation
├── trees/
│   ├── article_type.yaml         # Article type determination
│   ├── compliance_check.yaml     # Overall compliance verification
│   ├── method_quant.yaml         # Quantitative method section
│   ├── method_qual.yaml          # Qualitative method section
│   └── method_mixed.yaml         # Mixed methods section
└── tools/
    ├── validate.py               # YAML validation tool
    ├── to_mermaid.py             # YAML → Mermaid converter
    └── checker.py                # Interactive compliance checker
```

## Decision Trees

| Tree | Purpose | Root Node |
|------|---------|-----------|
| `article_type.yaml` | Determine JARS type (Quant/Qual/Mixed) | `identify_method` |
| `compliance_check.yaml` | Verify overall JARS compliance | `determine_type` |
| `method_quant.yaml` | Check quantitative method section | `start_method` |
| `method_qual.yaml` | Check qualitative method section | `start_method` |
| `method_mixed.yaml` | Check mixed methods section | `start_method` |

## YAML Format

```yaml
decision_tree:
  name: "Tree Name"
  version: "1.0"
  description: "What this tree does"
  root: "starting_node_id"

  nodes:
    node_id:
      type: "decision"           # decision, result, or action
      question: "Yes/No question"
      axioms: ["Q1", "Q2"]       # Related axioms
      evidence:                  # Verification criteria
        - "Check this"
        - "Check that"
      yes: "next_node_id"        # Node ID or inline result
      no: "other_node_id"
```

## Usage

### Validate Trees

```bash
cd 07_decision_trees/tools

# Validate all trees
python validate.py

# Validate specific tree
python validate.py ../trees/article_type.yaml
```

### Generate Mermaid Diagrams

```bash
# Print to stdout
python to_mermaid.py ../trees/article_type.yaml

# Save to file
python to_mermaid.py ../trees/article_type.yaml -o article_type.md
```

### Interactive Compliance Check

```bash
# Full interactive mode
python checker.py

# Skip to specific type
python checker.py --type quant
python checker.py --type qual
python checker.py --type mixed
```

## Integration Examples

### Python

```python
import yaml

with open('trees/article_type.yaml', 'r') as f:
    tree = yaml.safe_load(f)

# Access nodes
nodes = tree['decision_tree']['nodes']
root = tree['decision_tree']['root']

# Walk the tree programmatically
current = root
while current in nodes:
    node = nodes[current]
    if node['type'] == 'result':
        print(f"Result: {node['result']}")
        break
    # ... process decision nodes
```

### R

```r
library(yaml)

tree <- yaml.load_file("trees/article_type.yaml")
nodes <- tree$decision_tree$nodes
root <- tree$decision_tree$root

# Process nodes
for (node_id in names(nodes)) {
  node <- nodes[[node_id]]
  if (node$type == "decision") {
    cat("Question:", node$question, "\n")
  }
}
```

## Extending

To add a new decision tree:

1. Create a new YAML file in `trees/`
2. Follow the schema in `schemas/decision_tree.schema.json`
3. Validate with `python tools/validate.py`
4. Generate visualization with `python tools/to_mermaid.py`

## Related

- [02_jars_standards/jars_visual_framework.md](../02_jars_standards/jars_visual_framework.md) - Original ASCII diagrams
- [02_jars_standards/jars_requirements.md](../02_jars_standards/jars_requirements.md) - Detailed requirements

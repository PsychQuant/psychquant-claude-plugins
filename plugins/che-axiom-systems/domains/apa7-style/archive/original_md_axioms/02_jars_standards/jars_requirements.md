# Detailed JARS Requirements Axiomatization

## 1. JARS-Quant (Quantitative Research) Axiomatization

### 1.1 Method Section Axioms

**Axiom Q1 (Participant Description)**: 
∀a ∈ A_quant, ∃d ∈ Descriptions(a) such that Contains(d, demographics) ∧ Contains(d, sampling_method) ∧ Contains(d, sample_size)

**Axiom Q2 (Measurement Specification)**:
∀m ∈ Measures(a), Reports(a, reliability(m)) ∧ Reports(a, validity(m)) ∧ Reports(a, scoring(m))

**Axiom Q3 (Statistical Power)**:
∀a ∈ A_quant, (Experimental(a) → Reports(a, power_analysis)) ∧ Reports(a, effect_size)

### 1.2 Results Section Axioms

**Axiom Q4 (Statistical Reporting)**:
∀test ∈ StatisticalTests(a), Reports(a, test_statistic) ∧ Reports(a, df) ∧ Reports(a, p_value) ∧ Reports(a, effect_size) ∧ Reports(a, CI)

**Axiom Q5 (Data Completeness)**:
∀a ∈ A_quant, Reports(a, missing_data) ∧ Reports(a, exclusions) ∧ Reports(a, violations)

### 1.3 Specific Requirements by Design

**Definition Q1 (Experimental Studies)**:
- Random assignment method
- Manipulation details
- Control conditions
- Blinding procedures

**Definition Q2 (Observational Studies)**:
- Sampling frame
- Response rates
- Measurement timing
- Confounding variables

**Definition Q3 (Meta-Analysis)**:
- Search strategy
- Inclusion/exclusion criteria
- Coding procedures
- Heterogeneity assessment

## 2. JARS-Qual (Qualitative Research) Axiomatization

### 2.1 Method Section Axioms

**Axiom QL1 (Researcher Positioning)**:
∀a ∈ A_qual, Reports(a, researcher_background) ∧ Reports(a, researcher_perspective) ∧ Reports(a, researcher_relationship)

**Axiom QL2 (Context Specification)**:
∀a ∈ A_qual, Reports(a, setting) ∧ Reports(a, cultural_context) ∧ Reports(a, temporal_context)

**Axiom QL3 (Data Collection)**:
∀method ∈ DataCollection(a), Reports(a, procedure(method)) ∧ Reports(a, duration(method)) ∧ Reports(a, saturation_criteria)

### 2.2 Analysis Axioms

**Axiom QL4 (Analytic Process)**:
∀a ∈ A_qual, Reports(a, coding_process) ∧ Reports(a, theme_development) ∧ Reports(a, credibility_checks)

**Axiom QL5 (Trustworthiness)**:
∀a ∈ A_qual, ∃t ∈ TrustworthinessStrategies such that Implements(a, t) ∧ Reports(a, t)

### 2.3 Findings Presentation

**Definition QL1 (Evidence Requirements)**:
- Direct quotes
- Thick description
- Negative cases
- Pattern documentation

**Definition QL2 (Interpretation Levels)**:
- Descriptive findings
- Conceptual findings
- Theoretical findings

## 3. JARS-Mixed (Mixed Methods) Axiomatization

### 3.1 Integration Axioms

**Axiom M1 (Design Specification)**:
∀a ∈ A_mixed, Reports(a, mixed_design_type) ∧ Reports(a, integration_rationale) ∧ Reports(a, priority)

**Axiom M2 (Component Interaction)**:
∀a ∈ A_mixed, ∃i ∈ IntegrationPoints such that Describes(a, i) ∧ Shows(a, influence(quant→qual)) ∧ Shows(a, influence(qual→quant))

**Axiom M3 (Joint Display)**:
∀a ∈ A_mixed where Integrated(findings), ∃display ∈ Presentations(a) such that Shows(display, quant_results) ∧ Shows(display, qual_results) ∧ Shows(display, integration)

### 3.2 Quality Criteria

**Axiom M4 (Dual Quality)**:
∀a ∈ A_mixed, SatisfiesQuality(quant_component(a), JARS_Quant) ∧ SatisfiesQuality(qual_component(a), JARS_Qual)

**Axiom M5 (Integration Quality)**:
∀a ∈ A_mixed, ∃q ∈ QualityIndicators such that Demonstrates(a, mixing_quality) ∧ Demonstrates(a, inference_quality)

## 4. Universal Reporting Requirements

### 4.1 Title and Abstract

**Axiom U1 (Title Informativeness)**:
∀a ∈ A, Contains(title(a), study_type) ∧ Contains(title(a), main_topic) ∧ Length(title(a)) ≤ 12_words

**Axiom U2 (Abstract Completeness)**:
∀a ∈ A, Contains(abstract(a), objective) ∧ Contains(abstract(a), method) ∧ Contains(abstract(a), results) ∧ Contains(abstract(a), conclusions)

### 4.2 Ethical Considerations

**Axiom U3 (Ethics Reporting)**:
∀a ∈ A where Involves(a, human_participants), Reports(a, IRB_approval) ∧ Reports(a, informed_consent) ∧ Reports(a, ethical_issues)

**Axiom U4 (Transparency)**:
∀a ∈ A, Reports(a, funding) ∧ Reports(a, conflicts) ∧ Reports(a, data_availability) ∧ Reports(a, preregistration)

## 5. Formal Rules for Compliance Checking

### 5.1 Quantitative Compliance Function
```
CompliesQuant(a) := 
  ∀ax ∈ {Q1, Q2, Q3, Q4, Q5}, Satisfies(a, ax) ∧
  ∀req ∈ DesignSpecificReqs(design(a)), Meets(a, req)
```

### 5.2 Qualitative Compliance Function
```
CompliesQual(a) := 
  ∀ax ∈ {QL1, QL2, QL3, QL4, QL5}, Satisfies(a, ax) ∧
  ∀ev ∈ EvidenceReqs, Provides(a, ev)
```

### 5.3 Mixed Methods Compliance Function
```
CompliesMixed(a) := 
  CompliesQuant(quant_component(a)) ∧
  CompliesQual(qual_component(a)) ∧
  ∀ax ∈ {M1, M2, M3, M4, M5}, Satisfies(a, ax)
```

### 5.4 Universal Compliance Function
```
CompliesUniversal(a) := 
  ∀ax ∈ {U1, U2, U3, U4}, Satisfies(a, ax)
```

### 5.5 Overall Compliance
```
CompliesJARS(a) := 
  CompliesUniversal(a) ∧
  [Type(a) = Quant → CompliesQuant(a)] ∧
  [Type(a) = Qual → CompliesQual(a)] ∧
  [Type(a) = Mixed → CompliesMixed(a)]
```

## 6. Theorems and Corollaries

**Theorem M1**: A mixed methods article requires more reporting elements than either pure quantitative or pure qualitative articles.
- Proof: |Requirements(Mixed)| = |Requirements(Quant)| + |Requirements(Qual)| + |Requirements(Integration)| - |Overlap|

**Theorem U1**: The abstract word limit forces prioritization of information.
- Proof: Given word_limit = 250 and required_elements = 4, average_per_element ≤ 62.5 words

**Corollary Q1**: Power analysis reporting prevents underpowered studies from claiming null results.

**Corollary QL1**: Researcher positioning reporting enables reflexivity assessment.

## 7. Implementation Checklist Generator

Given an article type, generate checklist:
```
GenerateChecklist(type) := 
  universalItems ∪ 
  (type = Quant ? quantItems : ∅) ∪
  (type = Qual ? qualItems : ∅) ∪
  (type = Mixed ? quantItems ∪ qualItems ∪ mixedItems : ∅)
```
# Chapter 4 Detailed Writing Rules: Axiomatization

## 1. Verb Tense Axiomatization

### 1.1 Tense Assignment Function
```
TenseAssignment: Section × Context → Tense

TenseAssignment(section, context) = 
    match (section, context):
        (LiteratureReview, established_knowledge) → SimplePast
        (LiteratureReview, ongoing_relevance) → PresentPerfect
        (Method, procedure) → SimplePast
        (Method, description_of_stimulus) → SimplePast
        (Results, findings) → SimplePast
        (Discussion, result_interpretation) → Present
        (Discussion, study_implications) → Present
        (Discussion, future_research) → Future/Modal
```

### 1.2 Tense Consistency Axioms

**Axiom T1 (Primary Tense Dominance)**: 
∀section ∈ Paper, |{s : s ∈ Sentences(section) ∧ Tense(s) = PrimaryTense(section)}| ≥ 0.7 × |Sentences(section)|

**Axiom T2 (Tense Shift Justification)**:
∀s₁, s₂ ∈ Sentences where Adjacent(s₁, s₂) ∧ Tense(s₁) ≠ Tense(s₂) → ∃reason ∈ ValidReasons

**Valid Tense Shift Reasons**:
1. Citation integration: Past study + present relevance
2. Method to result transition
3. Specific to general claims
4. Historical to current context

## 2. Voice Selection Axiomatization

### 2.1 Voice Preference Function
```
VoicePreference: Sentence × Context → {Active, Passive}

Prefer(Active) when:
    - Actor(sentence) = Researchers ∧ Important(Actor)
    - Clarity(Active) > Clarity(Passive)
    - DirectStatement(sentence)

Prefer(Passive) when:
    - Focus(sentence) = Receiver(Action)
    - Actor(sentence) = Unknown ∨ Irrelevant
    - ScientificConvention(sentence)
```

### 2.2 Voice Axioms

**Axiom V1 (Active Default)**: 
∀s ∈ Sentences, ¬∃reason ∈ PassiveReasons → Voice(s) = Active

**Axiom V2 (Voice Clarity Principle)**:
∀s ∈ Sentences, Ambiguous(Actor(s)) → RequireRevision(s)

## 3. Pronoun Usage Axiomatization

### 3.1 Pronoun Resolution Rules

**Axiom P1 (Antecedent Clarity)**:
∀pronoun ∈ Pronouns, ∃!antecedent such that Refers(pronoun, antecedent) ∧ Clear(Reference)

**Axiom P2 (Pronoun Distance)**:
∀pronoun ∈ Pronouns, Distance(pronoun, Antecedent(pronoun)) ≤ 2_sentences

**Axiom P3 (First Person Usage)**:
FirstPerson(pronoun) → Context(pronoun) ∈ {DescribingOwnResearch, AuthorAction}

### 3.2 Singular "They" Rules

**Definition P1**: SingularThey(pronoun) ≡ Number(pronoun) = Singular ∧ Form(pronoun) = "they/them/their"

**Rule P1**: GenderUnknown(referent) ∨ GenderIrrelevant(referent) → UseSingularThey

## 4. Clarity Optimization Axioms

### 4.1 Word Choice Hierarchy
```
WordChoice Priority:
1. Common words > Uncommon words
2. Concrete terms > Abstract terms
3. Specific terms > Vague terms
4. Short words > Long words (when equal meaning)
```

### 4.2 Sentence Structure Axioms

**Axiom S1 (Subject-Verb Proximity)**:
∀sentence, Distance(Subject(sentence), MainVerb(sentence)) ≤ 7_words

**Axiom S2 (Modifier Attachment)**:
∀modifier, Distance(modifier, Modified) = minimal ∧ Unambiguous(Attachment)

**Axiom S3 (Parallel Lists)**:
∀item₁, item₂ ∈ List, GrammaticalForm(item₁) = GrammaticalForm(item₂)

## 5. Conciseness Formalization

### 5.1 Redundancy Detection
```
RedundancyPatterns = {
    ("absolutely" + absolute_term): Remove("absolutely"),
    ("completely" + completion_verb): Remove("completely"),
    ("in order to"): Replace("to"),
    ("due to the fact that"): Replace("because"),
    ("at this point in time"): Replace("now"),
    ("each and every"): Replace("each" | "every"),
    ("first and foremost"): Replace("first"),
    ("future plans"): Replace("plans")
}
```

### 5.2 Nominalization Transformation
```
NominalizationRules = {
    V + "tion/sion" → V:
        "make a decision" → "decide"
        "give consideration" → "consider"
        "conduct an analysis" → "analyze"
    
    "is/are" + ADJ + "of" → V:
        "is indicative of" → "indicates"
        "is suggestive of" → "suggests"
}
```

## 6. Transition Logic Axiomatization

### 6.1 Transition Types
```
TransitionType = {
    Addition: {furthermore, moreover, additionally, also},
    Contrast: {however, nevertheless, in contrast, whereas},
    Cause: {therefore, thus, consequently, as a result},
    Example: {for example, for instance, specifically},
    Time: {subsequently, meanwhile, previously},
    Summary: {in summary, overall, in conclusion}
}
```

### 6.2 Transition Placement Rules

**Axiom TR1 (Paragraph Transitions)**:
∀p₁, p₂ where Sequential(p₁, p₂), ∃t ∈ Transitions : Places(t, End(p₁)) ∨ Places(t, Start(p₂))

**Axiom TR2 (Transition Appropriateness)**:
∀t ∈ Transitions used, Type(t) matches Relationship(Previous, Next)

## 7. Anthropomorphism Avoidance

### 7.1 Anthropomorphism Detection
```
AnthropomorphicPatterns = {
    Study/Research + human_action_verb,
    Table/Figure + cognitive_verb,
    Theory/Model + intentional_verb
}
```

### 7.2 Correction Rules
```
"The study examined..." → "We examined..." | "The researchers examined..."
"Table 1 shows..." → "Table 1 presents..." | "As shown in Table 1..."
"The theory argues..." → "The theory proposes..." | "According to the theory..."
```

## 8. Bias-Free Language Axioms

### 8.1 People-First Language

**Axiom BF1**: 
∀description of people, PersonFirst(description) ∨ IdentityFirst(description) where PreferredByGroup

**Examples**:
- "people with disabilities" (person-first)
- "autistic individuals" (identity-first, if preferred)

### 8.2 Gender-Inclusive Language

**Axiom BF2**:
∀generic_reference, ¬GenderSpecific(reference) unless GenderRelevant(context)

**Implementation**:
- "policeman" → "police officer"
- "mankind" → "humankind"
- "he/she" → "they" | restructure

## 9. Emphasis Techniques Axiomatization

### 9.1 Emphasis Hierarchy
```
EmphasisStrength (ascending):
1. Word order (weakest)
2. Punctuation (colon, dash)
3. Syntactic structure
4. Explicit markers ("importantly", "notably")
5. Typographic (italics) (strongest in text)
```

### 9.2 Emphasis Rules

**Rule E1**: ImportantPoint(p) → Position(p) ∈ {SentenceEnd, ParagraphStart, ParagraphEnd}

**Rule E2**: Emphasis(point) → UseOnlyOne(EmphasisMethod)

## 10. Sentence Variety Formalization

### 10.1 Sentence Types
```
SentenceStructures = {
    Simple: [Subject + Verb + Object],
    Compound: [Independent + Coordinator + Independent],
    Complex: [Independent + Subordinate],
    Compound-Complex: [Multiple_Independent + Subordinate]
}
```

### 10.2 Variety Metrics
```
VarietyScore(paragraph) = 
    StructuralVariety × 0.3 +
    LengthVariety × 0.3 +
    OpeningVariety × 0.4

where:
    StructuralVariety = |UniqueStructures| / |Sentences|
    LengthVariety = 1 - (StdDev(Lengths) / Mean(Lengths))
    OpeningVariety = |UniqueOpenings| / |Sentences|
```

## 11. Implementation Algorithms

### 11.1 Clarity Score Algorithm
```python
def calculate_clarity_score(text):
    factors = {
        'avg_sentence_length': (15, 20),  # ideal range
        'passive_voice_ratio': 0.2,       # max acceptable
        'nominalization_density': 0.1,     # max acceptable
        'jargon_definition_ratio': 0.9,   # min required
        'pronoun_clarity': 0.95           # min required
    }
    
    score = 1.0
    
    # Sentence length penalty
    avg_len = average_sentence_length(text)
    if not factors['avg_sentence_length'][0] <= avg_len <= factors['avg_sentence_length'][1]:
        score *= 0.9
    
    # Passive voice penalty
    if passive_ratio(text) > factors['passive_voice_ratio']:
        score *= 0.85
    
    # Continue for other factors...
    return score
```

### 11.2 Conciseness Optimizer
```python
def optimize_conciseness(text):
    # Apply transformation rules
    for pattern, replacement in RedundancyPatterns:
        text = apply_pattern(text, pattern, replacement)
    
    for pattern, replacement in NominalizationRules:
        text = apply_pattern(text, pattern, replacement)
    
    # Remove empty phrases
    empty_phrases = ["it is important to note that", "it should be noted that"]
    for phrase in empty_phrases:
        text = text.replace(phrase, "")
    
    return text.strip()
```

## 12. Quality Assurance Checklist

### 12.1 Sentence Level
- [ ] Active voice used (unless passive justified)
- [ ] Subject-verb agreement correct
- [ ] Modifiers placed correctly
- [ ] Pronouns have clear antecedents
- [ ] Parallel structure in lists

### 12.2 Paragraph Level
- [ ] Clear topic sentence
- [ ] Logical flow between sentences
- [ ] Appropriate transitions
- [ ] Consistent focus
- [ ] Adequate development

### 12.3 Section Level
- [ ] Appropriate tense usage
- [ ] Consistent terminology
- [ ] Clear transitions between paragraphs
- [ ] Logical organization
- [ ] Appropriate emphasis

## 13. Common Error Patterns and Corrections

### 13.1 Tense Errors
```
Error: "The participants have completed the survey yesterday."
Correction: "The participants completed the survey yesterday."
Rule: Specific past time → Simple past

Error: "Smith (2020) argues that this was important."
Correction: "Smith (2020) argues that this is important."
Rule: Cited author's current position → Present tense
```

### 13.2 Voice Errors
```
Error: "The survey was completed by 50 participants."
Correction: "Fifty participants completed the survey."
Rule: Known actor performing action → Active voice

Error: "We were surprised by the results."
Correction: "The results surprised us."
Rule: Focus on results → Active voice with results as subject
```

### 13.3 Clarity Errors
```
Error: "The participants in the study that we conducted last year were satisfied."
Correction: "The participants in our study last year were satisfied."
Rule: Reduce embedded clauses for clarity

Error: "This demonstrates that it is clear that the hypothesis was supported."
Correction: "This demonstrates that the hypothesis was supported."
Rule: Remove redundant clarity markers
```
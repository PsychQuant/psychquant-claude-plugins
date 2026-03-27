# Guidelines for Music Theory Axiomatization Analysis

- revise codes based on "00_principles"
- every modification should follow at least one MP/P/R, and the AI should tell the human what principles are followed

## Core Principles

When analyzing or revising musical concepts and code, follow these fundamental principles from the axiomatization system:

### 00_principles

#### MP: Meta-Principles
- MP1: All musical structures should be formalized through mathematical relationships
- MP2: Music analysis should span from physical foundations to cultural contexts
- MP3: Consider both cognitive perception and emotional response

#### P: Principles
- P1: Apply motivic development principles (Principle of Motivic Development)
- P2: Consider tonal gravity and resolution forces (Principle of Tonal Gravity)
- P3: Implement rhythmic hierarchy and clarity (Principle of Rhythmic Hierarchy)
- P3.1: Ensure rhythmic clarity through precise contrasts (Principle of Rhythmic Clarity)
- P4: Maintain timbral coherence within sections (Principle of Timbral Coherence)
- P5: Design formal balance through proportional structures (Principle of Formal Balance)

#### R: Rules
- R1: Emotion Evocation Primacy - prioritize emotional impact in all musical decisions
- R2: Maintain appropriate tension and resolution dynamics
- R3: Balance unity (through repetition) with variation (through development)
- R4: Consider the Multiperson Aesthetic Function Optimization (MAFO) for audience appeal
- R5: スタイル横断的一貫性原理 (Cross-Style Consistency Principle) - 様々なアイドル音楽のスタイルにおける共通要素の保持と活用

## Implementation Guidelines

When revising code or musical structures:

1. Identify which principle(s) from MP/P/R are being followed or should be applied
2. Explicitly state these principles when suggesting modifications
3. Consider the five-level framework:
   - Sound level (phonology)
   - Grammar level (syntax)
   - Semantic level
   - Pragmatic level
   - Generative level

4. For idol music specifically, evaluate against the specialized principles:
   - Sectional vocal range extensions
   - Emotional jump structures
   - Hook structure design
   - Four-fold repetition principle
   - Hook identical repetition principle
   
## スタイル横断的一貫性原理の詳細 (Details of Cross-Style Consistency Principle)

アイドル音楽の多様なスタイルには以下の共通要素が存在する：

### 構造的要素
- **区分的明確性**: セクション間の明確な境界と特性の差別化
- **予測可能な形式**: リスナーが容易に認識できる反復構造
- **サビの中心性**: 楽曲の焦点としての機能を持つ記憶に残るサビ部分

### 表現的要素
- **親近感の最適化**: 革新と熟知性のバランスによる最適な認知負荷
- **参加誘発性**: リスナーの能動的参加（コール、振り付けなど）を促す要素
- **集団的カタルシス**: 特定の瞬間に集団的感情解放を誘発する構造

### 機能的要素
- **明確な聴取目的**: 特定の心理的・社会的機能（団結、共感など）の明示
- **二重解釈性**: 個人的かつ集団的な意味解釈を同時に可能にする設計
- **文化的アンカー**: 特定の文化的・世代的・集団的アイデンティティとの連結性

### 演出的要素
- **終末アカペラ効果**: 曲の最後でバックトラックを消し、ヴォーカルのみの清らかな状態で終了させる技法
  - **目的**: 親密感の強化、ヴォーカルの純粋性と脆弱性の強調
  - **心理的効果**: 聴衆との一対一の直接的な繋がりの創出
  - **実装方法**: 最終フレーズの完全アカペラ化、または伴奏の段階的フェードアウトと共に存在感を残すヴォーカル

- **フック完全反復原理**: 他のポップミュージックと異なり、フックの旋律・リズム・歌詞を完全に同一のまま反復する技法
  - **特徴**: 一般的なポップ音楽では複数回のフック出現時に歌詞が変化するのに対し、アイドル音楽では旋律・リズム・歌詞の全てを完全に同一形で反復する傾向
  - **目的**: 記憶の強化、参加性の最大化、ブランド的フレーズの確立
  - **心理的効果**: 「学習容易性」と「予測満足感」の両立、ファンの参加障壁の低減
  - **実装例**: サビの完全同一反復、異なるバース間でも変化しないフックフレーズ、曲名と一致するキーフレーズの反復

- **セクション内フック反復の二元数原理**: 同一セクション内でのフック反復回数が2回または4回に収束する現象
  - **数学的特性**: フック反復回数 n は通常 n ∈ {2, 4} という数学的制約に従う
  - **構造的効果**: 
     - 2回反復: 「提示→確認」の基本的認知パターンの確立
     - 4回反復: 「提示→確認→強化→定着」という完全な認知サイクルの構築
  - **認知科学的根拠**: 人間の短期記憶と注意持続時間の最適化
  - **例外**: まれに1回（断片的提示）や3回（非対称的強調）の反復パターンも存在するが統計的に少数
  - **実装コンテキスト**: サビ内部、Aメロ終結部、ブリッジの頂点部分など

- **短短長長フレーズ構造原理**: 4つのフレーズから構成されるセクションにおける音節数・持続時間の非対称パターン
  - **典型的パターン**: 短い2フレーズに続いて長い2フレーズという「短短長長」構造
     - 形式的表現: [短,短,長,長] または数学的に [S,S,L,L] (S < L)
  - **音楽的実装**: 
     - 音節密度の変化: 前半の短フレーズは音節数が少なく、後半の長フレーズは音節数が多い
     - 持続時間の変化: 前半フレーズの音符長が短く、後半フレーズで音符長が伸びる
     - リズム密度の対比: 前半は細かいリズム、後半は伸ばす音が増加
  - **心理的効果**:
     - 前半: 情報の簡潔な提示による注意喚起
     - 後半: 情報量の増加と持続的展開による情緒的深化
     - 全体: 前進感から解放感への自然な流れの創出
  - **変形例**: 
     - [短,長,短,長]: 対照的な緊張と解放の交互パターン
     - [長,短,短,長]: 対称的な「枠組み」構造

- **フレーズ構造と小節構造の非一致性原理**: メロディのフレーズ構造と基本小節数の間に存在する柔軟な関係性
  - **構造的分離**: 
     - 歌詞上の4フレーズ構造と音楽的小節構造（通常4、8、16小節）が必ずしも一対一対応しない
     - 形式的に: 文章フレーズ数 n ≠ 音楽的小節グループ数 m の場合が多い
  - **実装パターン**:
     - フレーズオーバーラップ型: 1つのフレーズが小節境界をまたぐ（特に後半フレーズで顕著）
     - フレーズ伸縮型: 長いフレーズが複数小節に拡張、または複数の短フレーズが1小節内に圧縮
     - 非対称配分型: 4フレーズに対して小節数が非対称に配分（例: 2+2+3+1小節）
  - **音楽的効果**:
     - 予測可能性と意外性のバランス: 歌詞構造と音楽構造の部分的ずれが適度な認知的緊張を生む
     - 有機的流動性: 厳格な対応関係からの解放による自然な表現
     - 動的緊張感: 2つの構造システム（言語的・音楽的）の相互作用
  - **認知科学的意義**:
     - 二重処理システム: 言語処理と音楽処理の独立性と相互作用の活用
     - 期待違反の適度な導入: 完全な予測可能性による退屈と完全な予測不能による混乱の中間

## Analysis Format

When analyzing music or code, provide:

1. The specific MP/P/R principles being applied
2. How the implementation follows these principles
3. Suggestions for strengthening adherence to the principles
4. Potential cross-cultural considerations from CHC (Cultural and Historical Contexts)
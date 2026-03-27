# Structural Constraints on Weight Curves

**體重曲線的結構化限制**

This document formalizes the constraints that physics and physiology impose on the shape of body weight time series. These constraints are not statistical regularities—they are logical necessities derived from mass conservation.

---

## 1. The Fundamental Asymmetry

### 1.1 Core Observation

The key insight is an asymmetry between weight gain and weight loss:

```text
Weight INCREASES (E⁺):
├── DISCRETE events only
│   ├── Eating (mass enters through mouth)
│   ├── Drinking (mass enters through mouth)
│   └── IV infusion (rare, medical)
└── NO continuous increase pathway exists

Weight DECREASES (E⁻):
├── CONTINUOUS pathways (always active):
│   ├── Respiration (CO₂ + H₂O vapor) ～50-80 g/hr
│   └── Skin evaporation (insensible) ～10-20 g/hr
│
└── DISCRETE events (intermittent):
    ├── Urination (尿尿) ～200-500 g/event
    ├── Defecation (大便) ～100-300 g/event
    ├── Exercise sweat (運動流汗) ～0.5-2 kg/session
    └── Vomiting/bleeding (rare, medical)
```

### 1.2 Event Type Classification

```text
增加體重 E⁺           減少體重 E⁻
─────────────────────────────────────────────────
    ↓ 只有離散        連續 ↓         ↓ 離散

  ┌─┐ eat           ╲___          ┌┐ urinate
  │ │               ╲             ││
  │ │ drink          ╲___         └┘ defecate
  └─┘                    ╲
                          ╲___    ╭──╮ exercise
                               ╲  │  │ (sweat)
                                  ╰──╯

關鍵不對稱:
├── E⁺ 只有離散事件 (沒有任何方式能連續增加體重)
└── E⁻ 有連續 + 離散兩種 (呼吸永不停止 + 上廁所是離散的)
```

### 1.3 Implications for Curve Shape

This asymmetry creates a **piecewise structure** with jumps and decays:

```text
        ↑ W(t)
        │
        │     ┌─┐ eat           ┌─┐ eat
        │     │ ╲               │ ╲___
        │     │  ╲__            │     ╲
        │    ╱│     └┐ urinate  │      ╲___
        │   ╱ │      │          │          └┐ urinate
        │  ╱  │      ╲__        │           │
        │ ╱   │         ╲___    │           ╲___
        │╱    │              ╲__│                ↘
        └─────┼────────────────┼──────────────────→ t
              meal₁            meal₂

圖例:
├── ┌─┐ 離散增加 (進食/喝水)
├── ╲__ 連續減少 (呼吸/蒸發)
└── └┐  離散減少 (上廁所)

規則:
1. 進食時刻: W(t⁺) > W(t⁻)   [向上跳躍]
2. 上廁所時: W(t⁺) < W(t⁻)   [向下跳躍]
3. 其餘時間: dW/dt < 0        [連續遞減]
4. 不可能:   無輸入時體重自發增加
```

---

## 2. Formal Axiomatization

### 2.1 Event Classification: Basic vs Complex

我們區分兩類事件：

```text
┌─────────────────────────────────────────────────────────────────┐
│                    EVENT TAXONOMY (事件分類)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Basic Events (基本事件)                                         │
│  ─────────────────────                                          │
│  定義: 瞬時、原子、不可分割                                       │
│  性質: 發生在單一時刻 t，造成瞬間狀態/質量變化                      │
│                                                                 │
│  ├── 質量跳躍 (Mass Jumps)                                       │
│  │   ├── intake(m, t)   : 物質進入，Δm = +m                      │
│  │   └── excrete(m, t)  : 物質離開，Δm = -m                      │
│  │                                                              │
│  └── 狀態轉移 (State Transitions)                                │
│      ├── sleep_start(t)     : s.consciousness → asleep          │
│      ├── wake_up(t)         : s.consciousness → awake           │
│      ├── exercise_start(t)  : s.activity → intense              │
│      └── exercise_end(t)    : s.activity → rest                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Complex Events (複合事件)                                       │
│  ─────────────────────                                          │
│  定義: 由 basic events 包夾的時間區間 + 區間內的連續過程            │
│  性質: 有開始、持續、結束；可分解為 basic events                   │
│                                                                 │
│  ├── Exercise (運動)                                            │
│  │   └── = exercise_start + [duration with high r] + exercise_end│
│  │                                                              │
│  ├── Sleep (睡眠)                                               │
│  │   └── = sleep_start + [duration with low r] + wake_up        │
│  │                                                              │
│  ├── Meal (一餐)                                                │
│  │   └── = eating_start + [intermittent intakes] + eating_end   │
│  │                                                              │
│  └── Fasting (禁食)                                             │
│      └── = last_meal_end + [duration with no E⁺] + next_meal    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Basic Events 詳解

```text
質量跳躍 Basic Events:
══════════════════════

E⁺_basic (質量增加):
├── bite(m, t)     : 一口食物，m ≈ 10-50 g
├── sip(m, t)      : 一口飲料，m ≈ 20-100 g
└── infuse(m, t)   : IV 輸液 (罕見)

E⁻_basic (質量減少):
├── urinate(m, t)  : 尿尿，m ≈ 200-500 g
├── defecate(m, t) : 大便，m ≈ 100-300 g
├── vomit(m, t)    : 嘔吐 (罕見)
└── bleed(m, t)    : 出血 (罕見)

狀態轉移 Basic Events:
══════════════════════

S_transition (狀態轉移):
├── sleep_start(t)     : 開始睡覺
├── wake_up(t)         : 醒來
├── exercise_start(t, intensity) : 開始運動 (帶強度參數)
├── exercise_end(t)    : 結束運動
├── eating_start(t)    : 開始進食
└── eating_end(t)      : 結束進食

關鍵區別:
├── 質量跳躍: 改變 W，不改變 s
├── 狀態轉移: 改變 s，不直接改變 W
└── s 的改變會影響後續的 r(s)，間接影響 W
```

### 2.3 Complex Events 詳解

```text
Complex Event = [Basic Event]_start + Duration + [Basic Event]_end

═══════════════════════════════════════════════════════════════════

Exercise (運動):
────────────────
  組成:
  ├── exercise_start(t₁, intensity)  [Basic: 狀態轉移]
  ├── duration: (t₁, t₂)             [期間 r(s) 升高]
  └── exercise_end(t₂)               [Basic: 狀態轉移]

  期間效果:
  ├── s.activity = intense
  ├── r(s) ≈ 500-1500 g/hr
  └── Δm = -∫[t₁ to t₂] r(s) dt

  後續效果 (EPOC):
  └── r 在 t₂ 後仍然升高一段時間

═══════════════════════════════════════════════════════════════════

Sleep (睡眠):
─────────────
  組成:
  ├── sleep_start(t₁)   [Basic: 狀態轉移]
  ├── duration: (t₁, t₂) [期間 r(s) 降低，無 E⁺]
  └── wake_up(t₂)       [Basic: 狀態轉移]

  期間效果:
  ├── s.consciousness = asleep
  ├── s.activity = sleep
  ├── r(s) ≈ 40-70 g/hr
  └── Δm = -∫[t₁ to t₂] r(s) dt ≈ -0.3 to -0.5 kg (8hr)

  約束:
  └── 睡眠期間不應有 E⁺ (除非夢遊)

═══════════════════════════════════════════════════════════════════

Meal (一餐):
────────────
  組成:
  ├── eating_start(t₁)   [Basic: 狀態轉移]
  ├── duration: (t₁, t₂)  [期間有多個 bite/sip]
  │   ├── bite(m₁, τ₁)
  │   ├── sip(m₂, τ₂)
  │   ├── bite(m₃, τ₃)
  │   └── ...
  └── eating_end(t₂)     [Basic: 狀態轉移]

  簡化模型:
  ├── 如果進食時間短 (< 30 min)
  ├── 可以合併為單一事件: eat(Σmᵢ, t_mid)
  └── 這是 Complex → 簡化 Basic 的近似

═══════════════════════════════════════════════════════════════════

Fasting (禁食):
───────────────
  組成:
  ├── last_intake(t₁)    [最後一次 E⁺]
  ├── duration: (t₁, t₂)  [期間無 E⁺]
  └── first_intake(t₂)   [第一次 E⁺]

  特點:
  ├── 沒有明確的 start/end 事件
  ├── 是由「E⁺ 的缺席」定義的
  └── 16:8 間歇禁食 = 16 小時的 Fasting Complex Event
```

### 2.4 Body Composition: Five-Level Model (身體組成的五層模型)

根據 Wang et al. (1992) 的經典框架，身體組成可以從五個層級分析：

> **Reference**: Wang ZM, Pierson RN Jr, Heymsfield SB. "The five-level model:
> a new approach to organizing body-composition research."
> *American Journal of Clinical Nutrition*. 1992;56(1):19-28.
> [PubMed: 1609756](https://pubmed.ncbi.nlm.nih.gov/1609756/)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│           FIVE-LEVEL BODY COMPOSITION MODEL (五層身體組成模型)            │
│                    (Wang ZM, Pierson RN, Heymsfield SB, 1992)            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Level 5: WHOLE BODY (整體)                                             │
│  ═══════════════════════════                                            │
│  ├── 身高、體重、BMI                                                    │
│  └── 這是體重計測量的層級                                               │
│           ▲                                                             │
│           │                                                             │
│  Level 4: TISSUE-ORGAN (組織-器官)                                      │
│  ═══════════════════════════════════                                    │
│  ├── Adipose Tissue (脂肪組織)                                          │
│  │   ├── Subcutaneous (皮下脂肪)                                        │
│  │   └── Visceral (內臟脂肪)                                            │
│  ├── Skeletal Muscle (骨骼肌)                                           │
│  ├── Bone (骨骼)                                                        │
│  ├── Organs (器官): 肝、腎、心、腦...                                   │
│  └── Residual (其他)                                                    │
│           ▲                                                             │
│           │                                                             │
│  Level 3: CELLULAR (細胞)                                               │
│  ════════════════════════                                               │
│  ├── Body Cell Mass, BCM (體細胞質量)                                   │
│  ├── Extracellular Fluid, ECF (細胞外液)                                │
│  ├── Extracellular Solids, ECS (細胞外固體)                             │
│  └── Fat (脂肪)                                                         │
│           ▲                                                             │
│           │                                                             │
│  Level 2: MOLECULAR (分子)                                              │
│  ══════════════════════════                                             │
│  ├── Water (水): ~60%                                                   │
│  ├── Lipids (脂質): ~15%                                                │
│  ├── Protein (蛋白質): ~18%                                             │
│  ├── Minerals (礦物質): ~6%                                             │
│  └── Glycogen (肝醣): ~1%                                               │
│           ▲                                                             │
│           │                                                             │
│  Level 1: ATOMIC (原子) ← 我們的 CHONNa 框架在這裡                      │
│  ════════════════════════                                               │
│  ├── Oxygen (O): ~60%                                                   │
│  ├── Carbon (C): ~20%                                                   │
│  ├── Hydrogen (H): ~10%                                                 │
│  ├── Nitrogen (N): ~3%                                                  │
│  ├── Calcium (Ca): ~1.5%                                                │
│  ├── Phosphorus (P): ~1%                                                │
│  └── Others (K, S, Na, Cl, Mg...): ~4%                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.4.1 Compartment Models (隔室模型)

```text
不同複雜度的隔室模型:

2-Compartment Model (二隔室):
══════════════════════════════
  Body Weight = Fat Mass (FM) + Fat-Free Mass (FFM)

  ├── FM:  脂肪組織，密度 0.9007 g/mL
  └── FFM: 去脂體重，密度 1.1000 g/mL

  測量: 水下秤重、空氣置換法 (BodPod)、DXA

3-Compartment Model (三隔室):
══════════════════════════════
  Body Weight = FM + Body Water + Dry FFM

  ├── FM:  脂肪
  ├── TBW: 總體水 (~60% of body weight)
  └── Dry FFM: 乾燥去脂體重 (蛋白質 + 礦物質)

  測量: 需要水分測量 (氘稀釋法)

4-Compartment Model (四隔室):
══════════════════════════════
  Body Weight = FM + TBW + Protein + Minerals

  ├── FM:      脂肪
  ├── TBW:     總體水
  ├── Protein: 蛋白質 (從 N 平衡推算)
  └── Minerals: 礦物質 (從骨密度推算)

  這是「黃金標準」模型
  測量: DXA + 氘稀釋 + 空氣置換

5-Compartment Model (我們的框架):
══════════════════════════════════
  從原子層級追蹤:

  Body = C_body + H_body + O_body + N_body + Na_body + ...

  ├── C:  追蹤脂肪/碳水/蛋白質
  ├── H:  追蹤水分
  ├── O:  追蹤水分/呼吸
  ├── N:  追蹤蛋白質/肌肉
  └── Na: 追蹤細胞外水

  優點: 可以精確追蹤每種原子的流動
  缺點: 實際測量困難
```

### 2.4.2 Linking Levels to Mass Loss Pathways (層級與質量流失的關聯)

```text
質量流失發生在哪個層級？

Level 1 (原子層級) — 我們追蹤的層級:
═══════════════════════════════════════
  ├── C 流失: 主要通過 CO₂ 呼出
  ├── H 流失: 主要通過 H₂O (尿/汗/呼吸)
  ├── O 流失: 主要通過 CO₂ 和 H₂O
  ├── N 流失: 主要通過尿素 (尿液)
  └── Na 流失: 通過汗水和尿液

Level 2 (分子層級):
═══════════════════════════════════════
  ├── Water 流失: 尿/汗/呼吸/蒸發
  ├── Lipid 流失: 氧化 → CO₂ + H₂O
  ├── Protein 流失: 氧化 → CO₂ + H₂O + Urea
  ├── Glycogen 流失: 氧化 → CO₂ + H₂O
  └── Mineral 流失: 尿液 (微量)

Level 4 (組織層級):
═══════════════════════════════════════
  ├── Adipose Tissue: 脂肪細胞釋放脂肪 → 氧化
  ├── Skeletal Muscle: 蛋白質分解 → 氧化
  └── 這是「減肥」或「增肌」關心的層級

關鍵洞見:
═══════════════════════════════════════
  體重計測量的是 Level 5 (整體)
  但我們關心的變化發生在 Level 2-4
  而物質流動追蹤最清楚的是 Level 1

  Level 1 (原子) 是最「乾淨」的追蹤層級
  因為原子守恆是絕對的物理定律
```

### 2.4.3 Time Constants by Level (各層級的時間常數)

```text
不同層級的變化速度不同:

Level 1 原子流動:
├── CO₂: 秒級 (每次呼吸)
├── H₂O: 分鐘-小時級 (喝水/排尿)
└── Na:  小時-天級 (腎臟調節)

Level 2 分子變化:
├── Water: 小時-天 (τ ~ 1-3 天)
├── Glycogen: 小時-天 (τ ~ 1-2 天)
├── Lipids: 週-月 (τ ~ 2-4 週)
└── Protein: 週-月 (τ ~ 2-4 週)

Level 4 組織變化:
├── Adipose: 週-月 (真正的脂肪流失)
├── Muscle: 週-月 (肌肉增長/流失)
└── Bone: 月-年 (骨密度變化)

Level 5 體重變化:
├── 日波動: ±1-2 kg (主要是 Water + Glycogen)
├── 週趨勢: 真正的 FM/Muscle 變化開始顯現
└── 月趨勢: 可靠的身體組成變化
```

---

### 2.5 Complete Inventory: Mass Loss Pathways (質量流失途徑完整清單)

從生理學角度，系統性列出所有身體流失質量的途徑：

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                 MASS LOSS PATHWAYS (質量流失途徑)                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ══════════════════════════════════════════════════════════════════     │
│  1. WATER LOSS (水分流失) — 佔總流失的 ~85%                              │
│  ══════════════════════════════════════════════════════════════════     │
│                                                                         │
│  ┌─ Continuous (連續) ─────────────────────────────────────────────┐    │
│  │                                                                 │    │
│  │  Respiratory Water Vapor (呼吸水蒸氣)                           │    │
│  │  ├── 機制: 肺泡濕潤空氣 → 呼出                                  │    │
│  │  ├── 速率: ~15-30 mL/hr (休息) ~ 50-100 mL/hr (運動)            │    │
│  │  └── 狀態依賴: s.activity, s.environment.humidity               │    │
│  │                                                                 │    │
│  │  Insensible Perspiration (無感蒸發/皮膚蒸發)                    │    │
│  │  ├── 機制: 皮膚表面水分蒸發 (非汗腺)                            │    │
│  │  ├── 速率: ~10-20 mL/hr                                         │    │
│  │  └── 狀態依賴: s.environment.temp, s.environment.humidity       │    │
│  │                                                                 │    │
│  │  Sweating (出汗) — 運動時變為主要途徑                           │    │
│  │  ├── 機制: 汗腺分泌                                             │    │
│  │  ├── 速率: 0 (休息) ~ 500-2000 mL/hr (激烈運動)                 │    │
│  │  └── 狀態依賴: s.activity, s.environment.temp                   │    │
│  │                                                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ┌─ Discrete (離散) ───────────────────────────────────────────────┐    │
│  │                                                                 │    │
│  │  Urination (尿尿)                                               │    │
│  │  ├── 質量: 200-500 g/次                                         │    │
│  │  ├── 頻率: 4-8 次/天                                            │    │
│  │  └── 總計: ~1.5-2 L/天                                          │    │
│  │                                                                 │    │
│  │  Tears (眼淚) — 通常可忽略                                      │    │
│  │  └── 質量: < 1 g/天 (除非大哭)                                  │    │
│  │                                                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ══════════════════════════════════════════════════════════════════     │
│  2. GAS LOSS (氣體流失) — 這是脂肪流失的主要途徑！                       │
│  ══════════════════════════════════════════════════════════════════     │
│                                                                         │
│  ┌─ Continuous (連續) ─────────────────────────────────────────────┐    │
│  │                                                                 │    │
│  │  CO₂ Exhalation (二氧化碳呼出) ⭐ 最重要                        │    │
│  │  ├── 機制: 代謝產物經肺排出                                     │    │
│  │  ├── 來源: 碳水 + 脂肪 + 蛋白質氧化                             │    │
│  │  ├── 速率: ~20-30 g/hr (休息) ~ 100-200 g/hr (運動)             │    │
│  │  ├── 狀態依賴: s.activity (與 VO₂ 成正比)                       │    │
│  │  └── 關鍵: 這是脂肪離開身體的主要途徑！                         │    │
│  │           脂肪的碳 → CO₂ → 呼出                                 │    │
│  │                                                                 │    │
│  │  Flatulence (放屁/腸道氣體)                                     │    │
│  │  ├── 機制: 腸道細菌發酵產生                                     │    │
│  │  ├── 成分: CH₄, H₂, CO₂, N₂, H₂S                                │    │
│  │  └── 質量: ~0.5-1.5 L/天 ≈ 1-2 g/天                             │    │
│  │                                                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ══════════════════════════════════════════════════════════════════     │
│  3. SOLID LOSS (固體流失)                                               │
│  ══════════════════════════════════════════════════════════════════     │
│                                                                         │
│  ┌─ Discrete (離散) ───────────────────────────────────────────────┐    │
│  │                                                                 │    │
│  │  Defecation (大便)                                              │    │
│  │  ├── 質量: 100-300 g/次                                         │    │
│  │  ├── 頻率: 1-2 次/天                                            │    │
│  │  ├── 成分: 水(75%), 細菌, 纖維, 膽色素, 脂肪                    │    │
│  │  └── 注意: 大部分是水！乾物質只有 ~25%                          │    │
│  │                                                                 │    │
│  │  Vomiting (嘔吐) — 罕見                                         │    │
│  │  └── 質量: 200-1000 g/次                                        │    │
│  │                                                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ┌─ Continuous but negligible (連續但可忽略) ──────────────────────┐    │
│  │                                                                 │    │
│  │  Hair Loss (掉髮): ~50-100 根/天 ≈ 0.005 g/天                   │    │
│  │  Skin Cells (皮膚脫落): ~1-2 g/天                               │    │
│  │  Nail Growth (指甲): negligible (剪掉時離開)                    │    │
│  │                                                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ══════════════════════════════════════════════════════════════════     │
│  4. SPECIAL CASES (特殊情況)                                            │
│  ══════════════════════════════════════════════════════════════════     │
│                                                                         │
│  Bleeding (出血): 罕見，可能大量                                        │
│  Menstruation (月經): ~30-80 mL/週期                                    │
│  Breast Milk (母乳): ~500-800 mL/天 (哺乳期)                            │
│  Semen (精液): ~2-5 mL/次 ≈ negligible                                  │
│  Saliva (唾液): 通常吞回，除非吐出                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.4.1 Aggregated Rate Function r(s)

將上述途徑合併為狀態依賴的流失率：

```text
r(s) = r_respiratory(s) + r_evaporative(s) + r_sweating(s)
       ─────────────────────────────────────────────────────
       連續過程 (Continuous Processes)

其中:

r_respiratory(s) = r_CO₂(s) + r_H₂O_breath(s)
├── r_CO₂(s):
│   ├── 休息:    ~25 g/hr
│   ├── 輕度活動: ~50 g/hr
│   ├── 中度運動: ~100 g/hr
│   └── 激烈運動: ~200 g/hr
│
└── r_H₂O_breath(s):
    ├── 休息:    ~20 g/hr
    └── 運動:    ~50-100 g/hr

r_evaporative(s) = f(temp, humidity)
├── 涼爽乾燥: ~10 g/hr
├── 溫暖濕熱: ~5 g/hr
└── 熱乾燥:   ~25 g/hr

r_sweating(s) = 0 (休息) ~ 1500 g/hr (激烈運動+熱)
├── 這是運動時最大的流失途徑！
├── 但這是「水」不是「脂肪」
└── 運動後喝水會補回來
```

### 2.4.2 The Fat Loss Insight (脂肪流失的洞見)

```text
⭐ 關鍵洞見: 脂肪去哪了？

很多人以為:
├── 脂肪變成熱量消失 ❌
├── 脂肪從汗水排出 ❌
├── 脂肪從大便排出 ❌
└── 脂肪變成肌肉 ❌

實際上:
├── 脂肪 (C₅₅H₁₀₄O₆) + O₂ → CO₂ + H₂O
├── 10 kg 脂肪 → 28 kg CO₂ + 11 kg H₂O
├── 84% 的脂肪質量從【呼吸】離開 (CO₂)
└── 16% 的脂肪質量從【尿/汗/呼吸】離開 (H₂O)

這就是為什麼:
├── r_CO₂(s) 是追蹤脂肪流失的關鍵
├── 運動增加 VO₂ → 增加 CO₂ 排出 → 加速脂肪流失
├── 但大部分運動減的重量是【水】(汗水)
└── 真正的脂肪流失 << 體重計顯示的減少
```

### 2.4.3 Daily Mass Balance Example

```text
典型一天的質量流失 (無運動):

連續過程:
├── CO₂ 呼出:        ~600 g (24 hr × 25 g/hr)
├── 呼吸水蒸氣:       ~400 g (24 hr × 17 g/hr)
├── 皮膚蒸發:         ~350 g (24 hr × 15 g/hr)
└── 小計:             ~1350 g

離散事件:
├── 尿液:             ~1500 g (6 次 × 250 g)
├── 糞便:             ~200 g (1 次)
└── 小計:             ~1700 g

總流失:               ~3050 g/天

平衡:
├── 如果攝入 3050 g (食物 + 飲料)
│   └── 體重維持
├── 如果攝入 < 3050 g
│   └── 體重下降 (主要是水分赤字)
└── 真正的脂肪流失取決於 CO₂ 產生量 (能量赤字)

運動日:
├── 1 小時跑步額外流失: ~1000 g (主要是汗水)
├── 但這只是水！
├── 真正額外脂肪流失: ~50-100 g (取決於強度)
└── 大部分會在喝水後補回
```

關鍵觀察:
```text
├── Basic Events: 原子操作，發生在時刻點
├── Complex Events: 由 Basic Events 包夾的區間
├── Continuous Processes: 永遠在進行的背景過程
│
└── 只有 Basic Events 出現在微分方程的 δ 函數中
    Complex Events 是分析/描述的便利，不是基本建模單位
```

### 2.5 Structural Constraint Axioms

**Axiom S1 (No Spontaneous Weight Gain / 無自發增重)**:

```text
∀ interval (t₁, t₂) where E⁺ ∩ (t₁, t₂) = ∅:
  W(t₂) ≤ W(t₁)

等價陳述:
  若 W(t₂) > W(t₁)，則必存在 e ∈ E⁺ 發生於 t₁ < time(e) < t₂

這是質量守恆的直接結果：物質不能憑空產生。
```

**Axiom S2 (Discrete Jumps at Events / 事件時的離散跳躍)**:

```text
進食事件 (向上跳躍):
  ∀ e ∈ E⁺ with mass m at time t:
    W(t⁺) = W(t⁻) + m    [瞬間增加]

排泄事件 (向下跳躍):
  ∀ e ∈ E⁻_discrete with mass m at time t:
    W(t⁺) = W(t⁻) - m    [瞬間減少]

典型離散事件質量:
├── 進食:   +0.3 ~ 1.5 kg/餐
├── 喝水:   +0.2 ~ 0.5 kg/次
├── 尿尿:   -0.2 ~ 0.5 kg/次
├── 大便:   -0.1 ~ 0.3 kg/次
└── 運動後: -0.5 ~ 2.0 kg/次 (汗水)
```

**Axiom S3 (Continuous Decay / 連續衰減)**:

```text
任何離散事件之間，體重連續減少:

  dW/dt = -r(s)   where r ≥ 0, and s = s(t)

關鍵分離:
├── r = r(s)     : 流失率是【狀態】的函數
├── s = s(t)     : 狀態是【時間】的函數
└── r(t) = r(s(t)): 組合後才是時間的函數
```

**身體狀態 s 的定義**:

```text
狀態向量 s = (activity, consciousness, environment, hydration, ...)

s.activity ∈ {sleep, rest, light, moderate, intense}
├── sleep:    METs ≈ 0.9
├── rest:     METs ≈ 1.0
├── light:    METs ≈ 2-3
├── moderate: METs ≈ 4-6
└── intense:  METs ≈ 7-12

s.consciousness ∈ {asleep, awake}
├── asleep: 呼吸較淺，代謝較低
└── awake:  呼吸較深，代謝較高

s.environment = (temperature, humidity, altitude)
├── 高溫/低濕 → 蒸發加速
└── 高海拔 → 呼吸加速

s.hydration ∈ {dehydrated, normal, overhydrated}
└── 影響汗水率和尿液量
```

**流失率函數 r(s)**:

```text
r(s) = r_respiration(s) + r_evaporation(s)

r_respiration(s):
├── s.consciousness = asleep:  ~30-50 g/hr
├── s.consciousness = awake:   ~50-80 g/hr
└── 與 METs 成正比: r ∝ VO₂ ∝ METs

r_evaporation(s):
├── 基礎: ~10-20 g/hr
├── s.environment.temp 高 → 增加
├── s.environment.humidity 低 → 增加
└── s.activity = intense → 大幅增加 (汗水)

典型 r(s) 值:
├── 睡眠:     ~40-70 g/hr
├── 清醒休息: ~60-100 g/hr
├── 輕度活動: ~100-150 g/hr
├── 中度運動: ~300-600 g/hr
└── 激烈運動: ~800-1500 g/hr
```

---

### ⚠️ Critical Issue: Metabolic Adaptation (代謝適應問題)

**傳統 BMR 模型的嚴重缺陷**:

```text
傳統假設:
  r = r(weight, height, age, sex)  ← Mifflin-St Jeor 等公式

問題: 這個模型假設「相同體重 = 相同代謝率」，但這是錯的！

反例: 「不吃東西反而瘦得比較慢」
───────────────────────────────────
觀察: 有人嚴格節食，但減重速度反而變慢
原因: 身體進入「節能模式」，代謝率下降 20-40%

這意味著 r 不只是 (weight, activity) 的函數，
還依賴於【能量平衡歷史】！
```

**更完整的狀態模型**:

```text
狀態 s 應該包含:

s.current = (activity, consciousness, environment)  ← 當前狀態
s.history = (energy_balance_trend, duration)        ← 歷史狀態 ⭐

s.history.energy_balance_trend ∈ {
  chronic_deficit,   # 長期熱量赤字 → BMR 下降
  maintenance,       # 維持 → BMR 穩定
  chronic_surplus    # 長期熱量盈餘 → BMR 可能上升
}

s.history.duration = 這個狀態持續多久了

代謝適應:
├── 短期 (< 1 週): r 主要由 s.current 決定
├── 中期 (1-4 週): 開始出現適應，r 開始下降
└── 長期 (> 4 週): 顯著適應，r 可能下降 20-40%
```

**為什麼傳統 BMR 公式有問題**:

```text
Mifflin-St Jeor:
  BMR = 10×W + 6.25×H - 5×A + 5 (male)

隱含假設:
├── 相同 (W, H, A) → 相同 BMR
├── 減肥前後 BMR 只隨體重線性變化
└── 忽略適應性產熱 (adaptive thermogenesis)

實際情況:
├── 減肥後的 70kg 人 vs 一直是 70kg 的人
│   └── BMR 可能差 200-400 kcal/day！
├── The Biggest Loser 研究: 參賽者 6 年後 BMR 仍低於預期
└── 這就是為什麼「復胖」如此常見

結論:
  r = r(s.current, s.history, body_composition)

  不能只用 r(weight)！
```

**對本框架的影響**:

```text
短期模型 (本文主要關注):
├── 數小時到數天的體重變化
├── s.current 主導，代謝適應效果較小
└── r(s.current) 近似有效

長期模型 (需要額外考慮):
├── 數週到數月的體重變化
├── 必須納入 s.history
├── r(s.current, s.history) 才準確
└── 這解釋了「平台期」現象

實際建議:
├── 不要用公式的 BMR，用自己測量的
├── 追蹤自己的 r 隨時間如何變化
└── 如果 r 顯著下降，可能需要「飲食休息」(diet break)
```

**開放問題**:

```text
Q1: s.history 應該如何量化？
    → 過去 N 天的平均熱量赤字？累積赤字？

Q2: 代謝適應是可逆的嗎？
    → 部分可逆，但可能需要數月到數年

Q3: 如何在 App 中追蹤代謝適應？
    → 比較「預期減重」vs「實際減重」
    → 如果實際 << 預期，可能正在適應

這是一個需要進一步研究的領域。
```

---

**Axiom S4 (Event Exclusivity / 事件互斥)**:

```text
同一時刻不能同時進行兩個離散事件:
  ∀t: |{e : time(e) = t}| ≤ 1

實際意義:
├── 不能同時吃飯和上廁所
├── 事件有自然的時序順序
└── 簡化事件序列建模
```

---

### 2.6 Summary: Basic vs Complex vs Continuous

```text
┌────────────────────────────────────────────────────────────────────┐
│ Type              │ Examples           │ 在方程中的角色            │
├───────────────────┼────────────────────┼───────────────────────────┤
│ Basic Event       │ bite, urinate,     │ δ 函數 (瞬間跳躍)         │
│ (基本事件)        │ exercise_start     │                           │
├───────────────────┼────────────────────┼───────────────────────────┤
│ Complex Event     │ Exercise, Sleep,   │ 分解為 Basic Events       │
│ (複合事件)        │ Meal, Fasting      │ 分析用，非建模基本單位    │
├───────────────────┼────────────────────┼───────────────────────────┤
│ Continuous Process│ respiration,       │ -r(s) dt (連續衰減)       │
│ (連續過程)        │ evaporation        │                           │
└────────────────────────────────────────────────────────────────────┘

關鍵洞見:
├── 運動、睡覺是 Complex Events (由 Basic Events 包夾)
├── 上廁所、進食是 Basic Events (瞬間跳躍)
├── 呼吸、蒸發是 Continuous Processes (背景)
└── Complex Events 可以分解為 Basic + Duration + Basic
```

---

## 3. Mathematical Formalization

### 3.1 Hybrid Model (連續 + 離散混合)

體重變化是**混合系統**：連續衰減 + 離散跳躍

```text
完整動態方程:

  dW/dt = -r(s(t)) + Σⱼ mⱼ⁺ × δ(t - tⱼ⁺) - Σₖ mₖ⁻ × δ(t - tₖ⁻)
          ────────   ────────────────────   ────────────────────
          連續流失       離散增加 (進食)       離散減少 (上廁所)
          (狀態決定)

其中:
├── s(t)             : 身體狀態 (activity, consciousness, environment, ...)
├── r(s) ≥ 0         : 流失率，是狀態的函數 (不直接依賴時間)
├── {tⱼ⁺, mⱼ⁺}       : 進食事件 (時間, 質量)
├── {tₖ⁻, mₖ⁻}       : 排泄事件 (時間, 質量)
└── δ(t)             : 狄拉克 delta 函數 (表示瞬間跳躍)

概念分離:
├── 時間 t → 決定「現在是什麼狀態」
├── 狀態 s → 決定「流失率是多少」
└── 這樣可以用同一個 r(s) 描述不同時間點的相同狀態

積分形式 (兩事件之間):
  W(t₂) = W(t₁) - ∫[t₁ to t₂] r(s(τ)) dτ + Σ(進食) - Σ(排泄)
```

### 3.2 Event Sequence Representation

將一天建模為**事件序列**：

```text
日內事件序列: E = {(t₁, type₁, m₁), (t₂, type₂, m₂), ...}

事件類型:
├── eat:      進食,    Δm = +m
├── drink:    喝水,    Δm = +m
├── urinate:  尿尿,    Δm = -m
├── defecate: 大便,    Δm = -m
├── exercise: 運動,    Δm = -m (汗水)
└── (連續)    呼吸/蒸發, dm/dt = -r

範例日程:
06:00  起床     W = 68.5 kg
06:15  尿尿     -0.35 kg  →  68.15 kg
07:00  早餐     +0.45 kg  →  68.60 kg (含飲料)
       (連續衰減 -0.1 kg/hr)
10:00  尿尿     -0.25 kg  →  68.05 kg
12:00  午餐     +0.60 kg  →  68.65 kg
       ...
```

### 3.3 State Transition Model

狀態 s(t) 如何隨時間變化：

```text
狀態轉移:

s(t) 的變化通常由【事件】觸發:

  睡覺事件:   s.consciousness: awake → asleep
              s.activity: * → sleep

  起床事件:   s.consciousness: asleep → awake
              s.activity: sleep → rest

  運動開始:   s.activity: rest → moderate/intense

  運動結束:   s.activity: moderate/intense → rest

狀態轉移圖:
              ┌─────────────────────────────────────┐
              │                                     │
              ▼                                     │
  ┌─────────────────┐     sleep      ┌───────────────────┐
  │  awake + rest   │ ──────────────→│  asleep + sleep   │
  │  r(s) ≈ 80 g/hr │                │  r(s) ≈ 50 g/hr   │
  └─────────────────┘ ←──────────────└───────────────────┘
         │  ▲            wake up
         │  │
exercise │  │ stop
         ▼  │
  ┌─────────────────┐
  │ awake + intense │
  │ r(s) ≈ 1000 g/hr│
  └─────────────────┘

每個狀態有對應的 r(s) 值，狀態決定流失率。
```

### 3.4 Stochastic Differential Equation

完整的隨機微分方程：

```text
dW(t) = -r(s(t)) dt + Σⱼ mⱼ⁺ × δ(t - tⱼ⁺) dt - Σₖ mₖ⁻ × δ(t - tₖ⁻) dt + σ dBₜ
        ────────     ──────────────────────   ──────────────────────   ───────
        連續流失           進食跳躍              排泄跳躍              測量噪音
      (狀態決定)

變數說明:
├── s(t)           : 身體狀態向量 (activity, consciousness, ...)
├── r(s)           : 流失率函數，只依賴狀態 (不直接依賴時間)
├── {tⱼ⁺, mⱼ⁺}     : 進食事件 (時間, 質量)
├── {tₖ⁻, mₖ⁻}     : 排泄事件 (尿尿、大便、運動流汗)
└── σ dBₜ          : 測量噪音 (不是生理變異)

關鍵觀察:
├── r(s) 不直接依賴 t，而是依賴狀態 s
│   └── 同樣的狀態在不同時間有相同的流失率
├── s(t) 捕捉「時間 → 狀態」的對應
│   └── 例如: 23:00-06:00 通常是 s.consciousness = asleep
├── 噪音項 σ dBₜ 只是測量誤差
├── 真正的生理過程是確定性的 (給定完整的 s(t) 和事件序列)
└── 離散事件可以向上 (E⁺) 或向下 (E⁻) 跳躍
```

---

## 4. Constraint Types Hierarchy

### 4.1 Classification

```text
Level 0: Physical Law Constraints (Absolute)
├── S0.1: Mass conservation (ΔW = Σin - Σout)
├── S0.2: Non-negative mass (W ≥ 0)
└── S0.3: No spontaneous mass creation

Level 1: Physiological Constraints (Universal Human)
├── S1.1: Eating is the only mass input pathway
├── S1.2: Multiple continuous output pathways exist
├── S1.3: Output rate bounded by physiology
│         └── Cannot lose > ~2 kg/hr even with extreme exercise
└── S1.4: Certain outputs require biological triggers
          └── Cannot urinate without bladder content

Level 2: Individual Constraints (Person-specific)
├── S2.1: Personal basal metabolic rate
├── S2.2: Personal sweat rate coefficient
├── S2.3: Personal respiration rate
└── S2.4: Personal meal size distribution

Level 3: Situational Constraints (Context-specific)
├── S3.1: Sleep: no eating, reduced respiration
├── S3.2: Exercise: elevated loss rate
├── S3.3: Fasting: eating events suppressed
└── S3.4: Illness: altered rates
```

### 4.2 Constraint Strength Ordering

```text
Absolute constraints (Level 0)
  └── Cannot be violated under any circumstances
      └── Violation implies measurement error or data corruption

Universal constraints (Level 1)
  └── Can only be violated by medical intervention
      └── Violation implies IV fluids or similar

Individual constraints (Level 2)
  └── Parameters vary by person but structure holds
      └── Violation implies poor parameter estimation

Situational constraints (Level 3)
  └── Depend on context; must infer situation first
      └── Violation implies wrong situational model
```

---

## 5. Practical Applications

### 5.1 Anomaly Detection

Using constraints to detect data quality issues:

```text
Anomaly Type 1: Impossible Weight Increase
─────────────────────────────────────────
Observation: W(t₂) > W(t₁) with no recorded eating in (t₁, t₂)

Diagnosis priority:
1. Missing eating record (most likely)
2. Measurement error (likely)
3. Timestamp error (possible)
4. Scale malfunction (check device)

Action: Flag for user verification; do not update model with anomalous point

Anomaly Type 2: Excessive Weight Loss Rate
──────────────────────────────────────────
Observation: dW/dt < -2.0 kg/hr for sustained period

Diagnosis:
1. Extreme exercise not recorded (possible)
2. Scale malfunction (possible)
3. Wrong person on scale (possible)

Physiological limit: ~1.5-2.0 kg/hr maximum (extreme sweat)

Anomaly Type 3: Impossibly Large Meal
─────────────────────────────────────
Observation: Meal mass > 3 kg indicated

Diagnosis:
1. Multiple meals recorded as one (likely)
2. Includes heavy drinks (possible)
3. Timestamp error (possible)

Physiological limit: Single meal typically < 2 kg
```

### 5.2 Missing Event Inference

```text
Scenario: Weight increased 0.5 kg between measurements,
          but no eating event recorded.

Inference:
├── ∃ eating event in interval (by Axiom S1)
├── Estimated meal mass = ΔW + (r_avg × Δt)
│   └── If Δt = 2 hr, r_avg = 0.05 kg/hr
│   └── Meal ≈ 0.5 + 0.1 = 0.6 kg
└── Prompt user: "Did you eat something around [time]?"
```

### 5.3 Meal Mass Estimation

```text
Known: W_before, W_after, Δt (meal duration)
Assume: Eating duration loss is r × Δt

Estimate:
m_meal ≈ W_after - W_before + r_avg × Δt

Example:
├── W_before = 70.2 kg
├── W_after = 70.8 kg (after 30 min meal)
├── r_avg = 0.05 kg/hr
└── m_meal ≈ 0.6 + 0.025 = 0.625 kg

Uncertainty: ± 0.1 kg (due to r variation)
```

### 5.4 Basal Metabolic Rate Estimation

```text
Overnight measurement (sleep period):

r_sleep = (W_before_sleep - W_after_wake) / sleep_duration

This reflects:
├── Respiration CO₂ output (~70%)
├── Respiration H₂O vapor (~20%)
└── Skin evaporation (~10%)

Typical range: 0.3-0.5 kg / 8hr = 40-60 g/hr

Conversion to energy:
├── CO₂ output implies carbon oxidation
├── Carbon comes from fat/carbs
├── ~0.5 kg overnight → ~100-150 g C → ~400-600 kcal
└── This is a lower bound on BMR (some H₂O not from metabolism)
```

---

## 6. Constrained State Estimation

### 6.1 Constrained Kalman Filter

Standard Kalman Filter allows physiologically impossible states:

```text
Standard Kalman Update:
  x(t+1) = A × x(t) + B × u(t) + w(t)

Problem: Process noise w(t) can be positive, implying spontaneous
         weight gain—which violates Axiom S1.

Solution: Constrained Kalman Filter

Constraints:
  x(t+1) ≤ x(t) + m_input(t)    [weight can't exceed input]
  w(t) ≤ 0                       [loss noise is always negative]

Mathematical formulation:
  minimize: (x - x_predicted)ᵀ × P⁻¹ × (x - x_predicted)
  subject to: x ≤ x_prev + m_input
              x ≥ 0

This becomes a Quadratic Programming (QP) problem at each step.
```

### 6.2 Implementation Approach

```text
Algorithm: Constrained Kalman Update

Input: x_prev, P_prev, y_obs, m_input (if eating)
Output: x_post, P_post

1. Standard Kalman prediction:
   x_pred = A × x_prev + B × u
   P_pred = A × P_prev × Aᵀ + Q

2. Standard Kalman update:
   K = P_pred × Hᵀ × (H × P_pred × Hᵀ + R)⁻¹
   x_kalman = x_pred + K × (y_obs - H × x_pred)
   P_kalman = (I - K × H) × P_pred

3. Constraint projection:
   if x_kalman > x_prev + m_input:
       x_post = x_prev + m_input
   else if x_kalman < 0:
       x_post = 0
   else:
       x_post = x_kalman

4. Covariance adjustment (if constrained):
   P_post = adjust_covariance(P_kalman, constraint_active)

Return: x_post, P_post
```

---

## 7. Daily Weight Curve Patterns

### 7.1 Typical 24-Hour Pattern

```text
Typical weight curve over 24 hours:

W (kg)
 │
 │                    ┌─┐ lunch
 │         ┌─┐ b'fast │ │
70.5│        │ ╲      │  ╲___
 │        │  ╲____│       ╲    ┌─┐ dinner
70.0│       │                ╲__│ │
 │       │                     │ ╲___
69.5│      │                      │    ╲___
 │      │                           │       ╲___
69.0│_____│                              │        ╲____
 │  sleep                                  │          sleep
 └────────────────────────────────────────────────────────→ t
   0  2  4  6  8  10  12  14  16  18  20  22  24 (hour)

Observations:
├── Morning weight is lowest (after sleep fast)
├── Each meal creates a step increase
├── Between meals, continuous decrease
├── Sleep creates the longest uninterrupted decline
└── Total daily intake ≈ total daily output (on average)
```

### 7.2 Constraint Violations as Diagnostics

```text
Pattern 1: Weight increases overnight
────────────────────────────────
W_morning > W_evening (previous)

Impossible unless:
├── Sleepwalking to refrigerator (check)
├── Scale calibration shifted
├── Different person measured
└── Data entry error

Pattern 2: Flat line between meals
──────────────────────────────
dW/dt ≈ 0 for extended period

Unusual because:
├── Respiration continues
├── Skin evaporation continues
└── Expected: ~50g/hr loss

Possible explanations:
├── Continuous sipping (matching loss)
├── Scale resolution too coarse
└── Very short time interval

Pattern 3: Increase without recorded meal
───────────────────────────────────────
ΔW > 0.1 kg with no recorded input

Definitely one of:
├── Forgot to record eating/drinking
├── Measurement was during meal
├── Timestamp error
└── Data corruption
```

---

## 8. Integration with Weight Control YAML

These constraints should be added to `weight_control_axioms.yaml`:

```yaml
# Proposed addition to weight_control_axioms.yaml

structural_constraints:
  id: "S1_curve_shape"
  one_liner: "體重曲線遵循物理約束的分段單調結構"
  see_also: "structural_constraints.md"

  axiom_S1_piecewise_monotonicity:
    statement_natural: |
      Between eating events, body weight can only decrease or stay constant.
      Weight increases only occur through eating, drinking, or IV infusion.
    statement_formal: |
      ∀ interval (t₁, t₂) where E⁺ ∩ (t₁, t₂) = ∅:
        W(t₂) ≤ W(t₁)

  axiom_S2_jump_discontinuity:
    statement_natural: |
      Eating events cause instantaneous weight increases equal to the
      mass of food/drink consumed.
    statement_formal: |
      ∀ eating event e with mass m at time t:
        W(t⁺) = W(t⁻) + m

  axiom_S3_nonnegative_loss_rate:
    statement_natural: |
      The rate of weight loss between eating events is always non-negative.
      The body continuously loses mass through respiration, evaporation,
      and excretion.
    statement_formal: |
      r(t) = -dW/dt ≥ 0  ∀t ∉ E⁺

  applications:
    - anomaly_detection: "Flag impossible weight increases"
    - missing_event_inference: "Infer unrecorded eating from constraint violations"
    - meal_mass_estimation: "Calculate food mass from weight jumps"
    - bmr_estimation: "Use overnight decline for basal rate estimation"
    - constrained_kalman: "Physics-aware state estimation"
```

---

## 9. Revision History

| Date | Change |
|------|--------|
| 2026-01-01 | Initial structural constraints documentation |

---

*Maintainer: Che Cheng*

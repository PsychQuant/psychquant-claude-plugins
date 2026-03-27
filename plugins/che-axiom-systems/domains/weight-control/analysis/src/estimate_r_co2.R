# =============================================================================
# 從多天體重數據估計 CO₂ 排出速率 (r_CO₂)
# =============================================================================
#
# 核心思想：
#   r(t) = r_CO₂ + r_H₂O(t)
#   - r_CO₂ 穩定（代謝率決定）
#   - r_H₂O(t) 變異大但有下界
#   - min(r) → r_CO₂ + r_H₂O_min
#
# =============================================================================

library(dplyr)
library(lubridate)
library(ggplot2)

# -----------------------------------------------------------------------------
# 1. 讀取數據
# -----------------------------------------------------------------------------

read_body_composition <- function(file_path) {
  data <- read.csv(file_path, fileEncoding = "UTF-8-BOM")

  # 解析日期時間
  data <- data %>%
    mutate(
      datetime = ymd_hm(`測量日期`),
      date = as.Date(datetime),
      time = format(datetime, "%H:%M"),
      hour = hour(datetime),
      weight_kg = as.numeric(`體重.kg.`),
      body_fat_pct = as.numeric(`體脂肪...`),
      bmr_kcal = as.numeric(`基礎代謝.kcal.`)
    ) %>%
    arrange(datetime)

  return(data)
}

# -----------------------------------------------------------------------------
# 2. 識別測量配對（支援多種模式）
# -----------------------------------------------------------------------------

# 模式 A：睡前-起床配對（原始方法）
identify_sleep_pairs <- function(data) {
  # 定義時間窗口
  # 睡前：20:00 - 03:00（跨日）
  # 起床：05:00 - 10:00

  data <- data %>%
    mutate(
      measurement_type = case_when(
        hour >= 20 | hour <= 3 ~ "bedtime",
        hour >= 5 & hour <= 10 ~ "morning",
        TRUE ~ "other"
      )
    )

  # 找出配對
  pairs <- data.frame()

  bedtime_records <- data %>% filter(measurement_type == "bedtime")
  morning_records <- data %>% filter(measurement_type == "morning")

  for (i in 1:nrow(bedtime_records)) {
    bed_time <- bedtime_records$datetime[i]
    bed_weight <- bedtime_records$weight_kg[i]
    bed_date <- bedtime_records$date[i]

    # 找下一個早晨測量（同一天或隔天早上）
    # 睡前如果是 20:00-23:59，找隔天早上
    # 睡前如果是 00:00-03:00，找同一天早上

    if (bedtime_records$hour[i] >= 20) {
      target_date <- bed_date + 1
    } else {
      target_date <- bed_date
    }

    morning_match <- morning_records %>%
      filter(date == target_date) %>%
      slice(1)  # 取第一個早晨測量

    if (nrow(morning_match) == 1) {
      wake_time <- morning_match$datetime
      wake_weight <- morning_match$weight_kg

      # 計算時間差（小時）
      delta_t <- as.numeric(difftime(wake_time, bed_time, units = "hours"))

      # 排除不合理的時間差（太短或太長）
      if (delta_t > 3 && delta_t < 14) {
        delta_M <- bed_weight - wake_weight  # 體重下降（kg）
        r <- delta_M / delta_t * 1000  # g/hr

        pairs <- rbind(pairs, data.frame(
          bed_datetime = bed_time,
          wake_datetime = wake_time,
          bed_weight = bed_weight,
          wake_weight = wake_weight,
          delta_t = delta_t,
          delta_M = delta_M * 1000,  # g
          r = r  # g/hr
        ))
      }
    }
  }

  return(pairs)
}

# 模式 B：連續早晨配對
# 適用於主要在早上測量的情況
# 假設每天同一時間測量，近似 24 小時間隔
identify_morning_pairs <- function(data) {
  # 只取早晨測量（5:00 - 10:00）
  morning_data <- data %>%
    filter(hour >= 5 & hour <= 10) %>%
    arrange(datetime) %>%
    # 每天只取第一筆（最早的）
    group_by(date) %>%
    slice(1) %>%
    ungroup() %>%
    arrange(date)

  pairs <- data.frame()

  for (i in 1:(nrow(morning_data) - 1)) {
    date1 <- morning_data$date[i]
    date2 <- morning_data$date[i + 1]

    # 只配對連續兩天
    if (as.numeric(date2 - date1) == 1) {
      t1 <- morning_data$datetime[i]
      t2 <- morning_data$datetime[i + 1]
      w1 <- morning_data$weight_kg[i]
      w2 <- morning_data$weight_kg[i + 1]

      delta_t <- as.numeric(difftime(t2, t1, units = "hours"))
      delta_M <- w1 - w2  # 可能為負（體重增加）或正（體重下降）

      # 排除不合理的時間差
      if (delta_t > 20 && delta_t < 28) {
        pairs <- rbind(pairs, data.frame(
          date1 = date1,
          date2 = date2,
          datetime1 = t1,
          datetime2 = t2,
          weight1 = w1,
          weight2 = w2,
          delta_t = delta_t,
          delta_M = delta_M * 1000,  # g
          r = delta_M / delta_t * 1000  # g/hr（可能為負）
        ))
      }
    }
  }

  return(pairs)
}

# -----------------------------------------------------------------------------
# 3. 估計 r_CO₂
# -----------------------------------------------------------------------------

estimate_r_co2 <- function(pairs, r_H2O_min = 20) {
  # r_H2O_min: 最小蒸散速率的估計（g/hr）
  # 預設 20 g/hr（呼吸 + 皮膚最小蒸散）

  # 方法 1：使用最小值
  r_min <- min(pairs$r)
  r_co2_from_min <- r_min - r_H2O_min


  # 方法 2：使用第 5 百分位數（更穩健）
  r_p05 <- quantile(pairs$r, 0.05)
  r_co2_from_p05 <- r_p05 - r_H2O_min

  # 方法 3：使用最低 3 個值的平均
  r_lowest_3 <- mean(sort(pairs$r)[1:min(3, nrow(pairs))])
  r_co2_from_lowest <- r_lowest_3 - r_H2O_min

  results <- list(
    n_pairs = nrow(pairs),
    r_mean = mean(pairs$r),
    r_sd = sd(pairs$r),
    r_min = r_min,
    r_p05 = r_p05,
    r_lowest_3 = r_lowest_3,
    r_H2O_min_assumed = r_H2O_min,
    r_co2_from_min = r_co2_from_min,
    r_co2_from_p05 = r_co2_from_p05,
    r_co2_from_lowest = r_co2_from_lowest
  )

  return(results)
}

# -----------------------------------------------------------------------------
# 4. 分解每晚的 CO₂ 和 H₂O
# -----------------------------------------------------------------------------

decompose_weight_loss <- function(pairs, r_co2) {
  pairs <- pairs %>%
    mutate(
      # CO₂ 貢獻
      delta_M_CO2 = r_co2 * delta_t,  # g

      # H₂O 貢獻
      delta_M_H2O = delta_M - delta_M_CO2,  # g

      # 對應的脂肪氧化（κ ≈ 2.8）
      fat_oxidized = delta_M_CO2 / 2.8,  # g

      # 比例
      pct_CO2 = delta_M_CO2 / delta_M * 100,
      pct_H2O = delta_M_H2O / delta_M * 100,

      # r_H2O
      r_H2O = delta_M_H2O / delta_t  # g/hr
    )

  return(pairs)
}

# -----------------------------------------------------------------------------
# 5. 視覺化
# -----------------------------------------------------------------------------

plot_r_distribution <- function(pairs, r_co2_est) {
  p <- ggplot(pairs, aes(x = r)) +
    geom_histogram(bins = 15, fill = "steelblue", alpha = 0.7, color = "white") +
    geom_vline(xintercept = r_co2_est, color = "red", linetype = "dashed", size = 1) +
    annotate("text", x = r_co2_est + 5, y = Inf, vjust = 2,
             label = paste("r_CO2 ≈", round(r_co2_est, 1), "g/hr"),
             color = "red") +
    labs(
      title = "夜間體重下降速率 r(t) 的分布",
      subtitle = paste("n =", nrow(pairs), "晚"),
      x = "r = ΔM/Δt (g/hr)",
      y = "頻次"
    ) +
    theme_minimal()

  return(p)
}

plot_r_convergence <- function(pairs) {
  # 累積最小值
  running_min <- cummin(pairs$r)

  df <- data.frame(
    n = 1:nrow(pairs),
    running_min = running_min
  )

  p <- ggplot(df, aes(x = n, y = running_min)) +
    geom_line(color = "steelblue", size = 1) +
    geom_point(color = "steelblue", size = 2) +
    labs(
      title = "min(r) 的收斂情況",
      subtitle = "隨著數據增加，最小值趨於穩定",
      x = "累積天數",
      y = "累積最小 r (g/hr)"
    ) +
    theme_minimal()

  return(p)
}

plot_decomposition <- function(pairs) {
  # 長格式
  df_long <- pairs %>%
    select(bed_datetime, delta_M_CO2, delta_M_H2O) %>%
    tidyr::pivot_longer(
      cols = c(delta_M_CO2, delta_M_H2O),
      names_to = "component",
      values_to = "mass"
    ) %>%
    mutate(
      component = case_when(
        component == "delta_M_CO2" ~ "CO₂",
        component == "delta_M_H2O" ~ "H₂O"
      )
    )

  p <- ggplot(df_long, aes(x = bed_datetime, y = mass, fill = component)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = c("CO₂" = "coral", "H₂O" = "steelblue")) +
    labs(
      title = "每晚體重下降的分解",
      x = "日期",
      y = "質量 (g)",
      fill = "成分"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(p)
}

plot_r_H2O_validation <- function(pairs) {
  p <- ggplot(pairs, aes(x = bed_datetime, y = r_H2O)) +
    geom_line(color = "steelblue", alpha = 0.5) +
    geom_point(color = "steelblue", size = 2) +
    geom_hline(yintercept = c(20, 80), linetype = "dashed", color = "gray50") +
    annotate("text", x = min(pairs$bed_datetime), y = 20,
             label = "最小蒸散 (20 g/hr)", hjust = 0, vjust = -0.5, color = "gray50") +
    annotate("text", x = min(pairs$bed_datetime), y = 80,
             label = "高蒸散 (80 g/hr)", hjust = 0, vjust = -0.5, color = "gray50") +
    labs(
      title = "估計的 r_H₂O 是否在合理範圍？",
      subtitle = "應該在 20-80 g/hr 之間",
      x = "日期",
      y = "r_H₂O (g/hr)"
    ) +
    theme_minimal()

  return(p)
}

# -----------------------------------------------------------------------------
# 6. 主程式
# -----------------------------------------------------------------------------

main <- function() {
  # 讀取數據
  file_path <- "../data/BodyComposition_201011-202601.csv"
  data <- read_body_composition(file_path)

  cat("=== 數據概覽 ===\n")
  cat("總測量次數:", nrow(data), "\n")
  cat("日期範圍:", as.character(min(data$date)), "到", as.character(max(data$date)), "\n")
  cat("\n")

  # 首先嘗試睡前-起床配對
  sleep_pairs <- identify_sleep_pairs(data)
  cat("睡前-起床配對數:", nrow(sleep_pairs), "\n")

  # 嘗試連續早晨配對
  morning_pairs <- identify_morning_pairs(data)
  cat("連續早晨配對數:", nrow(morning_pairs), "\n")
  cat("\n")

  # 優先使用有較多數據的方法
  if (nrow(sleep_pairs) >= 10) {
    cat(">>> 使用睡前-起床配對（夜間體重變化）\n\n")
    pairs <- sleep_pairs
    pair_type <- "sleep"
  } else if (nrow(morning_pairs) >= 10) {
    cat(">>> 使用連續早晨配對（24小時體重變化）\n")
    cat("注意：這是 24 小時間隔，包含飲食和活動的影響\n")
    cat("      r 可能為負（體重增加）或正（體重下降）\n\n")
    pairs <- morning_pairs
    pair_type <- "morning"
  } else {
    cat("配對數不足，無法進行分析。\n")
    cat("需要至少 10 個有效配對。\n")
    cat("建議：增加睡前或起床時的測量。\n")
    return(NULL)
  }

  # 基本統計
  cat("=== 體重變化率 r(t) 統計 ===\n")
  cat("平均值:", round(mean(pairs$r), 2), "g/hr\n")
  cat("標準差:", round(sd(pairs$r), 2), "g/hr\n")
  cat("最小值:", round(min(pairs$r), 2), "g/hr\n")
  cat("最大值:", round(max(pairs$r), 2), "g/hr\n")
  cat("中位數:", round(median(pairs$r), 2), "g/hr\n")
  cat("\n")

  # 對於 24 小時數據，需要不同的解讀
  if (pair_type == "morning") {
    cat("=== 24 小時體重變化分析 ===\n")

    # 統計體重變化方向
    n_loss <- sum(pairs$delta_M > 0)
    n_gain <- sum(pairs$delta_M < 0)
    n_stable <- sum(abs(pairs$delta_M) < 100)  # 100g 以內視為穩定

    cat("體重下降天數:", n_loss, "(",
        round(n_loss/nrow(pairs)*100, 1), "%)\n")
    cat("體重增加天數:", n_gain, "(",
        round(n_gain/nrow(pairs)*100, 1), "%)\n")
    cat("體重穩定天數（±100g）:", n_stable, "(",
        round(n_stable/nrow(pairs)*100, 1), "%)\n")
    cat("\n")

    # 計算淨體重趨勢
    total_days <- as.numeric(max(pairs$date2) - min(pairs$date1))
    total_change <- sum(pairs$delta_M)  # g
    daily_trend <- total_change / total_days  # g/天

    cat("總觀察天數:", total_days, "\n")
    cat("總體重變化:", round(total_change), "g\n")
    cat("平均每日趨勢:", round(daily_trend, 1), "g/天\n")

    if (daily_trend > 0) {
      cat("→ 整體趨勢：減重中\n")
    } else if (daily_trend < 0) {
      cat("→ 整體趨勢：增重中\n")
    } else {
      cat("→ 整體趨勢：維持\n")
    }
    cat("\n")

    # 對於 24 小時數據，估計 r_CO₂ 的方法需要調整
    # 由於包含飲食，無法直接用 min(r) 來估計
    # 但可以分析體重變化的下界
    cat("=== 代謝分析（參考值）===\n")

    # 找出減重最多的日子（接近禁食狀態）
    top_loss_days <- pairs %>%
      filter(delta_M > 0) %>%
      arrange(desc(r)) %>%
      head(5)

    if (nrow(top_loss_days) > 0) {
      cat("減重最多的 5 天（可能接近禁食狀態）:\n")
      for (i in 1:nrow(top_loss_days)) {
        cat("  ", as.character(top_loss_days$date1[i]), ": ",
            round(top_loss_days$delta_M[i]), " g (",
            round(top_loss_days$r[i], 1), " g/hr)\n", sep = "")
      }
    }
    cat("\n")

    # 輸出結果
    results <- list(
      data = data,
      pairs = pairs,
      pair_type = pair_type,
      daily_trend = daily_trend
    )

  } else {
    # 原始的睡前-起床分析
    r_H2O_min <- 20  # 假設最小蒸散 20 g/hr
    est <- estimate_r_co2(pairs, r_H2O_min)

    cat("=== r_CO₂ 估計 ===\n")
    cat("假設 r_H₂O_min =", r_H2O_min, "g/hr\n")
    cat("\n")
    cat("方法 1（最小值）:\n")
    cat("  min(r) =", round(est$r_min, 2), "g/hr\n")
    cat("  r_CO₂ ≈", round(est$r_co2_from_min, 2), "g/hr\n")
    cat("\n")
    cat("方法 2（第 5 百分位數）:\n")
    cat("  P05(r) =", round(est$r_p05, 2), "g/hr\n")
    cat("  r_CO₂ ≈", round(est$r_co2_from_p05, 2), "g/hr\n")
    cat("\n")
    cat("方法 3（最低 3 晚平均）:\n")
    cat("  mean(lowest 3) =", round(est$r_lowest_3, 2), "g/hr\n")
    cat("  r_CO₂ ≈", round(est$r_co2_from_lowest, 2), "g/hr\n")
    cat("\n")

    # 使用第 5 百分位數作為主要估計
    r_co2_est <- est$r_co2_from_p05

    # 分解每晚
    pairs <- decompose_weight_loss(pairs, r_co2_est)

    cat("=== 分解結果（使用 r_CO₂ =", round(r_co2_est, 2), "g/hr）===\n")
    cat("平均每晚：\n")
    cat("  總體重下降:", round(mean(pairs$delta_M), 1), "g\n")
    cat("  CO₂ 貢獻:", round(mean(pairs$delta_M_CO2), 1), "g (",
        round(mean(pairs$pct_CO2), 1), "%)\n")
    cat("  H₂O 貢獻:", round(mean(pairs$delta_M_H2O), 1), "g (",
        round(mean(pairs$pct_H2O), 1), "%)\n")
    cat("  脂肪氧化:", round(mean(pairs$fat_oxidized), 1), "g\n")
    cat("\n")

    # 驗證 r_H₂O 是否合理
    cat("=== r_H₂O 驗證 ===\n")
    cat("r_H₂O 範圍:", round(min(pairs$r_H2O), 2), "-",
        round(max(pairs$r_H2O), 2), "g/hr\n")
    cat("期望範圍: 20-80 g/hr\n")

    n_below <- sum(pairs$r_H2O < 0)
    n_above <- sum(pairs$r_H2O > 100)

    if (n_below > 0) {
      cat("警告:", n_below, "晚的 r_H₂O < 0（r_CO₂ 可能估計過高）\n")
    }
    if (n_above > 0) {
      cat("注意:", n_above, "晚的 r_H₂O > 100（可能有特殊事件）\n")
    }
    if (n_below == 0 && n_above == 0) {
      cat("✓ 所有 r_H₂O 都在合理範圍內\n")
    }
    cat("\n")

    # 輸出結果
    results <- list(
      data = data,
      pairs = pairs,
      pair_type = pair_type,
      estimates = est,
      r_co2_used = r_co2_est
    )
  }

  # 理論值比較
  cat("=== 與理論值比較 ===\n")
  avg_bmr <- mean(data$bmr_kcal, na.rm = TRUE)
  cat("平均 BMR（BIA）:", round(avg_bmr), "kcal/天\n")

  # 從 BMR 粗估 r_CO₂
  # 24 小時代謝產生的 CO₂
  # 假設 RQ = 0.8，每 kcal 產生約 0.2g CO₂
  daily_co2 <- avg_bmr * 0.2  # g/天
  hourly_r_co2 <- daily_co2 / 24  # g/hr

  cat("理論每日 CO₂ 產生: ~", round(daily_co2), "g/天\n")
  cat("理論 r_CO₂: ~", round(hourly_r_co2, 1), "g/hr\n")
  cat("\n")

  return(results)
}

# -----------------------------------------------------------------------------
# 執行
# -----------------------------------------------------------------------------

# 如果直接執行此腳本
if (!interactive()) {
  results <- main()
}

# 互動式使用時，手動執行：
# results <- main()
#
# 繪圖：
# plot_r_distribution(results$pairs, results$r_co2_used)
# plot_r_convergence(results$pairs)
# plot_decomposition(results$pairs)
# plot_r_H2O_validation(results$pairs)

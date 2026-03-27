# =============================================================================
# r_CO₂ 估計方法 v2：反向驗證法
# =============================================================================
#
# 問題：原方法使用 r_H₂O_min = 20 g/hr 假設，但 P10(r) ≈ 19 g/hr 導致負估計
#
# 新方法：
# 1. 假設理論 r_CO₂ 正確（從 BMR 計算）
# 2. 反推每晚的 r_H₂O = r(t) - r_CO₂
# 3. 檢查 r_H₂O 分布是否合理
# 4. 用最低 r_H₂O 來驗證理論 r_CO₂
#
# =============================================================================

library(dplyr)
library(lubridate)
library(ggplot2)

# -----------------------------------------------------------------------------
# 1. 讀取數據
# -----------------------------------------------------------------------------

read_data <- function(file_path) {
  data <- read.csv(file_path, fileEncoding = "UTF-8-BOM")

  colnames(data) <- c("datetime_str", "timezone", "weight_kg", "body_fat_pct",
                      "fat_mass_kg", "visceral_fat", "bmr_kcal",
                      "skeletal_muscle_pct", "skeletal_muscle_kg",
                      "bmi", "body_age", "model")

  data <- data %>%
    mutate(
      datetime = ymd_hm(datetime_str),
      date = as.Date(datetime),
      hour = hour(datetime),
      weight_kg = as.numeric(weight_kg),
      bmr_kcal = as.numeric(bmr_kcal)
    ) %>%
    filter(!is.na(datetime), !is.na(weight_kg)) %>%
    arrange(datetime)

  return(data)
}

# -----------------------------------------------------------------------------
# 2. 找睡眠配對（嚴格時間窗口）
# -----------------------------------------------------------------------------

find_sleep_pairs <- function(data) {
  # 定義時間窗口
  # 睡前：20:00-03:00（晚上8點到凌晨3點）
  # 起床：05:00-10:00（早上5點到10點）

  pairs <- data.frame()

  for (i in 1:(nrow(data) - 1)) {
    t1 <- data$datetime[i]
    t2 <- data$datetime[i + 1]
    h1 <- data$hour[i]
    h2 <- data$hour[i + 1]

    # 檢查是否是 bedtime -> morning 配對
    is_bedtime <- (h1 >= 20 | h1 <= 3)
    is_morning <- (h2 >= 5 & h2 <= 10)

    if (!is_bedtime || !is_morning) next

    # 計算時間差
    delta_t <- as.numeric(difftime(t2, t1, units = "hours"))

    # 合理睡眠時長：3-14 小時
    if (delta_t < 3 || delta_t > 14) next

    # 體重變化
    bed_weight <- data$weight_kg[i]
    wake_weight <- data$weight_kg[i + 1]
    delta_M_g <- (bed_weight - wake_weight) * 1000  # g

    # 只分析體重下降的配對
    if (delta_M_g <= 0) next

    # 計算 r(t)
    r_total <- delta_M_g / delta_t  # g/hr

    # 取得 BMR
    bmr <- data$bmr_kcal[i]

    pairs <- rbind(pairs, data.frame(
      bed_datetime = t1,
      wake_datetime = t2,
      bed_hour = h1,
      wake_hour = h2,
      bed_weight_kg = bed_weight,
      wake_weight_kg = wake_weight,
      delta_t_hr = delta_t,
      delta_M_g = delta_M_g,
      r_total = r_total,
      bmr_kcal = bmr
    ))
  }

  return(pairs)
}

# -----------------------------------------------------------------------------
# 3. 反向驗證分析
# -----------------------------------------------------------------------------

analyze_reverse_method <- function(pairs) {
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n")
  cat("反向驗證法分析\n")
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n\n")

  # 計算平均 BMR
  avg_bmr <- mean(pairs$bmr_kcal, na.rm = TRUE)

  # 理論 r_CO₂ = BMR × 0.2 / 24
  # 0.2 = CO₂ 質量產生量 (g/kcal)
  # 來源：1 kcal 氧化約產生 0.2g CO₂
  r_co2_theoretical <- avg_bmr * 0.2 / 24  # g/hr

  cat("--- 理論 r_CO₂ ---\n")
  cat("平均 BMR:", round(avg_bmr), "kcal/天\n")
  cat("理論 r_CO₂ = BMR × 0.2 / 24 =", round(r_co2_theoretical, 2), "g/hr\n\n")

  # 假設理論值正確，反推 r_H₂O
  pairs <- pairs %>%
    mutate(
      r_co2_theoretical = r_co2_theoretical,
      r_h2o_implied = r_total - r_co2_theoretical
    )

  cat("--- 反推 r_H₂O 分布 ---\n")
  cat("r_H₂O 平均:", round(mean(pairs$r_h2o_implied), 2), "g/hr\n")
  cat("r_H₂O 中位數:", round(median(pairs$r_h2o_implied), 2), "g/hr\n")
  cat("r_H₂O 最小:", round(min(pairs$r_h2o_implied), 2), "g/hr\n")
  cat("r_H₂O 最大:", round(max(pairs$r_h2o_implied), 2), "g/hr\n")
  cat("r_H₂O P05:", round(quantile(pairs$r_h2o_implied, 0.05), 2), "g/hr\n")
  cat("r_H₂O P10:", round(quantile(pairs$r_h2o_implied, 0.10), 2), "g/hr\n")
  cat("r_H₂O P25:", round(quantile(pairs$r_h2o_implied, 0.25), 2), "g/hr\n\n")

  # 檢查 r_H₂O 是否合理
  # 呼吸水分損失約 10-15 g/hr
  # 皮膚蒸散約 5-30 g/hr（取決於溫度、濕度）
  # 總計：15-45 g/hr 是合理範圍

  r_h2o_min_implied <- min(pairs$r_h2o_implied)
  r_h2o_p10_implied <- quantile(pairs$r_h2o_implied, 0.10)

  cat("--- 合理性檢查 ---\n")
  cat("預期 r_H₂O 範圍: 15-45 g/hr（睡眠時）\n")
  cat("反推 r_H₂O 最小值:", round(r_h2o_min_implied, 2), "g/hr\n")

  if (r_h2o_min_implied >= 0 && r_h2o_min_implied <= 50) {
    cat("✓ 反推 r_H₂O 落在合理範圍，理論 r_CO₂ 可能正確\n\n")
  } else if (r_h2o_min_implied < 0) {
    cat("✗ 反推 r_H₂O 為負值，表示理論 r_CO₂ 過高\n")
    cat("  需要調低 r_CO₂ 估計\n\n")
  } else {
    cat("? 反推 r_H₂O 偏高，可能有其他因素\n\n")
  }

  # 另一種估計方法：用 min(r_total) 來估計上界
  r_total_min <- min(pairs$r_total)
  r_total_p05 <- quantile(pairs$r_total, 0.05)
  r_total_p10 <- quantile(pairs$r_total, 0.10)

  cat("--- 基於 r_total 分布的估計 ---\n")
  cat("min(r_total):", round(r_total_min, 2), "g/hr\n")
  cat("P05(r_total):", round(r_total_p05, 2), "g/hr\n")
  cat("P10(r_total):", round(r_total_p10, 2), "g/hr\n\n")

  # 如果假設最低水分蒸散發生在最低 r_total 的夜晚
  # 那麼 r_CO₂ 的上界 ≈ min(r_total) - r_H₂O_min
  # 但 r_H₂O_min 未知...

  # 使用迭代方法：
  # 假設 r_H₂O 服從某種分布，r_H₂O_min 約為 P05 或 P10
  # 先假設理論 r_CO₂ 正確，算出 r_H₂O 分布
  # 用 r_H₂O 的 P05/P10 作為 r_H₂O_min 的估計

  r_h2o_min_est <- quantile(pairs$r_h2o_implied, 0.05)  # 用 P05

  cat("--- 迭代估計 ---\n")
  cat("假設 r_H₂O_min ≈ P05(r_H₂O_implied) =", round(r_h2o_min_est, 2), "g/hr\n")

  # 重新估計 r_CO₂
  # r_CO₂ = min(r_total) - r_H₂O_min_est
  # 或 r_CO₂ = P05(r_total) - r_H₂O_min_est
  r_co2_est_from_min <- r_total_min - r_h2o_min_est
  r_co2_est_from_p05 <- r_total_p05 - r_h2o_min_est

  cat("r_CO₂ 估計（從 min）:", round(r_co2_est_from_min, 2), "g/hr\n")
  cat("r_CO₂ 估計（從 P05）:", round(r_co2_est_from_p05, 2), "g/hr\n")
  cat("理論 r_CO₂:", round(r_co2_theoretical, 2), "g/hr\n\n")

  return(list(
    pairs = pairs,
    r_co2_theoretical = r_co2_theoretical,
    r_h2o_min_implied = r_h2o_min_implied,
    r_h2o_distribution = summary(pairs$r_h2o_implied),
    r_total_distribution = summary(pairs$r_total)
  ))
}

# -----------------------------------------------------------------------------
# 4. 視覺化
# -----------------------------------------------------------------------------

create_plots <- function(results, output_dir) {
  pairs <- results$pairs
  r_co2_theoretical <- results$r_co2_theoretical

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 圖 1：r_total 分布
  p1 <- ggplot(pairs, aes(x = r_total)) +
    geom_histogram(bins = 15, fill = "steelblue", color = "white", alpha = 0.7) +
    geom_vline(xintercept = r_co2_theoretical, color = "red",
               linetype = "dashed", linewidth = 1) +
    annotate("text", x = r_co2_theoretical + 5, y = Inf, vjust = 2,
             label = paste0("理論 r_CO₂ = ", round(r_co2_theoretical, 1), " g/hr"),
             color = "red") +
    labs(
      title = "睡眠期間總質量流失率 r(t) 分布",
      subtitle = paste0("n = ", nrow(pairs), " 個有效睡眠配對"),
      x = "r(t) = ΔM/Δt (g/hr)",
      y = "次數"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))

  ggsave(file.path(output_dir, "08_r_total_distribution.png"), p1,
         width = 10, height = 6, dpi = 150)

  # 圖 2：r_H₂O（反推）分布
  p2 <- ggplot(pairs, aes(x = r_h2o_implied)) +
    geom_histogram(bins = 15, fill = "orange", color = "white", alpha = 0.7) +
    geom_vline(xintercept = 0, color = "black", linetype = "dashed") +
    geom_vline(xintercept = 20, color = "blue", linetype = "dotted", linewidth = 1) +
    annotate("text", x = 20 + 5, y = Inf, vjust = 2,
             label = "預期最低 ~20 g/hr", color = "blue") +
    labs(
      title = "反推 r_H₂O 分布（假設理論 r_CO₂ 正確）",
      subtitle = paste0("r_H₂O = r(t) - ", round(r_co2_theoretical, 1), " g/hr"),
      x = "r_H₂O (g/hr)",
      y = "次數"
    ) +
    theme_minimal()

  ggsave(file.path(output_dir, "09_r_h2o_implied_distribution.png"), p2,
         width = 10, height = 6, dpi = 150)

  # 圖 3：r_total vs 睡眠時長
  p3 <- ggplot(pairs, aes(x = delta_t_hr, y = r_total)) +
    geom_point(alpha = 0.6, size = 2) +
    geom_smooth(method = "lm", se = TRUE, color = "red") +
    geom_hline(yintercept = r_co2_theoretical, color = "blue",
               linetype = "dashed") +
    labs(
      title = "r(t) vs 睡眠時長",
      x = "睡眠時長 (小時)",
      y = "r(t) (g/hr)"
    ) +
    theme_minimal()

  ggsave(file.path(output_dir, "10_r_vs_sleep_duration.png"), p3,
         width = 10, height = 6, dpi = 150)

  # 圖 4：雙變量分布
  p4 <- ggplot(pairs, aes(x = r_co2_theoretical, y = r_h2o_implied)) +
    geom_point(aes(color = delta_t_hr), size = 3) +
    scale_color_viridis_c(name = "睡眠時長\n(hr)") +
    geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
    labs(
      title = "各夜晚的 r_CO₂ 與 r_H₂O 關係",
      subtitle = "（假設 r_CO₂ 恆定）",
      x = "r_CO₂ (g/hr) - 固定",
      y = "r_H₂O (g/hr) - 變動"
    ) +
    theme_minimal()

  ggsave(file.path(output_dir, "11_co2_vs_h2o_components.png"), p4,
         width = 10, height = 8, dpi = 150)

  cat("圖表已儲存至:", output_dir, "\n")

  return(list(p1 = p1, p2 = p2, p3 = p3, p4 = p4))
}

# -----------------------------------------------------------------------------
# 5. 主程式
# -----------------------------------------------------------------------------

main_v2 <- function() {
  data_file <- "../data/BodyComposition_201011-202601.csv"
  output_dir <- "../output"

  cat("\n讀取數據...\n")
  data <- read_data(data_file)
  cat("總筆數:", nrow(data), "\n\n")

  cat("找睡眠配對（嚴格時間窗口）...\n")
  pairs <- find_sleep_pairs(data)
  cat("有效配對:", nrow(pairs), "\n\n")

  if (nrow(pairs) < 5) {
    cat("配對數不足，無法進行分析。\n")
    return(NULL)
  }

  # 反向驗證分析
  results <- analyze_reverse_method(pairs)

  # 視覺化
  plots <- create_plots(results, output_dir)

  cat("\n" %>% paste(rep("=", 60), collapse = ""), "\n")
  cat("分析完成！\n")
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n")

  return(results)
}

# -----------------------------------------------------------------------------
# 執行
# -----------------------------------------------------------------------------

if (!interactive()) {
  results_v2 <- main_v2()
}

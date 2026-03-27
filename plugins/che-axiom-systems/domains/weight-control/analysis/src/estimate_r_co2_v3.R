# =============================================================================
# r_CO₂ 估計方法 v3：完整篩選流程
# =============================================================================
#
# 篩選原則（依序套用）：
#   (1) Δt ∈ [4, 12] 小時 — 合理睡眠時長
#   (2) ΔM > 0           — 質量守恆（睡眠期間必然減重）
#   (3) ΔM ≥ 2ε = 200g   — 測量精度（ε = 100g，體重計精度 0.1 kg）
#   (4) DBSCAN 過濾      — 排除 r_total 異常值（k=3, eps=P75）
#
# 最終有效樣本：n = 45 晚
#
# =============================================================================

library(dplyr)
library(lubridate)
library(ggplot2)
library(dbscan)

# -----------------------------------------------------------------------------
# 參數設定
# -----------------------------------------------------------------------------

EPSILON <- 100           # g（體重計精度 0.1 kg）
MIN_DELTA_M <- 2 * EPSILON  # 200g
MIN_SLEEP_HOURS <- 4
MAX_SLEEP_HOURS <- 12

# DBSCAN 參數
DBSCAN_K <- 3            # k-NN 的 k 值
DBSCAN_EPS_QUANTILE <- 0.75  # 用 P75 作為 eps

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
# 2. 找睡眠配對（基於時間長度）
# -----------------------------------------------------------------------------

find_sleep_pairs <- function(data) {
  pairs <- data.frame()

  for (i in 1:(nrow(data) - 1)) {
    t1 <- data$datetime[i]
    t2 <- data$datetime[i + 1]

    # 計算時間差
    delta_t <- as.numeric(difftime(t2, t1, units = "hours"))

    # 條件 1: 合理睡眠時長
    if (delta_t < MIN_SLEEP_HOURS || delta_t > MAX_SLEEP_HOURS) next

    # 體重變化
    bed_weight <- data$weight_kg[i]
    wake_weight <- data$weight_kg[i + 1]
    delta_M_g <- (bed_weight - wake_weight) * 1000  # g

    # 條件 2: 質量守恆（體重下降）
    if (delta_M_g <= 0) next

    # 條件 3: 測量精度
    if (delta_M_g < MIN_DELTA_M) next

    # 計算 r(t)
    r_total <- delta_M_g / delta_t  # g/hr

    # 取得 BMR
    bmr <- data$bmr_kcal[i]

    pairs <- rbind(pairs, data.frame(
      bed_datetime = t1,
      wake_datetime = t2,
      bed_hour = data$hour[i],
      wake_hour = data$hour[i + 1],
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
# 3. DBSCAN 異常值偵測
# -----------------------------------------------------------------------------

apply_dbscan_filter <- function(pairs) {
  cat("=== DBSCAN 異常值偵測 ===\n")
  cat("參數: k =", DBSCAN_K, ", eps = P", DBSCAN_EPS_QUANTILE * 100, "\n\n")

  # 準備數據矩陣
  r_matrix <- matrix(pairs$r_total, ncol = 1)

  # 計算 k-NN 距離
  knn_dist <- kNNdist(r_matrix, k = DBSCAN_K)

  # 用 P75 作為 eps
  eps_val <- quantile(knn_dist, DBSCAN_EPS_QUANTILE)
  cat("k-NN 距離 P75 =", round(eps_val, 2), "\n")

  # 執行 DBSCAN
  db_result <- dbscan(r_matrix, eps = eps_val, minPts = DBSCAN_K)

  # 標記結果
  pairs$cluster <- db_result$cluster
  pairs$is_outlier <- (db_result$cluster == 0)

  # 統計
  n_outliers <- sum(pairs$is_outlier)
  n_inliers <- sum(!pairs$is_outlier)

  cat("識別為異常值:", n_outliers, "筆\n")
  cat("保留為正常值:", n_inliers, "筆\n\n")

  # 顯示異常值
  if (n_outliers > 0) {
    cat("--- 異常值詳情 ---\n")
    outliers <- pairs %>% filter(is_outlier)
    for (i in 1:nrow(outliers)) {
      cat(sprintf("  %s %02.0f:00 → %02.0f:00: r = %.1f g/hr\n",
                  as.Date(outliers$bed_datetime[i]),
                  outliers$bed_hour[i],
                  outliers$wake_hour[i],
                  outliers$r_total[i]))
    }
    cat("\n")
  }

  return(list(
    pairs = pairs,
    eps = eps_val,
    knn_dist = knn_dist
  ))
}

# -----------------------------------------------------------------------------
# 4. 估計 r_CO₂
# -----------------------------------------------------------------------------

estimate_r_co2 <- function(pairs) {
  # 只用正常值
  valid_pairs <- pairs %>% filter(!is_outlier)

  cat("=== r_CO₂ 估計結果 ===\n")
  cat("有效配對數:", nrow(valid_pairs), "\n\n")

  # 方法 1: 理論值（從 BMR）
  avg_bmr <- mean(valid_pairs$bmr_kcal, na.rm = TRUE)
  r_co2_theoretical <- avg_bmr * 0.2 / 24

  cat("--- 方法 1: 理論值 ---\n")
  cat("平均 BMR:", round(avg_bmr), "kcal/天\n")
  cat("r_CO₂ = BMR × 0.2 / 24 =", round(r_co2_theoretical, 2), "g/hr\n\n")

  # 方法 2: 從 min(r) 估計
  r_min <- min(valid_pairs$r_total)
  r_p05 <- quantile(valid_pairs$r_total, 0.05)
  r_p10 <- quantile(valid_pairs$r_total, 0.10)

  cat("--- 方法 2: 從 r_total 分布 ---\n")
  cat("min(r):", round(r_min, 2), "g/hr\n")
  cat("P05(r):", round(r_p05, 2), "g/hr\n")
  cat("P10(r):", round(r_p10, 2), "g/hr\n\n")

  # r_total 統計
  cat("--- r_total 分布統計 ---\n")
  cat("平均:", round(mean(valid_pairs$r_total), 2), "g/hr\n")
  cat("中位數:", round(median(valid_pairs$r_total), 2), "g/hr\n")
  cat("標準差:", round(sd(valid_pairs$r_total), 2), "g/hr\n")
  cat("範圍:", round(min(valid_pairs$r_total), 2), "-",
      round(max(valid_pairs$r_total), 2), "g/hr\n\n")

  # 計算每日碳流出
  daily_co2_g <- r_co2_theoretical * 24
  daily_carbon_g <- daily_co2_g * (12/44)  # CO₂ 中碳的比例

  cat("=== 每日碳流出估計 ===\n")
  cat("每日 CO₂ 呼出:", round(daily_co2_g, 0), "g/天\n")
  cat("每日碳流出:", round(daily_carbon_g, 0), "g C/天\n")

  return(list(
    r_co2_theoretical = r_co2_theoretical,
    r_min = r_min,
    r_p05 = r_p05,
    r_p10 = r_p10,
    daily_carbon_g = daily_carbon_g,
    valid_pairs = valid_pairs
  ))
}

# -----------------------------------------------------------------------------
# 5. 視覺化
# -----------------------------------------------------------------------------

create_plots <- function(dbscan_result, estimates, output_dir) {
  pairs <- dbscan_result$pairs
  valid_pairs <- estimates$valid_pairs
  r_co2 <- estimates$r_co2_theoretical

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 圖 1: DBSCAN 結果
  pairs$status <- ifelse(pairs$is_outlier, "異常值", "正常值")

  p1 <- ggplot(pairs, aes(x = r_total, fill = status)) +
    geom_histogram(bins = 15, color = "white", alpha = 0.7) +
    geom_vline(xintercept = r_co2, color = "red",
               linetype = "dashed", linewidth = 1) +
    scale_fill_manual(values = c("正常值" = "steelblue", "異常值" = "tomato")) +
    annotate("text", x = r_co2 + 8, y = Inf, vjust = 2,
             label = paste0("理論 r_CO₂ = ", round(r_co2, 1), " g/hr"),
             color = "red") +
    labs(
      title = "DBSCAN 異常值偵測結果",
      subtitle = paste0("k = ", DBSCAN_K, ", eps = P75 = ",
                        round(dbscan_result$eps, 1)),
      x = "r(t) = ΔM/Δt (g/hr)",
      y = "次數",
      fill = "狀態"
    ) +
    theme_minimal() +
    theme(legend.position = "top")

  ggsave(file.path(output_dir, "21_dbscan_final.png"), p1,
         width = 10, height = 6, dpi = 150)

  # 圖 2: 正常值分布
  p2 <- ggplot(valid_pairs, aes(x = r_total)) +
    geom_histogram(bins = 12, fill = "steelblue", color = "white", alpha = 0.7) +
    geom_vline(xintercept = r_co2, color = "red",
               linetype = "dashed", linewidth = 1) +
    geom_vline(xintercept = estimates$r_min, color = "darkgreen",
               linetype = "dotted", linewidth = 1) +
    annotate("text", x = r_co2 + 5, y = Inf, vjust = 2,
             label = paste0("理論 r_CO₂ = ", round(r_co2, 1)),
             color = "red", size = 3.5) +
    annotate("text", x = estimates$r_min + 5, y = Inf, vjust = 4,
             label = paste0("min(r) = ", round(estimates$r_min, 1)),
             color = "darkgreen", size = 3.5) +
    labs(
      title = "篩選後 r(t) 分布",
      subtitle = paste0("n = ", nrow(valid_pairs), " 個有效睡眠配對"),
      x = "r(t) = ΔM/Δt (g/hr)",
      y = "次數"
    ) +
    theme_minimal()

  ggsave(file.path(output_dir, "22_r_filtered_distribution.png"), p2,
         width = 10, height = 6, dpi = 150)

  # 圖 3: Strip plot with labels
  pairs_sorted <- pairs %>% arrange(r_total) %>% mutate(idx = row_number())

  p3 <- ggplot(pairs_sorted, aes(x = idx, y = r_total, color = status)) +
    geom_point(size = 3) +
    geom_text(aes(label = sprintf("%s\n%02.0f→%02.0f",
                                   format(as.Date(bed_datetime), "%m/%d"),
                                   bed_hour, wake_hour)),
              vjust = -0.5, size = 2, check_overlap = TRUE) +
    geom_hline(yintercept = r_co2, color = "red", linetype = "dashed") +
    scale_color_manual(values = c("正常值" = "steelblue", "異常值" = "tomato")) +
    labs(
      title = "所有配對的 r(t) 值（按大小排序）",
      x = "排序索引",
      y = "r(t) (g/hr)",
      color = "狀態"
    ) +
    theme_minimal() +
    theme(legend.position = "top")

  ggsave(file.path(output_dir, "23_strip_plot_labeled.png"), p3,
         width = 14, height = 8, dpi = 150)

  cat("\n圖表已儲存至:", output_dir, "\n")

  return(list(p1 = p1, p2 = p2, p3 = p3))
}

# -----------------------------------------------------------------------------
# 6. 主程式
# -----------------------------------------------------------------------------

main_v3 <- function() {
  data_file <- "../data/BodyComposition_201011-202601.csv"
  output_dir <- "../output"

  cat("\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("r_CO₂ 估計 v3：DBSCAN 異常值偵測\n")
  cat(paste(rep("=", 60), collapse = ""), "\n\n")

  # 讀取數據
  cat("讀取數據...\n")
  data <- read_data(data_file)
  cat("總筆數:", nrow(data), "\n\n")

  # 找睡眠配對
  cat("篩選條件:\n")
  cat("  - Δt ∈ [", MIN_SLEEP_HOURS, ",", MAX_SLEEP_HOURS, "] 小時\n")
  cat("  - ΔM > 0（質量守恆）\n")
  cat("  - ΔM ≥", MIN_DELTA_M, "g（2ε）\n\n")

  pairs <- find_sleep_pairs(data)
  cat("初步篩選後配對數:", nrow(pairs), "\n\n")

  if (nrow(pairs) < 10) {
    cat("配對數不足，無法進行分析。\n")
    return(NULL)
  }

  # DBSCAN 異常值偵測
  dbscan_result <- apply_dbscan_filter(pairs)

  # 估計 r_CO₂
  estimates <- estimate_r_co2(dbscan_result$pairs)

  # 視覺化
  plots <- create_plots(dbscan_result, estimates, output_dir)

  cat("\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("分析完成！\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")

  return(list(
    dbscan_result = dbscan_result,
    estimates = estimates,
    plots = plots
  ))
}

# -----------------------------------------------------------------------------
# 執行
# -----------------------------------------------------------------------------

if (!interactive()) {
  results_v3 <- main_v3()
}

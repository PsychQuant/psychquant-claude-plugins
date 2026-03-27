# =============================================================================
# 體重數據綜合分析
# =============================================================================
#
# 針對長期體重追蹤數據的完整分析
# 資料：BodyComposition_201011-202601.csv (1285 筆，2020-2026)
#
# =============================================================================

library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyr)

# -----------------------------------------------------------------------------
# 1. 讀取與清理數據
# -----------------------------------------------------------------------------

read_and_clean_data <- function(file_path) {
  data <- read.csv(file_path, fileEncoding = "UTF-8-BOM")

  # 解析欄位（處理中文欄位名）
  colnames(data) <- c("datetime_str", "timezone", "weight_kg", "body_fat_pct",
                      "fat_mass_kg", "visceral_fat", "bmr_kcal",
                      "skeletal_muscle_pct", "skeletal_muscle_kg",
                      "bmi", "body_age", "model")

  data <- data %>%
    mutate(
      datetime = ymd_hm(datetime_str),
      date = as.Date(datetime),
      year = year(datetime),
      month = month(datetime),
      hour = hour(datetime),
      weight_kg = as.numeric(weight_kg),
      body_fat_pct = as.numeric(body_fat_pct),
      fat_mass_kg = as.numeric(fat_mass_kg),
      bmr_kcal = as.numeric(bmr_kcal),
      skeletal_muscle_pct = as.numeric(skeletal_muscle_pct),
      skeletal_muscle_kg = as.numeric(skeletal_muscle_kg),
      bmi = as.numeric(bmi),
      visceral_fat = as.numeric(visceral_fat)
    ) %>%
    filter(!is.na(datetime), !is.na(weight_kg)) %>%
    arrange(datetime)

  return(data)
}

# -----------------------------------------------------------------------------
# 2. 基本統計摘要
# -----------------------------------------------------------------------------

summarize_data <- function(data) {
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n")
  cat("數據概覽\n")
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n\n")

  cat("總測量次數:", nrow(data), "\n")
  cat("日期範圍:", as.character(min(data$date)), "到", as.character(max(data$date)), "\n")
  cat("總天數:", as.numeric(max(data$date) - min(data$date)), "天\n\n")

  # 體重統計
  cat("--- 體重 (kg) ---\n")
  cat("起始:", round(first(data$weight_kg), 1), "kg\n")
  cat("最終:", round(last(data$weight_kg), 1), "kg\n")
  cat("變化:", round(last(data$weight_kg) - first(data$weight_kg), 1), "kg\n")
  cat("最低:", round(min(data$weight_kg), 1), "kg\n")
  cat("最高:", round(max(data$weight_kg), 1), "kg\n")
  cat("平均:", round(mean(data$weight_kg), 1), "kg\n\n")

  # 體脂率統計
  cat("--- 體脂率 (%) ---\n")
  cat("起始:", round(first(data$body_fat_pct), 1), "%\n")
  cat("最終:", round(last(data$body_fat_pct), 1), "%\n")
  cat("變化:", round(last(data$body_fat_pct) - first(data$body_fat_pct), 1), "%\n\n")

  # BMR 統計
  cat("--- 基礎代謝 (kcal) ---\n")
  cat("平均 BMR:", round(mean(data$bmr_kcal, na.rm = TRUE)), "kcal/天\n")
  cat("理論 r_CO₂:", round(mean(data$bmr_kcal, na.rm = TRUE) * 0.2 / 24, 1), "g/hr\n\n")
}

# -----------------------------------------------------------------------------
# 3. 睡眠配對分析（改進版）
# -----------------------------------------------------------------------------

analyze_sleep_pairs <- function(data) {
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n")
  cat("睡眠期間體重變化分析\n")
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n\n")

  # 定義時間窗口
  # 睡前：20:00 - 03:00
  # 起床：05:00 - 10:00

  data <- data %>%
    mutate(
      measurement_type = case_when(
        hour >= 20 | hour <= 3 ~ "bedtime",
        hour >= 5 & hour <= 10 ~ "morning",
        TRUE ~ "other"
      )
    )

  # 找配對
  pairs <- data.frame()
  bedtime_records <- data %>% filter(measurement_type == "bedtime")
  morning_records <- data %>% filter(measurement_type == "morning")

  for (i in 1:nrow(bedtime_records)) {
    bed_time <- bedtime_records$datetime[i]
    bed_weight <- bedtime_records$weight_kg[i]
    bed_hour <- bedtime_records$hour[i]
    bed_date <- bedtime_records$date[i]

    # 決定目標日期
    if (bed_hour >= 20) {
      target_date <- bed_date + 1
    } else {
      target_date <- bed_date
    }

    morning_match <- morning_records %>%
      filter(date == target_date) %>%
      slice(1)

    if (nrow(morning_match) == 1) {
      wake_time <- morning_match$datetime
      wake_weight <- morning_match$weight_kg

      delta_t <- as.numeric(difftime(wake_time, bed_time, units = "hours"))

      # 只保留合理的時間差
      if (delta_t > 3 && delta_t < 14) {
        delta_M <- bed_weight - wake_weight  # kg
        r <- delta_M / delta_t * 1000  # g/hr

        pairs <- rbind(pairs, data.frame(
          bed_datetime = bed_time,
          wake_datetime = wake_time,
          bed_weight = bed_weight,
          wake_weight = wake_weight,
          delta_t = delta_t,
          delta_M_kg = delta_M,
          delta_M_g = delta_M * 1000,
          r_g_hr = r
        ))
      }
    }
  }

  cat("有效配對數:", nrow(pairs), "\n\n")

  if (nrow(pairs) == 0) {
    cat("沒有找到有效的睡前-起床配對。\n")
    return(NULL)
  }

  # 只分析體重下降的配對（睡眠時應該減重）
  positive_pairs <- pairs %>% filter(delta_M_g > 0)
  negative_pairs <- pairs %>% filter(delta_M_g <= 0)

  cat("體重下降配對:", nrow(positive_pairs), "(",
      round(nrow(positive_pairs)/nrow(pairs)*100, 1), "%)\n")
  cat("體重增加配對:", nrow(negative_pairs), "(",
      round(nrow(negative_pairs)/nrow(pairs)*100, 1), "%)\n\n")

  if (nrow(positive_pairs) < 5) {
    cat("體重下降配對數不足，無法估計 r_CO₂。\n")
    return(pairs)
  }

  # 使用體重下降配對估計 r_CO₂
  cat("--- 使用體重下降配對分析 ---\n")
  cat("r 平均值:", round(mean(positive_pairs$r_g_hr), 1), "g/hr\n")
  cat("r 中位數:", round(median(positive_pairs$r_g_hr), 1), "g/hr\n")
  cat("r 最小值:", round(min(positive_pairs$r_g_hr), 1), "g/hr\n")
  cat("r 最大值:", round(max(positive_pairs$r_g_hr), 1), "g/hr\n")
  cat("r P05:", round(quantile(positive_pairs$r_g_hr, 0.05), 1), "g/hr\n")
  cat("r P10:", round(quantile(positive_pairs$r_g_hr, 0.10), 1), "g/hr\n\n")

  # 估計 r_CO₂
  r_H2O_min <- 20  # 假設最小蒸散
  r_p10 <- quantile(positive_pairs$r_g_hr, 0.10)
  r_co2_est <- max(0, r_p10 - r_H2O_min)  # 確保非負

  cat("--- r_CO₂ 估計 ---\n")
  cat("假設 r_H₂O_min =", r_H2O_min, "g/hr\n")
  cat("使用 P10(r) =", round(r_p10, 1), "g/hr\n")
  cat("估計 r_CO₂ ≈", round(r_co2_est, 1), "g/hr\n\n")

  # 與理論值比較
  avg_bmr <- mean(data$bmr_kcal, na.rm = TRUE)
  theoretical_r_co2 <- avg_bmr * 0.2 / 24

  cat("--- 與理論比較 ---\n")
  cat("BMR:", round(avg_bmr), "kcal/天\n")
  cat("理論 r_CO₂:", round(theoretical_r_co2, 1), "g/hr\n")
  cat("估計/理論 比值:", round(r_co2_est / theoretical_r_co2, 2), "\n\n")

  return(list(
    all_pairs = pairs,
    positive_pairs = positive_pairs,
    r_co2_est = r_co2_est,
    theoretical_r_co2 = theoretical_r_co2
  ))
}

# -----------------------------------------------------------------------------
# 4. 長期趨勢分析
# -----------------------------------------------------------------------------

analyze_trends <- function(data) {
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n")
  cat("長期趨勢分析\n")
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n\n")

  # 按月彙總
  monthly <- data %>%
    group_by(year, month) %>%
    summarize(
      n = n(),
      weight_mean = mean(weight_kg),
      weight_min = min(weight_kg),
      weight_max = max(weight_kg),
      fat_pct_mean = mean(body_fat_pct, na.rm = TRUE),
      bmr_mean = mean(bmr_kcal, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      year_month = paste(year, sprintf("%02d", month), sep = "-")
    )

  cat("月度統計（部分）:\n")
  print(head(monthly, 10))
  cat("...\n")
  print(tail(monthly, 5))
  cat("\n")

  # 計算體重變化趨勢
  # 使用線性迴歸
  data$days_from_start <- as.numeric(data$date - min(data$date))

  weight_model <- lm(weight_kg ~ days_from_start, data = data)

  cat("--- 線性趨勢 ---\n")
  cat("斜率:", round(coef(weight_model)[2] * 30, 2), "kg/月\n")
  cat("斜率:", round(coef(weight_model)[2] * 365, 2), "kg/年\n")
  cat("R²:", round(summary(weight_model)$r.squared, 3), "\n\n")

  # 碳當量分析
  # 如果體重增加，計算需要多少碳滯留
  total_weight_change <- last(data$weight_kg) - first(data$weight_kg)  # kg
  total_days <- as.numeric(max(data$date) - min(data$date))

  # 假設體重變化主要是脂肪（77% 碳）和肌肉（約 15% 碳，考慮水分）
  # 簡化假設：平均 50% 是碳
  carbon_change <- total_weight_change * 0.5 * 1000  # g
  daily_carbon_balance <- carbon_change / total_days  # g/天

  cat("--- 碳當量分析 ---\n")
  cat("總體重變化:", round(total_weight_change, 1), "kg\n")
  cat("總天數:", total_days, "天\n")
  cat("估計碳變化:", round(carbon_change), "g\n")
  cat("每日淨碳平衡:", round(daily_carbon_balance, 1), "g/天\n")

  if (daily_carbon_balance > 0) {
    cat("→ 每日淨碳滯留（增重中）\n")
  } else {
    cat("→ 每日淨碳流出（減重中）\n")
  }
  cat("\n")

  return(monthly)
}

# -----------------------------------------------------------------------------
# 5. 視覺化
# -----------------------------------------------------------------------------

create_visualizations <- function(data, output_dir) {
  # 確保輸出目錄存在
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 圖 1：體重長期趨勢
  p1 <- ggplot(data, aes(x = date, y = weight_kg)) +
    geom_point(alpha = 0.3, size = 1) +
    geom_smooth(method = "loess", span = 0.1, color = "red", se = FALSE) +
    labs(
      title = "體重長期趨勢 (2020-2026)",
      x = "日期",
      y = "體重 (kg)"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))

  ggsave(file.path(output_dir, "01_weight_trend.png"), p1,
         width = 12, height = 6, dpi = 150)

  # 圖 2：體脂率趨勢
  p2 <- ggplot(data, aes(x = date, y = body_fat_pct)) +
    geom_point(alpha = 0.3, size = 1, color = "orange") +
    geom_smooth(method = "loess", span = 0.1, color = "red", se = FALSE) +
    labs(
      title = "體脂率長期趨勢",
      x = "日期",
      y = "體脂率 (%)"
    ) +
    theme_minimal()

  ggsave(file.path(output_dir, "02_bodyfat_trend.png"), p2,
         width = 12, height = 6, dpi = 150)

  # 圖 3：體重 vs 體脂率
  p3 <- ggplot(data, aes(x = weight_kg, y = body_fat_pct, color = year)) +
    geom_point(alpha = 0.5, size = 1.5) +
    scale_color_viridis_c() +
    labs(
      title = "體重 vs 體脂率",
      x = "體重 (kg)",
      y = "體脂率 (%)",
      color = "年份"
    ) +
    theme_minimal()

  ggsave(file.path(output_dir, "03_weight_vs_bodyfat.png"), p3,
         width = 10, height = 8, dpi = 150)

  # 圖 4：測量時間分布
  p4 <- ggplot(data, aes(x = hour)) +
    geom_histogram(bins = 24, fill = "steelblue", color = "white") +
    scale_x_continuous(breaks = seq(0, 23, 2)) +
    labs(
      title = "測量時間分布",
      x = "小時",
      y = "次數"
    ) +
    theme_minimal()

  ggsave(file.path(output_dir, "04_measurement_time.png"), p4,
         width = 10, height = 6, dpi = 150)

  # 圖 5：日內體重變化（箱線圖）
  data_with_period <- data %>%
    mutate(
      period = case_when(
        hour >= 0 & hour < 6 ~ "凌晨 (0-6)",
        hour >= 6 & hour < 12 ~ "早上 (6-12)",
        hour >= 12 & hour < 18 ~ "下午 (12-18)",
        hour >= 18 ~ "晚上 (18-24)"
      ),
      period = factor(period, levels = c("凌晨 (0-6)", "早上 (6-12)",
                                          "下午 (12-18)", "晚上 (18-24)"))
    )

  # 計算每日平均，然後看各時段偏差
  daily_avg <- data %>%
    group_by(date) %>%
    summarize(daily_mean = mean(weight_kg), .groups = "drop")

  data_normalized <- data_with_period %>%
    left_join(daily_avg, by = "date") %>%
    filter(!is.na(daily_mean)) %>%
    mutate(weight_deviation = weight_kg - daily_mean)

  p5 <- ggplot(data_normalized, aes(x = period, y = weight_deviation, fill = period)) +
    geom_boxplot() +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    labs(
      title = "日內體重波動（相對於當日平均）",
      x = "時段",
      y = "體重偏差 (kg)"
    ) +
    theme_minimal() +
    theme(legend.position = "none")

  ggsave(file.path(output_dir, "05_intraday_variation.png"), p5,
         width = 10, height = 6, dpi = 150)

  cat("圖表已儲存至:", output_dir, "\n")

  return(list(p1 = p1, p2 = p2, p3 = p3, p4 = p4, p5 = p5))
}

# -----------------------------------------------------------------------------
# 6. 主程式
# -----------------------------------------------------------------------------

main <- function() {
  # 設定路徑
  data_file <- "../data/BodyComposition_201011-202601.csv"
  output_dir <- "../output"

  # 讀取數據
  cat("\n讀取數據...\n\n")
  data <- read_and_clean_data(data_file)

  # 基本統計
  summarize_data(data)

  # 睡眠配對分析
  sleep_results <- analyze_sleep_pairs(data)

  # 長期趨勢
  monthly <- analyze_trends(data)

  # 視覺化
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n")
  cat("生成視覺化圖表\n")
  cat("=" %>% rep(60) %>% paste(collapse = ""), "\n\n")
  plots <- create_visualizations(data, output_dir)

  # 返回結果
  return(list(
    data = data,
    sleep_results = sleep_results,
    monthly = monthly,
    plots = plots
  ))
}

# -----------------------------------------------------------------------------
# 執行
# -----------------------------------------------------------------------------

if (!interactive()) {
  results <- main()
} else {
  cat("互動模式：執行 results <- main() 來運行分析\n")
}

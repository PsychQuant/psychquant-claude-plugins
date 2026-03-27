# =============================================================================
# 將體重數據轉換成睡前-起床配對
# =============================================================================
#
# 輸入：BodyComposition_202508-202601.csv
# 輸出：sleep_pairs.csv
#
# =============================================================================

library(dplyr)
library(lubridate)

# -----------------------------------------------------------------------------
# 參數設定
# -----------------------------------------------------------------------------

# 睡眠間隔偵測（自動模式）
# 不用固定時間窗口，而是找出符合睡眠時長的測量間隔
MIN_SLEEP_HOURS <- 4   # 最短睡眠時間
MAX_SLEEP_HOURS <- 12  # 最長睡眠時間

# r_H2O_min 假設值（g/hr）
R_H2O_MIN <- 20

# -----------------------------------------------------------------------------
# 主程式
# -----------------------------------------------------------------------------

create_sleep_pairs <- function(input_file, output_file = NULL) {

  # 讀取數據
  data <- read.csv(input_file, fileEncoding = "UTF-8-BOM")

  # 解析欄位
  data <- data %>%
    mutate(
      datetime = ymd_hm(.[[1]]),  # 第一欄是日期時間
      date = as.Date(datetime),
      hour = hour(datetime),
      weight_kg = as.numeric(.[[3]]),  # 第三欄是體重
      body_fat_pct = as.numeric(.[[4]])  # 第四欄是體脂率
    ) %>%
    arrange(datetime)

  cat("=== 數據摘要 ===\n")
  cat("總測量次數:", nrow(data), "\n")
  cat("日期範圍:", as.character(min(data$date)), "到", as.character(max(data$date)), "\n")
  cat("\n")

  # ==========================================================================
  # 自動偵測睡眠配對
  # 策略：找出所有時間間隔在 MIN_SLEEP_HOURS ~ MAX_SLEEP_HOURS 的相鄰測量
  # ==========================================================================

  pairs <- data.frame()

  for (i in 1:(nrow(data) - 1)) {
    t1 <- data$datetime[i]
    t2 <- data$datetime[i + 1]

    # 計算時間差
    delta_t <- as.numeric(difftime(t2, t1, units = "hours"))

    # 檢查是否符合睡眠時長
    if (delta_t >= MIN_SLEEP_HOURS && delta_t <= MAX_SLEEP_HOURS) {

      bed_weight <- data$weight_kg[i]
      wake_weight <- data$weight_kg[i + 1]
      bed_fat <- data$body_fat_pct[i]
      wake_fat <- data$body_fat_pct[i + 1]

      # 計算體重變化
      delta_M <- (bed_weight - wake_weight) * 1000  # g
      r <- delta_M / delta_t  # g/hr

      # 只保留體重下降的配對（睡覺時應該會減重）
      if (delta_M > 0) {
        pairs <- rbind(pairs, data.frame(
          # 識別資訊
          pair_id = nrow(pairs) + 1,
          night_date = as.character(data$date[i]),

          # 睡前測量
          bed_datetime = as.character(t1),
          bed_hour = data$hour[i],
          bed_weight_kg = bed_weight,
          bed_fat_pct = bed_fat,

          # 起床測量
          wake_datetime = as.character(t2),
          wake_hour = data$hour[i + 1],
          wake_weight_kg = wake_weight,
          wake_fat_pct = wake_fat,

          # 計算結果
          sleep_hours = round(delta_t, 2),
          weight_loss_g = round(delta_M, 0),
          r_g_per_hr = round(r, 2)
        ))
      }
    }
  }

  cat("=== 配對結果 ===\n")
  cat("偵測條件：間隔", MIN_SLEEP_HOURS, "-", MAX_SLEEP_HOURS, "小時且體重下降\n")
  cat("有效配對數:", nrow(pairs), "\n\n")

  if (nrow(pairs) == 0) {
    cat("沒有找到有效配對。\n")
    cat("請確認數據中包含間隔 4-12 小時的連續測量。\n")
    return(NULL)
  }

  # 顯示配對
  cat("配對詳情:\n")
  for (i in 1:nrow(pairs)) {
    cat(sprintf("  [%d] %s %02d:00 → %02d:00: %.1f → %.1f kg (↓%d g, %.1f hr, r=%.1f g/hr)\n",
                pairs$pair_id[i],
                pairs$night_date[i],
                pairs$bed_hour[i],
                pairs$wake_hour[i],
                pairs$bed_weight_kg[i],
                pairs$wake_weight_kg[i],
                pairs$weight_loss_g[i],
                pairs$sleep_hours[i],
                pairs$r_g_per_hr[i]))
  }
  cat("\n")

  # 統計
  cat("=== 統計摘要 ===\n")
  cat("r 平均值:", round(mean(pairs$r_g_per_hr), 2), "g/hr\n")
  cat("r 標準差:", round(sd(pairs$r_g_per_hr), 2), "g/hr\n")
  cat("r 最小值:", round(min(pairs$r_g_per_hr), 2), "g/hr\n")
  cat("r 最大值:", round(max(pairs$r_g_per_hr), 2), "g/hr\n\n")

  # 估計 r_CO2
  r_min <- min(pairs$r_g_per_hr)
  r_co2_est <- r_min - R_H2O_MIN

  cat("=== r_CO2 估計 ===\n")
  cat("min(r) =", round(r_min, 2), "g/hr\n")
  cat("r_H2O_min =", R_H2O_MIN, "g/hr（假設）\n")
  cat("r_CO2 ≈", round(r_co2_est, 2), "g/hr\n\n")

  # 加入分解欄位
  pairs <- pairs %>%
    mutate(
      r_co2_est = r_co2_est,
      co2_g = round(r_co2_est * sleep_hours, 0),
      h2o_g = weight_loss_g - co2_g,
      co2_pct = round(co2_g / weight_loss_g * 100, 1),
      h2o_pct = round(h2o_g / weight_loss_g * 100, 1),
      fat_oxidized_g = round(co2_g / 2.8, 1)  # κ ≈ 2.8
    )

  # 輸出檔案
  if (!is.null(output_file)) {
    write.csv(pairs, output_file, row.names = FALSE)
    cat("已儲存至:", output_file, "\n")
  }

  return(pairs)
}

# -----------------------------------------------------------------------------
# 執行
# -----------------------------------------------------------------------------

if (!interactive()) {
  # 命令列執行
  input_file <- "../data/BodyComposition_201011-202601.csv"
  output_file <- "../data/sleep_pairs.csv"

  pairs <- create_sleep_pairs(input_file, output_file)
}

# 互動式使用：
# pairs <- create_sleep_pairs(
#   "../data/BodyComposition_201011-202601.csv",
#   "../data/sleep_pairs.csv"
# )

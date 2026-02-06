library(memoria)
library(distantia)

#example data
data(pollen, climate, package = "memoria")

#colnames
colnames(pollen)
# [1] "age"       "pinus"     "quercus"   "poaceae"
# [5] "artemisia"

colnames(climate)
# [1] "age"                     "temperatureAverage"
# [3] "rainfallAverage"         "temperatureWarmestMonth"
# [5] "temperatureColdestMonth" "oxigenIsotope"

nrow(pollen)
# 639
nrow(climate)
#800

#time resolution range in thousands of years
range(diff(pollen$age))
# 0.320 6.475

range(diff(climate$age))
# 1 1

#union of datasets with different resolution with memoria
df <- memoria::mergePalaeoData(
  datasets.list = list(
    pollen = pollen,
    climate = climate
  ),
  time.column = "age",
  interpolation.interval = 0.5 #500 years
)

nrow(df)
#1598

range(diff(df$age))
# [1] 0.5 0.5

colnames(df)
# [1] "age"
# [2] "pollen.pinus"
# [3] "pollen.quercus"
# [4] "pollen.poaceae"
# [5] "pollen.artemisia"
# [6] "climate.temperatureAverage"
# [7] "climate.rainfallAverage"
# [8] "climate.temperatureWarmestMonth"
# [9] "climate.temperatureColdestMonth"
# [10] "climate.oxigenIsotope"

#union of datasets with different resolution with distantia

#user argument
interpolation.interval <- 0.5

#step 1: convert both datasets to tsl
pollen.tsl <- distantia::tsl_init(
  x = pollen,
  time_column = "age"
)

climate.tsl <- distantia::tsl_init(
  x = climate,
  time_column = "age"
)

#step 2: get time range
pollen.tsl.time <- distantia::tsl_time_summary(
  tsl = pollen.tsl
)[c("begin", "end")] |>
  unlist()

climate.tsl.time <- distantia::tsl_time_summary(
  tsl = climate.tsl
)[c("begin", "end")] |>
  unlist()

#range of new time from the time intersection in both time series
new.time.from <- max(c(pollen.tsl.time["begin"], climate.tsl.time["begin"]))

new.time.to <- max(c(pollen.tsl.time["end"], climate.tsl.time["end"]))

new.time <- seq(
  from = new.time.from,
  to = new.time.to,
  by = interpolation.interval
)

#resample both time series
pollen.tsl.regular <- distantia::tsl_resample(
  tsl = pollen.tsl,
  new_time = new.time
)

climate.tsl.regular <- distantia::tsl_resample(
  tsl = climate.tsl,
  new_time = new.time
)

df <- rbind(
  distantia::tsl_to_df(tsl = pollen.tsl.regular),
  distantia::tsl_to_df(tsl = climate.tsl.regular)
) |>
  #use base R instead of tidyr!
  tidyr::pivot_wider(
    names_from = "name",
    values_from = "x"
  ) |>
  na.omit()

nrow(df)
#1598

range(diff(df$time))
#0.5 0.5

colnames(df)
# > colnames(df)
# [1] "time"                    "pinus"
# [3] "quercus"                 "poaceae"
# [5] "artemisia"               "temperatureAverage"
# [7] "rainfallAverage"         "temperatureWarmestMonth"
# [9] "temperatureColdestMonth" "oxigenIsotope"

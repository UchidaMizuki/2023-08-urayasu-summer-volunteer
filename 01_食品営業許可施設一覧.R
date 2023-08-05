source("setup.R")

# 01_食品営業許可施設一覧 -----------------------------------------------------------

# 年度末時点営業施設一覧（令和3年5月31日までに取得した営業許可にて営業中の施設）
# - https://www.pref.chiba.lg.jp/eishi/kyokaitiran/syokuhineigyoukyoka.html
curl::curl_download("https://www.pref.chiba.lg.jp/eishi/kyokaitiran/documents/2023-3getumatujiten3-1-2306syuusei.xlsx",
                    "data-raw/食品営業許可施設一覧_2022.xlsx")

licensed_food_business_2022 <- read_excel("data-raw/食品営業許可施設一覧_2022.xlsx",
                                          sheet = "②市川保健所") |>
  unite("施設名", `施設＿名称（屋号・商号）１`, `施設＿名称（屋号・商号）２`,
        sep = "/",
        na.rm = TRUE) |>
  unite("所在地", `所在地１`, `所在地２`,
        sep = "/",
        na.rm = TRUE) |>
  select(`施設名`, `所在地`, `業種`, `初回許可年月日`) |>
  filter(str_starts(`所在地`, "浦安市")) |>
  mutate(csis_geocode(`所在地`)) |>
  st_as_sf(coords = c("X", "Y"),
           crs = JGD2011)

write_sf(licensed_food_business_2022, "data/食品営業許可施設一覧_2022.geojson")

licensed_food_business_2022 |>
  st_drop_geometry() |>
  select(!c(loc_name, i_conf, i_lvl)) |>
  write_excel_csv("data/食品営業許可施設一覧_2022.csv")

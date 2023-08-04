source("setup.R")

# 00_共通データ ----------------------------------------------------------------

# 行政区域
dir_create("data-raw/行政区域_2023")

destfile <- file_temp()
curl::curl_download("https://nlftp.mlit.go.jp/ksj/gml/data/N03/N03-2023/N03-20230101_12_GML.zip",
                    destfile = destfile)
zip::unzip(destfile,
           exdir = "data-raw/行政区域_2023")

adminbdry_2023 <- read_sf("data-raw/行政区域_2023/N03-23_12_230101.shp",
                          options = "ENCODING=shift-jis") |>
  rename(city_name = N03_004) |>
  select(city_name) |>
  filter(city_name == "浦安市")
write_sf(adminbdry_2023, "data/行政区域_2023.geojson")

# 行政区域メッシュ
adminbdry_2023 <- read_sf("data/行政区域_2023.geojson")
grid250m_adminbdry_2023 <- adminbdry_2023 |>
  mutate(grid250m = jpgrid::geometry_to_grid(geometry,
                                             grid_size = "250m")) |>
  st_drop_geometry() |>
  unnest(grid250m) |>
  jpgrid::grid_as_sf(crs = JGD2011) |>
  mutate(grid250m = as.character(grid250m))
write_sf(grid250m_adminbdry_2023, "data/250mメッシュ_行政区域_2023.geojson")

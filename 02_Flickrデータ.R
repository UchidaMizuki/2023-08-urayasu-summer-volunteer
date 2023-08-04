source("setup.R")

# 02_Flickrデータ ------------------------------------------------------------

grid250m_adminbdry_2023 <- read_sf("data/250mメッシュ_行政区域_2023.geojson")

# 写真データの検索
# - FlickAPIパッケージを使用するためには環境変数に`FLICKR_API_KEY`を設定 => `Sys.setenv(FLICKR_API_KEY = )`
photo_search_flickr <- grid250m_adminbdry_2023 |>
  as_tibble() |>
  mutate(photo = geometry |>
           map(slowly(\(geometry) {
             FlickrAPI::get_photo_search(bbox = st_bbox(geometry),
                                         extras = c("description", "geo", "tags", "url_n", "date_taken"),
                                         per_page = 250) |>
               as_tibble()
           },
           rate = rate_delay(1e-1)),
           .progress = TRUE),
         .keep = "unused")

write_rds(photo_search_flickr, "data-temp/photo_search_flickr.rds")

photo_search_flickr <- read_rds("data-temp/photo_search_flickr.rds")

photo_search_flickr <- photo_search_flickr |>
  select(grid250m, photo) |>
  # 列の型が合わず縦に結合できないので文字列に変換
  mutate(photo = photo |>
           map(\(photo) {
             if (!vec_is_empty(photo)) {
               photo |>
                 mutate(across(!where(is.list),
                               as.character))
             }
           })) |>
  unnest(photo) |>
  unpack(description,
         names_sep = "") |>
  select(grid250m, title, description_content, datetaken, tags, latitude, longitude, url_n) |>
  mutate(across(c(latitude, longitude),
                as.double),
         datetaken = ymd_hms(datetaken)) |>
  st_as_sf(coords = c("longitude", "latitude"),
           crs = JGD2011)

write_sf(photo_search_flickr, "data/Flickrデータ.geojson")

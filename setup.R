library(tidyverse)
library(fs)
library(readxl)
library(vctrs)
library(sf)
library(reticulate)

# 00_setup ----------------------------------------------------------------

dir_create("data-raw")
dir_create("data-temp")
dir_create("data")

# 日本測地系
JGD2011 <- 6668

# シンプル ジオコーディング 実験
# - https://geocode.csis.u-tokyo.ac.jp/home/simple-geocoding/
csis_geocode <- function(address,
                         url_geocode = "https://geocode.csis.u-tokyo.ac.jp/cgi-bin/simple_geocode.cgi",
                         geosys = "world",
                         constraint = NULL) {
  unique_address <- vec_unique(address)
  unique_address |>
    map(slowly(\(address) {
      out <- httr::GET(url_geocode,
                       query = compact(list(addr = address,
                                            charset = "UTF8",
                                            geosys = geosys,
                                            constraint = constraint))) |>
        httr::content()

      tibble(loc_name = out |>
               xml2::xml_find_all("//address") |>
               xml2::xml_text() |>
               first(),
             X = out |>
               xml2::xml_find_all("//longitude") |>
               xml2::xml_double() |>
               first(),
             Y = out |>
               xml2::xml_find_all("//latitude") |>
               xml2::xml_double() |>
               first(),
             i_conf = out |>
               xml2::xml_find_all("//iConf") |>
               xml2::xml_integer() |>
               first(),
             i_lvl = out |>
               xml2::xml_find_all("//iLvl") |>
               xml2::xml_integer() |>
               first())
    },
    rate = rate_delay(1e-1)),
    .progress = TRUE) |>
    list_rbind() |>
    vec_slice(vec_match(address, unique_address))
}

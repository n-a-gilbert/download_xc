library(tidyverse)
library(here)
library(warbleR)

setwd(here::here("data"))

# read in eBird barchart histogram file (need to manually delete junk in top rows)
d <- read.delim(file = "kaeng_krachan_hotspots.txt", header = FALSE)

# clean/process species names and filter based on frequency
sci_names_to_query <- d |> 
  tibble::as_tibble() |> 
  # get rid of the html stuff
  dplyr::mutate(V1 = stringr::str_remove_all(V1, "<em class=sci>")) |> 
  dplyr::mutate(V1 = stringr::str_remove_all(V1, "</em>")) |>
  # filter out spuhs and slashes
  dplyr::filter(!grepl("sp.", V1)) |>
  dplyr::filter(!grepl("/", V1)) |> 
  tidyr::separate( V1, into = c("common", "sci"), sep = "\\(") |> 
  dplyr::mutate(sci = stringr::str_remove_all(sci, "\\)")) |> 
  dplyr::mutate(common = trimws(common)) |>
  dplyr::select(-V50) |> 
  # so it seems like the barcharts are arrange in 12 months with four blocks each
  # so there are 48 blocks total (not quite weekly)
  tidyr::pivot_longer(V2:V49, names_to = "block", values_to = "perc") |> 
  dplyr::mutate(block = readr::parse_number(block) - 1) |> 
  # dropping out summer stuff since I'm going to Thailand in the winter :)
  dplyr::filter(!(block > 16  & block < 35)) |> 
  dplyr::group_by(common, sci) |> 
  # calculate median percentage of checklists the species occurs on across blocks of interest
  dplyr::summarise( med = median(perc)) |> 
  # I'm going to retain species that are reported on at least 1% of checklists
  dplyr::filter(med > 0.01) |> 
  dplyr::arrange(-med)

sci_names_vector <- sci_names_to_query |> 
  dplyr::pull(sci)

# query Xeno-Canto for the focal species
# this step is just retrieving metadata for the focal species
kk <- list(list())
for(i in 1:length(sci_names_vector)){
  kk[[i]] <- warbleR::query_xc(qword = sci_names_vector[i])
  print( paste("Finished", i, "of", length(sci_names_vector)))
}

do.call(rbind, kk)

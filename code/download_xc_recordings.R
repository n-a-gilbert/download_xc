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
  dplyr::arrange(-med) |> 
  dplyr::mutate( nslice = ceiling(med * 10))

sci_names_vector <- sci_names_to_query |> 
  dplyr::pull(sci)

# query Xeno-Canto for the focal species
# this step is just retrieving metadata for the focal species
kk <- list(list())
for(i in 1:length(sci_names_vector)){
  kk[[i]] <- warbleR::query_xc(qword = sci_names_vector[i])
  print( paste("Finished", i, "of", length(sci_names_vector)))
}

kk_metadata <- dplyr::bind_rows(kk)

download_these <- kk_metadata |>
  # the call type column is a mess. Simplify to song, call, song and call, and other
  mutate( song = ifelse(grepl("song", Vocalization_type), 1, 0),
          call = ifelse(grepl("call", Vocalization_type), 1, 0)) |> 
  dplyr::mutate( type = ifelse(song == 1 & call == 0, "song", 
                               ifelse(song == 0 & call == 1, "call", 
                                      ifelse(song == 1 & call == 1, "song & call", "other")))) |> 
  # omit recordings without a quality score
  dplyr::filter(!Quality == "no score") |> 
  # convert to a number for sorting
  dplyr::mutate(qual = as.numeric(factor(Quality))) |>
  # get length of recording in seconds
  tidyr::separate( Length, into = c("minutes", "seconds"), sep = ":") |> 
  dplyr::mutate(across(minutes:seconds, function(x) as.numeric(x))) |> 
  dplyr::mutate(minutes = minutes * 60) |> 
  dplyr::mutate(len_sec = minutes + seconds) |> 
  # filter out recordings longer than 1.5 minutes
  dplyr::filter(len_sec < 90) |> 
  dplyr::mutate(sci = paste(Genus, Specific_epithet)) |> 
  dplyr::left_join(sci_names_to_query) |> 
  dplyr::group_by(sci, type) |>
  dplyr::arrange(sci, type, qual) |>
  # slice first row for each species and call type. should be arranged so the first row has the highest quality
  dplyr::slice_head(n = 1) |> 
  dplyr::ungroup() |> 
  dplyr::select(Recording_ID, common, type)

setwd(here::here("recordings"))

for( i in 1:nrow(download_these)){
  warbleR::query_xc(
    download = TRUE, 
    X = slice(download_these, i), 
    file.name = c("common", "type"))
  print( paste("Finished", i, "of", nrow(download_these)))
}

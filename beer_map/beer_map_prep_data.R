# beer_map_prep_data.R
# Prep data for beer maps
# Jesse Zlotoff
# 8/30/18

##### load packages
library(tidyverse)

##### load & recode brewery data

### load
breweries <- read_csv("all_breweries.csv")

### pull out state, clean it up
breweries$state <- breweries$addr2 %>%
    str_replace("^[^,]+, ([A-Za-z]{2}).*", "\\1")

prob_vals <- breweries %>%
    select(addr2, state) %>%
    filter(!str_detect(state, "^[A-Z]{2}$")) %>%
    unique()
print(prob_vals)

# manually check/fix problem data
breweries$state <- breweries$state %>%
    str_replace("Ma", "ME") %>%
    str_replace(", (..)", "\\1") %>%
    str_replace(",", "") %>%
    str_to_upper()

prob_vals <- breweries %>%
    select(addr2, state) %>%
    filter(!str_detect(state, "^[A-Z]{2}$")) %>%
    unique()
print(prob_vals)
rm(prob_vals)

### find and remove duplicates by brewery name
breweries <- breweries %>%
    group_by(name) %>%
    filter(row_number()==1) %>%
    arrange(name)

# flag brewery offshoots ... ie 10 Barrel Brewing Co vs 10 Barrel Brewing Co - Denver
breweries$main <- ""
for (n in breweries$name) {
#    print(paste(n, str_length(n)))
    breweries$main <- ifelse(substr(breweries$name,1,str_length(n)) == n & breweries$name !=n, n, breweries$main)
}

save(breweries, file="breweries.rdata")

tab <- breweries %>%
    group_by(state) %>%
    mutate(count = n()) %>%
    select(state, count) %>%
    distinct() %>%
    arrange(state)
print(tab)
rm(prob_vals, tab)

##### ratings data
ratings_raw <- read_csv("beer_history_personal.csv")

# remove duplicate beers
ratings <- ratings_raw %>%
    arrange(brewery_name, beer_name, desc(rating_score)) %>%
    group_by(brewery_name, beer_name) %>%
    mutate(n = row_number()) %>%
    filter(n==1) %>%
    select(-n) %>%
    ungroup()

# filter to US states and clean up data
ratings <- ratings %>%
    filter(brewery_country=="United States")

prob_vals <- ratings %>%
    select(brewery_name, brewery_city, brewery_state) %>%
    filter(!str_detect(brewery_state, "^[A-Z]{2}$")) %>%
    unique()
print(prob_vals)

# manually check/fix problem data
ratings$brewery_state <- ratings$brewery_state %>%
    str_replace("Pa", "PA")

rm(ratings_raw)

### save
save(ratings, file="ratings.rdata")


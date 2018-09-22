# beer_map_analysis.R
# Build beer maps/do analysis
# Jesse Zlotoff
# 8/31/18

##### load packages
library(kableExtra)
library(rgdal)
library(rgeos)
library(ggrepel)
library(Rcartogram)
library(getcartr)
library(tidyverse) # order matters since getcartr masks dplyr::select

##### load data
load("breweries.rdata")


##### data cleaning
brew_clean <- breweries %>%
    filter(type != "Planning") %>%
    filter(main == "") %>%
    filter(state != "")
rm(breweries)

state_lookup <- read_tsv("state_lookup.txt")

brew_clean <- brew_clean %>%
    left_join(state_lookup, c("state" = "Abbreviation")) %>%
    rename(Abbreviation = state, state=State)
rm(state_lookup)

##### quantity analysis
states <- brew_clean %>%
    group_by(state) %>%
    mutate(num_breweries = n()) %>%
    select(state, Abbreviation, num_breweries) %>%
    distinct() %>%
    arrange(state)

hist <- states %>%
    ggplot() +
    geom_histogram(mapping = aes(x=num_breweries), binwidth = 5)
#print(hist)

num_brew_table <- states %>%
    arrange(desc(num_breweries)) %>%
    select(state, num_breweries) %>%
    rename(State=state, "Number of Breweries"=num_breweries) %>%
    kable(escape = F, align="lr") %>%
    kable_styling(bootstrap_options = "condensed", full_width = F, position="left")
print(num_brew_table)

# control for population size
popsize <- read_csv("PEP_2017_PEPANNRES_with_ann.csv")
popsize <- popsize %>%
    filter(GEO.id != "Id") %>%
    rename(FIPS = GEO.id2, State = `GEO.display-label`) %>%
    select(FIPS, State, respop72017)

states <- states %>%
    inner_join(popsize, c("state" = "State"))
rm(popsize)

states <- states %>%
    mutate(respop72017 = as.numeric(respop72017),
           breweries_per_100k = num_breweries / (respop72017 / 100000))

brew_by_pop_table <- states %>%
    mutate(breweries_per_100k = round(breweries_per_100k, 2)) %>%
    select(state, breweries_per_100k) %>%
    arrange(desc(breweries_per_100k)) %>%
    rename(State=state, "Breweries per 100K People"=breweries_per_100k) %>%
    kable(escape = F, align="lr") %>%
    kable_styling(bootstrap_options = "condensed", full_width = F, position="left")
print(brew_by_pop_table)

comb_table <- states %>%
    mutate(breweries_per_100k = round(breweries_per_100k, 2)) %>%
    select(state, num_breweries, breweries_per_100k) %>%
    arrange(desc(num_breweries)) %>%
    rename(State=state, "Number of Breweries"=num_breweries, "Breweries per 100K People"=breweries_per_100k) %>%
    kable(escape = F, align="lrr") %>%
    kable_styling(bootstrap_options = "condensed", full_width = F, position="left")
print(comb_table)

##### compare num breweries to brewery density
states <- states %>%
    mutate(outlier = ifelse(Abbreviation %in% c("CA","VT","MT","ME","CO","OR","WA"), "Y", "N"),
           pop_in_100k = respop72017 / 100000.0)
outlier_labels <- states %>%
    filter(outlier == "Y") %>%
    select(Abbreviation, num_breweries, breweries_per_100k)

num_vs_density <- ggplot(data=states) +
    geom_point(mapping = aes(x=num_breweries, y=breweries_per_100k, size=pop_in_100k, color=outlier)) +
    labs(x="Number of Breweries", y="Brewery Density (per 100K people)") +
    labs(title="Number and Density of Breweries") +
    theme(legend.position="bottom", legend.title = element_text(size=10),
          plot.title = element_text(hjust = 0.5)) +
    guides(size=guide_legend(title="Population Size (in 100K)"),
           color=FALSE) +
    scale_color_manual(values=c("darkgreen", "purple")) +
    geom_text_repel(data=outlier_labels, aes(x=num_breweries, y=breweries_per_100k, label=Abbreviation),
        color="black", inherit.aes = FALSE)
plot(num_vs_density)
ggsave(num_vs_density, filename="num_vs_density.jpeg")


##### cartogram
hexgrid <- readOGR("us_states_hexgrid/us_states_hexgrid.shp")

hexgrid@data <- hexgrid@data %>%
    left_join(states, c("iso3166_2" = "Abbreviation"))
#plot(hexgrid)

hexgrid@data$id = rownames(hexgrid@data)
hexgrid.points = fortify(hexgrid, region="id")
hexgrid.df <- inner_join(hexgrid.points, hexgrid@data, by="id")
hexgrid_centers <- cbind.data.frame(data.frame(gCentroid(hexgrid, byid=TRUE), id=hexgrid@data$iso3166_2))

cartogram_num <- ggplot(data=hexgrid.df, aes(long,lat,group=group, fill = num_breweries)) +
    geom_polygon() +
    geom_path(color="white") +
    coord_equal() +
    theme_void() +
    labs(x=NULL, y=NULL) +
    labs(title="Number of Breweries by State") +
    scale_fill_continuous(trans = 'reverse') +
    theme(legend.position="bottom", legend.title = element_text(size=10),
          plot.title = element_text(hjust = 0.5)) +
    guides(fill=guide_legend(title="Number of Breweries")) +
    geom_text(data=hexgrid_centers, aes(x=x, y=y, label=id), size=3, colour="white", inherit.aes = FALSE)
plot(cartogram_num)
ggsave(cartogram_num, filename = "num_brewery_cartogram.jpeg")


cartogram_density <- ggplot(data=hexgrid.df, aes(long,lat,group=group, fill = breweries_per_100k)) +
    geom_polygon() +
    geom_path(color="white") +
    coord_equal() +
    theme_void() +
    labs(x=NULL, y=NULL) +
    labs(title="Brewery Density by State") +
    scale_fill_continuous(trans = 'reverse') +
    theme(legend.position="bottom", legend.title = element_text(size=10),
          plot.title = element_text(hjust = 0.5)) +
    guides(fill=guide_legend(title="Number of Breweries per 100,000 people",
           title.position="top")) +
    geom_text(data=hexgrid_centers, aes(x=x, y=y, label=id), size=3, colour="white", inherit.aes = FALSE)
plot(cartogram_density)
ggsave(cartogram_density, filename = "density_brewery_cartogram.jpeg")


##### regular map

# statemap <- readOGR("statesp020_nt00032/statesp020.shp")
#
# statemap@data <- statemap@data %>%
#     left_join(states, c("STATE_FIPS" = "FIPS"))
# #plot(statemap)
#
# statemap@data$id = rownames(statemap@data)
# statemap.points = fortify(statemap, region="id")
# statemap.df <- inner_join(statemap.points, statemap@data, by="id")
# statemap_centers <- cbind.data.frame(data.frame(gCentroid(statemap, byid=TRUE), id=statemap@data$Abbreviation))
#
# statemap.df <- statemap.df %>%
#     select(-ends_with("_ADM")) %>%
#     select(-c(hole, state)) %>%
#     filter(STATE!="Puerto Rico" & STATE!="U.S. Virgin Islands")
#
# statemap_density <- ggplot(data=statemap.df, aes(long,lat,group=group, fill = breweries_per_100k)) +
#     geom_polygon() +
#     geom_path(color="white") +
#     coord_equal() +
#     theme_void() +
#     labs(title="Brewery Density by State") +
#     scale_fill_continuous(trans = 'reverse') +
#     theme(legend.position="bottom", legend.title = element_text(size=10),
#           plot.title = element_text(hjust = 0.5)) +
#     guides(fill=guide_legend(title="Number of Breweries per 100,000 people",
#                              title.position="top")) +
#     geom_text(data=statemap_centers, aes(x=x, y=y, label=id), size=3, colour="white", inherit.aes = FALSE)
# plot(statemap_density)
# #ggsave(statemap_density, filename = "density_brewery_states.jpeg")


##### reshaped map

carto <- quick.carto(spdf=hexgrid, v=hexgrid@data$num_breweries, res=256, blur=0.5)
#plot(carto)
carto@data$id = rownames(carto@data)
carto.points = fortify(carto, region="id")
carto.df <- inner_join(carto.points, carto@data, by="id")
carto_centers <- cbind.data.frame(data.frame(gCentroid(carto, byid=TRUE), id=carto@data$iso3166_2))

big_states <- states %>%
    filter(num_breweries >=100) %>%
    mutate(id=Abbreviation) %>%
    inner_join(carto_centers, c("id"="id")) %>%
    select(id, x, y)

reshaped_carto_num <- ggplot(data=carto.df, aes(long,lat,group=group, fill = num_breweries)) +
    geom_polygon() +
    geom_path(color="white") +
    coord_equal() +
    theme_void() +
    labs(x=NULL, y=NULL) +
    labs(title="Number of Breweries by State (Adjusted)") +
    scale_fill_continuous(trans = 'reverse') +
    theme(legend.position="bottom", legend.title = element_text(size=10),
          plot.title = element_text(hjust = 0.5)) +
    guides(fill=guide_legend(title="Number of Breweries")) +
    geom_text(data=big_states, aes(x=x, y=y, label=id), size=3, colour="white", inherit.aes = FALSE)
plot(reshaped_carto_num)
ggsave(reshaped_carto_num, file="reshaped_carto_num.jpeg")

##### ratings
load("ratings.rdata")

# calculate average and top score by brewery
ratings <- ratings %>%
    filter(!is.na(rating_score)) %>%
    group_by(brewery_name) %>%
    mutate(brewery_avg = mean(rating_score), brewery_top = max(rating_score), brewery_num_beers = n()) %>%
    ungroup() %>%
    distinct(brewery_name, brewery_state, brewery_avg, brewery_top, brewery_num_beers)

# calculate average and top score by state
ratings <- ratings %>%
    group_by(brewery_state) %>%
    mutate(state_avg = mean(brewery_avg), state_top = max(brewery_top), state_num = n(), state_beers = sum(brewery_num_beers),
           state_brew_avg_min = min(brewery_avg), state_brew_avg_max = max(brewery_avg),
           state_total = sum(brewery_avg)) %>%
    ungroup() %>%
    arrange(brewery_state,brewery_name)

state_ratings <- ratings %>%
    select(brewery_state, starts_with("state_")) %>%
    distinct() %>%
    arrange(brewery_state)

rating_table <- state_ratings %>%
    mutate(state_avg = round(state_avg,1), state_top = round(state_top,1),
           state_brew_avg_min = round(state_brew_avg_min,1),
           state_brew_avg_max = round(state_brew_avg_max,1)) %>%
    select(-state_total) %>%
    arrange(desc(state_avg), desc(state_top), desc(state_brew_avg_max)) %>%
    rename(State=brewery_state, "Avg. Rating"=state_avg, "Top Rating"=state_top, "Num. Breweries"=state_num,
           "Num. Beers"=state_beers, "Min. Brewery Avg."=state_brew_avg_min, "Max Brewery Avg."=state_brew_avg_max) %>%
    kable(escape = F, align="lcccccc") %>%
    kable_styling(bootstrap_options = "condensed", full_width = F, position="left")
print(rating_table)

# maps
hexgrid.df <- hexgrid.df %>%
    left_join(state_ratings, c("iso3166_2" = "brewery_state"))

cartogram_rating <- ggplot(data=hexgrid.df, aes(long,lat,group=group, fill = state_avg)) +
    geom_polygon() +
    geom_path(color="white") +
    coord_equal() +
    theme_void() +
    labs(x=NULL, y=NULL) +
    labs(title="My Average Brewery Rating by State") +
    scale_fill_continuous(trans = 'reverse') +
    theme(legend.position="bottom", legend.title = element_text(size=10),
          plot.title = element_text(hjust = 0.5)) +
    guides(fill=guide_legend(title="Average Brewery Rating (out of 5)",
                             title.position="top")) +
    scale_fill_gradient(low="green", high="darkgreen") +
    geom_text(data=hexgrid_centers, aes(x=x, y=y, label=id), size=3, colour="white", inherit.aes = FALSE)
plot(cartogram_rating)
ggsave(cartogram_rating, filename = "cartogram_rating.jpeg")

### reshaped

hexgrid@data <- hexgrid@data %>%
    left_join(state_ratings, c("iso3166_2" = "brewery_state"))

carto_rating <- quick.carto(spdf=hexgrid, v=hexgrid@data$state_total, res=256, blur=0.5)
carto_rating@data$id = rownames(carto_rating@data)
carto_rating.points = fortify(carto_rating, region="id")
carto_rating.df <- inner_join(carto_rating.points, carto_rating@data, by="id")
carto_rating_centers <- cbind.data.frame(data.frame(gCentroid(carto_rating, byid=TRUE), id=carto_rating@data$iso3166_2))

reshaped_carto_rating <- ggplot(data=carto_rating.df, aes(long,lat,group=group, fill = state_total)) +
    geom_polygon() +
    geom_path(color="white") +
    coord_equal() +
    theme_void() +
    labs(x=NULL, y=NULL) +
    labs(title="My Total Brewery Ratings by State") +
    scale_fill_continuous(trans = 'reverse') +
    theme(legend.position="bottom", legend.title = element_text(size=10),
          plot.title = element_text(hjust = 0.5)) +
    guides(fill=guide_legend(title="Total State Rating",
                             title.position="top")) +
    scale_fill_gradient(low="green", high="darkgreen") +
    geom_text(data=carto_rating_centers, aes(x=x, y=y, label=id), size=3, colour="white", inherit.aes = FALSE)
plot(reshaped_carto_rating)
ggsave(reshaped_carto_rating, filename = "reshaped_carto_rating.jpeg")


##### save results for blog post

graphs <- c(comb_table, num_vs_density, cartogram_num, cartogram_density, reshaped_carto_num,
            rating_table, cartogram_rating, reshaped_carto_rating)
save(comb_table, num_vs_density, cartogram_num, cartogram_density, reshaped_carto_num,
     rating_table, cartogram_rating, reshaped_carto_rating,
     file= "output.rdata")



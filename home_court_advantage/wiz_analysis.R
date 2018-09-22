# wiz_analysis.R
# Determine if home court advantage existed for Wizards in 16/17 season
# Jesse Zlotoff
# 8/7/18

##### load packages
library(reshape2)
library(tidyverse)
#library(ztable)
library(kableExtra)
library(broom)

##### load & recode data

# load
results <- read_csv("201617_wizards_results.csv")

# rename columns
results <- rename(results, game_number=G, date_string=Date, time=X3, at=X6, opponent=Opponent,
                  win_loss=X8, ot=X9, team_points=Tm, opponent_points=Opp, post_win=W, post_loss=L,
                  streak=Streak)

# drop empty columns
results <- results %>%
    select_if(~(is.character(.) & sum(is.na(.))!=length(.)) | !is.character(.))

# drop single value columns
results <- results %>%
    select_if(~!length(unique(.))==1)

# add binary variable for win, home game; string home game; point differential
results <- results %>%
    mutate(win_binary = win_loss=="W",
           home_game_binary = is.na(at),
           home_game = ifelse(home_game_binary==1,"Home","Away"),
           point_differential = team_points - opponent_points)

# relabel win_loss
results$win_loss <- ifelse(results$win_loss=="W","Win","Loss")

# save data
save(results, file="wiz_1617_clean.rdata")

##### simple analysis

attach(results)

# very basic tab
t <- table(win_loss,home_game)
t <- table(factor(win_loss, levels = c("Win","Loss")),
           factor(home_game, levels = c("Home","Away")))
print(t)

# with percent
ptab <- round( prop.table(t,2), 2)
print(ptab)

# calculate chi sq
chi2 <- chisq.test(t)
print(chi2)
print(chi2$p.value)


##### pretty table
cnt <- results %>%
    group_by(win_loss) %>%
    count(home_game_binary) %>%
    spread(home_game_binary,n)
cnt <- rename(cnt, home_n=`TRUE`, away_n=`FALSE`) %>%
    arrange(desc(win_loss)) %>%
    select(win_loss,home_n,away_n)

pct <- results %>%
    group_by(win_loss) %>%
    count(home_game_binary) %>%
    group_by(home_game_binary) %>%
    mutate(freq = round(100 * n/sum(n)),1) %>%
    select(-n) %>%
    spread(home_game_binary,freq)
pct <- rename(pct, home_p=`TRUE`, away_p=`FALSE`) %>%
    arrange(desc(win_loss)) %>%
    select(win_loss, home_p, away_p)

table <- cnt %>%
    left_join(pct, by="win_loss")
table <- table %>%
    select(win_loss, home_n, home_p, everything())
table <- rename(table, Result=win_loss, "Home Games"=home_n, "Home Pct"=home_p, "Away Games"=away_n, "Away Pct"=away_p)

# wiz_summary <- ztable(as.data.frame(table))
# cgroup=c(NA,"Home","Away")
# n.cgroup=c(1,2,2)
# wiz_summary <- addcgroup(wiz_summary, cgroup=cgroup, n.cgroup=n.cgroup)
# wiz_summary <- update_ztable(wiz_summary, include.rownames=FALSE, digits=0, caption="Wizards 2016-2017 Season", align="llcccc")
# wiz_summary <- wiz_summary %>%
#     addCellColor(rows=2,cols=c(4,6), "grannysmithapple")
# print(wiz_summary)

# reproduce table with kable/kableExtra for use in markdown
df <- as.data.frame(table)
wiz_summary_k <- df %>%
    mutate(
        `Home Pct` = cell_spec(`Home Pct`, background = ifelse(df$Result=="Win","#9BF56E","white"), background_as_tile = FALSE),
        `Away Pct` = cell_spec(`Away Pct`, background = ifelse(df$Result=="Win","#9BF56E","white"), background_as_tile = FALSE)
    ) %>%
    kable(escape = F, align="c") %>%
    add_header_above(c(" " = 1, "Home" = 2, "Away" = 2)) %>%
    kable_styling(bootstrap_options = "condensed", full_width = F, position="left")
    # footnote(general="2016-2017 season",
    #          footnote_as_chunk = T,
    #          general_title = "*")
print(wiz_summary_k)

##### prep all-team data for regression

# load and filter to important columns
standings <- read_csv("expanded_standings.csv")
standings <- standings %>%
    select(Team, Overall)

# calculate win pct
standings <- extract(standings, Overall, c("wins","losses"), "^(\\d+)\\-(\\d+)", remove=FALSE)
standings$wins <- as.numeric(standings$wins)
standings$losses <- as.numeric(standings$losses)
standings <- standings %>%
    mutate(win_pct = wins/82)
standings <- select(standings, -Overall)

save(standings, file="team_standings_1617.rdata")


##### merge wiz results and standings data
results <- results %>%
    left_join(standings, by=c("opponent" = "Team"))
results <- rename(results, opp_win_pct = win_pct)

##### run regression

# all teams regr
logit <- glm(win_binary ~ home_game_binary + opp_win_pct + game_number, data=results, family=binomial(link = "logit"))
logit_c <- coef(logit)

# format table
# regr_output_all <- ztable(logit)
# regr_output_all$x <- regr_output_all$x %>%
#     select(-c(OR,lcl,ucl))
# regr_output_all <- regr_output_all %>%
#     addRowColor(rows=c(3,4), color="grannysmithapple")
# print(regr_output_all)

regr_output_all_k <- tidy(logit) %>%
    rename(Estimate = estimate, "Std Error"=std.error, "Z Value"=statistic, "P Value"=p.value) %>%
    kable(escape = F, align="c", digits=3) %>%
    kable_styling(bootstrap_options = "condensed", full_width = F, position="left") %>%
    row_spec(2:3, background="yellow")
print(regr_output_all_k)

results$yhat <- predict(logit, results, type="response")

# save data
save(results, file="wiz_1617_clean.rdata")


##### pretty charts

# compare winpct by opp_pct for home/away
by_opp_pct <- results %>%
    mutate(opp_win_cat = cut(opp_win_pct, breaks = seq(0, 1, by=0.2))) %>%
    group_by(opp_win_cat, home_game) %>%
    summarise(n = n(),
              win_num = sum(as.integer(win_binary))  ) %>%
    mutate(win_pct = win_num / n )
by_opp_pct <- by_opp_pct %>%
    arrange(opp_win_cat, desc(home_game))
by_opp_pct$home_game <- factor(by_opp_pct$home_game, levels=c("Home", "Away"))

wiz_bars <- by_opp_pct %>%
    filter(n >= 3) %>%
    ggplot() +
    geom_bar(mapping = aes(x = opp_win_cat, y=win_pct, fill = home_game), stat = "identity", position = "dodge")
wiz_bars <- wiz_bars + labs(x="Opponent Win Percent (Bin)", y="Win Percent", fill="Home/Away")
wiz_bars <- wiz_bars + labs(title="Wizards Wins Home & Away", subtitle="Win Percent by Opponent Win Percent for Home/Away")
wiz_bars <- wiz_bars + theme_classic() +
    theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
          plot.caption = element_text(hjust = 1, size = 8))
print(wiz_bars)

#ggsave("wizards_bars.jpeg", wiz_g)


# regression trends
trend_data <- data.frame(opp_win_pct = seq(0, 1, by=0.05))
trend_data <- trend_data %>%
    uncount(82, .id = "game_number") %>%
    uncount(2, .id = "id")
trend_data$home_game_binary <- trend_data$id==1
trend_data$yhat <- predict(logit, trend_data, type="response")
trend_data <- trend_data %>%
    select(-c(game_number, id)) %>%
    mutate(home_game = ifelse(home_game_binary==1,"Home","Away")) %>%
    group_by(opp_win_pct, home_game) %>%
    mutate(yhat_a = mean(yhat)) %>%
    distinct(opp_win_pct, home_game, yhat_a)
trend_data$home_game <- factor(trend_data$home_game, levels = c("Home", "Away"))

wiz_trend <- ggplot(data = trend_data, aes(x=opp_win_pct, y=yhat_a, group = home_game, colour = home_game)) +
    geom_line()
wiz_trend <- wiz_trend + labs(x="Opponent Win Percent", y="Predicted Win Percent", colour="Home/Away")
wiz_trend <- wiz_trend + labs(title="Predicted Wizards Wins Home & Away")
wiz_trend <- wiz_trend + theme_classic() +
    theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust = 0.5),
          plot.caption = element_text(hjust = 1, size = 8))

print(wiz_trend)
#ggsave("wizards_trend.jpeg", wiz_trend)

# predicted win_percent table by opponent
trend_table_data <- results %>%
    arrange(opponent, home_game) %>%
    distinct(opponent, opp_win_pct, home_game, yhat) %>%
    group_by(opponent, opp_win_pct, home_game) %>%
    mutate(predicted = mean(yhat)) %>%
    distinct(opponent, opp_win_pct, home_game, predicted)

trend_table_data <- trend_table_data %>%
    group_by(opponent, opp_win_pct, home_game) %>%
    mutate(i = row_number()) %>%
    spread(home_game, predicted) %>%
    arrange(desc(opp_win_pct), opponent) %>%
    select(opponent, opp_win_pct, Home, Away) %>%
    rename(Opponent = opponent, "Opponent Win Percent" = opp_win_pct,
           "Predicted Chance of Home Win" = Home, "Predicted Chance of Away Win" = Away)
#wiz_predicted <- ztable(as.data.frame(trend_table_data))
#wiz_predicted <- update_ztable(wiz_predicted, include.rownames = FALSE, digits=2, caption="Wizards 2016-2017 Season Predicted")
#print(wiz_predicted)

# ungroup so we can mutate data in groupby columns; add home-away net
temp <- trend_table_data %>%
    mutate(n=n()) %>%
    ungroup() %>%
    select(-n) %>%
    mutate(`Home vs Away Difference` = `Predicted Chance of Home Win` - `Predicted Chance of Away Win`)

# format kable
wiz_predicted_k <- temp %>%
    mutate(
        `Opponent Win Percent` = cell_spec(paste(as.character(round(`Opponent Win Percent`, digits=2) * 100), "%")),
        `Predicted Chance of Home Win` = cell_spec(paste(as.character(round(`Predicted Chance of Home Win`, digits=2) * 100), "%")),
        `Predicted Chance of Away Win` = cell_spec(paste(as.character(round(`Predicted Chance of Away Win`, digits=2) * 100), "%")),
        `Home vs Away Difference` = cell_spec(paste(as.character(round(`Home vs Away Difference`, digits=2) * 100), "%"),
                background=ifelse(`Home vs Away Difference` >= 0.3, "#9BF56E", "white"))
    ) %>%
    kable(escape = F, align="c", digits=3) %>%
    kable_styling(bootstrap_options = "condensed", full_width = F, position = "left")
wiz_predicted_k


##### save analysis results

save(wiz_summary_k, wiz_bars, wiz_trend, wiz_predicted_k, regr_output_all_k, chi2, t, file="analysis_results.rdata")


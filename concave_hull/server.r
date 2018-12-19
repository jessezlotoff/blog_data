###
# Purpose: code and server side of shiny app for concave hull
# Author(s): Jesse Zlotoff
# Modified: 12/19/18
###

library(tidyverse)
library(shiny)

#####

build_point_set <- function(num_points, max_num=10) {
    # build random set of points

    x <- runif(num_points, max= max_num)
    y <- runif(num_points, max= max_num)
    points <- as.tibble(x) %>%
        cbind(y) %>%
        rename(x = value) %>%
        mutate(hull_num = 0,
               hull = 0)
    return(points)
}


#####

find_leftmost <- function(df) {
    # find left-most point in x,y dataframe

    lpt <- df %>%
        mutate(mx = min(x)) %>%
        filter(x == mx) %>%
        select(x, y) %>%
        filter(row_number()==1)
    return(lpt)
}


#####

get_angle <- function(x1, y1, x2, y2, x3, y3, bc=NULL, lbc=NULL) {
    # get angle between three points

    ab <- c(x2-x1, y2-y1)
    if (is.null(bc)) {
        bc <- c(x3-x2, y3-y2)
    }
    ab_bc <- ab[1]*bc[1] + ab[2]*bc[2]
    lab <- sqrt(ab[1]^2 + ab[2]^2)
    if (is.null(lbc)) {
        lbc <- sqrt(bc[1]^2 + bc[2]^2)
    }
    ang <- acos(ab_bc / (lab * lbc))
    ang <- (180 * ang) / pi # convert from radians to degrees
    return(ang)

}


#####

get_next_point <- function(df, x2, y2, x3=x2, y3=-10) {
    # find next point in hull and flag it in the df

    next_num <- max(df$hull_num) + 1
    next_pt <- df %>%
        filter(hull_num <= 1) %>%
        mutate(angle = mapply(get_angle, x, y, x2, y2, x3, y3),
               min_ang = min(angle, na.rm=TRUE)
         ) %>%
        filter(angle == min_ang)
    df <- df %>%
        mutate(hull_num = ifelse(x==next_pt$x & y==next_pt$y & next_pt$hull_num!=1, next_num, hull_num),
               complete = next_pt$hull_num==1)
    return(df)
}


#####

get_cur_points <- function(df) {
    # pull out the last point(s) added

    cur_num <- max(df$hull_num)
    if (cur_num==1) {
        temp <- df %>%
            filter(hull_num==cur_num) %>%
            select(x, y)
        res <- list("x2"=temp$x, "y2"=temp$y, "x3"=temp$x, "y3"=-10)
    } else {
        temp <- df %>%
            filter(hull_num==cur_num | hull_num==cur_num-1) %>%
            arrange(hull_num) %>%
            select(x, y)
        res <- list("x2"=temp$x[2], "y2"=temp$y[2], "x3"=temp$x[1], "y3"=temp$y[1])
    }
    return(res)
}


#####
build_chart <- function(df, line_color="orange") {

    color <- c("0" = "black", "1"=line_color)
    p <- df %>%
        ggplot() +
        geom_point(mapping = aes(x=x, y=y, color=as.factor(hull)), show.legend = FALSE) +
        labs(x = "", y="") +
        scale_color_manual(values= color)

    if (max(df$hull_num) > 1) {
        poly <- df %>%
            filter(hull==1) %>%
            arrange(hull_num)

        if (df$complete[1] == TRUE) {
            poly <- poly %>%
                bind_rows(poly %>% filter(hull_num==1))
        }
        p <- p + geom_path(poly, mapping = aes(x=x, y=y, color=as.factor(hull)), show.legend = FALSE)
    }
    return(p)
}


############

### shiny function
function(input, output, session) {

    output$plotted <- reactive({0})
    rv <- reactiveValues(pts=NULL, tnum=0)

    observe({
        shinyjs::toggleState("plot", !is.null(input$num_points) && input$num_points != "")
    })

    observeEvent(input$plot, { # plot button
        output$plotted <- reactive({1})
        rv$pts <- build_point_set(input$num_points)
        p <- build_chart(rv$pts)
        output$chart <- renderPlot(p)
        show("trace")
        show("chart")
    })

    observeEvent(input$reset, { # reset button
        output$plotted <- reactive({0})
        reset("chart")
        hide("chart")
        hide("trace")
        rv$pts <- NULL
        rv$tnum <- 0
        rv$complete <- FALSE
    })

    observeEvent(input$trace, { # trace button
        output$traced <- reactive({1})
        rv$tnum <- rv$tnum + 1
        if (rv$tnum == 1) {
            l <- find_leftmost(rv$pts)
            rv$pts <- rv$pts %>%
                mutate(hull_num = ifelse(x==l$x & y==l$y, 1, 0),
                       hull = ifelse(hull_num > 0, 1, 0)
                )
        } else {
            c <- get_cur_points(rv$pts)
            rv$pts <- rv$pts %>%
                get_next_point(c$x2, c$y2, x3=c$x3, y3=c$y3) %>%
                mutate(hull = ifelse(hull_num > 0, 1, 0))
        }
        p <- build_chart(rv$pts, line_color = input$color_choice)
        output$chart <- renderPlot(p)
    })

    outputOptions(output, "plotted", suspendWhenHidden = FALSE)


}

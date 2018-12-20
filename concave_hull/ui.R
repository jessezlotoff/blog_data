###
# Purpose: ui side of shiny app for concave hull
# Author(s): Jesse Zlotoff
# Modified: 12/19/18
###

library(shiny)
library(shinyjs)


fluidPage(
    useShinyjs(),  # Include shinyjs

    fluidRow(
        column(4,
           # inputs
               numericInput("num_points", "Number of Points", 15),
                selectInput("color_choice", "Select color", c("orange", "red", "green", "blue")),
                actionButton("plot", "Plot"),
            actionButton("reset", "Reset"),
          br(), br(),
           conditionalPanel(
              condition = "output.plotted == 1",
               actionButton("trace", "Trace")
          )
        ),

        column(8,
           # plot
               plotOutput("chart")
        ) # end column
    ), # end row 1
    fluidRow(
        column(12,
            div(style = "background-color:#E0E2DF",
                p(tags$b("Instructions")),
                p("Click 'Plot' to create and show a random group of points.  Click 'Trace' to highlight the left-most point, and then continue clicking the button to draw the concave hull.  The plot can handle numbers between 1 and 5,000.")
            )
        )
    )
)



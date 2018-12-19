### ui portion of q_library shiny app
# Jesse Zlotoff
# 12/11/18

library(shiny)
library(shinyjs)


fluidPage(
    useShinyjs(),  # Include shinyjs

    fluidRow(
        column(4,
            div(style="height:220px",
            # search form
            textInput("search_text", "Question Search", placeholder = "Enter text"),
            checkboxInput("search_cat", "Include category labels"),
            checkboxInput("search_case", "Match case"),
            actionButton("search_button", "Submit"),
            actionButton("reset", "Reset"),
            br(), br(),
                div(style="font-size:12px",
                    p(em("Data from Pew Research Center American Trends Panel, January-April 2017"))
                )
            )
        ),

        column(8,
           style = "height:220px; overflow-y:scroll; position:relative;",
           # search results
           conditionalPanel(
               condition = "output.search_run == 1",
               uiOutput("search_result_radio")
           )
        ) # end column
    ), # end row 1
    hr(),

    fluidRow(
        column(12,
           div(style = "background-color:#E0E2DF",
               conditionalPanel(
                   condition = "output.search_run == 1",
                   htmlOutput("q_info")
               )
           )
       )
    ), # end row 2
    hr(),
    fluidRow(
        column(2,
           conditionalPanel(
               condition = "output.num_waves > 1",
               uiOutput("wave_radio")
           )
        ),
        column(5,
               conditionalPanel(
                   condition = "output.search_run == 1",
                   htmlOutput("prev_q")
               )
        ),
        column(5,
               conditionalPanel(
                   condition = "output.search_run == 1",
                   htmlOutput("next_q")
               )
        )
   )
)
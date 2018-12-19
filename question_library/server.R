### server portion of q_library shiny app
# Jesse Zlotoff
# 12/11/18

library(tidyverse)
library(shiny)

load("meta_ts.rdata")

### format date
format_date <- function(date) {
    yr <- substr(date,3,4)
    mo <- sub("^0?(.*)","\\1",substr(date,5,6))
    dy <- sub("^0?(.*)","\\1",substr(date,7,8))
    lab <- paste(c(mo, dy, yr), collapse="/")
    return(lab)
}

### build formatted list from vector of dates
# convert vector of dates to list of dates with clean labels
format_wave_dates <- function(dates) {
    labels <- c()
    for (d in dates) {
        labels <- append(labels, format_date(d))
    }
    dlist <- as.list(setNames(dates, labels))
    return(dlist)
}


### output q text and meta info for a given var_name
    # q_label, punches or numeric min/max, num waves, earliest/latest wave dates
output_q <- function(metadata, variable) {

    ts <- metadata %>%
        ungroup() %>%
        filter(var_name == variable)
    ts_single <- ts %>%
        filter(row_number()==1)

    # q-text
    q_lab <- ts_single %>%
        select(var_label) %>%
        paste()

    # punches
    punches <- ts_single %>%
        select(starts_with("P")) %>%
        gather(key = punch_number, value = category) %>%
        drop_na() %>%
        mutate(numeric = grepl("^\\d\\.?\\d*$", category)) %>%
        select(-punch_number)
    count_cat <- punches %>%
        filter(numeric==FALSE) %>%
        nrow()
    count_num <- nrow(punches) - count_cat
    if (count_num >= 7 & punches$numeric[1]==TRUE) { # pseudo-numeric
        num_p <- punches %>%
            filter(numeric==TRUE) %>%
            mutate(category = as.numeric(category)) %>%
            summarise(min=min(category),
                      max=max(category))
        p_lab <- paste0("[numeric: min=", num_p$min, " max=", num_p$max, "]")

        if (count_cat > 0) { # categoricals as well
            temp <- punches %>%
                filter(numeric==FALSE) %>%
                select(category)
            temp_lab <- paste(temp$category, collapse = "<br/>")
            p_lab <- paste(c(p_lab, temp_lab), collapse="<br/>")
        }
        p_cat <- c()
    } else { # not a pseudo-numeric
        temp <- punches %>%
            select(category)
        p_cat <- temp$category
        p_lab <- paste(temp$category, collapse = "<br/>")
    }

    # waves
    if (ts_single$num_waves == 1) {
        w_lab <- paste0("(Asked in 1 wave: ", format_date(ts_single$date), ")")
        w_cat <- c(ts_single$date)
    } else {
        w_cat <- ts$date
        w <- ts %>%
            select(date) %>%
            summarize(earliest=min(date), latest=max(date))
        w_lab <- paste0("(Asked in ", ts_single$num_waves, " waves: earliest=", format_date(w$earliest),
                        ", latest=", format_date(w$latest), ")")
    }

    # combined output
    output_text <- paste(c(q_lab, p_lab, w_lab), collapse = "<br/><br/>")
    output <- list("q_lab" = q_lab, "p_lab" = p_lab, "p_cat" = p_cat,
                   "w_lab" = w_lab, "w_cat" = w_cat, "output_text" = output_text,
                   "num_waves" = ts_single$num_waves)
    return(output)
}

### find prev/next question for a given q in a given wave
prev_next_q <- function(metadata, question, w_date) {

    cur_wave <- metadata %>%
        filter(date == w_date)
    cur_num <- cur_wave %>%
        filter(var_name == question)

    # find prev q
    if (cur_num$qnum <= 1) { #
        prev_q <- "No previous question found"
    } else {
        pq <- cur_wave %>%
            filter(qnum == cur_num$qnum - 1)
        prev_q <- pq$var_label %>%
            paste()
    }

    # find next q
    if (cur_num$qnum == 0) {
        next_q <- "No next question found"
    } else {
        nq <- cur_wave %>%
            filter(qnum == cur_num$qnum + 1)
        if (nrow(nq) == 0) {
            next_q <- "No next question found"
        } else {
            next_q <- nq$var_label %>%
                paste()
        }
    }

    prev_next = list("prev" = prev_q, "next" = next_q)
    return(prev_next)

}


### search
    # search q text and, optionally, punch text for a given string
    # returns list of lists: raw result labels w/ var_name keys, formatted result labels w/ var_name keys
search_q <- function(metadata, search_string, check_categories=FALSE, match_case=FALSE) {
    if (check_categories==FALSE) { # just check q text
        res <- metadata %>%
            filter(grepl(search_string, var_label, ignore.case = !match_case)) %>%
            select(var_name, var_label) %>%
            distinct()
    } else { # check cats too
        res <- metadata %>%
            unite(cats, P1:P10, sep=";") %>%
            mutate(cats = sub(";NA.*", "", cats),
                var_label = ifelse(qtype=="categorical", paste(var_label, "Categories: ", cats), var_label)) %>%
            filter(grepl(search_string, var_label, ignore.case = !match_case)) %>%
            select(var_name, var_label) %>%
            distinct()
    }

    if (nrow(res) > 0) { # results found
        raw <- as.list(setNames(res$var_name, res$var_label))
        frmt <- as.list(c())
    } else { # no res found
        raw <- as.list(c())
        frmt <- as.list(c())
    }

    result <- list("raw" = raw, "frmt" = frmt)
    return(result)
}


############

### shiny function
function(input, output, session) {

    output$search_run <- reactive({0})

    observe({
        shinyjs::toggleState("search_button", !is.null(input$search_text) && input$search_text != "")
    })

    observeEvent(input$search_button, {
        output$search_run = reactive({1})
        reset("search_result_radio")
        hide("q_info")
        reset("wave_radio")
        reset("search_cat")
        reset("search_case")
        hide("prev_q")
        hide("next_q")
        hide("wave_radio")
    })
    observeEvent(input$reset, { # reset button clicked
        output$search_run <- reactive({0})
        updateTextInput(session, "search_text", value="")
        reset("search_result_radio")
        hide("q_info")
        reset("wave_radio")
        hide("wave_radio")
        hide("prev_q")
        hide("next_q")
        reset("search_cat")
        reset("search_case")
        reset("prev_q")
        reset("next_q")
    })
    outputOptions(output, "search_run", suspendWhenHidden = FALSE)


    # search results
    results <- eventReactive(input$search_button, {
        search_q(meta_ts, input$search_text, check_categories = input$search_cat, match_case = input$search_case)
    })
    output$search_result_radio <- renderUI( {
        if (length(results()[["raw"]])>0) {
            radioButtons("q_selector", "Matching Question(s)", results()[["raw"]], selected=character(0), width='100%')
        } else {
            HTML({"No results found"})
        }
    })

    # turn on q_info after result q selected
    observe({
        if (!is.null(input$q_selector)) {
            show("q_info")
        }
    })

    # pull q meta info
    q_meta <- reactive( {
        validate(
            need(!is.null(input$q_selector), "Please select a question")
        )
        output_q(meta_ts, input$q_selector)
    })
    output$q_info <- renderUI(HTML(q_meta()[["output_text"]]))

    # turn on prev_next after result q selected
    observe({
        if (!is.null(input$q_selector)) {
            show("wave_radio")
            show("prev_q")
            show("next_q")
        }
    })

    # export num waves for conditional ui; radio buttons for waves
    output$num_waves <- reactive( {
        q_meta()[["num_waves"]]
    })
    output$wave_radio <- renderUI( {
        radioButtons('wrd', "Waves", format_wave_dates(rev(q_meta()[["w_cat"]])))
    })
    outputOptions(output, "num_waves", suspendWhenHidden = FALSE)

    # show prev/next q for given wave
    prev_next <- reactive( {
        if (q_meta()[["num_waves"]] > 1) {
            validate(
                need(input$wrd != "", "")
            )
            prev_next_q(meta_ts, input$q_selector, input$wrd)
        } else {
            prev_next_q(meta_ts, input$q_selector, q_meta()[["w_cat"]][1])
        }
    })
    output$prev_q <- renderUI(HTML({
        paste(c("<b>Previous question</b>",prev_next()[["prev"]]), collapse = "<br/>")
    }))
    output$next_q <- renderUI(HTML({
        paste(c("<b>Following question</b>",prev_next()[["next"]]), collapse = "<br/>")
    }))
}


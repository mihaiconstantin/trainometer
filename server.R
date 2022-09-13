# Server.
server <- function(input, output, session) {
    # Load data only once.
    data_raw <- reactive({
        # Load the data.
        data <- load_ns_data(input$data$datapath)

        # Get the range of the dates in the data.
        data_min <- min(data$date)
        data_max <- max(data$date)

        # Update the date input based on dates range.
        updateDateRangeInput(session, "dates",
            label = paste("Date Range (updated from data)"),
            start = data_min,
            end = data_max,
            min = data_min - 1,
            max = data_max + 1
        )

        return(data)
    })


    # Filter the data.
    data_subset <- reactive({
        # Get a copy of the data to subset around.
        data <- data_raw()

        # Extract dates from input.
        date_start <- as.Date(input$dates[1], format = "%Y-%m-%d")
        date_end <- as.Date(input$dates[2], format = "%Y-%m-%d")

        # Extract days from input.
        days <- input$days

        subset <- data[with(data,
            date >= date_start &
            date <= date_end &
            grepl(input$departure, departure, ignore.case = TRUE, perl = TRUE) &
            grepl(input$destination, destination, ignore.case = TRUE, perl = TRUE) &
            day %in% days
        ), ]

        # Return the subset that will be stored in the environment.
        return(subset)
    })


    # Data aggregated by date.
    subset_by_date <- reactive({
        # Aggregated the subset data by date.
        data <- get_aggregated_by_travel_date(data_subset())

        # Return the data.
        return(data)
    })


    # Data aggregated by day.
    subset_by_day <- reactive({
        # Aggregated the subset data by day.
        data <- get_aggregated_by_day(data_subset())

        # Return the data.
        return(data)
    })


    # Render correct UI for the main table section.
    output$ui_table_main = renderUI({
        return(get_text_or_table(
            path = input$data$datapath,
            table_id = "table_main"
        ))
    })


    # Render correct UI for the days table section.
    output$ui_table_days = renderUI({
        return(get_text_or_table(
            path = input$data$datapath,
            table_id = "table_days"
        ))
    })


    # Render the main table.
    output$table_main = DT::renderDataTable({
        # If aggregated data is requested, display it as such.
        if (input$aggregate) {
            return(
                format_date_aggregated_data(subset_by_date())
            )
        }

        # Otherwise, just show the complete data.
        return(
            format_complete_data(data_subset())
        )
    }, rownames = FALSE)


    # Render the days table.
    output$table_days = DT::renderDataTable({
        # Return formatted data aggregated by day.
        return(
            format_day_aggregated_data(subset_by_day())
        )
    }, rownames = FALSE, options = week_days_table_options)


    # Render travel costs.
    output$travel_costs <- renderText({
        # If there is no data loaded, then return zero costs.
        if (is.null(input$data$datapath)) {
            return("0.00")
        }

        # Otherwise calculate the actual costs.
        costs <- sum(data_subset()$price)

        # Format the costs.
        costs <- format(round(costs, 2), nsmall = 2)

        return(costs)
    })

    # Download button.
    output$show_download_button <- reactive({
        # Indicate whether data has been uploaded or not.
        return(!is.null(input$data))
    })

    # Output options.
    # See this brilliant answer: https://stackoverflow.com/a/21535587/5252007.
    outputOptions(output, "show_download_button", suspendWhenHidden = FALSE)

    # Perform the download.
    output$download_table_main <- downloadHandler(
        filename = function() {
            # Create file name.
            paste("data-shiny-travel-", Sys.Date(), ".csv", sep = "")
        },
        content = function(file) {
            # Select the correct data.
            if (input$aggregate) {
                data <- subset_by_date()
            } else {
                data <- data_subset()
            }

            # Write the data to `csv``.
            write.csv(data, file, row.names = FALSE)
        }
    )
}

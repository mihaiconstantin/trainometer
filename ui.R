# HTML template.
ui <- htmlTemplate("www/index.html",

    # Input for loading the data.
    input_data = fileInput(inputId = "data", label = "NS '.csv' Dataset", width = "100%"),

    # Input for indicating the departure.
    input_departure = textInput(inputId = "departure", label = "Departure", value = "", width = "100%", placeholder = input_labels$location),

    # Input for indicating the destination.
    input_destination = textInput(inputId = "destination", label = "Destination", value = "", width = "100%", placeholder = input_labels$location),

    # Input for selecting the date range.
    input_dates = dateRangeInput(
        inputId = "dates",
        label = "Date Range",
        width = "100%",
        weekstart = 1,
        separator = "to"
    ),

    # Input for selecting the travel days.
    input_days = checkboxGroupInput(inputId = "days", label = NULL,
        c(
            "Monday" = "monday",
            "Tuesday" = "tuesday",
            "Wednesday" = "wednesday",
            "Thursday" = "thursday",
            "Friday" = "friday",
            "Saturday" = "saturday",
            "Sunday" = "sunday"
        ),
        selected = c(
            "monday", "tuesday", "wednesday", "thursday", "friday"
        ),
        inline = TRUE
    ),

    # Switch whether to aggregate the data.
    input_aggregate = shinyWidgets::switchInput(
        inputId = "aggregate",
        label = "Aggregate by travel date",
        size = "small",
        labelWidth = "100%",
        inline = TRUE
    ),

    # Output for the main table.
    output_ui_table_main = uiOutput("ui_table_main"),

    # Output for the days table.
    output_ui_table_days = uiOutput("ui_table_days"),

    # Output for travel costs `HTML`.
    output_travel_costs = textOutput("travel_costs", inline = TRUE),

    # Download buttons.
    link_download_table_main = downloadLink("download_table_main", "Download", class = "download-link btn-primary")
)

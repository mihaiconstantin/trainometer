# Load libraries.
library(shiny)
library(shinyWidgets)
library(DT)


# Constants.
week_days_table_options = list(
    # Disable sorting.
    ordering = FALSE,

    # Disable searching.
    searching = FALSE,

    # Disable pagination.
    paging = FALSE,

    # Disable additional info.
    info = FALSE
)


input_labels = list(
    location = "a regular expression (e.g., tilburg|utrecht)"
)


# Parse pricing data.
parse_price <- function(price) {
    # Remove the euro sign.
    price <- gsub("€", "", price)

    # Change decimal to dot.
    price <- gsub(",", ".", price)

    # Convert to numeric.
    price <- as.numeric(price)

    return(price)
}


# Format main data for table display.
format_complete_data <- function(data) {
    # Convert date to character.
    data$date <- as.character(data$date)

    # Adjust column names.
    colnames(data) <- c("Date", "Day", "Check In", "Check Out", "Departure", "Destination", "Product", "Transaction", "Price (€)")

    return(data)
}


# Format aggregated data by date for table display.
format_date_aggregated_data <- function(data) {
    # Convert date to character.
    data$date <- as.character(data$date)

    # Add column names.
    colnames(data) <- c("Date", "Day", "Costs (€)")

    return(data)
}


# Format aggregated data by day for table display.
format_day_aggregated_data <- function(data) {
    # Add column names.
    colnames(data) <- c("Day", "Transaction Count", "Costs (€)")

    return(data)
}


# Load NS data.
load_ns_data <- function(path) {
    # Read data.
    data <- read.csv(path)

    # Convert date.
    data$Datum <- as.Date(data$Datum, format = "%d-%m-%Y")

    # Convert pricing variables to numeric.
    data$Af <- parse_price(data$Af)
    data$Bij <- parse_price(data$Bij)

    # Mark missing times as NA.
    data$Check.in[data$Check.in == ""] <- NA
    data$Check.uit[data$Check.uit == ""] <- NA

    # Lowercase columns.
    data$Vertrek <- trimws(tolower(data$Vertrek))
    data$Bestemming <- trimws(tolower(data$Bestemming))
    data$Transactie <- trimws(tolower(data$Transactie))
    data$Product <- trimws(tolower(data$Product))

    # Remove redundant information from departure and destination variables.
    data$Vertrek <- sub("\\s\\(.*$", "", data$Vertrek)
    data$Bestemming <- sub("\\s\\(.*$", "", data$Bestemming)

    # Mark missing departure and destination.
    data$Vertrek[data$Vertrek == ""] <- "n/a"
    data$Bestemming[data$Bestemming == ""] <- "n/a"

    # Convert character variables to factors.
    data$Vertrek <- factor(data$Vertrek, exclude = "")
    data$Bestemming <- factor(data$Bestemming, exclude = "")
    data$Transactie <- factor(data$Transactie, exclude = "")
    data$Product <- factor(data$Product, exclude = "")

    # Create day ordered factor.
    day <- ordered(
        tolower(strftime(data$Datum, "%A")),
        levels = tolower(weekdays(ISOdate(1, 1, 1:7)))
    )

    # Retain only relevant columns.
    output <- data.frame(
        date = data$Datum,
        day = day,
        check_in = data$Check.in,
        check_out = data$Check.uit,
        departure = data$Vertrek,
        destination = data$Bestemming,
        product = data$Product,
        transaction = data$Transactie,
        price = data$Af
    )

    # Order data.
    output <- output[with(output, order(
        date, check_in, check_out
    )), ]

    return(output)
}


# Aggregate the data by travel date.
get_aggregated_by_travel_date <- function(data) {
    # Return empty data frame if the data has no rows.
    if (!nrow(data)) {
        return(data.frame(matrix(NA, 0, 3)))
    }

    # Get unique travel dates.
    unique_dates <- unique(data$date)

    # Create aggregation data frame.
    aggregation <- data.frame(
        # Store unique travel dates.
        date = unique_dates,

        # Create day ordered factor.
        day = ordered(
            tolower(strftime(unique_dates, "%A")),
            levels = tolower(weekdays(ISOdate(1, 1, 1:7)))
        ),

        # Store total price per date.
        costs = sapply(unique_dates, function(date) {
            sum(data$price[data$date == date])
        })
    )

    return(aggregation)
}


# Aggregate the data by week day.
get_aggregated_by_day <- function(data) {
    # Return empty data frame if the data has no rows.
    if (!nrow(data)) {
        return(data.frame(matrix(NA, 0, 3)))
    }

    # Get unique travel dates.
    unique_days <- unique(data$day)

    # Order the days based on the factor ordering.
    unique_days <- unique_days[order(unique_days)]

    # Create aggregation data frame.
    aggregation <- data.frame(
        # Store unique travel days.
        day = unique_days,

        # Store the number of transactions.
        transactions = as.numeric(table(data$day)[unique_days]),

        # Store total price per week day.
        costs = sapply(unique_days, function(day) {
            sum(data$price[data$day == day])
        })
    )

    return(aggregation)
}


# Return text or data table.
get_text_or_table <- function(path, table_id, text, ...) {
    # Add default text.
    if(missing(text)) {
        text <- "No mission has been started yet."
    }

    if(is.null(path)) {
        # Indicate no data is selected.
        return(text)
    } else {
        # Show data table.
        return(DT::dataTableOutput(outputId = table_id, width = "100%", ...))
    }
}

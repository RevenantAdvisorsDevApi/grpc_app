# Install quantmod if not already installed
if(!require(quantmod)) {
  install.packages("quantmod", repos = "https://cloud.r-project.org/")
  library(quantmod)
}

# List of 10 tickers (S&P 500)
tickers <- c("AAPL", "MSFT", "AMZN", "GOOG", "META",
             "TSLA", "NVDA", "JPM", "UNH", "HD")

# Create folder "hist" in project directory if it doesn't exist
if(!dir.exists("hist")) {
  dir.create("hist")
}

# Date range: last 5 years
start_date <- Sys.Date() - 5*365
end_date <- Sys.Date()

# Download historical data and save as CSV
for (ticker in tickers) {
  cat("Downloading", ticker, "...\n")
  tryCatch({
    stock_data <- getSymbols(Symbols = ticker,
                             src = "yahoo",
                             from = start_date,
                             to = end_date,
                             auto.assign = FALSE)
    
    # Extract adjusted close price
    df <- data.frame(Date = index(stock_data),
                     Price = as.numeric(Ad(stock_data)))
    
    # Save to CSV in hist folder
    write.csv(df, file = file.path("hist", paste0(ticker, ".csv")),
              row.names = FALSE)
    
    cat("Saved", ticker, "to hist folder.\n")
    
  }, error = function(e){
    cat("Error downloading", ticker, ":", e$message, "\n")
  })
}

cat("All done!\n")

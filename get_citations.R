install.packages("scholar")

library(scholar)
id <- "PuPa3ekAAAAJ"
pubs <- get_publications(id)

filename <- paste0("history/citations_", Sys.Date(), ".csv")
write.csv(pubs, filename, row.names = FALSE)

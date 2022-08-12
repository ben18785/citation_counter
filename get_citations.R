library(xml2)
library(rvest)
library(httr)
library(stringr)
library(dplyr)

# simplified version of functions from: https://github.com/jkeirstead/scholar
get_scholar_resp <- function(url, attempts_left = 5) {
  
  stopifnot(attempts_left > 0)
  
  resp <- httr::GET(url)
  
  # On a successful GET, return the response
  if (httr::status_code(resp) == 200) {
    resp
  } else if(httr::status_code(resp) == 429){
    stop("Response code 429. Google is rate limiting you for making too many requests too quickly.")
  } else if (attempts_left == 1) { # When attempts run out, stop with an error
    stop("Cannot connect to Google Scholar. Is the ID you provided correct?")
  } else { # Otherwise, sleep a second and try again
    Sys.sleep(1)
    get_scholar_resp(url, attempts_left - 1)
  }
}

get_publications <- function(id, sortby="citation") {
  
    site <- "https://scholar.google.com"
    if(sortby == "citation"){
      url_template <- paste0(site, "/citations?hl=en&user=%s&cstart=%d&pagesize=%d")
    }
      
    if(sortby == "year"){
      url_template <- paste0(site, "/citations?hl=en&user=%s&cstart=%d&pagesize=%d&sortby=pubdate")
    }
    
    cstart = 0
    cstop = Inf
    pagesize = 100
    url <- sprintf(url_template, id, cstart, pagesize)
    
    ## Load the page
    page <- get_scholar_resp(url) %>% read_html()
    cites <- page %>% html_nodes(xpath="//tr[@class='gsc_a_tr']")
    
    title <- cites %>% html_nodes(".gsc_a_at") %>% html_text()
    pubid <- cites %>% html_nodes(".gsc_a_at") %>%
      html_attr("href") %>% str_extract(":.*$") %>% str_sub(start=2)
    doc_id <- cites %>% html_nodes(".gsc_a_ac") %>% html_attr("href") %>%
      str_extract("cites=.*$") %>% str_sub(start=7)
    cited_by <- suppressWarnings(cites %>% html_nodes(".gsc_a_ac") %>%
                                   html_text() %>%
                                   as.numeric(.) %>% replace(is.na(.), 0))
    year <- cites %>% html_nodes(".gsc_a_y") %>% html_text() %>%
      as.numeric()
    authors <- cites %>% html_nodes("td .gs_gray") %>% html_text() %>%
      as.data.frame(stringsAsFactors=FALSE) %>%
      filter(row_number() %% 2 == 1)  %>% .[[1]]
    
    ## Get the more complicated parts
    details <- cites %>% html_nodes("td .gs_gray") %>% html_text() %>%
      as.data.frame(stringsAsFactors=FALSE) %>%
      filter(row_number() %% 2 == 0) %>% .[[1]]
    
    
    ## Clean up the journal titles (assume there are no numbers in
    ## the journal title)
    first_digit <- as.numeric(regexpr("[\\[\\(]?\\d", details)) - 1
    journal <- str_trim(str_sub(details, end=first_digit)) %>%
      str_replace(",$", "")
    
    ## Clean up the numbers part
    numbers <- str_sub(details, start=first_digit) %>%
      str_trim() %>% str_sub(end=-5) %>% str_trim() %>% str_replace(",$", "")
    
    ## Put it all together
    data <- data.frame(title=title,
                       author=authors,
                       journal=journal,
                       number=numbers,
                       cites=cited_by,
                       year=year,
                       cid=doc_id,
                       pubid=pubid)
    
    if (nrow(data) > 0 && nrow(data)==pagesize) {
      data <- rbind(data, get_publications(id, cstart=cstart+pagesize, pagesize=pagesize))
    }

  data
}

id <- "PuPa3ekAAAAJ"
pubs <- get_publications(id)

filename <- paste0("history/citations_", Sys.Date(), ".csv")
write.csv(pubs, filename, row.names = FALSE)


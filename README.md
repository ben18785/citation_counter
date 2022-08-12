# Google Scholar cron scraper using Github actions
A very self centred scraper of Google Scholar that returns publications (with citation counts) at daily intervals using Github actions to run a cron job. This repo takes and bastardises a few key functions from the [scholar](https://github.com/jkeirstead/scholar) repo.

If you want to change the id that is scraped, just replace the one in the `get_citations.R` file with another id. (You'll also need to change a few things relating to me in the Github workflows: i.e. my username and my email.)

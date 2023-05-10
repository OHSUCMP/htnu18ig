library(zoo)
library(dplyr)
library(readxl)
library(tidyr)
library(tidyverse)
library(lubridate)
library(xlsx)

# This script updates the CQL based on the Excel spreadsheet Cards.xlsx and the templates in the folder CQL_templates. After running, be sure to do a git diff on the cql files to manually 
# inspect the differences.
# There are things that are not currently automated:
# - "Suggestions" are complex and should be manually updated using the Excel spreadsheet as a guide
# - The CQL for the Adverse Events and Pharma workflows do not currently contain any links. If links are added to the spreadsheet, 
# the CQL template should be updated to accommodate this
# - This script does not update the CQL for the details of the "b" recommendations of the NonPharma workflow - this is the recommendation that
# gets served if the patient has set a goal but it is not yet time to update it. The details field of this recommendation contains special logic
# for displaying the Goal Summary back to the user, so this cannot currently be automated.
# - NonPharma links are not currently updated, because they are generally all the same regardless of logic. This can be done later if we find we need separate links.

p <- function(vec) {
  str_replace_all(paste0(vec[!is.na(vec)]), "\\s?\\[.*?\\]", "")
}

# Overwrite the template text with the blocks of text transformed from the Excel spreadsheet. Apostrophes need to be replaced again for some reason. One replacement alone does not work.
processTemplate <- function(cards, txt) {
  for (i in 1:nrow(cards)) {
    txt = str_replace_all(txt, paste0("\\{\\{", cards[i, "recommendation"], ".summary\\}\\}"), str_replace_all(as.character(cards[i, "summary"]), "'", "\\\\'"))
    txt = str_replace_all(txt, paste0("\\{\\{", cards[i, "recommendation"], ".detail\\}\\}"), str_replace_all(as.character(cards[i, "detail"]), "'", "\\\\'"))
    txt = str_replace_all(txt, paste0("\\{\\{", cards[i, "recommendation"], ".link\\}\\}"), str_replace_all(as.character(cards[i, "link"]), "'", "\\\\'"))
  }
  return(txt)
}

cards_file <- file.path("Cards_OHSU_20221128_Control.xlsx")

# Read the cards spreadsheet, selecting only the columns of interest
cards <- read_xlsx(cards_file, skip=2, col_names=c("recommendation", "na-1", "na-2", "na-3", "na-4", "summary", 
                                                   "patient_detail", "careteam_detail", "na-5", "na-6", "suggestion_type", 
                                                   "suggestion_label", "suggestion_references", "suggestion_actions", 
                                                   "content_needed", "link_label", "link_url", "na-7", "na-8", "token", 
                                                   "na-9", "na-10", "na-11", "na-12"))  %>% 
  select(-starts_with("na-"))
# Replace "na" recommendation numbers with the previous recommendation number. These are second lines (additional suggestions or links)
tmp <- na.locf(cards %>% select(recommendation))
# Filter out the recommendations we don't care about
valid_recommendations = c('1', '2', '3', '4', '5', '6', '13', '14a', '14b', 
                          '19a', '19b', '19c', '19d', '20a', '20b', '20c', '20d', '21a', '21b', '21c', '21d', 
                          '22a', '22b', '22c', '22d', '23a', '23b', '23c', '23d', '29', '32', '33', '34')
cards <- bind_cols(tmp, cards %>% select(-recommendation)) %>% filter(recommendation %in% valid_recommendations)

# There should be only one summary per recommendation
summary <- cards %>% group_by(recommendation) %>% summarise(summary = p(summary))
# There may not be a careTeam detail - leave out if that's the case
detail <- cards %>% mutate(careteam_detail = ifelse(is.na(careteam_detail), "", careteam_detail)) %>% 
  group_by(recommendation) %>% summarise(patient_detail = p(patient_detail), careteam_detail = p(careteam_detail)) %>% 
  mutate(detail = paste0("{{#patient}}", patient_detail, "{{/patient}}", ifelse(careteam_detail != "", paste0("{{#careTeam}}", careteam_detail, "{{/careTeam}}"), "")))

# There may be multiple links. Break links up by hard returns into separate rows
links <- cards %>% select("recommendation", "link_label", "link_url") %>% separate_rows(link_label, link_url, sep = "\n", convert = FALSE) %>% 
  mutate_all(na_if,"") %>% filter(!is.na(link_label) & !is.na(link_url))
# Rejoin as json array
links <- links %>% mutate(link=paste0('{"label":"', link_label, '", "url":"', link_url, '"}')) %>% group_by(recommendation) %>% 
  mutate(link = paste0(link, collapse = ",")) %>% select(recommendation, link) %>% distinct() %>% 
  mutate(link = paste0("[", link, "]"))

new_cards <- left_join(summary, left_join(detail, links))
# Escape the apostrophe's. For some reason we have to do this again in processTemplate
new_cards <- new_cards %>% mutate_all(list(~ str_replace_all(., "'", "\\\\'")))

# Hypertension
template <- file.path("CQL_templates", "Hypertension.txt")
cql <- file.path("../input/CQL/", "Hypertension.cql")
infile  <- readLines(template)
outfile <- processTemplate(new_cards, infile)
writeLines(outfile, con=cql)

# Monitoring
template <- file.path("CQL_templates", "Monitoring.txt")
cql <- file.path("../input/CQL/", "Monitoring.cql")
infile  <- readLines(template)
outfile <- processTemplate(new_cards, infile)
writeLines(outfile, con=cql)

# NonPharma
template <- file.path("CQL_templates", "NonPharmacologicIntervention.txt")
cql <- file.path("../input/CQL/", "NonPharmacologicIntervention.cql")
infile  <- readLines(template)
outfile <- processTemplate(new_cards, infile)
writeLines(outfile, con=cql)

# Pharma
template <- file.path("CQL_templates", "Pharma.txt")
cql <- file.path("../input/CQL/", "Pharma.cql")
infile  <- readLines(template)
outfile <- processTemplate(new_cards, infile)
writeLines(outfile, con=cql)

# HypertensiveEmergency
template <- file.path("CQL_templates", "HypertensiveEmergency.txt")
cql <- file.path("../input/CQL/", "HypertensiveEmergency.cql")
infile  <- readLines(template)
outfile <- processTemplate(new_cards, infile)
writeLines(outfile, con=cql)

# AdverseEvents
template <- file.path("CQL_templates", "AdverseEvents.txt")
cql <- file.path("../input/CQL/", "AdverseEvents.cql")
infile  <- readLines(template)
outfile <- processTemplate(new_cards, infile)
writeLines(outfile, con=cql)





## rendering naar een of meerdere van de onderstaande formats

# rm(list = ls())

require(rmarkdown)
require(bookdown)

# to preview a chapter, uncomment one of the lines and run.
# bookdown::preview_chapter("index.Rmd")
# bookdown::preview_chapter("10_meteorologieenklimaat.Rmd")
# bookdown::preview_chapter("060_Bathymetrie_en_morfodynamiek.Rmd")
# bookdown::preview_chapter("10_meteorologieenklimaat.Rmd")
# bookdown::preview_chapter("060_Bathymetrie_en_morfodynamiek.Rmd")
# bookdown::preview_chapter("20_waterkwaliteit.Rmd")
# bookdown::preview_chapter("30_zeehonden.Rmd")
# bookdown::preview_chapter("40_vogels.Rmd")
# bookdown::preview_chapter("70_waterkwantiteit.Rmd")

# knitr::clean_cache() # kan soms handig zijn

file.remove("_main.md")
file.remove("_main.Rmd")
# gitbook formatted html pages (gebruikt op testpagina)
bookdown::render_book("index.Rmd", output_format = NULL, 
                      new_session = F)
# "normal" pdf
# options(tinytex.verbose = FALSE) # change to TRUE for debugging
bookdown::render_book("index.Rmd", output_format = bookdown::pdf_book(latex_engine = "lualatex"),
                      new_session = T, clean_envir = T)

# Veel gemaakte fouten
# Figuurlabels (label in code block) mogen geen underscore (_) bevatten bij rendering naar pdf
# Dubbele labels mogen niet (door hele document, alle hoofdstukken)
# Tufte output laat maar 2 niveau's toe (chapters # en sections ##)
# When using leaflet, make sure cache is not activated
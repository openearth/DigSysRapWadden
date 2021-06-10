## rendering naar een of meerdere van de onderstaande formats

rm(list = ls())

require(rmarkdown)
require(bookdown)

# gitbook formatted html pages (gebruikt op testpagina)
bookdown::render_book("index.Rmd", output_format = NULL, 
                      new_session = T)

# "normal" pdf
# options(tinytex.verbose = FALSE) # change to TRUE for debugging
# bookdown::render_book("index.Rmd", output_format = bookdown::pdf_book(latex_engine = "xelatex"),
#                       new_session = T, clean_envir = T)

# Veel gemaakte fouten
# Figuurlabels (label in code block) mogen geen underscore (_) bevatten bij rendering naar pdf
# Dubbele labels mogen niet (door hele document, alle hoofdstukken)
# Tufte output laat maar 2 niveau's toe (chapters # en sections ##)
# 
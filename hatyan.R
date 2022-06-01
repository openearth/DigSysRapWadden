
# install.packages("reticulate")
Sys.which("python")
library(reticulate)
py_discover_config()
py_install("pandas")

# version <- "3.8.7"
# reticulate::install_python(version = version)

# virtualenv_create(
#   envname = "kenwaar"
# )
# 
# virtualenv_install(
#   envname = "kenwaar",
#   packages = list("numpy", "hatyan", "matplotlib==3.2.1")
# )
# 
# # virtualenv_install(
# #   envname = "kenwaar",
# #   packages = c("matplotlib==3.2")
# # )
# 
# use_virtualenv(virtualenv = "kenwaar")
# virtualenv_list()


#=== conda environments

require(reticulate)
conda_list()
conda_create(envname = "kenwaar_conda", packages = c("numpy", "matplotlib==3.2.1"))
use_condaenv("kenwaar_conda")
py_install("hatyan", pip = T)
reticulate::py_run_file("hatyanExample.py")


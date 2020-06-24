library(ggsci)
library(rpart.plot)

path_of_code <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(path_of_code)

source("classification_procedure.R")

pode3 <- load_data("PODE3")
d <- dissim(pode3)
process <- best_clustering(pode3, d, "PODE3", 20)
test <- process[[1]]
test_tree <- process[[2]]
rpart.plot(test_tree)

ggplot(test) + geom_point(aes(x = log(TPA_PODE3), y = log(BA_PODE3), color = as.factor(cluster))) + scale_color_jco() + theme_light()

#there is clearly an issue - sometimes, a cluster will be too insignificant to be picked out by the decision tree. In this case, what should we do?

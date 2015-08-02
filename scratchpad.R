library(visNetwork)
library(RNeo4j)
library(dplyr)
source("helpers.R")

cypher_query <- "match (n:Person)-[r]-(m:Movie) return distinct n, r, m"
cypher_query <- "match (val:Person {name:\"Val Kilmer\"}), (rob:Person {name:\"Rob Reiner\"}), p=shortestPath((val)-[*..8]-(rob)) return p"
cypher_query <- "match (val:Person {name:\"Val Kilmer\"}), (rob:Person {name:\"Rob Reiner\"}), x=(val)-[*..5]-(rob) return x"
cypher_query <- "match ()-[r:DIRECTED]-() return distinct keys(r)"

c <- cypher(g, cypher_query)
props <- unlist(c[1,1])

data <- neo4jTovisNetwork(cypher_query)

nodes <- data$nodes
rels <- data$rels

visNetwork(nodes = nodes, edges = rels, width = "100%") %>% visGroups(groupname = "Person", shape = "icon", icon = list(code = "f007")) %>%
  visGroups(groupname = "Movie", shape = "icon", icon = list(code = "f008", color="red")) %>%
  addFontAwesome()








nodes <- data.frame(id = 1:10,                                # add labels on nodes
                    group = c("GrA", "GrB"),                  # control shape of nodes
                    title = paste0("<p><b>", 1:10,"</b><br>Node !</p>"))                  # shadow


edges <- data.frame(from = sample(1:10,100, replace=T), to = sample(1:10, 100, replace=T),
                    label = paste("Edge", 1:100),                                    # dashes
                    title = paste("Edge", 1:100))                       # shadow

visNetwork(nodes, edges, width = "100%") %>% visOptions(manipulation = TRUE)

nodes <- data.frame(id = 1:3, group = c("B", "A", "B"))
edges <- data.frame(from = c(1,2), to = c(2,3))

visNetwork(nodes, edges, width = "100%") %>%
  visGroups(groupname = "A", shape = "icon", icon = list(code = "f0c0", size = 75)) %>%
  visGroups(groupname = "B", shape = "icon", icon = list(code = "f007", color = "red")) %>%
  addFontAwesome()

g <- startGraph("http://localhost:7474/db/data/", "neo4j", "admin")

q <- "match (n) return distinct labels(n)"
q = "match (n:Person)-[r:ACTED_IN]->(m:Movie) where m.title= 'The Birdcage' return n"
df <- getNodes(g, q)

paste(1)
as.character(3)

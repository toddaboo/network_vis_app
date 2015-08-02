# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinyBS)
library(RNeo4j)
library(visNetwork)
source('helpers.R')

shinyServer(function(session, input, output) {

  g <- startGraph("http://localhost:7474/db/data/")
  
  data <- reactive({
    if(input$run == 0) return(NULL)
    isolate({
      withProgress(message = 'Pulling data...', value = 25, {
        neo4jTovisNetwork(g, input$query)
      })
    })
  })
  
  output$networkVis <- renderVisNetwork({
    if(input$run == 0) return(NULL)
    isolate({
      nodes <- data()$nodes
      rels <- data()$rels
      
      withProgress(message = 'Generating plot...', value = 50, {
        visNetwork(nodes, rels, width="100%") %>% 
          visOptions(highlightNearest = TRUE, clickToUse = TRUE) #%>% 
#           visGroups(groupname = "Person", shape = "icon", icon = list(code = "f007")) %>%
#           visGroups(groupname = "Movie", shape = "icon", icon = list(code = "f008", color="red")) %>%
#           addFontAwesome()
      })
    })
  })
  
})

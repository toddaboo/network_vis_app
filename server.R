# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinyBS)
library(sortableR)
library(RNeo4j)
library(visNetwork)
source('helpers.R')

shinyServer(function(session, input, output) {

  g <- startGraph("http://localhost:7474/db/data/")
  
  output$searchQuery <- renderUI({
    things <- getLabel(g)
    selectInput("search", "", selectize = T, choices = things)
  })
  
  qry <- reactive({
    gsub("&gt;", ">", input$cypher_query)
  })
  
  output$cypher <- renderText({
    qry()
  })
  
  output$things <- renderUI({
    things <- getLabel(g)
    bsCollapsePanel(title = "Things", style = "primary",
      div(class="panel-heading", id = "sortThings",
        lapply(things, function(x) list(div(tags$span( class = "glyphicon glyphicon-move" ), x)))
      )
      ,sortableR( "sortThings", options = list( group = "sortGroup1" ) )
    )
  })
  
  output$relationships <- renderUI({
    rels <- getType(g)
    bsCollapsePanel(title = "Relationships", style = "primary",
      div(class="panel-heading", id = "sortRels", 
        lapply(rels, function(x) list(div(tags$span( class = "glyphicon glyphicon-move" ), x)))
      )
      ,sortableR( "sortRels", options = list( group = "sortGroup1" ) )
    )
  })
  
  output$filters <- renderUI({
    bsCollapsePanel(title = "Filters", style = "primary",
      div(class="panel-body", id = "sortFilters"
              #, lapply(rels, function(x) list(tags$li(x, class="list-group-item")))
      )
      ,sortableR( "sortFilters", options = list( group = "sortGroup1" ) )
    )
  })
  
  data <- reactive({    
    validate(
      need(qry() != "", "Please enter a query."),
      need(try(cypher(g, qry()), silent=T), "Query invalid.")
    )
    
    withProgress(message = 'Pulling data...', value = 25, {
      neo4jTovisNetwork(g, qry())
    })
  })
  
  output$networkVis <- renderVisNetwork({
    validate(
      need(!is.null(data()), "Please enter a query.")
    )

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

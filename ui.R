
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinyBS)
library(shinydashboard)
library(sortableR)
source('helpers.R')

shinyUI(fluidPage(

  # Application title
  titlePanel("Network Viz!"),
  
  sidebarLayout(position='right', 
    sidebarPanel(
      fluidRow(column(12, submitButton("Run", icon=icon("play")), br())),
      fluidRow(
        #tags$textarea(id="query", rows=8, cols=40), 
        column(6, uiOutput("things")),
        column(6, uiOutput("relationships"))
      ),
      fluidRow(
        column(12, uiOutput("filters"))
      )
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Search Query", uiOutput("searchQuery")),
        tabPanel("Visual Query",
          column(4,
            div(class="panel panel-default",
                div(class="panel-heading", h6(strong("(Thing 1)"), " (drag here...)")),
                div(class="panel-body", id="sort3")
                ,sortableR( "sort3", options = list( group = "sortGroup1" ) )
            )
          ),
          column(4,
            div(class="panel panel-default",
                div(class="panel-heading", h6(strong("-[Relationship]->"), " (drag here...)")),
                div(class="panel-body", id="sort4")
                ,sortableR( "sort4", options = list( group = "sortGroup1" ) )
            )
          ),
          column(4,
            div(class="panel panel-default",
                div(class="panel-heading", h6(strong("(Thing 2)"), " (drag here...)")),
                div(class="panel-body", id="sort5")
                ,sortableR( "sort5", options = list( group = "sortGroup1" ) )
            )
          )
        )
      ),
      tags$script('
        $(document).ready(function() {
          $("button").click(function() {
            var thing1 = $("#sort3").text();
            if(thing1 != "") thing1 = ":" + thing1;
            var rel1 = $("#sort4").text();
            if(rel1 != "") rel1 = ":" + rel1;
            var thing2 = $("#sort5").text();
            if(thing2 != "") thing2 = ":" + thing2;
            var query = "match (thing1" + thing1 + ")-[r" + rel1 + "]->(thing2" + thing2 + ") return thing1, r, thing2";
            Shiny.onInputChange("cypher_query", query);
          });
        });
      '),
      
      fluidRow(
        column(12,
          verbatimTextOutput("cypher"),
          conditionalPanel("output.networkVis", "it may take a minute to load...when it does, click on the graph to explore"),
          visNetworkOutput("networkVis")
        )
      )
    )
  )

))

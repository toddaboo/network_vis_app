
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinyBS)
source('helpers.R')

shinyUI(fluidPage(

  # Application title
  titlePanel("Network Viz!"),
  
  sidebarLayout(
    sidebarPanel(
      tags$textarea(id="query", rows=8, cols=40), br(),
      submitButton("Run", icon=icon("play"))
    ),
    mainPanel(
      conditionalPanel("output.networkVis", "it may take a minute to load...when it does, click on the graph to explore"),
      visNetworkOutput("networkVis")
    )
  )

))

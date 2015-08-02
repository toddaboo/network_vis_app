# a function to pull the properties for a given node label or relationship type
getProp <- function() {
  
}

# a function to mod the existing bsModal function
shinyBSDep <- htmltools::htmlDependency("shinyBS", packageVersion("shinyBS"), src = c("href" = "sbs"), script = "shinyBS.js", stylesheet = "shinyBS.css")

bsModalMod<- function (id, title, trigger, ..., size) 
{
  if (!missing(size)) {
    if (size == "large") {
      size = "modal-lg"
    }
    else if (size == "small") {
      size = "modal-sm"
    }
    size <- paste("modal-dialog", size)
  }
  else {
    size <- "modal-dialog"
  }
  bsTag <- shiny::tags$div(class = "modal sbs-modal fade", 
             id = id, tabindex = "-1", `data-sbs-trigger` = trigger, 
             shiny::tags$div(class = size, shiny::tags$div(class = "modal-content", 
               shiny::tags$div(class = "modal-header", shiny::tags$button(type = "button",
                  class = "close", `data-dismiss` = "modal", shiny::tags$span(shiny::HTML("&times;"))), 
                    shiny::tags$h4(class = "modal-title", title)), 
               shiny::tags$div(class = "modal-body", list(...)), 
               shiny::tags$div(class = "modal-footer", shiny::actionButton("add", "Add", `data-dismiss` = "modal")))))
  htmltools::attachDependencies(bsTag, shinyBSDep)
}

# function to determine if a given list is a list of nodes
is.node <- function(list) {
  stopifnot(is.list(list))
  
  if(names(list[[1]][2]) == "outgoing_relationships") {
    return(TRUE)
  } else if(names(list[[1]][2]) == "start") {
    return(FALSE)
  } else {
    print("Sorry, I'm not sure what this is.")
  }
}

# function to determine if a given list is a list of relationships
is.rel <- function(list) {
  stopifnot(is.list(list))
  
  if(names(list[[1]][2]) == "outgoing_relationships") {
    return(FALSE)
  } else if(names(list[[1]][2]) == "start") {
    return(TRUE)
  } else {
    print("Sorry, I'm not sure what this is.")
  }
}

# a function to convert a list of nodes from RNeo4j format to visNetwork format
nodesToVisNetwork <- function(list) {
  stopifnot(is.node(list))
  if(!'dplyr' %in% row.names(installed.packages())) { stop("Need to install and/or load package 'dplyr'") }
  # convert column of data to a data frame of node data
  df <- as.data.frame(bind_rows(lapply(list, function(x) {
    if(length(x[c("data")]$data) > 0) { 
      d <- data.frame(x[c("metadata", "data")])
      if(length(names(d)[!(names(d) %in% c("metadata.id", "metadata.labels"))]) == 1) {
        names(d)[!(names(d) %in% c("metadata.id", "metadata.labels"))] <- paste0("data.", names(d)[!(names(d) %in% c("metadata.id", "metadata.labels"))])
      }
      if("data.data" %in% names(d)) { names(d)[names(d) == "data.data"] <- "data.name" }
      return(d)
    } else { 
      return(data.frame(x[c("metadata")]))
    }
  })))
  
  df %>%
    select(id=metadata.id, group=metadata.labels, starts_with("data.")) -> df
  
  properties <- gsub("^data.", "", names(select(df, starts_with("data."))))
  names(df) <- gsub("^data.", "", names(df))
  
  #----------------------------------------------------------------------
  # add in logic for determining which data field to use for the "label"
  #----------------------------------------------------------------------
  # for now, just use the node labels
  df$label <- df$group
  #---------------
  
  tooltip <- ""
  for(prop in properties) {
    tooltip <- paste0(tooltip, "<b>", prop, "</b>: ", df[,c(prop)], "<br />")
  }
  # clean up NAs
  splt <- strsplit(tooltip, "<br />")
  tooltip <- unlist(lapply(splt, function(x) paste(x[!grepl("NA", x)], collapse="<br />")))
  
  df$title <- tooltip
  df <- df[,c("id", "label", "group", "title")]
  
  # remove duplicates
  df %>% group_by(id) %>% filter(row_number() == 1) -> df
}

# a function to convert a list of relationships from RNeo4j format to visNetwork format
relsToVisNetwork <- function(list) {
  stopifnot(is.rel(list))
  if(!'dplyr' %in% row.names(installed.packages())) { stop("Need to install and/or load package 'dplyr'") }
  # convert column of data to a data frame of node data
  df <- as.data.frame(bind_rows(lapply(list, function(x) {
    if(length(x[c("data")]$data) > 0) { 
      d <- data.frame(x[c("start", "end", "metadata", "data")])
      if(length(names(d)[!(names(d) %in% c("start", "end", "metadata.id", "metadata.type"))]) == 1) {
        names(d)[!(names(d) %in% c("start", "end", "metadata.id", "metadata.type"))] <- paste0("data.", names(d)[!(names(d) %in% c("start", "end", "metadata.id", "metadata.type"))])
      }
      return(d)
    } else { 
      return(data.frame(x[c("start", "end", "metadata")]))
    }
  })))
  
  df %>% 
    select(from=start, to=end, label=metadata.type, starts_with("data.")) -> df
  
  # extract start ID and end ID
  df$from <- sub(".*db/data/node/", "", df$from)
  df$to <- sub(".*db/data/node/", "", df$to)
  
  properties <- gsub("^data.", "", names(select(df, starts_with("data."))))
  names(df) <- gsub("^data.", "", names(df))
  
  tooltip <- ""
  for(prop in properties) {
    tooltip <- paste0(tooltip, "<b>", prop, "</b>: ", df[,c(prop)], "<br />")
  }
  # clean up NAs
  splt <- strsplit(tooltip, "<br />")
  tooltip <- unlist(lapply(splt, function(x) paste(x[!grepl("NA", x)], collapse="<br />")))
  
  df$title <- tooltip
  
  df$arrows <- "to"
  df <- df[,c("from", "to", "label", "arrows", "title")]
}

# a function to run a cypher query, translate from RNeo4j output to visNetwork, and return formatted data
neo4jTovisNetwork <- function(graph, cypher_query) {
  raw <- cypher(graph, cypher_query)
  
  nodes <- data.frame(matrix(nrow=0, ncol=4))
  names(nodes) <- c("id", "label", "group", "title")
    
  rels <- data.frame(matrix(nrow=0, ncol=5))
  names(rels) <- c("from", "to", "label", "arrow", "title")
                     
  for(col in names(raw)) {
    if(is.node(raw[,c(col)])) {
      visNodes <- nodesToVisNetwork(raw[,c(col)])
      nodes <- rbind(nodes, visNodes)
    }
    
    if(is.rel(raw[,c(col)])) {
      visRels <- relsToVisNetwork(raw[,c(col)])
      rels <- rbind(rels, visRels)
    }
  }
  return(list(nodes=nodes, rels=rels))
}


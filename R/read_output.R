read_shapes <- function(x) {
  sf::st_read(x$args, quiet = TRUE)
}

read_table <- function(x) {
  if (tools::file_ext(x$args) == "txt") {
    object <- 
      utils::read.table(x$args, header = T, sep = "\t") %>%
      tibble::as_tibble()
    
  } else if (tools::file_ext(x$args) == "csv") {
    object <- 
      utils::read.csv(x$args) %>% 
      tibble::as_tibble()
    
  } else if (tools::file_ext(x$args) == "dbf") {
    object <- 
      foreign::read.dbf(x$args) %>%
      tibble::as_tibble()
  }
  
  object
}

read_grid <- function(x) {
  
  if (tools::file_ext(x$args) == "sg-gds-z") {
    warning(paste(
      "Cannot load SAGA Grid Collection as an R raster object",
      "- this is not currently supported"
    ))
  } else {
    object <- raster::raster(x$args)
  }
  
  object
}

read_grid_list <- function(x) {
  x$args <- strsplit(x$args, ";")[[1]]
  object <- lapply(x$args, raster::raster)
  names(object) <- paste(x$alias, seq_along(x$args), sep = "_")
  
  object
}

read_output <- function(output, .intern) {
  
  output$args <- gsub(".sgrd", ".sdat", output$args)

  if (isTRUE(.intern)) {
    
    object <- tryCatch(expr = {
      
      switch(
        output$feature,
        "Shape" = read_shapes(output),
        "Table" = read_table(output),
        "Grid" = read_grid(output),
        "Raster" = read_grid(output),
        "Grid list" = read_grid_list(output)
      )
      
    }, error = function(e) {
      message(
        paste(
          "No geoprocessing output for", output$alias,
          ". Results may require other input parameters to be specified"
          )
        )
      return(NULL)
    })
    
  } else {
    object <- output$args
  }
  
  object
}
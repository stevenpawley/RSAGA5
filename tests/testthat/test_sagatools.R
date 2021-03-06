library(Rsagacmd)
library(magrittr)
library(raster)

testthat::test_that("basic SAGA-GIS tool usage ", {
  testthat::skip_on_cran()

  if (!is.null(saga_search())) {
    saga <- saga_gis(all_outputs = FALSE)

    # test execution of a SAGA-GIS tool
    dem <- saga$grid_calculus$random_terrain(
      target_user_xmin = 0,
      target_user_xmax = 1000,
      target_user_ymin = 0,
      target_user_ymax = 1000,
      radius = 100,
      iterations = 500, 
      target_out_grid = tempfile(fileext = ".sgrd")
    )
    
    testthat::expect_is(dem, "RasterLayer")

    # table output
    orb <- saga$climate_tools$earths_orbital_parameters(orbpar = tempfile(fileext = ".csv"))
    testthat::expect_is(orb, "tbl_df")

    # optional outputs with conditions on inputs
    flowacc <- dem %>%
      saga$ta_preprocessor$sink_removal(dem_preproc = tempfile(fileext = ".sgrd")) %>%
      saga$ta_hydrology$flow_accumulation_top_down(flow = tempfile(fileext = ".sgrd"))
    
    testthat::expect_is(flowacc, "RasterLayer")

    # test loading simple features object and pipes
    dem_mean <- cellStats(dem, mean)
    
    shapes <- dem %>%
      saga$grid_calculus$grid_calculator(
        formula = gsub("z", dem_mean, "ifelse(g1>z,1,0)"), 
        result = tempfile(fileext = ".sgrd")
      ) %>%
      saga$shapes_grid$vectorising_grid_classes(polygons = tempfile(fileext = ".shp"))
    
    testthat::expect_is(shapes, "sf")
  }
})


testthat::test_that("handling of single and multiband rasters", {
  testthat::skip_on_cran()

  if (!is.null(saga_search())) {
    saga <- saga_gis()

    # generate a singleband raster
    rasterlayer_from_singleband <- saga$grid_calculus$random_terrain(
      target_user_xmin = 0,
      target_user_xmax = 1000,
      target_user_ymin = 0,
      target_user_ymax = 1000,
      radius = 100,
      iterations = 500
    )
    
    # create rasterbrick, rasterstacks, and layers from each
    rasterbrick <-
      writeRaster(
        stack(rasterlayer_from_singleband, rasterlayer_from_singleband),
        filename = tempfile(fileext = ".tif")
      )
    
    rasterstack <- stack(
      rasterlayer_from_singleband, 
      rasterlayer_from_singleband
      )
    
    rasterlayer_from_rasterbrick <- rasterbrick[[1]]
    rasterlayer_from_rasterstack <- rasterstack[[1]]

    # tests
    testthat::expect_is(
      saga$grid_filter$simple_filter(input = rasterlayer_from_singleband),
      "RasterLayer"
    )
    testthat::expect_is(
      saga$grid_filter$simple_filter(input = rasterlayer_from_rasterbrick),
      "RasterLayer"
    )
    testthat::expect_is(
      saga$grid_filter$simple_filter(input = rasterlayer_from_rasterstack),
      "RasterLayer"
    )
  }
})

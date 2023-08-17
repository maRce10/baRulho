test_that("using extended table and method 1", {
  data("degradation_est")
  
  X <- degradation_est[degradation_est$sound.files != "master.wav", ]

  br <- blur_ratio(X = X, method = 1)

  expect_equal(sum(is.na(br$blur.ratio)), 9)
  
  expect_equal(nrow(br), 25)
  
  expect_equal(ncol(br),11)
  
  expect_equal(class(br)[1], "extended_selection_table")
  
})

test_that("using data frame", {
  data("degradation_est")
  
  # set temporary directory
  td <- tempdir()  
  
  for (i in unique(degradation_est$sound.files)[-1])
    writeWave(object = attr(degradation_est, "wave.objects")[[i]], file.path(td, i))
  
  options(sound.files.path = td, pb = FALSE)
  
  X <- as.data.frame(degradation_est[degradation_est$sound.files != "master.wav", ])
  
  expect_warning(br <- blur_ratio(X = X, method = 2))
  
  expect_equal(sum(is.na(br$blur.ratio)), 13)
  
  expect_equal(nrow(br), 25)
  
  expect_equal(ncol(br), 11)
  
  expect_equal(class(br)[1], "data.frame")
  
})
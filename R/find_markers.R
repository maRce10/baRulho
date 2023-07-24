#' Find acoustic markers on test sound files
#' 
#' \code{find_markers} find acoustic markers on test (re-recorded) sound files using spectrographic cross-correlation.
#' @usage find_markers(X, template.rows = NULL, markers = c("start_marker", "end_marker"),
#' test.files = NULL, path = NULL, pb = TRUE, cores = 1,...)
#' @param X Object of class 'data.frame', 'selection_table' or 'extended_selection_table' (the last 2 classes are created by the function \code{\link[warbleR]{selection_table}} from the warbleR package) with the reference to the sounds in the master sound file. Must contain the following columns: 1) "sound.files": name of the .wav files, 2) "selec": unique selection identifier (within a sound file), 3) "start": start time, 4) "end": end time of selections and 5) "sound.id": unique identifier for each of the annotated sounds in 'X'. Columns for 'top.freq', 'bottom.freq' and 'channel' are optional. Required. 
#' @param template.rows Numeric vector with the index of the rows from 'X' to be used as templates. DEPRECATED.
#' @param markers Character vector with the name of the annotations (as in the column 'sound.id') to be used as templates for cross-correlation. Default is \code{c("start_marker", "end_marker")}. Using more than one template is recomended as the time difference between their position can be used to evaluate the precision of the detection (see 'Value' section).
#' @param test.files Character vector of length 1 with the name(s) of the test (re-recorded) file(s) in which to search for the template(s). If not supplied all sound files in 'path' are used instead.
#' @param path Character string containing the directory path where test (re-recorded) sound files are found.
#' @param pb Logical argument to control if progress bar is shown. Default is \code{TRUE}.
#' @param cores Numeric vector of length 1. Controls whether parallel computing is applied by specifying the number of cores to be used. Default is 1 (i.e. no parallel computing).
#' @param ...	Additional arguments to be passed to \code{\link[ohun]{template_correlator}} for setting cross-correlation parameters (e.g. 'wl', 'ovlp', etc).
#' @return A data frame with test file names, template name, maximum cross-correlation score for each tamplate and the start and end where it was detected. If two or more templates are used the function computes an additional column, 'time.match', that compares the time difference between the two templates in the test-files against that in the master sound file. In a perfect detection the value must be 0.
#' @export
#' @name find_markers
#' @details The function takes a master sound file's reference data ('X') and finds the position of acoustics templates ('templates' argument, included as selections in 'X') in the re-recorded sound files. This is used to align signals found in re-recorded sound files according to a master sound file referenced in 'X'. The position of the templates is determined as the highest spectrogram cross-correlation value for each template using the functions \code{\link[ohun]{template_correlator}} and \code{\link[ohun]{template_detector}}. \strong{Make sure the master sound file (that refered to in 'X') is found in the same folder than the re-recorded sound files}. Take a look at the package vignette for information on how to incorporate this function into a sound degradation analysis workflow.
#' @seealso \code{\link{spcc_align}}; \code{\link{align_test_files}}
#' @examples
#' \dontrun{
#' # use a temporary directory
#' td <- tempdir()  
#' 
#' # load example data from warbleR
#' data(list = c("Phae.long1", "Phae.long2", "lbh_selec_table"))
#' 
#' # save sound files to temporary folder
#' writeWave(Phae.long1, file.path(td, "Phae.long1.wav"))
#' writeWave(Phae.long2, file.path(td, "Phae.long2.wav"))
#' 
#' # make an extended selection table
#' est <- selection_table(X = lbh_selec_table, extended = TRUE, confirm.extended = FALSE, 
#' path = td, pb = FALSE)
#' 
#' # create master sound file
#' master.sf <- master_sound_file(X = est, file.name = "example_master", 
#' dest.path = td, gap.duration = 0.3)
#' 
#' # read master
#' exmp.master <- readWave(file.path(td, "example_master.wav"))
#' 
#' # add 1 s silence
#' exmp.test1 <- addsilw(wave = exmp.master, at = "start", d = 1,
#' output = "Wave", f = exmp.master@samp.rate)
#' 
#' exmp.test2 <- addsilw(wave = exmp.master, at = "start", d = 2, 
#' output = "Wave", f = exmp.master@samp.rate)
#' 
#' # create noise
#' ns <- noisew(f = exmp.master@samp.rate, d = duration(exmp.test2) + 1, 
#' output = "Wave")
#' 
#' # make noise exactly the same length and add noise to 2 examples
#' exmp.test1@left <- exmp.test1@left + (ns@left[1:length(exmp.test1@left)] * 500)
#' exmp.test2@left <- exmp.test2@left + (ns@left[1:length(exmp.test2@left)] * 500)
#' 
#' exmp.test1 <- tuneR::normalize(exmp.test1, unit = "16")
#' exmp.test2 <- tuneR::normalize(exmp.test2, unit = "16")
#' 
#' # save examples
#' writeWave(object = exmp.test1, filename = file.path(td, "example_test1.wav"), extensible = FALSE)
#' writeWave(object = exmp.test2, filename = file.path(td, "example_test2.wav"), extensible = FALSE)
#' 
#' # search using start marker as template
#' find_markers(X = master.sf[which(master.sf$orig.sound.file == "start_marker"),],
#' test.files = c("example_test1.wav", "example_test2.wav"), path = td, pb = FALSE)
#' 
#' # search using end marker as template
#' find_markers(X = master.sf[which(master.sf$orig.sound.file == "end_marker"),], 
#' test.files = c("example_test1.wav", "example_test2.wav"), 
#' path = td, pb = FALSE)
#' 
#' # search using both start and end markers as template
#' find_markers(X = master.sf, 
#' template.rows = which(master.sf$orig.sound.file == "start_marker" | 
#' master.sf$orig.sound.file == "end_marker"), 
#' test.files = c("example_test1.wav", "example_test2.wav"), 
#' path = td, pb = FALSE)
#' }
#' @author Marcelo Araya-Salas (\email{marcelo.araya@@ucr.ac.cr})
#' @references {
#' Araya-Salas, M. (2020). baRulho: baRulho: quantifying habitat-induced degradation of (animal) acoustic signals in R. R package version 1.0.2
#' }

find_markers <-
  function(X,
           template.rows = NULL,
           markers = c("start_marker", "end_marker"),
           test.files = NULL,
           path = NULL,
           pb = TRUE,
           cores = 1,
           ...) {

    # deprecated message
    if (!is.null(template.rows))
      stop2("'template.rows' has been deprecated")
    
    # check sound.id column 
    if (is.null(X$sound.id)) stop2("'X' must contain a 'sound.id' column")

    if (!all(markers %in% X$sound.id)) stop2("at least one value in 'markers' not found in 'sound.id' column in 'X'") else X <- X[X$sound.id %in% markers, ]
        
    # get sound files in path
    files_in_path <-
      list.files(path = path,
                 pattern = "\\.wav$",
                 ignore.case = TRUE)
    
    # check if there are files
    if (length(files_in_path) == 0)
      stop2("No .wav files found in 'path'")
    
    # check for master sound file
    if (!any(files_in_path %in% unique(X$sound.files)))
      stop2(
        "sound file referenced in 'X' not found in 'path' (make sure you put the master sound file in the same folder than the re-recorded files)"
      )
    
    # remove sound files
    if (!is.null(test.files)) {
      if (!all(test.files %in% files_in_path))
        stop2("Not all 'test.files' were found in 'path'")
    } else
      test.files <-
      files_in_path[!files_in_path %in% unique(X$sound.files)] # remove master sound file
    
    # get metadata of sound files to get sampling rates
    wi <-
      warbleR::info_sound_files(
        path = path,
        parallel = 1,
        pb = FALSE,
        skip.error = TRUE,
        files = c(test.files, unique(X$sound.files))
      )
    
    if (length(unique(wi$sample.rate)) > 1)
      stop2(
        "Not all sound files share the same sampling rate (check wave properties with warbleR::info_sound_files())"
      )
    
    # run cross correlation
    if (pb)
      write(file = "",
            x = paste0("running cross-correlation (step 1 out of 2):"))
    templ_corrs <-
      ohun::template_correlator(
        templates = X,
        files = test.files,
        path = path,
        cores = cores,
        pb = pb, 
        ...
      )
    
    # find peaks
    if (pb)
      write(file = "",
            x = paste0("running peak detection (step 2 out of 2):"))
    
    pks <-
      as.data.frame(
        ohun::template_detector(
          template.correlations = templ_corrs,
          cores = cores,
          threshold = 0.0001,
          pb = pb
        )
      )
    
    pks <-
      pks[stats::ave(
        x = -pks$scores,
        as.factor(pks$sound.files),
        as.factor(pks$template),
        FUN = rank
      ) <= 1,]
    
    # pks$time <-
    #   vapply(seq_len(nrow(pks)), function(x)
    #     mean(c(pks$end[x], pks$start[x])), FUN.VALUE = numeric(1))
    
    # rename sound file column
    try(names(pks)[names(pks) == "sound.files"] <- "test.files")
    
    # rename markers
    pks$template <- vapply(pks$template, function(x) as.character(X$sound.id[paste(X$sound.files, X$selec, sep = "-") == x]), FUN.VALUE = character(length = 1))
    
    # fix row labels and selec labels
    pks$selec <- rownames(pks) <- seq_len(nrow(pks))
    
    
    # check that the distance between  markers is similar in re-recorded files compare to the master
    if (!is_extended_selection_table(X) & length(markers) > 1){
      time_dist_markers <- vapply(test.files, function(x) pks$end[pks$template == markers[2] & pks$test.files == x] - pks$start[pks$template == markers[1] & pks$test.files == x], FUN.VALUE = numeric(length = 1L))
      
      # subtract duration in master sound file
      time_dist_markers <- time_dist_markers - (X$end[X$sound.id == markers[2]] - X$start[X$sound.id == markers[1]])
      
      # add results 
      pks$time.match <- NA
      pks$time.match[pks$template == markers[1]] <- time_dist_markers
    }
    
    return(pks)
    
  }

##############################################################################################################
#' alternative name for \code{\link{find_markers}}
#'
#' @keywords internal
#' @details see \code{\link{find_markers}} for documentation. \code{\link{search_templates}} will be deprecated in future versions.
#' @export

search_templates <- find_markers
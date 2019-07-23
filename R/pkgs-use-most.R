
#' Package use
#'
#' Take inventory of your own package use
#'
#' @param ... Directory location in which files ending in '.R' and '.Rmd' will
#'   be searched for packages (via fully qualified namespace or calls to library
#'   or require).
#' @return A pkguse object, which is really just a tibble with specialized
#'   methods for plot and summary.
#' @export
pkg_use <- function(...) {
  x <- read_r_files(...)
  x <- parse_r_pkgs(x)
  x <- factor(x, levels = unique(x))
  x <- table(pkg = x)
  tibble::as_tibble(x) %>%
    arrange_and_factor(pkg, -n) %>%
    `class<-`(c("pkguse", "tbl_df", "tbl", "data.frame"))
}


read_r_files <- function(...) {
  dirs <- unlist(list(...))
  r <- unlist(lapply(dirs, list.files,
    pattern = "\\.(R|Rmd|Rmarkdown|rmd|r|Rhistory)$",
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE))
  suppressWarnings( x <- unlist(lapply(r, tfse::readlines)))
  x
}

parse_r_pkgs <- function(x) {
  ## via pkg::
  c(tfse::regmatches_(x, "[[:alpha:]][[:alnum:]\\.]+(?=::)", drop = TRUE),
    ## via library(pkg)
    tfse::regmatches_(x, "(?<=library\\()[A-Za-z][[:alnum:]\\.]+(?=\\))", drop = TRUE),
    ## via require(pkg)
    tfse::regmatches_(x, "(?<=require\\()[A-Za-z][[:alnum:]\\.]+(?=\\))", drop = TRUE),
    ## via requireNamespace('pkg')
    tfse::regmatches_(x, "(?<=requireNamespace\\(')[A-Za-z][[:alnum:]\\.]+(?=\\')", drop = TRUE),
    ## via requireNamespace("pkg")
    tfse::regmatches_(x, "(?<=requireNamespace\\(\")[A-Za-z][[:alnum:]\\.]+(?=\\\")", drop = TRUE))
}

arrange_and_factor <- function(.x, cat, val) {
  cat <- rlang::enquo(cat)
  cat <- names(dplyr::select(.x, !!cat))
  val <- rlang::enquo(val)
  .x <- dplyr::arrange(.x, !!val)
  .x[[cat]] <- factor(.x[[cat]], levels = rev(unique(.x[[cat]])))
  .x
}

#' @export
plot.pkguse <- function(x, n = 50, base_family = "Arial Narrow", base_size = 16) {
  x %>%
    utils::head(n) %>%
    dplyr::mutate(eo = rep(c(TRUE, FALSE), nrow(.) / 1.5)[seq_len(nrow(.))]) %>%
    ggplot2::ggplot(ggplot2::aes(x = pkg, y = n, fill = eo)) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_manual(values = c("#707a8f", "greenyellow")) +
    ggplot2::theme_gray(base_family = base_family, base_size = base_size) +
    ggplot2::theme(legend.position = "none",
      plot.title = ggplot2::element_text(face = "bold")) +
    ggplot2::labs(x = NULL, y = NULL,
      title = "#rstats packages I use the most")
}

#' @export
summary.pkguse <- function(x) {
  k <- as.character(x$pkg)
  n <- x$n
  cat("Total packages        :", nrow(x), fill = TRUE)
  cat("Total uses            :", sum(n), fill = TRUE)
  most <- paste0(k[1], " (", n[1], " times)")
  mid <- paste0(k[nrow(x) %/% 2], " (", n[nrow(x) %/% 2], " times)")
  cat("Most used package     :", most, fill = TRUE)
  cat("Median used package   :", mid, fill = TRUE)
}


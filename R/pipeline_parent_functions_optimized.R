#' Run full pipeline for a single item type
#'
#' @param embedding_matrix Numeric matrix (columns = items for one type)
#' @param items Data frame of items for this type (must include ID, statement, attribute)
#' @param type_name Character. Type label used for tracking/logging.
#' @param model NULL, "glasso", or "TMFG"
#' @param algorithm EGA algorithm
#' @param uni.method EGA uni.method
#' @param corr Character. Correlation method. Default "auto" uses EGAnet's automatic detection.
#' @param ncores Numeric. Number of cores for parallel processing. Default NULL uses EGAnet default.
#' @param boot.iter Numeric. Number of bootstrap iterations. Default 100.
#' @param keep.org Logical. Whether to include original items and embeddings
#' @param silently Logical. Whether to print progress statements
#' @param plot Logicial. Whether to plot the network plots at the end
#'
#' @return A named list containing pipeline results for this type
run_pipeline_for_item_type <- function(embedding_matrix,
                                       items,
                                       type_name,
                                       model = NULL,
                                       algorithm = "walktrap",
                                       uni.method = "louvain",
                                       corr = "auto",
                                       ncores = NULL,
                                       boot.iter = 100,
                                       keep.org = FALSE,
                                       silently,
                                       plot) {

  if (keep.org) {
    result <- list(
      final_NMI = NULL,
      initial_NMI = NULL,
      embeddings = list(),
      UVA = list(),
      bootEGA = list(),
      EGA.model_selected = NULL,
      final_items = NULL,
      initial_items = items,
      final_EGA = NULL,
      initial_EGA = NULL,
      start_N = nrow(items),
      final_N = NULL,
      network_plot = NULL,
      stability_plot = NULL
    )
  } else {
    result <- list(
      final_NMI = NULL,
      initial_NMI = NULL,
      embeddings = list(),
      UVA = list(),
      bootEGA = list(),
      EGA.model_selected = NULL,
      final_items = NULL,
      final_EGA = NULL,
      initial_EGA = NULL,
      start_N = nrow(items),
      final_N = NULL,
      network_plot = NULL,
      stability_plot = NULL
    )
  }

  embedding_matrix <- .align_embedding_to_ids(embedding_matrix, items$ID)
  items <- .subset_items_by_ids(items, colnames(embedding_matrix))

  if (nrow(items) < 6L) {
    warning(
      "[", type_name, "] Too few items (", nrow(items),
      ") for meaningful network analysis. Minimum recommended is 6. Returning partial result."
    )
    result$final_items <- items
    result$final_N <- nrow(items)
    return(result)
  }

  if (!silently) {
    cat("\n\n")
    cat(paste("Starting item pool reduction for", type_name, "items.\n"))
    cat("-------------------\n")
  }

  true_communities <- as.integer(factor(items$attribute))
  names(true_communities) <- items$ID

  if (keep.org) {
    result$embeddings$full_org <- embedding_matrix
    result$embeddings$sparse_org <- sparsify_embeddings(embedding_matrix)
  }

  uva_res <- reduce_redundancy_uva(embedding_matrix, items, corr = corr)
  if (!isTRUE(uva_res$success)) {
    warning("[", type_name, "] UVA failed -- returning partial result.")
    return(result)
  }

  if (!silently) {
    cat("Unique Variable Analysis complete.\n")
  }

  result$UVA$n_removed <- uva_res$items_removed
  result$UVA$n_sweeps <- uva_res$iterations
  result$UVA$redundant_pairs <- uva_res$redundant_pairs

  reduced_matrix <- uva_res$embedding_matrix
  reduced_items <- .subset_items_by_ids(items, colnames(reduced_matrix))

  if (ncol(reduced_matrix) < 4L) {
    warning(
      "[", type_name, "] Too few items (", ncol(reduced_matrix),
      ") remaining after UVA for further analysis. Returning partial result."
    )
    result$final_items <- reduced_items
    result$final_N <- nrow(reduced_items)
    return(result)
  }

  reduced_truth <- true_communities[colnames(reduced_matrix)]

  select_res <- select_optimal_embedding(
    embedding_matrix = reduced_matrix,
    true_communities = reduced_truth,
    model = model,
    algorithm = algorithm,
    uni.method = uni.method,
    corr = corr
  )

  if (!isTRUE(select_res$success)) {
    warning("[", type_name, "] Model selection failed -- returning partial result.")
    return(result)
  }

  if (!silently) {
    if (is.null(model)) {
      cat("Optimal EGA model and embedding type found.\n")
    } else {
      cat("Optimal embedding type found.\n")
    }
  }

  result$embeddings$selected <- select_res$embedding_type
  result$EGA.model_selected <- select_res$model

  initial_matrix <- .apply_embedding_type(embedding_matrix, select_res$embedding_type)
  initial_res <- final_community_detection(
    embedding_matrix = initial_matrix,
    true_communities = true_communities,
    model = select_res$model,
    algorithm = select_res$algorithm,
    uni.method = select_res$uni.method,
    corr = corr
  )

  if (isTRUE(initial_res$success)) {
    result$initial_EGA <- initial_res$ega
    result$initial_NMI <- initial_res$final_nmi

    if (keep.org) {
      result$initial_items <- .attach_communities(items, initial_res$communities)
    }
  }

  selected_embedding <- select_res$best_embedding_matrix
  selected_items <- .subset_items_by_ids(reduced_items, colnames(selected_embedding))

  boot_res <- iterative_stability_check(
    embedding_matrix = selected_embedding,
    items = selected_items,
    cut.off = 0.75,
    model = select_res$model,
    algorithm = select_res$algorithm,
    uni.method = select_res$uni.method,
    corr = corr,
    ncores = ncores,
    boot.iter = boot.iter,
    silently = silently
  )

  if (!isTRUE(boot_res$successful)) {
    warning("[", type_name, "] BootEGA failed -- returning partial result.")
    return(result)
  }

  result$bootEGA$initial_boot <- boot_res$boot1
  result$bootEGA$final_boot <- boot_res$boot2
  result$bootEGA$n_removed <- .safe_removed_n(boot_res$items_removed)
  result$bootEGA$items_removed <- boot_res$items_removed

  stable_selected_embedding <- boot_res$embedding
  stable_ids <- colnames(stable_selected_embedding)
  stable_items <- .subset_items_by_ids(items, stable_ids)

  final_truth <- true_communities[stable_ids]
  final_res <- final_community_detection(
    embedding_matrix = stable_selected_embedding,
    true_communities = final_truth,
    model = select_res$model,
    algorithm = select_res$algorithm,
    uni.method = select_res$uni.method,
    corr = corr
  )

  if (!isTRUE(final_res$success)) {
    warning("[", type_name, "] Final EGA failed -- returning partial result.")
    return(result)
  }

  result$final_EGA <- final_res$ega
  result$final_NMI <- final_res$final_nmi
  result$final_items <- .attach_communities(stable_items, final_res$communities)

  full_embeds_final <- .align_embedding_to_ids(embedding_matrix, result$final_items$ID)
  result$embeddings$full <- full_embeds_final
  result$embeddings$sparse <- sparsify_embeddings(full_embeds_final)

  if (!silently) {
    cat("\nBuilding initial network based on optimal settings...")
  }

  try_stab <- calc_final_stability(
    result,
    initial_matrix,
    algorithm,
    uni.method,
    corr = corr,
    ncores = ncores,
    boot.iter = boot.iter,
    silently
  )

  if (isTRUE(try_stab$successful)) {
    result <- try_stab$result
  }

  result$final_N <- nrow(result$final_items)

  if (!silently) {
    cat(paste0("\nReduction for ", type_name, " items complete."))
  }

  tryCatch({
    network_plot <- plot_comparison(
      p1 = result$initial_EGA,
      p2 = result$final_EGA,
      caption1 = "Network Plot for Items Pre-Reduction",
      caption2 = "Network Plot for Items Post-Reduction",
      nmi1 = result$initial_NMI,
      nmi2 = result$final_NMI,
      title = paste("Network Plots for", type_name, "Items Before vs After AIGENIE Reduction")
    )
    result$network_plot <- network_plot
  }, error = function(e) {
    warning(paste("Failed to create network plots for", type_name, "items."))
  })

  tryCatch({
    initial_stability_obj <- build_item_stability_from_reference(
      boot_obj = result$bootEGA$initial_boot_with_redundancies,
      reference_ega = result$initial_EGA
    )

    final_stability_obj <- build_item_stability_from_reference(
      boot_obj = result$bootEGA$final_boot,
      reference_ega = result$final_EGA
    )

    result$bootEGA$initial_item_stability <- initial_stability_obj
    result$bootEGA$final_item_stability <- final_stability_obj

    stability_plot <- plot_comparison(
      p1 = plot_item_stability_reference(initial_stability_obj),
      p2 = plot_item_stability_reference(final_stability_obj),
      caption1 = "Stability Plot for Items Pre-Reduction",
      caption2 = "Stability Plot for Items Post-Reduction",
      nmi1 = result$initial_NMI,
      nmi2 = result$final_NMI,
      title = paste("Bootstrapped Item Stability for", type_name, "Items Before vs After AIGENIE Reduction")
    )
    result$stability_plot <- stability_plot
  }, error = function(e) {
    warning(paste("Failed to create stability plots for", type_name, "items."))
  })

  if (plot && !is.null(result$network_plot)) {
    plot(result$network_plot)
  }

  result
}


#' Run reduction pipeline for all item types
#'
#' @param embedding_matrix Full embedding matrix (columns = all items)
#' @param items Data frame of all items (must include ID, statement, attribute, type)
#' @param EGA.model NULL, "glasso", or "TMFG"
#' @param EGA.algorithm EGA algorithm
#' @param EGA.uni.method EGA uni.method
#' @param corr Character. Correlation method. Default "auto" uses EGAnet's automatic detection.
#' @param ncores Numeric. Number of cores for parallel processing.
#' @param boot.iter Numeric. Number of bootstrap iterations.
#' @param keep.org Logical. Whether to include original items and embeddings
#' @param silently Logical. Whether to print progress statements
#' @param plot Logical. Whether to plot the network plots at the end
#'
#' @return A named list of pipeline results, one per item type
run_item_reduction_pipeline <- function(embedding_matrix,
                                        items,
                                        EGA.model = NULL,
                                        EGA.algorithm = "walktrap",
                                        EGA.uni.method = "louvain",
                                        corr = "auto",
                                        ncores = NULL,
                                        boot.iter = 100,
                                        keep.org,
                                        silently,
                                        plot) {

  # --- Prepare ---
  unique_types <- unique(items$type)
  success <- TRUE

  # Split by type
  embedding_split <- lapply(unique_types, function(t) {
    cols <- items$ID[items$type == t]
    embedding_matrix[, cols, drop = FALSE]
  })
  items_split <- split(items, items$type)

  names(embedding_split) <- unique_types

  # --- Run pipeline ---
  results <- lapply(unique_types, function(tname) {
    tryCatch({
      run_pipeline_for_item_type(
        embedding_matrix = embedding_split[[tname]],
        items = items_split[[tname]],
        type_name = tname,
        model = EGA.model,
        algorithm = EGA.algorithm,
        uni.method = EGA.uni.method,
        corr = corr,
        ncores = ncores,
        boot.iter = boot.iter,
        keep.org = keep.org,
        silently = silently,
        plot = plot
      )
    }, error = function(e) {
      warning("Pipeline failed for type: ", tname, " -- ", e$message)
      success <<- FALSE
      return(NULL)
    })
  })


  names(results) <- unique_types

  return(list(item_level = results,
              success = success))
}




#' Run full pipeline for all items in the sample
#'
#' @param item_level AIGENIE results on the item level
#' @param items all items generated for the initial item pool
#' @param embeddings all embeddings created for the initial item pool
#' @param model NULL, "glasso", or "TMFG"
#' @param algorithm EGA algorithm
#' @param uni.method EGA uni.method
#' @param corr Character. Correlation method. Default "auto" uses EGAnet's automatic detection.
#' @param keep.org Logical. Whether to include original items and embeddings
#' @param silently Logical. Whether to print progress statements
#' @param plot logical. Whether to plot the network plot
#'
#' @return A named list containing pipeline results for this type
run_pipeline_for_all <- function(item_level,
                                 items,
                                 embeddings,
                                 model = NULL,
                                 algorithm = "walktrap",
                                 uni.method = "louvain",
                                 corr = "auto",
                                 keep.org = FALSE,
                                 silently,
                                 plot) {

  if (keep.org) {
    overall_result <- list(
      final_NMI = NULL,
      initial_NMI = NULL,
      embeddings = list(),
      EGA.model_selected = NULL,
      final_items = NULL,
      initial_items = items,
      final_EGA = NULL,
      initial_EGA = NULL,
      start_N = nrow(items),
      final_N = NULL,
      network_plot = NULL,
      stability_plot = NULL,
      bootEGA = list()
    )
  } else {
    overall_result <- list(
      final_NMI = NULL,
      initial_NMI = NULL,
      embeddings = list(),
      EGA.model_selected = NULL,
      final_items = NULL,
      final_EGA = NULL,
      initial_EGA = NULL,
      start_N = nrow(items),
      final_N = NULL,
      network_plot = NULL,
      stability_plot = NULL,
      bootEGA = list()
    )
  }

  success <- TRUE

  embeddings <- .align_embedding_to_ids(embeddings, items$ID, context = "embeddings")
  items <- .subset_items_by_ids(items, colnames(embeddings))

  if (keep.org) {
    overall_result$embeddings$full_org <- embeddings
    overall_result$embeddings$sparse_org <- sparsify_embeddings(embeddings)
  }

  valid_idx <- which(vapply(
    item_level,
    function(x) {
      !is.null(x) &&
        !is.null(x$final_items) &&
        nrow(x$final_items) > 0L &&
        !is.null(x$embeddings$full)
    },
    logical(1)
  ))

  if (length(valid_idx) == 0L) {
    warning("No valid item-level results were available for the overall analysis.")
    success <- FALSE
    return(list(overall_result = overall_result, success = success))
  }

  valid_item_level <- item_level[valid_idx]

  df_list <- lapply(valid_item_level, function(x) x$final_items)
  emb_list <- lapply(valid_item_level, function(x) x$embeddings$full)

  final_items <- do.call(rbind, df_list)
  final_embeddings <- do.call(cbind, emb_list)

  final_items <- .subset_items_by_ids(final_items, colnames(final_embeddings))
  final_embeddings <- .align_embedding_to_ids(final_embeddings, final_items$ID, context = "final_embeddings")

  overall_result$final_items <- final_items
  overall_result$embeddings$full <- final_embeddings
  overall_result$embeddings$sparse <- sparsify_embeddings(final_embeddings)

  final_truth <- paste(final_items$type, final_items$attribute, sep = "_")
  names(final_truth) <- final_items$ID

  if (!silently) {
    cat("

")
    cat("Starting analysis on all items.
")
    cat("-------------------
")
  }

  initial_truth <- paste(items$type, items$attribute, sep = "_")
  names(initial_truth) <- items$ID

  select_res <- select_optimal_embedding(
    embedding_matrix = embeddings,
    true_communities = initial_truth,
    model = model,
    algorithm = algorithm,
    uni.method = uni.method,
    corr = corr
  )

  if (!isTRUE(select_res$success)) {
    warning("Building the initial overall EGA network has failed -- returning partial result.")
    success <- FALSE
    return(list(overall_result = overall_result, success = success))
  }

  if (!silently) {
    if (is.null(model)) {
      cat("Optimal EGA model and embedding type found.
")
    } else {
      cat("Optimal embedding type found.
")
    }
  }

  overall_result$embeddings$selected <- select_res$embedding_type
  overall_result$EGA.model_selected <- select_res$model

  initial_matrix <- .apply_embedding_type(embeddings, select_res$embedding_type)

  if (!silently) {
    cat("Building initial EGA network based on optimal settings...")
  }

  initial_res <- final_community_detection(
    embedding_matrix = initial_matrix,
    true_communities = initial_truth,
    model = select_res$model,
    algorithm = select_res$algorithm,
    uni.method = select_res$uni.method,
    corr = corr
  )

  if (!isTRUE(initial_res$success)) {
    warning("EGA failed on all items in the initial item pool -- returning partial result.")
    success <- FALSE
    return(list(overall_result = overall_result, success = success))
  }

  overall_result$initial_NMI <- initial_res$final_nmi
  overall_result$initial_EGA <- initial_res$ega

  if (keep.org) {
    overall_result$initial_items <- .attach_communities(items, initial_res$communities)
  }

  final_matrix <- .apply_embedding_type(final_embeddings, select_res$embedding_type)
  final_res <- final_community_detection(
    embedding_matrix = final_matrix,
    true_communities = final_truth,
    model = select_res$model,
    algorithm = select_res$algorithm,
    uni.method = select_res$uni.method,
    corr = corr
  )

  if (!isTRUE(final_res$success)) {
    warning("Building the final overall EGA network has failed -- returning partial result.")
    success <- FALSE
    return(list(overall_result = overall_result, success = success))
  }

  overall_result$final_NMI <- final_res$final_nmi
  overall_result$final_EGA <- final_res$ega
  overall_result$final_items <- .attach_communities(final_items, final_res$communities)
  overall_result$final_N <- nrow(overall_result$final_items)

  try_stab <- calc_final_stability(
    result = overall_result,
    data = initial_matrix,
    EGA.algorithm = select_res$algorithm,
    EGA.uni.method = select_res$uni.method,
    corr = corr,
    ncores = NULL,
    boot.iter = 100,
    silently = silently
  )

  if (isTRUE(try_stab$successful)) {
    overall_result <- try_stab$result
  }

  if (!is.null(final_matrix) && ncol(final_matrix) >= 3L) {
    boot_args <- list(
      data = final_matrix,
      corr = corr,
      model = overall_result$EGA.model_selected,
      algorithm = select_res$algorithm,
      uni.method = select_res$uni.method,
      iter = 100,
      EGA.type = "EGA.fit",
      plot.itemStability = FALSE,
      plot.typicalStructure = FALSE,
      verbose = !silently,
      seed = 123
    )

    final_boot <- tryCatch({
      do.call(EGAnet::bootEGA, boot_args)
    }, error = function(e) NULL)

    overall_result$bootEGA$final_boot <- final_boot
  }

  if (!silently) {
    cat("Done.")
  }

  tryCatch({
    network_plot <- plot_comparison(
      p1 = overall_result$initial_EGA,
      p2 = overall_result$final_EGA,
      caption1 = "Network Plot for Items Pre-Reduction",
      caption2 = "Network Plot for Items Post-Reduction",
      nmi1 = overall_result$initial_NMI,
      nmi2 = overall_result$final_NMI,
      title = "Network Plots for All Items Before vs After AIGENIE Reduction"
    )
    overall_result$network_plot <- network_plot
  }, error = function(e) {
    warning("Failed to create network plots for the items overall.")
  })

  tryCatch({
    initial_stability_obj <- build_item_stability_from_reference(
      boot_obj = overall_result$bootEGA$initial_boot_with_redundancies,
      reference_ega = overall_result$initial_EGA
    )

    final_stability_obj <- build_item_stability_from_reference(
      boot_obj = overall_result$bootEGA$final_boot,
      reference_ega = overall_result$final_EGA
    )

    overall_result$bootEGA$initial_item_stability <- initial_stability_obj
    overall_result$bootEGA$final_item_stability <- final_stability_obj

    overall_result$stability_plot <- plot_comparison(
      p1 = plot_item_stability_reference(initial_stability_obj),
      p2 = plot_item_stability_reference(final_stability_obj),
      caption1 = "Stability Plot for Items Pre-Reduction",
      caption2 = "Stability Plot for Items Post-Reduction",
      nmi1 = overall_result$initial_NMI,
      nmi2 = overall_result$final_NMI,
      title = "Bootstrapped Item Stability for All Items Before vs After AIGENIE Reduction"
    )
  }, error = function(e) {
    warning("Failed to create stability plots for the items overall.")
  })

  if (plot && !is.null(overall_result$network_plot)) {
    plot(overall_result$network_plot)
  }

  list(overall_result = overall_result, success = success)
}

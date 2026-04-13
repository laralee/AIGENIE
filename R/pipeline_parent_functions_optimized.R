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


  if(keep.org){
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
    )} else {
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

  # Check minimum items for meaningful analysis

  if (nrow(items) < 6) {
    warning("[", type_name, "] Too few items (", nrow(items),
            ") for meaningful network analysis. Minimum recommended is 6. Returning partial result.")
    result$final_items <- items
    result$final_N <- nrow(items)
    return(result)
  }

  if(!silently){
    cat("\n\n")
    cat(paste("Starting item pool reduction for", type_name  ,"items.\n"))
    cat("-------------------\n")
  }

  # 1. Convert attribute to numeric factor for true communities
  true_communities <- as.factor(as.integer(factor(items$attribute)))
  names(true_communities) <- items$ID

  # 2. Redundancy reduction (UVA)

  uva_res <- reduce_redundancy_uva(embedding_matrix, items, corr = corr)

  if (!uva_res$success) {
    warning("[", type_name, "] UVA failed -- returning partial result.")
    return(result)
  }

  if(!silently){
    cat("Unique Variable Analysis complete.\n")
  }


  result$UVA$n_removed <- uva_res$items_removed
  result$UVA$n_sweeps <- uva_res$iterations
  result$UVA$redundant_pairs <- uva_res$redundant_pairs

  reduced_matrix <- uva_res$embedding_matrix
  reduced_items <- items[items$ID %in% colnames(reduced_matrix), , drop = FALSE]

  # Check if enough items remain after UVA
  if (ncol(reduced_matrix) < 4) {
    warning("[", type_name, "] Too few items (", ncol(reduced_matrix),
            ") remaining after UVA for further analysis. Returning partial result.")
    result$final_items <- reduced_items
    result$final_N <- nrow(reduced_items)
    return(result)
  }

  if (keep.org) {
    result$embeddings$full_org <- embedding_matrix
    result$embeddings$sparse_org <- sparsify_embeddings(embedding_matrix)
  }


  # 3. Optimal embedding/model selection
  select_res <- select_optimal_embedding(
    embedding_matrix = reduced_matrix,
    true_communities = true_communities,
    model = model,
    algorithm = algorithm,
    uni.method = uni.method,
    corr = corr
  )

  if (!isTRUE(select_res$success)) {
    warning("[", type_name, "] Model selection failed -- returning partial result.")
    return(result)
  }

  if(!silently){
    if(is.null(model)){
      cat("Optimal EGA model and embedding type found.\n")
    } else {
      cat("Optimal embedding type found.\n")
    }

  }


  selected_embedding <- select_res$best_embedding_matrix
  result$embeddings$selected <- select_res$embedding_type
  result$EGA.model_selected <- select_res$model
  post_uva_initial_nmi <- select_res$nmi

  # 4. BootEGA filtering
  boot_res <- iterative_stability_check(
    embedding_matrix = selected_embedding,
    items = items,
    cut.off = 0.75,
    model = select_res$model,
    algorithm = select_res$algorithm,
    uni.method = select_res$uni.method,
    corr = corr,
    ncores = ncores,
    boot.iter = boot.iter,
    silently = silently
  )

  if (!boot_res$successful) {
    warning("[", type_name, "] BootEGA failed -- returning partial result.")
    return(result)
  }

  result$bootEGA$post_uva_initial_boot <- boot_res$boot1
  result$bootEGA$post_uva_final_boot <- boot_res$boot2
  result$bootEGA$n_removed <- nrow(boot_res$items_removed)
  result$bootEGA$items_removed <- boot_res$items_removed

  stable_embedding <- boot_res$embedding
  stable_items <- items[items$ID %in% colnames(stable_embedding), , drop = FALSE]

  # 5. Final EGA + NMI
  final_res <- final_community_detection(
    embedding_matrix = stable_embedding,
    true_communities = true_communities,
    model = select_res$model,
    algorithm = select_res$algorithm,
    uni.method = select_res$uni.method,
    corr = corr
  )

  if (!isTRUE(final_res$success)) {
    warning("[", type_name, "] Final EGA failed -- returning partial result.")
    return(result)
  }

  # Add community labels
  com_df <- data.frame(ID = names(final_res$communities),
                       EGA_com = final_res$communities,
                       stringsAsFactors = FALSE)

  result$final_items <- merge(stable_items, com_df, by = "ID")
  result$final_NMI <- final_res$final_nmi

  result$final_EGA <- final_res$ega

  # Store full + sparse embeddings
  full_embeds_final <- embedding_matrix[,colnames(embedding_matrix) %in% result$final_items$ID]
  result$embeddings$full <- full_embeds_final
  result$embeddings$sparse <- sparsify_embeddings(full_embeds_final)

  # 6. Build initial network
  if(!silently){
    cat("\nBuilding initial network based on optimal settings...")
  }


  true_communities <- as.factor(as.integer(factor(items$attribute)))
  names(true_communities) <- items$ID

  # Use the SAME representation that was selected as optimal (sparse vs full),
  # applied to the FULL pre-UVA embedding matrix. The original code passed raw
  # `embedding_matrix` unconditionally, silently mismatching the selected
  # representation whenever embeddings$selected == "sparse".
  if(result$embeddings$selected == "full"){
    data <- embedding_matrix
  } else {
    data <- sparsify_embeddings(embedding_matrix)
  }

  # Initial EGA on the full pool, computed directly from the embeddings
  # (NOT taken from bootEGA's median typical structure).
  initial_res <- final_community_detection(
    embedding_matrix = data,
    true_communities = true_communities,
    model = select_res$model,
    algorithm = select_res$algorithm,
    uni.method = select_res$uni.method,
    corr = corr
  )

  if (!isTRUE(initial_res$success)) {
    warning("[", type_name, "] Initial EGA failed -- returning partial result.")
    return(result)
  }

  # add the communities to the initial items (if retained)
  if(keep.org){
    com_df <- data.frame(ID = names(initial_res$communities),
                         EGA_com = initial_res$communities,
                         stringsAsFactors = FALSE)

    result$initial_items <- merge(items, com_df, by = "ID", all.x = TRUE)
  }

  result$initial_EGA <- initial_res$ega
  result$initial_NMI <- initial_res$final_nmi

  try_stab <- calc_final_stability(result,
                                   data,
                                   algorithm,
                                   uni.method,
                                   corr = corr,
                                   ncores = ncores,
                                   boot.iter = boot.iter,
                                   silently)

  if(try_stab$successful){
    result <- try_stab$result
  }

  # add the final number of items
  result$final_N <- nrow(result$final_items)


  if(!silently){
    cat(paste0("\nReduction for ",type_name," items complete."))
  }

 tryCatch({network_plot <- plot_comparison(
    p1 = result$initial_EGA,
    p2 = result$final_EGA,
    caption1 = "Network Plot for Items Pre-Reduction",
    caption2 = "Network Plot for Items Post-Reduction",
    nmi1 = result$initial_NMI,
    nmi2 = result$final_NMI,
    title = paste("Network Plots for", type_name, "Items Before vs After AIGENIE Reduction")
  )
  result$network_plot <- network_plot },
  error = function(e) {
    warning(paste("Failed to create network plots for", type_name, "items."))
  })


  tryCatch({stability_plot <- plot_stability_comparison(
    boot1 = result$bootEGA$initial_boot_with_redundancies,
    boot2 = result$bootEGA$post_uva_final_boot,
    caption1 = "Original Sample | EGA + TEFI",
    caption2 = "Original Sample | EGA + TEFI",
    nmi1 = result$initial_NMI,
    nmi2 = result$final_NMI,
    title = paste("Bootstrapped Item Stability for", type_name, "Items Before vs After AIGENIE Reduction")
  )
  result$stability_plot <- stability_plot
  result$network_plot <- network_plot },
  error = function(e) {
    warning(paste("Failed to create stability plots for", type_name,
                  "items. Reason:", conditionMessage(e)))
  })


  if(plot && !is.null(result$network_plot)){
    print(result$network_plot)
  }


  return(result)
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
                                 ncores = NULL,
                                 boot.iter = 100,
                                 keep.org = FALSE,
                                 silently,
                                 plot) {

  # Collapse all item types into a single "All" type so the same pipeline
  # used per-type can be applied to the entire item pool. This guarantees
  # that run_pipeline_for_all and run_pipeline_for_item_type execute the
  # exact same steps (UVA -> select_optimal_embedding -> bootEGA filter ->
  # final EGA -> initial EGA -> calc_final_stability -> network/stability plots).
  items_all <- run_all_together(items)

  # Make sure embeddings columns are aligned to items$ID
  if (!is.null(colnames(embeddings))) {
    embeddings_all <- embeddings[, items_all$ID, drop = FALSE]
  } else {
    embeddings_all <- embeddings
    colnames(embeddings_all) <- items_all$ID
  }

  overall_result <- run_pipeline_for_item_type(
    embedding_matrix = embeddings_all,
    items            = items_all,
    type_name        = "All",
    model            = model,
    algorithm        = algorithm,
    uni.method       = uni.method,
    corr             = corr,
    ncores           = ncores,
    boot.iter        = boot.iter,
    keep.org         = keep.org,
    silently         = silently,
    plot             = plot
  )

  # Restore the original (non-collapsed) attribute / type columns on the
  # surviving items so downstream code that joins on real attributes works.
  if (!is.null(overall_result$final_items) &&
      "ID" %in% names(overall_result$final_items)) {
    keep_ids <- overall_result$final_items$ID
    restored <- items[items$ID %in% keep_ids, , drop = FALSE]
    if ("EGA_com" %in% names(overall_result$final_items)) {
      restored <- merge(
        restored,
        overall_result$final_items[, c("ID", "EGA_com"), drop = FALSE],
        by = "ID", all.x = TRUE
      )
    }
    overall_result$final_items <- restored
  }

  if (keep.org) {
    overall_result$initial_items <- items
  }

  success <- !is.null(overall_result) &&
             !is.null(overall_result$final_EGA) &&
             !is.null(overall_result$initial_EGA)

  return(list(overall_result = overall_result,
              success        = success))
}

#' Launch bloodstream configuration app
#'
#' @description Launch the Shiny app for creating bloodstream configuration files
#' 
#' @import shiny
#'
#' @param bids_dir Character string path to the BIDS directory (default: NULL)
#' @param derivatives_dir Character string path to the derivatives directory (default: NULL)
#' @param config_file Character string path to existing config file to load (default: NULL)
#' @param analysis_folder Character string name for analysis subfolder (default: "default")
#' @param host Character string host address for the Shiny server (default: "127.0.0.1")
#' @param port Integer port number for the Shiny server (default: 3838)
#'
#' @details 
#' This function launches a Shiny application that allows users to:
#' - Define data subsets using BIDS metadata
#' - Configure modelling approaches for different blood components (Parent Fraction, BPR, AIF, Whole Blood)
#' - Generate and download customized config files
#' - Optionally run the bloodstream pipeline directly from the app
#' 
#' The app includes tabs for each blood component with specific modelling options,
#' and a final tab for downloading the config and running the pipeline.
#'
#' @export
bloodstream_config_app <- function(bids_dir = NULL, derivatives_dir = NULL, config_file = NULL, analysis_folder = "default", host = "127.0.0.1", port = 3838) {
  
  
  # Function to generate new filename
  generate_new_filename <- function() {
    current_date <- as.character(as.Date(Sys.Date()))
    random_seq <- stringi::stri_rand_strings(1, 4)
    paste0("config_", current_date, "_id-", random_seq, ".json")
  }
  
  # Define UI for bloodstream app ----
  ui <- fluidPage(theme = shinythemes::shinytheme("flatly"),
                  
    # App title ----
    titlePanel("Create a customised bloodstream config file"),
    
    # Sidebar layout for subsetting ----
    sidebarLayout(
      
      # Sidebar panel for inputs ----
      sidebarPanel(
        
        h2("Data Subset"),
        p(glue::glue("Use these options to apply this config to a subset of the data. ",
               "Values should be separated by semi-colons. ",
               "All measurements fulfilling all the conditions will ",
               "be included. Leave options blank for no subsetting is desired, ",
               "i.e. leaving sub blank implies that all subjects should ",
               "be included."),
          style = "font-size:14px;"
        ),
        textInput(inputId = "subset_sub", label = "sub", value = ""),
        textInput(inputId = "subset_ses", label = "ses", value = ""),
        textInput(inputId = "subset_rec", label = "rec", value = ""),
        textInput(inputId = "subset_task", label = "task", value = ""),
        textInput(inputId = "subset_run", label = "run", value = ""),
        textInput(inputId = "subset_tracer", label = "TracerName", value = ""),
        textInput(inputId = "subset_modeadmin", label = "ModeOfAdministration", value = ""),
        textInput(inputId = "subset_institute", label = "InstitutionName", value = ""),
        textInput(inputId = "subset_pharmaceutical", label = "PharmaceuticalName", value = ""),
      ),
      
      # Main panel for modelling options ----
      mainPanel(
        
        h2("Modelling Choices"),
        p(glue::glue("Select the modelling approach for each of the blood curves which ",
               "should be fitted to the data. The default approach for each is ",
               "simply to apply linear interpolation to the observed data. ",
               "As a rule of thumb, modelling the parent fraction and the ",
               "blood-to-plasma ratio are usually a good idea. Modelling ",
               "the AIF and the whole blood are mostly best left for specific ",
               "applications. For debugging, I recommend using simple ",
               "interpolation and inspecting the plots and QC output."),
          style = "font-size:14px;"
        ),
        br(),
        
        # Tabset
        tabsetPanel(type = "tabs",
                    
          tabPanel("Parent Fraction",
                   
            h4("Parent Fraction Model Selection"),
            p(glue::glue("There are many options available for modelling the parent ",
                   "fraction. For most tracers, a good default option is the ",
                   "`Fit Individually: Choose the best-fitting model` option, ",
                   "which will choose the model which fits best on average, and ",
                   "applies that model to all of the data. ",
                   "Hierarchical models (more to come) are best left for experienced users.  ")),
            
            selectInput(inputId = "pf_model",
                        label = "Parent fraction model",
                        choices=c("Interpolation",
                                  "Fit Individually: Choose the best-fitting model",
                                  "Fit Individually: Hill",
                                  "Fit Individually: Exponential",
                                  "Fit Individually: Power",
                                  "Fit Individually: Sigmoid",
                                  "Fit Individually: Inverse Gamma",
                                  "Fit Individually: Gamma",
                                  "Fit Individually: GAM",
                                  "Fit Hierarchically: HGAM"),
                        selected = "Interpolation", multiple = FALSE),
            checkboxInput(inputId = "pf_set_t0",
                          label = "Set to 100% at time 0",
                          value = TRUE),
            h4("Time subsetting"),
            div(style="display:inline-block",textInput(inputId="pf_starttime", label="from (min)", value = 0)),
            div(style="display:inline-block",textInput(inputId="pf_endtime", label="to (min)", value = Inf)),
            br(),
            h4("Additional Modelling Options"),
            textInput(inputId = "pf_k",
                      label = "GAM dimension of the basis (k)",
                      value = "6"),
            p(div(HTML("<em>This value must sometimes be reduced when there are too few data points, or increased for extra wiggliness.</em>")),
              style = "font-size:12px;"
            ),
            textInput(inputId = "pf_hgam_opt",
                      label = "HGAM Smooth Formula",
                      value = "s(log(time), k=8) + s(log(time), pet, bs='fs', k=5)"),
            p(div(HTML("<em>Use any of the subsetting attributes, as well as measurement (pet).  ",
                       "Note: it is recommended to log-transform time for best results. e.g. s(log(time), k=8) + s(log(time), pet, bs='fs', k=5) </em>")))
          ),
          
          tabPanel("Blood-to-Plasma Ratio",
                   
            h4("Blood-to-Plasma Ratio Model Selection"),
            p(glue::glue("There are not so many common models for the BPR. ",
                   "When the BPR is clearly constant or linear, use ",
                   "the relevant option. ",
                   "For most tracers, with a more complex function, ",
                   "a good default option is the ",
                   "`Fit Individually: GAM` option, ",
                   "which will fit a smooth generalised additive model ",
                   "to each curve independently. ",
                   "Hierarchical models are best left for experienced users.  ")),
            
            selectInput(inputId = "bpr_model",
                        label = "BPR model",
                        choices=c("Interpolation",
                                  "Fit Individually: Constant",
                                  "Fit Individually: Linear",
                                  "Fit Individually: GAM",
                                  "Fit Hierarchically: HGAM"),
                        selected = "Interpolation",
                        multiple = FALSE),
            br(),
            h4("Time subsetting"),
            div(style="display:inline-block",textInput(inputId="bpr_starttime", label="from (min)", value = 0)),
            div(style="display:inline-block",textInput(inputId="bpr_endtime", label="to (min)", value = Inf)),
            br(),
            h4("Additional Modelling Options"),
            textInput(inputId = "bpr_k",
                      label = "GAM dimension of the basis (k)",
                      value = "6"),
            p(div(HTML("<em>This value must sometimes be reduced when there are too few data points, or increased for extra wiggliness.</em>")),
              style = "font-size:12px;"
            ),
            textInput(inputId = "bpr_hgam_opt",
                      label = "HGAM Smooth Formula",
                      value = "s(time, k=8) + s(time, pet, bs='fs', k=5)"),
            p(div(HTML("<em>Use any of the subsetting attributes, as well as measurement (pet), e.g. s(time, k=8) + s(time, pet, bs='fs', k=5)</em>")))
          ),
          
          tabPanel("Arterial Input Function",
                   
            h4("Arterial Input Function Model Selection"),
            p(glue::glue("Models for the AIF should be used with caution as they ",
                   "can easily underfit the data for minimal gains in performance.")),
            
            selectInput(inputId = "aif_model",
                        label = "AIF model",
                        choices=c("Interpolation",
                                  "Fit Individually: Linear Rise, Triexponential Decay",
                                  "Fit Individually: Feng",
                                  "Fit Individually: FengConv",
                                  "Fit Individually: Splines"),
                        selected = "Interpolation",
                        multiple = FALSE),
            h4("Time subsetting"),
            div(style="display:inline-block",textInput(inputId="aif_starttime", label="from (min)", value = 0)),
            div(style="display:inline-block",textInput(inputId="aif_endtime", label="to (min)", value = Inf)),
            h4("Additional Parametric Modelling Options"),
            p("expdecay_props: What proportions of the decay should be used for ",
              "choosing starting parameters for the exponential decay. Leave blank ",
              "for default."),
            div(style="display:inline-block",textInput(inputId="aif_expdecay_1", label="expdecay_props[1]", value = "")),
            div(style="display:inline-block",textInput(inputId="aif_expdecay_2", label="expdecay_props[2]", value = "")),
            textInput(inputId = "aif_inftime",
                      label = "Injection infusion duration (sec)",
                      value = ""),
            p(div(HTML("<em>Required for FengConv: either the number of seconds if known (e.g. 30), or the range if unknown, e.g. 25;35.</em>")),
              style = "font-size:12px;"),
            br(),
            h4("Additional Spline Modelling Options"),
            p(glue::glue("Depending on the number of samples and the wiggliness of the curve, some of the ",
                   "k values may need to be altered.")),
            div(style="display:inline-block",textInput(inputId="aif_kb",   label="k before the peak", value = "")),
            div(style="display:inline-block",textInput(inputId="aif_ka_a", label="k after the peak (auto)", value = "")),
            div(style="display:inline-block",textInput(inputId="aif_ka_m", label="k after the peak (manual)", value = "")),
            br(),
            h4("Weighting Options for AIF Fitting"),
            p(glue::glue("These options control how the AIF models are weighted during fitting. ",
                   "Proper weighting can improve model fits, especially for parametric models.")),
            
            selectInput(inputId = "aif_weightscheme",
                        label = "Weight scheme",
                        choices = list("Uniform weighting" = 1,
                                       "Time/activity weighting (Method 2)" = 2),
                        selected = 2,
                        multiple = FALSE),
            
            checkboxInput(inputId = "aif_method_weights",
                          label = "Method weights",
                          value = TRUE),
            div(p("Divides weights between discrete and continuous samples equally"), 
                style = "font-size:12px; margin-left:20px; margin-top:-10px;"),
            
            checkboxInput(inputId = "aif_taper_weights", 
                          label = "Taper weights",
                          value = TRUE),
            div(p("Gradually trades off between continuous and discrete samples after peak"), 
                style = "font-size:12px; margin-left:20px; margin-top:-10px;"),
            br(),
            
            checkboxInput(inputId = "aif_exclude_manual_during_continuous",
                          label = "Exclude manual samples collected during continuous sampling",
                          value = FALSE),
            div(p("Removes discrete (manual) samples that occur before the last continuous sample for calculating the AIF curve"), 
                style = "font-size:12px; margin-left:20px; margin-top:-10px;")
          ),
          
          tabPanel("Whole Blood",
                   
            h4("Whole Blood Model Selection"),
            p(glue::glue("Models for the whole blood don't tend to make much difference. ",
                   "They are mostly useful when the blood measurements are very noisy, ",
                   "and when brain uptake is so low that the blood makes a big impact.")),
            
            selectInput(inputId = "wb_model",
                        label = "Whole Blood model",
                        choices=c("Interpolation",
                                  "Fit Individually: Splines"),
                        selected = "Interpolation",
                        multiple = FALSE),
            checkboxInput(inputId = "wb_dispcor",
                          label = "Perform dispersion correction on autosampler samples?",
                          value = FALSE),
            checkboxInput(inputId = "wb_exclude_manual_during_continuous",
                          label = "Exclude manual samples collected during continuous sampling",
                          value = FALSE),
            div(p("Removes discrete (manual) samples that occur before the last continuous sample for calculating the whole blood curve"), 
                style = "font-size:12px; margin-left:20px; margin-top:-10px;"),
            h4("Time subsetting"),
            div(style="display:inline-block",textInput(inputId="wb_starttime", label="from (min)", value = 0)),
            div(style="display:inline-block",textInput(inputId="wb_endtime", label="to (min)", value = Inf)),
            br(),
            h4("Additional Spline Modelling Options"),
            p(glue::glue("Depending on the number of samples, some of the ",
                   "k values may need to be reduced from their default ",
                   "of 10")),
            div(style="display:inline-block",textInput(inputId="wb_kb",   label="k before the peak", value = "")),
            div(style="display:inline-block",textInput(inputId="wb_ka_a", label="k after the peak (auto)", value = "")),
            div(style="display:inline-block",textInput(inputId="wb_ka_m", label="k after the peak (manual)", value = ""))
          ),
          
          tabPanel("Download & Run",
                   
            h3("Configuration File"),
            downloadButton('downloadData', 'Download Config File', class = "btn-primary"),
            br(), br(),
            
            # Add pipeline execution section
            conditionalPanel(
              condition = "output.bids_dir_available",
              div(
                h3("Run Pipeline"),
                p("Execute the bloodstream pipeline using the current configuration."),
                div(id = "pipeline_controls",
                    actionButton("run_pipeline", "Run Bloodstream Pipeline", 
                                class = "btn-success btn-lg"),
                    br(), br()
                ),
            ),
            
            # Show message when in standalone mode (no BIDS directory)
            conditionalPanel(
              condition = "!output.bids_dir_available",
              div(
                h3("Config Creation Mode"),
                p("No BIDS directory provided. You can create and download configuration files, but cannot run the pipeline directly from this interface."),
                p("To run the pipeline, use the downloaded config with:", style = "font-family: monospace; background-color: #f8f9fa; padding: 10px; border-left: 3px solid #007bff;"),
                tags$code("bloodstream(studypath, configpath)"), br(), br()
              )
            ),
            
            ),
            
            h4("Current Configuration:"),
            verbatimTextOutput("json_text")
          )
        )
      )
    )
  )
  
  # Define server logic for config file creation ----
  server <- function(input, output, session) {
    
    # Set up directory paths
    derivatives_path <- derivatives_dir %||% (if (!is.null(bids_dir)) file.path(bids_dir, "derivatives") else NULL)
    analysis_path <- if (!is.null(derivatives_path)) file.path(derivatives_path, "bloodstream", analysis_folder) else NULL
    
    # Check if pipeline can be run (need at least bids_dir)
    output$bids_dir_available <- reactive({
      !is.null(bids_dir) && dir.exists(bids_dir)
    })
    outputOptions(output, "bids_dir_available", suspendWhenHidden = FALSE)
    
    # Load existing config if provided and update inputs
    if (!is.null(config_file) && file.exists(config_file)) {
      tryCatch({
        config_data <- jsonlite::fromJSON(config_file)
        cat("Loading config from:", config_file, "\n")
        
        # Update subset inputs  
        updateTextInput(session, "subset_sub", value = config_data$Subsets$sub %||% "")
        updateTextInput(session, "subset_ses", value = config_data$Subsets$ses %||% "")
        updateTextInput(session, "subset_rec", value = config_data$Subsets$rec %||% "")
        updateTextInput(session, "subset_task", value = config_data$Subsets$task %||% "")
        updateTextInput(session, "subset_run", value = config_data$Subsets$run %||% "")
        updateTextInput(session, "subset_tracer", value = config_data$Subsets$TracerName %||% "")
        updateTextInput(session, "subset_modeadmin", value = config_data$Subsets$ModeOfAdministration %||% "")
        updateTextInput(session, "subset_institute", value = config_data$Subsets$InstitutionName %||% "")
        updateTextInput(session, "subset_pharmaceutical", value = config_data$Subsets$PharmaceuticalName %||% "")
        
        # Update Parent Fraction inputs
        updateSelectInput(session, "pf_model", selected = config_data$Model$ParentFraction$Method %||% "Interpolation")
        updateCheckboxInput(session, "pf_set_t0", value = config_data$Model$ParentFraction$set_ppf0 %||% TRUE)
        updateTextInput(session, "pf_starttime", value = as.character(config_data$Model$ParentFraction$starttime %||% 0))
        updateTextInput(session, "pf_endtime", value = as.character(config_data$Model$ParentFraction$endtime %||% Inf))
        updateTextInput(session, "pf_k", value = as.character(config_data$Model$ParentFraction$gam_k %||% "6"))
        updateTextInput(session, "pf_hgam_opt", value = config_data$Model$ParentFraction$hgam_formula %||% "")
        
        # Update BPR inputs
        updateSelectInput(session, "bpr_model", selected = config_data$Model$BPR$Method %||% "Interpolation")
        updateTextInput(session, "bpr_starttime", value = as.character(config_data$Model$BPR$starttime %||% 0))
        updateTextInput(session, "bpr_endtime", value = as.character(config_data$Model$BPR$endtime %||% Inf))
        updateTextInput(session, "bpr_k", value = as.character(config_data$Model$BPR$gam_k %||% "6"))
        updateTextInput(session, "bpr_hgam_opt", value = config_data$Model$BPR$hgam_formula %||% "")
        
        # Update AIF inputs
        updateSelectInput(session, "aif_model", selected = config_data$Model$AIF$Method %||% "Interpolation")
        updateTextInput(session, "aif_starttime", value = as.character(config_data$Model$AIF$starttime %||% 0))
        updateTextInput(session, "aif_endtime", value = as.character(config_data$Model$AIF$endtime %||% Inf))
        updateTextInput(session, "aif_expdecay_1", value = as.character(config_data$Model$AIF$expdecay_props[1] %||% ""))
        updateTextInput(session, "aif_expdecay_2", value = as.character(config_data$Model$AIF$expdecay_props[2] %||% ""))
        updateTextInput(session, "aif_inftime", value = paste(config_data$Model$AIF$inftime, collapse = ";"))
        updateTextInput(session, "aif_kb", value = config_data$Model$AIF$spline_kb %||% "")
        updateTextInput(session, "aif_ka_a", value = config_data$Model$AIF$spline_ka_a %||% "")
        updateTextInput(session, "aif_ka_m", value = config_data$Model$AIF$spline_ka_m %||% "")
        updateSelectInput(session, "aif_weightscheme", selected = config_data$Model$AIF$weightscheme %||% 2)
        updateCheckboxInput(session, "aif_method_weights", value = config_data$Model$AIF$Method_weights %||% TRUE)
        updateCheckboxInput(session, "aif_taper_weights", value = config_data$Model$AIF$taper_weights %||% TRUE)
        updateCheckboxInput(session, "aif_exclude_manual_during_continuous", value = config_data$Model$AIF$exclude_manual_during_continuous %||% FALSE)
        
        # Update Whole Blood inputs
        updateSelectInput(session, "wb_model", selected = config_data$Model$WholeBlood$Method %||% "Interpolation")
        updateCheckboxInput(session, "wb_dispcor", value = config_data$Model$WholeBlood$dispcor %||% FALSE)
        updateCheckboxInput(session, "wb_exclude_manual_during_continuous", value = config_data$Model$WholeBlood$exclude_manual_during_continuous %||% FALSE)
        updateTextInput(session, "wb_starttime", value = as.character(config_data$Model$WholeBlood$starttime %||% 0))
        updateTextInput(session, "wb_endtime", value = as.character(config_data$Model$WholeBlood$endtime %||% Inf))
        updateTextInput(session, "wb_kb", value = config_data$Model$WholeBlood$spline_kb %||% "")
        updateTextInput(session, "wb_ka_a", value = config_data$Model$WholeBlood$spline_ka_a %||% "")
        updateTextInput(session, "wb_ka_m", value = config_data$Model$WholeBlood$spline_ka_m %||% "")
        
      }, error = function(e) {
        cat("Error loading config file:", e$message, "\n")
      })
    }
    
    # Reactive expression to generate the config file ----
    config_json <- reactive({
      
      Subsets <- list(
        sub = input$subset_sub,
        ses = input$subset_ses,
        rec = input$subset_rec,
        task = input$subset_task,
        run = input$subset_run,
        TracerName = input$subset_tracer,
        ModeOfAdministration = input$subset_modeadmin,
        InstitutionName = input$subset_institute,
        PharmaceuticalName = input$subset_pharmaceutical
      )
      
      ParentFraction <- list(
        Method = input$pf_model,
        set_ppf0 = input$pf_set_t0,
        starttime = as.numeric(input$pf_starttime),
        endtime  = as.numeric(input$pf_endtime),
        gam_k = input$pf_k,
        hgam_formula = input$pf_hgam_opt
      )
      
      BPR <- list(
        Method = input$bpr_model,
        starttime = as.numeric(input$bpr_starttime),
        endtime  = as.numeric(input$bpr_endtime),
        gam_k = as.numeric(input$bpr_k),
        hgam_formula = input$bpr_hgam_opt
      )
      
      AIF <- list(
        Method = input$aif_model,
        starttime = as.numeric(input$aif_starttime),
        endtime  = as.numeric(input$aif_endtime),
        expdecay_props = as.numeric(c(input$aif_expdecay_1,
                                      input$aif_expdecay_2)),
        inftime = as.numeric(stringr::str_split(input$aif_inftime, pattern = ";")[[1]]),
        spline_kb = input$aif_kb,
        spline_ka_m = input$aif_ka_m,
        spline_ka_a = input$aif_ka_a,
        weightscheme = as.numeric(input$aif_weightscheme),
        Method_weights = input$aif_method_weights,
        taper_weights = input$aif_taper_weights,
        exclude_manual_during_continuous = input$aif_exclude_manual_during_continuous
      )
      
      WholeBlood <- list(
        Method = input$wb_model,
        dispcor = input$wb_dispcor,
        exclude_manual_during_continuous = input$wb_exclude_manual_during_continuous,
        starttime = as.numeric(input$wb_starttime),
        endtime  = as.numeric(input$wb_endtime),
        spline_kb = input$wb_kb,
        spline_ka_m = input$wb_ka_m,
        spline_ka_a = input$wb_ka_a
      )
      
      config_list <- list(
        Subsets = Subsets,
        Model = list(
          ParentFraction = ParentFraction,
          BPR = BPR,
          AIF = AIF,
          WholeBlood = WholeBlood
        )
      )
      
      jsonlite::toJSON(config_list, pretty=TRUE)
    })
    
    # Download handler - save to analysis directory only when bids_dir is provided
    output$downloadData <- downloadHandler(
      filename = function() {
        config_name <- generate_new_filename()
        if (!is.null(bids_dir) && !is.null(analysis_path)) {
          # Create analysis directory if it doesn't exist
          if (!dir.exists(analysis_path)) {
            dir.create(analysis_path, recursive = TRUE)
          }
          # Return just the filename, but save to analysis path in content function
          config_name
        } else {
          config_name
        }
      },
      content = function(con) {
        config_text <- config_json()
        if (!is.null(bids_dir) && !is.null(analysis_path)) {
          # Save to analysis directory
          config_file_path <- file.path(analysis_path, basename(con))
          writeLines(text = config_text, con = config_file_path)
          cat("Config saved to:", config_file_path, "\n")
        }
        # Always provide download
        writeLines(text = config_text, con = con)
      }
    )
    
    # Pipeline execution
    
    observeEvent(input$run_pipeline, {
      if (!is.null(bids_dir) && dir.exists(bids_dir)) {
        
        # Show processing notification that stays visible during processing
        processing_id <- showNotification("Running bloodstream...", 
                        type = "message", duration = NULL, id = "processing_pipeline")
        
        # Save config to temporary file
        temp_config_file <- tempfile(fileext = ".json")
        writeLines(config_json(), temp_config_file)
        
        # Run pipeline in background
        tryCatch({
          
          # Run the pipeline
          result <- bloodstream(bids_dir = bids_dir, configpath = temp_config_file, 
                               derivatives_dir = derivatives_dir, analysis_foldername = analysis_folder)
          
          # Remove processing notification and show success
          removeNotification("processing_pipeline")
          showNotification(HTML("Pipeline completed successfully!<br>Check the output to ensure fitting was successful.<br>App will close in 3 seconds..."), 
                          type = "message", duration = 5)
          
          # Clean up temp file
          unlink(temp_config_file)
          
          # Auto-close the app after successful completion
          later::later(function() {
            cat("Auto-closing Shiny app after successful pipeline completion...\n")
            stopApp()
          }, delay = 3)
          
        }, error = function(e) {
          # Remove processing notification on error
          removeNotification("processing_pipeline")
          showNotification(paste("Pipeline failed with error:", e$message), 
                          type = "error", duration = 10)
          unlink(temp_config_file)
        })
      }
    })
    
    
    # Display current config
    output$json_text <- renderText({ config_json() })
    
    # Handle session disconnect - stop app when browser is closed
    session$onSessionEnded(function() {
      cat("Browser session ended. Stopping app...\n")
      stopApp()
    })
  }
  
  # Run the application
  cat("Starting bloodstream configuration app...\n")
  if (!is.null(bids_dir)) {
    cat("BIDS directory:", bids_dir, "\n")
  }
  if (!is.null(derivatives_dir)) {
    cat("Derivatives directory:", derivatives_dir, "\n")
  }
  if (!is.null(config_file)) {
    cat("Loading config file:", config_file, "\n")
  }
  cat("Analysis folder:", analysis_folder, "\n")
  cat("App will be available at: http://", host, ":", port, "\n", sep = "")
  
  
  # Create the application (following kinfitr_app pattern)
  app <- shiny::shinyApp(ui = ui, server = server)
  
  cat("If running from within a docker container, open one of the following addresses in your web browser.\n")
  cat("http://localhost:", port, "\n", sep = "")
  cat("NOTE: If you are having issues accessing the web app, please check that you have included the port mapping (-p ", port, ":", port, ") in your Docker command.\n\n", sep = "")

  # Launch using runApp (more reliable in Docker)
  cat("Launching app...\n")
  shiny::runApp(app, host = host, port = port)
}
# https://jugabus.shinyapps.io/entrega_shiny_julio_garcia_bustos/


library(shiny)
library(shinythemes)
library(ggplot2)
library(dplyr)
library(tidyr)
library(DT)
library(plotly)


ui <- navbarPage(theme = shinytheme("yeti"), "App Máster Ciencia de Datos",
                 
                 
                 tags$head(
                   includeCSS("styles.css")  
                 ),
                 
                 tabPanel("Selección de máquina", 
                          sidebarLayout(
                            sidebarPanel(
                              h5("MÁQUINA"), 
                              fileInput("DatosFichero", "Selecciona un fichero"),
                              uiOutput("select_matricula"),
                            ),
                            mainPanel(
                              h5("Probabilidad de orden"), 
                              plotOutput('graf1')
                            )
                          )
                 ),
                 
                 navbarMenu("Estado de la máquina",
                            tabPanel("Evolución temporal alarmas", 
                                     sidebarLayout(
                                       sidebarPanel(
                                         h5("Filtrar por estado de alarma"),
                                         radioButtons("estado_alarma1", "Selecciona estado de alarma", 
                                                      choices = c("Activas" = "activa", "Inactivas" = "inactiva")),
                                         h5("Selecciona una alarma"),
                                         uiOutput("select_alarmas_radio")
                                       ),
                                       mainPanel(
                                         h5("Evolución temporal alarmas"), 
                                         plotlyOutput('graf2')
                                       )
                                     )
                            ),
                            tabPanel("Registros de la máquina", 
                                     sidebarLayout(
                                       sidebarPanel(
                                         h5("Filtrar por estado de alarma"),
                                         radioButtons("estado_alarma2", "Selecciona estado de alarma", 
                                                      choices = c("Activas" = "activa", "Inactivas" = "inactiva")),
                                         uiOutput("select_alarmas_check") 
                                       ),
                                       mainPanel(h5("Registros de la máquina seleccionada"), dataTableOutput('tabla1'))
                                     )
                            )
                 ),
                 
                 tabPanel("Estadísticas Globales Temporales", 
                          sidebarLayout(
                            sidebarPanel(
                              h5("PERIODO Y ESTADÍSTICAS"), 
                              dateRangeInput('rango_fecha', label = 'Selecciona el periodo', 
                                             min = '2016-01-01', max = '2025-02-13', 
                                             start = '2016-01-02', end = '2016-12-14', 
                                             format = "yyyy-mm-dd", separator= "a"),
                              h5("SELECCIONAR ALARMA"), 
                              uiOutput("select_alarma_hist"), 
                              radioButtons("tipo_grafico", "Seleccionar tipo de gráfico:", 
                                           choices = c("Histograma" = "hist", "Boxplot" = "boxplot")),
                              conditionalPanel(
                                condition = "input.tipo_grafico == 'hist'",
                                sliderInput("slider1", label = "Número de bins del histograma", 
                                            min = 1, max = 10, value = 5, step = 1)
                              ),
                              conditionalPanel(
                                condition = "input.tipo_grafico == 'boxplot'",
                                checkboxInput("Caja1", "Todas las máquinas", value = FALSE)
                              )
                            ),
                            mainPanel(
                              conditionalPanel(
                                condition = "input.tipo_grafico == 'hist'",
                                h5("Histograma de la alarma seleccionada"),
                                plotOutput('hist1')
                              ),
                              conditionalPanel(
                                condition = "input.tipo_grafico == 'boxplot'",
                                h5("Boxplot de la alarma seleccionada"),
                                plotOutput('boxplot1')
                              )
                            )
                          )
                 )
)

server <- function(input, output, session) {
  
  df_react <- reactive({
    req(input$DatosFichero)
    
    extension <- tools::file_ext(input$DatosFichero$name)
    

    if (extension != "Rdata") {
      showModal(modalDialog(
        title = "Formato de archivo incorrecto",
        "El archivo proporcionado debe tener la extensión .Rdata.",
        easyClose = TRUE,
        footer = NULL
      ))
      return(NULL) 
    }
    
    load(input$DatosFichero$datapath)  
    return(Datos)  
  })
  

  output$select_matricula <- renderUI({
    datos <- df_react()
    selectInput("Selectbox1", "Selecciona máquina", choices = unique(datos$matricula))
  })
  
  df_maq <- reactive({
    datos <- df_react()
    req(input$Selectbox1)
    datos %>% filter(matricula == input$Selectbox1)
  })
  
  
  
  output$graf1 <- renderPlot({
    df_maq() %>% 
      ggplot(aes(dia, p_orden, colour = p_orden)) + 
      geom_point() + geom_line() + 
      scale_color_gradient(low = "blue", high = "red") + 
      labs(title = "Evolución de la probabilidad de orden", x = "Día", y = "Probabilidad de orden") +
      theme_minimal()
  })
  
  output$select_alarmas_radio <- renderUI({
    datos <- df_maq()
    req(input$estado_alarma1)
    
    if (input$estado_alarma1 == "activa") {
      alarmas <- names(datos)[grep('^a.', names(datos))] %>% 
        Filter(function(col) any(datos[[col]] == 1, na.rm = TRUE), .)
    } else {
      alarmas <- names(datos)[grep('^a.', names(datos))] %>% 
        Filter(function(col) all(datos[[col]] == 0, na.rm = TRUE), .)
    }
    
    radioButtons("radiobuttons1", "Selecciona la alarma a visualizar", choices = alarmas)
  })
  
  output$select_alarmas_check <- renderUI({
    datos <- df_maq()
    req(input$estado_alarma2)
    
    if (input$estado_alarma2 == "activa") {
      alarmas <- names(datos)[grep('^a.', names(datos))] %>% 
        Filter(function(col) any(datos[[col]] == 1, na.rm = TRUE), .)
    } else {
      alarmas <- names(datos)[grep('^a.', names(datos))] %>% 
        Filter(function(col) all(datos[[col]] == 0, na.rm = TRUE), .)
    }
    
    checkboxGroupInput("GrupoCajas1", "Selecciona las alarmas para ver en la tabla", choices = alarmas, inline = FALSE)
  })
  
  output$graf2 <- renderPlotly({
    datos <- df_maq()
    req(input$radiobuttons1)  
    
    datos_filtrados <- datos %>% filter(!is.na(.data[[input$radiobuttons1]]))
    
    p <- ggplot(datos_filtrados, aes(x = dia, y = .data[[input$radiobuttons1]])) + 
      geom_point() + 
      geom_line() +
      theme_minimal() +
      labs(title = "Gráfico de Alarma", x = "Día", y = input$radiobuttons1)
    
    ggplotly(p)
  })
  
  
  output$tabla1 <- renderDataTable({
    req(df_react(), input$Selectbox1, input$GrupoCajas1)
    subset(df_react(), matricula == input$Selectbox1, select = c("matricula", "dia", input$GrupoCajas1, "p_orden"))
  })
  
  output$select_alarma_hist <- renderUI({
    datos <- df_react()
    alarmas <- grep('^a.', colnames(datos), value = TRUE)
    selectInput("Selectbox2", "Alarma", choices = alarmas)
  })
  
  datos_alarma <- reactive({
    req(input$Selectbox2, input$rango_fecha)
    df_maq() %>% 
      filter(dia >= input$rango_fecha[1], dia <= input$rango_fecha[2]) %>% 
      select(.data[[input$Selectbox2]]) %>% 
      drop_na()
  })
  
  output$hist1 <- renderPlot({
    req(input$Selectbox2, input$rango_fecha)
    datos <- datos_alarma()
    
    ggplot(datos, aes(x = .data[[input$Selectbox2]])) + 
      geom_histogram(binwidth = diff(range(datos[[input$Selectbox2]]))/input$slider1, 
                     fill = "steelblue", color = "black", alpha = 0.7)
  })
  
  output$boxplot1 <- renderPlot({
    req(input$rango_fecha, input$Selectbox2)
    datos <- df_react() %>%
      filter(dia >= input$rango_fecha[1], dia <= input$rango_fecha[2]) %>%
      select(matricula, dia, .data[[input$Selectbox2]]) %>%
      drop_na()
    
    if (input$Caja1) {
      ggplot(datos, aes(x = matricula, y = .data[[input$Selectbox2]])) + 
        geom_boxplot(fill = "steelblue", color = "black", alpha = 0.7) +
        labs(title = paste("Boxplots de", input$Selectbox2, "para todas las máquinas"), 
             x = "Máquina", y = input$Selectbox2) +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 90, hjust = 1))
    } else {
      datos %>% ggplot(aes(y = .data[[input$Selectbox2]])) + 
        geom_boxplot(fill = "steelblue", color = "black", alpha = 0.7) +
        labs(title = paste("Boxplot de", input$Selectbox2, "para la máquina seleccionada"), 
             x = "", y = input$Selectbox2) +
        theme_minimal()
    }
  })
  
}



shinyApp(ui, server)
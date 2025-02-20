# install.packages(c("shiny", "shinydashboard", "DT", "sodium", "RPostgreSQL", "DBI", "shinyjs", "shinyauthr", "here"))

library(shiny)
library(shinydashboard)
library(DT)
library(shinyjs)
library(sodium)
library(here)

rm(list=ls())
#setwd(here::here())
setwd("/Users/emericmellet/Desktop/Local /SEAL_DB.Parent/SEAL_DB.Rapp")

# Main login screen
loginpage <- div(id = "loginpage", style = "width: 500px; max-width: 100%; margin: 0 auto; padding: 20px;",
                 wellPanel(
                   tags$h2("LOG IN", class = "text-center", style = "padding-top: 0;color:#333; font-weight:600;"),
                   img(src = "https://github.com/hxr303/S.E.A.L.-Database/blob/main/FlogoBN.jpg?raw=true", width = "200px", height = "160px", style = "display: block; margin: 0 auto;"),
                   textInput("userName", placeholder="Username", label = tagList(icon("user"), "Username")),
                   passwordInput("passwd", placeholder="Password", label = tagList(icon("unlock-alt"), "Password")),
                   br(),
                   div(
                     style = "text-align: center;",
                     actionButton("login", "SIGN IN", style = "color: white; background-color:#3c8dbc;
                                 padding: 10px 15px; width: 150px; cursor: pointer;
                                 font-size: 18px; font-weight: 600;"),
                     shinyjs::hidden(
                       div(id = "nomatch",
                           tags$p("Incorrect username or password!",
                                  style = "color: red; font-weight: 600; 
                                            padding-top: 5px;font-size:16px;", 
                                  class = "text-center"))),
                     br(),
                     br(),
                     tags$code("Username: Admin  Password: pass"),
                     br(),
                     tags$code("Username: Viewer  Password: sightseeing"),
                     br(),
                     tags$code("Username: Guest (Create account, not available now)  Password: 123")
                     
                   ))
)

credentials = data.frame(
  username_id = c("Admin", "Viewer", "Guest"),
  passod   = sapply(c("pass", "sightseeing", "123"),password_store),
  permission  = c("advanced", "basic", "none"), 
  stringsAsFactors = FALSE
)

header <- dashboardHeader( title = "S.E.A.L Database",
                           tags$li(
                             class = "dropdown",
                             style = "padding: 8px;",
                             shinyauthr::logoutUI("logout")
                           ),
                           tags$li(
                             class = "dropdown",
                             tags$a(
                               icon("github"),
                               href = "https://github.com/SlippyRicky/SEAL-DB.git",
                               title = "SEAL-DB"
                             )))


sidebar <- dashboardSidebar(uiOutput("sidebarpanel")) 
body <- dashboardBody(shinyjs::useShinyjs(), uiOutput("body"))
ui<-dashboardPage(header, sidebar, body, skin = "blue")


slidenames <- read.csv("SlideNames.csv")
slidenames.vector <- unique(slidenames$Slide.Name)


server <- function(input, output, session) {
  
  
  login = FALSE
  USER <- reactiveValues(login = login)
  
  observe({ 
    if (USER$login == FALSE) {
      if (!is.null(input$login)) {
        if (input$login > 0) {
          Username <- isolate(input$userName)
          Password <- isolate(input$passwd)
          if(length(which(credentials$username_id==Username))==1) { 
            pasmatch  <- credentials["passod"][which(credentials$username_id==Username),]
            pasverify <- password_verify(pasmatch, Password)
            if(pasverify) {
              USER$login <- TRUE
            } else {
              shinyjs::toggle(id = "nomatch", anim = TRUE, time = 1, animType = "fade")
              shinyjs::delay(3000, shinyjs::toggle(id = "nomatch", anim = TRUE, time = 1, animType = "fade"))
            }
          } else {
            shinyjs::toggle(id = "nomatch", anim = TRUE, time = 1, animType = "fade")
            shinyjs::delay(3000, shinyjs::toggle(id = "nomatch", anim = TRUE, time = 1, animType = "fade"))
          }
        } 
      }
    }})    
  
  output$logoutbtn <- renderUI({
    req(USER$login)
    tags$li(a(icon("fa fa-sign-out"), "Logout", 
              href="javascript:window.location.reload(true)"),
            class = "dropdown", 
            style = "background-color: #eee !important; border: 0;
                    font-weight: bold; margin:5px; padding: 10px;")
  })
  
  
  output$sidebarpanel <- renderUI({
    if (USER$login == TRUE) {
      user_permission <- credentials[credentials$username_id == isolate(input$userName), "permission"]
      
      menuItems <- list()
      
      if (user_permission %in% c("none")) {
        menuItems <- c(menuItems, list(menuItem("Create account", tabName = "create_account", icon = icon("user"))))
      }
      if (user_permission %in% c("basic")) {
        menuItems <- c(
          menuItems,
          list(menuItem("Search", tabName = "search_db", icon = icon("search"))),
          list(menuItem("About", tabName = "about", icon = icon("info-circle")))
        )
      }
      if (user_permission %in% c("advanced")) {
        menuItems <- c(
          menuItems,
          list(menuItem("Welcome", tabName = "welcome_tab", icon = icon("home"))),
          list(menuItem("Search", tabName = "search_tab", icon = icon("search"))),
          list(menuItem("Download", tabName = "download_tab", icon = icon("download"))),
          list(menuItem("Update", tabName = "update_tab", icon = icon("exchange-alt"))),
          list(menuItem("Create Account", tabName = "create_account", icon = icon("user")))
        )
      }
      
      sidebarMenu(menuItems)
    }
  })
  
  
  output$body <- renderUI({
    if (USER$login == TRUE ) {
      tabItems(
        tabItem(tabName = "welcome_tab",
                fluidPage(
                  titlePanel("Image Viewer"),
                  p("This database currently contains bone
                    images from six species distributed
                    across three families within the suborder
                    Pinnipedia. The families present are Phocidae (fur seals and
                    sea lions), Odobenidae (walruses) and Phocidae (fur seals)
                    [1], [2]."),
                  
                  fluidRow(
                    box(
                      selectInput("image", "Select an Image:",
                                  choices = NULL,
                                  selected = NULL)
                    ),
                    box(
                      imageOutput("selectedImage")
                    )
                  )
                )
        ),
        
        tabItem(tabName = "search_tab",
                h2("Search"),
                fluidRow(
                  box(
                    status = "primary",
                    solidHeader = TRUE,
                    width = 12,
                    textInput("search_input", label = "Enter search words", value = ""),
                    actionButton("search_button", "Search")
                  )
                ),
                fluidRow(
                  box(
                    title = "Search Results",
                    status = "primary",
                    solidHeader = TRUE,
                    width = 12,
                    DTOutput("search_result"),
                    textOutput("error")
                  )
                )
        ),
        
        tabItem(tabName = "download_tab",
                fluidPage(
                  titlePanel("Download Data"),
                  p("This section allows you to download data from the database. Customize this UI as needed."),
                  fluidRow(
                    box(
                      title = "Select Download Options",
                      status = "primary",
                      solidHeader = TRUE,
                      width = 12,
                      textInput("search_input", label = "Enter search key",
                                value = "", placeholder = " your search key "),
                      selectInput("download_option", "Select Download Option",
                                  choices = c("Server 1", "Server 2", "Server 3")),
                      downloadButton("download_data_btn", "Download Data")
                    )
                  )
                )
        ),
        
        tabItem(tabName = "update_tab",
                fluidPage(
                  titlePanel("Update Data"),
                  p("This section allows you to update data in the database.
                    Customize this UI as needed."),
                  fluidRow(
                    box(
                      title = "Update Table",
                      status = "primary",
                      solidHeader = TRUE,
                      width = 12,
                      DTOutput("update_table")
                    )
                  )
                )
        ),
        
        tabItem(tabName = "create_account",
                h2("Create Account"),
                textInput("new_username", "Username"),
                passwordInput("new_password", "Password",
                              placeholder = "Beware of the password you use"),
                passwordInput("confirm_password", "Confirm Password"),
                textInput("additional_comments", "Additional Comments",
                          placeholder = "Please write name and student ID
                          if applicable"),
                actionButton("create_account_btn", "Create Account")
        )
      )
      
    }
    
    else {loginpage}
    
  })
  
  output$selectedImage <- renderImage({
    # Path to directory containing images
    img_dir <- "www/"
    
    # Full file path to the selected (.png added to the end of the names specified in the vector)
    img_path <- file.path(img_dir, paste0(input$image, ".png"))
    
    # Render the selected image
    list(src = img_path, 
         alt = "Selected Image",
         width = "100%")
  }, deleteFile = FALSE) # The file is stored in the UI once loaded (?)
  
  observe({
    updateSelectInput(session, "image", choices = slidenames.vector)
  })
  
  output$results <- DT::renderDataTable({
    datatable(iris, options = list(autoWidth = TRUE,
                                   searching = FALSE))
  })
  
  output$results2 <- DT::renderDataTable({
    datatable(mtcars, options = list(autoWidth = TRUE,
                                     searching = FALSE))
  })
}


shinyApp(ui = ui, server = server)


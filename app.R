library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "BugSigDBAssistant",
  sidebar = sidebar(
    p("Under construction")
  ),
  p("Coming soon")
)

server <- function(input, output, session) {}

shinyApp(ui, server)

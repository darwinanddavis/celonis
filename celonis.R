pacman::p_load(networkD3,dplyr,jsonlite,ggplot2,colorspace,readr,stringr,scales)
fh <- "songs.json"
df <- jsonlite::fromJSON(fh)

# plot ----------------------------------------------------------
xlab <- "Decade"
ylab <- "Country"
ttl <- "Top 20 songs"  
subttl <- "Per decade by country"
caption <- "Matt Malishev | @darwinanddavis"

df %>% glimpse

# scatter facet
ggplot() +
  geom_point(data = df, aes(loudness,energy, size = tempo/10, col = tempo)) +
  facet_wrap(~Decade)

ggplot() +
  geom_point(data = df, aes(loudness,energy, size = tempo/10, col = Country %>% as.factor())) 

ggplot() +
  geom_point(data = df, aes(energy,liveness, size = tempo/10, col = Country %>% as.factor())) 



# column 
df %>% glimpse
ranked <- df %>% 
  group_by(Country) %>% 
  mutate("yy" = Rank %>% sort
  )
colpal <- sequential_hcl(df$Decade %>% unique %>% length,
                         "Purple-Orange")
opac <- 0.7
ggplot() +
  geom_col(data = ranked, 
           aes(Country, yy, fill = Decade %>% as.factor(), col = Decade %>% as.factor())) +
  coord_flip() +
  facet_wrap(~Decade,nrow = 1) +
  scale_fill_manual(name = ttl, values = adjustcolor(colpal,opac), aesthetics = c("col","fill")) +
  my_theme() 

# save
fh <- "p1"
my_save(fh) # save to dir 

# save ordinal colpal to file  
sequential_hcl(df$Artist %>% unique %>% length,
               "Purple-Orange") %>% 
  write_lines(sep = "','", here::here("colpal.txt"))



# plots  --------------------------------------------------------

# devtools::install_github("jcheng5/d3scatter")
# devtools::install_github("kent37/summarywidget")
pacman::p_load(d3scatter,crosstalk,leaflet,tibble,httpuv,summarywidget,DT,scatterD3)

var1 <- "Rank"
colt <- "#5B3794"
colf <- "#F8DCD9"
df$colpal <- sequential_hcl(df[,var1] %>% length,"Purple-Orange")
sd <- SharedData$new(df)

# scale fill for d3scatter()
# colpald3 <- scale_fill_selection(colf, colt)
# colpald3 <- scale_color_selection(colf, colt)

bscols(widths = 
         # c(12,rep(5,2)),
         c(12,rep(4,1)),
       # c(12,12,c(2,6)), # 1 full row, 1 full row, 2 rows 6 cols
       
       list(
         filter_slider("rank", "Rank", sd, ~Rank, step = 1),
         filter_checkbox("Decade", "Decade", sd, ~paste0(Decade,"'s") %>% sort, inline = T)
       ),
       d3scatter(sd, ~energy, ~danceability, color = c(rep.int(c(colt,colf),times = 99/2),colt) %>% as.factor(),
                 width = "100%", height = 400),
      
       # scatterD3(data = sd$data(), x = energy, y = danceability,key_var = Rank),
       
       # list(
         d3scatter(sd, ~energy, ~tempo, ~Rank,
                   # x_lim = range(mtcars$hp), y_lim = range(mtcars$mpg),
                   width = "100%", height = 200),
         d3scatter(sd, ~energy, ~danceability, ~Rank,
                   # x_lim = range(mtcars$hp), y_lim = range(mtcars$mpg),
                   width = "100%", height = 200)
       # )
       ,
       datatable(sd, rownames = F,
                 class="compact", extensions="Scroller",
                 options=list(deferRender=T, scrollY = 200, scrollX = 10 , scroller=T,
                              pageLength = 5, autoWidth = T),
                 style = "bootstrap",
                 width = "100%", height = 200)
)

colv <- colorRampPalette(colors = c("#FF0100","#790086","#0000FF"))
colv(sd$data()[,"Rank"] %>% length) %>% 
write_lines(sep = "','", here::here("colpal2.txt"))



# changes in app_demo.js from d3 template to match songs.json data ------------------------------------
"/Users/malishev/Documents/programs/d3/data/movies.csv" %>% 
  read_csv %>% glimpse

# d3 barchart
df %>% glimpse
df$Decade %>% unique

revenue = energy
budget = tempo
popularity = danceability
genre = Country
title = Artist
release_date = Decade
release_year = City
runtime = Rank
tagline = Name



# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# leaflet -------------------------------------------------------
pacman::p_load(htmltools,geosphere,leaflet,rnaturalearthdata,rnaturalearth,mapdata,sf)

# metric to map   
var1 <- "Rank"
tt <- paste0("Top songs by artist according to ",var1, " (1960 - 2000)") # title 

# colpal <- sequential_hcl(6,"ag_GrnYl")
colt <- "#5B3794"
colf <- "#F8DCD9"
colp <- colorRampPalette(colors = c(colt, "#FFFFFF", colf))
colpal <- colp(df %>% pull(var1) %>% unique %>% length)
colv <- colpal[1]
scales::show_col(colpal,labels = F)

# world data
data(world.cities) # /maps
world_cities <- world.cities 

ic <- df$Country %>% unique
mp <- ne_countries(scale = "medium", returnclass = "sf") %>% 
  filter(name %in% ic) %>% 
  rename("Country" = name) %>% 
  left_join(sd$data(), by = "Country")

# leaflet colpal
pal <- colorNumeric(
  palette = colpal,
  domain = mp %>% pull(var1)
)


# leaflet
setview <- c(0,0)
custom_tile <- "http://d.sm.mapstack.stamen.com/((darkmatter,$00ffff[hsl-color]),(mapbox-water,$00589c[hsl-color]),(parks,$ff9a30[source-in]))/{z}/{x}/{y}.png"
par(bg="black")
opac <- 1
mp_scores <- mp %>% pull(var1)
mp_names <- mp %>% pull(Country)

# style

# text labels 
style <- list(
  "color" = colv,
  "font-weight" = "normal",
  "padding" = "8px"
)
layer_options <- layersControlOptions(collapsed = F)
text_label_opt <- labelOptions(noHide = F, direction = "top", textsize = "15px",
                               textOnly = F, opacity = 0.7, offset = c(0,0),
                               style = style, permanent = T
)

# popup
popup_func <- function(d) paste0("<strong>",d %>% pull(Country),"</strong><br/><br/>","<strong>",var1,"</strong><br/><span style=color:",mp %>% pull(colpal),";>", d %>% pull(var1),"</span><br/>") %>% purrr::map(htmltools::HTML)

# titles
ttl <- paste0("<div style=\"color:",colv,";\"> 
              ",tt,"
              </div>")

map_title <- tags$style( 
  HTML(".leaflet-control.map-title { 
       transform: translate(-50%,-20%);
       position: fixed !important;
       left: 50%;
       text-align: center;
       padding-left: 10px; 
       padding-right: 10px; 
       background: white; opacity: 0.5;
       font-size: 25px;
       }"
       ))

title <- tags$div(
  map_title, HTML(ttl)
)  

# bl
heading_bl <- paste0(
  "Data source: <a style=color:",colv,"; href=https://www.celonis.com/> Celonis </a><br>
  Author: <a style=color:",colv,"; href=https://darwinanddavis.github.io/DataPortfolio/> Matt Malishev </a><br>
  Twitter/Github: <a style=color:",colv,"; href=https://github.com/darwinanddavis/worldmaps/tree/gh-pages> @darwinanddavis </a><br>
  Spot an error? <a style=color:",colv,"; href=https://github.com/darwinanddavis/worldmaps/issues> Submit an issue </a>"
)

# tr
heading_tr <- paste(
  "<strong> Total songs <div style=\"color:",colv,"; font-size:80%\">",mp$Name %>% unique %>% length,"</div> </strong>", "<br/>",
  "<strong> Total artists <div style=\"color:",colv,"; font-size:80%\"> ",mp$Artist %>% unique %>% length," </div> </strong>","<br/>",
  "<strong> Total countries <div style=\"color:",colv,"; font-size:80%\"> ",mp$Country %>% unique %>% length," </div> </strong>","<br/>"
)

# easy buttons 
locate_me <- easyButton( # locate user
  icon="fa-crosshairs", title="Zoom to my position",
  onClick=JS("function(btn, map){ map.locate({setView: true}); }"));

reset_zoom <- easyButton( # reset zoom 
  icon="fa-globe", title="Reset zoom",
  onClick=JS("function(btn, map){ map.setZoom(3);}"));  

map_control_box <- htmltools::tags$style( 
  htmltools::HTML(".leaflet-control.layers-base { 
                  text-align: left;
                  padding-left: 10px; 
                  padding-right: 10px; 
                  background: white; opacity: 1;
                  font-size: 20px;
                  }"
       ))

control_box <- htmltools::tags$div(
  map_control_box, htmltools::HTML("")
)  

# layers
mp1 <- mp %>% filter(Decade == 60)
mp2 <- mp %>% filter(Decade == 70)
mp3 <- mp %>% filter(Decade == 80)
mp4 <- mp %>% filter(Decade == 90)
mp5 <- mp %>% filter(Decade == 2000)

map <- leaflet() %>% 
  setView(setview[1],setview[2],zoom=2) %>% 
  addTiles(custom_tile) %>% 
  addPolygons(data =  mp1, opacity = opac,color = ~colpal,fillColor = ~colpal,stroke = TRUE,weight = 0.5, 
              # popup=paste0("<br>",mp1$Score,"<br>"),
              popup = popup_func(mp1),
              label=paste(mp1$Country), 
              labelOptions = text_label_opt, popupOptions = text_label_opt,
              group = "1960"
  ) %>%  
  addPolygons(data =  mp2, opacity = opac,color = ~colpal,fillColor = ~colpal,stroke = TRUE,weight = 0.5, 
              popup = popup_func(mp2),
              label=paste(mp2$Country), 
              labelOptions = text_label_opt, popupOptions = text_label_opt,
              group = "1970"
  ) %>%  
  addPolygons(data =  mp3,opacity = opac,color = ~colpal,fillColor = ~colpal,stroke = TRUE,weight = 0.5, 
              popup = popup_func(mp3),
              label=paste(mp3$Country), 
              labelOptions = text_label_opt, popupOptions = text_label_opt,
              group = "1980"
  ) %>%  
  addPolygons(data =  mp4,opacity = opac,color = ~colpal,fillColor = ~colpal,stroke = TRUE,weight = 0.5, 
              popup = popup_func(mp4),
              label=paste(mp4$Country), 
              labelOptions = text_label_opt, popupOptions = text_label_opt,
              group = "1990"
  ) %>%  
  addPolygons(data =  mp5,opacity = opac,color = ~colpal,fillColor = ~colpal,stroke = TRUE,weight = 0.5, 
              popup = popup_func(mp5),
              label=paste(mp5$Country), 
              labelOptions = text_label_opt, popupOptions = text_label_opt,
              group = "2000"
  ) %>%  
  addProviderTiles(
    # "CartoDB.DarkMatter"
    "Stamen.TonerLite"
  ) %>% 
  addLegend(pal = pal,
            values  = mp %>% pull(var1),
            position = "bottomright",
            title = var1,
            opacity = opac) %>% 
  addLayersControl(
    baseGroups = c("1960","1970","1980","1990","2000"),
    options = layer_options) %>% 
  addControl(title, "bottomleft", className = "map-title") %>% 
  addControl(heading_bl,"bottomleft") %>%
  addControl(heading_tr, "topright") %>% 
  addControl(control_box, "topright", className = "layers-base") %>% 
  addEasyButton(reset_zoom) %>% 
  addEasyButton(locate_me) 
map

# save
df %>% saveRDS(here::here("jips_test","jips_df.Rda"))  
mp %>% saveRDS(here::here("jips_test","jips_mp.Rda"))  
map %>% saveWidget(here::here("plots","jips.html"))  



# leaflet with polygon data * scatter ---------------------------------------------

xlab <- "ENERGY"
# with circles (working ) 
bscols(widths = c(12,6,6),
       list(
        filter_slider("rank", "Rank", sd1, ~Rank, step = 1),
        filter_checkbox("Decade", "Decade", sd1, ~paste0(Decade,"'s") %>% sort, inline = T)
       ),
       list(
       leaflet(sd1, width = "100%", height = 400) %>% 
         addTiles() %>% 
         addCircleMarkers(
           lng = sd1$data()[, "geometry"] %>% st_centroid() %>% st_coordinates() %>% .[,"X"],
           lat = sd1$data()[, "geometry"] %>% st_centroid() %>% st_coordinates() %>% .[,"Y"],
           color = colt, fillColor = colt, radius = ~Rank, 
           opacity = opac, fill = T, stroke = T, weight = 0.5,
           label = ~paste0("City: ", as.character(City),"br",
                           "Energy: ", as.character(energy),"br",
                           "Danceability: ", as.character(loudness),"/n"
                           ),
           popup = ~paste0("Country: ", as.character(Country))
               ) 
       ),
       list(
         d3scatter(sd1, ~energy, ~loudness, color = ~Rank, width = "100%", height = 200,x_label = xlab, y_label = "LOUDNESS"),
         d3scatter(sd1, ~energy, ~tempo, color = ~Rank,width = "100%", height = 200,x_label = xlab, y_label = "TEMPO")
       )
)



# leafet with city data -----------------------------------------------------

var1 <- "Rank"
colt <- "#5B3794"
colf <- "#F8DCD9"
colv <- colpal[1]
# df$colpal <- sequential_hcl(df[,var1] %>% length,"Purple-Orange")
# colp <- colorRampPalette(colors = c(colt, "#FFFFFF", colf))
# colpal <- colp(df[,var1] %>% length)
# df$colpal <- colpal # assign new colpal to var1 in df



sd <- SharedData$new(df)


# map city data 
countries <- sd$data()[,"Country"] %>% unique 
cities <- sd$data()[,"City"] %>% unique

city_df <- world_cities %>% 
  dplyr::filter(country.etc %in% c(countries,"USA","UK"), 
                name %in% cities) %>% 
  dplyr::select(Y = lat,
                X = long,
                City = name, 
                Country = country.etc) %>% 
  left_join(sd$data(), by = "City")

# convert data 
sd2 <- SharedData$new(city_df)


# map params 
var1 <- "Rank"
xlab <- "ENERGY"
colv <- "#000000"
colt <- colpal[1] # "#FF0100"
colf <- "#0000FF"
opac <- 0.9
ttl <- "Top 20 songs per city"
custom_tile <- "https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png"
  
style <- list("color" = colv,"font-weight" = "normal","padding" = "8px")
text_label_opt <- labelOptions(noHide = F, direction = "top", textsize = "10px",
                               textOnly = F, opacity = 0.7, offset = c(0,0),
                               style = style, permanent = T
)

heading_tr <- paste0(
    "<span style=color:",colt,";> ",ttl," </span><br>",
    "Hover over locations for more info"
) 

popup_func <- function(d) paste0("<strong><span style=color:",colt,";>",d %>% pull(City),"</span></strong><br/><br/>",
                                 "<strong>","Artist: ","</strong><span>", d %>% pull(Artist),"</span><br/>",
                                 "<strong>","Song: ","</strong><span>", d %>% pull(Name),"</span><br/>",
                                 "<strong>","Decade: ","</strong><span>", d %>% pull(Decade),"'s</span><br/>",
                                 "<strong>",var1,": </strong><span>", d %>% pull(var1),"</span><br/>") %>% purrr::map(htmltools::HTML)

# with circles (working ) 
bscols(widths = c(12,6,6),
       list(
         filter_slider("rank", "Rank", sd2, ~Rank, step = 1, pre = "Rank "),
         filter_checkbox("Decade", "Decade", sd2, ~paste0(Decade,"'s"), inline = T)
       ),
       list(
         leaflet(sd2, width = "100%", height = 400) %>% 
           addTiles(custom_tile) %>%
           setView(setview[1],setview[2],zoom=1) %>% 
           addCircleMarkers(
             lng = sd2$data()[, "X"] %>% jitter(5),
             lat = sd2$data()[, "Y"] %>% jitter(5), 
             color = colt, fillColor = colt, radius = ~Rank, 
             opacity = opac, fill = T, stroke = T, weight = 1,
             popup = popup_func(sd2$data()),
             label = popup_func(sd2$data()), # paste(sd2$data()[,"City"]),
             labelOptions = text_label_opt, popupOptions = text_label_opt
           ) %>% 
           # addProviderTiles(
           #   # "CartoDB.DarkMatter"
           #   # "Stamen.TonerLite"
           #   "Stadia.AlidadeSmooth"
           # ) %>%
           # addLegend(pal = pal,
           #           values  = ~Rank,
           #           position = "bottomright",
           #           title = "Rank",
           #           opacity = opac) %>%
           addControl(heading_tr,"topright") %>%
           addEasyButton(reset_zoom)
       ),
       list(
         d3scatter(sd2, ~energy, ~loudness, color = ~Rank, width = "100%", height = 200,x_label = xlab, y_label = "LOUDNESS"),
         d3scatter(sd2, ~energy, ~tempo, color = ~Rank,width = "100%", height = 200,x_label = xlab, y_label = "TEMPO")
       ),
       list(
         datatable(sd2, rownames = F,autoHideNavigation = T, fillContainer = F,
                   class="compact", extensions="Scroller",
                   options=list(deferRender=T, scrollY = 200, scrollX = 100, scroller=T,
                                pageLength = 5, autoWidth = T),
                   style = "bootstrap",
                   width = "100%", height = 200)
       )
)


# rCharts -------------------------------------------------------
# # bubble chart   ----------------------------------------------
pacman::p_load(rCharts)
h4 <- hPlot(data = df, energy ~ loudness, type = "bubble", title = "Zoom demo", subtitle = "bubble chart", 
            size = "Rank", group = "Country",radius = "Rank")
h4$colors(colpal[1:9])
h4$chart(zoomType = "xy")
h4$exporting(enabled = F)
h4$print(include_assets=T)
h4

h2 = hPlot(Pulse ~ Height, data = MASS::survey, type = "bubble", title = "Zoom demo", subtitle = "bubble chart", size = "Age", group = "Exer")
h2$chart(zoomType = "xy")
h2$exporting(enabled = F)
h2$print(include_assets=T)
h2





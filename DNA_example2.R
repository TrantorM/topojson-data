library(htmltools)
library(leaflet)
library(leaflet.extras)   # für: addTopoJSONChoropleth; devtools::install_github('bhaskarvk/leaflet.extras')
library(data.table)
library(vueR)             # für: reactive programming; devtools::install_github("timelyportfolio/vueR")

DNAKarte_adm2_K2.topojson <- readr::read_file('https://rawgit.com/TrantorM/topojson-data/master/DNAKarte_adm2_K2.topojson')        # system.time: 0.005

# # # # # # # # # #   G e n e r a t e   M a p   # # # # # # # # # # 
valuePropertyCode <- function(x, y){
  x = paste0('feature.properties.',x)
  y = paste0('feature.properties.',y)
  code = paste0("function(feature) {val = Math.log10(",x," / ",y,"); return ((val > -1.3 || val== Number.POSITIVE_INFINITY) ? ((val < 1.3) ? val : 1.3) : -1.3);}") # limitiere val auf -1.3 .. 1.3; siehe: http://www.hnldesign.nl/work/code/javascript-limit-integer-min-max/
  return(JS(code))
}

red = "{{selected}}"
blue = 'R1a'

map <- leaflet() %>% 
  addProviderTiles("CartoDB.Positron") %>% 
  setView(lng = 10, lat = 48, zoom = 5) %>%
  leaflet.extras::addGeoJSONChoropleth(DNAKarte_adm2_K2.topojson,
                                       valueProperty = JS(paste0("function(feature) {return feature.properties.{{selected}}}")),
                                       # valueProperty = "{{selectedHaplogroupNormalizied}}",
                                       # valueProperty = valuePropertyCode(red,blue),
                                       scale = c('blue','white','red'), 
                                       mode='k',    # q for quantile, e for equidistant, k for k-means
                                       steps = 10,
                                       # labelProperty = labelPropertyCode(red,blue),
                                       color='#ffffff', weight=1,
                                       fillOpacity = 1.0,
                                       group = 'choro'
  )

# # # # # # # # # #   W e b p a g e   a n d   V u e R   # # # # # # # # # # 
ui <- tagList(tags$div("Modern human DNA Y-Haplogroup"),
              tags$div(id="app",
                       tags$select("v-model" = "selected",
                                   tags$option("disabled value"="","Select one"),
                                   tags$option("I1"),
                                   tags$option("I2a1"),
                                   tags$option("I2a2"),
                                   tags$option("E1b"),
                                   tags$option("G"),
                                   tags$option("R1a"),
                                   tags$option("R1b")),
                       tags$span("Haplogroup Ratio: {{selected}} vs. R1a"),
                       tags$div(map)
),
tags$script(
  "
  var app = new Vue({
    el: '#app',
    data: {
      selected: 'R1b'
    },
    watch: {
      selected: function() {
        // uncomment debugger below if you want to step through debugger;
        
        // only expect one; if we expect multiple leaflet then we will need to be more specific
        var instance = HTMLWidgets.find('.leaflet');
        // get the map; could easily combine with above
        var map = instance.getMap();
        // we set group name to choro above, so that we can easily clear
        map.layerManager.clearGroup('choro');
        
        // now we will use the prior method to redraw
        var el = document.querySelector('.leaflet');
        // get the original method
        var addgeo = JSON.parse(document.querySelector(\"script[data-for='\" + el.id + \"']\").innerText).x.calls[1];
        addgeo.args[7].valueProperty = this.selected;
        LeafletWidget.methods.addGeoJSONChoropleth.apply(map,addgeo.args);
      }
    },
    computed: {
      selectedHaplogroupNormalizied() {
        return this.selected;
      }
    }
  });
  "
  ),
html_dependency_vue(offline=FALSE,minified=FALSE))

browsable(ui)

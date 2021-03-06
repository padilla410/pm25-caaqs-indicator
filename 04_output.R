# Copyright 2015 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

library("rcaaqs")
library("readr")
library("dplyr")
library("tidyr")
library("bcmaps")

library("ggplot2")
library("grid")
library("envreportutils")

library("sf")
library("geojsonio")

if (!exists("airzone_summary")) load("tmp/analysed.RData")

# Create output directory:
dir.create("out", showWarnings = FALSE)

# Summary plot of stations ------------------------------------------------


# Summary achievement map -------------------------------------------------

## @knitr pre

# transformthe lat-long coordinates to BC Albers
airzone_ambient_map <- transform_bc_albers(airzone_ambient_map)

airzone_ambient_map$caaqs_24h[is.na(airzone_ambient_map$caaqs_24h)] <- "Insufficient Data"
airzone_ambient_map$caaqs_annual[is.na(airzone_ambient_map$caaqs_annual)] <- "Insufficient Data"

pm_stats <- transform_bc_albers(pm_stats)
pm_stats <- cbind(pm_stats, st_coordinates(pm_stats))

## @knitr summary_plot

ambient_summary_plot <- summary_plot(pm_stats, metric_val = "metric_value", station = "station_name", 
                                     airzone = "Airzone", parameter = "metric", pt_size = 2)

## @knitr achievement_map_24

achievement_map_24 <- ggplot(airzone_ambient_map) + 
  geom_sf(aes(fill = caaqs_24h), colour = "white") + 
  coord_sf(datum = NA) + 
  scale_fill_manual(values = get_colours("achievement", drop_na = FALSE), 
                    drop = FALSE, 
                    name = bquote(atop('Airzones:', ~PM[2.5]~ '(24-hour) Air Quality Standard')), 
                    guide = guide_legend(order = 1, title.position = "top")) + 
  geom_point(data = pm_stats[pm_stats$metric == "pm2.5_24h", ], 
             aes(x = X, y = Y, colour = metric_value)) +
  scale_colour_gradient(high = "#252525", low = "#f0f0f0", 
                        name = bquote(atop('Monitoring Stations:',~PM[2.5]~ '(24-hour) Metric (' *mu* 'g/'*m^{3}*')')), 
                        guide = guide_colourbar(order = 2, title.position = "top", 
                                                barwidth = 10)) + 
 # labs(title = bquote('Status of 24-hour '~PM[2.5]~ 'Levels in B.C. Air Zones (2014-2016)')) + 
  theme_minimal() + 
  theme(axis.title = element_blank(), axis.text = element_blank(), 
        axis.ticks = element_blank(), panel.grid = element_blank(), 
        legend.position = "bottom", legend.box = "horizontal", 
        legend.box.just = "top", legend.direction = "horizontal", 
        legend.title.align = 0, legend.spacing = unit(20, "mm"),
        legend.title = element_text(face = "plain", size = 11, hjust = ))

## @knitr achievement_map_annual

achievement_map_annual <- ggplot(airzone_ambient_map) + 
  geom_sf(aes(fill = caaqs_annual), colour = "white") + 
  coord_sf(datum = NA) + 
  scale_fill_manual(values = get_colours("achievement", drop_na = FALSE), 
                    drop = FALSE, 
                    name = bquote(atop('Airzones:', ~PM[2.5]~ '(Annual) Air Quality Standard')), 
                    guide = guide_legend(order = 1, title.position = "top")) + 
  geom_point(data = pm_stats[pm_stats$metric == "pm2.5_annual", ], 
             aes(x = X, y = Y, colour = metric_value)) +
  scale_colour_gradient(high = "#252525", low = "#f0f0f0", 
                        name = bquote(
                          atop('Monitoring Stations:', 
                               ~PM[2.5]~ '(Annual) Metric (' * mu * 'g/' * m^{3} * ')')
                          ), 
                        guide = guide_colourbar(order = 2, title.position = "top", 
                                                barwidth = 10)) + 
#  labs(title = bquote('Status of Annual '~PM[2.5]~ 'Levels in B.C. Air Zones (2014-2016)')) + 
  theme_minimal() + 
  theme(axis.title = element_blank(), axis.text = element_blank(), 
        axis.ticks = element_blank(), panel.grid = element_blank(), 
        legend.position = "bottom", legend.box = "horizontal", 
        legend.box.just = "top", legend.direction = "horizontal", 
        legend.title.align = 0, legend.spacing = unit(20, "mm"),
        legend.title = element_text(face = "plain", size = 11))


# Individual Station Plots ------------------------------------------------

## @knitr stn_plots

emsids <- unique(pm_stats$ems_id)
stnplots <- vector("list", length(emsids))
names(stnplots) <- emsids

for (emsid in emsids) {
  
  ## Subset daily, caaqs, and annual data
  daily_data <- avgdaily[avgdaily$ems_id == emsid, ]
  if (nrow(daily_data) == 0) next
  caaqs_data_24h <- pm_stats[pm_stats$ems_id == emsid & 
                               pm_stats$metric == "pm2.5_24h", ]
  caaqs_data_annual <- pm_stats[pm_stats$ems_id == emsid & 
                                  pm_stats$metric == "pm2.5_annual", ]
  
  # Create plots
  p_24 <- plot_ts(daily_data, caaqs_data = caaqs_data_24h, 
                  parameter = "pm2.5_24h", rep_yr = 2016, base_size = 14)
  
  p_annual <- plot_ts(daily_data, caaqs_data = caaqs_data_annual, 
                      parameter = "pm2.5_annual", rep_yr = 2016, base_size = 14)
  
  p_annual <- p_annual + coord_cartesian(ylim = c(0, 80))
  p_24 <- p_24 + coord_cartesian(ylim = c(0, 80))
  
  
  stnplots[[emsid]]$daily <- p_24
  stnplots[[emsid]]$annual <- p_annual
  message("creating plots for ", emsid, "\n")
}


# Management map and bar chart --------------------------------------------

## Management Air Zone Map

## @knitr mgmt_map

airzone_mgmt_map <- transform_bc_albers(airzone_mgmt_map)

airzone_mgmt_map$caaq_mgmt[is.na(airzone_mgmt_map$caaq_mgmt)] <- "Insufficient Data"

colrs <- get_colours("management", drop_na = FALSE)

labels_df = data.frame(x = c(680000, 1150000, 780000, 1150000, 
                             1550000, 1150000, 1500000),
                       y = c(950000, 1550000, 1500000, 950000, 
                             600000, 325000, 410000), 
                       airzone_name = c("Coastal", "Northeast", "Northwest", 
                                        "Central\nInterior", "Southern\nInterior", 
                                        "Georgia Strait", "Lower Fraser Valley"))

mgmt_map <- ggplot(airzone_mgmt_map) +   
  geom_sf(aes(fill = caaq_mgmt), colour = "white") + 
  coord_sf(datum = NA) + 
  theme_minimal() + 
  scale_fill_manual(values = colrs, 
                    drop = FALSE, 
                    name = "Air Zone Management Levels", 
                    guide = guide_legend(reverse = TRUE)) + 
  theme(axis.title = element_blank(),
        axis.text = element_blank(), 
        axis.ticks = element_blank(),
        panel.grid = element_blank(),
        legend.position = "none",
        plot.margin = unit(c(0,0,0,0),"mm")) +
  geom_text(data = labels_df, aes(x = x, y = y, label = airzone_name), 
            colour = "black", size = 5)

## Management Bar Chart

## @knitr mgmt_chart

mgmt_chart <- ggplot(data = pm_mgmt_stats,
                     aes(x = metric, fill = mgmt)) + 
  geom_bar(alpha = 1, width = 0.8) +
  facet_wrap(~Airzone, ncol = 1) +
  xlab("") + ylab("Number of Reporting Stations") +
  coord_flip() +
  scale_y_continuous(expand = c(0,0)) +
  scale_fill_manual(values = colrs, 
                    drop = TRUE, 
                    name = "Air Zone Management Levels", 
                    guide = guide_legend(reverse = TRUE)) +
  scale_x_discrete(labels = c("pm2.5_24h" = "24-hour", "pm2.5_annual" = "Annual")) +
  theme_soe_facet() +
  theme(panel.grid.major.y = (element_blank()),
        axis.text = element_text(size = 12),
        legend.position = "bottom",
        legend.direction = "vertical",
        legend.box.just = "left",
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 12),
        legend.spacing = unit(5,"mm"),
        plot.margin = unit(c(15,0,5,0),"mm"),
        strip.text = element_text(size = 12))

# multiplot of bar chart and mgmt map
## multiplot(mgmt_chart, mgmt_map, cols = 2, widths = c(1, 1.4))

## @knitr end

####### Updated to here for 2017 analysis

# Output data, maps, and charts ------------------------------------------------

outCRS <- 4326

## Combined Management map and barchart with multiplot
# png_retina(filename = "./out/pm_mgmt_viz.png", width = 836, height = 560, units = "px")
# svg_px("./out/pm_mgmt_viz.svg", width = 836, height = 560)
# multiplot(mgmt_chart, mgmt_map, cols = 2, widths = c(1, 1.4))
# dev.off()

## SVG of airzone CAAQS mgmt level map
svg_px("out/pm_caaqs_mgmt_map.svg", width = 500, height = 500)
plot(mgmt_map)
dev.off()

## SVG of airzone/station CAAQS mgmt achievement chart
svg_px("out/pm_caaqs_mgmt_chart.svg", width = 500, height = 500)
plot(mgmt_chart)
dev.off()

# write summary stats
pm_stats <- select(pm_stats, -X, -Y)
pm_stats %>% 
  st_set_geometry(NULL) %>% 
  mutate(caaq_year = max_year) %>% 
  write_csv(paste0("out/pm25_site_summary_", max_year, ".csv"))

## Convert pm_stats back to SpatialPointsDataFrame and export as geojson
pm_stats_wide <- reshape(st_set_geometry(pm_stats, NULL), 
                         v.names = c("min_year", "max_year", 
                                     "n_years", "metric_value", "caaqs"), 
                         idvar = "ems_id", timevar = "metric", 
                         direction = "wide", sep = "_")
names(pm_stats_wide) <- gsub("_pm2.5", "", names(pm_stats_wide))

st_as_sf(pm_stats_wide, coords = c("longitude", "latitude"), 
                          crs = 4617) %>% 
  st_transform(outCRS) %>% 
  ## Can't currently use geojson_write because it turns NA into "NA" in the geojson rather than
  ## null - issue opened here: https://github.com/ropensci/geojsonio/issues/109
  # geojson_write(file = "out/pm_site_summary.geojson")
  geojson_list %>% unclass() %>% 
  jsonlite::toJSON(pretty = FALSE, auto_unbox = TRUE, na = "null") %>% 
  cat(file = "out/pm_site_summary.geojson")

## Export airzone_map as geojson
# Replace NAs in caaq status and management levels in airzone_map
replace_na <- function(x, text) {
  x[is.na(x)] <- text
  x
}

airzone_ambient_map$caaqs_annual <- replace_na(airzone_ambient_map$caaqs_annual, "Insufficient Data")
airzone_ambient_map$caaqs_24h <- replace_na(airzone_ambient_map$caaqs_24h, "Insufficient Data")

airzone_ambient_map %>%
  st_transform(outCRS) %>% 
  geojson_write(file = "out/pm_airzone_summary.geojson")

## Save line plots
line_dir <- "out/station_plots/"
dir.create(line_dir, showWarnings = FALSE, recursive = TRUE)
lapply(list.files(line_dir, full.names = TRUE), file.remove)
width <- 778
height <- 254

for (i in seq_along(stnplots)) {
  emsid <- names(stnplots[i])
  daily_plot <- stnplots[[i]]$daily
  annual_plot <- stnplots[[i]]$annual
  cat("saving plots for", emsid, "\n")
  # png_retina(filename = paste0(line_dir, emsid, "_24h_lineplot.png"), 
  #     width = 778, height = 254, units = "px", res = res)
  svg_px(paste0(line_dir, emsid, "_24h_lineplot.svg"), 
          width = width, height = height)
  plot(daily_plot)
  dev.off()
  # png_retina(filename = paste0(line_dir, emsid, "_annual_lineplot.png"), 
  #     width = 778, height = 254, units = "px", res = res)
  svg_px(paste0(line_dir, emsid, "_annual_lineplot.svg"),
          width = width, height = height)
  plot(annual_plot)
  dev.off()
}
graphics.off() # Kill any hanging graphics processes

## Need to do two airzone summary csvs - one for ambient, one for management

st_set_geometry(airzone_ambient_map, NULL) %>% 
  write_csv("out/pm25_ambient_airzone_caaqs_summary.csv")

st_set_geometry(airzone_mgmt_map, NULL) %>% 
  write_csv("out/pm25_mgmt_airzone_caaqs_summary.csv")

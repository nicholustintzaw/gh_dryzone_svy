
################################################################################
# Plots Generator
################################################################################

## 1. Packages and Settings ----

options(scipen    = 999)
options(max.print = 5000)
options(tibble.width = Inf)


if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse, data.table, lubridate, here, dplyr, stringi, tidyr, haven,
  readxl, ggplot2, sf, tmap
)



# The below gets rid of package function conflicts
#
# filter    <- dplyr::filter
# select    <- dplyr::select
# summarize <- dplyr::summarize

################################################################################
# food item level
################################################################################

# file dir assignment

tsp_shp <- here::here("01_raw", "shape_file", "mmr_polbnda_adm3_250k_mimu_1", "mmr_polbnda_adm3_250k_mimu_1.shp")

mg_shp <- here::here("01_raw", "shape_file", "mmr_mgy_polbnda_adm4_250k_wfp_mimu_1", "mmr_mgy_polbnda_adm4_250k_wfp_mimu_1.shp")

sg_shp <- here::here("01_raw", "shape_file", "mmr_sag_polbnda_adm4_250k_mimu", "mmr_sag_polbnda_adm4_250k_mimu.shp")


township <- st_read(tsp_shp) %>%
  filter(TS_PCODE == "MMR009020" |
           TS_PCODE == "MMR009018" | 
           TS_PCODE == "MMR009025" |
           TS_PCODE == "MMR009024" |
           TS_PCODE == "MMR009019" |
           TS_PCODE == "MMR005007" | 
           TS_PCODE == "MMR005019" | 
           TS_PCODE == "MMR005016"
           ) %>%
  mutate(zone = ifelse(TS_PCODE == "MMR005016" | TS_PCODE == "MMR005019",1, 
                       ifelse(TS_PCODE == "MMR005007", 2, 
                              ifelse(TS_PCODE == "MMR009020" | TS_PCODE == "MMR009018" | TS_PCODE == "MMR009019", 3, 
                                     ifelse(TS_PCODE == "MMR009025" | TS_PCODE == "MMR009024", 4, NA)))
  ))

zone_1 <- township %>% filter(zone == 1)
zone_2 <- township %>% filter(zone == 2)
zone_3 <- township %>% filter(zone == 3)
zone_4 <- township %>% filter(zone == 4)


# MMR009020	Myaing    3
# MMR009018	Pakokku   3
# MMR009025	Saw       4
# MMR009024	Tilin     4
# MMR009019	Yesagyo   3
# MMR005007	Kanbalu   2
# MMR005019	Pale      1
# MMR005016	Yinmarbin 1


mgawy <- st_read(mg_shp)
sagain <- st_read(sg_shp)


study_area <- rbind(mgawy, sagain) %>%
  filter(TS_PCODE == "MMR009020" |
           TS_PCODE == "MMR009018" | 
           TS_PCODE == "MMR009025" |
           TS_PCODE == "MMR009024" |
           TS_PCODE == "MMR009019" |
           TS_PCODE == "MMR005007" | 
           TS_PCODE == "MMR005019" | 
           TS_PCODE == "MMR005016"
  )

# Set tmap_mode to "view" for interactive mode
tmap_options(check.and.fix = TRUE)

tmap_mode("view")

# Plot your shapefile data
tm_shape(study_area) +
  tm_borders()  # Add borders

# Create a color palette based on the number of unique zones
num_zones <- length(unique(township$zone))
colors <- rainbow(num_zones)  # You can replace 'rainbow' with other color palettes if needed

township$zone <- as.factor(township$zone)


palette <- c("blue", "green", "red", "orange", "purple")  # Add more colors if needed


# Plot township boundaries with different colors based on zone variable
tm_shape(township) +
  tm_borders(col = "blue", lwd = 2, alpha = 0.7) +  # Adjust transparency scale with alpha parameter
  
  # Plot village tract boundaries
  tm_shape(study_area) +
  tm_borders(lwd = 1, col = "red")  # Set line width and color for village tract boundaries


# Plot township boundaries with different colors based on zone variable
tm_shape(zone_1) +
  tm_borders(col = "blue", lwd = 2, alpha = 0.7) + 
  tm_shape(zone_2) +
  tm_borders(col = "purple", lwd = 2, alpha = 0.7) +
  tm_shape(zone_3) +
  tm_borders(col = "red", lwd = 2, alpha = 0.7) +
  tm_shape(zone_4) +
  tm_borders(col = "orange", lwd = 2, alpha = 0.7) +
  # Plot village tract boundaries
  tm_shape(study_area) +
  tm_borders(lwd = 1, col = "green", alpha = 0.7)  # Set line width and color for village tract boundaries


######################################################################################
# read dta file
fooditem <- read_dta(fooditem)

# remove commune which were not part of HH survey
table(fooditem$com_name_eng)

df_food <- fooditem %>%
  filter(com_name_eng != "Lang Ha" &
           com_name_eng != "Khuong Thuong" &
           com_name_eng != "O Cho Dua")

table(df_food$com_name_eng)

df_food <- data.frame(df_food) %>%
  filter((!is.na(s4q2latitude) | !is.na(s4q2longitude)) &
           food_items_yes == 1 & food_groups != "")

df_food <- df_food %>%
  rename(
    "longitude" = "s4q2longitude",
    "latitude" = "s4q2latitude"
  )


# Transform data to sf object
d_food <- st_as_sf(df_food, coords = c("longitude", "latitude"))
# Assign CRS
st_crs(d_food) <- 4326


# Maps generation
tmap_mode("view") # interactive mode

# food_groups
tm_shape(d_food) +
  tm_dots("food_groups",
          palette = "Dark2") +
  tm_facets(by = "com_name_eng", ncol = 3)

# by geo area breakdown
d_food %>%
  filter(rural_urban == 1) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("food_groups",
          palette = "Dark2") +
  tm_facets(by = "com_name_eng", ncol = 3)

d_food %>%
  filter(rural_urban == 2) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("food_groups",
          palette = "Dark2") +
  tm_facets(by = "com_name_eng", ncol = 3)

d_food %>%
  filter(rural_urban == 3) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("food_groups",
          palette = "Dark2") +
  tm_facets(by = "com_name_eng", ncol = 3)


################################################################################
# outlet level
################################################################################

outlet <- here::here("Data", "Food environment", "4. Analysis prep", "2023_food_vendor_census_tidy_analysisprep.dta")

outlet <- read_dta(outlet)


# remove commune which were not part of HH survey
table(outlet$com_name_eng)

df_outlet <- outlet %>%
  filter(com_name_eng != "Lang Ha" &
           com_name_eng != "Khuong Thuong" &
           com_name_eng != "O Cho Dua")

table(df_outlet$com_name_eng)


df_outlet <- data.frame(df_outlet) %>%
  filter((!is.na(s4q2latitude) | !is.na(s4q2longitude)))

df_outlet <- df_outlet %>%
  rename(
    "longitude" = "s4q2longitude",
    "latitude" = "s4q2latitude"
  )


# change outcome var into str var
df_outlet <- df_outlet %>%
  mutate(nova4_yes = ifelse(nova4_yes == 1, "Outlet with Ultra-processed foods", "Other Outlets"),
         ssb_yes = ifelse(ssb_yes == 1, "Outlet with Sugar-Sweetened Beverages", "Other Outlets"),
         vegetable_grp_yes = ifelse(vegetable_grp_yes == 1, "Outlet with Vegetables", "Other Outlets"),
         fruit_grp_yes = ifelse(fruit_grp_yes == 1, "Outlet with Fruits", "Other Outlets"))

food_level <- c("Other food groups",
                "Fruits and Vegetables",
                "Healthy & Unhealthy foods",
                "Sugar-Sweetened Beverages (SSB)")

df_outlet$outlet_food_cat_str <- factor(df_outlet$outlet_food_cat_str, levels = food_level)

color_food_level <- c("gray", "darkgreen", "orange", "firebrick")
color_negative <- c("orange", "firebrick")
color_positive <- c("orange", "darkgreen")


# Transform data to sf object
d_outlet <- st_as_sf(df_outlet, coords = c("longitude", "latitude"))
# Assign CRS
st_crs(d_outlet) <- 4326

# Maps generation
tmap_mode("view") # interactive mode

# outlet_food_cat_str
d_outlet %>%
  tm_shape() +
  tm_dots("outlet_food_cat_str",
          title = "Outlet with",
          palette = color_food_level) +
  tm_facets(by = "com_name_eng", ncol = 3)

# by geo area breakdown
d_outlet %>%
  filter(rural_urban == 1) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("outlet_food_cat_str",
          title = "Outlet with",
          palette = color_food_level) +
  tm_facets(by = "com_name_eng", nrow = 2) +
  tm_legend(legend.outside = T, legend.stack = "horizontal", legend.outside.position = 'bottom')

d_outlet %>%
  filter(rural_urban == 2) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("outlet_food_cat_str",
          title = "Outlet with",
          palette = color_food_level) +
  tm_facets(by = "com_name_eng", ncol = 2) +
  tm_legend(legend.outside = T, legend.stack = "horizontal", legend.outside.position = 'bottom')

d_outlet %>%
  filter(rural_urban == 3) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("outlet_food_cat_str",
          title = "Outlet with",
          palette = color_food_level) +
  tm_facets(by = "com_name_eng", ncol = 2) +
  tm_legend(legend.outside = T, legend.stack = "horizontal", legend.outside.position = 'bottom')



# nova4_yes
d_outlet %>%
  tm_shape() +
  tm_dots("nova4_yes",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 3)

# by geo area breakdown
d_outlet %>%
  filter(rural_urban == 1) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("nova4_yes",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", nrow = 2)

d_outlet %>%
  filter(rural_urban == 2) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("nova4_yes",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 2)

d_outlet %>%
  filter(rural_urban == 3) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("nova4_yes",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 2)

# ssb_yes
d_outlet %>%
  tm_shape() +
  tm_dots("ssb_yes",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 3)

# by geo area breakdown
d_outlet %>%
  filter(rural_urban == 1) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("ssb_yes",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", nrow = 2)

d_outlet %>%
  filter(rural_urban == 2) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("ssb_yes",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 2)

d_outlet %>%
  filter(rural_urban == 3) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("ssb_yes",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 2)

# vegetable_grp_yes
d_outlet %>%
  tm_shape() +
  tm_dots("vegetable_grp_yes",
          title = "",
          palette = color_positive) +
  tm_facets(by = "com_name_eng", ncol = 3)

# by geo area breakdown
d_outlet %>%
  filter(rural_urban == 1) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("vegetable_grp_yes",
          title = "",
          palette = color_positive) +
  tm_facets(by = "com_name_eng", nrow = 2)

d_outlet %>%
  filter(rural_urban == 2) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("vegetable_grp_yes",
          title = "",
          palette = color_positive) +
  tm_facets(by = "com_name_eng", ncol = 2)

d_outlet %>%
  filter(rural_urban == 3) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("vegetable_grp_yes",
          title = "",
          palette = color_positive) +
  tm_facets(by = "com_name_eng", ncol = 2)

# fruit_grp_yes
d_outlet %>%
  tm_shape() +
  tm_dots("fruit_grp_yes",
          title = "",
          palette = color_positive) +
  tm_facets(by = "com_name_eng", ncol = 3)

# by geo area breakdown
d_outlet %>%
  filter(rural_urban == 1) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("fruit_grp_yes",
          title = "",
          palette = color_positive) +
  tm_facets(by = "com_name_eng", nrow = 2)

d_outlet %>%
  filter(rural_urban == 2) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("fruit_grp_yes",
          title = "",
          palette = color_positive) +
  tm_facets(by = "com_name_eng", ncol = 2)

d_outlet %>%
  filter(rural_urban == 3) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("fruit_grp_yes",
          title = "",
          palette = color_positive) +
  tm_facets(by = "com_name_eng", ncol = 2)


################################################################################
## Advertisement
################################################################################

# outlet level
ads <- here::here("Data", "Food environment", "4. Analysis prep", "2023_food_vendor_detailed_advertisements_tidy_analysisprep.dta")

ads <- read_dta(ads)


# remove commune which were not part of HH survey
table(ads$com_name_eng)

df_ads <- ads %>%
  filter(com_name_eng != "Lang Ha" &
           com_name_eng != "Khuong Thuong" &
           com_name_eng != "O Cho Dua")

table(df_ads$com_name_eng)


df_ads <- data.frame(df_ads) %>%
  filter((!is.na(s4q2latitude) | !is.na(s4q2longitude)))

df_ads <- df_ads %>%
  rename(
    "longitude" = "s4q2longitude",
    "latitude" = "s4q2latitude"
  )


# change outcome var into str var
df_ads <- df_ads %>%
  mutate(unhealthy_adv = ifelse(unhealthy_adv_yes == 1,
                                "Outlet with Marketing of unhealthy foods",
                                "Other outlets"),
         adv_target_kids = ifelse(adv_target_kids_yes == 1,
                                  "Outlet with Advertisement directed to kids",
                                  "Other outlets"),
         unhealthy_target_kids = ifelse(unhealthy_target_kids_yes == 1,
                                        "Outlet with Marketing of unhealthy foods directed to kids",
                                        "Other outlets"))


# Transform data to sf object
d_ads <- st_as_sf(df_ads, coords = c("longitude", "latitude"))
# Assign CRS
st_crs(d_ads) <- 4326

# Maps generation
tmap_mode("view") # interactive mode

# unhealthy_adv
d_ads %>%
  tm_shape() +
  tm_dots("unhealthy_adv",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 3)

# by geo area breakdown
d_ads %>%
  filter(rural_urban == 1) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("unhealthy_adv",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", nrow = 2)

d_ads %>%
  filter(rural_urban == 2) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("unhealthy_adv",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 2)

d_ads %>%
  filter(rural_urban == 3) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("unhealthy_adv",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 2)

# adv_target_kids
d_ads %>%
  tm_shape() +
  tm_dots("adv_target_kids",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 3)

# by geo area breakdown
d_ads %>%
  filter(rural_urban == 1) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("adv_target_kids",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", nrow = 2)

d_ads %>%
  filter(rural_urban == 2) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("adv_target_kids",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 2)

d_ads %>%
  filter(rural_urban == 3) %>%
  tm_shape() +
  tm_basemap(server = "OpenStreetMap") +
  tm_dots("adv_target_kids",
          title = "",
          palette = color_negative) +
  tm_facets(by = "com_name_eng", ncol = 2)


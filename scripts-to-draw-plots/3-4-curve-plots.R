library(dplyr)
library(ggplot2)
library(gridExtra)

# 1. Dataset with all 4 parameters
df <- data.frame(
  Condition = factor(c("DMSO Control", "DZNep Low", "DZNep High"), 
                     levels = c("DMSO Control", "DZNep Low", "DZNep High")),
  
  # Area Fraction (%)
  Area_Mean  = c(92.1, 87.4, 80.2),
  Area_SD    = c(2.2, 2.9, 3.6),
  
  # Cell Density (Nuclei Count per field)
  Nuclei_Mean = c(187.3, 166.7, 134.7),
  Nuclei_SD   = c(7.8, 7.4, 6.5),
  
  # Myotube Width (um)
  Width_Mean = c(7.23, 8.88, 8.32),
  Width_SD   = c(0.46, 1.02, 0.76),
  
  # Vacuolation (%)
  Vac_Mean   = c(2.0, 38.5, 82.1),
  Vac_SD     = c(1.2, 5.2, 6.8)
)

# 2. Shared Aesthetic Theme & Palette Colors
custom_theme <- theme_classic(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    plot.subtitle = element_text(size = 9.5, hjust = 0.5, face = "italic"),
    axis.title = element_text(face = "bold", size = 14),
    axis.text = element_text(color = "black", size = 11),
    panel.grid.major.y = element_line(color = "gray90", linetype = "dashed"),
    legend.position = "none"
  )

col_area   <- "#2B5C8F" # Deep Blue
col_nuclei <- "#2A9D8F" # Teal
col_width  <- "#D95F02" # Coral Orange
col_vac    <- "#7570B3" # Purple

# 3. Build Individual Panel Plots

# Plot A: Area Fraction
p1 <- ggplot(df, aes(x = Condition, y = Area_Mean, group = 1)) +
  geom_line(color = col_area, linewidth = 1) +
  geom_errorbar(aes(ymin = Area_Mean - Area_SD, ymax = Area_Mean + Area_SD), 
                width = 0.15, color = col_area) +
  geom_point(size = 3, color = col_area) +
  labs(title = "Area Fraction (%)", subtitle = "Monotonic Decay",
       x = "Treatment", y = "Coverage Area (%)") +
  scale_y_continuous(limits = c(70, 100)) +
  custom_theme

# Plot B: Cell Density (Nuclei Count)
p2 <- ggplot(df, aes(x = Condition, y = Nuclei_Mean, group = 1)) +
  geom_line(color = col_nuclei, linewidth = 1) +
  geom_errorbar(aes(ymin = Nuclei_Mean - Nuclei_SD, ymax = Nuclei_Mean + Nuclei_SD), 
                width = 0.15, color = col_nuclei) +
  geom_point(size = 3, color = col_nuclei) +
  labs(title = "Cell Density (Nuclei Count)", subtitle = "Monotonic Decay",
       x = "Treatment", y = "Nuclei Count / Field") +
  scale_y_continuous(limits = c(100, 210)) +
  custom_theme

# Plot C: Myotube Width
p3 <- ggplot(df, aes(x = Condition, y = Width_Mean, group = 1)) +
  geom_line(color = col_width, linewidth = 1) +
  geom_errorbar(aes(ymin = Width_Mean - Width_SD, ymax = Width_Mean + Width_SD), 
                width = 0.15, color = col_width) +
  geom_point(size = 3, color = col_width) +
  labs(title = "Myotube Width (\u03BCm)", subtitle = "Non-Monotonic (Inverted-U)",
       x = "Treatment", y = "Mean Width (\u03BCm)") +
  scale_y_continuous(limits = c(5, 11)) +
  custom_theme

# Plot D: Vacuolation
p4 <- ggplot(df, aes(x = Condition, y = Vac_Mean, group = 1)) +
  geom_line(color = col_vac, linewidth = 1) +
  geom_errorbar(aes(ymin = Vac_Mean - Vac_SD, ymax = Vac_Mean + Vac_SD), 
                width = 0.15, color = col_vac) +
  geom_point(size = 3, color = col_vac) +
  labs(title = "Cytoplasmic Vacuolation (%)", subtitle = "Monotonic Growth",
       x = "Treatment", y = "Vacuolated Area (%)") +
  scale_y_continuous(limits = c(0, 100)) +
  custom_theme

# 4. Combine in a 2x2 Grid Layout
combined_plot <- grid.arrange(p1, p2, p3, p4, nrow = 2, ncol = 2)

# Save high-resolution output
ggsave("DZNep_Complete_Dose_Response_2x2.svg", combined_plot, width = 8.5, height = 7, dpi = 300)
library(ggplot2)
library(dplyr)
library(tidyr)

# 1. Reconstruct Data Frame 
df <- data.frame(
  Day = c(-1, 0, 3, 4, 5, 6, 9),
  Area_Fraction = c(10.15, 10.50, 11.23, 12.33, 13.50, 14.52, 50.18),
  Major_Axis    = c(14.20, 17.50, 20.23, 27.17, 31.71, 38.39, 44.74),
  Minor_Axis    = c(8.66,  8.70,  8.86,  11.44, 13.15, 15.55, 17.83)
)

# Reshape data into long format for ggplot
df_long <- df %>%
  pivot_longer(
    cols = c("Area_Fraction", "Major_Axis", "Minor_Axis"),
    names_to = "Metric",
    values_to = "Value"
  ) %>%
  mutate(Metric = factor(Metric, 
                         levels = c("Area_Fraction", "Major_Axis", "Minor_Axis"),
                         labels = c("% Area Fraction", "Major Axis (Length)", "Minor Axis (Width)")))

# 2. Generate Publication Plot
p_plot <- ggplot(df_long, aes(x = Day, y = Value, color = Metric, group = Metric)) +
  
  # --- 5 MAIN UMBRELLA BACKGROUNDS ---
  annotate("rect", xmin = -1, xmax = 0, ymin = 0, ymax = 60, alpha = 0.1, fill = "#c6dbef") + # mESCs
  annotate("rect", xmin = 0,  xmax = 2, ymin = 0, ymax = 60, alpha = 0.2, fill = "#9ecae1") + # EBs
  annotate("rect", xmin = 2,  xmax = 7, ymin = 0, ymax = 60, alpha = 0.3, fill = "#6baed6") + # MPCs
  annotate("rect", xmin = 7,  xmax = 8, ymin = 0, ymax = 60, alpha = 0.4, fill = "#4292c6") + # Myocytes
  annotate("rect", xmin = 8,  xmax = 10, ymin = 0, ymax = 60, alpha = 0.5, fill = "#2171b5") + # Myotubes
  
  # --- DASHED INTERNAL PARTITION LINES ---
  geom_segment(aes(x = 5, xend = 5, y = 0, yend = 60), linetype = "dashed", color = "white", linewidth = 0.5) +
  geom_segment(aes(x = 6, xend = 6, y = 0, yend = 60), linetype = "dashed", color = "white", linewidth = 0.5) +
  geom_segment(aes(x = 9, xend = 9, y = 0, yend = 60), linetype = "dashed", color = "white", linewidth = 0.5) +
  
  # --- HIERARCHICAL TEXT LABELS (Smaller font for markers) ---
  annotate("text", x = -0.5, y = 56, label = "mESCs", fontface = "bold", size = 2.8, color = "#2c3e50", lineheight = 1.1) +
  annotate("text", x = 1.0,  y = 56, label = "EBs", fontface = "bold", size = 2.8, color = "#2c3e50", lineheight = 1.1) +
  
  annotate("text", x = 3.5,  y = 56, label = "MPCs (iMyoD)\niMyoD (ON)", fontface = "bold", size = 2.8, color = "#2c3e50", lineheight = 1.1) +
  annotate("text", x = 5.5,  y = 56, label = "Single MPCs\nMyoD+", fontface = "bold", size = 2.4, color = "#2c3e50", lineheight = 1.1) +
  annotate("text", x = 6.5,  y = 56, label = "Diff. MPCs\nMyoD+", fontface = "bold", size = 2.4, color = "#2c3e50", lineheight = 1.1) +
  
  annotate("text", x = 7.5,  y = 56, label = "Myocytes", fontface = "bold", size = 2.8, color = "#2c3e50", lineheight = 1.1) +
  
  annotate("text", x = 8.5,  y = 56, label = "Nascent\neMyHC+", fontface = "bold", size = 2.4, color = "#2c3e50", lineheight = 1.1) +
  annotate("text", x = 9.5,  y = 56, label = "Mature \nMyotubes\nMyHC/\nTitin", fontface = "bold", size = 2.4, color = "#2c3e50", lineheight = 1.1) +
  
  # Lines and point overlays
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.5, shape = 21, fill = "white", stroke = 1.2) +
  
  # Set X and Y Axis limits and steps 
  scale_y_continuous(
    limits = c(0, 60),
    breaks = seq(0, 60, by = 10),
    expand = c(0, 0)
  ) +
  scale_x_continuous(
    breaks = c(-1, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    labels = c("D-1", "D0", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9+", "")
  ) +
  
  # Color Palette for the Data Lines
  scale_color_manual(values = c(
    "% Area Fraction"     = "#D55E00", 
    "Major Axis (Length)" = "#E69F00", 
    "Minor Axis (Width)"  = "#009E73"  
  )) +
  
  # Formatting & Labels 
  labs(
    x = "Timeline / Culture Days",
    y = "Morphometric measure \n (%Area fraction;Length / Width = pixels) ",
    color = "Growth Metric",
    title = "Morphological Trajectory of In Vitro Skeletal Myogenesis"
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    axis.text = element_text(color = "black", size = 9),
    axis.title = element_text(face = "bold", size = 11),
    
    # --- COMPACT HORIZONTAL LEGEND BELOW THE CHART ---
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(face = "bold", size = 8),
    legend.text = element_text(size = 8),
    legend.background = element_rect(fill = "gray98", color = "gray80", linewidth = 0.4),
    legend.key.width = unit(1.0, "cm"),
    legend.key.height = unit(0.4, "cm"),
    legend.margin = margin(t = 2, r = 5, b = 2, l = 5),
    
    panel.grid.major.y = element_line(color = "gray92", linetype = "dashed")
  )

# 3. Save Plot
ggsave("./experiment-4/pots/morphological-trajectory-of-cell-culture.svg", p_plot, width = 8.2, height = 5.5, dpi = 300)
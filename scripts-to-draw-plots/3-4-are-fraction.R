options(bitmapType = "cairo")
suppressMessages(library(ggplot2))
suppressMessages(library(dplyr))

# 1. Reconstruct summary data from your tables
summary_data <- data.frame(
  Group = factor(
    c("DMSO", "DZNep (2 µM)", "DZNep (10 µM)"),
    levels = c("DMSO", "DZNep (2 µM)", "DZNep (10 µM)")
  ),
  Mean_Width   = c(7.23, 8.88, 8.32),
  Mean_Area    = c(47.58, 56.65, 49.17),
  Mean_Density = c(187.00, 166.00, 134.70)
)

# 2. Function to create clean average trend line plots
create_avg_line_plot <- function(sum_df, sum_y_var, y_label, title_text, y_limits) {
  ggplot(sum_df, aes(x = Group, y = .data[[sum_y_var]], group = 1)) +
    geom_line(color = "#3B5278", linewidth = 1.2) +
    geom_point(shape = 21, size = 4, fill = "#3B5278", color = "black", stroke = 1) +
    geom_text(
      aes(label = sprintf("%.2f", .data[[sum_y_var]])),
      vjust = -1.2, size = 4, fontface = "bold", color = "black"
    ) +
    scale_y_continuous(limits = y_limits, expand = expansion(mult = c(0.08, 0.15))) +
    labs(x = NULL, y = y_label, title = title_text) +
    theme_classic(base_size = 14) +
    theme(
      plot.title         = element_text(face = "bold", size = 16, hjust = 0.5, margin = margin(b = 10)),
      axis.line          = element_line(linewidth = 0.8, color = "black"),
      axis.ticks         = element_line(linewidth = 0.8, color = "black"),
      axis.ticks.length   = unit(0.15, "cm"),
      axis.text          = element_text(color = "black", size = 14),
      axis.title         = element_text(color = "black", face = "bold", size = 16),
      panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.4),
      legend.position    = "none"
    )
}

# 3. Generate each individual plot object
p_width <- create_avg_line_plot(
  sum_df     = summary_data, 
  sum_y_var  = "Mean_Width",
  y_label    = expression("Mean Width (" * mu * "m)"),
  title_text = "Dose-Dependent effect on myotube width",
  y_limits   = c(5, 11)
)

p_area <- create_avg_line_plot(
  sum_df     = summary_data, 
  sum_y_var  = "Mean_Area",
  y_label    = "Area Fraction (%)",
  title_text = "Dose-Dependent biphasic effect \non myotube area fraction",
  y_limits   = c(40, 65)
)

p_density <- create_avg_line_plot(
  sum_df     = summary_data, 
  sum_y_var  = "Mean_Density",
  y_label    = "Cell Density (Nuclei Count)",
  title_text = "Dose-dependent reduction in cell density \nfollowing DZNep treatment",
  y_limits   = c(120, 210)
)

# 4. Save individual plots to disk (both PNG and SVG formats)
# --- Plot 1: Width ---
ggsave("myotube_width_avg.svg", plot = p_width, width = 5.5, height = 4.5)

# --- Plot 2: Area Fraction ---
ggsave("area_fraction_avg.svg", plot = p_area, width = 5.5, height = 4.5)

# --- Plot 3: Cell Density ---
ggsave("cell_density_avg.svg", plot = p_density, width = 5.5, height = 4.5)
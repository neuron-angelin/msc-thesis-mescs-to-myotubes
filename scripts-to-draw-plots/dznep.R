options(bitmapType = "cairo")
suppressMessages(library(ggplot2))
suppressMessages(library(dplyr))
suppressMessages(library(ggpubr))

# 1. Complete raw/replicate data for all 3 metrics
raw_data <- data.frame(
  Group = factor(
    rep(c("DMSO", "DZNep (2 µM)", "DZNep (10 µM)"), each = 3),
    levels = c("DMSO", "DZNep (2 µM)", "DZNep (10 µM)")
  ),
  # Individual observations across 3 replicates
  Width = c(7.1, 7.4, 7.19,     # DMSO
            8.7, 9.1, 8.84,     # DZNep 2 µM
            8.2, 8.5, 8.26),    # DZNep 10 µM
  
  Area = c(46.2, 48.9, 47.64,   # DMSO
           55.1, 58.2, 56.65,   # DZNep 2 µM
           48.0, 50.3, 49.21),  # DZNep 10 µM
  
  Density = c(184, 196, 182,    # DMSO
              162, 175, 163,    # DZNep 2 µM
              128, 141, 135)    # DZNep 10 µM
)

# 2. Pairwise treatment comparisons relative to Control
comparisons_list <- list(
  c("DMSO", "DZNep (2 µM)"),
  c("DMSO", "DZNep (10 µM)")
)

# 3. Custom plotting function for clean jittered + significance graphs
create_custom_plot <- function(df, y_var, y_label, title_text, y_limits, p_val_pos) {
  
  # Calculate overall ANOVA p-value manually to force decimal notation (non-exponential)
  fit <- aov(as.formula(paste(y_var, "~ Group")), data = df)
  anova_p <- summary(fit)[[1]][["Pr(>F)"]][1]
  p_label <- sprintf("p = %.5f", anova_p)  # Standard decimal format (e.g., p = 0.00033)
  
  ggplot(df, aes(x = Group, y = .data[[y_var]])) +
    # Group mean trend line and mean marker point
    stat_summary(fun = mean, geom = "line", aes(group = 1), color = "#3B5278", linewidth = 1.2) +
    stat_summary(fun = mean, geom = "point", shape = 21, size = 4, fill = "#FFF", color = "black", stroke = 1) +
    
    # Jittered individual replicate data points
    geom_jitter(width = 0.12, size = 2.5, color = "#3B5278", alpha = 0.7) +
    
    # Custom non-exponential p-value annotation without the ANOVA method prefix
    annotate("text", x = 1, y = p_val_pos, label = p_label, size = 4.5, hjust = 0, fontface = "bold") +
    
    # Significance comparison bars relative to DMSO (*, **, ***)
    stat_compare_means(
      comparisons = comparisons_list,
      method = "t.test",
      label = "p.signif",
      symnum.args = list(cutpoints = c(0, 0.001, 0.01, 0.05, 1), symbols = c("***", "**", "*", "ns"))
    ) +
    
    scale_y_continuous(limits = y_limits, expand = expansion(mult = c(0.05, 0.12))) +
    labs(x = NULL, y = y_label, title = title_text) +
    theme_classic(base_size = 14) +
    theme(
      plot.title         = element_text(face = "bold", size = 15, hjust = 0.5, margin = margin(b = 10)),
      axis.line          = element_line(linewidth = 0.8, color = "black"),
      axis.ticks         = element_line(linewidth = 0.8, color = "black"),
      axis.ticks.length   = unit(0.15, "cm"),
      axis.text          = element_text(color = "black", size = 14),
      axis.title         = element_text(color = "black", face = "bold", size = 16),
      panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.4),
      legend.position    = "none"
    )
}

# 4. Generate plots for all three variables
p_width <- create_custom_plot(
  df         = raw_data,
  y_var      = "Width",
  y_label    = expression("Mean Width (" * mu * "m)"),
  title_text = "Dose-Dependent effect on myotube width",
  y_limits   = c(6, 11),
  p_val_pos  = 10.6
)

p_area <- create_custom_plot(
  df         = raw_data,
  y_var      = "Area",
  y_label    = "Area Fraction (%)",
  title_text = "Dose-Dependent biphasic effect\non myotube area fraction",
  y_limits   = c(40, 68),
  p_val_pos  = 65.5
)

p_density <- create_custom_plot(
  df         = raw_data,
  y_var      = "Density",
  y_label    = "Cell Density (Nuclei Count)",
  title_text = "Dose-dependent reduction in cell density\nfollowing DZNep treatment",
  y_limits   = c(110, 230),
  p_val_pos  = 222
)

# 5. Save plots
ggsave("myotube_width_jitter_sig.png", plot = p_width, width = 5.5, height = 4.5)
ggsave("area_fraction_jitter_sig.png", plot = p_area, width = 5.5, height = 4.5)
ggsave("cell_density_jitter_sig.png", plot = p_density, width = 5.5, height = 4.5)
options(bitmapType = "cairo")
suppressMessages(library(ggplot2))
suppressMessages(library(dplyr))

# 1. Reconstruct exact table data from the image
raw_data <- data.frame(
  well = rep(c("Well 1", "Well 2", "Well 3"), 2),
  Condition = factor(rep(c("Day 1", "Day 2"), each = 3), levels = c("Day 1", "Day 2")),
  Time_days = rep(c(1, 2), each = 3),
  Confluence = c(4.16, 1.22, 3.58, 10.57, 2.07, 12.62)
)

# Calculate summary statistics (Mean per Day)
summary_data <- raw_data %>%
  group_by(Condition, Time_days) %>%
  summarise(Mean_Confluence = mean(Confluence), .groups = "drop")

# 2. Calculate Growth Rate (mu) and Doubling Time (DT) based on Mean Values
t1 <- 1; t2 <- 2
N1 <- summary_data$Mean_Confluence[summary_data$Condition == "Day 1"]
N2 <- summary_data$Mean_Confluence[summary_data$Condition == "Day 2"]

# Exponential growth rate per day and per hour
mu_day  <- (log(N2) - log(N1)) / (t2 - t1)
mu_hour <- mu_day / 24

# Doubling Time in days and hours
dt_days  <- log(2) / mu_day
dt_hours <- dt_days * 24

# Text label for graph callout box
stats_label <- paste0(
  "Mean Proliferation Rate: ", sprintf("%.3f", mu_hour), " hr⁻¹\n",
  "Mean Doubling Time (DT): ", sprintf("%.2f", dt_hours), " hrs"
)

# 3. Build Plot
p_plot <- ggplot() +
  
  # Individual Well Trajectories (Thin grey background lines)
  geom_line(
    data = raw_data, 
    aes(x = Condition, y = Confluence, group = well), 
    color = "grey75", 
    linewidth = 0.6, 
    linetype = "solid"
  ) +
  
  # Mean Slope Line (Main trend line)
  geom_line(
    data = summary_data, 
    aes(x = Condition, y = Mean_Confluence, group = 1), 
    color = "#457B9D", 
    linewidth = 1.2, 
    linetype = "dashed"
  ) +
  
  # Individual Well Points
  geom_point(
    data = raw_data, 
    aes(x = Condition, y = Confluence, color = well), 
    size = 3, 
    alpha = 0.7
  ) +
  
  # Mean Points
  geom_point(
    data = summary_data, 
    aes(x = Condition, y = Mean_Confluence), 
    shape = 21, 
    fill = "#2A4B7C", 
    color = "black", 
    size = 5, 
    stroke = 1.2
  ) +
  
  # Point value labels for Means
  geom_text(
    data = summary_data,
    aes(x = Condition, y = Mean_Confluence, label = sprintf("%.2f%%", Mean_Confluence)),
    vjust = -1.3,
    size = 4.2,
    fontface = "bold"
  ) +
  
  # Annotation Box for DT and Rate
  annotate(
    "label",
    x = 1.5, y = 14.0, # Centered between Day 1 and Day 2 at the top
    label = stats_label,
    fill = "white",
    color = "grey15",
    size = 3.8,
    fontface = "bold",
    label.padding = unit(0.5, "lines"),
    box.color = "#457B9D",
    linewidth = 0.8
  ) +
  
  # Aesthetics & Colors
  scale_color_manual(values = c("Well 1" = "#E63946", "Well 2" = "#2A9D8F", "Well 3" = "#F4A261")) +
  scale_y_continuous(
    limits = c(0, 16),
    breaks = seq(0, 16, 2),
    expand = expansion(mult = c(0, 0.05))
  ) +
  labs(
    x = "Timepoint", 
    y = "Confluence / Area Fraction (%)",
    title = "Cell Proliferation Rate and Doubling Time",
    color = "Replicates"
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5, margin = margin(b = 15)),
    axis.line = element_line(linewidth = 1.2, color = "black"),
    axis.ticks = element_line(linewidth = 1.2, color = "black"),
    axis.ticks.length = unit(0.2, "cm"),
    axis.text = element_text(color = "black", size = 11),
    axis.title = element_text(color = "black", face = "bold", size = 13),
    panel.grid.major.y = element_line(colour = "grey92", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    legend.position = "right"
  )

# Save plot
ggsave("./experiment-4/pots/confluence-area-fraction-plot.svg", p_plot, width = 6.5, height = 4.9, dpi = 300)
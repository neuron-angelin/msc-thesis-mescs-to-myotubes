options(bitmapType = "cairo")
suppressMessages(library(ggplot2))

# 1. Dataset (Updated from table)
data <- data.frame(
  Condition = rep(c("GLUT4-medium", "GLUT4-high"), each = 3),
  Myofibre_Diameter = c(89.195,	83.58,	74.35,	113.5916667,	101.8516667,	115.36333333)
)

data$Condition <- factor(data$Condition, levels = c("GLUT4-medium", "GLUT4-high"))

# 2. Correct Unpaired Test
tt <- t.test(Myofibre_Diameter ~ Condition, data = data)
p  <- tt$p.value
sig <- ifelse(p < 0.001, "***",
              ifelse(p < 0.01,  "**",
                     ifelse(p < 0.05,  "*", "ns")))
lab <- paste0(sig)

# 3. Smart Layout & Headroom Variables
pal <- c("GLUT4-medium" = "#457B9D", "GLUT4-high" = "#2A4B7C")
# Adjusted headroom variable for data range max (~114 px)
y_br <- 160 

# 4. Generate the Clean Plot
p_plot <- ggplot(data, aes(Condition, Myofibre_Diameter, fill = Condition)) +
  # scale = "width" forces BOTH violins to have the exact same max width footprint
  geom_violin(trim = FALSE, scale = "width", width = 0.6, colour = "black",
              linewidth = 0.8, alpha = 0.85) +
  
  # Sleeker internal boxplot
  geom_boxplot(width = 0.07, fill = "black", colour = "black", outlier.shape = NA) +
  
  # Centered white median anchor point
  stat_summary(fun = median, geom = "point", shape = 21,
               size = 3, colour = "black", fill = "white", stroke = 1) +
  
  # Highly visible white replicate dots with thick black outlines
  geom_point(shape = 21, fill = "white", color = "black", size = 2, stroke = 1.3, alpha = 0.95,
             position = position_jitter(width = 0.03, seed = 42)) +
  
  # Clean, proportional GraphPad style significance bracket
  annotate("segment", x = 1, xend = 2, y = y_br, yend = y_br, colour = "grey20", linewidth = 0.5) +
  annotate("segment", x = 1, xend = 1, y = y_br, yend = y_br - 3, colour = "grey20", linewidth = 0.5) +
  annotate("segment", x = 2, xend = 2, y = y_br, yend = y_br - 3, colour = "grey20", linewidth = 0.5) +
  annotate("text", x = 1.5, y = y_br + 5, label = lab, size = 3.7) +
  
  scale_fill_manual(values = pal, guide = "none") +
  
  # Rescaled Y-axis limits (0 to 160 pixels)
  scale_y_continuous(
    limits = c(0, 180),            
    breaks = seq(0, 180, 20),     
    expand = expansion(mult = c(0, 0)) 
  ) +
  
  labs(x = "Cell Line", y = "Average of Top 6 widest myotubes (pixels)", title = "Myofibre Diameter across\n GLUT4 Medium/High Expression") +
  
  # Authentic Open GraphPad Prism Theme
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5, margin = margin(b = 15)),
    axis.line = element_line(linewidth = 1.2, color = "black"),
    axis.ticks = element_line(linewidth = 1.2, color = "black"),
    axis.ticks.length = unit(0.2, "cm"),
    axis.text = element_text(color = "black", size = 10),
    axis.title = element_text(color = "black", face = "bold", size = 13),
    panel.grid.major.y = element_line(colour = "grey92", linewidth = 0.5), # Soft horizontal reference lines
    panel.grid.minor = element_blank()
  )

# 5. Save Export
dir.create("./experiment-2-plots", showWarnings = FALSE)
ggsave("./experiment-2-plots/glut4-medium-high-myofibre-diameter-plot.svg", 
       p_plot, width = 5.5, height = 5, dpi = 300)
cat("unpaired p =", p, " label:", lab, "\n")
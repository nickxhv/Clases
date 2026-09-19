## -----------------------------------------------------------------
# library(ggplot2)
# 
# ggplot(datos, aes(x = variable_x, y = variable_y)) +
#   geom_tipo() +          # geometría: puntos, barras, etc.
#   labs(title = "...") +  # títulos y etiquetas
#   theme_minimal()        # tema visual

## -----------------------------------------------------------------


library(tidyverse)

# Paleta institucional Whale
whale <- c("#0066CC", "#3366FF", "#6699FF",
           "#FF6633", "#228B22")

# Dataset de ejemplo (nativo de R)
data(mpg, package = "ggplot2")

# Tema personalizado reutilizable
tema_escuela <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )


## -----------------------------------------------------------------


ggplot(mpg, aes(x = hwy)) +
  geom_histogram(fill = "#0066CC",
                 color = "white",
                 bins = 25) +
  labs(title = "Distribución de Eficiencia",
       x = "Millas por galón (hwy)",
       y = "Frecuencia") +
  theme_minimal()


## -----------------------------------------------------------------


ggplot(mpg, aes(x = reorder(class, hwy, median),
                y = hwy, fill = class)) +
  geom_boxplot(show.legend = FALSE,
               alpha = 0.7) +
  labs(title = "Eficiencia por Clase de Vehículo",
       x = "Clase",
       y = "Millas por galón (hwy)") +
  scale_fill_brewer(palette = "Blues") +
  theme_minimal()


## -----------------------------------------------------------------


mpg %>%
  count(class) %>%
  ggplot(aes(x = reorder(class, -n), y = n)) +
  geom_bar(stat = "identity",
           fill = "#0066CC") +
  geom_text(aes(label = n), vjust = -0.5,
            size = 3) +
  labs(title = "Vehículos por Clase",
       x = "", y = "Cantidad") +
  theme_minimal()


## -----------------------------------------------------------------


ggplot(mpg, aes(x = hwy, fill = drv)) +
  geom_density(alpha = 0.4) +
  labs(title = "Densidad de Eficiencia por Tracción",
       x = "Millas por galón (hwy)",
       fill = "Tracción") +
  scale_fill_manual(
    values = c("#0066CC", "#FF6633", "#228B22")
  ) +
  theme_minimal()


## -----------------------------------------------------------------


ggplot(mpg, aes(x = displ, y = hwy)) +
  geom_point(aes(color = drv),
             size = 2.5, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE,
              color = "gray30",
              linetype = "dashed") +
  labs(title = "Cilindrada vs Eficiencia",
       x = "Cilindrada (litros)",
       y = "Millas por galón (hwy)",
       color = "Tracción") +
  scale_color_manual(
    values = c("#0066CC", "#FF6633", "#228B22")
  ) +
  theme_minimal()


## -----------------------------------------------------------------


data(economics, package = "ggplot2")

ggplot(economics, aes(x = date,
                      y = unemploy / 1000)) +
  geom_area(fill = "#0066CC", alpha = 0.2) +
  geom_line(color = "#0066CC",
            linewidth = 0.6) +
  labs(title = "Desempleo en el Tiempo",
       x = "", y = "Desempleados (miles)") +
  theme_minimal()


## -----------------------------------------------------------------


ggplot(mpg, aes(x = displ, y = hwy)) +
  geom_point(color = "#0066CC", alpha = 0.5) +
  geom_smooth(method = "loess", se = FALSE,
              color = "gray30") +
  facet_wrap(~drv) +
  labs(title = "Cilindrada vs Eficiencia por Tracción",
       x = "Cilindrada (L)",
       y = "MPG (hwy)") +
  theme_minimal()


## -----------------------------------------------------------------


# Guardar el último gráfico generado
ggsave("grafico.png",
       width = 7, height = 4, dpi = 300)

# Guardar un objeto específico
p <- ggplot(mpg, aes(displ, hwy)) +
  geom_point()

ggsave("scatter.pdf", plot = p,
       width = 7, height = 4)


## -----------------------------------------------------------------


install.packages("gt")
library(gt)


## -----------------------------------------------------------------


library(tidyverse)

# Tabla de frecuencia con proporciones
mpg %>%
  count(class) %>%
  mutate(
    frec_rel = n / sum(n),
    frec_acum = cumsum(frec_rel)
  )


## -----------------------------------------------------------------


library(gt)

mpg %>%
  group_by(class) %>%
  summarise(
    n = n(),
    media = mean(hwy),
    mediana = median(hwy),
    desv = sd(hwy)
  ) %>%
  gt() %>%
  tab_header(
    title = "Estadísticas por Clase",
    subtitle = "Eficiencia en carretera"
  ) %>%
  fmt_number(columns = c(media, mediana, desv),
             decimals = 1) %>%
  cols_label(n = "N", media = "Media",
             mediana = "Mediana",
             desv = "Desv. Est.")


## -----------------------------------------------------------------


mpg %>%
  group_by(class) %>%
  summarise(media = mean(hwy),
            desv = sd(hwy)) %>%
  gt() %>%
  tab_header(title = "Eficiencia por Clase") %>%
  fmt_number(columns = c(media, desv),
             decimals = 1) %>%
  data_color(
    columns = media,
    colors = scales::col_numeric(
      palette = c("white", "#0066CC"),
      domain = NULL)
  ) %>%
  tab_options(
    heading.background.color = "#0066CC",
    column_labels.font.weight = "bold"
  )


## -----------------------------------------------------------------


tabla <- mpg %>%
  group_by(class) %>%
  summarise(media = mean(hwy)) %>%
  gt()

# Guardar como imagen
gtsave(tabla, "tabla.png")

# Guardar como HTML
gtsave(tabla, "tabla.html")

# Guardar como Word
gtsave(tabla, "tabla.docx")


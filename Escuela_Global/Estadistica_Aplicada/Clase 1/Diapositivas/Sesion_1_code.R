## ----setup, include=FALSE----------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE, 
                      fig.align = 'center', fig.width = 7, fig.height = 4,
                      size = 'footnotesize')
library(tidyverse)
library(janitor)
library(lubridate)


## ----libs, eval=TRUE, echo=TRUE----------------------------------------------------------------
# Cargar paquetes necesarios
library(tidyverse)      # Manipulación de datos
library(janitor)        # Limpieza automática
library(lubridate)      # Manejo de fechas


## ----create_data, eval=TRUE, echo=TRUE---------------------------------------------------------
set.seed(42)

datos_crudos <- data.frame(
  ID = 1:35,
  fecha = c("01/01/2024", "2024-01-02", "1 de enero 2024",
            rep(NA, 3), sample(c("01/04/2024", "2024-04-07"), 29, 
                               replace=TRUE)),
  sector = c("FINANZAS", "finanzas", "Finanzas", "  finanzas  ",
             rep(c("Retail", "RETAIL", " retail"), 10), "Manufactura"),
  ingresos = c(50000, -30000, 75000, 80000,
               rnorm(31, mean=65000, sd=15000)),
  empleados = c(100, 150, NA, 120, 
                sample(c(90, 110, 130), 31, replace=TRUE))
)


## ----diag1, eval=TRUE, echo=TRUE---------------------------------------------------------------
dim(datos_crudos)           # Dimensiones
head(datos_crudos, 8)       # Primeras 8 filas
colSums(is.na(datos_crudos)) # Valores faltantes


## ----struct, eval=TRUE, echo=TRUE--------------------------------------------------------------
str(datos_crudos)
summary(datos_crudos)


## ----prob_diag, eval=TRUE, echo=TRUE, size='small'---------------------------------------------
# Contar problemas
problemas <- tibble(
  tipo = c("Fechas con NA", "Sector con espacios", 
           "Ingresos negativos", "Empleados con NA"),
  cantidad = c(5, 2, 1, 1)
)
print(problemas)


## ----clean_names, eval=TRUE, echo=TRUE---------------------------------------------------------
datos_paso1 <- datos_crudos %>%
  clean_names()  # Convierte a snake_case

colnames(datos_paso1)


## ----clean_dates, eval=TRUE, echo=TRUE---------------------------------------------------------
datos_paso2 <- datos_paso1 %>%
  mutate(
    fecha = parse_date_time(fecha, orders = c("dmy", "ymd")),
    ano = year(fecha),
    mes = month(fecha)
  )

head(datos_paso2 %>% select(fecha, ano, mes), 8)


## ----clean_text, eval=TRUE, echo=TRUE----------------------------------------------------------
datos_paso3 <- datos_paso2 %>%
  mutate(
    sector = str_trim(sector),           # Eliminar espacios
    sector = str_to_title(sector),       # Estandarizar mayúsculas
    sector = case_when(
      str_detect(sector, "^Fin") ~ "Finanzas",
      str_detect(sector, "^Ret") ~ "Retail",
      TRUE ~ sector
    )
  )

datos_paso3 %>% select(sector) %>% distinct()


## ----ex3, eval=TRUE, echo=TRUE-----------------------------------------------------------------
# Ver antes
table(datos_crudos$sector)

# Ver después de limpieza
table(datos_paso3$sector)


## ----handle_neg, eval=TRUE, echo=TRUE----------------------------------------------------------
datos_paso4 <- datos_paso3 %>%
  mutate(
    ingreso_negativo = ingresos < 0,  # Flag para auditoría
    ingresos = abs(ingresos)           # Valor absoluto
  )

cat("Registros con ingreso original negativo:",
    sum(datos_paso4$ingreso_negativo), "\n")


## ----impute, eval=TRUE, echo=TRUE--------------------------------------------------------------
datos_paso5 <- datos_paso4 %>%
  filter(!is.na(fecha)) %>%           # Eliminar NA en fechas
  group_by(sector) %>%
  mutate(
    empleados = ifelse(is.na(empleados),
                       median(empleados, na.rm=TRUE),
                       empleados)
  ) %>%
  ungroup()

colSums(is.na(datos_paso5))


## ----ex4, eval=TRUE, echo=TRUE-----------------------------------------------------------------
decisiones_limpieza <- tibble(
  problema = c("Fechas múltiples formatos", "Sector con espacios",
               "Ingresos negativos", "Empleados faltantes"),
  accion = c("parse_date_time con múltiples órdenes",
             "str_trim + str_to_title + case_when",
             "Marcar + convertir a positivos",
             "Imputar con mediana por sector"),
  justificacion = c("Combinación de formatos comunes",
                    "Inconsistencia de entrada",
                    "Potencial error o devolución",
                    "Mantener datos para análisis")
)

print(decisiones_limpieza)


## ----outliers, eval=TRUE, echo=TRUE------------------------------------------------------------
datos_paso6 <- datos_paso5 %>%
  mutate(
    Q1 = quantile(ingresos, 0.25, na.rm=TRUE),
    Q3 = quantile(ingresos, 0.75, na.rm=TRUE),
    IQR = Q3 - Q1,
    outlier = ingresos < (Q1 - 1.5*IQR) | 
              ingresos > (Q3 + 1.5*IQR)
  )

cat("Outliers detectados:", sum(datos_paso6$outlier), "\n")
datos_paso6 %>% filter(outlier) %>% 
  select(id, sector, ingresos)


## ----ex5, eval=TRUE, echo=TRUE-----------------------------------------------------------------
# Estadísticas de ingresos
summary(datos_paso6$ingresos)

# Valores extremos
datos_paso6 %>% 
  filter(outlier) %>%
  select(id, sector, ingresos, empleados)


## ----derived, eval=TRUE, echo=TRUE-------------------------------------------------------------
datos_limpios <- datos_paso6 %>%
  mutate(
    # Eficiencia operativa
    ingreso_per_capita = ingresos / empleados,
    
    # Categorización por escala
    categoria_tamaño = case_when(
      empleados < 100 ~ "Pequeña",
      empleados < 200 ~ "Mediana",
      TRUE ~ "Grande"
    ),
    
    # Período de análisis
    periodo = paste0(ano, "-", 
                     str_pad(mes, 2, pad="0"))
  ) %>%
  # Eliminar variables auxiliares
  select(-starts_with("Q1"), -starts_with("Q3"), 
         -starts_with("IQR"), -ingreso_negativo)

head(datos_limpios)


## ----ex6, eval=TRUE, echo=TRUE-----------------------------------------------------------------
# Validar variable derivada
resumen_eficiencia <- datos_limpios %>%
  group_by(sector) %>%
  summarise(
    ingreso_promedio = mean(ingresos, na.rm=TRUE),
    empleados_promedio = mean(empleados, na.rm=TRUE),
    eficiencia_promedio = mean(ingreso_per_capita, 
                               na.rm=TRUE),
    .groups = 'drop'
  )

print(resumen_eficiencia)


## ----dictionary, eval=TRUE, echo=TRUE----------------------------------------------------------
diccionario_datos <- tibble(
  variable = colnames(datos_limpios),
  descripcion = c(
    "Identificador único del registro",
    "Fecha de la transacción",
    "Sector económico", "Ingresos en USD",
    "Cantidad de empleados",
    "Año de la transacción",
    "Mes de la transacción (1-12)",
    "Outlier según método IQR",
    "Ingresos por empleado (USD)",
    "Categoría por número de empleados",
    "Período YYYY-MM"
  ),
  tipo = c("Numérico", rep(c("Fecha", "Categoría", "Numérico",
                              "Numérico"), 2), "Lógico",
           "Numérico"),
  unidad = c("-", "YYYY-MM-DD", "-", "USD", "Unidades",
             "Años", "Mes", "-", "USD/empleado", "-", "YYYY-MM")
)

print(diccionario_datos)


## ----export, eval=TRUE, echo=TRUE--------------------------------------------------------------
# Exportar datos limpios
write_csv(datos_limpios, "datos_preparados.csv")

# Exportar diccionario
write_csv(diccionario_datos, "diccionario_variables.csv")

cat("Archivos generados:\n")
cat("✓ datos_preparados.csv\n")
cat("✓ diccionario_variables.csv\n")


## ----ex7, eval=TRUE, echo=TRUE-----------------------------------------------------------------
# Resumen de calidad final
cat("=== CONTROL DE CALIDAD FINAL ===\n")
cat("Registros:", nrow(datos_limpios), "\n")
cat("Variables:", ncol(datos_limpios), "\n")
cat("Valores faltantes totales:", 
    sum(is.na(datos_limpios)), "\n")
cat("Completitud:", 
    round(100 * (1 - sum(is.na(datos_limpios)) / 
                 (nrow(datos_limpios) * ncol(datos_limpios))), 1),
    "%\n")


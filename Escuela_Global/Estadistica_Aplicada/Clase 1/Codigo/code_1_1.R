
# --- Cargar librerías --------------------------------------------------------

library(tidyverse)
library(readr)
library(writexl)



# --- PASO 0: Definir directorio ---------------------------------------------

#Verificar el entrono:
getwd()
setwd("C:/Users/UsuarioNuevo/Documents/Clases/Escuela_Global/Estadistica_Aplicada/Clase 1/Ejercicios")
getwd()

# --- PASO 1: Importar CSV ---------------------------------------------------

datos_raw <- read_csv(
  "dataset_comercio.csv",
  locale = locale(encoding = "UTF-8"),
  col_types = cols(
    id             = col_integer(),
    fecha          = col_character(),
    pais           = col_character(),
    sector         = col_character(),
    tipo_operacion = col_character(),
    monto_usd      = col_character(),   # Texto (tiene símbolos $)
    volumen_ton    = col_double(),
    empleados      = col_integer(),
    arancel_pct    = col_double(),
    partida_arancelaria = col_character(),
    num_factura    = col_character()
  )
)


#problems()

cat("Registros importados:", nrow(datos_raw), "\n")

# --- PASO 2: Eliminar duplicados (filas completas) --------------------------

datos <- datos_raw %>%
  distinct()

cat("Después de duplicados completos:", nrow(datos), "\n")

# --- PASO 3: Eliminar duplicados por num_factura ----------------------------

datos <- datos %>%
  distinct(num_factura, .keep_all = TRUE)

cat("Después de duplicados por factura:", nrow(datos), "\n")

# --- PASO 4: Limpiar columna "pais" -----------------------------------------
# Recortar espacios → Mayúsculas → Extraer primeros 2 caracteres
# NOTA: El recorte a 2 caracteres es un ERROR INTENCIONAL de demostración.
# Convierte "PERÚ" → "PE", "CHILE" → "CH", etc.

datos <- datos %>%
  mutate(
    pais = str_trim(pais),
    pais = toupper(pais),
    pais = str_sub(pais, 1, 2)          
  )

# --- PASO 5: Limpiar columna "sector" ---------------------------------------

datos <- datos %>%
  mutate(
    sector = str_trim(sector),
    sector = toupper(sector)
  )

# --- PASO 6: Limpiar columna "tipo_operacion" --------------------------------

datos <- datos %>%
  mutate(
    tipo_operacion = str_trim(tipo_operacion),
    tipo_operacion = toupper(tipo_operacion),
    tipo_operacion = str_replace(tipo_operacion, "^IMPORT$", "IMPORTACIÓN"),
    tipo_operacion = str_replace(tipo_operacion, "^EXPORT$", "EXPORTACIÓN")
  )

# --- PASO 7: Limpiar columna "monto_usd" ------------------------------------
# Quitar símbolo $ y comas → convertir a numérico

datos <- datos %>%
  mutate(
    monto_usd = str_remove_all(monto_usd, "\\$"),
    monto_usd = str_remove_all(monto_usd, ","),
    monto_usd = as.numeric(monto_usd)
  )

# --- PASO 8: Valor absoluto en columnas numéricas ----------------------------

datos <- datos %>%
  mutate(
    volumen_ton = abs(volumen_ton),
    monto_usd   = abs(monto_usd),
    empleados   = abs(empleados)
  )

# --- PASO 9: Imputar datos faltantes ----------------------------------------
# En el pipeline de Power Query:
#   - arancel_pct  → null reemplazado con 12.27 (mediana)
#   - empleados    → null reemplazado con 268 (mediana)
#   - monto_usd    → NO se imputa (la rama quedó huérfana en M)
#
# NOTA: En el código M original, "Valor reemplazado2" (monto_usd null → 114.9)
# no se conecta al pipeline porque "Personalizado1" referencia directamente
# a "Valor absoluto calculado", no a "Valor reemplazado2".
# Por lo tanto, monto_usd conserva sus null y se filtra en el paso siguiente.

datos <- datos %>%
  mutate(
    arancel_pct = replace_na(arancel_pct, 12.27),
    empleados   = replace_na(empleados, 268L)
  )

# --- PASO 10: Filtrar filas con valores faltantes en columnas críticas -------

datos <- datos %>%
  filter(
    !is.na(monto_usd),
    fecha != "" & !is.na(fecha),
    pais  != "" & !is.na(pais),
    sector != "" & !is.na(sector),
    num_factura != "" & !is.na(num_factura)
  )

cat("Después de filtrar faltantes:", nrow(datos), "\n")

# --- PASO 11: Eliminar los 3 outliers superiores en monto_usd ---------------
# En Power Query: ordenar descendente por monto → skip top 3 rows

datos <- datos %>%
  arrange(desc(monto_usd)) %>%
  slice(-(1:3))

cat("Después de quitar 3 outliers top:", nrow(datos), "\n")

# --- PASO 12: Ordenar por id ascendente -------------------------------------

datos <- datos %>%
  arrange(id)

# ============================================================================
# DIAGNÓSTICO POST-LIMPIEZA
# ============================================================================

cat("\n========================================\n")
cat("RESUMEN DE LIMPIEZA\n")
cat("========================================\n")
cat("Registros originales:", nrow(datos_raw), "\n")
cat("Registros finales:   ", nrow(datos), "\n")
cat("Eliminados:          ", nrow(datos_raw) - nrow(datos), "\n")
cat("Columnas:            ", ncol(datos), "\n")

cat("\n--- Valores faltantes restantes ---\n")
print(colSums(is.na(datos)))

cat("\n--- Tipos de dato ---\n")
print(sapply(datos, class))

cat("\n--- Valores únicos en texto ---\n")
cat("pais:          ", n_distinct(datos$pais), "→", 
    paste(sort(unique(datos$pais)), collapse = ", "), "\n")
cat("sector:        ", n_distinct(datos$sector), "→", 
    paste(sort(unique(datos$sector)), collapse = ", "), "\n")
cat("tipo_operacion:", n_distinct(datos$tipo_operacion), "→", 
    paste(sort(unique(datos$tipo_operacion)), collapse = ", "), "\n")

cat("\n--- Estadísticas numéricas ---\n")
datos %>%
  summarise(
    monto_min  = min(monto_usd, na.rm = TRUE),
    monto_med  = median(monto_usd, na.rm = TRUE),
    monto_max  = max(monto_usd, na.rm = TRUE),
    vol_min    = min(volumen_ton, na.rm = TRUE),
    vol_med    = median(volumen_ton, na.rm = TRUE),
    vol_max    = max(volumen_ton, na.rm = TRUE),
    emp_min    = min(empleados, na.rm = TRUE),
    emp_med    = median(empleados, na.rm = TRUE),
    emp_max    = max(empleados, na.rm = TRUE)
  ) %>%
  glimpse()

# ============================================================================
# EXPORTAR
# ============================================================================

write.csv(datos, "datos_comercio_limpio.csv", 
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\n✓ Archivo exportado: datos_comercio_limpio.csv\n")
cat("  Filas:", nrow(datos), "| Columnas:", ncol(datos), "\n")

write_xlsx(datos, "datos_comercio_limpio.xlsx")


#locale = locale(encoding = "UTF-8")
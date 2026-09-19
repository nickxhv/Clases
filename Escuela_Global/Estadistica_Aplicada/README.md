# Estadística Descriptiva e Inferencial Aplicada con Softwares e IA



!\[Stata](https://img.shields.io/badge/Stata-17-2E5C8A?style=for-the-badge)

!\[R](https://img.shields.io/badge/R-4.0%2B-276DC3?style=for-the-badge)

!\[Quarto](https://img.shields.io/badge/Quarto-1.3%2B-FF6B6B?style=for-the-badge)

!\[Excel](https://img.shields.io/badge/Excel-2019%2B-21A366?style=for-the-badge)







Materiales del curso dictado en **Escuela Global**: diapositivas, código, ejercicios y soluciones.

El curso recorre el ciclo completo del análisis de datos, desde la limpieza hasta el pronóstico, con un enfoque **Excel-First**: cada técnica se construye primero en la hoja de cálculo, donde el participante ya sabe moverse, y migra a R y Stata cuando la hoja de cálculo se queda corta.

\---

## Estructura del repositorio

```
Escuela\_Global/
└── Estadistica\_Aplicada/
    ├── Clase 1/          Sesiones 0 y 1 — Introducción y primeros pasos
    │   ├── Codigo/
    │   ├── Diapositivas/
    │   └── Ejercicios/
    ├── Clase 2/          Sesiones 2 y 3 — Limpieza, descriptiva y visualización
    │   ├── Code/
    │   ├── Data/
    │   ├── Diapositivas/
    │   └── Ejercicios/
    ├── Clase 3/          Sesión 4 — Probabilidad e inferencia
    │   ├── Code/
    │   ├── Data/
    │   └── Ejercicios/
    └── Clase 4/          Sesión 5 — Regresión lineal y series de tiempo
        ├── Code/
        ├── Data/
        ├── Diapositivas/
        └── Ejercicios/
```

Convención de carpetas dentro de cada clase:

|Carpeta|Contenido|
|-|-|
|`Code/`|Do-files de Stata y scripts de R|
|`Data/`|Datasets de trabajo (ver [Datos](#datos))|
|`Diapositivas/`|Fuentes Quarto (`.qmd`) y PDF compilados|
|`Ejercicios/`|Enunciados, soluciones, gráficos y logs de resultados|

\---

## Contenido por sesión

|Sesión|Carpeta|Temas|
|-|-|-|
|0 y 1|Clase 1|Presentación del curso, tipos de datos, primeros pasos en R|
|2|Clase 2|Limpieza y modelamiento de datos|
|3|Clase 2|Estadística descriptiva y visualización|
|4|Clase 3|Probabilidad, inferencia y diseño muestral complejo|
|5|Clase 4|Regresión lineal, diagnóstico de supuestos, series de tiempo y ARIMA|

\---

## Software

|Herramienta|Uso|
|-|-|
|**Excel**|Capa fundacional: toda técnica se introduce aquí primero|
|**Stata**|Análisis principal, especialmente inferencia con diseño muestral|
|**R**|Visualización con `ggplot2` y análisis complementario|
|**Quarto + Beamer**|Generación de las diapositivas|

### Paquetes de Stata

```stata
ssc install estout, replace
```

`estout` no viene con Stata y es necesario para las tablas comparativas de modelos (`eststo`, `esttab`).

### Paquetes de R

```r
install.packages(c("tidyverse", "ggplot2", "readxl", "haven", "gt"))
```

\---

## Datos

Los archivos `.dta` están excluidos del repositorio mediante `.gitignore`, con una excepción:

|Archivo|¿Incluido?|Motivo|
|-|-|-|
|`series\_peru.dta`|Sí|84 observaciones, tamaño mínimo|
|`enaho01a-2025-500.dta`|No|\~909 MB, supera el límite de 100 MB de GitHub|

### Cómo obtener los microdatos de la ENAHO

1. Ingresar al portal de microdatos del INEI: [https://proyectos.inei.gob.pe/microdatos/](https://proyectos.inei.gob.pe/microdatos/)
2. Seleccionar **Encuesta Nacional de Hogares (ENAHO)**, año **2025**, formato **Stata**
3. Descargar el **Módulo 500 – Empleo e Ingresos**
4. Colocar el archivo `enaho01a-2025-500.dta` en la carpeta `Data/` de las clases 2, 3 y 4

Los do-files usan rutas relativas a través de globals, de modo que solo hay que ajustar la raíz:

```stata
global main "RUTA/A/TU/CARPETA/Clase 4"
global code   "$main/Code"
global data   "$main/Data"
global output "$main/Ejercicios"
```

### Variables principales de la ENAHO

|Variable|Descripción|
|-|-|
|`i524a1`|Ingreso por trabajo dependiente|
|`p208a`|Edad|
|`estrato`|Estrato geográfico (base para construir área urbano/rural)|
|`fac500a`|Factor de expansión|
|`conglome`|Conglomerado (unidad primaria de muestreo)|

**Nota metodológica.** La ENAHO tiene diseño muestral complejo. Toda inferencia poblacional debe declararse con:

```stata
svyset conglome \[pw=fac500a], strata(estrato)
```

y estimarse con el prefijo `svy:`. Los comandos sin ponderar que aparecen en el material tienen fines pedagógicos, para contrastar resultados.

### `series\_peru.dta`

Series macroeconómicas trimestrales del Perú, 2000q1–2020q4 (84 observaciones): PIB, recaudación tributaria, exportaciones e importaciones, en millones de soles.

\---

## Cómo usar este material

**Para reproducir los resultados de Stata:**

```stata
cd "RUTA/A/Clase 4/Code"
do "Sesion\_5\_Regresion\_Series.do"
```

Cada carpeta `Ejercicios/` contiene el `.log` con la salida completa esperada, útil para verificar que la reproducción fue correcta.

**Para recompilar las diapositivas:**

```bash
quarto render Sesion\_5\_Regresion\_SeriesTiempo.qmd
```

Los bloques de código usan `echo: fenced` y `eval: false`, de modo que los participantes pueden extraerlos con:

```r
knitr::purl("Sesion\_5\_Regresion\_SeriesTiempo.qmd")
```

\---

## Notas

* El material está en español y es agnóstico al sector: los ejemplos se adaptan a finanzas, retail, manufactura y comercio exterior.
* Los ejercicios están ponderados 70 % Excel y 30 % Stata/R.
* Los datasets simulados incluyen problemas realistas de forma deliberada (valores faltantes, outliers, quiebres metodológicos). No son datos limpios de juguete.

\---

## Autor

**Nick Hurtado**

\---

## Licencia

Material educativo de uso libre con atribución. Los microdatos de la ENAHO son propiedad del INEI y están sujetos a sus propios términos de uso.


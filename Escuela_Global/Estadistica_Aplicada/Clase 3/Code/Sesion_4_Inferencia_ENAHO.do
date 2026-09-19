// ============ Sesion 4: Probabilidad e Inferencia ===
// ======= Autor: Nick Hurtado ========================
// ====================================================


global main  "C:\Users\UsuarioNuevo\Documents\Clases\Escuela_Global\Estadistica_Aplicada\Clase 3"
global code   "$main/Code"
global data   "$main/Data"
global output "$main/Ejercicios"

cd "$output"

pwd
dir


// ================================================================
//     BLOQUE 0: CARGAR DATOS Y PREPARAR VARIABLES (INDISPENSABLE)
// ================================================================
// NOTA: Este bloque es obligatorio. Sin él, "area_res" no existe
// y todos los comandos siguientes fallarán con "variable not found".

use "$data/enaho01a-2025-500.dta", clear

gen area_res = .
replace area_res = 1 if inlist(estrato, 1, 2, 3, 4, 5)
replace area_res = 2 if inlist(estrato, 6, 7, 8)

label define area_lbl 1 "Urbano" 2 "Rural"
label values area_res area_lbl
label variable area_res "Área de residencia"


// ================================================================
//     BLOQUE 1: DISTRIBUCIÓN NORMAL
// ================================================================

** ¿El ingreso se distribuye normalmente?

** Histograma con curva normal superpuesta
hist i524a1 if i524a1 > 0 & i524a1 < 10000, ///
    normal frequency bin(30) ///
    title("¿El ingreso sigue una distribución normal?") ///
    subtitle("Histograma con curva normal superpuesta") ///
    xtitle("Ingreso mensual (S/)") ///
    color(navy%60) lcolor(white) ///
    normopts(lcolor(cranberry) lwidth(thick)) ///
    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(hist_normal, replace)

graph export "hist_normal.png", replace width(1200)

** Gráfico Q-Q (quantile-quantile)
** Si los puntos caen sobre la línea → distribución normal
qnorm i524a1 if i524a1 > 0 & i524a1 < 10000, ///
    title("Gráfico Q-Q del ingreso") ///
    subtitle("Puntos sobre la línea = normalidad") ///
    mcolor(navy%50) msize(tiny) ///
    rlopts(lcolor(cranberry) lwidth(medthick)) ///
	    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(qq_ingreso, replace)

graph export "qq_normal.png", replace width(1200)

** Histogramas superpuestos Urbano vs Rural
twoway ///
    (hist i524a1 if area_res == 1 & i524a1 > 0 & i524a1 < 10000, ///
        frequency color(navy%40) lcolor(navy) bin(30)) ///
    (hist i524a1 if area_res == 2 & i524a1 > 0 & i524a1 < 10000, ///
        frequency color(cranberry%40) lcolor(cranberry) bin(30)), ///
    title("Distribución del ingreso: Urbano vs Rural") ///
    xtitle("Ingreso (S/)") ytitle("Frecuencia") ///
    legend(order(1 "Urbano" 2 "Rural")) ///
	    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(hist_urb_rur, replace)

graph export "hist_urbano_rural.png", replace width(1200)

** Histograma con densidad kernel
hist i524a1 if i524a1 > 0 & i524a1 < 10000, ///
    density bin(30) ///
    title("Densidad del ingreso") ///
    color(navy%50) lcolor(white) ///
    addplot(kdensity i524a1 if i524a1 > 0 & i524a1 < 10000, ///
            lcolor(cranberry) lwidth(medthick)) ///
    legend(order(1 "Histograma" 2 "Densidad kernel")) ///
	    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(hist_kde, replace)

graph export "hist_kde.png", replace width(1200)

** Test formal de normalidad (Shapiro-Wilk)
** Nota: solo funciona bien con muestras < 5000
swilk i524a1 if _n <= 2000 & i524a1 > 0
** Si p < 0.05 → Rechazar normalidad

** Funciones de probabilidad normal en Stata
** P(X <= 2000) con mu=1800, sigma=700
display "P(X<=2000) = " normal((2000-1800)/700)

** Percentil 90
display "Percentil 90 = " 1800 + invnormal(0.90)*700

** Z-score de S/ 3500
display "Z-score de 3500 = " (3500-1800)/700

** Conclusión: El ingreso NO es normal (sesgado derecha)
** Pero el TLC garantiza que las MEDIAS sí son normales


// ================================================================
//     BLOQUE 2: PROBABILIDAD CONDICIONAL
// ================================================================

** P(Urbano) y P(Rural)
tab area_res [iw=fac500a], missing

** Crear variable indicadora de ingreso alto
gen ingreso_alto = (i524a1 > 2000 & i524a1 != .)
label define ialto_lbl 0 "<= S/ 2000" 1 "> S/ 2000"
label values ingreso_alto ialto_lbl

** Tabla cruzada: P(ingreso > 2000 | área)
** Sin factor (solo la muestra)
tabulate area_res ingreso_alto, row

** Con factor (estimación poblacional)
tabulate area_res ingreso_alto [iw=fac500a], row

** Lectura: "De los urbanos, X% gana más de S/ 2000"
**          "De los rurales, Y% gana más de S/ 2000"
** ¿Son significativamente distintos? → Lo probamos abajo


// ================================================================
//     BLOQUE 3: DECLARAR DISEÑO MUESTRAL
// ================================================================

** IMPORTANTE: La ENAHO es una encuesta compleja
** Tiene conglomerados, estratos y factores de expansión
** Sin svyset, los errores estándar están SUBESTIMADOS

svyset conglome [pw=fac500a], strata(estrato)

** Verificar
svydescribe


// ================================================================
//     BLOQUE 4: INTERVALOS DE CONFIANZA
// ================================================================

** ----- IC sin diseño muestral (INCORRECTO para encuestas) -----
ci means i524a1

** ----- IC con diseño muestral (CORRECTO) -----
svy: mean i524a1

** ----- IC por área de residencia -----
svy: mean i524a1, over(area_res)

** ----- IC por dominio geográfico -----
svy: mean i524a1, over(dominio)

** ----- Graficar IC por área -----
svy: mean i524a1, over(area_res)
marginsplot, ///
    title("IC 95% del ingreso por área") ///
    ytitle("Ingreso promedio (S/)") ///
    recast(bar) ///
    plotopts(barwidth(0.5) color(navy%70)) ///
    ciopts(lcolor(cranberry) lwidth(thick)) ///
	    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(ic_area, replace)

graph export "ic_por_area.png", replace width(1200)

** ----- Graficar IC por dominio -----
svy: mean i524a1, over(dominio)
marginsplot, ///
    title("IC 95% del ingreso por dominio") ///
    ytitle("Ingreso promedio (S/)") ///
    xlabel(, angle(45) labsize(small)) ///
    ciopts(lcolor(cranberry)) ///
	    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(ic_dominio, replace)

graph export "ic_por_dominio.png", replace width(1400)


// ================================================================
//     BLOQUE 5: PRUEBA T DE UNA MUESTRA
// ================================================================

** Pregunta: ¿El ingreso promedio es S/ 2000?
** H0: μ = 2000
** H1: μ ≠ 2000

** Sin diseño muestral (referencia)
ttest i524a1 == 2000

** Con diseño muestral (CORRECTO)
svy: mean i524a1
test _b[i524a1] = 2000

** Leer resultado:
** F(1, gl) = xxx
** Prob > F = 0.0000  →  p < 0.05 → Rechazar H0
** El ingreso promedio es significativamente distinto de S/ 2000

** También se puede con ttesti (sin datos, solo estadísticos)
** ttesti n media desv valor_h0
** ttesti 200 1850 580 2000


// ================================================================
//     BLOQUE 6: PRUEBA T DE DOS MUESTRAS
// ================================================================

** Pregunta: ¿El ingreso es diferente entre urbano y rural?
** H0: μ_urbano = μ_rural
** H1: μ_urbano ≠ μ_rural

** Sin diseño muestral (referencia, NO para reportar)
ttest i524a1, by(area_res)

** Con diseño muestral (CORRECTO)
svy: mean i524a1, over(area_res)


** Resultado esperado:
** Diferencia ≈ S/ 9,426 (muestral) o similar con svy
** p < 0.001 → Rechazar H0: la diferencia ES significativa

** ----- Visualizar la diferencia -----

** Calcular medias para las líneas 
summarize i524a1 if area_res == 1 & i524a1 > 0, meanonly
local media_urb = r(mean)
summarize i524a1 if area_res == 2 & i524a1 > 0, meanonly
local media_rur = r(mean)

** Histogramas superpuestos con medias marcadas(Se deben correr junto con las medidas de lineas)
twoway ///
    (hist i524a1 if area_res == 1 & i524a1 > 0 & i524a1 < 8000, ///
        frequency color(navy%30) bin(30)) ///
    (hist i524a1 if area_res == 2 & i524a1 > 0 & i524a1 < 8000, ///
        frequency color(cranberry%30) bin(30)), ///
    xline(`media_urb', lcolor(navy) lpattern(dash) lwidth(medthick)) ///
    xline(`media_rur', lcolor(cranberry) lpattern(dash) lwidth(medthick)) ///
    title("Distribución del ingreso: Urbano vs. Rural") ///
    subtitle("Líneas punteadas = medias de cada grupo") ///
    xtitle("Ingreso (S/)") ///
    ytitle("Frecuencia") ///
    legend(order(1 "Urbano" 2 "Rural") rows(1)) ///
    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(hist_ttest, replace)

graph export "hist_ttest_urbano_rural.png", replace width(1400)

** Boxplot con nota de significancia
graph box i524a1 if i524a1 > 0 & i524a1 < 10000, ///
    over(area_res) ///
    title("Distribución del ingreso por área") ///
    subtitle("¿La diferencia es estadísticamente significativa?") ///
    ytitle("Ingreso (S/)") ///
    box(1, color(navy%70)) box(2, color(cranberry%70)) ///
    note("Fuente: ENAHO 2025 | Prueba t (svy): p < 0.001") ///
	    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(box_ttest, replace)

graph export "box_ttest_area.png", replace width(1200)


// ================================================================
//     BLOQUE 7: PRUEBAS POR MÚLTIPLES GRUPOS
// ================================================================

** Pregunta: ¿Hay diferencia de ingresos entre TODOS los dominios?
svy: mean i524a1, over(dominio)

** Comparaciones de pares con lincom (usando las ETIQUETAS del dominio)
** Si el nombre de la etiqueta tiene espacios, usar comillas compuestas:
** lincom `"Lima Metropolitana"' - `"Costa Norte"'
**
** Ejemplo genérico (ajustar nombres según las etiquetas reales de tu base):
** lincom `"Lima Metropolitana"' - `"Sierra Sur"'

** Ver los nombres exactos de las categorías estimadas:
ereturn list
matrix list e(b)

** Graficar IC por dominio
svy: mean i524a1, over(dominio)
marginsplot, ///
    title("IC 95% del ingreso por dominio") ///
    subtitle("Intervalos que no se traslapan → diferencia significativa") ///
    ytitle("Ingreso promedio (S/)") ///
    xlabel(, angle(45) labsize(small)) ///
    ciopts(lcolor(cranberry) lwidth(medthick)) ///
	    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(ic_dom_final, replace)

graph export "ic_dominios.png", replace width(1400)


// ================================================================
//     BLOQUE 8: PRUEBA CHI-CUADRADO
// ================================================================

** Pregunta: ¿El área de residencia está asociada al tipo de pago principal?
** H0: Son independientes (no hay asociación)
** H1: Están asociadas

** Sin factor
tabulate area_res p523, chi2

** Con frecuencias esperadas
tabulate area_res p523, expected chi2

** Con factor (CORRECTO)
svy: tabulate area_res p523, pearson

** Con porcentajes por fila
svy: tabulate area_res p523, row

** Leer resultado:
** Pearson: Design-based F(...) = xxx
** P-value = 0.0000
** → Rechazar H0: SÍ hay asociación entre área y tipo de vivienda


// ================================================================
//     BLOQUE 9: COMPARACIÓN ttest vs svy
// ================================================================

** DEMOSTRACIÓN: ¿Por qué importa el diseño muestral?

** Sin svy (errores estándar subestimados)
mean i524a1, over(area_res)

** Con svy (errores estándar correctos)
svy: mean i524a1, over(area_res)

** COMPARAR los errores estándar:
** Sin svy: SE más pequeño → IC más estrecho → falsa precisión
** Con svy: SE más grande → IC más ancho → conclusiones correctas

** Regla: Con datos de encuesta → SIEMPRE usar svy


// ================================================================
//     BLOQUE 10: GRÁFICO FINAL PROFESIONAL
// ================================================================

** Gráfico final: Ingreso por dominio (profesional)
graph hbar (mean) i524a1 [pw=fac500a], ///
    over(dominio, sort(1) descending) ///
    title("Ingreso promedio mensual por dominio geográfico", size(medium)) ///
    subtitle("Ocupación principal - PEA ocupada", size(small)) ///
    ytitle("Ingreso promedio (S/)") ///
    bar(1, color(navy%80)) ///
    blabel(bar, format(%9.0fc) size(small) position(inside) color(white)) ///
    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Factor de expansión: fac500a" ///
         "Elaboración:Econ. Nick Hurtado Valladolid") ///
    name(final_hbar, replace)

graph export "ingreso_por_dominio.png", replace width(1400)

** Gráfico final: Ingreso vs Edad por área (profesional)
twoway ///
    (scatter i524a1 p208a if area_res == 1 & i524a1 > 0 & i524a1 < 15000, ///
        mcolor(navy%15) msize(tiny) msymbol(circle)) ///
    (scatter i524a1 p208a if area_res == 2 & i524a1 > 0 & i524a1 < 15000, ///
        mcolor(cranberry%15) msize(tiny) msymbol(triangle)) ///
    (qfit i524a1 p208a if area_res == 1 & i524a1 > 0 & i524a1 < 15000, ///
        lcolor(navy) lwidth(thick)) ///
    (qfit i524a1 p208a if area_res == 2 & i524a1 > 0 & i524a1 < 15000, ///
        lcolor(cranberry) lwidth(thick)), ///
    title("Relación Ingreso-Edad por Área de Residencia", size(medium)) ///
    subtitle("Ajuste cuadrático", size(small)) ///
    xtitle("Edad (años)") ytitle("Ingreso mensual (S/)") ///
    legend(order(3 "Urbano" 4 "Rural") rows(1) position(6)) ///
    note("Fuente: ENAHO 2025 - Módulo 500" ///
         "Elaboración: Econ. Nick Hurtado Valladolid") ///
    name(final_scatter, replace)

graph export "ingreso_edad_area.png", replace width(1400)


// ================================================================
//     BLOQUE 11: EXPORTAR MASIVO
// ================================================================

** Exportar todos los gráficos creados en ESTE do-file
** (lista corregida: solo nombres realmente generados arriba)
foreach g in hist_normal qq_ingreso hist_urb_rur hist_kde ///
             ic_area ic_dominio ic_dom_final ///
             hist_ttest box_ttest ///
             final_hbar final_scatter {
    capture graph display `g'
    if _rc == 0 {
        graph export "`g'.png", replace width(1200)
    }
    else {
        display "Gráfico no encontrado en memoria: `g'"
    }
}
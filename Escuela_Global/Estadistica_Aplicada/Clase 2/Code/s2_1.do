
// ============ Sesion 3: Visualización ===============
// ======= Autor: Nick Hurtado ========================
// ====================================================




global main  "C:\Users\UsuarioNuevo\Documents\Clases\Escuela_Global\Estadistica_Aplicada\Clase 2"
global code   "$main/Code"
global data   "$main/Data"
global output "$main/Ejercicios"


cd "$output"


** Conocer dirección: pwd (Print Working Direction)
pwd



** Conocer el listado de archivos:
dir


** Importamos los datos de Enaho - 2025

use "$data/enaho01a-2025-500.dta", clear


** Summarize: Resumen estadistico
// summarize
// help summarize
// i524a1: Cuanto fue su ingreso total . incluyendo  hora extra etc (IMPUTADO) ----> Ingreso monetario ocupación principal
summarize dominio

// Usando el parametro detail: 
summarize dominio, detail


// Resumen de mas de una variable:
summarize dominio estrato, detail

// Otra manera de obtener datos: 
tabstat dominio estrato i524a1 , statistics(mean max min range)

tabstat dominio estrato i524a1, statistics(mean max min range) columns(statistics)


tabstat  i524a1, by(dominio) statistics(mean max min range)

// Intervalos:  ameans ¿Cuantas medias existen? 

ameans i524a1


// Crear variables y labels:

gen area_res = .

replace area_res = 1 if inlist(estrato, 1, 2, 3, 4, 5)
replace area_res = 2 if inlist(estrato, 6, 7, 8)

label define area_lbl ///
    1 "Urbano" ///
    2 "Rural"

label values area_res area_lbl
	
label variable area_res "Área de residencia"


table area_res, missing format(%8.0fc)
table area_res [iweight=fac500a], missing format(%12.0fc)


// Tablas cruzadas
// area_res: area de residencia

tabulate dominio area_res [iweight=fac500a]

// GRAFICOS //


// Histograma: 
hist i524a1, frequency title("Distribución del ingreso bruto toal ") xtitle("Nivel de vivienda") color(navy)

// Grafico de barra: Valores en X discretos
graph bar (count), over(area_res, label(angle(45))) ///
    title("Nivel de vivienda") ///
    bar(1, color(navy))

// Uso de etiquetas:	
graph bar (count), over(area_res, label(angle(45))) ///
    title("Nivel de vivienda") ///
    ytitle("Frecuencia") ///
    bar(1, color(navy)) ///
    blabel(bar, format(%9.0fc))
	
// Uso de factores:	
graph bar (count) [pw=fac500a], over(area_res) asyvars ///
    title("Nivel de vivienda (Con Factor)") ///
    ytitle("Frecuencia expandida") ///
    bar(1, color(navy)) ///
    blabel(bar, format(%12.0fc) size(small)) ///
	ylabel(none) ///
	legend(rows(4) size(vsmall)) ///
	name(g1, replace)
	
	
graph bar (count) , over(area_res)  asyvars ///
    title("Nivel de vivienda (Sin Factor)") ///
    ytitle("Frecuencia ") ///
    bar(1, color(navy)) ///
    blabel(bar, format(%12.0fc) size(small)) ///
	ylabel(none) ///
	legend(rows(4) size(vsmall)) ///
	name(g2, replace)

	
// Graficos combinados	
graph combine g1 g2, ///
    title("Nivel de vivienda: muestra vs población") ///
    rows(1) ///
//     xsize(30) ysize(50)

graph export "comparacion_factor_vivienda.png", replace width(1600)

// BOX PLOT

// Boxplot básico del ingreso
graph box i524a1, ///
    title("Distribución del ingreso") ///
    ytitle("Ingreso (S/)") ///
    name(box1, replace)


graph box i524a1 if i524a1 > 0 & i524a1 < 15000, ///
    title("Distribución del ingreso") ///
    ytitle("Ingreso (S/)") ///
    name(box1, replace)


graph box i524a1 if i524a1 > 0 & i524a1 < 15000, ///
    over(area_res) ///
    title("Distribución del ingreso por área") ///
    subtitle("ENAHO 2025 - Ingreso ocupación principal") ///
    ytitle("Ingreso mensual (S/)") ///
    note("Se excluyen ingresos > S/ 15,000 para mejor visualización") ///
    name(box_area, replace)
	
	
// Boxplot horizontal (más legible con muchas categorías)
graph hbox i524a1 if i524a1 > 0 & i524a1 < 15000, ///
    over(dominio, sort(1) descending) ///
    title("Distribución del ingreso por dominio") ///
    box(1, color(navy%70)) ///
    name(hbox_dom, replace)
	
// Dispersión: Edad vs Ingreso
// p208a: edad en años
twoway scatter i524a1 p208a if i524a1 > 0 & i524a1 < 20000, ///
    title("Ingreso según edad") ///
    xtitle("Edad (años)") ///
    ytitle("Ingreso mensual (S/)") ///
    mcolor(navy%30) msize(tiny) ///
    name(sc1, replace)

// Scatter + línea de regresión lineal
twoway ///
    (scatter i524a1 p208a if i524a1 > 0 & i524a1 < 20000, ///
        mcolor(navy%20) msize(tiny)) ///
    (lfit i524a1 p208a if i524a1 > 0 & i524a1 < 20000, ///
        lcolor(cranberry) lwidth(medthick)), ///
    title("Ingreso según edad (con ajuste lineal)") ///
    xtitle("Edad (años)") ///
    ytitle("Ingreso mensual (S/)") ///
    legend(order(1 "Observaciones" 2 "Ajuste lineal") rows(1)) ///
    name(sc_lfit, replace)


	
// Modificaciones de base: Preserve + bar
preserve

    collapse (mean) ing_prom = i524a1 [pw=fac500a], by(dominio)

    graph bar (asis) ing_prom, ///
        over(dominio, sort(1) descending label(angle(45) labsize(small))) ///
        title("Ingreso promedio expandido por dominio") ///
        ytitle("Ingreso promedio (S/)") ///
        bar(1, color(navy%80)) ///
        blabel(bar, format(%9.0fc) size(small)) ///
        name(collapse_bar, replace)

restore


// Gráfico circular: distribución por área
graph pie [pw=fac500a], over(area_res) ///
    title("Distribución de la PEA por área") ///
    plabel(_all percent, format(%4.1f) size(small)) ///
    legend(rows(1)) ///
    name(pie_area, replace)

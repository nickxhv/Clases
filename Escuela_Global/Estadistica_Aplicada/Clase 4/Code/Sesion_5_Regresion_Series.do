// ============ Sesion 5: Regresión y Series de Tiempo ==
// ======= Autor: Nick Hurtado ==========================
// =======================================================


global main  "C:\Users\UsuarioNuevo\Documents\Clases\Escuela_Global\Estadistica_Aplicada\Clase 4"
global code   "$main/Code"
global data   "$main/Data"
global output "$main/Ejercicios"

cd "$output"

ssc install estout, replace

// ================================================================
// ================================================================
//     BLOQUE A: REGRESIÓN LINEAL (ENAHO 2025 - Módulo 500)
// ================================================================
// ================================================================

use "$data/enaho01a-2025-500.dta", clear

** Preparar variable de área (heredado de sesiones anteriores)
gen area_res = .
replace area_res = 1 if inlist(estrato, 1, 2, 3, 4, 5)
replace area_res = 2 if inlist(estrato, 6, 7, 8)

label define area_lbl 1 "Urbano" 2 "Rural"
label values area_res area_lbl
label variable area_res "Área de residencia"

svyset conglome [pw=fac500a], strata(estrato)


// ----------------------------------------------------------------
// 1. REGRESIÓN LINEAL SIMPLE
// ----------------------------------------------------------------

** Ingreso sobre edad
regress i524a1 p208a

** Guardar resultados para comparar
eststo  modelo1


// esttab modelo1


** Ver coeficientes con intervalo de confianza
regress i524a1 p208a, level(95)

** Predicción puntual: ingreso esperado a los 40 años
display "Ingreso esperado a 40 años: " _b[_cons] + _b[p208a]*40


// ----------------------------------------------------------------
// 2. REGRESIÓN LINEAL MÚLTIPLE
// ----------------------------------------------------------------

** Agregar área de residencia (variable categórica)
regress i524a1 p208a i.area_res
eststo modelo2

** Con interacción edad x área
regress i524a1 c.p208a##i.area_res
eststo modelo3

** Comparar los 3 modelos en una sola tabla
esttab modelo1 modelo2 modelo3, ///
    b(%9.2f) se(%9.2f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0f %9.3f)) ///
    title("Comparación de Modelos de Regresión")

** Exportar tabla a Word/Excel
esttab modelo1 modelo2 modelo3 using "comparacion_modelos.html", ///
    replace b(%9.2f) se(%9.2f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0f %9.3f))


// ----------------------------------------------------------------
// 3. COEFICIENTES ESTANDARIZADOS Y VIF
// ----------------------------------------------------------------

** Coeficientes beta (estandarizados)
regress i524a1 p208a i.area_res, beta

** Factor de Inflación de Varianza
regress i524a1 p208a i.area_res
estat vif


// ----------------------------------------------------------------
// 4. DIAGNÓSTICO DE RESIDUOS
// ----------------------------------------------------------------

regress i524a1 p208a i.area_res

** Generar residuos y valores ajustados
predict residuos, resid
predict ajustados, xb

** Gráfico de residuos vs ajustados
rvfplot, yline(0) ///
    title("Residuos vs Valores Ajustados") ///
    msize(tiny) mcolor(navy%40) ///
    name(rvf, replace)

graph export "residuos_vs_ajustados.png", replace width(1200)

** Histograma de residuos con curva normal
hist residuos, normal ///
    title("Distribución de los Residuos") ///
    color(navy%60) ///
    name(hist_resid, replace)

graph export "hist_residuos.png", replace width(1200)

** Q-Q plot de residuos
qnorm residuos, ///
    title("Q-Q Plot de Residuos") ///
    mcolor(navy%50) msize(tiny) ///
    name(qq_resid, replace)

graph export "qq_residuos.png", replace width(1200)

** Test de normalidad
swilk residuos if _n <= 2000


// ----------------------------------------------------------------
// 5. HETEROCEDASTICIDAD
// ----------------------------------------------------------------

regress i524a1 p208a i.area_res

** Test de Breusch-Pagan
estat hettest

** Si hay heterocedasticidad, usar errores robustos
regress i524a1 p208a i.area_res, robust

** Comparar errores estándar: normal vs robusto
eststo normal: regress i524a1 p208a i.area_res
eststo robusto: regress i524a1 p208a i.area_res, robust
esttab normal robusto, b(%9.2f) se(%9.2f) ///
    title("Errores Estándar: Normal vs Robusto")


// ----------------------------------------------------------------
// 6. REGRESIÓN CON DISEÑO MUESTRAL (SVY)
// ----------------------------------------------------------------

** La forma CORRECTA de reportar con datos de encuesta
svy: regress i524a1 p208a i.area_res

** Comparar con regresión simple (sin diseño)
regress i524a1 p208a i.area_res


// ================================================================
// ================================================================
//     BLOQUE B: SERIES DE TIEMPO (series_peru.dta)
// ================================================================
// ================================================================

use "$data/series_peru.dta", clear

describe
list in 1/5


// ----------------------------------------------------------------
// 7. DECLARAR LA SERIE DE TIEMPO
// ----------------------------------------------------------------

** Convertir variable date (texto "2000:01") a formato trimestral
gen fecha = quarterly(date, "YQ")
format fecha %tq

** Declarar la serie
tsset fecha

** Verificar
tsset
describe


// ----------------------------------------------------------------
// 8. GRÁFICOS DE SERIES DE TIEMPO
// ----------------------------------------------------------------

** PIB en el tiempo
tsline gdp, ///
    title("PIB trimestral del Perú (2000-2020)") ///
    ytitle("PIB (millones S/)") ///
    xtitle("") ///
    lcolor(navy) lwidth(medthick) ///
    name(ts_gdp, replace)

graph export "ts_pib.png", replace width(1400)

** Recaudación tributaria
tsline taxes, ///
    title("Recaudación tributaria trimestral") ///
    ytitle("Millones S/") ///
    lcolor(navy) ///
    name(ts_taxes, replace)

graph export "ts_taxes.png", replace width(1400)

** Comercio exterior: dos series
tsline exports imports, ///
    title("Comercio Exterior del Perú") ///
    ytitle("Millones S/") ///
    legend(order(1 "Exportaciones" 2 "Importaciones")) ///
    lcolor(navy cranberry) ///
    name(ts_comercio, replace)

graph export "ts_comercio_exterior.png", replace width(1400)

** Todas las series en paneles separados
tsline gdp taxes exports imports, ///
    title("Variables Macroeconómicas del Perú") ///
    name(ts_todas, replace)

	
	
tsline gdp,     name(g1, replace) title("PIB") nodraw
tsline taxes,   name(g2, replace) title("Impuestos") nodraw
tsline exports, name(g3, replace) title("Exportaciones") nodraw
tsline imports, name(g4, replace) title("Importaciones") nodraw

graph combine g1 g2 g3 g4, ///
    title("Variables Macroeconómicas del Perú") ///
    rows(2) ///
    name(ts_todas, replace)

// ----------------------------------------------------------------
// 9. TASAS DE CRECIMIENTO
// ----------------------------------------------------------------

** Crecimiento trimestral (variación % respecto al trimestre anterior)
gen crec_gdp = (gdp - L.gdp)/L.gdp * 100
label variable crec_gdp "Crecimiento trimestral del PIB (%)"

** Crecimiento interanual (respecto al mismo trimestre año anterior)
gen crec_gdp_anual = (gdp - L4.gdp)/L4.gdp * 100
label variable crec_gdp_anual "Crecimiento interanual del PIB (%)"

tsline crec_gdp_anual, ///
    title("Crecimiento Interanual del PIB") ///
    ytitle("Variación % anual") ///
    yline(0, lcolor(red) lpattern(dash)) ///
    name(ts_crecimiento, replace)

graph export "crecimiento_pib.png", replace width(1400)


// ----------------------------------------------------------------
// 10. AUTOCORRELACIÓN (ACF Y PACF)
// ----------------------------------------------------------------

** Correlograma completo (tabla + gráfico ASCII)
corrgram gdp, lags(20)

** Gráfico de ACF
ac gdp, lags(20) ///
    title("Función de Autocorrelación (ACF) - PIB") ///
    name(acf_gdp, replace)

graph export "acf_pib.png", replace width(1200)

** Gráfico de PACF
pac gdp, lags(20) ///
    title("Función de Autocorrelación Parcial (PACF) - PIB") ///
    name(pacf_gdp, replace)

graph export "pacf_pib.png", replace width(1200)

** ACF y PACF combinados
graph combine acf_gdp pacf_gdp, ///
    title("ACF y PACF del PIB") ///
    rows(1) xsize(14) ysize(6)

graph export "acf_pacf_combinado.png", replace width(1600)


// ----------------------------------------------------------------
// 11. PRUEBA DE ESTACIONARIEDAD (DICKEY-FULLER)
// ----------------------------------------------------------------

** Test sobre la serie en niveles
dfuller gdp, lags(4)

** H0: la serie tiene raíz unitaria (NO estacionaria)
** Si p > 0.05 → No se rechaza H0 → la serie NO es estacionaria

** Diferenciar la serie
gen d_gdp = D.gdp
label variable d_gdp "PIB diferenciado (primera diferencia)"

tsline d_gdp, ///
    title("PIB Diferenciado") ///
    yline(0, lcolor(red)) ///
    name(ts_dgdp, replace)

** Repetir el test sobre la serie diferenciada
dfuller d_gdp, lags(4)

** ACF de la serie diferenciada (debería decaer más rápido)
ac d_gdp, lags(20) ///
    title("ACF del PIB Diferenciado") ///
    name(acf_dgdp, replace)


// ----------------------------------------------------------------
// 12. DESCOMPOSICIÓN: TENDENCIA Y ESTACIONALIDAD
// ----------------------------------------------------------------

** Promedio móvil para extraer tendencia
tssmooth ma gdp_tendencia = gdp, window(2 1 1)

tsline gdp gdp_tendencia, ///
    title("PIB y su Tendencia (Promedio Móvil)") ///
    legend(order(1 "PIB observado" 2 "Tendencia")) ///
    lcolor(navy%50 cranberry) ///
    lwidth(thin thick) ///
    name(ts_tendencia, replace)

graph export "pib_tendencia.png", replace width(1400)

** Componente estacional (desviación respecto a la tendencia)
gen componente_estacional = gdp - gdp_tendencia

tsline componente_estacional, ///
    title("Componente Estacional del PIB") ///
    yline(0, lcolor(red) lpattern(dash)) ///
    name(ts_estacional, replace)

graph export "pib_estacional.png", replace width(1400)


// ----------------------------------------------------------------
// 13. MODELO ARIMA
// ----------------------------------------------------------------

** Estimar ARIMA(1,1,1)
arima gdp, arima(1,1,1)

** Guardar criterios de información para comparar
estat ic

** Probar otras especificaciones
arima gdp, arima(2,1,1)
estat ic

arima gdp, arima(1,1,2)
estat ic

** Elegir el modelo con menor AIC/BIC
** Reestimar el modelo elegido (ejemplo: ARIMA(1,1,1))
arima gdp, arima(1,1,1)

** Verificar residuos del modelo ARIMA
predict resid_arima, residuals
ac resid_arima, lags(20) ///
    title("ACF de Residuos del Modelo ARIMA")


// ----------------------------------------------------------------
// 14. PRONÓSTICO
// ----------------------------------------------------------------

** Re-estimar el modelo final
quietly arima gdp, arima(1,1,1)

** Extender el período muestral 8 trimestres hacia adelante
tsappend, add(8)

** Generar el pronóstico dinámico
predict pron_gdp, y dynamic(tq(2021q1))

** Error estándar de la predicción (para IC)
predict se_pron, stdp

** Construir bandas de confianza al 95%
gen li_pron = pron_gdp - 1.96*se_pron
gen ls_pron = pron_gdp + 1.96*se_pron

** Graficar observado + pronóstico + banda de confianza
twoway ///
    (tsline gdp, lcolor(navy) lwidth(medthick)) ///
    (tsline pron_gdp if fecha >= tq(2021q1), ///
        lcolor(cranberry) lpattern(dash) lwidth(medthick)) ///
    (rarea li_pron ls_pron fecha if fecha >= tq(2021q1), ///
        color(cranberry%20)), ///
    title("PIB Observado y Pronosticado (2021-2022)") ///
    ytitle("PIB (millones S/)") xtitle("") ///
    legend(order(1 "Observado" 2 "Pronóstico" 3 "IC 95%")) ///
    name(forecast_final, replace)

graph export "pronostico_pib.png", replace width(1600)

** Ver los valores pronosticados
list fecha pron_gdp li_pron ls_pron if fecha >= tq(2021q1)


// ================================================================
//                    RESUMEN DE COMANDOS
// ================================================================
//
// === REGRESIÓN LINEAL ===
//
// regress y x                    Regresión simple
// regress y x1 i.categorica      Regresión múltiple con dummy
// c.x1##i.categorica             Interacción continua x categórica
// , beta                         Coeficientes estandarizados
// , robust                       Errores estándar robustos
// estat vif                      Multicolinealidad
// estat hettest                  Test Breusch-Pagan
// predict var, xb                Valores ajustados
// predict var, resid             Residuos
// rvfplot                        Residuos vs ajustados
// svy: regress                   Regresión con diseño muestral
// esttab                         Tabla comparativa de modelos
//
// === SERIES DE TIEMPO ===
//
// tsset variable                 Declarar serie de tiempo
// tsline variable                Graficar serie
// L.variable / L4.variable       Rezago 1 / rezago 4
// D.variable                     Primera diferencia
// corrgram variable              Correlograma (tabla)
// ac variable, lags()            Autocorrelación (ACF)
// pac variable, lags()           Autocorr. parcial (PACF)
// dfuller variable               Test de raíz unitaria
// tssmooth ma                    Promedio móvil (tendencia)
// arima y, arima(p,d,q)          Modelo ARIMA
// estat ic                       AIC/BIC del modelo
// tsappend, add(n)               Extender períodos futuros
// predict, dynamic(tq())         Pronóstico dinámico
//
// === FECHAS EN STATA ===
//
// quarterly(date,"YQ")           Convertir texto a trimestral
// format var %tq                 Formato de fecha trimestral
// tq(2021q1)                     Especificar un trimestre
// ================================================================


// ============ Sesion 4: Probabilidad e inferencia
// ======= Autor: Nick Hurtado ========================
// ====================================================




global main  "C:\Users\UsuarioNuevo\Documents\Clases\Escuela_Global\Estadistica_Aplicada\Clase 3"
global code   "$main/Code"
global data   "$main/Data"
global output "$main/Ejercicios"


cd "$output"


** Importamos los datos de Enaho - 2025

use "$data/enaho01a-2025-500.dta", clear


ci means i524a1



// Crear variables y labels:

gen area_res = .

replace area_res = 1 if inlist(estrato, 1, 2, 3, 4, 5)
replace area_res = 2 if inlist(estrato, 6, 7, 8)

label define area_lbl ///
    1 "Urbano" ///
    2 "Rural"

label values area_res area_lbl
	
label variable area_res "Área de residencia"

svyset conglome [pw=fac500a],strata(estrato)

svy:mean i524a1,over(area_res)



** Prueba t de una muestra: ¿μ = 3000?
ttest i524a1 == 3000

// MEDIDAS SOBRE PRUEBA T
* t observado (calculado por Stata)
display "t calculado = " r(t)

* Valor crítico teórico
display "t crítico = " invttail(r(df_t), 0.025)

* Comparación automática
display "¿Se rechaza H0? " (abs(r(t)) > invttail(r(df_t), 0.025))


** Prueba t con factor de expansión
svyset conglome [pw=fac500a], strata(estrato)
svy: mean i524a1
test _b[i524a1] = 3000

** Prueba t de dos muestras: Urbano vs Rural
ttest i524a1, by(area_res)

** Con factor
svy: mean i524a1, over(area_res)
test [i524a1]Urbano = [i524a1]Rural


** Prueba t de dos grupos
ttest i524a1, by(area_res)

** Prueba con factor de expansión

svy: mean i524a1, over(area_res)
test [i524a1]Urbano = [i524a1]Rural




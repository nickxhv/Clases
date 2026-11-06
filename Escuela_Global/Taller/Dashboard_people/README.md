# Taller de People Analytics — Dashboard de Rotación

![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-F2C811?style=for-the-badge)
![DAX](https://img.shields.io/badge/DAX-30%20medidas-1F4E79?style=for-the-badge)
![Power Query](https://img.shields.io/badge/Power%20Query-M-258FFA?style=for-the-badge)
![Datos](https://img.shields.io/badge/Dataset-sint%C3%A9tico-6A994E?style=for-the-badge)

Materiales del taller dictado en **Escuela Global**: dataset sintético, archivos de Power BI por etapa, tema visual y diapositivas.

El taller construye de principio a fin un tablero de rotación de personal: se parte de siete CSV sin procesar y se termina en una página que responde cuatro preguntas de negocio. Dura dos horas, es virtual y asume manejo intermedio de Excel y haber abierto Power BI alguna vez. No asume experiencia en recursos humanos ni en DAX.

El enfoque es **pregunta primero**: cada medida del tablero existe porque alguien necesita decidir algo con ella. Las métricas que no completan la fila *pregunta → métrica → decisión* no entran.

---

## Estructura del repositorio

```
Dashboard_people/
├── 01_Data/
│   └── Raw/                    Los siete CSV del caso + diccionario
├── 02_Dev/
│   └── Reports/
│       ├── People_Analytics.pbix   Tablero terminado
│       └── Steps/                  Puntos de control intermedios
│           ├── 01_Models.pbix      Modelo armado, sin medidas
│           └── 02_KPI.pbix         Medidas núcleo, sin página final
├── 03_Templates/
│   ├── Theme_AP.json           Tema visual del reporte
│   └── logo.png                Logo de Contacto Andino
├── 04_Docs/
│   └── Taller_People_Analytics.pdf   Diapositivas de la sesión
└── README.md
```

Los archivos en `Steps/` permiten entrar al taller tarde o recuperarse de un error sin rehacer todo: si algo se rompe en la práctica, se abre el `.pbix` de la etapa anterior y se sigue.

---

## El caso: Contacto Andino

**Contacto Andino S.A.C.** es un centro de contacto peruano, ficticio, que atiende clientes de telecomunicaciones y banca. Sus números se comportan como los de un call center real: gente joven, rotación alta y márgenes ajustados.

| Dimensión | Valores |
|---|---|
| Sedes | Lima, Arequipa, Trujillo, Piura, Cusco |
| Áreas | Ventas, Cobranzas, Atención al Cliente, Soporte Técnico |
| Puestos | Asesor Junior, Asesor Senior (con banda salarial) |
| Turnos | Mañana, Tarde, Noche |
| Canales de reclutamiento | Portales de empleo, Redes sociales, Referidos, Agencias temporales, Ferias y convocatorias |
| Jefaturas | 30 |
| Ventana de datos | 1-ene-2025 a 31-oct-2026 |

El encargo de la Gerencia de Operaciones llega así: *"estamos perdiendo gente y no sabemos por qué"*. El primer trabajo analítico es traducirlo a preguntas con respuesta numérica:

1. ¿Cuánta gente estamos perdiendo y cómo evoluciona en el tiempo?
2. ¿Se van por decisión propia o los estamos sacando nosotros?
3. ¿En qué sedes, áreas, turnos y jefaturas se concentra el problema?
4. ¿Hay algo en cómo contratamos que explique quién se queda y quién se va?

---

## Los datos

| Archivo | Filas | Qué representa cada fila |
|---|---:|---|
| `Empleados.csv` | 2,586 | Una persona: ingreso, cese, canal, turno, salario |
| `Areas.csv` | 8 | Un área × puesto, con su banda salarial mínima y máxima |
| `Sedes.csv` | 5 | Una sede, con su región y tipo |
| `Jefes.csv` | 30 | Una jefatura |
| `Evaluaciones.csv` | 3,727 | La nota de desempeño de una persona en un semestre |
| `Encuesta_Clima.csv` | 6,160 | La respuesta de una persona en un trimestre |
| `Calendario.csv` | 669 | Un día, del 1-ene-2025 al 31-oct-2026 |

El detalle de cada campo está en [`01_Data/Raw/Diccionario.csv`](01_Data/Raw/Diccionario.csv).

### Dos cosas que hay que saber antes de cargar

**Los datos vienen sucios a propósito.** Cerca del 2 % de `Canal_Reclutamiento` trae mayúsculas y espacios inconsistentes: el mismo canal aparece escrito de varias formas y, sin normalizar, cualquier corte por canal reparte la misma realidad en filas separadas. Se limpia en Power Query con `Text.Proper(Text.Trim(Text.Lower(_)))`.

**`Tipo_Cese` no existe en la data.** Solo viene `Motivo_Cese`, con diez valores de texto libre. La separación entre voluntario e involuntario se construye:

```m
if [Motivo_Cese] = null then null
else if List.Contains(
    {"Fin de contrato", "Bajo desempeño", "Falta disciplinaria"}, [Motivo_Cese])
  then "Involuntario"
  else "Voluntario"
```

*Abandono de puesto* se clasifica como **voluntario**: la persona decidió irse, aunque no lo haya avisado. Es un criterio discutible y vale la pena hacerlo explícito — si se mueve a involuntario, el porcentaje de ceses voluntarios cae de 75.4 % a 62.0 % sin que cambie un solo dato.

---

## El modelo

Esquema estrella con `Empleados` al centro:

```
        Areas ─┐                  ┌─ Evaluaciones ─┐
        Sedes ─┼─► Empleados ◄────┤                ├─◄ Calendario
        Jefes ─┘                  └─ Encuesta_Clima┘
```

**El calendario no se relaciona con `Empleados`.** Es la decisión de diseño que sostiene todo el resto: una persona no tiene una fecha, tiene dos — ingreso y cese — y unir por una de ellas dejaría la otra fuera del contexto de filtro, lo que rompe el cálculo de headcount. Las medidas de dotación leen el rango del calendario con `MIN` y `MAX` y filtran `Empleados` por su cuenta.

El calendario sí se relaciona con `Evaluaciones[Fecha_Evaluacion]` y `Encuesta_Clima[Fecha_Encuesta]`, y debe marcarse como **tabla de fechas** para que funcione la inteligencia de tiempo (`DATEADD`, `TOTALYTD`).

Power BI no detecta todas las relaciones solo. Conviene revisarlas una por una antes de escribir la primera medida.

---

## Valores de control

Al 31 de octubre de 2026. Si alguno no coincide, hay un error aguas arriba y no tiene sentido seguir construyendo sobre él.

| Indicador | Valor |
|---|---:|
| Empleados en el archivo | 2,586 |
| Activos al cierre | 1,480 |
| Ceses últimos 12 meses | 581 |
| — voluntarios | 438 (75.4 %) |
| — involuntarios | 143 (24.6 %) |
| Rotación 12 meses | 40.6 % |
| Ceses antes de 90 días | 154 (26.5 %) |
| Antigüedad promedio de activos | 22.5 meses |
| Costo estimado de reemplazo, 12 meses | S/ 1,265,535 |
| Headcount inicio de octubre | 1,472 |
| Ingresos de octubre | 60 |
| Ceses de octubre | 52 |
| Rotación mensual de octubre | 3.52 % |

**La verificación que nunca falla:** headcount de inicio **+** ingresos **−** ceses **=** headcount de cierre. Para octubre, 1,472 + 60 − 52 = 1,480. Si esa identidad no se cumple, las medidas están mal y el resto del tablero hereda el error.

---

## Cómo usar este material

1. Clonar o descargar la carpeta completa, conservando la estructura.
2. Abrir Power BI Desktop → **Obtener datos → Texto/CSV** y cargar los siete archivos de `01_Data/Raw/` (el diccionario no se carga, es referencia).
3. En Power Query: normalizar `Canal_Reclutamiento`, crear `Tipo_Cese` y la columna de días hasta el cese.
4. Revisar las relaciones del modelo y marcar `Calendario` como tabla de fechas.
5. Escribir las medidas, empezando por `Headcount`, `Ingresos`, `Ceses` y `Rotación %`.
6. Armar la página y contrastar contra los valores de control de arriba.

Para aplicar el tema: **Vista → Temas → Buscar temas** y seleccionar `03_Templates/Theme_AP.json`. Es un tema de reporte, no toca el modelo, así que puede aplicarse en cualquier momento.

El logo va en **Insertar → Imagen**, anclado arriba a la izquierda y a la misma altura en todas las páginas para que no salte al navegar.

---

## Hallazgos del caso

El dataset tiene cuatro patrones plantados. La gracia del taller es que el tablero los encuentre solo, así que conviene no leer esta sección antes de la sesión.

<details>
<summary>Ver los hallazgos (spoiler)</summary>

**1. El canal de reclutamiento predice la permanencia.** Es el hallazgo más fuerte y sobrevive al control por turno y por sede.

| Canal | Contrataciones 12M | Rotación 12M | Retención 180 d |
|---|---:|---:|---:|
| Portales de empleo | 259 (38.1 %) | 49.1 % | 63.2 % |
| Redes sociales | 160 (23.6 %) | 43.2 % | 64.4 % |
| Agencias temporales | 111 (16.3 %) | 43.9 % | 65.5 % |
| Referidos | 89 (13.1 %) | **22.2 %** | **78.3 %** |
| Ferias y convocatorias | 60 (8.8 %) | 33.6 % | 71.8 % |

El canal del que más se contrata es el peor, y el mejor es apenas el 13 % de los ingresos. A 30 días las curvas de retención son indistinguibles (92–98 %); la separación ocurre entre el día 30 y el 90, lo que mueve el problema de *retención* a *selección e inducción*.

**2. El turno noche castiga.** 53.9 % de rotación contra 34.6 % del turno mañana, dentro de las mismas áreas y con los mismos salarios base. Al cruzarlo con el canal aparece algo que ninguno de los dos cortes muestra por separado: el castigo del turno noche cae casi entero sobre los canales que traen desconocidos — los portales pasan de 38.2 % a 66.2 % al cambiar de turno, los referidos apenas de 19.7 % a 24.0 %.

**3. Una sede y una jefatura concentran lo peor.** Trujillo rota 58.6 % con 35.6 % de ceses tempranos y el eNPS más bajo de las cinco sedes. Dentro de ella, una jefatura renovó su equipo completo en doce meses.

**4. Se está yendo el talento, no el bajo desempeño.** 32.5 % de quienes renuncian tenían nota de 4.0 o más, frente a 23.2 % entre los activos. Y 20.1 % estaba por debajo de su banda salarial, contra 13.6 % de los que se quedan.

</details>

---

## Requisitos

| Herramienta | Versión | Uso |
|---|---|---|
| **Power BI Desktop** | 2024 o posterior | Todo el taller |
| **Excel** | Opcional | Inspeccionar los CSV antes de cargarlos |

Los CSV están en UTF-8 y usan coma como separador. Si Excel los abre con los acentos rotos, importarlos con **Datos → Desde texto/CSV** y elegir codificación UTF-8 en vez de abrirlos con doble clic.

---

## Notas

- **Contacto Andino es una empresa ficticia y todos sus datos son simulados.** Fueron generados con un modelo de riesgo que incorpora los patrones de arriba, de modo que el análisis llega a conclusiones reales sobre datos inventados.
- Los problemas de calidad del dataset son deliberados. No es data limpia de juguete.
- Las tres formas más comunes de medir mal la rotación aparecen en el caso y se corrigen en el modelo: denominador de cierre en vez de promedio, anualizar multiplicando por doce, y mezclar ceses voluntarios con involuntarios.
- Los datos de personas son sensibles. En el Perú su tratamiento está regulado por la **Ley 29733**; la regla práctica del taller es no mostrar cortes con menos de cinco personas.

---

## Autor

**Nick Hurtado**

---

## Licencia

Material educativo de uso libre con atribución.

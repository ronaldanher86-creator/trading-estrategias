# Trading de pares (pairs trading, dólar-neutral)

## Fuente
"151 Estrategias de Trading" (Kakushadze & Serur, 2019, arXiv:1912.04492), **Sección 3.8 "Trading de pares"**, capítulo de Acciones, p. 47-48. Ecuaciones (283)-(291).

## Hipótesis
Dos acciones históricamente correlacionadas (misma industria, mismo factor de riesgo, etc.) rara vez se desvían de su relación de precios relativa por mucho tiempo sin motivo fundamental — cuando una se aprecia o deprecia más que la otra sin razón aparente, esa divergencia tiende a revertir. Se vende la que está "cara" (retorno relativo positivo) y se compra la que está "barata" (retorno relativo negativo), dólar-neutral, apostando a la convergencia, no a la dirección del mercado.

## Por qué es una candidata fuerte (a diferencia del J-Hook)
El propio paper, en su sección de comentarios (3.21), hace una distinción explícita que vale la pena citar: las estrategias de análisis técnico de una sola acción (medias móviles, soporte/resistencia, patrones tipo J-Hook) son consideradas "no científicas" por buena parte de la literatura académica, porque no hay razón fundamental por la que, por ejemplo, un patrón geométrico deba tener poder predictivo. El trading de pares, en cambio, se apoya en lógica de **arbitraje estadístico con base fundamental**: la correlación esperada entre acciones de la misma industria, derivada de exposición a los mismos factores de riesgo — es una categoría de estrategia distinta, con más de dos décadas de literatura académica revisada por pares.

## Universo e instrumentos
Dos acciones con alta correlación histórica (misma industria/sector, o relación económica clara — ej. dos competidores directos, una acción y su ETF sectorial, etc.). Precios ajustados por splits y dividendos (el paper lo exige explícitamente).

## Timeframe
No especificado de forma rígida por el paper — es una estrategia de reversión a la media de mediano plazo (t1 a t2), no intradía. El periodo de estimación de la correlación histórica y el periodo de "vuelta a la media" esperado deben fijarse explícitamente en el paso 03.

## Regla de entrada (formalización del paper)
1. Calcular los retornos logarítmicos de cada acción entre t1 y t2: `Rᴬ = ln(Pᴬ(t2)/Pᴬ(t1))`, `Rᴮ = ln(Pᴮ(t2)/Pᴮ(t1))`.
2. Retorno medio: `R̄ = ½(Rᴬ + Rᴮ)`.
3. Retornos netos de la media: `R̃ᴬ = Rᴬ − R̄`, `R̃ᴮ = Rᴮ − R̄`.
4. Una acción está **"cara"** si su retorno neto de la media es positivo, **"barata"** si es negativo.
5. Entrada: **vender la acción "cara", comprar la acción "barata"**, en cantidades `Qᴬ, Qᴮ` tales que la posición sea dólar-neutral: `Pᴬ·Qᴬ + Pᴮ·Qᴮ = 0`, con la inversión total en dólares `I` fijada por `Pᴬ|Qᴬ| + Pᴮ|Qᴮ| = I`.

El paper no fija explícitamente el umbral de desviación que dispara la entrada (¿qué tan "cara/barata" debe estar para entrar?) — eso, junto con la ventana t1→t2 exacta, es una decisión que falta fijar en el paso 03 (ej. usar un z-score del spread histórico con un umbral de entrada de ±2 desviaciones estándar es el enfoque más común en la literatura citada, aunque el paper no lo prescribe literalmente aquí).

## Regla de salida
No explícita en esta sección — el criterio natural (y el más usado en la literatura de pairs trading) es cerrar cuando el spread revierte a su media histórica (o cruza un umbral cercano a cero), con un stop-loss si la divergencia se sigue ampliando más allá de lo históricamente observado (riesgo de ruptura estructural de la correlación, ver riesgos abajo).

## Régimen donde debería funcionar
Mercados donde la relación fundamental/estadística entre el par se mantiene estable (misma industria, sin eventos idiosincráticos que rompan la correlación) y hay suficiente liquidez para operar ambas piernas sin fricción significativa.

## Régimen donde debería fallar
Cuando la correlación histórica se rompe estructuralmente (ej. una de las dos empresas sufre un evento idiosincrático: M&A, escándalo, cambio de modelo de negocio, quiebra) — en ese caso el spread no "revierte", diverge permanentemente, y la estrategia pierde justo cuando más grande se ve la señal de entrada.

## Evidencia disponible
- **Referencia seminal citada por el paper**: Gatev, Goetzmann & Rouwenhorst (2006), "Pairs Trading: Performance of a Relative-Value Arbitrage Rule" — de los estudios más citados en la literatura de arbitraje estadístico, con evidencia empírica de rendimientos ajustados por riesgo positivos en mercado de acciones de EE.UU. durante décadas (con matices sobre la caída del edge en periodos más recientes, algo que también advierte la literatura de seguimiento).
- El paper cita además Engle & Granger (1987) (base teórica de cointegración que sustenta por qué el spread debería revertir), Vidyamurthy (2004), y una lista extensa de estudios adicionales (Do & Faff 2010/2012, Krauss 2017, Krauss & Stübinger 2017, entre ~25 referencias en la nota 51 del paper).
- **Grado de evidencia: alto en literatura académica de terceros, con matiz temporal importante**: varios de los estudios citados (Krauss 2017 en particular) documentan que el edge de pairs trading clásico se ha reducido con el tiempo a medida que más capital institucional lo explota — hay que verificar esto con datos recientes en el paso 02 (AED), no asumir que el edge de 2006 sigue igual de vigente hoy.

## Riesgos conocidos
- **Riesgo de ruptura de correlación** (structural break): el riesgo dominante de esta estrategia — un evento idiosincrático en una de las dos acciones invalida la premisa completa.
- **Costo de financiamiento del corto**: vender en corto una acción tiene costos (interés del préstamo de acciones) que el paper no incorpora en la formulación básica — hay que sumarlos en el paso 04 (Backtest) para que los costos sean realistas.
- **Capacidad/liquidez**: si el par elegido tiene poco volumen, el slippage en ambas piernas puede erosionar el edge; y dado que la estrategia depende de vender en corto, verificar que el bróker/plataforma del usuario permita cortos en las acciones elegidas.
- **Edge decreciente documentado en la propia literatura citada** — no asumir que el resultado de un estudio de hace años se sostiene igual hoy.

## AED (paso 02) — 2026-09-16

**Par elegido:** XOM (ExxonMobil) vs. CVX (Chevron) — las dos mayores petroleras integradas de EE.UU., mismo sector, expuestas a los mismos factores (precio del crudo, refino, regulación energética). Datos diarios reales de TradingView, **2025-07-09 a 2026-09-16 (300 barras, ~14 meses)**.

### Paso 1 — ¿es un par legítimo?
Correlación de retornos diarios XOM-CVX: **0.824**. Alta, como se espera de dos comparables directos del mismo sector — confirma que tiene sentido tratarlas como un par antes de testear la reversión del spread.

### Paso 2 — ¿revierte el spread?
Se construyó el spread como retorno acumulado relativo (ln(XOM/XOM₀) − ln(CVX/CVX₀)), con z-score sobre ventana rodante de 20 días, y se midió el cambio del spread 10 días después de cada evento con |z| ≥ 1.5.

**Primer resultado (ingenuo, ventanas solapadas):**
- 89 eventos de señal sobre 270 observaciones.
- Tasa de reversión: 60.7%. Correlación z(t) vs. cambio futuro: **−0.27** (el signo negativo esperado).
- Test de permutación (20.000 reordenamientos): **p = 0.0000**.

A primera vista esto se ve espectacular. **No lo tomamos así**, por la razón exacta que señala `docs/validacion_estrategias.md` sobre autocorrelación: la ventana rodante de 20 días y el horizonte de 10 días hacen que eventos consecutivos compartan casi todos sus datos — no son 89 observaciones independientes, son ~89 vistazos muy correlacionados a un puñado real de episodios de divergencia del spread. Un p-valor de 0.0000 calculado sobre datos así de autocorrelacionados no significa lo que parece significar.

**Corrección (eventos no solapados, la cifra real):**
- Al exigir que cada evento nuevo empiece después de que termine la ventana del anterior, quedan **18 eventos independientes** (no 89).
- Tasa de reversión: 55.6% (10/18). Correlación z vs. cambio futuro: **−0.41** (dirección correcta, y de mayor magnitud).
- Test de permutación sobre estos 18: **p = 0.097** — ya no es significativo al umbral convencional de 0.05, aunque está cerca y la dirección es consistente.

### Lectura honesta
- La dirección del efecto es la que predice la hipótesis (reversión), en ambas versiones del test — eso es alentador.
- Pero el tamaño de muestra real (18 eventos independientes) está **por debajo del mínimo de ~30** que fija `docs/validacion_estrategias.md` para una conclusión fuerte. El resultado "espectacular" inicial (p=0.0000) era en buena parte un artefacto de tratar observaciones solapadas como si fueran independientes — exactamente el tipo de error que hay que evitar.
- Periodo corto: 14 meses es una sola ventana de mercado (incluye al menos un salto conjunto grande de ambas acciones a fines de enero, probablemente una noticia sectorial — consistente con que XOM/CVX se mueven juntas por factores comunes, que es la premisa del par, pero también significa que gran parte del "aprendizaje" viene de pocos episodios, no de un régimen largo).
- El P&L simulado (retorno medio +0.69% por evento no solapado, sin costos de transacción ni de préstamo del corto) es ilustrativo, no una validación — eso corresponde al paso 04 (Backtest) con reglas ya codificadas.

### Sesgos y limitaciones
- Un solo par, un solo periodo de 14 meses — no se probó en otros pares del sector ni en otros periodos.
- Sin costos: comisión, spread, y especialmente el costo de pedir prestada la acción para la pata corta, no están incluidos.
- La ventana (20d) y el horizonte (10d) y el umbral (|z|≥1.5) fueron elegidos por convención razonable, no optimizados — lo cual es correcto para un AED (evita curve-fitting prematuro), pero significa que no se ha explorado si otra combinación da una lectura distinta.

### Recomendación
**Evidencia preliminar, direccionalmente favorable, pero no concluyente.** A diferencia del momentum (idea 002, resultado nulo claro), aquí hay una señal real que vale la pena perseguir, pero no alcanza el umbral para pasar directo al paso 03. Antes de codificar reglas:
1. Repetir el mismo test en 2-3 pares adicionales del mismo sector (ej. otras petroleras integradas) para ver si el patrón se repite — eso aumentaría el n efectivo de forma legítima (distinto de solo extender la ventana del mismo par).
2. Si hay presupuesto de tiempo, conseguir más historia de XOM/CVX (más allá de los ~14 meses disponibles vía la API en este entorno) para tener más episodios independientes del mismo par.

## Ampliación de la muestra — 2026-09-16

Se repitió exactamente el mismo test (z-score rodante 20d, horizonte 10d, umbral |z|≥1.5, solo eventos no solapados) en 3 pares adicionales del sector petrolero, datos diarios reales de TradingView, mismo periodo (2025-07 a 2026-09):

| Par | Correlación de retornos | Eventos independientes | Tasa de reversión | Correlación z vs. cambio futuro |
|---|---|---|---|---|
| XOM-CVX (original) | 0.824 | 18 | 55.6% | **−0.406** (dirección correcta) |
| COP-XOM (nuevo) | 0.797 | 19 | 47.4% | **+0.081** (dirección INCORRECTA) |
| COP-CVX (nuevo) | 0.811 | 19 | 57.9% | **+0.164** (dirección INCORRECTA) |
| SHEL-BP (nuevo, majors europeas) | 0.786 | 17 | 47.1% | −0.216 (dirección correcta, débil) |
| **Pool combinado (4 pares)** | — | **73** | **52.1%** | **−0.069** |

**Test de permutación sobre el pool combinado (73 eventos, 20.000 reordenamientos): p = 0.563.**

### Lectura honesta — esto cambia el veredicto

El resultado favorable de XOM-CVX **no se replicó** en ninguno de los otros tres pares. Dos de los cuatro (COP-XOM, COP-CVX) mostraron el signo *contrario* al que predice la hipótesis de reversión a la media. Con la muestra ampliada a 73 eventos independientes — ahora sí por encima del mínimo de ~30 — el resultado combinado es indistinguible del azar (p=0.56, correlación prácticamente cero).

Esto es exactamente el patrón de un **falso positivo por comparaciones múltiples**: al probar 4 pares, es estadísticamente esperable que al menos uno muestre una correlación fuerte por puro azar, y XOM-CVX fue ese caso. El AED inicial (con n=18, un solo par) no tenía forma de distinguir esto de una señal real — por eso el proceso de validación exige ampliar la muestra antes de sacar conclusiones, y aquí se ve por qué: la conclusión cambió por completo al hacerlo.

### Veredicto actualizado
**RECHAZAR** esta especificación de la estrategia (z-score de 20 días, horizonte de 10 días, umbral 1.5, en este universo de petroleras integradas). No hay edge estadísticamente distinguible del azar una vez corregido por el sesgo de selección de un solo par favorable. Esto no descarta el trading de pares como categoría — otros sectores, otras ventanas de tiempo, u otra formalización (ej. cointegración formal en vez de z-score simple) podrían comportarse distinto — pero sí descarta específicamente lo que se probó aquí.

## Siguiente paso sugerido
No pasar al paso 03 con esta especificación — está rechazada tras la ampliación de muestra. Si se quiere seguir con trading de pares, la vía honesta es empezar de nuevo con una formalización distinta (cointegración de Engle-Granger, u otro sector/universo) y volver a correr el AED completo, no reutilizar estos parámetros.

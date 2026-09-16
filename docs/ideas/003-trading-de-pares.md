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

## Siguiente paso sugerido
Pasar a `trading-data-analyst` (paso 02, AED) sobre 2-3 pares candidatos con alta correlación histórica conocida (ej. dentro del mismo sector que ya sigue el usuario), para confirmar que la relación de cointegración/correlación sigue vigente en datos recientes antes de fijar el umbral de entrada exacto en el paso 03.

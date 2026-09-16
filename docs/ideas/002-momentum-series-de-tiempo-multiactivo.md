# Momentum de series de tiempo (multi-activo, estilo "managed futures")

## Fuente
"151 Estrategias de Trading" (Kakushadze & Serur, 2019, arXiv:1912.04492), **Sección 10.4 "Seguimiento de la tendencia (momentum)"**, capítulo de Futuros, p. 108-109. Ecuaciones (474)-(480).

## Hipótesis
Un activo que ha subido (bajado) de forma sostenida durante un periodo pasado tiende a seguir subiendo (bajando) en el periodo siguiente, porque la información se incorpora al precio de forma gradual (subreacción inicial, reacción en cadena de distintos tipos de participantes con horizontes distintos) y no instantánea. A diferencia del J-Hook, esto **no es folklore técnico**: es uno de los efectos más replicados en finanzas empíricas.

## Universo e instrumentos
El paper lo plantea sobre una canasta de futuros (N instrumentos). Para una cuenta retail en MetaTrader 5, la versión práctica es aplicar la regla **por instrumento, de forma independiente** (versión "time-series momentum" pura, no la versión cruzada dólar-neutral con N activos simultáneos que requiere gestionar un portafolio completo — ver sección de implementación abajo). Instrumentos candidatos accesibles vía CFDs/futuros en MT5: índices, materias primas, pares de forex mayores, alguna acción individual líquida.

## Timeframe
El paper deja el periodo de lookback T abierto ("días, semanas o meses"). La literatura citada (Moskowitz, Ooi & Pedersen 2012, "Time Series Momentum") usa típicamente lookback de 1-12 meses con rebalanceo mensual — es una estrategia de swing/posición, no intradía. No mezclar con el estilo intradía que ya tienen (`ELON_SpaceX_v1.mq5`).

## Regla de entrada (formalización del paper)
Para cada instrumento i, con retorno pasado Rᵢ sobre el periodo T:
- Señal: **εᵢ = signo(Rᵢ)** → largo si el retorno pasado fue positivo, corto si fue negativo.
- Peso/tamaño sugerido por el paper: **wᵢ ∝ εᵢ / σᵢ**, donde σᵢ es la volatilidad histórica del instrumento (normaliza el riesgo entre instrumentos de distinta volatilidad) — esto es, en esencia, lo mismo que hará `trading-risk-manager` en el paso 07, así que en la práctica de EA individual la señal de entrada es simplemente el signo del retorno acumulado del lookback, y el sizing por volatilidad se delega al paso 07 en vez de codificarlo dos veces.
- El paper advierte explícitamente un problema práctico: con |Rᵢ| pequeño, el signo εᵢ puede "voltearse" fácilmente por ruido aunque el cambio real sea mínimo, generando inestabilidad (entradas/salidas espurias). Su mitigación sugerida: suavizar con **εᵢ = tanh(Rᵢ/κ)**, con κ como la desviación estándar de corte transversal de Rᵢ, en vez de un signo binario duro. Esto es una de las decisiones de diseño a fijar en el paso 03 (Reglas) — no dejarla ambigua.

## Regla de salida
No especificada explícitamente en esta sección del paper (es un modelo de pesos de portafolio, no de entrada/salida discreta). Para implementarlo como EA se necesita definir, en el paso 03: frecuencia de rebalanceo (ej. mensual, como en la literatura citada), y si se usa stop-loss/take-profit por posición o solo el rebalanceo periódico de la señal como mecanismo de salida.

## Régimen donde debería funcionar
Mercados con tendencias persistentes de mediano plazo (meses) y ausencia de reversiones bruscas frecuentes — funciona mejor en periodos de tendencia direccional clara en múltiples activos (ej. expansión o contracción macro sostenida).

## Régimen donde debería fallar
Mercados en rango/choppy, y específicamente en **reversiones bruscas de tendencia** (el momentum sufre sus peores drawdowns justo cuando la tendencia se revierte después de haber sido fuerte — el "momentum crash" documentado en la literatura, ej. reversión post-2009). También sufre con el "whipsaw" del suavizado tanh si κ está mal calibrado.

## Evidencia disponible
- **Fuente primaria citada por el paper**: Moskowitz, Ooi & Pedersen (2012) "Time Series Momentum" — uno de los papers más replicados en finanzas cuantitativas, con evidencia de time-series momentum robusta across 58 instrumentos líquidos (commodities, FX, índices, bonos) durante más de 25 años de datos, con Sharpe ratios reportados en la literatura original en el rango de ~1.0 antes de costos (cifra de la literatura académica, no verificada aquí con datos propios — hay que replicarla, no darla por hecho).
- También citado: Balta & Kosowski (2013), y una lista extensa de referencias adicionales sobre momentum en futuros (ver nota 169 del paper: Ahn et al 2002, Bianchi/Drew/Fan 2015, Dusak 1973, Fuertes/Miffre/Fernandez-Perez 2015, Miffre & Rallis 2007, Pirrong 2005, entre otros).
- **Grado de evidencia: alto en literatura académica de terceros** (el efecto momentum de series de tiempo es de los más robustos y replicados fuera de muestra en múltiples clases de activos y décadas) — pero eso NO exime de correr el proceso completo de validación (pasos 02-06) sobre los instrumentos y el broker/costos específicos del usuario, porque el edge académico está medido con datos institucionales y costos distintos a una cuenta MT5 retail.

## Riesgos conocidos
- **Momentum crashes**: pérdidas grandes y concentradas en reversiones bruscas tras tendencias fuertes — el circuit breaker de `Include/RiskManager.mqh` es especialmente relevante aquí.
- **Costos de rebalanceo**: si se implementa con rebalanceo frecuente sobre múltiples instrumentos, el costo de transacción retail (spread, comisión) puede erosionar buena parte del edge académico (medido usualmente con costos institucionales menores).
- **Simplificación de N-activos a 1 instrumento**: la versión que se sugiere implementar primero (por instrumento, independiente) pierde el beneficio de diversificación de la versión de portafolio completo del paper — es un punto de partida más simple, no la estrategia completa tal como está descrita.

## AED (paso 02) — 2026-09-16

**Parámetros fijados para esta primera pasada** (no confirmados con el usuario previamente, elegidos como default razonable y documentados aquí para que se puedan ajustar): lookback T = 12 meses (el más citado en la literatura de referencia, Moskowitz-Ooi-Pedersen), horizonte de evaluación = retorno del mes siguiente, señal = signo binario simple del retorno acumulado de 12 meses (sin suavizado tanh, para medir el edge crudo antes de añadir ese refinamiento).

**Nota metodológica importante**: lo que se testeó aquí es la versión **más simple posible** de la idea — momentum de un solo instrumento, sin ponderar por volatilidad ni construir el portafolio cross-sectional dólar-neutral que describe el paper (Ecuación 474-480) y que usa la literatura académica citada. Es una prueba deliberadamente débil/conservadora de la hipótesis, no una réplica fiel del estudio original.

### Fuente de datos
TradingView Desktop no pudo conectarse vía CDP en este entorno (la app instalada vía Microsoft Store no expone el puerto de depuración pese a estar corriendo — limitación de sandboxing, no de los datos). Se usó como alternativa la API pública de Yahoo Finance (`query1.finance.yahoo.com/v8/finance/chart/`), datos mensuales:

| Instrumento | Símbolo | Periodo | Barras mensuales |
|---|---|---|---|
| Oro (futuro continuo) | `GC=F` | 2011-10 a 2026-09 | 154 |
| S&P 500 (índice) | `^GSPC` | 2011-10 a 2026-09 | 181 |
| EUR/USD (spot) | `EURUSD=X` | 2011-09 a 2026-09 | 181 |

### Resultados (signo del retorno 12m vs. retorno del mes siguiente)

| Instrumento | n útil | Retorno medio \| señal + | Retorno medio \| señal − | Diferencia | p-valor (permutación, 20.000 reordenamientos) |
|---|---|---|---|---|---|
| Oro | 141 (88+/53−) | +0.891% | +0.307% | +0.584% | **0.463** |
| S&P 500 | 168 (144+/24−) | +0.913% | +1.488% | **−0.575%** (signo invertido) | **0.522** |
| EUR/USD | 168 (76+/92−) | −0.043% | −0.098% | +0.055% | **0.862** |

El test de permutación baraja aleatoriamente qué meses se etiquetan "señal positiva" vs. "negativa" (preservando el tamaño de cada grupo) 20.000 veces, y mide qué fracción de esos reordenamientos al azar produce una diferencia de medias tan grande o mayor que la observada. Un p-valor bajo (convencionalmente <0.05) indicaría que la diferencia real difícilmente se explica por azar. Aquí **ningún instrumento se acerca a ese umbral** — los tres resultados son estadísticamente indistinguibles de barajar los datos al azar.

### Lectura honesta
- **No se encontró edge estructural con esta especificación simple, en esta muestra (2011-2026), en ninguno de los 3 instrumentos.** El Oro y EUR/USD muestran una diferencia con el signo "correcto" (momentum positivo antecede retornos algo mayores) pero pequeña y no significativa. El **S&P 500 muestra el signo invertido**: los meses que siguieron a una señal negativa tuvieron en promedio mejor retorno que los que siguieron a señal positiva — consistente con que 2011-2026 fue, en el índice, un mercado alcista secular con caídas que se recuperaron rápido (rebote en V), un régimen donde el momentum de 12 meses no es la lectura correcta.
- Esto **no refuta** la literatura académica citada (que usa décadas más de historia, decenas de instrumentos simultáneos, y ponderación por volatilidad) — refuta específicamente que **esta versión simplificada, en este periodo, en estos 3 instrumentos** tenga un edge detectable. Son cosas distintas y hay que ser precisos sobre cuál se está afirmando.
- Tamaño de muestra: 141-168 observaciones mensuales por instrumento es modesto pero por encima del mínimo de ~30 — no es un problema de tamaño de muestra, es que la diferencia observada es simplemente pequeña frente al ruido mes a mes (desviación estándar mensual de 2-4.6% vs. diferencias de señal de 0.05-0.58%).

### Sesgos de datos detectados
- `GC=F` es un futuro continuo (front-month) de Yahoo Finance — puede tener pequeños saltos en los rollos de contrato que no siempre están perfectamente ajustados; no se verificó la metodología de ajuste de Yahoo en detalle.
- `^GSPC` es el índice de precio, sin dividendos reinvertidos — correcto para momentum de precio puro, pero no comparable directamente a un retorno total.
- No hay sesgo de supervivencia relevante (son un índice, un futuro de materia prima y un par de FX, no una canasta de acciones individuales que puedan salir de listado).
- No se probó una fuente de datos alternativa para contrastar — los números de Yahoo Finance no fueron cruzados contra una segunda fuente.

### Calificación de confianza
**Preliminar, con resultado nulo.** No es evidencia de que el momentum "no exista" en general (la literatura de terceros sigue siendo la citada en el documento de hipótesis), pero sí es evidencia de que **esta implementación mínima no muestra señal explotable** en los instrumentos y periodo probados.

### Recomendación
No pasar directamente al paso 03 (Reglas) con la especificación actual (single-instrument, sin ponderación por volatilidad). Dos caminos razonables antes de descartar la idea:
1. **Probar la versión más fiel al paper**: cross-sectional, con una canasta más amplia de instrumentos (no solo 3) y ponderación por volatilidad (Ecuación 474-480), que es lo que realmente respalda la literatura citada — la versión testeada aquí era deliberadamente la más débil posible.
2. **Repriorizar**: dado que esta primera pasada no encontró señal y las ideas 003 (trading de pares) y 004 (carry trade) todavía no se han sometido a AED, podría ser más productivo testear esas antes de invertir más tiempo en una segunda pasada de momentum.

La decisión de cuál camino tomar es del usuario — ambos son válidos.

### Confirmación independiente con datos de TradingView — 2026-09-16 (mismo día, actualización)

Tras resolver la conexión CDP con TradingView Desktop (ver notas de la sesión), se repitió exactamente el mismo test con la fuente de datos real de la plataforma, con una muestra bastante más larga:

| Instrumento | Fuente | Periodo | n | Diferencia (+ vs −) | p-valor |
|---|---|---|---|---|---|
| Oro | `TVC:GOLD` | 2001-09 a 2026-08 (300 barras) | 287 | +0.631% | 0.351 |
| S&P 500 | `TVC:SPX` | 2001-10 a 2026-09 (300 barras) | 287 | **+0.128%** (antes era −0.575% con Yahoo) | 0.839 |
| EUR/USD | `OANDA:EURUSD` | 2002-04 a 2026-08 (293 barras) | 280 | **−0.264%** (antes era +0.055% con Yahoo) | 0.395 |

**El resultado nulo se confirma y se refuerza.** Con casi el doble de historia (24-25 años vs. 14-15 con Yahoo Finance), ningún instrumento se acerca a significancia estadística. Un dato adicional relevante: el **signo de la diferencia se invirtió** en S&P 500 y en EUR/USD entre el pase con Yahoo Finance y este pase con TradingView (periodos distintos, aunque solapados). Que el signo del efecto cambie según qué años exactos se incluyan es, en sí mismo, evidencia de que lo que se está midiendo es ruido alrededor de cero, no una señal estable — un edge real no debería voltear de signo simplemente por extender la muestra hacia atrás en el tiempo.

Esto no cambia la recomendación anterior: no se avanza al paso 03 con la especificación simple actual. Si se retoma esta idea, debe ser con la versión cross-sectional ponderada por volatilidad del paper (Ecuación 474-480), no con más repeticiones de la versión single-instrument, que ya fue puesta a prueba dos veces con fuentes y periodos distintos y en ambas fue indistinguible del azar.

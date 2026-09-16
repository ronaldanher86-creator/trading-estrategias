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

## Siguiente paso sugerido
Antes del paso 02 (AED), decidir junto con el usuario: (a) qué instrumento(s) usar como primer caso de prueba, (b) el lookback T exacto, y (c) si se usa el signo binario simple o el suavizado tanh — son las mismas ambigüedades que el paper deja abiertas a propósito ("no hay un método fundamental para fijar los parámetros"), así que hay que fijarlas aquí, no durante el backtest.

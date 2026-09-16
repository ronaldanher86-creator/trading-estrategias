# Carry trade de divisas (FX)

## Fuente
"151 Estrategias de Trading" (Kakushadze & Serur, 2019, arXiv:1912.04492), **Sección 8.2 "Carry trade"** y **8.2.1 "Carry alto-menos-bajo"**, capítulo de Divisas (FX), p. 96-98. Ecuaciones (440)-(444).

## Hipótesis
Según la Paridad de Tasas de Interés No Cubierta (UIRP), una moneda con tasa de interés más alta debería depreciarse lo suficiente para compensar exactamente esa ventaja de tasa. **Empíricamente, en promedio ocurre lo contrario**: las monedas de alta tasa tienden a apreciarse (o al menos no depreciarse lo suficiente para anular el diferencial), lo que deja una prima de retorno explotable al pedir prestado en la moneda de baja tasa e invertir en la de alta tasa — esto se conoce en la literatura como el "enigma de Fama" o "forward premium puzzle", y el propio paper lo nombra así explícitamente.

## Universo e instrumentos
Pares de divisas con diferencial de tasas de interés significativo entre las dos economías. En MT5, la aproximación retail no es el mercado de forwards que describe el paper, sino mantener una posición spot y cobrar/pagar el **swap/rollover diario** que ofrece el bróker — esto es economicamente similar pero **no idéntico** a la Paridad de Tasas de Interés Cubierta (CIRP) del paper: el swap del bróker puede incluir un margen/markup sobre la tasa "pura" de mercado. Esta diferencia debe verificarse con el bróker específico del usuario antes de asumir que el carry teórico del paper se traduce 1:1 en el carry realmente cobrado/pagado.

## Timeframe
Estrategia de mediano/largo plazo — se cobra el carry por mantener la posición abierta (idealmente varias semanas/meses), no es una estrategia intradía. El paper menciona forwards con vida de un mes como referencia típica para la versión cross-sectional (8.2.1).

## Regla de entrada (formalización del paper)

### Versión básica (8.2), un solo par
- Descuento/premio a plazo: `D(t,T) = s(t) − f(t,T)`, donde `s(t) = ln(S(t))` es el tipo de cambio spot logarítmico y `f(t,T) = ln(F(t,T))` el tipo de cambio forward logarítmico.
- Bajo CIRP: `D(t,T) ≈ r_f − r_d` (aproximación de primer orden del diferencial de tasas, doméstica vs. extranjera).
- Si el descuento a plazo es **positivo** → comprar forward (pedir prestada la moneda doméstica, invertir en la extranjera). Si es **negativo** → vender forward (lo inverso). Cuanto mayor la magnitud del descuento, más rentable se espera la posición.
- **Aproximación retail equivalente (sin forwards)**: ir largo en el par cuya divisa base tiene la tasa de interés más alta relativa a la cotizada, y cobrar el swap positivo diario — hay que verificar signo y magnitud del swap real en la plataforma del usuario, no asumirlo del diferencial de tasas "de libro".

### Versión cross-sectional (8.2.1), "carry alto-menos-bajo"
- Para una canasta de N monedas, calcular el descuento a plazo `Dᵢ(t,T)` de cada una.
- Comprar forwards de las monedas en el **cuantil superior** de descuento a plazo (mayor carry), vender las del **cuantil inferior** — construcción dólar-neutral (long-short), similar en espíritu al momentum cross-sectional de la idea 002.

## Regla de salida
No explícita en el paper para el horizonte de mantenimiento — típicamente se mantiene mientras el diferencial de tasas siga siendo favorable y se rebalancea periódicamente (mensual es común en la literatura citada), cerrando o invirtiendo la posición si el diferencial se revierte.

## Régimen donde debería funcionar
Periodos de "risk-on" / baja volatilidad macro, con diferenciales de tasas de interés estables y sostenidos entre economías — el carry trade tiende a generar retornos consistentes y de baja volatilidad aparente en estos periodos ("picking up nickels").

## Régimen donde debería fallar — el riesgo más importante de esta estrategia
Esta es la estrategia con el perfil de riesgo de cola más documentado de las tres propuestas: en episodios de "risk-off" / crisis (ej. 2008, marzo 2020), las monedas de alto carry se deprecian abruptamente y de forma simultánea mientras las de bajo carry (financiamiento) se aprecian — es decir, **las pérdidas llegan concentradas exactamente cuando el resto del portafolio probablemente también está bajo estrés**, no de forma independiente. Esto es precisamente el tipo de correlación-en-régimen-de-estrés que `trading-risk-manager` señala como el error más común al sumar riesgo entre estrategias — el carry trade es el ejemplo de libro de texto de ese riesgo, no una excepción.

## Evidencia disponible
- **Marco teórico**: UIRP/CIRP, con el "forward premium puzzle" documentado extensamente — el paper cita una lista larga de estudios seminales: Fama (1984), Hansen & Hodrick (1980), Engel (1996), Bekaert/Wei/Xing (2007), entre ~25 referencias (nota 141).
- **Riesgo de cola del carry**: citado explícitamente vía Brunnermeier, Nagel & Pedersen (2008) "Carry Trades and Currency Crashes" — literatura específicamente sobre el riesgo de reversión abrupta ("crash risk") del carry trade, no solo su retorno promedio.
- **Versión cross-sectional**: Lustig, Roussanov & Verdelhan (2011, 2014) — documentan el factor de carry cross-sectional como una prima de riesgo sistemática, no solo anecdótica.
- **Grado de evidencia: alto en cuanto al retorno promedio histórico documentado académicamente, pero con la propia literatura citada advirtiendo explícitamente sobre el riesgo de cola/crash** — este es el caso donde la "evidencia de que funciona en promedio" y la "evidencia de que puede perder mucho de golpe" vienen de las mismas fuentes citadas por el paper. No es una estrategia para sobredimensionar en el paso 07.

## Riesgos conocidos
- **Riesgo de cola/crash correlacionado** (ver arriba) — el riesgo dominante, con literatura académica dedicada específicamente a documentarlo.
- **Brecha entre el carry "de libro" (forwards/CIRP) y el swap real del bróker retail** — verificar explícitamente antes de asumir el retorno teórico del paper.
- **Apalancamiento**: el carry trade retail suele operarse apalancado para que el diferencial de tasas sea significativo frente al capital — esto amplifica tanto el carry cobrado como las pérdidas de un movimiento de precio adverso, y debe pasar estrictamente por el sizing conservador de `trading-risk-manager` (paso 07).
- **Costos de swap/spread** pueden variar por bróker y por condiciones de mercado (ampliarse justo en los momentos de estrés donde más se necesita salir).

## AED (paso 02) — 2026-09-16

**Pares elegidos:** AUD/JPY y NZD/JPY — los dos pares de carry más clásicos del mercado (dólar australiano y neozelandés, tasas relativamente altas durante casi todo el periodo, contra el yen, con tasas cercanas a cero durante la mayor parte de estos 22 años). Datos mensuales reales de TradingView, **2004-05 a 2026-08 (269 barras cada uno)**.

### Qué se midió (y qué NO)
Esto mide **solo la apreciación/depreciación de precio** de la divisa de carry, no el carry trade completo — no se incluye el swap/rollover diario que efectivamente cobra (o paga) un bróker retail. Según la hipótesis del paper (la UIRP no se sostiene, las divisas de tasa alta tienden a apreciarse en vez de depreciarse), la sola apreciación de precio ya debería mostrar una deriva positiva en promedio — si además se le suma el swap cobrado, el carry trade completo debería verse mejor todavía. Si el precio por sí solo no muestra deriva, el edge del carry trade depende enteramente de que el swap compense, lo cual no se puede verificar sin acceso al bróker real del usuario.

### Resultados

| Par | Retorno medio mensual | Anualizado | Volatilidad anualizada | Sharpe (solo precio) | p-valor (signo aleatorio) | Max drawdown | Win rate |
|---|---|---|---|---|---|---|---|
| AUD/JPY | +0.130% | +1.55% | 13.56% | 0.11 | 0.597 | **−47.0%** (sep-2007 a dic-2008) | 54.9% |
| NZD/JPY | +0.095% | +1.14% | 14.05% | 0.08 | 0.706 | **−51.9%** (may-2007 a dic-2008) | 55.2% |

### Lectura honesta
- **La dirección es la correcta** (deriva positiva, no negativa, consistente con la anomalía UIRP que describe el paper), pero **no es estadísticamente significativa** en ninguno de los dos pares — el retorno anualizado de ~1.1-1.5% vía apreciación de precio pura es pequeño frente a una volatilidad anualizada de ~14%, y el test de signo aleatorio no rechaza la hipótesis de que la deriva observada sea puro ruido.
- **El riesgo de cola no es teórico, aparece directamente en los datos**: ambos pares perdieron **entre 47% y 52% de su valor** en la Crisis Financiera Global de 2007-2008 — exactamente el "crash risk" documentado por Brunnermeier, Nagel & Pedersen que ya se había señalado como el riesgo dominante de esta estrategia en el documento de hipótesis. No es una advertencia abstracta: es lo que pasó, con estos pares específicos, la última vez que hubo una crisis de "risk-off" seria.
- El win rate mensual (~55%) es apenas mejor que una moneda al aire, consistente con "muchos meses ganando poco, pocos meses perdiendo mucho" — el patrón clásico de "recoger monedas frente a la apisonadora" que describe la literatura de carry trade.

### Sesgos y limitaciones
- No se midió el swap/rollover real — todo el caso a favor del carry trade depende de esa pieza que aquí no se pudo verificar.
- Un solo episodio de crisis (2007-2008) domina el drawdown máximo de ambos pares — no hay forma de saber, con un solo evento en la muestra, si "−50%" es representativo del peor caso futuro o si el próximo episodio de estrés sería distinto (mejor o peor).
- 268 observaciones mensuales suena bien por encima del mínimo de ~30, pero son altamente correlacionadas entre sí en el tiempo (autocorrelación de régimen) y ambos pares (AUD/JPY, NZD/JPY) se mueven casi juntos — en la práctica hay mucho menos de "2×268" información independiente.

### Recomendación
**No pasar al paso 03 todavía.** La apreciación de precio por sí sola no muestra un edge estadísticamente significativo, y el caso a favor de la estrategia depende de una pieza (el swap real) que no se pudo medir aquí. Antes de codificar cualquier regla:
1. Verificar con el bróker real del usuario el swap efectivo en estos pares (o similares), y calcular si ese swap, sumado a esta deriva de precio débil, produce un retorno esperado neto positivo después de costos.
2. Si se decide continuar, el paso 07 (Sizing·RM) debe dimensionar la posición asumiendo explícitamente un escenario de −50% como el observado en 2008, no solo la volatilidad "normal" fuera de crisis.

## Siguiente paso sugerido
Verificar el swap real del bróker antes de cualquier otra cosa — sin esa pieza, no hay forma de saber si el carry trade completo (no solo la apreciación de precio) tiene edge neto de costos. Si el usuario puede aportar esa información, se puede recalcular el retorno esperado total y decidir si pasa a paso 03.

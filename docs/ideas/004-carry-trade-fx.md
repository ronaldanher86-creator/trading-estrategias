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

## Siguiente paso sugerido
Pasar a `trading-data-analyst` (paso 02, AED) para: (a) verificar el swap real ofrecido por el bróker del usuario en 2-3 pares candidatos de alto diferencial de tasas, comparado contra el diferencial de tasas oficial, y (b) revisar el historial de esos pares en periodos de estrés de mercado conocidos, para dimensionar realistamente el peor caso antes de escribir ninguna regla de entrada en el paso 03.

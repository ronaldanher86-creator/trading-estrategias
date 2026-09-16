# J-Hook (patrón de continuación de tendencia)

## Hipótesis
Tras un movimiento fuerte, una consolidación/retroceso breve y poco profundo ("el gancho") permite entrar en la reanudación de la tendencia con menor riesgo que en el impulso inicial, porque el retroceso filtra a los compradores tardíos y confirma que la tendencia sigue viva antes de arriesgar capital.

## Origen y qué tan sólida es la evidencia (leer esto antes que nada)
Investigué en ~10 fuentes independientes (Investing.com, TradingView, Hit and Run Candlesticks, The Forex Geek, PatternsWizard, CompassFX, foros de useThinkScript/StockCharts). Conclusiones honestas:

- **No es un concepto de Investor's Business Daily / William O'Neil.** Busqué explícitamente la conexión con las "bases" de IBD (cup-with-handle, doble suelo, base plana) — el J-Hook **no aparece** como una de las bases oficiales de esa metodología. Es un patrón de análisis técnico discrecional de origen difuso, popularizado por varios sitios de trading retail (Hit and Run Candlesticks lo vende como parte de un ebook/membresía), no por una fuente académica ni institucional.
- **No encontré ningún backtest cuantitativo publicado** con win rate, profit factor o muestra de operaciones. Todas las fuentes son descriptivas/cualitativas. Esto es un patrón de "lo reconozco cuando lo veo", no uno con una definición numérica única y validada — es la señal de alerta #1 del checklist de overfitting que ya tenemos en `docs/validacion_estrategias.md` (sección 04-06): sin evidencia previa, TODO el peso de la validación recae en el paso 02 (AED) y 04-06 (backtest/optimización/robustez) que hagamos aquí, desde cero.
- **Grado de evidencia: hipótesis con folklore técnico convergente, sin evidencia estadística de terceros.** Trátalo como una idea a testear, no como algo con track record.

## Definición consolidada (donde las fuentes coinciden)
Las ~6 fuentes que sí dan una definición coinciden en 4 fases:

1. **Impulso inicial**: movimiento fuerte y direccional (alcista o bajista) con momentum claro.
2. **Retroceso/pullback**: correctivo, "poco profundo y controlado" — la cifra que más se repite es **no más del 50% del impulso inicial**, y una fuente lo acota además a **3-5 velas** de duración. Aquí es donde más varían las fuentes (una lo describe como una zona lateral tipo "caja", otra como un patrón de velas de reversión específico tipo martillo/doji/harami).
3. **Base/redondeo**: el precio deja de caer, se estabiliza, y empieza a girar de nuevo hacia la dirección del impulso original — es lo que le da la forma de "J" (o de "J" invertida en la versión bajista).
4. **Ruptura/confirmación**: el precio rompe el máximo (o mínimo, en la versión bajista) del impulso inicial / del retroceso — ahí se dispara la entrada.

### Versión alcista
- **Entrada**: al romper el máximo previo (algunas fuentes piden cierre de vela por encima del nivel, otras aceptan la apertura del día siguiente por encima).
- **Stop loss**: debajo del mínimo del retroceso.
- **Objetivo**: proyectar la altura del impulso inicial desde el punto de ruptura, o usar trailing stop.

### Versión bajista (inversa)
- **Entrada**: al romper el mínimo previo tras un rebote de alivio poco profundo.
- **Stop loss**: encima del máximo del rebote de alivio.
- **Objetivo**: proyectar la caída inicial, o trailing stop.

### Condición de fallo (una fuente lo señala explícitamente)
Si el precio no logra superar el máximo previo tras el retroceso, el patrón **falla** y se convierte en un **doble techo** (o doble suelo en la versión bajista) — es decir, el mismo setup que no confirma es, literalmente, el patrón de reversión opuesto. Esto es clave para el diseño de reglas: hay que decidir un límite de tiempo/precio explícito a partir del cual se considera "fallido" en vez de dejarlo indefinido.

## Universo e instrumentos
No especificado por ninguna fuente como restrictivo — se presenta como aplicable a acciones, forex, cripto, índices. Sin evidencia de que funcione mejor en algún instrumento específico.

## Timeframe
Las fuentes son consistentes en que "funciona en cualquier timeframe, de velas de 1 minuto a swing diario" — de nuevo, afirmación sin respaldo cuantitativo, hay que testearlo empíricamente en el(los) timeframe(s) que interesen.

## Régimen donde debería funcionar
Mercados en tendencia (alcista o bajista) ya establecida, con retrocesos ordenados. Es, en esencia, una variante de un patrón de **bandera (flag) o pull-back de continuación** — comparte la lógica de "trend pause and go" con patrones ya bien documentados en literatura técnica (bull/bear flags).

## Régimen donde debería fallar
- Mercados laterales/sin tendencia previa clara (no hay "impulso inicial" que darle continuidad).
- Retrocesos profundos (>50-60% del impulso) — ahí deja de ser un J-Hook y pasa a ser una posible reversión real, no una pausa.
- Alta volatilidad/noticias que invaliden la lectura de "pausa ordenada" (gaps, whipsaws).

## Ambigüedades que hay que resolver ANTES del paso 03 (Reglas) — esto no es opcional
A diferencia de la estrategia Initial Balance que ya tienen codificada (`ELON_SpaceX_v1.mq5`), el J-Hook **no tiene una definición numérica única** en las fuentes. Para que `pinescript-developer`/`mql5-developer` puedan escribir "blanco o negro, sin ambigüedad" (regla del paso 03), hay que fijar explícitamente, con una decisión tuya:
1. **Cómo se mide el "impulso inicial"**: ¿un múltiplo de ATR? ¿un % de movimiento en N barras? ¿un mínimo de pendiente?
2. **Profundidad máxima del retroceso**: ¿el 50% que más se repite, u otro umbral (ej. medido en % o en múltiplos de ATR)?
3. **Duración del retroceso**: ¿un rango de barras (ej. 3-5 como sugiere una fuente), o sin límite mientras no rompa el 50%?
4. **Qué cuenta como "base/redondeo"**: ¿un patrón de velas específico (martillo, doji, envolvente alcista), o simplemente N barras sin hacer nuevo mínimo?
5. **Nivel exacto de ruptura**: ¿el máximo del impulso inicial, o el máximo del retroceso? (las fuentes no siempre distinguen los dos).
6. **Condición de invalidación/fallo**: ¿cuánto tiempo/velas se espera la ruptura antes de descartar el setup como fallido (→ posible doble techo)?

## Riesgos conocidos
- **Curve-fitting alto si no se fijan las reglas ANTES de ver los resultados**: con tantos grados de libertad (6 parámetros ambiguos arriba), es fácil ajustar cada uno hasta que "funcione" en el histórico — es exactamente el tipo de patrón que el paso 05 (Optimización, "meseta no pico") está diseñado para detectar. Fijar los 6 parámetros de la lista anterior antes de correr el primer backtest, no después.
- **Sin evidencia previa de terceros que respalde ninguna combinación de esos parámetros** — toda la carga de la prueba recae en el AED (paso 02) y el backtest propio.
- **Solapamiento conceptual con patrones ya documentados** (bull/bear flag, pullback de continuación) — vale la pena, en el paso 02, comparar contra la literatura cuantitativa de esos patrones análogos en vez de tratar el J-Hook como algo inédito.
- **Definición subjetiva entre fuentes** (rango de vela vs. patrón de velas específico vs. "caja" de consolidación) — cualquier resultado de backtest solo es válido para la definición exacta que se elija, no para "el J-Hook" en abstracto.

## Siguiente paso sugerido
Pasar a **`trading-data-analyst`** (paso 02, AED) — pero antes de eso, se necesita que decidas los 6 parámetros de la sección de ambigüedades, porque el AED no puede medir "¿hay edge estructural?" sobre una definición que todavía tiene múltiples lecturas posibles. Si quieres, puedo proponerte un set de valores por defecto razonables (ej. retroceso ≤50% medido en ATR, 3-8 barras, ruptura = máximo del impulso inicial, invalidación a los N días) para que los apruebes o ajustes antes de seguir.

# Método TIS — línea de producción de estrategias

> Una estrategia es una línea de producción. Entra una premisa. Sale una estrategia validada.
> Siempre el mismo método. Cambia el activo.

Toda estrategia de este repo pasa por los mismos 8 pasos, en el mismo orden, sin saltarse ninguno. Lo único que cambia entre estrategias es el activo y la premisa de entrada — el proceso es idéntico siempre. Eso es lo que lo hace repetible y lo que evita que una estrategia se apruebe "porque se ve bien", sin haber pasado por el mismo filtro que todas las demás.

Cada paso tiene un color:
- 🟠 **Naranja = lo hace la IA, en horas.** Los agentes de `.claude/agents/` ejecutan estos pasos de punta a punta y entregan el resultado para revisión.
- 🟢 **Verde = criterio.** O lo haces tú, o no lo hace nadie. Un agente puede preparar el análisis y la recomendación, pero la decisión final es tuya — no se avanza al siguiente paso sin que la tomes explícitamente.

## Los 8 pasos

### 01 · Hipótesis 🟢
**Qué es:** el core logic. Qué comportamiento explotas y por qué existe.
**Agente:** `trading-strategy-researcher` redacta la hipótesis (universo, timeframe, regla propuesta, por qué debería existir esa ineficiencia, en qué régimen debería fallar) en `docs/ideas/NNN-nombre.md`.
**Por qué es verde:** ningún agente puede decidir *qué* ineficiencia vale la pena perseguir ni si la explicación económica es creíble — eso es criterio de trading, no un cálculo. El agente propone, tú decides si la hipótesis pasa a AED.

### 02 · AED (Análisis Exploratorio de Datos) 🟢
**Qué es:** ¿hay un edge estructural en los datos, o es ruido?
**Agente:** `trading-data-analyst` explora los datos históricos del instrumento/hipótesis: distribución de retornos condicionada al patrón propuesto, tamaño de muestra disponible, estacionalidad real vs. casualidad, comparación contra un benchmark aleatorio/shuffle.
**Por qué es verde:** distinguir "hay señal" de "esto es ruido con suerte" requiere juicio sobre significancia práctica, no solo estadística — el agente entrega la evidencia, tú decides si hay suficiente base para codificar reglas.

### 03 · Reglas 🟠
**Qué es:** entrada, salida, filtros, riesgo — en código. Blanco o negro, sin ambigüedad ("depende del contexto" no es una regla).
**Agentes:** `pinescript-developer` (prototipo en TradingView) y/o `mql5-developer` (EA en MetaTrader 5) traducen la hipótesis validada en AED a reglas exactas y codificadas.
**Salida:** código que compila, con cada condición de entrada/salida/filtro/riesgo explícita — nada de "si se ve bien, entrar".

### 04 · Backtest 🟠
**Qué es:** in-sample / out-of-sample. **La prueba fuera de muestra se usa una sola vez.**
**Agente:** `trading-quant-backtester` fija el corte IS/OOS *antes* de mirar resultados, corre el backtest in-sample, y corre el out-of-sample exactamente una vez con los parámetros ya fijados — si el resultado no gusta, no se vuelve a tocar el mismo corte OOS (eso lo convierte en in-sample y contamina la prueba). Se necesita un periodo OOS nuevo o más historia.
**Costos:** comisión, spread y slippage reales del instrumento, no genéricos.

### 05 · Optimización 🟠
**Qué es:** sensibilidad de parámetros. Se busca una **meseta, no un pico.**
**Agente:** `trading-quant-backtester` varía cada parámetro clave ±20-30% y grafica/reporta cómo cambia la métrica objetivo. Un parámetro que solo funciona en un valor exacto (pico aislado) es la firma clásica de overfitting; una meseta ancha donde valores cercanos también funcionan razonablemente es la señal de un edge real.

### 06 · Robustez 🟠
**Qué es:** stress test, Montecarlo, slippage y comisiones reales.
**Agente:** `trading-quant-backtester` corre Monte Carlo de reordenamiento de trades (para estimar el peor drawdown posible con la misma serie de resultados en otro orden), y stress-testea con slippage/comisiones más adversos que el caso base, para ver si el edge sobrevive con margen, no justo en el límite.
**Veredicto de cierre de 04-06:** `RECHAZAR` (no hay edge o no sobrevive a costos/OOS/robustez) · `ITERAR` (hay señal pero requiere ajuste específico, documentado) · `PROMOVER A SIZING` (pasa los checks mínimos).

### 07 · Sizing · RM 🟢
**Qué es:** cuánto riesgo merece esta estrategia. Drawdown esperado. Portafolio.
**Agente:** `trading-risk-manager` calcula tamaño de posición (riesgo % por operación, tope de fractional-Kelly), el drawdown esperado con ese tamaño, y cómo encaja dentro del presupuesto de riesgo del portafolio completo (asumiendo que en un régimen de estrés las correlaciones entre estrategias suben, no se mantienen en su nivel histórico "normal").
**Por qué es verde:** cuánto riesgo estás dispuesto a tolerar por esta estrategia específica, dado tu capital y tus otras posiciones, es una decisión personal — el agente calcula el rango razonable y el peor caso, tú fijas el número final.

### 08 · Deploy 🟢
**Qué es:** incubación en demo, servidor, monitoreo del edge.
**Agente:** `trading-deploy-monitor` define el plan de incubación (cuenta demo, tiempo mínimo/número mínimo de operaciones antes de real, servidor/VPS donde correrá 24/7 si aplica), y el protocolo de monitoreo continuo para detectar *edge decay* (degradación del edge en vivo respecto al backtest) una vez en producción.
**Por qué es verde:** decidir cuándo el comportamiento en demo es "suficientemente parecido" al backtest para pasar a real, y cuándo el edge se degradó lo bastante como para pausar la estrategia, es una decisión que exige tu criterio sobre el momento y el contexto de mercado — ningún agente debe tomarla de forma autónoma.

## Puerta final: `trading-code-reviewer`
Antes de que cualquier estrategia entre a demo (fin del paso 03/04, previo al 08), `trading-code-reviewer` audita el código específicamente por look-ahead bias, repainting, manejo de horario/sesión, gestión de órdenes y que el circuit breaker de `Include/RiskManager.mqh` esté realmente integrado. No es uno de los 8 pasos numerados — es un gate transversal que se aplica cada vez que hay código nuevo o modificado en pasos 03-06.

## Señales de alerta de overfitting (revisar en 04-06)
- Muchos parámetros libres relativo al número de trades disponibles.
- El rendimiento depende de 1-2 operaciones extremas ("home runs") más que de una ventaja consistente.
- Parámetros "raros" sin justificación económica (pico aislado, no meseta — ver paso 05).
- Datos con supervivencia sesgada (ej. solo instrumentos que siguen listados hoy).
- Menos de ~30 trades en el set de validación: evidencia preliminar, no concluyente — se documenta como tal, no se fuerza una conclusión fuerte.

## Estado vivo
Cada estrategia tiene su fila en [`../ESTRATEGIAS.md`](../ESTRATEGIAS.md) indicando en cuál de los 8 pasos está, la fecha, y el veredicto vigente.

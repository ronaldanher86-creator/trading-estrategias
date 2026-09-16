# Marco de validación de estrategias

Este documento define el proceso que **toda** estrategia de este repositorio debe pasar antes de considerarse apta para demo/forward test, y luego para cuenta real. Es la referencia que usa el agente `trading-quant-backtester` y el criterio con el que `trading-risk-manager` decide el tamaño de posición.

No existe una estrategia "rentable" hasta que sobrevive este proceso completo. Un backtest bonito in-sample no es evidencia suficiente — la mayoría de las estrategias que se ven bien en un solo backtest fallan en datos nuevos.

## Etapas

### 0. Hipótesis (`trading-strategy-researcher`)
Toda estrategia nace como una hipótesis escrita en `docs/ideas/NNN-nombre.md`, con la lógica económica de por qué debería funcionar y en qué régimen debería fallar. Sin esto, no se avanza a la etapa 1 — evita construir sobre patrones puramente numéricos sin explicación.

### 1. Backtest in-sample
- Definir universo, timeframe, periodo y **fijar de antemano** el corte in-sample/out-of-sample antes de mirar resultados fuera de muestra.
- Métricas mínimas a reportar: Sharpe, Sortino (si hay asimetría), max drawdown y duración del drawdown, win rate, profit factor, expectancy por trade, número total de trades.
- Costos realistas obligatorios: comisión, spread, slippage del instrumento específico (no un valor genérico).

### 2. Validación out-of-sample
- Se corre exactamente la misma estrategia (mismos parámetros, sin retocar) sobre el periodo reservado.
- Si el rendimiento out-of-sample es sustancialmente peor que in-sample (regla práctica: caída de Sharpe >50% o pérdida de la señal de significancia estadística), la estrategia se marca **RECHAZAR** o **ITERAR**, no se re-optimiza sobre el mismo set out-of-sample (eso solo lo convierte en in-sample otra vez).

### 3. Walk-forward (cuando el histórico lo permite)
- Ventanas rodantes de entrenamiton/validación en vez de un único corte estático, para detectar si el edge es estable en el tiempo o es un artefacto de un periodo particular.

### 4. Test de robustez / anti-overfitting (al menos uno)
- **Sensibilidad de parámetros**: variar cada parámetro clave ±20-30% y verificar que el resultado no colapsa (una estrategia robusta no depende de un valor exacto).
- **Monte Carlo de reordenamiento de trades**: mezclar el orden de los trades históricos y recalcular el drawdown máximo posible — el drawdown "de la peor secuencia posible" suele ser peor que el observado en el orden original.
- **Bootstrap / remuestreo**: para verificar que el retorno medio por trade es estadísticamente distinto de cero dado el tamaño de muestra.

### 5. Tamaño de muestra mínimo
- Menos de ~30 trades en el set de validación: no hay evidencia estadística suficiente para una conclusión fuerte. Se documenta como "evidencia preliminar" y se pide más historia o más instrumentos correlacionados antes de asignar capital real.

### 6. Veredicto
`trading-quant-backtester` emite uno de tres veredictos, registrados en `ESTRATEGIAS.md`:
- **RECHAZAR**: no hay edge, o no sobrevive a costos/OOS.
- **ITERAR**: hay señal pero requiere ajuste específico (se documenta cuál) o más datos.
- **PROMOVER A RISK-SIZING**: pasa los checks mínimos → pasa a `trading-risk-manager` para definir tamaño de posición y presupuesto de riesgo dentro del portafolio.

### 7. Forward test en demo
Antes de cuenta real, toda estrategia corre en cuenta demo con el tamaño de posición ya definido por `trading-risk-manager`, durante un periodo mínimo razonable para el timeframe de la estrategia (ej. no menos de 20-30 operaciones reales en demo para una intradía). El forward test en demo es la única validación que usa datos genuinamente no vistos por el desarrollador en absoluto — trátalo como la prueba más importante, no como un trámite.

### 8. Cuenta real
Solo tras pasar 0-7. Se inicia con una fracción del tamaño de posición objetivo (ej. 25-50%) y se escala gradualmente si el comportamiento en real es consistente con el forward test.

## Señales de alerta de overfitting (revisar siempre)
- Muchos parámetros libres relativo al número de trades disponibles.
- El rendimiento depende de 1-2 operaciones extremas ("home runs") más que de una ventaja consistente.
- Parámetros "raros" sin justificación económica (ej. un umbral que solo funciona en un valor muy específico, sin una razón de por qué ese valor y no uno cercano).
- El backtest usa datos de un instrumento/periodo con supervivencia sesgada (ej. solo acciones que siguen listadas hoy).

## Estado vivo
Cada estrategia debe tener su fila correspondiente en [`../ESTRATEGIAS.md`](../ESTRATEGIAS.md) con la etapa actual, fecha de última actualización y el veredicto vigente.

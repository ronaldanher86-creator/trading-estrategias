# Sistemas de Trading

Repositorio de desarrollo de estrategias de trading sistematizado, orientado a rentabilidad sostenible en el largo plazo (no a resultados de un solo backtest). Cubre investigación, backtesting/validación estadística, gestión de riesgo, e implementación en MetaTrader 5 (MQL5) y TradingView (Pine Script v6).

## Filosofía
En trading sistemático, la supervivencia de largo plazo depende más de la **gestión de riesgo y la validación estadística rigurosa** que de encontrar una señal de entrada brillante. Ninguna estrategia de este repo se considera "rentable" sin evidencia out-of-sample, y ninguna se lleva a cuenta real sin un circuit breaker de pérdida activo.

## Estructura
```
.claude/agents/       Subagentes especializados de Claude Code (ver abajo)
docs/
  ideas/               Hipótesis de estrategias nuevas (formato en trading-strategy-researcher)
  validacion_estrategias.md   Proceso de validación obligatorio para toda estrategia
  reportes/            Reportes periódicos de desempeño (trading-performance-reporter)
Include/
  RiskManager.mqh      Módulo de riesgo reutilizable: sizing, circuit breaker diario y de cuenta
pine/                  Fuentes Pine Script v6 (indicadores/estrategias)
backtests/             Scripts de backtest reproducibles (cuando aplique Python u otro)
ESTRATEGIAS.md         Registro vivo del estado de cada estrategia
ELON_SpaceX_v1.mq5     EA existente: ruptura de Initial Balance sobre SPCX (ver ESTRATEGIAS.md)
```

## Flujo de trabajo — Método TIS (8 pasos)
> Una estrategia es una línea de producción. Entra una premisa. Sale una estrategia validada. Siempre el mismo método, cambia el activo.

Cada estrategia pasa por los mismos 8 pasos, en el mismo orden (detalle completo en [`docs/validacion_estrategias.md`](docs/validacion_estrategias.md)). 🟠 = lo ejecuta la IA en horas. 🟢 = criterio: lo decides tú, o no lo decide nadie.

| # | Paso | Agente | Color |
|---|---|---|---|
| 01 | Hipótesis — core logic, qué explotas y por qué existe | `trading-strategy-researcher` | 🟢 |
| 02 | AED — ¿edge estructural o ruido? | `trading-data-analyst` | 🟢 |
| 03 | Reglas — entrada, salida, filtros, riesgo, en código | `pinescript-developer` / `mql5-developer` | 🟠 |
| 04 | Backtest — IS/OOS, el OOS se usa una sola vez | `trading-quant-backtester` | 🟠 |
| 05 | Optimización — sensibilidad de parámetros, meseta no pico | `trading-quant-backtester` | 🟠 |
| 06 | Robustez — stress test, Montecarlo, costos reales | `trading-quant-backtester` | 🟠 |
| 07 | Sizing · RM — cuánto riesgo, drawdown esperado, portafolio | `trading-risk-manager` | 🟢 |
| 08 | Deploy — incubación en demo, servidor, monitoreo del edge | `trading-deploy-monitor` | 🟢 |

Gate transversal (aplica en 03-06 y antes de 08): **`trading-code-reviewer`** — revisa look-ahead bias, repainting, manejo de horario/sesión, gestión de órdenes y que el circuit breaker de `Include/RiskManager.mqh` esté realmente integrado, no solo documentado.

Agente continuo (fuera de los 8 pasos, corre después de 08 mientras la estrategia esté viva): **`trading-performance-reporter`** — genera reportes periódicos (semanal/mensual) de desempeño real de todo el portafolio vs. lo esperado en la validación de cada estrategia, guardados en `docs/reportes/`. Complementa a `trading-deploy-monitor`: este último decide si hay señal de alerta de edge decay, el reportero produce el registro histórico honesto de números reales vs. esperados.

Invócalos por nombre para avanzar un paso concreto, por ejemplo: *"usa trading-strategy-researcher para revisar la serie Systematic Pill y proponer 2-3 ideas"*, *"pásale la hipótesis a trading-data-analyst para el AED"*, *"pásale ELON_SpaceX_v1.mq5 a trading-code-reviewer antes de probarlo en demo"*, o *"genera el reporte semanal con trading-performance-reporter"*.

## Estado actual
Ver [`ESTRATEGIAS.md`](ESTRATEGIAS.md). A la fecha, `ELON_SpaceX_v1.mq5` está portado desde Pine Script pero **no compilado, no integrado con el módulo de riesgo, y no validado estadísticamente en este repo** — es el primer candidato a pasar por el flujo completo.

## Material de research
Los PDFs en la raíz (serie "Systematic Pill", informes de portafolio, estrategias de acciones) son insumo de research para `trading-strategy-researcher`, no estrategias ya validadas — trátalos como fuente a contrastar, no como verdad.

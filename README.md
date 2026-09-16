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
Include/
  RiskManager.mqh      Módulo de riesgo reutilizable: sizing, circuit breaker diario y de cuenta
pine/                  Fuentes Pine Script v6 (indicadores/estrategias)
backtests/             Scripts de backtest reproducibles (cuando aplique Python u otro)
ESTRATEGIAS.md         Registro vivo del estado de cada estrategia
ELON_SpaceX_v1.mq5     EA existente: ruptura de Initial Balance sobre SPCX (ver ESTRATEGIAS.md)
```

## Flujo de trabajo (agentes)
El desarrollo de una estrategia nueva pasa por 5 subagentes, cada uno con un rol acotado y responsabilidad clara:

1. **`trading-strategy-researcher`** — convierte una idea/observación/paper en una hipótesis testeable con regla de entrada/salida explícita y régimen de fallo esperado.
2. **`pinescript-developer`** — prototipa y compila la estrategia en Pine Script v6, probándola en vivo sobre el chart de TradingView vía MCP (compila, lee errores, lee resultados del Strategy Tester).
3. **`trading-quant-backtester`** — valida estadísticamente: split in-sample/out-of-sample, walk-forward, test de robustez/anti-overfitting, costos realistas. Emite veredicto: RECHAZAR / ITERAR / PROMOVER A RISK-SIZING.
4. **`trading-risk-manager`** — define tamaño de posición y presupuesto de riesgo dentro del portafolio completo (no solo por estrategia aislada), y mantiene el circuit breaker de pérdida.
5. **`mql5-developer`** — porta la estrategia validada a un EA de MetaTrader 5, siguiendo las convenciones ya establecidas en `ELON_SpaceX_v1.mq5` (inputs agrupados, horario de servidor calibrado y comentado, magic number, modos de sizing).
6. **`trading-code-reviewer`** — última puerta antes de demo: revisa específicamente look-ahead bias, repainting, manejo de horario/sesión, gestión de órdenes y que el circuit breaker de riesgo esté realmente integrado (no solo documentado).

Invócalos por nombre cuando quieras avanzar una etapa concreta, por ejemplo: *"usa trading-strategy-researcher para revisar la serie Systematic Pill y proponer 2-3 ideas"*, o *"pásale ELON_SpaceX_v1.mq5 a trading-code-reviewer antes de probarlo en demo"*.

## Estado actual
Ver [`ESTRATEGIAS.md`](ESTRATEGIAS.md). A la fecha, `ELON_SpaceX_v1.mq5` está portado desde Pine Script pero **no compilado, no integrado con el módulo de riesgo, y no validado estadísticamente en este repo** — es el primer candidato a pasar por el flujo completo.

## Material de research
Los PDFs en la raíz (serie "Systematic Pill", informes de portafolio, estrategias de acciones) son insumo de research para `trading-strategy-researcher`, no estrategias ya validadas — trátalos como fuente a contrastar, no como verdad.

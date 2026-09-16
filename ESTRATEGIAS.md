# Registro de estrategias

Estado vivo de cada estrategia del portafolio. Se actualiza en cada etapa del proceso descrito en [`docs/validacion_estrategias.md`](docs/validacion_estrategias.md). No se asigna capital real a ninguna estrategia sin pasar por `RECHAZAR / ITERAR / PROMOVER A SIZING` y luego por forward test en demo.

Los 8 pasos del Método TIS: **01** Hipótesis 🟢 · **02** AED 🟢 · **03** Reglas 🟠 · **04** Backtest 🟠 · **05** Optimización 🟠 · **06** Robustez 🟠 · **07** Sizing·RM 🟢 · **08** Deploy 🟢. Detalle en [`docs/validacion_estrategias.md`](docs/validacion_estrategias.md).

| Estrategia | Instrumento | Archivo | Paso actual | Veredicto | Riesgo asignado | Última actualización |
|---|---|---|---|---|---|---|
| ELON SpaceX v1 (ruptura Initial Balance) | SPCX (acción) | `ELON_SpaceX_v1.mq5` | 03 · Reglas — portado desde Pine v6, **no compilado ni backtesteado en este repo todavía** | Sin evaluar | — | 2026-09-16 |
| J-Hook (continuación de tendencia) | Por definir | `docs/ideas/001-j-hook-breakout.md` | 01 · Hipótesis — 6 ambigüedades de definición sin resolver, sin evidencia de terceros | Sin evaluar | — | 2026-09-16 |
| Momentum de series de tiempo multi-activo | Oro / S&P 500 / EUR-USD (probado) | `docs/ideas/002-momentum-series-de-tiempo-multiactivo.md` | 02 · AED — sin edge detectable en la versión simple (single-instrument, sin vol-scaling) probada sobre 2011-2026 | Resultado nulo, no pasa a 03 sin ampliar el test | — | 2026-09-16 |
| Trading de pares (dólar-neutral) | XOM/CVX (probado, 14 meses) | `docs/ideas/003-trading-de-pares.md` | 02 · AED — señal direccionalmente favorable (correlación z/reversión −0.41) pero n real=18, insuficiente para 03 | Evidencia preliminar, ampliar muestra antes de avanzar | — | 2026-09-16 |
| Carry trade FX | AUD/JPY, NZD/JPY (probado, 22 años) | `docs/ideas/004-carry-trade-fx.md` | 02 · AED — deriva de precio positiva pero no significativa (p=0.60/0.71); drawdown de -47/-52% en 2008 confirma el riesgo de cola | No pasa a 03 sin verificar swap real del bróker | — | 2026-09-16 |

## Cómo añadir una estrategia nueva
1. `trading-strategy-researcher` crea la hipótesis en `docs/ideas/NNN-nombre.md` — **01 Hipótesis**.
2. `trading-data-analyst` confirma si hay edge estructural en los datos — **02 AED**.
3. `pinescript-developer` y/o `mql5-developer` codifican las reglas — **03 Reglas**.
4. `trading-quant-backtester` corre backtest, optimización y robustez, y emite veredicto — **04-06**.
5. Si el veredicto es "PROMOVER A SIZING", `trading-risk-manager` define tamaño y presupuesto de riesgo — **07 Sizing·RM**.
6. `trading-code-reviewer` da el visto bueno final antes de demo (gate transversal).
7. `trading-deploy-monitor` define el plan de incubación en demo y el monitoreo de edge decay — **08 Deploy**.
8. Se agrega/actualiza la fila correspondiente en esta tabla en cada paso, no solo al final.

## Reportes de desempeño
Una vez una estrategia llega a **08 · Deploy**, `trading-performance-reporter` genera reportes periódicos (semanal/mensual) en [`docs/reportes/`](docs/reportes/) comparando desempeño real vs. lo esperado en su validación (pasos 04-07). Es el registro histórico del portafolio — para alertas de degradación del edge en vivo, ver `trading-deploy-monitor`.

## Nota sobre ELON SpaceX v1
El propio header del archivo indica que fue portado 1:1 desde Pine Script preservando los valores por defecto ya ajustados en TradingView, pero que **no está compilado ni verificado en MetaEditor**. Antes de considerarla para demo:
- [ ] Compilar en MetaEditor sin errores.
- [ ] Confirmar el offset horario servidor↔NY con la fecha actual (el comentario del código está calibrado al 2026-09-09; verificar que sigue vigente, especialmente si hubo cambio de horario de verano de por medio).
- [ ] Integrar `Include/RiskManager.mqh` (circuit breaker diario y de cuenta) — actualmente el EA no lo tiene.
- [ ] Correr el proceso completo de `docs/validacion_estrategias.md` con datos históricos reales de SPCX.
- [ ] Pasar por `trading-code-reviewer` antes de demo.

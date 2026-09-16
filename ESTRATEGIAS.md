# Registro de estrategias

Estado vivo de cada estrategia del portafolio. Se actualiza en cada etapa del proceso descrito en [`docs/validacion_estrategias.md`](docs/validacion_estrategias.md). No se asigna capital real a ninguna estrategia sin pasar por `RECHAZAR / ITERAR / PROMOVER A RISK-SIZING` y luego por forward test en demo.

| Estrategia | Instrumento | Archivo | Etapa actual | Veredicto | Riesgo asignado | Última actualización |
|---|---|---|---|---|---|---|
| ELON SpaceX v1 (ruptura Initial Balance) | SPCX (acción) | `ELON_SpaceX_v1.mq5` | Portado desde Pine v6, **no compilado ni backtesteado en este repo todavía** | Sin evaluar | — | 2026-09-16 |

## Cómo añadir una estrategia nueva
1. `trading-strategy-researcher` crea la hipótesis en `docs/ideas/NNN-nombre.md`.
2. `pinescript-developer` y/o `mql5-developer` implementan un prototipo.
3. `trading-quant-backtester` corre el proceso de validación completo y emite veredicto.
4. Si el veredicto es "PROMOVER A RISK-SIZING", `trading-risk-manager` define tamaño y presupuesto de riesgo.
5. `trading-code-reviewer` da el visto bueno final antes de demo.
6. Se agrega/actualiza la fila correspondiente en esta tabla.

## Nota sobre ELON SpaceX v1
El propio header del archivo indica que fue portado 1:1 desde Pine Script preservando los valores por defecto ya ajustados en TradingView, pero que **no está compilado ni verificado en MetaEditor**. Antes de considerarla para demo:
- [ ] Compilar en MetaEditor sin errores.
- [ ] Confirmar el offset horario servidor↔NY con la fecha actual (el comentario del código está calibrado al 2026-09-09; verificar que sigue vigente, especialmente si hubo cambio de horario de verano de por medio).
- [ ] Integrar `Include/RiskManager.mqh` (circuit breaker diario y de cuenta) — actualmente el EA no lo tiene.
- [ ] Correr el proceso completo de `docs/validacion_estrategias.md` con datos históricos reales de SPCX.
- [ ] Pasar por `trading-code-reviewer` antes de demo.

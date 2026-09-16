//+------------------------------------------------------------------+
//|                                              RiskManager.mqh      |
//|  Modulo de gestion de riesgo reutilizable para EAs de este repo. |
//|                                                                    |
//|  Objetivo: que ninguna estrategia individual pueda, por bug o por |
//|  una racha adversa, causar una perdida no controlada. Este modulo |
//|  NO decide la senal de entrada -- solo el tamano de posicion y    |
//|  los interruptores (circuit breakers) de perdida diaria y de      |
//|  drawdown de cuenta.                                              |
//|                                                                    |
//|  Uso tipico dentro de un EA:                                      |
//|    #include <RiskManager.mqh>
//|    CRiskManager risk;
//|    int OnInit(){ risk.Init(InpMagic, InpMaxDailyLossPct,           |
//|                            InpMaxAccountDrawdownPct); ... }        |
//|    void OnTick(){                                                  |
//|      risk.OnTick(); // actualiza estado, detecta reset de dia      |
//|      if(!risk.CanTrade()) return; // breaker activo, no operar     |
//|      double lots = risk.LotsByRiskPct(stopDistPrice, riskPct);     |
//|      ...                                                            |
//|    }                                                                |
//+------------------------------------------------------------------+
#property strict

//====================================================================
// CRiskManager
//====================================================================
class CRiskManager
{
private:
   ulong    m_magic;
   double   m_maxDailyLossPct;      // % de equity: perdida maxima permitida EN EL DIA
   double   m_maxAccountDDPct;      // % de equity: drawdown maximo permitido DESDE EL PICO HISTORICO
   double   m_maxRiskPctPerTrade;   // tope duro de riesgo por operacion, independiente de lo que pida el EA

   datetime m_currentDay0;
   double   m_dayStartEquity;
   double   m_equityPeak;

   bool     m_dailyBreakerTripped;
   bool     m_accountBreakerTripped;

   string   m_logPrefix;

   datetime DayStart(datetime t)
   {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      dt.hour = 0; dt.min = 0; dt.sec = 0;
      return StructToTime(dt);
   }

   void LogBreaker(string what, double lossPct, double limitPct)
   {
      string msg = StringFormat(
         "[RiskManager][magic=%I64u] %s activado: perdida/drawdown=%.2f%% >= limite=%.2f%%. Trading detenido hasta reset manual o nuevo dia.",
         m_magic, what, lossPct, limitPct);
      Print(msg);
      // Persistimos en un archivo para que quede evidencia aunque se reinicie la terminal.
      int h = FileOpen(m_logPrefix + "_breaker_log.txt", FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
      if(h != INVALID_HANDLE)
      {
         FileSeek(h, 0, SEEK_END);
         FileWriteString(h, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " " + msg + "\n");
         FileClose(h);
      }
   }

public:
   void Init(ulong magic, double maxDailyLossPct, double maxAccountDDPct, double maxRiskPctPerTrade = 2.0)
   {
      m_magic               = magic;
      m_maxDailyLossPct     = MathAbs(maxDailyLossPct);
      m_maxAccountDDPct     = MathAbs(maxAccountDDPct);
      m_maxRiskPctPerTrade  = MathAbs(maxRiskPctPerTrade);
      m_logPrefix           = "RM_" + IntegerToString((int)magic);

      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      m_currentDay0     = DayStart(TimeCurrent());
      m_dayStartEquity  = eq;
      m_equityPeak      = eq;
      m_dailyBreakerTripped   = false;
      m_accountBreakerTripped = false;
   }

   //-----------------------------------------------------------------
   // Llamar en cada OnTick antes de cualquier logica de entrada.
   // Detecta cambio de dia (resetea el breaker diario) y actualiza el
   // pico de equity para el breaker de cuenta (que NO se resetea solo).
   //-----------------------------------------------------------------
   void OnTick()
   {
      double eq  = AccountInfoDouble(ACCOUNT_EQUITY);
      datetime d0 = DayStart(TimeCurrent());

      if(d0 != m_currentDay0)
      {
         m_currentDay0        = d0;
         m_dayStartEquity     = eq;
         m_dailyBreakerTripped = false; // el breaker diario SI se resetea cada dia
      }

      if(eq > m_equityPeak) m_equityPeak = eq;

      // --- Breaker diario ---
      if(!m_dailyBreakerTripped && m_dayStartEquity > 0)
      {
         double dayLossPct = (m_dayStartEquity - eq) / m_dayStartEquity * 100.0;
         if(dayLossPct >= m_maxDailyLossPct)
         {
            m_dailyBreakerTripped = true;
            LogBreaker("Breaker DIARIO", dayLossPct, m_maxDailyLossPct);
         }
      }

      // --- Breaker de cuenta (drawdown desde el pico historico) ---
      // Este NO se resetea automaticamente al dia siguiente: requiere
      // revision manual del usuario (cambiar m_accountBreakerTripped
      // exige tocar el codigo o exponer un input de "reset manual").
      if(!m_accountBreakerTripped && m_equityPeak > 0)
      {
         double ddPct = (m_equityPeak - eq) / m_equityPeak * 100.0;
         if(ddPct >= m_maxAccountDDPct)
         {
            m_accountBreakerTripped = true;
            LogBreaker("Breaker DE CUENTA", ddPct, m_maxAccountDDPct);
         }
      }
   }

   //-----------------------------------------------------------------
   // El EA debe consultar esto antes de abrir CUALQUIER posicion nueva.
   // No afecta al cierre/gestion de posiciones ya abiertas.
   //-----------------------------------------------------------------
   bool CanTrade()
   {
      return (!m_dailyBreakerTripped && !m_accountBreakerTripped);
   }

   bool IsDailyBreakerTripped()   { return m_dailyBreakerTripped; }
   bool IsAccountBreakerTripped() { return m_accountBreakerTripped; }

   //-----------------------------------------------------------------
   // Permite al usuario resetear manualmente el breaker de cuenta tras
   // revisar la situacion (nunca se resetea solo -- es intencional).
   //-----------------------------------------------------------------
   void ManualResetAccountBreaker()
   {
      m_accountBreakerTripped = false;
      m_equityPeak = AccountInfoDouble(ACCOUNT_EQUITY);
      Print(StringFormat("[RiskManager][magic=%I64u] Breaker de cuenta reseteado manualmente. Nuevo pico=%.2f", m_magic, m_equityPeak));
   }

   //-----------------------------------------------------------------
   // Tamano de posicion por % de riesgo fijo, con tope duro absoluto.
   // stopDistPrice: distancia del stop loss en precio (no en pips).
   // riskPct: riesgo deseado para ESTA operacion (se limita a
   //          m_maxRiskPctPerTrade aunque el EA pida mas).
   // Devuelve lotes SIN normalizar a volume_step/min/max -- el EA debe
   // seguir aplicando su propio NormalizeLots como hace ELON_SpaceX_v1.
   //-----------------------------------------------------------------
   double LotsByRiskPct(double stopDistPrice, double riskPct)
   {
      if(stopDistPrice <= 0) return 0.0;

      double effectiveRiskPct = MathMin(MathAbs(riskPct), m_maxRiskPctPerTrade);
      double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
      double tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize <= 0 || tickValue <= 0) return 0.0;

      double riskMoney     = equity * effectiveRiskPct / 100.0;
      double lossPerLot    = (stopDistPrice / tickSize) * tickValue;
      if(lossPerLot <= 0) return 0.0;

      return riskMoney / lossPerLot;
   }

   //-----------------------------------------------------------------
   // Cota superior de fractional-Kelly, para usar como TECHO del
   // riesgo por operacion, nunca como el valor a usar directamente.
   // winRate en [0,1]. avgWin/avgLoss en unidades monetarias positivas.
   // fraction: que fraccion del Kelly completo aplicar (recomendado
   //           0.25-0.5; el default es conservador a proposito).
   //-----------------------------------------------------------------
   double FractionalKellyCapPct(double winRate, double avgWin, double avgLoss, double fraction = 0.25)
   {
      if(avgLoss <= 0 || avgWin <= 0) return 0.0;
      double b = avgWin / avgLoss;
      double kelly = winRate - (1.0 - winRate) / b;
      if(kelly <= 0) return 0.0; // Kelly negativo = la estrategia no deberia operar con size positivo
      double cappedPct = kelly * fraction * 100.0;
      return MathMin(cappedPct, m_maxRiskPctPerTrade);
   }
};

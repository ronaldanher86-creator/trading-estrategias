//+------------------------------------------------------------------+
//|                                              ELON_SpaceX_v1.mq5   |
//|  Port de Pine v6 "ELON . long/short para SpaceX [TIS v1]"        |
//|  Estrategia de ruptura del Initial Balance (Trade It Simple)      |
//|                                                                    |
//|  IMPORTANTE: portado 1:1 desde el Pine Script del usuario,        |
//|  preservando los valores por defecto ya ajustados (10min IB,      |
//|  TP 0.60xIB, SL 0.40xIB, 95% capital, etc). No compilado aun --   |
//|  verificar en MetaEditor antes de usar en cuenta real.            |
//+------------------------------------------------------------------+
#property copyright "Trade It Simple"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//====================================================================
// 1. Initial Balance
//====================================================================
input group "1. Initial Balance (HORA DE SERVIDOR -- ver nota abajo)"
input int    InpIB_Minutes        = 10;    // Duracion del IB (min)
input int    InpIB_StartHour_Srv  = 16;    // Hora de inicio (calibrado 2026-09-09: servidor = NY+7h en EDT)
input int    InpIB_StartMin_Srv   = 30;    // Minuto de inicio
input bool   InpShowBox           = true;  // Dibujar caja del IB en el grafico

//====================================================================
// 2. Entrada
//====================================================================
input group "2. Entrada"
enum EntryMode { ENTRY_WICK, ENTRY_CLOSE };
input EntryMode InpEntryMode      = ENTRY_WICK;  // Wick(stops) / Close(confirmado)
input double InpBufferK           = 0.00;  // Buffer de ruptura = k x IB
input int    InpMinDelayMin       = 0;     // Espera minima tras el IB (min)
input int    InpMaxWaitMin        = 45;    // Tiempo maximo para entrar (min desde fin del IB)
input bool   InpEnableLong        = true;
input bool   InpEnableShort       = true;

//====================================================================
// 3. Filtro de tamano del IB
//====================================================================
input group "3. Filtro de tamano del IB"
input bool   InpUseMinIB          = false; // Off por defecto -- en 41 sesiones SPCX nunca se activo un umbral de 0.55%
input double InpMinIB_PctPrice    = 0.55;

//====================================================================
// 4. Objetivo y stop (multiplos del IB)
//====================================================================
input group "4. Objetivo y stop"
input double InpTP_K              = 0.60;
input double InpSL_CapK           = 0.40;

//====================================================================
// 5. Tamano de posicion
//====================================================================
input group "5. Tamano de posicion"
enum SizeMode { SIZE_ALL_CAPITAL, SIZE_RISK_PCT, SIZE_FIXED_QTY };
input SizeMode InpSizeMode        = SIZE_ALL_CAPITAL; // Todo el capital / Riesgo fijo % / Cantidad fija
input double InpCapitalPct        = 95.0;   // % de equity a desplegar (modo ALL_CAPITAL)
input double InpRiskPct           = 1.0;    // % de equity en riesgo (modo RISK_PCT)
input double InpFixedQty          = 100;    // Unidades fijas (modo FIXED_QTY, antes de convertir a lotes)

//====================================================================
// 6. Cierre forzoso (HORA DE SERVIDOR)
//====================================================================
input group "6. Cierre forzoso"
input int    InpFlatHour_Srv      = 22;    // Hora servidor equivalente a 15:30 NY (calibrado 2026-09-09: servidor = NY+7h en EDT)
input int    InpFlatMin_Srv       = 30;

//====================================================================
// 7. Identificacion
//====================================================================
input group "7. Identificacion"
input ulong  InpMagic             = 20260910;

//====================================================================
// NOTA SOBRE HORARIOS (leer antes de usar)
// MQL5 no tiene zonas horarias como Pine. Estos inputs son en HORA DE
// TU SERVIDOR MT5, no hora de Nueva York. Para calibrar UNA VEZ:
//   1. Mira la hora que marca la esquina inferior derecha de tu MT5.
//   2. Compara contra la hora real de Nueva York en ese momento.
//   3. La diferencia (offset) es constante casi todo el ano, EXCEPTO
//      2-3 semanas en marzo y noviembre donde EE.UU. y tu broker
//      cambian de horario de verano en fechas distintas -- en esas
//      semanas hay que sumar/restar 1 hora a mano.
//====================================================================

//--- Estado global
datetime g_ibStartTime    = 0;
datetime g_ibEndTime      = 0;
datetime g_flatTime       = 0;
datetime g_currentDay0    = 0;
double   g_ibHigh         = 0;
double   g_ibLow          = 0;
bool     g_ibReady        = false;
bool     g_tradedToday    = false;
ulong    g_buyStopTicket  = 0;
ulong    g_sellStopTicket = 0;
datetime g_lastBarTime    = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetTypeFillingBySymbol(_Symbol);
   g_currentDay0 = 0; // fuerza ResetDailyState en el primer tick
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "ELON_");
}

//+------------------------------------------------------------------+
datetime DayStart(datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
datetime TimeAtHourMin(datetime day0, int h, int m)
{
   MqlDateTime dt;
   TimeToStruct(day0, dt);
   dt.hour = h; dt.min = m; dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
void DeleteOrderIfExists(ulong &ticket)
{
   if(ticket == 0) return;
   if(OrderSelect(ticket))
      trade.OrderDelete(ticket);
   ticket = 0;
}

//+------------------------------------------------------------------+
void ResetDailyState(datetime now)
{
   g_currentDay0 = DayStart(now);
   g_ibHigh = 0.0;
   g_ibLow  = 0.0;
   g_ibReady = false;
   g_tradedToday = false;

   g_ibStartTime = TimeAtHourMin(g_currentDay0, InpIB_StartHour_Srv, InpIB_StartMin_Srv);
   g_ibEndTime   = g_ibStartTime + InpIB_Minutes * 60;
   g_flatTime    = TimeAtHourMin(g_currentDay0, InpFlatHour_Srv, InpFlatMin_Srv);

   DeleteOrderIfExists(g_buyStopTicket);
   DeleteOrderIfExists(g_sellStopTicket);
   ObjectsDeleteAll(0, "ELON_");
}

//+------------------------------------------------------------------+
// Redondea 'lots' al volume_step del simbolo y lo limita a min/max
//+------------------------------------------------------------------+
double NormalizeLots(double lots)
{
   double stepV = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minV  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxV  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(stepV <= 0) stepV = 0.01;
   lots = MathFloor(lots / stepV) * stepV;
   if(lots < minV) lots = 0.0;   // si no alcanza ni el minimo, no operar (equivale a qty<=0 en Pine)
   if(lots > maxV) lots = maxV;
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
// Traduce cada modo de sizing de Pine (f_qty) a lotes MT5
//   entryPriceForSizing: precio anticipado de entrada (para modo ALL_CAPITAL)
//   stopDistPrice       : distancia del stop en precio (para modo RISK_PCT)
//+------------------------------------------------------------------+
double CalcLots(double stopDistPrice, double entryPriceForSizing)
{
   double equity      = AccountInfoDouble(ACCOUNT_EQUITY);
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize <= 0) contractSize = 1.0;

   double lots = 0.0;

   if(InpSizeMode == SIZE_ALL_CAPITAL)
   {
      if(entryPriceForSizing > 0)
      {
         double units = equity * InpCapitalPct / 100.0 / entryPriceForSizing;
         lots = units / contractSize;
      }
   }
   else if(InpSizeMode == SIZE_RISK_PCT)
   {
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(stopDistPrice > 0 && tickSize > 0 && tickValue > 0)
      {
         double riskMoney = equity * InpRiskPct / 100.0;
         double ticksAtRisk = stopDistPrice / tickSize;
         lots = riskMoney / (ticksAtRisk * tickValue);
      }
   }
   else // SIZE_FIXED_QTY
   {
      lots = InpFixedQty / contractSize;
   }

   return NormalizeLots(lots);
}

//+------------------------------------------------------------------+
bool NewBar()
{
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t != g_lastBarTime) { g_lastBarTime = t; return true; }
   return false;
}

//+------------------------------------------------------------------+
void DrawBox()
{
   if(!InpShowBox || !g_ibReady) return;
   string nH = "ELON_IBHigh", nL = "ELON_IBLow";
   if(ObjectFind(0, nH) < 0)
      ObjectCreate(0, nH, OBJ_HLINE, 0, 0, g_ibHigh);
   else
      ObjectSetDouble(0, nH, OBJPROP_PRICE, g_ibHigh);
   ObjectSetInteger(0, nH, OBJPROP_COLOR, clrLime);

   if(ObjectFind(0, nL) < 0)
      ObjectCreate(0, nL, OBJ_HLINE, 0, 0, g_ibLow);
   else
      ObjectSetDouble(0, nL, OBJPROP_PRICE, g_ibLow);
   ObjectSetInteger(0, nL, OBJPROP_COLOR, clrRed);
}

//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagic)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void CloseAllPositions(string reasonComment)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagic)
         trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   datetime now = TimeCurrent();

   //--- cambio de dia: reiniciar estado del IB
   if(DayStart(now) != g_currentDay0)
      ResetDailyState(now);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0 || ask <= 0) return;

   bool inIB    = (now >= g_ibStartTime && now < g_ibEndTime);
   bool afterIB = (now >= g_ibEndTime);

   //--- construir el IB con el precio en vivo (bid), igual de fino que calc_on_every_tick=true en Pine
   if(inIB)
   {
      if(g_ibHigh == 0 || bid > g_ibHigh) g_ibHigh = bid;
      if(g_ibLow  == 0 || bid < g_ibLow)  g_ibLow  = bid;
   }

   if(!inIB && !g_ibReady && g_ibHigh > 0 && g_ibLow > 0)
   {
      g_ibReady = true;
      DrawBox();
   }

   //--- cierre forzoso
   if(now >= g_flatTime)
   {
      if(HasOpenPosition()) CloseAllPositions("EOD");
      DeleteOrderIfExists(g_buyStopTicket);
      DeleteOrderIfExists(g_sellStopTicket);
      return;
   }

   if(!g_ibReady) return;

   double ibRange = g_ibHigh - g_ibLow;
   if(ibRange <= 0) return;
   double ibPct = (g_ibHigh + g_ibLow) > 0 ? 100.0 * ibRange / ((g_ibHigh + g_ibLow) * 0.5) : 0;
   bool ibBigEnough = (!InpUseMinIB) || (ibPct >= InpMinIB_PctPrice);

   double buf     = InpBufferK * ibRange;
   double upLevel = g_ibHigh + buf;
   double dnLevel = g_ibLow  - buf;
   double stopDistForSizing = MathMin(InpSL_CapK, 1.0) * ibRange;

   bool windowDelayOk = (now >= g_ibStartTime + (InpIB_Minutes + InpMinDelayMin) * 60);
   bool windowStillOk = (now <= g_ibEndTime + InpMaxWaitMin * 60);

   //--- ya hay posicion abierta -> si una entrada llego, cancelar la otra pendiente (OCA manual)
   if(HasOpenPosition())
   {
      DeleteOrderIfExists(g_buyStopTicket);
      DeleteOrderIfExists(g_sellStopTicket);
      g_tradedToday = true;
   }

   bool canEnter = afterIB && windowDelayOk && windowStillOk && ibBigEnough && !g_tradedToday && !HasOpenPosition();

   //--- ventana vencida o ya operamos hoy -> limpiar pendientes
   if(g_tradedToday || !windowStillOk)
   {
      DeleteOrderIfExists(g_buyStopTicket);
      DeleteOrderIfExists(g_sellStopTicket);
   }

   if(!canEnter) return;

   if(InpEntryMode == ENTRY_WICK)
   {
      //--- colocar (o mantener) ordenes stop en los bordes del IB, cancelacion mutua manual
      if(InpEnableLong && g_buyStopTicket == 0)
      {
         double lots = CalcLots(stopDistForSizing, upLevel);
         if(lots > 0)
         {
            double sl = MathMax(upLevel - InpSL_CapK * ibRange, g_ibLow);
            double tp = upLevel + InpTP_K * ibRange;
            if(trade.BuyStop(lots, upLevel, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "ELON-L"))
               g_buyStopTicket = trade.ResultOrder();
         }
      }
      if(InpEnableShort && g_sellStopTicket == 0)
      {
         double lots = CalcLots(stopDistForSizing, dnLevel);
         if(lots > 0)
         {
            double sl = MathMin(dnLevel + InpSL_CapK * ibRange, g_ibHigh);
            double tp = dnLevel - InpTP_K * ibRange;
            if(trade.SellStop(lots, dnLevel, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "ELON-S"))
               g_sellStopTicket = trade.ResultOrder();
         }
      }
   }
   else // ENTRY_CLOSE: solo evaluar al cierre de una vela nueva, como el Pine original
   {
      if(!NewBar()) return;
      double lastClose = iClose(_Symbol, PERIOD_CURRENT, 1);

      if(InpEnableLong && lastClose > upLevel)
      {
         double lots = CalcLots(stopDistForSizing, ask);
         if(lots > 0)
         {
            double sl = MathMax(ask - InpSL_CapK * ibRange, g_ibLow);
            double tp = ask + InpTP_K * ibRange;
            if(trade.Buy(lots, _Symbol, ask, sl, tp, "ELON-L"))
               g_tradedToday = true;
         }
      }
      else if(InpEnableShort && lastClose < dnLevel)
      {
         double lots = CalcLots(stopDistForSizing, bid);
         if(lots > 0)
         {
            double sl = MathMin(bid + InpSL_CapK * ibRange, g_ibHigh);
            double tp = bid - InpTP_K * ibRange;
            if(trade.Sell(lots, _Symbol, bid, sl, tp, "ELON-S"))
               g_tradedToday = true;
         }
      }
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                  Robo_MM_IFR.mq5 |
//|                                                  Douglas Volcato |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Douglas Volcato"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//|                      Parâmetros do robô                          |
//+------------------------------------------------------------------+

enum ESTRATEGIA_ENTRADA
   {
      APENAS_MM, // Apenas médias móveis
      APENAS_IFR, // Apenas IFR
      MM_E_IFR // Médias e IFR
   };
   
sinput string s0; //-------Estratégia de Entrada-------
input ESTRATEGIA_ENTRADA estrategia = APENAS_MM;

sinput string s1; //-------Médias Móveis-------
input int mm_rapida_periodo = 12; // Período Média Rápida
input int mm_lenta_periodo = 32; // Período Média Lenta
input ENUM_TIMEFRAMES mm_tempo_grafico = PERIOD_CURRENT; // Tempo Gráfico
input ENUM_MA_METHOD mm_method = MODE_EMA; // Método
input ENUM_APPLIED_PRICE mm_preco = PRICE_CLOSE; //Preço Aplicado

sinput string s2; //-------IFR-------
input int ifr_periodo = 5; // Período IFR
input ENUM_TIMEFRAMES ifr_tempo_grafico = PERIOD_CURRENT; // Tempo Gráfico
input ENUM_APPLIED_PRICE ifr_preco = PRICE_CLOSE; //Preço Aplicado

input int ifr_sobrecompra = 70; // Nível Sobrecompra
input int ifr_sobrevenda = 30; // Nível Sobrevenda

sinput string s3; //--------------
input int num_lots = 100; // Número de lotes
input double TK = 60; // Take Porfit
input double SL = 30; //Stop Loss

sinput string s4; //--------------
input string hora_limite_fecha_op = "17:40"; // Horário de fehcar Posições

//+------------------------------------------------------------------+
//|                 Variáveis para os indicadores                    |
//+------------------------------------------------------------------+

int mm_rapida_Handle; // Handle controlador da média móvel rápida
double mm_rapida_Buffer[]; // Buffer para armazenamento de dados das médias

int mm_lenta_Handle; // Handle controlador da média móvel lenta
double mm_lenta_Buffer[]; // Buffer para armazenamento de dados das médias

int ifr_Handle; // Handle controlador do IFR
double ifr_Buffer[]; // Buffer para armazenamento de dados do IFR

//+------------------------------------------------------------------+
//|                     Variáveis das funções                        |
//+------------------------------------------------------------------+

int magic_number = 123456; // Número mágico do robô

MqlRates velas[]; // Variável para armazenar as velas
MqlTick tick; // Variável para armazenar ticks

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   mm_rapida_Handle = iMA(_Symbol,mm_tempo_grafico,mm_rapida_periodo,0,mm_method,mm_preco);
   mm_lenta_Handle = iMA(_Symbol,mm_tempo_grafico,mm_lenta_periodo,0,mm_method,mm_preco);
   ifr_Handle = iRSI(_Symbol,ifr_tempo_grafico,ifr_periodo,ifr_preco);
   
   if(mm_rapida_Handle < 0 || mm_lenta_Handle < 0 || ifr_Handle < 0)
      {
         Alert("Erro ao criar handles para o indicador - erro: ", GetLastError());
         return(-1);
      }
   
   CopyRates(_Symbol,_Period,0,4,velas);
   ArraySetAsSeries(velas,true);
   
   ChartIndicatorAdd(0,0,mm_lenta_Handle);
   ChartIndicatorAdd(0,0,mm_rapida_Handle);
   ChartIndicatorAdd(0,1,ifr_Handle);
   
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(mm_rapida_Handle);
   IndicatorRelease(mm_lenta_Handle);
   IndicatorRelease(ifr_Handle);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      //desenhaLinhaVertical("Li",tick.time,clrRed); 
      
      // Alimenta buffers com dados;
      CopyBuffer(mm_lenta_Handle,0,0,4,mm_lenta_Buffer);
      CopyBuffer(mm_rapida_Handle,0,0,4,mm_rapida_Buffer);
      CopyBuffer(ifr_Handle,0,0,4,ifr_Buffer);
      CopyRates(_Symbol,_Period,0,4,velas);
      
      // Ordena os vetores de dados
      ArraySetAsSeries(velas,true);
      ArraySetAsSeries(mm_rapida_Buffer,true);
      ArraySetAsSeries(mm_lenta_Buffer,true);
      ArraySetAsSeries(ifr_Buffer,true);
      
      // Alimenta variavel tick com dados
      SymbolInfoTick(_Symbol,tick);
      
      // Logica para ativar compra
      bool compra_mm_cros = mm_rapida_Buffer[0] > mm_lenta_Buffer[0] &&
                            mm_rapida_Buffer[2] < mm_lenta_Buffer[2];
      bool compra_ifr = ifr_Buffer[0] <= ifr_sobrevenda;
      
      // Logica para ativar venda
      bool venda_mm_cros = mm_lenta_Buffer[0] > mm_rapida_Buffer[0] &&
                            mm_lenta_Buffer[2] < mm_rapida_Buffer[2];
      bool venda_ifr = ifr_Buffer[0] >= ifr_sobrecompra;
      
      // Execucao das estrategias
      bool comprar = false;
      bool vender = false;
      
      if(estrategia == APENAS_MM)
         {
            comprar = compra_mm_cros;
            vender = venda_mm_cros;
         }
      else if(estrategia == APENAS_IFR)
         {
            comprar = compra_ifr;
            vender = venda_ifr; 
         }
      else
         {
            comprar = compra_mm_cros && compra_ifr;
            vender = venda_mm_cros && venda_ifr;
         }
         
      if(temosNovaVela() && PositionSelect(_Symbol) == false)
         {
            if(comprar)
            {
               desenhaLinhaVertical("Compra", velas[1].time,clrGreen);
               compraAMercado();
            }
            
            if(vender)
            {
               desenhaLinhaVertical("Venda", velas[1].time,clrRed);
               vendaAMercado();
            }
         }
         
      // Fecha operações caso esteja no final da hora limite
      if(TimeToString(TimeCurrent(),TIME_MINUTES) == hora_limite_fecha_op && PositionSelect(_Symbol) == true)
      {
         Print("Fim do tempo operacional, encerrando operações abertas.");
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            fechaCompra();
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            fechaVenda();
         }
      }
  }

void desenhaLinhaVertical(string nome, datetime dt, color cor = clrAqua)
   {
      ObjectDelete(0,nome);
      ObjectCreate(0,nome,OBJ_VLINE,0,dt,0);
      ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   }

//+------------------------------------------------------------------+
//|                  Funções para envio de ordens                    |
//+------------------------------------------------------------------+

void compraAMercado()
   {
      MqlTradeRequest requisicao;
      MqlTradeResult resposta;
      
      ZeroMemory(requisicao);
      ZeroMemory(resposta);
      
      requisicao.action = TRADE_ACTION_DEAL; // Executa ordem a mercado
      requisicao.magic = magic_number; // Número mágico
      requisicao.symbol = _Symbol; // Símbolo do ativo
      requisicao.volume = num_lots; // Número de lotes
      requisicao.price = NormalizeDouble(tick.ask,_Digits); // Preço
      requisicao.sl = NormalizeDouble(tick.ask - SL*_Point,_Digits); // Stop Loss
      requisicao.tp = NormalizeDouble(tick.ask - TK*_Point,_Digits); // Take Profit
      requisicao.deviation = 0; // Variabilidade desvio do preço de requisição
      requisicao.type = ORDER_TYPE_BUY; // Tipo de ordem
      requisicao.type_filling = ORDER_FILLING_FOK; // Tipo de execução da ordem
      
      bool sent = OrderSend(requisicao,resposta);
      
      if(resposta.retcode == 10008 || resposta.retcode == 10009)
         {
            Print("Ordem de compra enviada com sucesso!");
         }
      else
         {
            Print("Erro ao enviar ordem de compra. Erro: ", GetLastError());
            ResetLastError();
         }
   }
   
void vendaAMercado()
   {
      MqlTradeRequest requisicao;
      MqlTradeResult resposta;
      
      ZeroMemory(requisicao);
      ZeroMemory(resposta);
      
      requisicao.action = TRADE_ACTION_DEAL; // Executa ordem a mercado
      requisicao.magic = magic_number; // Número mágico
      requisicao.symbol = _Symbol; // Símbolo do ativo
      requisicao.volume = num_lots; // Número de lotes
      requisicao.price = NormalizeDouble(tick.bid,_Digits); // Preço
      requisicao.sl = NormalizeDouble(tick.bid - SL*_Point,_Digits); // Stop Loss
      requisicao.tp = NormalizeDouble(tick.bid - TK*_Point,_Digits); // Take Profit
      requisicao.deviation = 0; // Variabilidade desvio do preço de requisição
      requisicao.type = ORDER_TYPE_SELL; // Tipo de ordem
      requisicao.type_filling = ORDER_FILLING_FOK; // Tipo de execução da ordem
      
      bool sent = OrderSend(requisicao,resposta);
      
      if(resposta.retcode == 10008 || resposta.retcode == 10009)
         {
            Print("Ordem de venda enviada com sucesso!");
         }
      else
         {
            Print("Erro ao enviar ordem de venda. Erro: ", GetLastError());
            ResetLastError();
         }
   }
   
void fechaCompra()
   {
      MqlTradeRequest requisicao;
      MqlTradeResult resposta;
      
      ZeroMemory(requisicao);
      ZeroMemory(resposta);
      
      requisicao.action = TRADE_ACTION_DEAL;
      requisicao.magic = magic_number;
      requisicao.symbol = _Symbol;
      requisicao.volume = num_lots;
      requisicao.price = 0;
      requisicao.type = ORDER_TYPE_SELL;
      requisicao.type_filling = ORDER_FILLING_RETURN;
      
      bool sent = OrderSend(requisicao,resposta);
      
      if(resposta.retcode == 10008 || resposta.retcode == 10009)
         {
            Print("Ordem de venda enviada com sucesso!");
         }
      else
         {
            Print("Erro ao enviar ordem de venda. Erro: ", GetLastError());
            ResetLastError();
         }
   }
   
void fechaVenda()
   {
      MqlTradeRequest requisicao;
      MqlTradeResult resposta;
      
      ZeroMemory(requisicao);
      ZeroMemory(resposta);
      
      requisicao.action = TRADE_ACTION_DEAL;
      requisicao.magic = magic_number;
      requisicao.symbol = _Symbol;
      requisicao.volume = num_lots;
      requisicao.price = 0;
      requisicao.type = ORDER_TYPE_BUY;
      requisicao.type_filling = ORDER_FILLING_RETURN;
      
      bool sent = OrderSend(requisicao,resposta);
      
      if(resposta.retcode == 10008 || resposta.retcode == 10009)
         {
            Print("Ordem de compra enviada com sucesso!");
         }
      else
         {
            Print("Erro ao enviar ordem de compra. Erro: ", GetLastError());
            ResetLastError();
         }
   }

bool temosNovaVela()
   {
      static datetime last_time = 0;
      datetime lastbar_time = (datetime) SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
 
      if(last_time == 0)
         {
            last_time=lastbar_time;
            return(false);
         }
      if(last_time != lastbar_time)
         {
            last_time=lastbar_time;
            return(true); 
         }
      return false;
   }
   
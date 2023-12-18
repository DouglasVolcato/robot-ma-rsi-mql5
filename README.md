# Expert Advisor Readme

## Robot_ma_ifr Expert Advisor

### Overview
The `Robot_ma_ifr` Expert Advisor is designed for automated trading on the MetaTrader 5 platform. It combines two popular technical indicators, Moving Averages (MM) and the Relative Strength Index (IFR), to generate buy and sell signals based on user-defined strategies.

### Parameters

1. **Estratégia de Entrada (Entry Strategy)**
   - Options: APENAS_MM (Only Moving Averages), APENAS_IFR (Only Relative Strength Index), MM_E_IFR (Moving Averages and Relative Strength Index)
   - Description: Select the strategy for generating entry signals.

2. **Médias Móveis (Moving Averages)**
   - `mm_rapida_periodo`: Period of the fast moving average.
   - `mm_lenta_periodo`: Period of the slow moving average.
   - `mm_tempo_grafico`: Timeframe for moving averages.
   - `mm_method`: Method for calculating moving averages.
   - `mm_preco`: Applied price for moving averages.
   
3. **IFR (Relative Strength Index)**
   - `ifr_periodo`: Period of the Relative Strength Index.
   - `ifr_tempo_grafico`: Timeframe for the Relative Strength Index.
   - `ifr_preco`: Applied price for the Relative Strength Index.
   - `ifr_sobrecompra`: Overbought level for the Relative Strength Index.
   - `ifr_sobrevenda`: Oversold level for the Relative Strength Index.
   
4. **Operação (Operation)**
   - `num_lots`: Number of lots to trade.
   - `TK`: Take Profit distance in points.
   - `SL`: Stop Loss distance in points.

5. **Hora Limite para Fechar Operações (Closing Time)**
   - `hora_limite_fecha_op`: Time to close open positions.

### Indicators and Functions

- **Indicators**
  - Two moving averages and the Relative Strength Index are used to generate trading signals.
  
- **Functions**
  - `desenhaLinhaVertical`: Draws a vertical line on the chart.
  - `compraAMercado`: Places a market buy order.
  - `vendaAMercado`: Places a market sell order.
  - `fechaCompra`: Closes a buy position.
  - `fechaVenda`: Closes a sell position.
  - `temosNovaVela`: Checks if a new candle has started.

### Usage

1. **Installation**
   - Copy the `Robot_ma_ifr.mq5` file to the `Experts` folder of your MetaTrader 5 installation.

2. **Configuration**
   - Open the MetaEditor, compile the `Robot_ma_ifr.mq5` file, and attach the EA to a chart in MetaTrader 5.
   - Configure the parameters based on your preferred trading strategy.

3. **Execution**
   - The EA will execute buy and sell orders based on the selected strategy and parameters.

### Disclaimer

Trading involves risk, and it's important to thoroughly test any strategy before using it in a live trading environment. The `Robot_ma_ifr` Expert Advisor is provided as-is, and the user is responsible for any financial losses incurred through its use.

### Author Information

- **Author:** Douglas Volcato
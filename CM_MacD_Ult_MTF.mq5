//+------------------------------------------------------------------+
//| CM_MacD_Ult_MTF.mq5                                              |
//| Converted from Pine Script by ChrisMoody                         |
//| Updated 4-10-2014                                                |
//| MQL5 Version - MT5 Compatible - FULLY FIXED                      |
//+------------------------------------------------------------------+
#property copyright "ChrisMoody"
#property link      "https://www.tradingview.com"
#property version   "3.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4

//--- plot MACD
#property indicator_label1  "MACD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_width1  2

//--- plot Signal Line
#property indicator_label2  "Signal Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_width2  2

//--- plot Histogram
#property indicator_label3  "Histogram"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrDodgerBlue
#property indicator_width3  2

//--- plot Cross Dots
#property indicator_label4  "Cross"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrLime
#property indicator_width4  2

//--- Indicator buffers
double   buffer_macd[];
double   buffer_signal[];
double   buffer_hist[];
double   buffer_cross[];

//--- Input parameters
input bool     useCurrentRes = true;        // Use Current Chart Resolution?
input ENUM_TIMEFRAMES resCustom = PERIOD_H1; // Use Different Timeframe?
input bool     showMacDSignal = true;       // Show MacD & Signal Line?
input bool     showDots = true;             // Show Dots When MacD Crosses Signal Line?
input bool     showHistogram = true;        // Show Histogram?
input bool     macdColorChange = true;      // Change MacD Line Color-Signal Line Cross?
input bool     histColorChange = true;      // MacD Histogram 4 Colors?

input int      fastLength = 12;             // Fast EMA Length
input int      slowLength = 26;             // Slow EMA Length
input int      signalLength = 9;            // Signal Line SMA Length

//--- Handles for indicators
int handle_macd;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- indicator buffers mapping
    SetIndexBuffer(0, buffer_macd, INDICATOR_DATA);
    SetIndexBuffer(1, buffer_signal, INDICATOR_DATA);
    SetIndexBuffer(2, buffer_hist, INDICATOR_DATA);
    SetIndexBuffer(3, buffer_cross, INDICATOR_DATA);
    
    //--- Set arrow for crosses
    PlotIndexSetInteger(3, PLOT_ARROW, 159); // Dot character
    
    //--- Get MACD handle
    handle_macd = iMACD(_Symbol, useCurrentRes ? _Period : resCustom, 
                        fastLength, slowLength, signalLength, PRICE_CLOSE);
    
    if(handle_macd == INVALID_HANDLE)
    {
        Print("Error creating MACD handle");
        return INIT_FAILED;
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    //--- Check if we have enough bars
    if(rates_total < slowLength + signalLength)
        return 0;
    
    //--- Copy MACD values
    double macd_values[];
    double signal_values[];
    double hist_values[];
    
    ArraySetAsSeries(macd_values, true);
    ArraySetAsSeries(signal_values, true);
    ArraySetAsSeries(hist_values, true);
    
    //--- Copy MACD data
    if(CopyBuffer(handle_macd, 0, 0, rates_total, macd_values) <= 0)
    {
        Print("Error copying MACD buffer");
        return prev_calculated;
    }
    
    if(CopyBuffer(handle_macd, 1, 0, rates_total, signal_values) <= 0)
    {
        Print("Error copying Signal buffer");
        return prev_calculated;
    }
    
    if(CopyBuffer(handle_macd, 2, 0, rates_total, hist_values) <= 0)
    {
        Print("Error copying Histogram buffer");
        return prev_calculated;
    }
    
    //--- Set arrays as series
    ArraySetAsSeries(buffer_macd, true);
    ArraySetAsSeries(buffer_signal, true);
    ArraySetAsSeries(buffer_hist, true);
    ArraySetAsSeries(buffer_cross, true);
    
    //--- Main calculation loop
    int limit = prev_calculated == 0 ? rates_total - 1 : prev_calculated - 1;
    
    for(int i = limit; i >= 1; i--)
    {
        // Plot MACD and Signal
        buffer_macd[i] = showMacDSignal ? macd_values[i] : EMPTY_VALUE;
        buffer_signal[i] = showMacDSignal ? signal_values[i] : EMPTY_VALUE;
        buffer_hist[i] = showHistogram ? hist_values[i] : EMPTY_VALUE;
        buffer_cross[i] = EMPTY_VALUE;
        
        // Check for cross between MACD and Signal
        if(showDots && i < rates_total - 1)
        {
            bool macd_above_signal_current = macd_values[i] >= signal_values[i];
            bool macd_above_signal_prev = macd_values[i+1] >= signal_values[i+1];
            
            // Detect cross
            if(macd_above_signal_current != macd_above_signal_prev)
            {
                buffer_cross[i] = signal_values[i];
            }
        }
    }
    
    // Set colors using PLOT_LINE_COLOR with proper syntax
    if(macdColorChange)
    {
        PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrLime);    // MACD line color
        PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrYellow);  // Signal line color
    }
    
    if(histColorChange)
    {
        PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrDodgerBlue); // Histogram color
    }
    
    return rates_total;
}

//+------------------------------------------------------------------+
//| Deinit function                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(handle_macd != INVALID_HANDLE)
        IndicatorRelease(handle_macd);
}

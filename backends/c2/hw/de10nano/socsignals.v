input reset_n,
output [7:0] LED,

             
  output HDMI_I2S0,
  output HDMI_MCLK,
  output HDMI_LRCLK,
  output HDMI_SCLK,  

  output [23:0] HDMI_TX_D,
  output HDMI_TX_VS,
  output HDMI_TX_HS,
  output HDMI_TX_DE,
  output HDMI_TX_CLK,

  input HDMI_TX_INT,
  inout HDMI_I2C_SDA, 
  output HDMI_I2C_SCL,

`ifdef BIGMEM      
	//////////// HPS //////////
	output		    [14:0]		HPS_DDR3_ADDR,
	output		     [2:0]		HPS_DDR3_BA,
	output		          		HPS_DDR3_CAS_N,
	output		          		HPS_DDR3_CK_N,
	output		          		HPS_DDR3_CK_P,
	output		          		HPS_DDR3_CKE,
	output		          		HPS_DDR3_CS_N,
	output		     [3:0]		HPS_DDR3_DM,
	inout 		    [31:0]		HPS_DDR3_DQ,
	inout 		     [3:0]		HPS_DDR3_DQS_N,
	inout 		     [3:0]		HPS_DDR3_DQS_P,
	output		          		HPS_DDR3_ODT,
	output		          		HPS_DDR3_RAS_N,
	output		          		HPS_DDR3_RESET_N,
	input 		          		HPS_DDR3_RZQ,
	output		          		HPS_DDR3_WE_N,


      inout               HPS_I2C0_SCLK,
      inout               HPS_I2C0_SDAT,
      inout               HPS_I2C1_SCLK,
      inout               HPS_I2C1_SDAT,
      output              HPS_SD_CLK,
      inout               HPS_SD_CMD,
      inout    [ 3: 0]    HPS_SD_DATA,
     
      input               HPS_UART_RX,
      output              HPS_UART_TX,
      
      output              HPS_SPIM_CLK,
      input               HPS_SPIM_MISO,
      output              HPS_SPIM_MOSI,
      inout               HPS_SPIM_SS,
`endif      
      

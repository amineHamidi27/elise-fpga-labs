#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/timer.h>
#include <libopencm3/stm32/flash.h> // definitions du timer

void core_clock_setup(void);
static void clock_setup(void);
static void init_gpio(void);
void init_time1 (void);
void dds_slp_clr(void);
void dds_slp_set(void);
void det_clr(void);
void det_set(void);

static void clock_setup(void)
{rcc_periph_clock_enable(RCC_SPI1);
 rcc_periph_clock_enable(RCC_TIM1);
 rcc_periph_clock_enable(RCC_USART1);
 rcc_periph_clock_enable(RCC_GPIOA); // Enable GPIOA clock. 
 rcc_periph_clock_enable(RCC_GPIOB); // Enable GPIOB clock. 
 rcc_periph_clock_enable(RCC_GPIOC); // Enable GPIOC clock. 
 rcc_periph_clock_enable(RCC_ADC1);  //clock ADC
}

static void init_gpio(void)
{gpio_mode_setup(GPIOA, GPIO_MODE_INPUT,GPIO_PUPD_NONE, GPIO4 | GPIO5 | GPIO7 | GPIO15 ); // Enable (MOSI, CK, CS, DDS RST)
 gpio_mode_setup(GPIOA, GPIO_MODE_OUTPUT,GPIO_PUPD_NONE,GPIO11|GPIO12|GPIO13|GPIO14); // DDS sleep
 gpio_mode_setup(GPIOC, GPIO_MODE_OUTPUT,GPIO_PUPD_NONE, GPIO10); // Enable DET
}

void init_time1 (void)
{gpio_set_output_options(GPIOA, GPIO_OTYPE_PP, GPIO_OSPEED_50MHZ, GPIO8 );
 gpio_mode_setup (GPIOA, GPIO_MODE_AF, GPIO_PUPD_NONE, GPIO8);
 gpio_set_af (GPIOA, GPIO_AF1, GPIO8);
 rcc_periph_reset_pulse(RST_TIM1); // timer_reset(TIM1) in older libopencm3
 timer_set_mode (TIM1, TIM_CR1_CKD_CK_INT, TIM_CR1_CMS_EDGE, TIM_CR1_DIR_UP);	
//TIM_CR1_CKD_CK_INT = clock division ratio TIM_CR1_CMS_EDGE=counting mode TIM_CR1_DIR_UP=count direction

// https://github.com/libopencm3/libopencm3/blob/master/lib/stm32/common/timer_common_all.c
  timer_set_oc_mode(TIM1, TIM_OC1, TIM_OCM_PWM2);
  timer_enable_oc_output(TIM1, TIM_OC1);
  timer_enable_break_main_output(TIM1);
  timer_set_oc_value(TIM1, TIM_OC1, 1); // 1 

  timer_set_prescaler (TIM1, 0);
  timer_set_period (TIM1, 1);	 // pourquoi 1 et pas 2 ? il FAUT que period >= OC1
  timer_enable_counter (TIM1);
}

void dds_slp_clr (){gpio_clear(GPIOA, GPIO14);}
void det_set     (){gpio_set  (GPIOC, GPIO10);}

int main(void)
{signed char status=0;
 // char status=0;
 char direction=1;
 volatile long k;
 core_clock_setup();
 clock_setup();
 init_gpio();
 init_time1();
 det_set();
 dds_slp_clr ();
 
 while (1) {
 switch(status)
  {case 0: gpio_clear(GPIOA,GPIO12|GPIO13);gpio_set(GPIOA,GPIO11);break;
   case 1: gpio_clear(GPIOA,GPIO11|GPIO13);gpio_set(GPIOA,GPIO12);break;
   case 2: gpio_clear(GPIOA,GPIO11|GPIO12);gpio_set(GPIOA,GPIO13);break;
  }
 status+=direction;
 if ((status==3) || (status==-1)) {direction=-direction; status+=direction;}
 // if ((status==3) || (status==255)) {direction=-direction; status+=direction;}
 for (k=0;k<1000000;k++) asm("nop");
 }
 return 0;
}

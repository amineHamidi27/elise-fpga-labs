# SRCS=capture_stm32.c stm32_initialisation.c
SRCS=main.c stm32_initialisation.c # syscalls.c
PROJ_NAME=test

# libopencm3 (already built) and serial port of the DDS board
OPENCM3_DIR = /home/amine/Desktop/mic2/tp/libopencm3
PORT ?= /dev/ttyUSB1

CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
CFLAGS = -Wall 
CFLAGS += -g -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 -DSTM32F4
CFLAGS += -I$(OPENCM3_DIR)/include
CFLAGS += --static -nostartfiles -T./stm32f4-discovery.ld
CFLAGS += -L$(OPENCM3_DIR)/lib -lopencm3_stm32f4

all: $(PROJ_NAME).elf
	
$(PROJ_NAME).elf: $(SRCS)
	$(CC) $^ -o $@ $(CFLAGS) 
	$(OBJCOPY) -O ihex $(PROJ_NAME).elf $(PROJ_NAME).hex
	$(OBJCOPY) -O binary $(PROJ_NAME).elf $(PROJ_NAME).bin

clean:
	rm -f *.o $(PROJ_NAME) $(PROJ_NAME).elf $(PROJ_NAME).hex $(PROJ_NAME).bin

flash: $(PROJ_NAME).elf
	stm32flash.sh -w $(PROJ_NAME).bin $(PORT)

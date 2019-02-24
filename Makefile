DEVICE		=	attiny85
CLOCK		=	16500000UL
PROGRAMMER	=	usbasp
TARGET		=	rgbcontroller
FUSES		=	-U lfuse:w:0xe1:m -U hfuse:w:0xdd:m -U efuse:w:0xff:m

VERBOSE 	=	0
DEBUG		=	0

C_SOURCES	=	$(wildcard src/*.c) $(wildcard lib/usbdrv/*.c)
AS_SOURCES	=	$(wildcard src/*.S) $(wildcard lib/usbdrv/*.S)

C_INCLUDES	=	-Iinc -Ilib/usbdrv
#AS_INCLUDES	=	-Iinc -Ilib/usbdrv

MCUFLAGS	=	-mmcu=$(DEVICE) -DF_CPU=$(CLOCK) -DDEBUG_LEVEL=0
CFLAGS		=	-Wall -Os -std=gnu99 $(MCUFLAGS) $(C_INCLUDES)
CFLAGS		+=	-funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums -ffunction-sections -fdata-sections
CFLAGS		+=	-MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"
#ASFLAGS		=	$(MCUFLAGS) $(AS_INCLUDES) -Wall -fdata-sections -ffunction-sections
LDFLAGS		=	$(MCUFLAGS) -Wl,-Map=$(OUTDIR)/$(TARGET).map,--cref -Wl,--gc-sections
PROGFLAGS	=	-B 10

ifeq ($(DEBUG), 1)
CFLAGS		+=	-g
endif

ifeq ($(VERBOSE), 1)
NO_ECHO = 
else
NO_ECHO = @
endif

OBJDIR	= obj
OUTDIR	= bin

CC		= avr-gcc
OBJCOPY	= avr-objcopy
OBJDUMP	= avr-objdump
SIZE	= avr-size
AVRDUDE	= avrdude

OBJECTS	=	$(addprefix $(OBJDIR)/,$(notdir $(C_SOURCES:.c=.c.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))

OBJECTS	+=	$(addprefix $(OBJDIR)/,$(notdir $(AS_SOURCES:.S=.S.o)))
vpath %.S $(sort $(dir $(AS_SOURCES)))

.PHONY: all clean show_fuses burn_fuses flash flash_eeprom

all: $(OUTDIR)/$(TARGET).hex

clean:
	@echo Cleaning files..
	$(NO_ECHO)rm -rf $(OBJDIR) $(OUTDIR)

show_fuses:
	$(NO_ECHO)$(AVRDUDE) -c $(PROGRAMMER) -p $(DEVICE) $(PROGFLAGS) -nv

burn_fuses:
	$(NO_ECHO)$(AVRDUDE) -c $(PROGRAMMER) -p $(DEVICE) $(PROGFLAGS) $(FUSES)

flash: $(OUTDIR)/$(TARGET).hex
	$(NO_ECHO)$(AVRDUDE) -c $(PROGRAMMER) -p $(DEVICE) $(PROGFLAGS) -U flash:w:$<

flash_eeprom: $(OUTDIR)/$(TARGET).eeprom
	$(NO_ECHO)$(AVRDUDE) -c $(PROGRAMMER) -p $(DEVICE) $(PROGFLAGS) -U eeprom:w:$<

-include $(OBJECTS:.o=.d)

$(OBJDIR)/%.c.o: %.c | $(OBJDIR)
	@echo Compiling "$<"
	$(NO_ECHO)$(CC) -c $(CFLAGS) -o $@ $<

$(OBJDIR)/%.S.o: %.S | $(OBJDIR)
	@echo Assembling "$<"
	$(NO_ECHO)$(CC) -x assembler-with-cpp -c $(CFLAGS) $< -o $@

$(OUTDIR)/$(TARGET).elf: $(OBJECTS) | $(OUTDIR)
	@echo Linking "$@"
	$(NO_ECHO)$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(NO_ECHO)$(SIZE) --format=avr --mcu=$(DEVICE) $@

$(OUTDIR)/%.hex: $(OUTDIR)/%.elf | $(OUTDIR)
	@echo Preparing "$@"
	$(NO_ECHO)$(OBJCOPY) -j .text -j .data -O ihex $< $@

$(OUTDIR)/%.eeprom: $(OUTDIR)/%.elf
	$(NO_ECHO)$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O ihex $< $@

$(OBJDIR):
	$(NO_ECHO)mkdir $@

$(OUTDIR):
	$(NO_ECHO)mkdir $@
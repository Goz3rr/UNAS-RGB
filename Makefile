DEVICE		= attiny85
CLOCK		= 1000000UL
PROGRAMMER	= usbasp
TARGET		= rgbcontroller
FUSES		= -U efuse:w:0xff:m -U hfuse:w:0xdf:m -U lfuse:w:0x62:m

C_SOURCES	= $(wildcard src/*.c)
C_INCLUDES	= -Iinc

CFLAGS		=	-Wall -Os -g -std=gnu99 -DF_CPU=$(CLOCK) -mmcu=$(DEVICE) $(C_INCLUDES)
CFLAGS		+=	-funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums -ffunction-sections -fdata-sections
CFLAGS		+=	-MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"
LDFLAGS		=	-mmcu=$(DEVICE) -Wl,-Map=$(OUTDIR)/$(TARGET).map,--cref -Wl,--gc-sections
PROGFLAGS	=	-B 10

VERBOSE = 0
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

OBJECTS	= $(addprefix $(OBJDIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))

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

$(OBJDIR)/%.o: %.c | $(OBJDIR)
	@echo Compiling "$<"
	$(NO_ECHO)$(CC) -c $(CFLAGS) -o $@ $<

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
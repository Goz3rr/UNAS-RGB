#include <stdlib.h>

#include <avr/interrupt.h>
#include <avr/io.h>
#include <avr/wdt.h>
#include <util/delay.h>

#include "usbdrv.h"


#define PIN_VUSB_DM PB3
#define PIN_VUSB_DP PB2


#define PIN_RGB_R   PB1
#define PIN_PWM_R   OCR0B

#define PIN_RGB_G   PB0
#define PIN_PWM_G   OCR0A

#define PIN_RGB_B   PB4
#define PIN_PWM_B   OCR1B

#define USB_LED_SETLED 0

void hadUsbReset() {
    int frameLength, targetLength = (unsigned)(1499 * (double)F_CPU / 10.5e6 + 0.5);
    int bestDeviation = 9999;
    uint8_t trialCal, bestCal = 0, step, region;

    // do a binary search in regions 0-127 and 128-255 to get optimum OSCCAL
    for(region = 0; region <= 1; region++) {
        frameLength = 0;
        trialCal = (region == 0) ? 0 : 128;
        
        for(step = 64; step > 0; step >>= 1) { 
            if(frameLength < targetLength) // true for initial iteration
                trialCal += step; // frequency too low
            else
                trialCal -= step; // frequency too high
                
            OSCCAL = trialCal;
            frameLength = usbMeasureFrameLength();
            
            if(abs(frameLength-targetLength) < bestDeviation) {
                bestCal = trialCal; // new optimum found
                bestDeviation = abs(frameLength -targetLength);
            }
        }
    }

    OSCCAL = bestCal;
}

USB_PUBLIC uint8_t usbFunctionSetup(uint8_t data[8]) {
    usbRequest_t *rq = (void*)data;

    switch(rq->bRequest) {
        case USB_LED_SETLED:
            PIN_PWM_R = 255 - rq->wValue.bytes[0];
            PIN_PWM_G = 255 - rq->wValue.bytes[1];
            PIN_PWM_B = 255 - rq->wIndex.bytes[0];
            break;
    }

    return 0;
}

int main(void) {
    wdt_enable(WDTO_1S);

    // Set up RGB outputs. DM/DP pins reset in the right state.
    DDRB = _BV(PIN_RGB_R) | _BV(PIN_RGB_G) | _BV(PIN_RGB_B);

    // Enable OC0A and OC0B PWM
    TCCR0A |= _BV(COM0A0) | _BV(COM0A1) | _BV(COM0B0) | _BV(COM0B1) | _BV(WGM00) | _BV(WGM01);
    TCCR0B |= _BV(WGM02) | _BV(CS00) | _BV(CS01);

    // Enable OC1B PWM
    GTCCR |= _BV(PWM1B) | _BV(COM1B0) | _BV(COM1B1);
    TCCR1 |= _BV(COM1A0) | _BV(COM1A1) | _BV(CS10) | _BV(CS11) | _BV(CS12);

    // Disable all colors by default
    PIN_PWM_R = 255;
    PIN_PWM_G = 255;
    PIN_PWM_B = 255;

    usbInit();

    wdt_reset();
    usbDeviceDisconnect();
    _delay_ms(300);
    usbDeviceConnect();

    sei();

    while(1) {
        wdt_reset();
        usbPoll();
    }

    return 0;
}
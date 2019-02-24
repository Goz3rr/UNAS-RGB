#include <stdlib.h>

#include <avr/interrupt.h>
#include <avr/io.h>
#include <avr/wdt.h>
#include <util/delay.h>

#include "usbdrv.h"


#define PIN_VUSB_DM PB3
#define PIN_VUSB_DP PB2

#define PIN_RGB_R   PB1
#define PIN_RGB_G   PB0
#define PIN_RGB_B   PB4

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
    uint8_t red, green, blue;

    switch(rq->bRequest) {
        case USB_LED_SETLED:
            red = rq->wValue.bytes[0];
            green = rq->wValue.bytes[1];
            blue = rq->wIndex.bytes[0];

            if(red) {
                PORTB |= _BV(PIN_RGB_R);
            } else {
                PORTB &= ~_BV(PIN_RGB_R);
            }

            if(green) {
                PORTB |= _BV(PIN_RGB_G);
            } else {
                PORTB &= ~_BV(PIN_RGB_G);
            }

            if(blue) {
                PORTB |= _BV(PIN_RGB_B);
            } else {
                PORTB &= ~_BV(PIN_RGB_B);
            }

            break;
    }

    return 0;
}

int main (void) {
    wdt_enable(WDTO_1S);

    // Set up RGB outputs. DM/DP pins reset in the right state.
    DDRB = _BV(PIN_RGB_R) | _BV(PIN_RGB_G) | _BV(PIN_RGB_B);

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
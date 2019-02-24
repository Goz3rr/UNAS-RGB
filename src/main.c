#include <avr/io.h>
#include <util/delay.h>

#define PIN_VUSB_DM PB3
#define PIN_VUSB_DP PB2

#define PIN_RGB_R   PB1
#define PIN_RGB_G   PB0
#define PIN_RGB_B   PB4

int main (void)
{
    // Set RGB pins as output
    DDRB = _BV(PIN_RGB_R) | _BV(PIN_RGB_G) | _BV(PIN_RGB_B);

    while(1)
    {
        PORTB = _BV(PIN_RGB_R);
        _delay_ms(333);

        PORTB = _BV(PIN_RGB_G);
        _delay_ms(333);

        PORTB = _BV(PIN_RGB_B);
        _delay_ms(333);
    }

    return 1;
}
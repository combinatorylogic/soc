int32* _intptr(uint32 ptr);

void _leds(int32 v)
{
        int32 *channel = _intptr(65540);
        *channel = v;
}

void bootentry()
{
        int32 i = 0;
        do {
                _leds(i);
                i++;
                if (i>5) i = 0;
        } while(1);
}

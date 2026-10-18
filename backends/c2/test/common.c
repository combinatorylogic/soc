void _halt()
{
        int32 *channel = _intptr(65541);
        *channel = 1;
}

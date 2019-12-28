# Uploading

 cat /dev/ttyACM0 &> /dev/null &
 # ... wait a bit ...
 stty -F /dev/ttyACM0 raw
 cat whatever.bin > /dev/ttyACM0


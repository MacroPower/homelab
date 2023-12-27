doppler run -p talhelper -c main -- talhelper validate talconfig

doppler run -p talhelper -c main -- talhelper genconfig --no-gitignore

eval $(doppler run -p talhelper -c main -- talhelper gencommand apply)

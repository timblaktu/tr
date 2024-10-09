# Systemd Units

The basic startup sequence below is implemented with systemd units:

1. DEP systemd service
    1. provided by dep release package: 
        1. `dante_package/dep.service`, which invokes and references other provided scripts.
1. USB audio driver
    1. usb audio-->dep
1. jackd -d alsa -p 256
    1. buffersize is 256 to AWE's inputs
    1. may be additional buffering
1. DEPW-jack -m1 -v1 -z20 -n4 &
    1. handles jack connections
1. RTAudio-jack
    1. Listen on Tuning Socket, port 15002
1. Analog audio routing:
    1. jack_connect system: capture_1 DepJack:playback_1
    1. jack_connect system: capture_2 DepJack:playback_2

## System(d) Diagram




## References
    1. https://xilica.atlassian.net/browse/TES-40?focusedCommentId=16649

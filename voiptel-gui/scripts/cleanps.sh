#!/bin/sh 

kill -9 `ps auwwwx | grep rotatecdr | awk '{print $1}' | xargs`
kill -9 `ps auwwwx | grep archive | awk '{print $1}' | xargs`

return 0


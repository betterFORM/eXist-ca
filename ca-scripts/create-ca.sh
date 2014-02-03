#!/bin/sh 
echo hello world  >/tmp/junktest
pwd >>/tmp/junktest
echo $* >>/tmp/junktest

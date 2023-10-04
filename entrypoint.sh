#!/bin/sh
service rsyslog start
service postfix start
/bin/ping localhost

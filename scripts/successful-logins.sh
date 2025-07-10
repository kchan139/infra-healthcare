#!/bin/bash
set -e

last
grep 'Accepted' /var/log/auth.log

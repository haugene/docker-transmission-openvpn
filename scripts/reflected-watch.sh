#!/bin/bash
inotifywait -q -r -m $1 --format %w%f -e create |
while read file; do
  if echo "$file" | grep -iq "\.torrent" ; then
    canonfile=$(readlink -f "$file")
    relpath=$(realpath --relative-to="$REFLECTED_WATCH_DIR" "$canonfile")
    dir=$(dirname "$relpath")

    if echo `basename "$file"` | grep -iq "^\._"; then
      echo
    else
      counter=0
      while : ; do
        if [ "$counter" -gt "10" ]; then break; fi
        sleep 0.5s
        a=`stat -c%s "$canonfile"`
        if [ "$?" -ne "0" ]; then break; fi
        echo "$canonfile" stat: "$a"
        if [ "$a" -ne "0" ]; then break; fi
        counter=`expr "$counter" + 1`
      done
      while : ; do
        a=`stat -c%s "$canonfile"`
        if [ "$?" -ne "0" ]; then break; fi
        sleep 5s
        if [ "$a" -eq `stat -c%s "$canonfile"` ]; then break; fi
      done
      a=`stat -c%s "$canonfile"`
      if [ "$?" -eq "0" ]; then
        transmission-remote -a "$canonfile" -w "$TRANSMISSION_DOWNLOAD_DIR/$dir";
              # workaround for --trash-torrent not working
        [ "$TRANSMISSION_TRASH_ORIGINAL_TORRENT_FILES" = "true" ] && rm -f "$canonfile"
      fi
    fi
  fi
done

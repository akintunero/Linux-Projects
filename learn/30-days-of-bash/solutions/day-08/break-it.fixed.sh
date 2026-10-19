#!/usr/bin/env bash
# Fixed: append with >>, redirect stdout before stderr, never read and write the same file.
printf 'b\na\n' > data.txt

echo "start" > log.txt
ls /nonexistent >> log.txt 2>&1

ls /nonexistent > errors.txt 2>&1

sort -o data.txt data.txt        # -o is safe even when input and output are the same file

echo "log.txt: $(wc -l < log.txt) line(s)"
echo "errors.txt: $(wc -c < errors.txt) bytes"
echo "data.txt: $(wc -c < data.txt) bytes"

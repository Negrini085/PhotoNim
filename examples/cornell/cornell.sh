nim c -d:release examples/cornell/main.nim
parallel -j 8 --eta './examples/cornell/main {1} {2}' ::: $(seq 1 4) ::: $(seq 1 4)
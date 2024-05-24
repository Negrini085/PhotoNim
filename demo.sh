# Run the parallel demo animation
seq 118 359 | parallel -j 4 --eta 'angleNNN=$(printf "%03d" {1}); ./PhotoNim demo persp demo/img${angleNNN}.png --w=400 --h=400 --angle={1}'
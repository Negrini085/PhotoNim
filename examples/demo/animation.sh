# Run the parallel demo animation
seq 4 8 | parallel -j 4 --eta '
  angleNNN=$(printf "%03d" {1});
  ./PhotoNim demo persp examples/demo/frames/img${angleNNN}.png --w=400 --h=400 --angle={1}
'

ffmpeg -framerate 30 -i examples/demo/frames/img%03d.png -c:v libx264 -pix_fmt yuv420p examples/demo/demo.mp4
rm -r examples/demo/frames/
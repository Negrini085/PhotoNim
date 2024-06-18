# Run the parallel demo animation
seq 0 360 | parallel -j 8 --eta '
  angleNNN=$(printf "%03d" {1});
  ./PhotoNim demo persp Flat examples/demo/frames/img${angleNNN}.png --w=400 --h=400 --angle={1}
'

ffmpeg -framerate 30 -i examples/demo/frames/img%03d.png -c:v libx264 -pix_fmt yuv420p examples/demo/demo.mp4

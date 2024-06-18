# Run the parallel demo animation
seq 0 360 | parallel -j 8 --eta '
  angleNNN=$(printf "%03d" {1});
  ./PhotoNim earth examples/earth/frames/img${angleNNN}.png --w=600 --h=600 --angle={1}
'

ffmpeg -framerate 30 -i examples/earth/frames/img%03d.png -c:v libx264 -pix_fmt yuv420p examples/earth/earth.mp4
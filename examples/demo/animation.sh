# Run the parallel demo animation
seq 203 216 | parallel -j 8 --eta '
  angleNNN=$(printf "%03d" {1}); 
  nimble --silent demo persp Path {1} examples/demo/frames/img${angleNNN}.png
'

ffmpeg -framerate 30 -i examples/demo/frames/img%03d.png -c:v libx264 -pix_fmt yuv420p examples/demo/demo.mp4 -y
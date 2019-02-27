import os
import random

image_dir = '/directory/to/image/folder'  # path to the background image folder
install_dir = '/opt/cool-cyber-term/'     # leave like this if you follow the install instructions
scale_perc = 0.18                         # downscale factor of background image (0.18 => 18% of original size) is used for pixellation
opacity_perc = 0.7                        # opacity of the background image, so you still see your desktop 

scale_perc = int(scale_perc*100)
if image_dir[-1] != '/':
  image_dir += '/'
if install_dir[-1] != '/':
  install_dir += '/'
files=os.listdir(image_dir)
if len(files) > 0:
  random.shuffle(files)
  os.system('convert -resize '+str(scale_perc)+'% '+image_dir+files[0]+' '+install_dir+'background.png')
  os.system('convert '+install_dir+'background.png -alpha set -background none -channel A -evaluate multiply '+str(round(opacity_perc,2))+' +channel '+install_dir+'background.png')

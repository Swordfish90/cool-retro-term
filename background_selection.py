import os
import random

image_dir = '/home/bratwolf/Pictures/cyberpunk/wallhaven_alpha_wallhaven_cc_tag_376'
install_dir = '/opt/cool-retro-term/'
scale_perc = 0.18
opacity_perc = 0.7

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
  copyfile(image_dir+files[0], '/opt/cool-retro-term/background.jpg')

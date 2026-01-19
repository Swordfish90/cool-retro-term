3270font: A font for the nostalgic
==================================

![Travis-CI](https://api.travis-ci.org/rbanffy/3270font.svg)

![Screenshot](https://raw.githubusercontent.com/wiki/rbanffy/3270font/emacs.png)

![Sample](https://raw.githubusercontent.com/wiki/rbanffy/3270font/3270Medium_sample.png)

A little bit of history
-----------------------

This font is derived from the x3270 font, which, in turn, was
translated from the one in Georgia Tech's 3270tool, which was itself
hand-copied from a 3270 series terminal. I built it because I felt
terminals deserve to be pretty. The .sfd font file contains a x3270
bitmap font that was used for guidance.

![Using with the cool-old-tern (now cool-retro-term) terminal program](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/cool-retro-term.png)

Getting it
----------

If you are running Debian or Ubuntu and you don't want to mess with
building your font files, you can simply `apt-get install fonts-3270`
(It's available from the Debian
(https://packages.debian.org/sid/fonts/fonts-3270) and Ubuntu
(http://packages.ubuntu.com/zesty/fonts-3270) package repos at
https://packages.debian.org/sid/fonts/fonts-3270 and
http://packages.ubuntu.com/xenial/fonts/fonts-3270, although the
packaged version may not be the latest version, but it's good enough for
most purposes. For those who don't have the luxury of a proper
system-managed package, Adobe Type 1, TTF, OTF and WOFF versions are
available for download on
http://s3.amazonaws.com/3270font/3270_fonts_4cfe95c.zip (although this
URL may not always reflect the latest version).

![ASCII is so 60's](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/cyrillic.png)

The format
----------

The "source" file is edited using FontForge. You'll need it if you want
to generate fonts for your platform. On most civilized operating
systems, you can simply `apt-get install fontforge`, `yum install
fontforge` or even `port install fontforge`. On others, you may need to
grab your copy from http://fontforge.org/. I encourage you to drop by
and read the tutorials.

![Powerline-shell compatible!](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/powerline.png)

![Using it on OSX (don't forget to turn antialiasing on)](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/osx_terminal.png)

If you are running Windows, you'll probably need something like
Cygwin, but, in the end, the font works correctly (with some very
minor hinting issues).

![Works on Windows](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/windows_7.png)

Generating usable font files
----------------------------

The easiest way to generate the font files your computer can use is to
run `make all` (if you are running Ubuntu or Debian, `make install` will
install them too). Using `make help` will offer a handy list of options.

The script `generate_derived.pe` calls FontForge and generates
PostScript, OTF, TTF and WOFF versions of the base font, as well as a
slightly more condensed .sfd file with the base font narrowed to 488
units, with no glyph rescaling (or cropping - we need to fix that) and
its corresponding PostScript, TTF, OTF and WOFF versions.

![For your favorite editor](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/symbols.png)

Contributing
------------

I fear GitHub's pull-request mechanism may not be very
FontForge-friendly. If you want to contribute (there are a lot of
missing glyphs, such as most non-latin alphabets which most likely were
never built into 3270 terminals), the best workflow would probably be to
add the encoding slots (if needed), add/make the changes, remove the
unchanged glyphs and save it as a different file. If, in doubt, get in
touch and we will figure out how to do it right.

In order to generate the sample image and the grids for FontForge,
you'll need a Python 3 environment with PIL or pillow installed. The
requirements.txt file lists everything you need to do it.

Known problems
--------------

Not all symbols in the 3270 charset have Unicode counterparts. When
possible, they are duplicated in the Unicode space. The 3270-only
symbols are at the end of the font, along with some glyphs useful for
building others.

Please refer to http://x3270.bgp.nu/Charset.html for a complete map.

Future improvements
-------------------

A grid generator is provided for producing various grid sizes for the
font. Those grids are not used yet, but they are intended to be used to
align font features to provide better rendering at common font size
choices. The captures below exemplify these choices:

![x3270 with 32 pixel font (used as bitmap template for the font)](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/measurements_x3270_32.png)

![x3270 with 20 pixel font](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/measurements_x3270_20.png)

![Gnome Terminal on Ubuntu 17.10](
https://raw.githubusercontent.com/wiki/rbanffy/3270font/measurements_gnome_terminal.png)

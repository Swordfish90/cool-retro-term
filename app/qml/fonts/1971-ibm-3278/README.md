3270font: A font for the nostalgic
==================================

![Travis-CI](https://api.travis-ci.org/rbanffy/3270font.svg)

![Screenshot](https://raw.githubusercontent.com/wiki/rbanffy/3270font/emacs.png)

A little bit of history
-----------------------

This font is derived from the x3270 font, which, in turn, was translated
from the one in Georgia Tech's 3270tool, which was itself hand-copied
from a 3270 terminal. I built it because I felt terminals deserve to be
pretty. The .sfd font file contains a x3270 bitmap font that was used
for guidance.

![Using with the cool-old-tern (now cool-retro-term) terminal program]
(https://raw.githubusercontent.com/wiki/rbanffy/3270font/cool-retro-term.png)

Getting it
----------

If you are running Debian or Ubuntu and you don't want to mess with
building your font files, you can simply `apt-get install
fonts-3270`. It'll most likely not the latest version, with all new
glyphs I add from time to time, but it's good enough for most
purposes. For those who don't have the luxury of a proper system-managed
package, Adobe Type 1, TTF, OTF and WOFF versions are available for
download on http://s3.amazonaws.com/rbanffy/3270_fonts_14e43fc.zip
(although this URL may not always reflect the latest version).

The format
----------

The "source" file is edited using FontForge. You'll need it if you want
to generate fonts for your platform. On most civilized operating
systems, you can simply `apt-get install fontforge`, `yum install
fontforge` or even `port install fontforge`. On others, you may need to
grab your copy from http://fontforge.org/. I encourage you to drop by
and read the tutorials.

![Powerline-shell compatible!]
(https://raw.githubusercontent.com/wiki/rbanffy/3270font/powerline.png)

![Using it on OSX (don't forget to turn antialiasing on)]
(https://raw.githubusercontent.com/wiki/rbanffy/3270font/osx_terminal.png)

If you are running Windows, you'll probably need something like
Cygwin, but, in the end, the font works correctly (with some very
minor hinting issues).

![Works on Windows]
(https://raw.githubusercontent.com/wiki/rbanffy/3270font/windows_7.png)

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

Contributing
------------

I fear GitHub's pull-request mechanism may not be very
FontForge-friendly. If you want to contribute (there are a lot of
missing glyphs, such as the APL set and most non-latin alphabets which
most likely were never built into 3270 terminals), the best workflow
would be to make add the encoding slots (if needed), add/make the
changes, reencode it in "Unicode, Full", compact it and validate
it. Check if the `git diff` command gives out something sensible (does
not change things you didn't intend to) and make a pull request. If, in
doubt, get in touch and we will figure out how to do it right.

Preserving history
------------------

I regard the evolution of electronic computing a very important part of
our civilization's history. Consider donating to entities that help
preserve it, such as the Computer History Museum
(http://www.computerhistory.org/), the IT History Society
(http://ithistory.org/) and many others around the world. If you have a
historically significant piece of technology in your closet or garage,
consider contacting a local technology or industrial-design-oriented
museum for advice.

Known problems
--------------

Not all symbols in the 3270 charset have Unicode counterparts. When
possible, they are duplicated in the Unicode space. The 3270-only
symbols are at the end of the font.

Please refer to http://x3270.bgp.nu/Charset.html for a complete map.

cool-old-term is a terminal emulator which tries to mimic the look and feel of the old cathode tube screens.
It has been designed to be eye-candy, customizable, and reasonably lightweight.

It now uses the konsole engine which is powerful and stable.

To build and launch it (Qt5.2 are required):

	git clone https://github.com/Swordifish90/cool-old-term.git
	cd cool-old-term
        cd konsole-qml-plugin	
        qmake && make && make install
        cd ..
	./cool-old-term

This is still an eary release, but you are free to test it and tell me what do you think.

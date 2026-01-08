QT += qml quick widgets sql quickcontrols2
TARGET = cool-retro-term

# TODO: When migrating to CMake, use KDSingleApplication's CMakeLists.txt instead of these manual sources.
INCLUDEPATH += $$PWD/../KDSingleApplication/src
HEADERS += \
    $$PWD/../KDSingleApplication/src/kdsingleapplication.h \
    $$PWD/../KDSingleApplication/src/kdsingleapplication_lib.h \
    $$PWD/../KDSingleApplication/src/kdsingleapplication_localsocket_p.h
SOURCES += \
    $$PWD/../KDSingleApplication/src/kdsingleapplication.cpp \
    $$PWD/../KDSingleApplication/src/kdsingleapplication_localsocket.cpp
DEFINES += KDSINGLEAPPLICATION_STATIC_BUILD

DESTDIR = $$OUT_PWD/../

HEADERS += \
    fileio.h \
    monospacefontmanager.h

SOURCES += main.cpp \
    fileio.cpp \
    monospacefontmanager.cpp

macx:ICON = icons/crt.icns

RESOURCES += qml/resources.qrc

# Shader compilation (Qt Shader Baker)
QSB_BIN = $$[QT_HOST_BINS]/qsb
isEmpty(QSB_BIN): QSB_BIN = $$[QT_INSTALL_BINS]/qsb

SHADERS_DIR = $${_PRO_FILE_PWD_}/shaders
SHADERS += $$files($$SHADERS_DIR/*.frag) $$files($$SHADERS_DIR/*.vert)
SHADERS -= $$SHADERS_DIR/terminal_dynamic.frag
SHADERS -= $$SHADERS_DIR/terminal_static.frag
SHADERS -= $$SHADERS_DIR/passthrough.vert

qsb.input = SHADERS
qsb.output = ../../app/shaders/${QMAKE_FILE_NAME}.qsb
qsb.commands = $$QSB_BIN --glsl \"100 es,120,150\" --hlsl 50 --msl 12 --qt6 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_IN}
qsb.clean = $$qsb.output
qsb.name = qsb ${QMAKE_FILE_IN}
qsb.variable_out = QSB_FILES
QMAKE_EXTRA_COMPILERS += qsb
PRE_TARGETDEPS += $$QSB_FILES
OTHER_FILES += $$SHADERS $$QSB_FILES

DYNAMIC_SHADER = $$SHADERS_DIR/terminal_dynamic.frag
STATIC_SHADER = $$SHADERS_DIR/terminal_static.frag

RASTER_MODES = 0 1 2 3 4
BINARY_FLAGS = 0 1
VARIANT_SHADER_DIR = $$relative_path($$PWD/shaders, $$OUT_PWD)
VARIANT_OUTPUTS =

for(raster_mode, RASTER_MODES) {
    for(burn_in, BINARY_FLAGS) {
        for(display_frame, BINARY_FLAGS) {
            for(chroma_on, BINARY_FLAGS) {
                dynamic_variant = terminal_dynamic_raster$${raster_mode}_burn$${burn_in}_frame$${display_frame}_chroma$${chroma_on}
                dynamic_output = $${VARIANT_SHADER_DIR}/$${dynamic_variant}.frag.qsb
                dynamic_target = shader_variant_$${dynamic_variant}
                $${dynamic_target}.target = $${dynamic_output}
                $${dynamic_target}.depends = $$DYNAMIC_SHADER
                $${dynamic_target}.commands = $$QSB_BIN --glsl \"100 es,120,150\" --hlsl 50 --msl 12 --qt6 -DCRT_RASTER_MODE=$${raster_mode} -DCRT_BURN_IN=$${burn_in} -DCRT_DISPLAY_FRAME=$${display_frame} -DCRT_CHROMA=$${chroma_on} -o $${dynamic_output} $$DYNAMIC_SHADER
                QMAKE_EXTRA_TARGETS += $${dynamic_target}
                VARIANT_OUTPUTS += $${dynamic_output}
            }
        }
    }
}

for(rgb_shift, BINARY_FLAGS) {
    for(bloom_on, BINARY_FLAGS) {
        for(curve_on, BINARY_FLAGS) {
            for(shine_on, BINARY_FLAGS) {
                static_variant = terminal_static_rgb$${rgb_shift}_bloom$${bloom_on}_curve$${curve_on}_shine$${shine_on}
                static_output = $${VARIANT_SHADER_DIR}/$${static_variant}.frag.qsb
                static_target = shader_variant_$${static_variant}
                $${static_target}.target = $${static_output}
                $${static_target}.depends = $$STATIC_SHADER
                $${static_target}.commands = $$QSB_BIN --glsl \"100 es,120,150\" --hlsl 50 --msl 12 --qt6 -DCRT_RGB_SHIFT=$${rgb_shift} -DCRT_BLOOM=$${bloom_on} -DCRT_CURVATURE=$${curve_on} -DCRT_FRAME_SHININESS=$${shine_on} -o $${static_output} $$STATIC_SHADER
                QMAKE_EXTRA_TARGETS += $${static_target}
                VARIANT_OUTPUTS += $${static_output}
            }
        }
    }
}
PRE_TARGETDEPS += $${VARIANT_OUTPUTS}

#########################################
##              INTALLS
#########################################

target.path += /usr/bin/

INSTALLS += target

# Install icons
unix {
    icon32.files = icons/32x32/cool-retro-term.png
    icon32.path = /usr/share/icons/hicolor/32x32/apps
    icon64.files = icons/64x64/cool-retro-term.png
    icon64.path = /usr/share/icons/hicolor/64x64/apps
    icon128.files = icons/128x128/cool-retro-term.png
    icon128.path = /usr/share/icons/hicolor/128x128/apps
    icon256.files = icons/256x256/cool-retro-term.png
    icon256.path = /usr/share/icons/hicolor/256x256/apps

    INSTALLS += icon32 icon64 icon128 icon256
}

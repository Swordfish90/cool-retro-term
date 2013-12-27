#include "register_qml_types.h"

#include <QtQml>

#include "terminal_screen.h"
#include "object_destruct_item.h"
#include "screen.h"
#include "text.h"
#include "cursor.h"
#include "mono_text.h"

void register_qml_types()
{
    qmlRegisterType<TerminalScreen>("org.yat", 1, 0, "TerminalScreen");
    qmlRegisterType<ObjectDestructItem>("org.yat", 1, 0, "ObjectDestructItem");
    qmlRegisterType<MonoText>("org.yat", 1, 0, "MonoText");
    qmlRegisterType<Screen>();
    qmlRegisterType<Text>();
    qmlRegisterType<Cursor>();
}

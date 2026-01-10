#include <QtTest>

#include "tst_konsole_wcwidth.h"
#include "tst_fileio.h"
#include "tst_character.h"

int main(int argc, char *argv[])
{
    int status = 0;

    // Run all test classes
    {
        KonsoleWcwidthTest test;
        status |= QTest::qExec(&test, argc, argv);
    }
    {
        FileIOTest test;
        status |= QTest::qExec(&test, argc, argv);
    }
    {
        CharacterTest test;
        status |= QTest::qExec(&test, argc, argv);
    }

    return status;
}

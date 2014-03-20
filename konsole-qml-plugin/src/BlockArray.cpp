/*
    This file is part of Konsole, an X terminal.
    Copyright (C) 2000 by Stephan Kulow <coolo@kde.org>

    Rewritten for QT4 by e_k <e_k at users.sourceforge.net>, Copyright (C)2008

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301  USA.

*/

// Own
#include "BlockArray.h"

#include <QtCore>

// System
#include <assert.h>
#include <sys/mman.h>
#include <sys/param.h>
#include <unistd.h>
#include <stdio.h>


static int blocksize = 0;

BlockArray::BlockArray()
        : size(0),
        current(size_t(-1)),
        index(size_t(-1)),
        lastmap(0),
        lastmap_index(size_t(-1)),
        lastblock(0), ion(-1),
        length(0)
{
    // lastmap_index = index = current = size_t(-1);
    if (blocksize == 0) {
        blocksize = ((sizeof(Block) / getpagesize()) + 1) * getpagesize();
    }

}

BlockArray::~BlockArray()
{
    setHistorySize(0);
    assert(!lastblock);
}

size_t BlockArray::append(Block * block)
{
    if (!size) {
        return size_t(-1);
    }

    ++current;
    if (current >= size) {
        current = 0;
    }

    int rc;
    rc = lseek(ion, current * blocksize, SEEK_SET);
    if (rc < 0) {
        perror("HistoryBuffer::add.seek");
        setHistorySize(0);
        return size_t(-1);
    }
    rc = write(ion, block, blocksize);
    if (rc < 0) {
        perror("HistoryBuffer::add.write");
        setHistorySize(0);
        return size_t(-1);
    }

    length++;
    if (length > size) {
        length = size;
    }

    ++index;

    delete block;
    return current;
}

size_t BlockArray::newBlock()
{
    if (!size) {
        return size_t(-1);
    }
    append(lastblock);

    lastblock = new Block();
    return index + 1;
}

Block * BlockArray::lastBlock() const
{
    return lastblock;
}

bool BlockArray::has(size_t i) const
{
    if (i == index + 1) {
        return true;
    }

    if (i > index) {
        return false;
    }
    if (index - i >= length) {
        return false;
    }
    return true;
}

const Block * BlockArray::at(size_t i)
{
    if (i == index + 1) {
        return lastblock;
    }

    if (i == lastmap_index) {
        return lastmap;
    }

    if (i > index) {
        qDebug() << "BlockArray::at() i > index\n";
        return 0;
    }

//     if (index - i >= length) {
//         kDebug(1211) << "BlockArray::at() index - i >= length\n";
//         return 0;
//     }

    size_t j = i; // (current - (index - i) + (index/size+1)*size) % size ;

    assert(j < size);
    unmap();

    Block * block = (Block *)mmap(0, blocksize, PROT_READ, MAP_PRIVATE, ion, j * blocksize);

    if (block == (Block *)-1) {
        perror("mmap");
        return 0;
    }

    lastmap = block;
    lastmap_index = i;

    return block;
}

void BlockArray::unmap()
{
    if (lastmap) {
        int res = munmap((char *)lastmap, blocksize);
        if (res < 0) {
            perror("munmap");
        }
    }
    lastmap = 0;
    lastmap_index = size_t(-1);
}

bool BlockArray::setSize(size_t newsize)
{
    return setHistorySize(newsize * 1024 / blocksize);
}

bool BlockArray::setHistorySize(size_t newsize)
{
//    kDebug(1211) << "setHistorySize " << size << " " << newsize;

    if (size == newsize) {
        return false;
    }

    unmap();

    if (!newsize) {
        delete lastblock;
        lastblock = 0;
        if (ion >= 0) {
            close(ion);
        }
        ion = -1;
        current = size_t(-1);
        return true;
    }

    if (!size) {
        FILE * tmp = tmpfile();
        if (!tmp) {
            perror("konsole: cannot open temp file.\n");
        } else {
            ion = dup(fileno(tmp));
            if (ion<0) {
                perror("konsole: cannot dup temp file.\n");
                fclose(tmp);
            }
        }
        if (ion < 0) {
            return false;
        }

        assert(!lastblock);

        lastblock = new Block();
        size = newsize;
        return false;
    }

    if (newsize > size) {
        increaseBuffer();
        size = newsize;
        return false;
    } else {
        decreaseBuffer(newsize);
        ftruncate(ion, length*blocksize);
        size = newsize;

        return true;
    }
}

void moveBlock(FILE * fion, int cursor, int newpos, char * buffer2)
{
    int res = fseek(fion, cursor * blocksize, SEEK_SET);
    if (res) {
        perror("fseek");
    }
    res = fread(buffer2, blocksize, 1, fion);
    if (res != 1) {
        perror("fread");
    }

    res = fseek(fion, newpos * blocksize, SEEK_SET);
    if (res) {
        perror("fseek");
    }
    res = fwrite(buffer2, blocksize, 1, fion);
    if (res != 1) {
        perror("fwrite");
    }
    //    printf("moving block %d to %d\n", cursor, newpos);
}

void BlockArray::decreaseBuffer(size_t newsize)
{
    if (index < newsize) { // still fits in whole
        return;
    }

    int offset = (current - (newsize - 1) + size) % size;

    if (!offset) {
        return;
    }

    // The Block constructor could do somthing in future...
    char * buffer1 = new char[blocksize];

    FILE * fion = fdopen(dup(ion), "w+b");
    if (!fion) {
        delete [] buffer1;
        perror("fdopen/dup");
        return;
    }

    int firstblock;
    if (current <= newsize) {
        firstblock = current + 1;
    } else {
        firstblock = 0;
    }

    size_t oldpos;
    for (size_t i = 0, cursor=firstblock; i < newsize; i++) {
        oldpos = (size + cursor + offset) % size;
        moveBlock(fion, oldpos, cursor, buffer1);
        if (oldpos < newsize) {
            cursor = oldpos;
        } else {
            cursor++;
        }
    }

    current = newsize - 1;
    length = newsize;

    delete [] buffer1;

    fclose(fion);

}

void BlockArray::increaseBuffer()
{
    if (index < size) { // not even wrapped once
        return;
    }

    int offset = (current + size + 1) % size;
    if (!offset) { // no moving needed
        return;
    }

    // The Block constructor could do somthing in future...
    char * buffer1 = new char[blocksize];
    char * buffer2 = new char[blocksize];

    int runs = 1;
    int bpr = size; // blocks per run

    if (size % offset == 0) {
        bpr = size / offset;
        runs = offset;
    }

    FILE * fion = fdopen(dup(ion), "w+b");
    if (!fion) {
        perror("fdopen/dup");
        delete [] buffer1;
        delete [] buffer2;
        return;
    }

    int res;
    for (int i = 0; i < runs; i++) {
        // free one block in chain
        int firstblock = (offset + i) % size;
        res = fseek(fion, firstblock * blocksize, SEEK_SET);
        if (res) {
            perror("fseek");
        }
        res = fread(buffer1, blocksize, 1, fion);
        if (res != 1) {
            perror("fread");
        }
        int newpos = 0;
        for (int j = 1, cursor=firstblock; j < bpr; j++) {
            cursor = (cursor + offset) % size;
            newpos = (cursor - offset + size) % size;
            moveBlock(fion, cursor, newpos, buffer2);
        }
        res = fseek(fion, i * blocksize, SEEK_SET);
        if (res) {
            perror("fseek");
        }
        res = fwrite(buffer1, blocksize, 1, fion);
        if (res != 1) {
            perror("fwrite");
        }
    }
    current = size - 1;
    length = size;

    delete [] buffer1;
    delete [] buffer2;

    fclose(fion);

}


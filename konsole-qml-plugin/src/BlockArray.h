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

#ifndef BLOCKARRAY_H
#define BLOCKARRAY_H

#include <unistd.h>

//#error Do not use in KDE 2.1

#define BlockSize (1 << 12)
#define ENTRIES   ((BlockSize - sizeof(size_t) ) / sizeof(unsigned char))

struct Block {
    Block() {
        size = 0;
    }
    unsigned char data[ENTRIES];
    size_t size;
};

// ///////////////////////////////////////////////////////

class BlockArray {
public:
    /**
    * Creates a history file for holding
    * maximal size blocks. If more blocks
    * are requested, then it drops earlier
    * added ones.
    */
    BlockArray();

    /// destructor
    ~BlockArray();

    /**
    * adds the Block at the end of history.
    * This may drop other blocks.
    *
    * The ownership on the block is transfered.
    * An unique index number is returned for accessing
    * it later (if not yet dropped then)
    *
    * Note, that the block may be dropped completely
    * if history is turned off.
    */
    size_t append(Block * block);

    /**
    * gets the block at the index. Function may return
    * 0 if the block isn't available any more.
    *
    * The returned block is strictly readonly as only
    * maped in memory - and will be invalid on the next
    * operation on this class.
    */
    const Block * at(size_t index);

    /**
    * reorders blocks as needed. If newsize is null,
    * the history is emptied completely. The indices
    * returned on append won't change their semantic,
    * but they may not be valid after this call.
    */
    bool setHistorySize(size_t newsize);

    size_t newBlock();

    Block * lastBlock() const;

    /**
    * Convenient function to set the size in KBytes
    * instead of blocks
    */
    bool setSize(size_t newsize);

    size_t len() const {
        return length;
    }

    bool has(size_t index) const;

    size_t getCurrent() const {
        return current;
    }

private:
    void unmap();
    void increaseBuffer();
    void decreaseBuffer(size_t newsize);

    size_t size;
    // current always shows to the last inserted block
    size_t current;
    size_t index;

    Block * lastmap;
    size_t lastmap_index;
    Block * lastblock;

    int ion;
    size_t length;

};

#endif

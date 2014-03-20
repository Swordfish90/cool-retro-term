/*
    This file is part of Konsole, an X terminal.
    Copyright 1997,1998 by Lars Doelle <lars.doelle@on-line.de>

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

#ifndef TEHISTORY_H
#define TEHISTORY_H

// Qt
#include <QtCore/QBitRef>
#include <QtCore/QHash>
#include <QtCore/QVector>
#include <QTemporaryFile>

// KDE
//#include <ktemporaryfile.h>

// Konsole
#include "BlockArray.h"
#include "Character.h"

// map
#include <sys/mman.h>


#if 1
/*
   An extendable tmpfile(1) based buffer.
*/

class HistoryFile
{
public:
  HistoryFile();
  virtual ~HistoryFile();

  virtual void add(const unsigned char* bytes, int len);
  virtual void get(unsigned char* bytes, int len, int loc);
  virtual int  len();

  //mmaps the file in read-only mode
  void map();
  //un-mmaps the file
  void unmap();
  //returns true if the file is mmap'ed
  bool isMapped();


private:
  int  ion;
  int  length;
  QTemporaryFile tmpFile;

  //pointer to start of mmap'ed file data, or 0 if the file is not mmap'ed
  char* fileMap;
 
  //incremented whenver 'add' is called and decremented whenever
  //'get' is called.
  //this is used to detect when a large number of lines are being read and processed from the history
  //and automatically mmap the file for better performance (saves the overhead of many lseek-read calls).
  int readWriteBalance;

  //when readWriteBalance goes below this threshold, the file will be mmap'ed automatically
  static const int MAP_THRESHOLD = -1000;
};
#endif

//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
// Abstract base class for file and buffer versions
//////////////////////////////////////////////////////////////////////
class HistoryType;

class HistoryScroll
{
public:
  HistoryScroll(HistoryType*);
 virtual ~HistoryScroll();

  virtual bool hasScroll();

  // access to history
  virtual int  getLines() = 0;
  virtual int  getLineLen(int lineno) = 0;
  virtual void getCells(int lineno, int colno, int count, Character res[]) = 0;
  virtual bool isWrappedLine(int lineno) = 0;

  // backward compatibility (obsolete)
  Character   getCell(int lineno, int colno) { Character res; getCells(lineno,colno,1,&res); return res; }

  // adding lines.
  virtual void addCells(const Character a[], int count) = 0;
  // convenience method - this is virtual so that subclasses can take advantage
  // of QVector's implicit copying
  virtual void addCellsVector(const QVector<Character>& cells)
  {
    addCells(cells.data(),cells.size());
  }

  virtual void addLine(bool previousWrapped=false) = 0;

  //
  // FIXME:  Passing around constant references to HistoryType instances
  // is very unsafe, because those references will no longer
  // be valid if the history scroll is deleted.
  //
  const HistoryType& getType() { return *m_histType; }

protected:
  HistoryType* m_histType;

};

#if 1

//////////////////////////////////////////////////////////////////////
// File-based history (e.g. file log, no limitation in length)
//////////////////////////////////////////////////////////////////////

class HistoryScrollFile : public HistoryScroll
{
public:
  HistoryScrollFile(const QString &logFileName);
  virtual ~HistoryScrollFile();

  virtual int  getLines();
  virtual int  getLineLen(int lineno);
  virtual void getCells(int lineno, int colno, int count, Character res[]);
  virtual bool isWrappedLine(int lineno);

  virtual void addCells(const Character a[], int count);
  virtual void addLine(bool previousWrapped=false);

private:
  int startOfLine(int lineno);

  QString m_logFileName;
  HistoryFile index; // lines Row(int)
  HistoryFile cells; // text  Row(Character)
  HistoryFile lineflags; // flags Row(unsigned char)
};


//////////////////////////////////////////////////////////////////////
// Buffer-based history (limited to a fixed nb of lines)
//////////////////////////////////////////////////////////////////////
class HistoryScrollBuffer : public HistoryScroll
{
public:
  typedef QVector<Character> HistoryLine;

  HistoryScrollBuffer(unsigned int maxNbLines = 1000);
  virtual ~HistoryScrollBuffer();

  virtual int  getLines();
  virtual int  getLineLen(int lineno);
  virtual void getCells(int lineno, int colno, int count, Character res[]);
  virtual bool isWrappedLine(int lineno);

  virtual void addCells(const Character a[], int count);
  virtual void addCellsVector(const QVector<Character>& cells);
  virtual void addLine(bool previousWrapped=false);

  void setMaxNbLines(unsigned int nbLines);
  unsigned int maxNbLines() { return _maxLineCount; }
  

private:
  int bufferIndex(int lineNumber);

  HistoryLine* _historyBuffer;
  QBitArray _wrappedLine;
  int _maxLineCount;
  int _usedLines;  
  int _head;
  
  //QVector<histline*> m_histBuffer;
  //QBitArray m_wrappedLine;
  //unsigned int m_maxNbLines;
  //unsigned int m_nbLines;
  //unsigned int m_arrayIndex;
  //bool         m_buffFilled;
};

/*class HistoryScrollBufferV2 : public HistoryScroll
{
public:
  virtual int  getLines();
  virtual int  getLineLen(int lineno);
  virtual void getCells(int lineno, int colno, int count, Character res[]);
  virtual bool isWrappedLine(int lineno);

  virtual void addCells(const Character a[], int count);
  virtual void addCells(const QVector<Character>& cells);
  virtual void addLine(bool previousWrapped=false);

};*/

#endif

//////////////////////////////////////////////////////////////////////
// Nothing-based history (no history :-)
//////////////////////////////////////////////////////////////////////
class HistoryScrollNone : public HistoryScroll
{
public:
  HistoryScrollNone();
  virtual ~HistoryScrollNone();

  virtual bool hasScroll();

  virtual int  getLines();
  virtual int  getLineLen(int lineno);
  virtual void getCells(int lineno, int colno, int count, Character res[]);
  virtual bool isWrappedLine(int lineno);

  virtual void addCells(const Character a[], int count);
  virtual void addLine(bool previousWrapped=false);
};

//////////////////////////////////////////////////////////////////////
// BlockArray-based history
//////////////////////////////////////////////////////////////////////
class HistoryScrollBlockArray : public HistoryScroll
{
public:
  HistoryScrollBlockArray(size_t size);
  virtual ~HistoryScrollBlockArray();

  virtual int  getLines();
  virtual int  getLineLen(int lineno);
  virtual void getCells(int lineno, int colno, int count, Character res[]);
  virtual bool isWrappedLine(int lineno);

  virtual void addCells(const Character a[], int count);
  virtual void addLine(bool previousWrapped=false);

protected:
  BlockArray m_blockArray;
  QHash<int,size_t> m_lineLengths;
};

//////////////////////////////////////////////////////////////////////
// History using compact storage
// This implementation uses a list of fixed-sized blocks
// where history lines are allocated in (avoids heap fragmentation)
//////////////////////////////////////////////////////////////////////
typedef QVector<Character> TextLine;

class CharacterFormat
{
public:
  bool equalsFormat(const CharacterFormat &other) const {
    return other.rendition==rendition && other.fgColor==fgColor && other.bgColor==bgColor;
  }

  bool equalsFormat(const Character &c) const {
    return c.rendition==rendition && c.foregroundColor==fgColor && c.backgroundColor==bgColor;
  }

  void setFormat(const Character& c) {
    rendition=c.rendition;
    fgColor=c.foregroundColor;
    bgColor=c.backgroundColor;
  }

  CharacterColor fgColor, bgColor;
  quint16 startPos;
  quint8 rendition;
};

class CompactHistoryBlock
{
public:
  
  CompactHistoryBlock(){
    blockLength = 4096*64; // 256kb
    head = (quint8*) mmap(0, blockLength, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON, -1, 0);
    //head = (quint8*) malloc(blockLength);
    Q_ASSERT(head != MAP_FAILED);
    tail = blockStart = head;
    allocCount=0;
  }
  
  virtual ~CompactHistoryBlock(){
    //free(blockStart);
    munmap(blockStart, blockLength);
  }
  
  virtual unsigned int remaining(){ return blockStart+blockLength-tail;}
  virtual unsigned  length() { return blockLength; }
  virtual void* allocate(size_t length);
  virtual bool contains(void *addr) {return addr>=blockStart && addr<(blockStart+blockLength);}
  virtual void deallocate();
  virtual bool isInUse(){ return allocCount!=0; } ;

private:
  size_t blockLength;
  quint8* head;
  quint8* tail;
  quint8* blockStart;
  int allocCount;
};

class CompactHistoryBlockList {
public:
  CompactHistoryBlockList() {};
  ~CompactHistoryBlockList();

  void *allocate( size_t size );
  void deallocate(void *);
  int length() {return list.size();}
private:
  QList<CompactHistoryBlock*> list;
};

class CompactHistoryLine
{
public:
  CompactHistoryLine(const TextLine&, CompactHistoryBlockList& blockList);
  virtual ~CompactHistoryLine();

  // custom new operator to allocate memory from custom pool instead of heap
  static void *operator new( size_t size, CompactHistoryBlockList& blockList);
  static void operator delete( void *) { /* do nothing, deallocation from pool is done in destructor*/ } ;

  virtual void getCharacters(Character* array, int length, int startColumn) ;
  virtual void getCharacter(int index, Character &r) ;
  virtual bool isWrapped() const {return wrapped;};
  virtual void setWrapped(bool isWrapped) { wrapped=isWrapped;};
  virtual unsigned int getLength() const {return length;};

protected:
  CompactHistoryBlockList& blockList;
  CharacterFormat* formatArray;
  quint16 length;
  quint16* text;
  quint16 formatLength;
  bool wrapped;
};

class CompactHistoryScroll : public HistoryScroll
{
  typedef QList<CompactHistoryLine*> HistoryArray;

public:
  CompactHistoryScroll(unsigned int maxNbLines = 1000);
  virtual ~CompactHistoryScroll();

  virtual int  getLines();
  virtual int  getLineLen(int lineno);
  virtual void getCells(int lineno, int colno, int count, Character res[]);
  virtual bool isWrappedLine(int lineno);

  virtual void addCells(const Character a[], int count);
  virtual void addCellsVector(const TextLine& cells);
  virtual void addLine(bool previousWrapped=false);

  void setMaxNbLines(unsigned int nbLines);
  unsigned int maxNbLines() const { return _maxLineCount; }

private:
  bool hasDifferentColors(const TextLine& line) const;
  HistoryArray lines;
  CompactHistoryBlockList blockList;
  
  unsigned int _maxLineCount;
};

//////////////////////////////////////////////////////////////////////
// History type
//////////////////////////////////////////////////////////////////////

class HistoryType
{
public:
  HistoryType();
  virtual ~HistoryType();

  /**
   * Returns true if the history is enabled ( can store lines of output )
   * or false otherwise. 
   */
  virtual bool isEnabled()           const = 0;
  /**
   * Returns true if the history size is unlimited.
   */
  bool isUnlimited() const { return maximumLineCount() == 0; }
  /**
   * Returns the maximum number of lines which this history type
   * can store or 0 if the history can store an unlimited number of lines.
   */
  virtual int maximumLineCount()    const = 0;

  virtual HistoryScroll* scroll(HistoryScroll *) const = 0;
};

class HistoryTypeNone : public HistoryType
{
public:
  HistoryTypeNone();

  virtual bool isEnabled() const;
  virtual int maximumLineCount() const;

  virtual HistoryScroll* scroll(HistoryScroll *) const;
};

class HistoryTypeBlockArray : public HistoryType
{
public:
  HistoryTypeBlockArray(size_t size);
  
  virtual bool isEnabled() const;
  virtual int maximumLineCount() const;

  virtual HistoryScroll* scroll(HistoryScroll *) const;

protected:
  size_t m_size;
};

#if 1 
class HistoryTypeFile : public HistoryType
{
public:
  HistoryTypeFile(const QString& fileName=QString());

  virtual bool isEnabled() const;
  virtual const QString& getFileName() const;
  virtual int maximumLineCount() const;

  virtual HistoryScroll* scroll(HistoryScroll *) const;

protected:
  QString m_fileName;
};


class HistoryTypeBuffer : public HistoryType
{
    friend class HistoryScrollBuffer;

public:
  HistoryTypeBuffer(unsigned int nbLines);
   
  virtual bool isEnabled() const;
  virtual int maximumLineCount() const;
  
  virtual HistoryScroll* scroll(HistoryScroll *) const;

protected:
  unsigned int m_nbLines;
};

class CompactHistoryType : public HistoryType
{
public:
  CompactHistoryType(unsigned int size);
  
  virtual bool isEnabled() const;
  virtual int maximumLineCount() const;

  virtual HistoryScroll* scroll(HistoryScroll *) const;

protected:
  unsigned int m_nbLines;
};


#endif


#endif // TEHISTORY_H

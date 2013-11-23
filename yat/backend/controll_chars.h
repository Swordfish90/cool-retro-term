/**************************************************************************************************
* Copyright (c) 2012 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
* associated documentation files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge, publish, distribute,
* sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or
* substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
* NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
* DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
* OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
***************************************************************************************************/

#ifndef CONTROLL_CHARS_H
#define CONTROLL_CHARS_H

//This is taken largely from Standard ECMA-48
//http://www.ecma-international.org/publications/standards/Ecma-048.htm
//Also to heres a few handy references
//http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
//http://www.vt100.net/docs/vt100-ug/chapter3.html

#include <QtCore/QDebug>

namespace C0 {
enum C0 {
    NUL = 0x00,
    SOH = 0x01,
    STX = 0x02,
    ETX = 0x03,
    EOT = 0x04,
    ENQ = 0x05,
    ACK = 0x06,
    BEL = 0x07,
    BS = 0x08,
    HT = 0x09,
    LF = 0x0a,
    VT = 0x0b,
    FF = 0x0c,
    CR = 0x0d,
    SOorLS1 = 0x0e,
    SIorLS0 = 0x0f,
    DLE = 0x10,
    DC1 = 0x11,
    DC2 = 0x12,
    DC3 = 0x13,
    DC4 = 0x14,
    NAK = 0x15,
    SYN = 0x16,
    ETB = 0x17,
    CAN = 0x18,
    EM = 0x19,
    SUB = 0x1a,
    ESC = 0x1b,
    IS4 = 0x1c,
    IS3 = 0x1d,
    IS2 = 0x1e,
    IS1 = 0x1f,
    C0_END = 0x20
};
QDebug operator<<(QDebug debug, C0 character);
}

namespace C1_7bit {
enum C1_7bit {
    C1_7bit_Start = 0x80,
    NOT_DEFINED = C1_7bit_Start,
    NOT_DEFINED1 = 0x81,
    BPH = 0x42,
    NBH = 0x43,
    NOT_DEFINED2 = 0x82,
    NEL = 0x45,
    SSA = 0x46,
    ESA = 0x47,
    HTS = 0x48,
    HTJ = 0x49,
    VTS = 0x4a,
    PLD = 0x4b,
    PLU = 0x4c,
    RI  = 0x4d,
    SS2 = 0x4e,
    SS3 = 0x4f,
    DCS = 0x50,
    PU1 = 0x51,
    PU2 = 0x52,
    STS = 0x53,
    CCH = 0x54,
    MW  = 0x55,
    SPA = 0x56,
    EPA = 0x57,
    SOS = 0x58,
    NOT_DEFINED3 = 0x99,
    SCI = 0x5a,
    CSI = 0x5b,
    ST  = 0x5c,
    OSC = 0x5d,
    PM  = 0x5e,
    APC = 0x5f,
    C1_7bit_Stop = 0x60
};
QDebug operator<<(QDebug debug, C1_7bit character);
}
namespace C1_8bit {
enum C1_8bit {
    C1_8bit_Start = 0x80,
    NOT_DEFINED = C1_8bit_Start,
    NOT_DEFINED1 = 0x81,
    BPH = 0x82,
    NBH = 0x83,
    NOT_DEFINED2 = 0x84,
    NEL = 0x85,
    SSA = 0x86,
    ESA = 0x87,
    HTS = 0x88,
    HTJ = 0x89,
    VTS = 0x8a,
    PLD = 0x8b,
    PLU = 0x8c,
    RI  = 0x8d,
    SS2 = 0x8e,
    SS3 = 0x8f,
    DCS = 0x90,
    PU1 = 0x91,
    PU2C1_7bit = 0x92,
    STS = 0x93,
    CCH = 0x94,
    MW  = 0x95,
    SPA = 0x96,
    EPA = 0x97,
    SOS = 0x98,
    NOT_DEFINED3 = 0x99,
    SCI = 0x9a,
    CSI = 0x9b,
    ST  = 0x9c,
    OSC = 0x9d,
    PM  = 0x9e,
    APC = 0x9f,
    C1_8bit_Stop = 0xa0
};
QDebug operator<<(QDebug debug, C1_8bit character);
}

namespace FinalBytesNoIntermediate {
enum FinalBytesNoIntermediate {
    ICH = 0x40,
    CUU = 0x41,
    CUD = 0x42,
    CUF = 0x43,
    CUB = 0x44,
    CNL = 0x45,
    CPL = 0x46,
    CHA = 0x47,
    CUP = 0x48,
    CHT = 0x49,
    ED = 0x4a,
    EL = 0x4b,
    IL = 0x4c,
    DL = 0x4d,
    EF = 0x4e,
    EA = 0x4f,
    DCH = 0x50,
    SSE = 0x51,
    CPR = 0x52,
    SU = 0x53,
    SD = 0x54,
    NP = 0x55,
    PP = 0x56,
    CTC = 0x57,
    ECH = 0x58,
    CVT = 0x59,
    CBT = 0x5a,
    SRS = 0x5b,
    PTX = 0x5c,
    SDS = 0x5d,
    SIMD = 0x5e,
    NOT_DEFINED = 0x5f,
    HPA = 0x60,
    HPR = 0x61,
    REP = 0x62,
    DA = 0x63,
    VPA = 0x64,
    VPR = 0x65,
    HVP = 0x66,
    TBC = 0x67,
    SM = 0x68,
    MC = 0x69,
    HPB = 0x6a,
    VPB = 0x6b,
    RM = 0x6c,
    SGR = 0x6d,
    DSR = 0x6e,
    DAQ = 0x6f,
    Reserved0 = 0x70,
    Reserved1 = 0x71,
    Reserved2 = 0x72,
    Reserved3 = 0x73,
    Reserved4 = 0x74,
    Reserved5 = 0x75,
    Reserved6 = 0x76,
    Reserved7 = 0x77,
    Reserved8 = 0x78,
    Reserved9 = 0x79,
    Reserveda = 0x7a,
    Reservedb = 0x7b,
    Reservedc = 0x7c,
    Reservedd = 0x7d,
    Reservede = 0x7e,
    Reservedf = 0x7f
};
QDebug operator<<(QDebug debug, FinalBytesNoIntermediate character);
}

namespace FinalBytesSingleIntermediate {
enum FinalBytesSingleIntermediate {
    SL = 0x40,
    SR = 0x41,
    GSM = 0x42,
    GSS = 0x43,
    FNT = 0x44,
    TSS = 0x45,
    JFY = 0x46,
    SPI = 0x47,
    QUAD = 0x48,
    SSU = 0x49,
    PFS = 0x4a,
    SHS = 0x4b,
    SVS = 0x4c,
    IGS = 0x4d,
    NOT_DEFINED = 0x4e,
    IDCS = 0x4f,
    PPA = 0x50,
    PPR = 0x51,
    PPB = 0x52,
    SPD = 0x53,
    DTA = 0x54,
    SHL = 0x55,
    SLL = 0x56,
    FNK = 0x57,
    SPQR = 0x58,
    SEF = 0x59,
    PEC = 0x5a,
    SSW = 0x5b,
    SACS = 0x5c,
    SAPV = 0x5d,
    STAB = 0x5e,
    GCC = 0x5f,
    TATE = 0x60,
    TALE = 0x61,
    TAC = 0x62,
    TCC = 0x63,
    TSR = 0x64,
    SCO = 0x65,
    SRCS = 0x66,
    SCS = 0x67,
    SLS = 0x68,
    NOT_DEFINED2 = 0x69,
    NOT_DEFINED3 = 0x6a,
    SCP = 0x6b,
    NOT_DEFINED4 = 0x6c,
    NOT_DEFINED5 = 0x6d,
    NOT_DEFINED6 = 0x6e,
    NOT_DEFINED7 = 0x6f,
    Reserved0 = 0x70,
    Reserved1 = 0x71,
    Reserved2 = 0x72,
    Reserved3 = 0x73,
    Reserved4 = 0x74,
    Reserved5 = 0x75,
    Reserved6 = 0x76,
    Reserved7 = 0x77,
    Reserved8 = 0x78,
    Reserved9 = 0x79,
    Reserveda = 0x7a,
    Reservedb = 0x7b,
    Reservedc = 0x7c,
    Reservedd = 0x7d,
    Reservedf = 0x7f
};
QDebug operator<<(QDebug debug, FinalBytesSingleIntermediate character);
}

#endif // CONTROLL_CHARS_H

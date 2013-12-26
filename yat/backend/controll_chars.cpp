/*******************************************************************************
* Copyright (c) 2013 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*******************************************************************************/
#include "controll_chars.h"

namespace C0 {
QDebug operator<<(QDebug debug, C0 character) {
    bool insert_space = debug.autoInsertSpaces();
    debug.setAutoInsertSpaces(false);
    debug << "C0::";
    switch (character) {
        case NUL:
            debug << "NUL";
            break;
        case SOH:
            debug << "SOH";
            break;
        case STX:
            debug << "STX";
            break;
        case ETX:
            debug << "ETX";
            break;
        case EOT:
            debug << "EOT";
            break;
        case ENQ:
            debug << "ENQ";
            break;
        case ACK:
            debug << "ACK";
            break;
        case BEL:
            debug << "BEL";
            break;
        case BS:
            debug << "BS";
            break;
        case HT:
            debug << "HT";
            break;
        case LF:
            debug << "LF";
            break;
        case VT:
            debug << "VT";
            break;
        case FF:
            debug << "FF";
            break;
        case CR:
            debug << "CR";
            break;
        case SOorLS1:
            debug << "SOorLS1";
            break;
        case SIorLS0:
            debug << "SIorLS0";
            break;
        case DLE:
            debug << "DLE";
            break;
        case DC1:
            debug << "DC1";
            break;
        case DC2:
            debug << "DC2";
            break;
        case DC3:
            debug << "DC3";
            break;
        case DC4:
            debug << "DC4";
            break;
        case NAK:
            debug << "NAK";
            break;
        case SYN:
            debug << "SYN";
            break;
        case ETB:
            debug << "ETB";
            break;
        case CAN:
            debug << "CAN";
            break;
        case EM:
            debug << "EM";
            break;
        case SUB:
            debug << "SUB";
            break;
        case ESC:
            debug << "ESC";
            break;
        case IS4:
            debug << "IS4";
            break;
        case IS3:
            debug << "IS3";
            break;
        case IS2:
            debug << "IS2";
            break;
        case IS1:
            debug << "IS1";
            break;
        case C0_END:
            debug << "C0_END";
            break;
        default:
            debug << qPrintable(QString("0x%1").arg(character,0,16));
            break;
    }
    debug.setAutoInsertSpaces(insert_space);
    return debug;
}
}

namespace C1_7bit {
QDebug operator<<(QDebug debug, C1_7bit character) {
    bool insert_space = debug.autoInsertSpaces();
    debug.setAutoInsertSpaces(false);
    debug << "C1_7bit::";
    switch(character) {
        case ESC:
            debug << "ESC";
            break;
        case SCS_G0:
            debug << "SCS_G0";
            break;
        case SCS_G1:
            debug << "SCS_G1";
            break;
        case SCS_G2:
            debug << "SCS_G2";
            break;
        case SCS_G3:
            debug << "SCS_G3";
            break;
        case DECSC:
            debug << "DECSC";
            break;
        case DECRC:
            debug << "DECRC";
            break;
        case NOT_DEFINED:
            debug << "NOT_DEFINED";
            break;
        case NOT_DEFINED1:
            debug << "NOT_DEFINED1";
            break;
        case BPH:
            debug << "BPH";
            break;
        case NBH:
            debug << "NBH";
            break;
        case IND:
            debug << "IND";
            break;
        case NEL:
            debug << "NEL";
            break;
        case SSA:
            debug << "SSA";
            break;
        case ESA:
            debug << "ESA";
            break;
        case HTS:
            debug << "HTS";
            break;
        case HTJ:
            debug << "HTJ";
            break;
        case VTS:
            debug << "VTS";
            break;
        case PLD:
            debug << "PLD";
            break;
        case PLU:
            debug << "PLU";
            break;
        case RI :
            debug << "RI ";
            break;
        case SS2:
            debug << "SS2";
            break;
        case SS3:
            debug << "SS3";
            break;
        case DCS:
            debug << "DCS";
            break;
        case PU1:
            debug << "PU1";
            break;
        case PU2:
            debug << "PU2";
            break;
        case STS:
            debug << "STS";
            break;
        case CCH:
            debug << "CCH";
            break;
        case MW :
            debug << "MW ";
            break;
        case SPA:
            debug << "SPA";
            break;
        case EPA:
            debug << "EPA";
            break;
        case SOS:
            debug << "SOS";
            break;
        case NOT_DEFINED3:
            debug << "NOT_DEFINED3";
            break;
        case SCI:
            debug << "SCI";
            break;
        case CSI:
            debug << "CSI";
            break;
        case ST :
            debug << "ST ";
            break;
        case OSC:
            debug << "OSC";
            break;
        case PM :
            debug << "PM ";
            break;
        case APC:
            debug << "APC";
            break;
        case C1_7bit_Stop:
            debug << "C1_7bit_Stop";
            break;
        default:
            debug << qPrintable(QString("0x%1").arg(character,0,16));
            break;
    }
    debug.setAutoInsertSpaces(insert_space);
    return debug;
}
}

namespace C1_8bit {
QDebug operator<<(QDebug debug, C1_8bit character) {
    bool insert_space = debug.autoInsertSpaces();
    debug.setAutoInsertSpaces(false);
    debug << "C1_8bit::";
    switch(character) {
        case NOT_DEFINED:
            debug << "NOT_DEFINED";
            break;
        case NOT_DEFINED1:
            debug << "NOT_DEFINED1";
            break;
        case BPH:
            debug << "BPH";
            break;
        case NBH:
            debug << "NBH";
            break;
        case NOT_DEFINED2:
            debug << "NOT_DEFINED2";
            break;
        case NEL:
            debug << "NEL";
            break;
        case SSA:
            debug << "SSA";
            break;
        case ESA:
            debug << "ESA";
            break;
        case HTS:
            debug << "HTS";
            break;
        case HTJ:
            debug << "HTJ";
            break;
        case VTS:
            debug << "VTS";
            break;
        case PLD:
            debug << "PLD";
            break;
        case PLU:
            debug << "PLU";
            break;
        case RI :
            debug << "RI ";
            break;
        case SS2:
            debug << "SS2";
            break;
        case SS3:
            debug << "SS3";
            break;
        case DCS:
            debug << "DCS";
            break;
        case PU1:
            debug << "PU1";
            break;
        case PU2C1_7bit:
            debug << "PU2C1_7bit";
            break;
        case STS:
            debug << "STS";
            break;
        case CCH:
            debug << "CCH";
            break;
        case MW :
            debug << "MW ";
            break;
        case SPA:
            debug << "SPA";
            break;
        case EPA:
            debug << "EPA";
            break;
        case SOS:
            debug << "SOS";
            break;
        case NOT_DEFINED3:
            debug << "NOT_DEFINED3";
            break;
        case SCI:
            debug << "SCI";
            break;
        case CSI:
            debug << "CSI";
            break;
        case ST :
            debug << "ST ";
            break;
        case OSC:
            debug << "OSC";
            break;
        case PM :
            debug << "PM ";
            break;
        case APC:
            debug << "APC";
            break;
        case C1_8bit_Stop:
            debug << "C1_8bit_Stop";
            break;
        default:
            debug << qPrintable(QString("0x%1").arg(character,0,16));
            break;
    }
    debug.setAutoInsertSpaces(insert_space);
    return debug;
}
}
namespace FinalBytesNoIntermediate {
QDebug operator<<(QDebug debug, FinalBytesNoIntermediate character) {
    bool insert_space = debug.autoInsertSpaces();
    debug.setAutoInsertSpaces(false);
    debug << "FinalBytesNoIntermediate::";
    switch(character) {
        case ICH:
            debug << "ICH";
            break;
        case CUU:
            debug << "CUU";
            break;
        case CUD:
            debug << "CUD";
            break;
        case CUF:
            debug << "CUF";
            break;
        case CUB:
            debug << "CUB";
            break;
        case CNL:
            debug << "CNL";
            break;
        case CPL:
            debug << "CPL";
            break;
        case CHA:
            debug << "CHA";
            break;
        case CUP:
            debug << "CUP";
            break;
        case CHT:
            debug << "CHT";
            break;
        case ED:
            debug << "ED";
            break;
        case EL:
            debug << "EL";
            break;
        case IL:
            debug << "IL";
            break;
        case DL:
            debug << "DL";
            break;
        case EF:
            debug << "EF";
            break;
        case EA:
            debug << "EA";
            break;
        case DCH:
            debug << "DCH";
            break;
        case SSE:
            debug << "SSE";
            break;
        case CPR:
            debug << "CPR";
            break;
        case SU:
            debug << "SU";
            break;
        case SD:
            debug << "SD";
            break;
        case NP:
            debug << "NP";
            break;
        case PP:
            debug << "PP";
            break;
        case CTC:
            debug << "CTC";
            break;
        case ECH:
            debug << "ECH";
            break;
        case CVT:
            debug << "CVT";
            break;
        case CBT:
            debug << "CBT";
            break;
        case SRS:
            debug << "SRS";
            break;
        case PTX:
            debug << "PTX";
            break;
        case SDS:
            debug << "SDS";
            break;
        case SIMD:
            debug << "SIMD";
            break;
        case NOT_DEFINED:
            debug << "NOT_DEFINED";
            break;
        case HPA:
            debug << "HPA";
            break;
        case HPR:
            debug << "HPR";
            break;
        case REP:
            debug << "REP";
            break;
        case DA:
            debug << "DA";
            break;
        case VPA:
            debug << "VPA";
            break;
        case VPR:
            debug << "VPR";
            break;
        case HVP:
            debug << "HVP";
            break;
        case TBC:
            debug << "TBC";
            break;
        case SM:
            debug << "SM";
            break;
        case MC:
            debug << "MC";
            break;
        case HPB:
            debug << "HPB";
            break;
        case VPB:
            debug << "VPB";
            break;
        case RM:
            debug << "RM";
            break;
        case SGR:
            debug << "SGR";
            break;
        case DSR:
            debug << "DSR";
            break;
        case DAQ:
            debug << "DAQ";
            break;
        case Reserved0:
            debug << "Reserved0";
            break;
        case Reserved1:
            debug << "Reserved1";
            break;
        case DECSTBM:
            debug << "DECSTBM";
            break;
        case Reserved3:
            debug << "Reserved3";
            break;
        case Reserved4:
            debug << "Reserved4";
            break;
        case Reserved5:
            debug << "Reserved5";
            break;
        case Reserved6:
            debug << "Reserved6";
            break;
        case Reserved7:
            debug << "Reserved7";
            break;
        case Reserved8:
            debug << "Reserved8";
            break;
        case Reserved9:
            debug << "Reserved9";
            break;
        case Reserveda:
            debug << "Reserveda";
            break;
        case Reservedb:
            debug << "Reservedb";
            break;
        case Reservedc:
            debug << "Reservedc";
            break;
        case Reservedd:
            debug << "Reservedd";
            break;
        case Reservede:
            debug << "Reservede";
            break;
        case Reservedf:
            debug << "Reservedf";
            break;
        default:
            debug << qPrintable(QString("0x%1").arg(character,0,16));
            break;
    }
    debug.setAutoInsertSpaces(insert_space);
    return debug;
}
}

namespace FinalBytesSingleIntermediate {
QDebug operator<<(QDebug debug, FinalBytesSingleIntermediate character)
{
    bool insert_space = debug.autoInsertSpaces();
    debug.setAutoInsertSpaces(false);
    debug << "FinalBytesSingleIntermediate::";
    switch(character) {
        case SL:
            debug << "SL";
            break;
        case SR:
            debug << "SR";
            break;
        case GSM:
            debug << "GSM";
            break;
        case GSS:
            debug << "GSS";
            break;
        case FNT:
            debug << "FNT";
            break;
        case TSS:
            debug << "TSS";
            break;
        case JFY:
            debug << "JFY";
            break;
        case SPI:
            debug << "SPI";
            break;
        case QUAD:
            debug << "QUAD";
            break;
        case SSU:
            debug << "SSU";
            break;
        case PFS:
            debug << "PFS";
            break;
        case SHS:
            debug << "SHS";
            break;
        case SVS:
            debug << "SVS";
            break;
        case IGS:
            debug << "IGS";
            break;
        case NOT_DEFINED:
            debug << "NOT_DEFINED";
            break;
        case IDCS:
            debug << "IDCS";
            break;
        case PPA:
            debug << "PPA";
            break;
        case PPR:
            debug << "PPR";
            break;
        case PPB:
            debug << "PPB";
            break;
        case SPD:
            debug << "SPD";
            break;
        case DTA:
            debug << "DTA";
            break;
        case SHL:
            debug << "SHL";
            break;
        case SLL:
            debug << "SLL";
            break;
        case FNK:
            debug << "FNK";
            break;
        case SPQR:
            debug << "SPQR";
            break;
        case SEF:
            debug << "SEF";
            break;
        case PEC:
            debug << "PEC";
            break;
        case SSW:
            debug << "SSW";
            break;
        case SACS:
            debug << "SACS";
            break;
        case SAPV:
            debug << "SAPV";
            break;
        case STAB:
            debug << "STAB";
            break;
        case GCC:
            debug << "GCC";
            break;
        case TATE:
            debug << "TATE";
            break;
        case TALE:
            debug << "TALE";
            break;
        case TAC:
            debug << "TAC";
            break;
        case TCC:
            debug << "TCC";
            break;
        case TSR:
            debug << "TSR";
            break;
        case SCO:
            debug << "SCO";
            break;
        case SRCS:
            debug << "SRCS";
            break;
        case SCS:
            debug << "SCS";
            break;
        case SLS:
            debug << "SLS";
            break;
        case NOT_DEFINED2:
            debug << "NOT_DEFINED2";
            break;
        case NOT_DEFINED3:
            debug << "NOT_DEFINED3";
            break;
        case SCP:
            debug << "SCP";
            break;
        case NOT_DEFINED4:
            debug << "NOT_DEFINED4";
            break;
        case NOT_DEFINED5:
            debug << "NOT_DEFINED5";
            break;
        case NOT_DEFINED6:
            debug << "NOT_DEFINED6";
            break;
        case NOT_DEFINED7:
            debug << "NOT_DEFINED7";
            break;
        case Reserved0:
            debug << "Reserved0";
            break;
        case Reserved1:
            debug << "Reserved1";
            break;
        case Reserved2:
            debug << "Reserved2";
            break;
        case Reserved3:
            debug << "Reserved3";
            break;
        case Reserved4:
            debug << "Reserved4";
            break;
        case Reserved5:
            debug << "Reserved5";
            break;
        case Reserved6:
            debug << "Reserved6";
            break;
        case Reserved7:
            debug << "Reserved7";
            break;
        case Reserved8:
            debug << "Reserved8";
            break;
        case Reserved9:
            debug << "Reserved9";
            break;
        case Reserveda:
            debug << "Reserveda";
            break;
        case Reservedb:
            debug << "Reservedb";
            break;
        case Reservedc:
            debug << "Reservedc";
            break;
        case Reservedd:
            debug << "Reservedd";
            break;
        case Reservedf:
            debug << "Reservedf";
            break;
        default:
            debug << qPrintable(QString("0x%1").arg(character,0,16));
            break;
    }
    debug.setAutoInsertSpaces(insert_space);
    return debug;
}
}


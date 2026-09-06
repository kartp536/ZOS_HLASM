//TUDEMO    JOB (102,SYS),'HLASM TIMEUSED',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*
//*====================================================================*
//* JCL TO ASSEMBLE, LINK-EDIT, AND EXECUTE THE TUDEMO PROGRAM
//* WITH WTO MESSAGE DISPLAY TO JOB LOG (V4 - ULTRA-ROBUST LINKAGE)
//*====================================================================*
//*
//* STEP 1: ASSEMBLE USING IBM HIGH LEVEL ASSEMBLER (ASMA90)
//*
//ASM      EXEC PGM=ASMA90,
//             PARM='OBJECT,LIST,XREF(SHORT),ALIGN'
//SYSLIB   DD  DSN=SYS1.MACLIB,DISP=SHR
//         DD  DSN=SYS1.MODGEN,DISP=SHR
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(15,15))
//SYSPRINT DD  SYSOUT=*
//* SYSLIN defines the output object dataset passed to the Binder
//SYSLIN   DD  DSN=&&OBJMOD,DISP=(NEW,PASS,DELETE),
//             UNIT=SYSDA,SPACE=(CYL,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120)
//* SYSIN DD * points to the source module.
//SYSIN    DD  *
*---------------------------------------------------------------------*
* MODULE NAME : TUDEMO                                                *
* DESCRIPTION : Demonstration of the z/OS TIMEUSED macro in HLASM     *
*               to measure elapsed task processor (CPU) time and      *
*               write the result to the job log via WTO.              *
*                                                                     *
* ENVIRONMENT : z/OS, AMODE 31, RMODE ANY, Problem or Supervisor State*
*               Runs in Primary ASC mode.                             *
*                                                                     *
* PROCESSING  : 1. Invokes TIMEUSED to get starting CPU time.         *
*               2. Runs a dummy loop to consume CPU cycles.           *
*               3. Invokes TIMEUSED to get ending CPU time.           *
*               4. Calculates the difference in TOD clock units.      *
*               5. Converts TOD clock units to microseconds.          *
*               6. Formats microseconds to decimal and issues WTO.    *
*               7. Releases storage and exits with Return Code 0.     *
*---------------------------------------------------------------------*
TUDEMO   CSECT
TUDEMO   AMODE 31
TUDEMO   RMODE ANY
*
* Standard Entry Linkage
*
         STM   14,12,12(13)     Save caller's registers
         LR    12,15            Establish R12 as base register
         USING TUDEMO,12        Establish program addressability
*
* Allocate dynamic storage for reentrancy (Subpool 0)
*
         LA    2,WORKLEN        Load work area length into R2
         STORAGE OBTAIN,LENGTH=(2),ADDR=(1),LOC=ANY,COND=NO
*
* Set up save area chain
*
         ST    13,4(,1)         Store backward pointer in new save area
         ST    1,8(,13)         Store forward pointer in caller's save area
         LR    13,1             Point R13 to our dynamic work area
         USING WORKAREA,13      Establish work area addressability
*
* Step 1: Query CPU Time at start of measurement
*
         TIMEUSED STORADR=CPU_START,LINKAGE=SYSTEM
*
* Verify return code in R15 (should be 0)
*
         LTR   15,15            Check return code
         BNZ   ERR_TIME         If non-zero, branch to error handler
*
* Step 2: Dummy workload loop to consume some CPU time
*
         L     2,=F'10000000'   Set loop counter to 10 million (R2 repurposed)
LOOP_WORK EQU   *
         BCT   2,LOOP_WORK      Decrement and loop until zero
*
* Step 3: Query CPU Time at end of measurement
*
         TIMEUSED STORADR=CPU_END,LINKAGE=SYSTEM
*
* Verify return code in R15 (should be 0)
*
         LTR   15,15            Check return code
         BNZ   ERR_TIME         If non-zero, branch to error handler
*
* Step 4: Perform 64-bit subtraction to find elapsed CPU time
*
         LG    1,CPU_END        Load 8-byte end CPU time (TOD format)
         SG    1,CPU_START      Subtract 8-byte start CPU time
         STG   1,CPU_DIFF       Store elapsed TOD clock units
*
* Step 5: Convert TOD units to microseconds
* In z/Architecture TOD format, bit 51 represents 1 microsecond.
* Shifting a 64-bit TOD value right by 12 bits shifts bit 51 to bit 63 (LSB),
* converting the value directly into microseconds.
*
         SRLG  1,1,12           Shift right by 12 bits
         STG   1,CPU_USEC       Store elapsed microseconds
*
* Step 5b: Format microsecond count to decimal and print to log (WTO)
*
         L     3,CPU_USEC+4     Load low-order 32 bits of microseconds
         CVD   3,DBL_WORK       Convert binary to packed decimal in work area
*
* Initialize and populate dynamic WTO list in reentrant storage
*
         MVC   WTOPLIST(WTOLEN_C),WTOTEMPL Copy template to dynamic storage
         MVC   W_NUM(12),EDMASK Copy edit mask to numeric field
         ED    W_NUM(12),DBL_WORK+2 Edit packed decimal to EBCDIC string
*
* Write message directly to Operator / Job Log
*
         WTO   MF=(E,WTOPLIST)  Issue WTO using dynamic parameter list
*
* Normal Exit Linkage: Free storage and return to caller
*
EXIT_OK  EQU   *
         LR    1,13             Save work area address for STORAGE RELEASE
         L     13,4(,13)        Point R13 back to caller's save area
         LA    2,WORKLEN        Load work area size into R2
         STORAGE RELEASE,LENGTH=(2),ADDR=(1),COND=NO
*
         LM    14,12,12(13)     Restore caller's registers (overwrites R15)
         XR    15,15            Explicitly set return code (R15) to 0 (Success)
         BR    14               Return to caller
*
* Error Exit Handler
*
ERR_TIME EQU   *
         LR    1,13             Save work area address for STORAGE RELEASE
         L     13,4(,13)        Point R13 back to caller's save area
         LA    2,WORKLEN        Load work area size into R2
         STORAGE RELEASE,LENGTH=(2),ADDR=(1),COND=NO
*
         LM    14,12,12(13)     Restore caller's registers (overwrites R15)
         LA    15,12            Explicitly set return code (R15) to 12 (Error)
         BR    14               Return to caller
*
* Literals Pool
*
         LTORG
*
* Static Templates and Constants (ReadOnly)
*
EDMASK   DC    X'402020202020202020202120' Edit mask for 11 digits
*
WTOTEMPL DS    0H
         DC    AL2(WTOLEN_C)    Length of parameter list
         DC    H'0'             MCS flags
         DC    CL18'ELAPSED CPU TIME: '
         DC    CL12' '          Placeholder for formatted number
         DC    CL30' MICROSECONDS'
WTOLEN_C EQU   *-WTOTEMPL       Calculated length of WTO template
*
* Dynamic Work Area DSECT
*
WORKAREA DSECT
SAVEAREA DS    18F              Standard MVS 18-word save area (72 bytes)
CPU_START DS   D                8-byte start CPU time (doubleword aligned)
CPU_END   DS   D                8-byte end CPU time (doubleword aligned)
CPU_DIFF  DS   D                Elapsed TOD clock units
CPU_USEC  DS   D                Elapsed microseconds
DBL_WORK  DS   D                Doubleword work area for CVD/ED
*
* Dynamic WTO Parameter List Mapping (64 bytes total)
*
WTOPLIST DS    0H
W_LEN    DS    H
W_MCS    DS    H
W_TXT    DS    0CL60
W_PRE    DS    CL18
W_NUM    DS    CL12
W_SUF    DS    CL30
*
WORKLEN   EQU  *-WORKAREA       Calculated length of dynamic work area
*
         END   TUDEMO
/*
//*
//* STEP 2: LINK-EDIT / BIND THE OBJECT MODULE TO CREATE LOAD MODULE
//*
//LKED     EXEC PGM=IEWBLINK,
//             PARM='MAP,LET,LIST,NCAL'
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(5,5))
//SYSPRINT DD  SYSOUT=*
//* Input object module from step 1
//SYSLIN   DD  DSN=&&OBJMOD,DISP=(OLD,DELETE)
//* Output load library (a temporary library for immediate execution)
//SYSLMOD  DD  DSN=&&GOSET(TUDEMO),DISP=(NEW,PASS,DELETE),
//             UNIT=SYSDA,SPACE=(CYL,(1,1,1)),
//             DCB=(RECFM=U,LRECL=0,BLKSIZE=32760)
//*
//* STEP 3: RUN THE COMPILED AND BOUND TUDEMO PROGRAM
//*
//RUN      EXEC PGM=*.LKED.SYSLMOD,
//             COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//

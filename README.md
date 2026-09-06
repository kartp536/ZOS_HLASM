# ZOS_HLASM

A collection of sample IBM High Level Assembler (HLASM) programs, routines, and macros for z/OS.

## Overview

This repository contains practical code examples and reference implementations designed for developers learning or working with **IBM High Level Assembler (HLASM)** on the **IBM z/OS** operating system.

## Repository Contents

- **Basic Assembly Programs:** Fundamentals of assembler coding, base-displacement addressing, register conventions, and storage declarations (`DS`, `DC`).
- **Control & Linkage:** Standard save area linkage conventions (entry and exit sequences), calling subroutines, and parameter passing.
- **System Macros:** Working examples of common z/OS supervisor call (SVC) macros such as `WTO` (Write to Operator), `GETMAIN`/`FREEMAIN`, and `TIME`.
- **Data Manipulation:** Packed decimal arithmetic (`AP`, `SP`, `MP`, `DP`), binary operations, and character manipulation (`MVC`, `CLC`, `TR`, `TRT`).
- **Record I/O:** Sequential file processing (QSAM) demonstrating `DCB`, `OPEN`, `GET`/`PUT`, and `CLOSE`.

## Requirements & Environment

- **Target OS:** IBM z/OS (or emulators such as Hercules / zPDT)
- **Assembler:** High Level Assembler (HLASM) Release 6 or higher
- **Linkage Editor / Binder:** IBM DFSMS Binder for z/OS

## Getting Started

### 1. Assemble and Link-Edit
Sample JCL to assemble and link a program:

```jcl
//ASMLINK  JOB (ACCOUNT),'HLASM COMPILE',CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//ASM      EXEC PGM=ASMA90,PARM='OBJECT,NODECK'
//SYSLIB   DD DISP=SHR,DSN=SYS1.MACLIB
//         DD DISP=SHR,DSN=SYS1.MODGEN
//SYSIN    DD DISP=SHR,DSN=YOUR.SOURCE.PDS(MEMBER)
//SYSLIN   DD DISP=(,PASS),DSN=&&OBJSET,SPACE=(CYL,(1,1)),UNIT=SYSALLDA
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSALLDA,SPACE=(CYL,(2,2))
//*
//LKED     EXEC PGM=IEWBLINK,PARM='LIST,MAP,XREF',COND=(4,LT,ASM)
//SYSLIB   DD DISP=SHR,DSN=CEE.SCEELKED
//SYSLIN   DD DISP=(OLD,DELETE),DSN=&&OBJSET
//SYSLMOD  DD DISP=SHR,DSN=YOUR.LOAD.PDS(MEMBER)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))


2. Execute
Run the load module via batch JCL:
//RUNHLASM JOB (ACCOUNT),'RUN HLASM',CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1    EXEC PGM=MEMBER
//STEPLIB  DD DISP=SHR,DSN=YOUR.LOAD.PDS
//SYSOUT   DD SYSOUT=*

Contributing
Contributions and additions of new HLASM sample routines are welcome. Feel free to open an issue or submit a pull request.

License
Distributed under the MIT License. See LICENSE for details.
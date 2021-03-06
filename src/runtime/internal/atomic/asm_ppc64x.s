// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build ppc64 ppc64le

#include "textflag.h"

// bool cas(uint32 *ptr, uint32 old, uint32 new)
// Atomically:
//	if(*val == old){
//		*val = new;
//		return 1;
//	} else
//		return 0;
TEXT runtime∕internal∕atomic·Cas(SB), NOSPLIT, $0-17
	MOVD	ptr+0(FP), R3
	MOVWZ	old+8(FP), R4
	MOVWZ	new+12(FP), R5
cas_again:
	SYNC
	LWAR	(R3), R6
	CMPW	R6, R4
	BNE	cas_fail
	STWCCC	R5, (R3)
	BNE	cas_again
	MOVD	$1, R3
	SYNC
	ISYNC
	MOVB	R3, ret+16(FP)
	RET
cas_fail:
	MOVD	$0, R3
	BR	-5(PC)

// bool	runtime∕internal∕atomic·Cas64(uint64 *ptr, uint64 old, uint64 new)
// Atomically:
//	if(*val == *old){
//		*val = new;
//		return 1;
//	} else {
//		return 0;
//	}
TEXT runtime∕internal∕atomic·Cas64(SB), NOSPLIT, $0-25
	MOVD	ptr+0(FP), R3
	MOVD	old+8(FP), R4
	MOVD	new+16(FP), R5
cas64_again:
	SYNC
	LDAR	(R3), R6
	CMP	R6, R4
	BNE	cas64_fail
	STDCCC	R5, (R3)
	BNE	cas64_again
	MOVD	$1, R3
	SYNC
	ISYNC
	MOVB	R3, ret+24(FP)
	RET
cas64_fail:
	MOVD	$0, R3
	BR	-5(PC)

TEXT runtime∕internal∕atomic·Casuintptr(SB), NOSPLIT, $0-25
	BR	runtime∕internal∕atomic·Cas64(SB)

TEXT runtime∕internal∕atomic·Loaduintptr(SB),  NOSPLIT|NOFRAME, $0-16
	BR	runtime∕internal∕atomic·Load64(SB)

TEXT runtime∕internal∕atomic·Loaduint(SB), NOSPLIT|NOFRAME, $0-16
	BR	runtime∕internal∕atomic·Load64(SB)

TEXT runtime∕internal∕atomic·Storeuintptr(SB), NOSPLIT, $0-16
	BR	runtime∕internal∕atomic·Store64(SB)

TEXT runtime∕internal∕atomic·Xadduintptr(SB), NOSPLIT, $0-24
	BR	runtime∕internal∕atomic·Xadd64(SB)

TEXT runtime∕internal∕atomic·Loadint64(SB), NOSPLIT, $0-16
	BR	runtime∕internal∕atomic·Load64(SB)

TEXT runtime∕internal∕atomic·Xaddint64(SB), NOSPLIT, $0-16
	BR	runtime∕internal∕atomic·Xadd64(SB)

// bool casp(void **val, void *old, void *new)
// Atomically:
//	if(*val == old){
//		*val = new;
//		return 1;
//	} else
//		return 0;
TEXT runtime∕internal∕atomic·Casp1(SB), NOSPLIT, $0-25
	BR runtime∕internal∕atomic·Cas64(SB)

// uint32 xadd(uint32 volatile *ptr, int32 delta)
// Atomically:
//	*val += delta;
//	return *val;
TEXT runtime∕internal∕atomic·Xadd(SB), NOSPLIT, $0-20
	MOVD	ptr+0(FP), R4
	MOVW	delta+8(FP), R5
	SYNC
	LWAR	(R4), R3
	ADD	R5, R3
	STWCCC	R3, (R4)
	BNE	-4(PC)
	SYNC
	ISYNC
	MOVW	R3, ret+16(FP)
	RET

TEXT runtime∕internal∕atomic·Xadd64(SB), NOSPLIT, $0-24
	MOVD	ptr+0(FP), R4
	MOVD	delta+8(FP), R5
	SYNC
	LDAR	(R4), R3
	ADD	R5, R3
	STDCCC	R3, (R4)
	BNE	-4(PC)
	SYNC
	ISYNC
	MOVD	R3, ret+16(FP)
	RET

TEXT runtime∕internal∕atomic·Xchg(SB), NOSPLIT, $0-20
	MOVD	ptr+0(FP), R4
	MOVW	new+8(FP), R5
	SYNC
	LWAR	(R4), R3
	STWCCC	R5, (R4)
	BNE	-3(PC)
	SYNC
	ISYNC
	MOVW	R3, ret+16(FP)
	RET

TEXT runtime∕internal∕atomic·Xchg64(SB), NOSPLIT, $0-24
	MOVD	ptr+0(FP), R4
	MOVD	new+8(FP), R5
	SYNC
	LDAR	(R4), R3
	STDCCC	R5, (R4)
	BNE	-3(PC)
	SYNC
	ISYNC
	MOVD	R3, ret+16(FP)
	RET

TEXT runtime∕internal∕atomic·Xchguintptr(SB), NOSPLIT, $0-24
	BR	runtime∕internal∕atomic·Xchg64(SB)


TEXT runtime∕internal∕atomic·Storep1(SB), NOSPLIT, $0-16
	BR	runtime∕internal∕atomic·Store64(SB)

TEXT runtime∕internal∕atomic·Store(SB), NOSPLIT, $0-12
	MOVD	ptr+0(FP), R3
	MOVW	val+8(FP), R4
	SYNC
	MOVW	R4, 0(R3)
	RET

TEXT runtime∕internal∕atomic·Store64(SB), NOSPLIT, $0-16
	MOVD	ptr+0(FP), R3
	MOVD	val+8(FP), R4
	SYNC
	MOVD	R4, 0(R3)
	RET

// void	runtime∕internal∕atomic·Or8(byte volatile*, byte);
TEXT runtime∕internal∕atomic·Or8(SB), NOSPLIT, $0-9
	MOVD	ptr+0(FP), R3
	MOVBZ	val+8(FP), R4
	// Align ptr down to 4 bytes so we can use 32-bit load/store.
	// R5 = (R3 << 0) & ~3
	RLDCR	$0, R3, $~3, R5
	// Compute val shift.
#ifdef GOARCH_ppc64
	// Big endian.  ptr = ptr ^ 3
	XOR	$3, R3
#endif
	// R6 = ((ptr & 3) * 8) = (ptr << 3) & (3*8)
	RLDC	$3, R3, $(3*8), R6
	// Shift val for aligned ptr.  R4 = val << R6
	SLD	R6, R4, R4

again:
	SYNC
	LWAR	(R5), R6
	OR	R4, R6
	STWCCC	R6, (R5)
	BNE	again
	SYNC
	ISYNC
	RET

// void	runtime∕internal∕atomic·And8(byte volatile*, byte);
TEXT runtime∕internal∕atomic·And8(SB), NOSPLIT, $0-9
	MOVD	ptr+0(FP), R3
	MOVBZ	val+8(FP), R4
	// Align ptr down to 4 bytes so we can use 32-bit load/store.
	// R5 = (R3 << 0) & ~3
	RLDCR	$0, R3, $~3, R5
	// Compute val shift.
#ifdef GOARCH_ppc64
	// Big endian.  ptr = ptr ^ 3
	XOR	$3, R3
#endif
	// R6 = ((ptr & 3) * 8) = (ptr << 3) & (3*8)
	RLDC	$3, R3, $(3*8), R6
	// Shift val for aligned ptr.  R4 = val << R6 | ^(0xFF << R6)
	MOVD	$0xFF, R7
	SLD	R6, R4
	SLD	R6, R7
	XOR $-1, R7
	OR	R7, R4
again:
	SYNC
	LWAR	(R5), R6
	AND	R4, R6
	STWCCC	R6, (R5)
	BNE	again
	SYNC
	ISYNC
	RET

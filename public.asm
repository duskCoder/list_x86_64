;; The MIT License (MIT)
;;
;; Copyright (c) 2013-2014 Olivier Gayot
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.

;; initializes the list stored at address $rdi with default values
global list_init:function

;; dynamically allocate a new list and return its address via $rax. If
;; the dynamic allocation unlikely fails, $rax will contain a null pointer
global list_new_raw:function

;; same as list_new_raw, unless the list is initialized with default values
global list_new:function

;; remove every element of the list pointed to by $rip.
;; the elements are freed using free() from the libc
global list_clear:function

;; create a new element (using dynamic allocation) at the end of the list
;; stored at address $rdi. the created element will contain the value of $rsi
;; if, unlikely, the allocation fails, $rax will contain -1.
;; otherwise (on success), $rax will be set to 0
global list_append:function

;; like list_append but instead of adding at the end of the list, this
;; function adds at the position $rdx
global list_insert:function

;; for every element in the list stored at address $rdi, call the function
;; pointed to by $rsi with the value of the current element.
global list_apply:function

;; here is the definition of a list (aka a prehead)
struc list_t
    .first: resq 1
    .size:  resd 1
endstruc

;; the elements which are linked together
struc elem_t
    .next:  resq 1
    .value: resq 1
endstruc

; vim:ft=nasm

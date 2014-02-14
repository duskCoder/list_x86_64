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

extern malloc

;; initializes the list stored at address $rdi with default values
global list_init

;; dynamically allocate a new list and return its address via $rax. If
;; the dynamic allocation unlikely fails, $rax will contain a null pointer
global list_new_raw

;; same as list_new_raw, unless the list is initialized with default values
global list_new

;; create a new element (using dynamic allocation) at the end of the list
;; stored at address $rdi. the created element will contain the value of $rsi
;; if, unlikely, the allocation fails, $rax will contain -1.
;; otherwise (on success), $rax will be set to 0
global list_append

;; for every element in the list stored at address $rdi, call the function
;; pointed to by $rsi with the value of the current element.
global list_apply

section .text

list_init: ;; {{{

    enter 0, 0

    mov QWORD [rdi], 0 ; first = NULL
    mov DWORD [rdi + 8], 0 ; size = 0

    leave
    ret

;; }}}
list_new: ;; {{{

    call list_new_raw

    test rax, rax
    je list_new_end

    mov rdi, rax
    call list_init

    list_new_end:
    ret

;; }}}
list_new_raw: ;; {{{

    enter 0, 0

    mov rdi, 0xc
    call malloc

    leave
    ret

;; }}}
list_append: ;; {{{

    enter 0x18, 0

    mov [rsp], rdi
    mov [rsp + 8], rsi

    mov rdi, 0x10
    call malloc

    test rax, rax
    jne list_append_malloc_succeed
    mov rax, -1
    jmp list_append_end

    list_append_malloc_succeed:
    ; set the new element
    mov rsi, QWORD [rsp + 8]
    mov QWORD [rax], 0
    mov QWORD [rax + 8], rsi

    mov rdi, [rsp]
    mov ecx, [rdi + 8]

    list_append_loop:
    test ecx, ecx
    je list_append_set_elem
    dec ecx
    mov rdi, QWORD [rdi]
    jmp list_append_loop

    list_append_set_elem:
    ; set the next element
    mov [rdi], rax

    ; increment size
    mov rdi, QWORD [rsp]
    inc DWORD [rdi + 8]

    xor rax, rax

    list_append_end:
    leave
    ret

;; }}}
list_apply: ;; {{{

    enter 0x14, 0

    mov QWORD [rsp], rsi

    mov ecx, DWORD [rdi + 8]

    list_apply_loop:
    test ecx, ecx
    je list_apply_end
    dec ecx
    ; elem = list->first or elem = elem->next
    mov rdi, QWORD [rdi]

    ; backup our registers
    mov DWORD [rsp + 8], ecx
    mov QWORD [rsp + 0xc], rdi

    mov rdi, QWORD [rdi + 8]
    call QWORD [rsp]

    ; get back the registers
    mov ecx, DWORD [rsp + 8]
    mov rdi, QWORD [rsp + 0xc]

    jmp list_apply_loop

    list_apply_end:
    leave
    ret

;; }}}

; vim:ft=nasm

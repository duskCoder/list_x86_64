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
extern free

%include "public.asm"

section .text

list_init: ;; {{{

    mov QWORD [rdi + list_t.first], 0 ; first = NULL
    mov DWORD [rdi + list_t.size], 0 ; size = 0

    ret

;; }}}
list_new: ;; {{{

    call list_new_raw

    test rax, rax
    je .end

    mov rdi, rax
    call list_init

    .end:
    ret

;; }}}
list_new_raw: ;; {{{

    enter 0, 0

    mov rdi, list_t_size
    call malloc

    leave
    ret

;; }}}
list_clear: ;; {{{

    enter 0, 0

    mov ecx, [rdi + list_t.size] ; load the size of the list into the counter

    test ecx, ecx
    je .end

    mov rsi, QWORD [rdi + list_t.first]

    ; the list is reset to its initial state
    mov DWORD [rdi + list_t.size], 0
    mov QWORD [rdi + list_t.first], 0

    .loop:
    push QWORD [rsi + elem_t.next]
    push rcx

    mov rdi, rsi
    call free

    pop rcx
    pop rsi

    dec ecx

    test ecx, ecx
    jne .loop

    .end:
    leave
    ret

;; }}}

%macro rethrow_create_element 0
    mov rdi, elem_t_size
    call malloc

    test rax, rax
    jne %%malloc_succeed
    mov rax, -1
    jmp .end

    %%malloc_succeed
%endmacro

list_append: ;; {{{

    enter 0x18, 0

    mov [rsp], rdi
    mov [rsp + 8], rsi

    rethrow_create_element

    ; set the new element
    mov rsi, QWORD [rsp + 8]
    mov QWORD [rax + elem_t.next], 0
    mov QWORD [rax + elem_t.value], rsi

    mov rdi, [rsp]
    mov ecx, [rdi + list_t.size]

    .loop:
    test ecx, ecx
    je .set_elem
    dec ecx
    mov rdi, QWORD [rdi + elem_t.next]
    jmp .loop

    .set_elem:
    ; set the next element
    mov [rdi], rax

    ; increment size
    mov rdi, QWORD [rsp]
    inc DWORD [rdi + list_t.size]

    xor rax, rax

    .end:
    leave
    ret

;; }}}
list_insert: ;; {{{

    enter 0, 0

    cmp edx, DWORD [rdi + list_t.size]
    jg .error

    inc DWORD [rdi + list_t.size]

    push rdx
    push rsi
    push rdi
    rethrow_create_element
    pop rdi
    pop rsi
    pop rcx

    ; set the element
    mov QWORD [rax + elem_t.value], rsi

    test ecx, ecx
    jnz .insert

    ; this will be the first element
    mov r8, QWORD [rdi + list_t.first]
    mov QWORD [rax + elem_t.next], r8
    mov QWORD [rdi + list_t.first], rax

    jmp .success

    ; this is not the first element
    .insert:
    mov rdi, QWORD [rdi + list_t.first]

    .loop:
    dec ecx
    test ecx, ecx
    jz .loop_ended
    mov rdi, QWORD [rdi + elem_t.next]
    jmp .loop

    .loop_ended:
    mov r8, QWORD [rdi + elem_t.next]
    mov QWORD [rax + elem_t.next], r8
    mov QWORD [rdi + elem_t.next], rax

    .success:
    xor rax, rax
    jmp .end

    .error:
    mov rax, -1

    .end:
    leave
    ret

;; }}}
list_apply: ;; {{{

    enter 0x14, 0

    mov QWORD [rsp], rsi

    mov ecx, DWORD [rdi + list_t.size]

    .loop:
    test ecx, ecx
    je .end
    dec ecx
    ; elem = list->first or elem = elem->next
    mov rdi, QWORD [rdi]

    ; backup our registers
    mov DWORD [rsp + 8], ecx
    mov QWORD [rsp + 0xc], rdi

    mov rdi, QWORD [rdi + elem_t.value]
    call QWORD [rsp]

    ; get back the registers
    mov ecx, DWORD [rsp + 8]
    mov rdi, QWORD [rsp + 0xc]

    jmp .loop

    .end:
    leave
    ret

;; }}}

; vim:ft=nasm

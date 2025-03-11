# Nim-Loader
A not too basic shellcode loader written in nim with the functionality to send a request to discord webhooks,
it uses the windows api for allocating memory, changing memory protection, injecting the shellcode 
to the created memory buffer and getting the computer name / hostname.

## Compile and Run:
compile:
```ps
nim c -d:ssl loader.nim
```
run:
```
.\loader.exe
```

![aa](https://github.com/user-attachments/assets/325277ab-208a-4e89-bbb0-38d18b5ceece)
![ff](https://github.com/user-attachments/assets/61684b83-916a-4355-bf86-8f5e880069de)


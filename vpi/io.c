#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <conio.h>
#include <windows.h>
#else
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#endif

#define VPI_COMPATIBILITY_VERSION_1800v2012 1
#include "sv_vpi_user.h"
#include "vpi_user.h"

static int read_char(void) {
  int c;

#ifdef _WIN32
  c = _kbhit() ? _getch() : -1;
#else
  int bytesWaiting;
  ioctl(0, FIONREAD, &bytesWaiting);
  c = bytesWaiting > 0 ? getchar() : -1;
#endif

  return c;
}

void on_start(void) {
#ifdef _WIN32
  HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode = 0;
  GetConsoleMode(hStdin, &mode);
  SetConsoleMode(hStdin, mode & (~ENABLE_ECHO_INPUT));
#else
  struct termios io;
  tcgetattr(STDIN_FILENO, &io);
  io.c_lflag &= ~(ICANON | ECHO);

  tcsetattr(STDIN_FILENO, TCSANOW, &io);
#endif
}

void on_end(void) {
#ifdef _WIN32
  HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode = 0;
  GetConsoleMode(hStdin, &mode);
  SetConsoleMode(hStdin, mode | ENABLE_ECHO_INPUT);
#else
  struct termios io;
  tcgetattr(STDIN_FILENO, &io);
  io.c_lflag |= ICANON | ECHO;

  tcsetattr(STDIN_FILENO, TCSANOW, &io);
#endif
}

static int read_char_calltf(char *user_data) {
  vpiHandle callh = vpi_handle(vpiSysTfCall, NULL);

  int c = read_char();

  s_vpi_value val;
  val.format = vpiIntVal;
  val.value.integer = c;

  vpi_put_value(callh, &val, NULL, vpiNoDelay);

  return 0;
}

static int on_start_calltf(struct t_cb_data *user_data) {
  on_start();
  return 0;
}

static int on_end_calltf(struct t_cb_data *user_data) {
  on_end();
  return 0;
}

void register_read_char(void) {
  s_vpi_systf_data data = {
      vpiSysFunc, vpiIntFunc, "$read_char", read_char_calltf,
      NULL,       NULL,       "$read_char",
  };

  vpi_register_systf(&data);
}

void register_on_start(void) {
  s_cb_data cb = {
      cbStartOfSimulation, on_start_calltf, NULL, NULL, NULL, 0, NULL,
  };

  vpi_register_cb(&cb);
}

void register_on_end(void) {
  s_cb_data cb = {
      cbEndOfSimulation, on_end_calltf, NULL, NULL, NULL, 0, NULL,
  };

  vpi_register_cb(&cb);
}

void (*vlog_startup_routines[])(void) = {
    register_read_char,
    register_on_start,
    register_on_end,
    NULL,
};

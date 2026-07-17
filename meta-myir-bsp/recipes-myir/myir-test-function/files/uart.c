#include <stdio.h>
#include <termios.h>
#include <linux/ioctl.h>
#include <linux/serial.h>
#include <asm-generic/ioctls.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <stdlib.h>
#include <getopt.h>
#include <sys/ioctl.h>
#include <signal.h>

typedef enum {DISABLE = 0, ENABLE} RS485_ENABLE_t;
typedef enum {MODE_RECEIVE = 0, MODE_SEND = 1} WORK_MODE_t;

volatile int running = 1;
struct termios oldtio;

void signal_handler(int sig) {
    if (sig == SIGINT) {
        running = 0;
    }
}

int set_port(int fd, int nSpeed, int nBits, char nEvent, int nStop)
{
    struct termios newtio;
    
    memset(&oldtio, 0, sizeof(oldtio));
    if(tcgetattr(fd, &oldtio) != 0) {
        perror("set_port/tcgetattr");
        return -1;    
    }
    
    memset(&newtio, 0, sizeof(newtio));
    newtio.c_cflag = newtio.c_cflag |= CLOCAL | CREAD;
    newtio.c_cflag &= ~CSIZE;    
    
    switch (nBits) {
        case 8: newtio.c_cflag |= CS8; break;
        case 7: newtio.c_cflag |= CS7; break;
        case 6: newtio.c_cflag |= CS6; break;
        case 5: newtio.c_cflag |= CS5; break;
        default: newtio.c_cflag |= CS8; break;
    }
    
    switch (nEvent) {
        case 'o': case 'O':
            newtio.c_cflag |= PARENB;
            newtio.c_cflag |= PARODD;
            newtio.c_iflag |= (INPCK | ISTRIP);
            break;
        case 'e': case 'E':
            newtio.c_cflag |= PARENB;
            newtio.c_cflag &= ~PARODD;
            newtio.c_iflag |= (INPCK | ISTRIP);
            break;
        case 'n': case 'N':
            newtio.c_cflag &= ~PARENB;
            break;
        default:
            newtio.c_cflag &= ~PARENB; 
            break;
    }
    
    switch (nStop) {
        case 1: newtio.c_cflag &= ~CSTOPB; break;
        case 2: newtio.c_cflag |= CSTOPB; break;
        default: newtio.c_cflag &= ~CSTOPB; break;    
    }    
    
    switch (nSpeed) {
        case 300: cfsetospeed(&newtio, B300); cfsetispeed(&newtio, B300); break;
        case 600: cfsetospeed(&newtio, B600); cfsetispeed(&newtio, B600); break;
        case 1200: cfsetospeed(&newtio, B1200); cfsetispeed(&newtio, B1200); break;
        case 2400: cfsetospeed(&newtio, B2400); cfsetispeed(&newtio, B2400); break;
        case 4800: cfsetospeed(&newtio, B4800); cfsetispeed(&newtio, B4800); break;
        case 9600: cfsetospeed(&newtio, B9600); cfsetispeed(&newtio, B9600); break;
        case 19200: cfsetospeed(&newtio, B19200); cfsetispeed(&newtio, B19200); break;
        case 38400: cfsetospeed(&newtio, B38400); cfsetispeed(&newtio, B38400); break;
        case 57600: cfsetospeed(&newtio, B57600); cfsetispeed(&newtio, B57600); break;
        case 115200: cfsetospeed(&newtio, B115200); cfsetispeed(&newtio, B115200); break;
        case 230400: cfsetospeed(&newtio, B230400); cfsetispeed(&newtio, B230400); break;
        default: cfsetospeed(&newtio, B115200); cfsetispeed(&newtio, B115200); break;    
    }
    
    newtio.c_cc[VTIME] = 0;
    newtio.c_cc[VMIN] = 0;
    tcflush(fd, TCIFLUSH);
    
    if((tcsetattr(fd, TCSANOW, &newtio))!=0) {
        perror("set_port/tcsetattr");
        return -1;
    }
    
    return 0;
}

int open_port(char *dir)
{
    int fd;
    fd = open(dir, O_RDWR | O_NOCTTY | O_NDELAY);
    if(fd < 0) {
        perror("open_port");    
    }    
    return fd;
}

void print_usage(FILE *stream, int exit_code)
{
    fprintf(stream, "Usage: rs485_test [ options ]\n");
    fprintf(stream,
            "\t-h  --help      Display this usage information.\n"
            "\t-d  --device    Serial device (e.g., /dev/ttyS0)\n"
            "\t-b  --baudrate  Set baud rate (e.g., 9600, 115200)\n"
            "\t-m  --mode      Work mode: 0=receive, 1=send (default: 0)\n"
            "\t-s  --string    Send string (only for send mode, default: 123456789)\n");
    exit(exit_code);
}

int rs485_enable(const int fd, const RS485_ENABLE_t enable)
{
    struct serial_rs485 rs485conf;
    int res;
    
    res = ioctl(fd, TIOCGRS485, &rs485conf);
    if (res < 0) {
        perror("Ioctl error on getting 485 configure");
        return res;
    }
    
    if (enable) {
        rs485conf.flags |= SER_RS485_ENABLED;
    } else {
        rs485conf.flags &= ~(SER_RS485_ENABLED);
    }
    
    rs485conf.delay_rts_before_send = 0x00000004;
    
    res = ioctl(fd, TIOCSRS485, &rs485conf);
    if (res < 0) {
        perror("Ioctl error on setting 485 configure");
    }
    
    return res;
}

int main(int argc, char *argv[])
{
    int fd, i;
    int speed = 9600;
    int mode = MODE_RECEIVE;  // 默认接收模式
    char *device = NULL;
    char *send_str = "123456789";
    int device_flag = 0, spee_flag = 0;
    char read_buf[256];
    int nread;
    ssize_t ret;
    
    const char *const short_options = "hd:b:m:s:";
    const struct option long_options[] = {
        { "help",    0, NULL, 'h'},
        { "device",  1, NULL, 'd'},
        { "baudrate",1, NULL, 'b'},
        { "mode",    1, NULL, 'm'},
        { "string",  1, NULL, 's'},
        { NULL,      0, NULL, 0  }
    };
    
    if (argc < 2) {
        print_usage(stdout, 0);
        exit(0);    
    }
    
    while (1) {
        int next_option = getopt_long(argc, argv, short_options, long_options, NULL);
        if (next_option < 0)
            break;
        switch (next_option) {
            case 'h':
                print_usage(stdout, 0);
                break;
            case 'd':
                device = optarg;
                device_flag = 1;
                break;
            case 'b':
                speed = atoi(optarg);
                spee_flag = 1;
                break;
            case 'm':
                mode = atoi(optarg);
                break;
            case 's':
                send_str = optarg;
                break;
            case '?':
                print_usage(stderr, 1);
                break;
            default:
                abort();
        }
    }
    
    if ((!device_flag) || (!spee_flag)) {
        print_usage(stderr, 1);
        exit(0);    
    }
    
    signal(SIGINT, signal_handler);
    
    fd = open_port(device);
    if (fd < 0) {
        perror("open failed");
        return -1;
    }
    
    // 启用RS485模式
    if (rs485_enable(fd, ENABLE) == 0) {
        printf("RS485 mode enabled\n");
    } else {
        printf("Failed to enable RS485 mode\n");
    }
    
    i = set_port(fd, speed, 8, 'N', 1);
    if (i < 0) {
        perror("set_port failed");
        close(fd);
        return -1;    
    }
    
    printf("Serial port %s opened, baudrate: %d\n", device, speed);
    
    if (mode == MODE_SEND) {
        // 发送模式
        int len = strlen(send_str);
        printf("SEND MODE - Sending: %s\n", send_str);
        printf("Press Ctrl+C to stop\n\n");
        
        while (running) {
            printf("SEND[%d]: %s\n", len, send_str);
            ret = write(fd, send_str, len);
            if (ret < 0) {
                perror("write error");
            } else if (ret != len) {
                printf("Warning: only wrote %zd of %d bytes\n", ret, len);
            }
            sleep(2);
        }
    } else {
        // 接收模式
        printf("RECEIVE MODE - Waiting for data...\n");
        printf("Press Ctrl+C to exit\n\n");
        
        while (running) {
            nread = read(fd, read_buf, sizeof(read_buf) - 1);
            if (nread > 0) {
                read_buf[nread] = '\0';
                printf("RECV[%3d]: %s\n", nread, read_buf);
            }
            usleep(10000);  // 10ms
        }
    }
    
    tcsetattr(fd, TCSANOW, &oldtio);
    close(fd);
    printf("\nProgram exited\n");
    
    return 0;
}
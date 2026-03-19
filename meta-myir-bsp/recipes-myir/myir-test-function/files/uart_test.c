#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>
#include <getopt.h>
#include <string.h>


#define RS485_GPIO 524  //RS485 DE/RE
#define RS485_GPIO_BASE "/sys/class/gpio/gpio"
#define RS485_GPIO_DIR_FMT RS485_GPIO_BASE "%d/direction"
#define RS485_GPIO_VAL_FMT RS485_GPIO_BASE "%d/value"


#define FALSE 1
#define TRUE  0

static int gpio_exists(int gpio_num)
{
    struct stat st;
    char path[64];
    snprintf(path, sizeof(path), "%s%d", RS485_GPIO_BASE, gpio_num);
    return (stat(path, &st) == 0);
}

static void rs485_gpio_write_fmt(const char *fmt, int gpio_num, const char *val)
{
    char path[128];
    snprintf(path, sizeof(path), fmt, gpio_num);
    
    int fd = open(path, O_WRONLY);
    if (fd >= 0) {
        write(fd, val, strlen(val));
        close(fd);
    }
}

static void rs485_gpio_init(void)
{
    int fd;
    char gpio_str[8];

    if (!gpio_exists(RS485_GPIO)) {
        fd = open("/sys/class/gpio/export", O_WRONLY);
        if (fd >= 0) {
            snprintf(gpio_str, sizeof(gpio_str), "%d", RS485_GPIO);
            write(fd, gpio_str, strlen(gpio_str));
            close(fd);
            usleep(100000); 
        } else {
            perror("Failed to open export");
            return;
        }
    }

    rs485_gpio_write_fmt(RS485_GPIO_DIR_FMT, RS485_GPIO, "out");

    rs485_gpio_write_fmt(RS485_GPIO_VAL_FMT, RS485_GPIO, "0");
}

static inline void rs485_tx_enable(void)
{
    rs485_gpio_write_fmt(RS485_GPIO_VAL_FMT, RS485_GPIO, "1");
}

static inline void rs485_rx_enable(void)
{
    rs485_gpio_write_fmt(RS485_GPIO_VAL_FMT, RS485_GPIO, "0");
}


char *recchr="We received:\"";

int speed_arr[] = {
    B921600, B460800, B230400, B115200, B57600, B38400, B19200,
    B9600, B4800, B2400, B1200, B300,
};

int name_arr[] = {
    921600, 460800, 230400, 115200, 57600, 38400, 19200,
    9600, 4800, 2400, 1200, 300,
};

void print_usage (FILE *stream, int exit_code);

void set_speed(int fd, int speed)
{
    int i, status;
    struct termios Opt;

    tcgetattr(fd, &Opt);

    for (i = 0; i < sizeof(speed_arr)/sizeof(int); i++) {
        if (speed == name_arr[i]) {
            tcflush(fd, TCIOFLUSH);
            cfsetispeed(&Opt, speed_arr[i]);
            cfsetospeed(&Opt, speed_arr[i]);
            status = tcsetattr(fd, TCSANOW, &Opt);
            if (status != 0)
                perror("tcsetattr");
            return;
        }
    }

    fprintf(stderr, "Unsupported baudrate\n");
    print_usage(stderr, 1);
}

int set_Parity(int fd,int databits,int stopbits,int parity)
{
    struct termios options;

    if (tcgetattr(fd,&options) != 0) {
        perror("SetupSerial");
        return FALSE;
    }

    options.c_cflag &= ~CSIZE;
    options.c_cflag |= (databits == 7) ? CS7 : CS8;

    switch (parity) {
    case 'N':
    case 'n':
        options.c_cflag &= ~PARENB;
        options.c_iflag &= ~INPCK;
        break;
    case 'O':
    case 'o':
        options.c_cflag |= (PARODD | PARENB);
        options.c_iflag |= INPCK;
        break;
    case 'E':
    case 'e':
        options.c_cflag |= PARENB;
        options.c_cflag &= ~PARODD;
        options.c_iflag |= INPCK;
        break;
    default:
        return FALSE;
    }

    if (stopbits == 2)
        options.c_cflag |= CSTOPB;
    else
        options.c_cflag &= ~CSTOPB;

    options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
    options.c_oflag &= ~OPOST;

    options.c_cc[VTIME] = 150;
    options.c_cc[VMIN]  = 0;

    tcflush(fd, TCIFLUSH);
    return (tcsetattr(fd, TCSANOW, &options) == 0);
}

int OpenDev(char *Dev)
{
    int fd = open(Dev, O_RDWR | O_NOCTTY);
    if (fd < 0)
        perror("Open serial");
    return fd;
}

const char *program_name;

void print_usage (FILE *stream, int exit_code)
{
    fprintf(stream,
        "Usage: %s -d dev -b baud -m mode [-s string]\n"
        "  -d device   serial device\n"
        "  -b baudrate baudrate\n"
        "  -m mode     1=send 0=recv\n"
        "  -s string   send string\n",
        program_name);
    exit(exit_code);
}

int main(int argc, char *argv[])
{
    int fd, nread;
    char buff[512];
    char *device = NULL;
    char *xmit = "1234567890";
    int speed = 115200;
    int send_mode = 0;
    int opt;

    program_name = argv[0];

    while ((opt = getopt(argc, argv, "hd:b:s:m:")) != -1) {
        switch (opt) {
        case 'd': device = optarg; break;
        case 'b': speed = atoi(optarg); break;
        case 's': xmit = optarg; break;
        case 'm': send_mode = atoi(optarg); break;
        case 'h':
        default:
            print_usage(stderr, 1);
        }
    }

    if (!device)
        print_usage(stderr, 1);

    rs485_gpio_init();

    fd = OpenDev(device);
    if (fd < 0) return -1;

    set_speed(fd, speed);
    if (!set_Parity(fd, 8, 1, 'N')) {
        fprintf(stderr, "Set parity failed\n");
        return -1;
    }

    if (send_mode) {
        while (1) {
            rs485_tx_enable();
            usleep(1000);

            printf("%s SEND: %s\n", device, xmit);
            write(fd, xmit, strlen(xmit));
            tcdrain(fd);

            rs485_rx_enable();
            sleep(1);
        }
    } else {
        rs485_rx_enable();
        while (1) {
            nread = read(fd, buff, sizeof(buff) - 1);
            if (nread > 0) {
                buff[nread] = '\0';
                printf("%s RECV[%d]: %s\n", device, nread, buff);
            }
        }
    }

    close(fd);
    return 0;
}
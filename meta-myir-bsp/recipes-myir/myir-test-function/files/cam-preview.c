/*
 * cam-preview.c — camera preview without GStreamer (lookup-table optimized)
 *
 * Board: MYD-Y6ULL (i.MX6ULL), LCD 800x480 RGB565
 * Camera: OV2659 via mx6s-csi (/dev/video1)
 *
 * Pipeline: V4L2 capture YUYV → scale 800x600→800x480 → RGB565 → /dev/fb0
 * Colour conversion uses 4×256-byte lookup tables — zero multiplications.
 *
 * Build:
 *   $CC cam-preview.c -o cam-preview
 */

#include <errno.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <linux/videodev2.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <unistd.h>

#define CAM_DEV     "/dev/video1"
#define FB_DEV      "/dev/fb0"
#define CAP_WIDTH   800
#define CAP_HEIGHT  600
#define FB_WIDTH    800
#define FB_HEIGHT   480
#define BUF_COUNT   4

static volatile sig_atomic_t keep_running = 1;

static void sig_handler(int sig) { (void)sig; keep_running = 0; }

/* ---- LVGL suspend / resume ---- */
static pid_t lvgl_pid(void)
{
	FILE *f = popen("pidof myir_lvgl", "r");
	char buf[32] = {0};
	pid_t p = 0;

	if (f) {
		if (fgets(buf, sizeof(buf), f))
			p = (pid_t)atoi(buf);
		pclose(f);
	}
	return p;
}

static void lvgl_suspend(void)
{
	pid_t p = lvgl_pid();
	if (p > 0) {
		kill(p, SIGSTOP);
		printf("LVGL (pid %d) suspended\n", p);
	}
}

static void lvgl_resume(void)
{
	pid_t p = lvgl_pid();
	if (p > 0) {
		kill(p, SIGCONT);
		printf("LVGL (pid %d) resumed\n", p);
	}
}

/* ---- YUV lookup tables (1 KB total, built once) ---- */
static short rv_tab[256];    /* (v * 1436) >> 10 */
static short gu_tab[256];    /* (u *  352) >> 10 */
static short gv_tab[256];    /* (v *  731) >> 10 */
static short bu_tab[256];    /* (u * 1813) >> 10 */
static int   tabs_ready;

static void init_yuv_tabs(void)
{
	int i;
	for (i = -128; i < 128; i++) {
		int idx = i + 128;
		rv_tab[idx] = (short)((i * 1436) >> 10);
		gu_tab[idx] = (short)((i *  352) >> 10);
		gv_tab[idx] = (short)((i *  731) >> 10);
		bu_tab[idx] = (short)((i * 1813) >> 10);
	}
	tabs_ready = 1;
}

/*
 * YUYV (src_w × src_h) → RGB565 (dst_w × dst_h)
 * Nearest-neighbour scaling + lookup-table YUV→RGB.
 * Precomputes row mapping to eliminate divides from the inner loop.
 */
static void yuyv_scale_to_rgb565(const uint8_t *yuyv,
				 uint16_t *rgb,
				 int src_w, int src_h,
				 int dst_w, int dst_h)
{
	int dy;

	if (!tabs_ready)
		init_yuv_tabs();

	/* No horizontal scaling: CAP_WIDTH == FB_WIDTH (both 800) */
	for (dy = 0; dy < dst_h; dy++) {
		/* precomputed source line: nearest-neighbour vertical scale */
		int sy = dy * src_h / dst_h;
		if (sy >= src_h) sy = src_h - 1;

		const uint8_t *yuyv_line = yuyv + sy * src_w * 2;
		uint16_t       *rgb_line = rgb  + dy * dst_w;
		int dx;

		for (dx = 0; dx < dst_w; dx += 2) {
			/*
			 * src_w == dst_w, so sx == dx — no horizontal scaling needed.
			 * Just read the macro-pixel directly.
			 */
			int y0 = yuyv_line[dx * 2 + 0];
			int u  = yuyv_line[dx * 2 + 1];
			int y1 = yuyv_line[dx * 2 + 2];
			int v  = yuyv_line[dx * 2 + 3];
			int r, g, b;

			/* lookup-table YUV→RGB565 */
			r = y0 + rv_tab[v];
			g = y0 - gu_tab[u] - gv_tab[v];
			b = y0 + bu_tab[u];
			if (r < 0) r = 0; if (r > 255) r = 255;
			if (g < 0) g = 0; if (g > 255) g = 255;
			if (b < 0) b = 0; if (b > 255) b = 255;
			rgb_line[dx] = (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));

			if (dx + 1 >= dst_w) break;

			r = y1 + rv_tab[v];
			g = y1 - gu_tab[u] - gv_tab[v];
			b = y1 + bu_tab[u];
			if (r < 0) r = 0; if (r > 255) r = 255;
			if (g < 0) g = 0; if (g > 255) g = 255;
			if (b < 0) b = 0; if (b > 255) b = 255;
			rgb_line[dx + 1] = (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
		}
	}
}

/* Write RGB565 to framebuffer.  stride == w * 2, so single memcpy. */
static void fb_blit_rgb565(unsigned char *fb_base, uint16_t *rgb,
			   int w, int h, int line_length)
{
	(void)line_length;
	memcpy(fb_base, rgb, (size_t)w * h * 2);
}

int main(void)
{
	int cam_fd, fb_fd, i;
	struct v4l2_format        fmt;
	struct v4l2_requestbuffers req;
	struct v4l2_buffer         buf;
	enum v4l2_buf_type         type;
	void *buf_ptr[BUF_COUNT] = {NULL};
	uint16_t *rgb = NULL;
	unsigned char *fb_base = NULL;
	unsigned char *fb_backup = NULL;
	size_t         fb_size;
	int            fb_line;
	struct fb_fix_screeninfo finfo;
	struct fb_var_screeninfo vinfo;
	unsigned int frame_count = 0;
	struct timeval t1, t2;

	signal(SIGINT,  sig_handler);
	signal(SIGTERM, sig_handler);

	/* ---- open camera ---- */
	cam_fd = open(CAM_DEV, O_RDWR);
	if (cam_fd < 0) { perror("open " CAM_DEV); return 1; }

	/* ---- set format ---- */
	memset(&fmt, 0, sizeof(fmt));
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt.fmt.pix.width       = CAP_WIDTH;
	fmt.fmt.pix.height      = CAP_HEIGHT;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
	fmt.fmt.pix.field       = V4L2_FIELD_NONE;
	if (ioctl(cam_fd, VIDIOC_S_FMT, &fmt) < 0) {
		perror("VIDIOC_S_FMT"); close(cam_fd); return 1;
	}
	printf("capture: %ux%u %c%c%c%c\n",
	       fmt.fmt.pix.width, fmt.fmt.pix.height,
	       (char)(fmt.fmt.pix.pixelformat >> 0),
	       (char)(fmt.fmt.pix.pixelformat >> 8),
	       (char)(fmt.fmt.pix.pixelformat >> 16),
	       (char)(fmt.fmt.pix.pixelformat >> 24));

	/* ---- request + mmap buffers ---- */
	memset(&req, 0, sizeof(req));
	req.count  = BUF_COUNT;
	req.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	req.memory = V4L2_MEMORY_MMAP;
	if (ioctl(cam_fd, VIDIOC_REQBUFS, &req) < 0) {
		perror("VIDIOC_REQBUFS"); close(cam_fd); return 1;
	}
	for (i = 0; i < (int)req.count; i++) {
		memset(&buf, 0, sizeof(buf));
		buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		buf.memory = V4L2_MEMORY_MMAP;
		buf.index  = i;
		if (ioctl(cam_fd, VIDIOC_QUERYBUF, &buf) < 0) {
			perror("VIDIOC_QUERYBUF"); close(cam_fd); return 1;
		}
		buf_ptr[i] = mmap(NULL, buf.length, PROT_READ | PROT_WRITE,
				  MAP_SHARED, cam_fd, buf.m.offset);
		if (buf_ptr[i] == MAP_FAILED) {
			perror("mmap"); close(cam_fd); return 1;
		}
		if (ioctl(cam_fd, VIDIOC_QBUF, &buf) < 0) {
			perror("VIDIOC_QBUF"); close(cam_fd); return 1;
		}
	}
	printf("%d camera buffers (%.1f MB)\n",
	       (int)req.count,
	       (double)(req.count * fmt.fmt.pix.sizeimage) / (1024.0 * 1024.0));

	/* ---- start streaming ---- */
	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if (ioctl(cam_fd, VIDIOC_STREAMON, &type) < 0) {
		perror("VIDIOC_STREAMON"); close(cam_fd); return 1;
	}

	/* ---- open / mmap / backup framebuffer ---- */
	fb_fd = open(FB_DEV, O_RDWR);
	if (fb_fd < 0) { perror("open " FB_DEV); close(cam_fd); return 1; }
	ioctl(fb_fd, FBIOGET_FSCREENINFO, &finfo);
	ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo);
	fb_line = finfo.line_length;
	fb_size = (size_t)fb_line * vinfo.yres_virtual;
	printf("fb: %ux%u bpp=%d stride=%d size=%zu\n",
	       vinfo.xres, vinfo.yres, vinfo.bits_per_pixel, fb_line, fb_size);

	fb_base = mmap(NULL, fb_size, PROT_READ | PROT_WRITE,
		       MAP_SHARED, fb_fd, 0);
	if (fb_base == MAP_FAILED) {
		perror("fb mmap"); close(fb_fd); close(cam_fd); return 1;
	}

	fb_backup = malloc(fb_size);
	if (fb_backup)
		memcpy(fb_backup, fb_base, fb_size);

	rgb = malloc(FB_WIDTH * FB_HEIGHT * 2);
	if (!rgb) { perror("malloc"); munmap(fb_base, fb_size); close(fb_fd); close(cam_fd); return 1; }

	/* ---- main loop ---- */
	lvgl_suspend();
	printf("Preview running, Ctrl-C to stop...\n");

	while (keep_running) {
		memset(&buf, 0, sizeof(buf));
		buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		buf.memory = V4L2_MEMORY_MMAP;

		if (ioctl(cam_fd, VIDIOC_DQBUF, &buf) < 0) {
			if (errno == EINTR) continue;
			perror("VIDIOC_DQBUF"); break;
		}

		gettimeofday(&t1, NULL);

		/* YUYV 800x600 → RGB565 800x480 */
		yuyv_scale_to_rgb565(buf_ptr[buf.index],
				     rgb,
				     fmt.fmt.pix.width,
				     fmt.fmt.pix.height,
				     FB_WIDTH, FB_HEIGHT);

		/* blit to framebuffer */
		fb_blit_rgb565(fb_base, rgb, FB_WIDTH, FB_HEIGHT, fb_line);

		gettimeofday(&t2, NULL);

		frame_count++;
		if (frame_count % 30 == 0) {
			double dt = (t2.tv_sec - t1.tv_sec) +
				    (t2.tv_usec - t1.tv_usec) / 1000000.0;
			printf("frame %u  %d ms  fps ~%.0f\n",
			       frame_count, (int)(dt * 1000), 1.0 / dt);
		}

		if (ioctl(cam_fd, VIDIOC_QBUF, &buf) < 0) {
			perror("VIDIOC_QBUF"); break;
		}
	}

	/* ---- restore framebuffer + resume LVGL ---- */
	if (fb_backup)
		memcpy(fb_base, fb_backup, fb_size);
	printf("fb restored\n");
	lvgl_resume();

	/* ---- cleanup ---- */
	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	ioctl(cam_fd, VIDIOC_STREAMOFF, &type);
	for (i = 0; i < BUF_COUNT; i++)
		if (buf_ptr[i]) munmap(buf_ptr[i], fmt.fmt.pix.sizeimage);
	free(fb_backup);
	free(rgb);
	munmap(fb_base, fb_size);
	close(fb_fd);
	close(cam_fd);
	return 0;
}

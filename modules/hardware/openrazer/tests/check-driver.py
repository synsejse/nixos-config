#!/usr/bin/env python3
"""Fault-injection tests against actual patched C functions, without hardware.

Usage: python3 check-driver.py /path/to/patched/openrazer/source
The USB calls are replaced in a host executable; no daemon or device is created.
"""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

root = Path(sys.argv[1]) / 'driver'
common = (root / 'razercommon.c').read_text()
mouse = (root / 'razermouse_driver.c').read_text()
chroma = (root / 'razerchromacommon.c').read_text()
header = (root / 'razercommon.h').read_text()

def function(source, name):
    start = re.search(r'^.*\b' + name + r'\([^;]*?\)\n\{', source, re.M).start()
    end = source.index('\n}', start) + 2
    return source[start:end] + '\n'

prefix = r'''
#include <assert.h>
#include <errno.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
typedef unsigned int uint;
typedef unsigned long ulong;
#define GFP_KERNEL 0
#define HID_REQ_SET_REPORT 9
#define HID_REQ_GET_REPORT 1
#define USB_TYPE_CLASS 0x20
#define USB_RECIP_INTERFACE 1
#define USB_DIR_OUT 0
#define USB_DIR_IN 0x80
#define USB_CTRL_SET_TIMEOUT 5000
#define KERN_WARNING ""
#define KERN_ALERT ""
#define ARRAY_SIZE(x) (sizeof(x)/sizeof((x)[0]))
#define WARN_ON(x) (!!(x))
#define WARN_ONCE(x, ...) (!!(x))
#define printk(...) ((void)0)
#define kzalloc(n, f) calloc(1, n)
#define kfree free
#define simple_strtoul strtoul
#define clamp_u16(v, a, b) ((v)<(a)?(a):((v)>(b)?(b):(v)))
#define clamp_u8 clamp_u16
struct usb_device { struct { unsigned short idProduct; } descriptor; };
struct mutex { int held; };
static int lock_acquisitions;
#define lockdep_assert_held(m) assert((m)->held)
struct razer_mouse_device { struct usb_device *usb_dev; unsigned short usb_pid; struct mutex lock; struct { unsigned short poll; unsigned char dpi; } orochi2011; struct { unsigned char poll; } da3_5g; };
struct device { struct razer_mouse_device *data; };
struct device_attribute { int unused; };
static int kstrtou16(const char *s, unsigned int base, unsigned short *value) {
    char *end; unsigned long parsed;
    if (*s == '-') return -EINVAL;
    errno=0; parsed=strtoul(s,&end,base);
    if (errno || parsed>65535) return -ERANGE;
    if (end==s || (*end && strcmp(end,"\n"))) return -EINVAL;
    *value=parsed; return 0;
}
static void *dev_get_drvdata(struct device *d) { return d->data; }
static void mutex_lock(struct mutex *m) { assert(!m->held); m->held=1; lock_acquisitions++; }
static void mutex_unlock(struct mutex *m) { assert(m->held); m->held=0; }
static void usleep_range(ulong a, ulong b) { (void)a; (void)b; }
static int usb_sndctrlpipe(struct usb_device *d, int n) { (void)d; return n; }
static int usb_rcvctrlpipe(struct usb_device *d, int n) { (void)d; return n; }
static void *kmemdup(const void *data, size_t n, int flags) { (void)flags; void *p=malloc(n); if(p) memcpy(p,data,n); return p; }
'''
constants = '\n'.join(line for line in (header + '\n' + (root/'razermouse_driver.h').read_text()).splitlines()
                      if re.match(r'#define (RAZER_(USB_REPORT_LEN|CMD_\w+)|USB_DEVICE_ID_\w+|RAZER_\w+_WAIT_\w+)\s+', line))
structs = header[header.index('union transaction_id_union {'):header.index('struct razer_argb_report {')]
stubs = r'''
static int set_error, get_result, sets, gets, reply_status, reply_size, wrong_command, bad_reads, bad_crc_reads, wrong_tid, preserve_args, set_error_at, wrong_ack_at, status_at;
static unsigned char arg0, arg1;
static struct razer_report last_request, sent_reports[16];
static void deathadder3_5g_set_poll_rate(struct razer_mouse_device *d, unsigned short rate) { (void)d; (void)rate; abort(); }
static struct razer_report razer_chroma_misc_set_orochi2011_poll_dpi(unsigned short p, unsigned char x, unsigned char y) { (void)p; (void)x; (void)y; abort(); }
unsigned char razer_calculate_crc(struct razer_report *report);
static void print_erroneous_report(struct razer_report *r, char *d, char *m) { (void)r; (void)d; (void)m; }
static int usb_control_msg(struct usb_device *dev, int pipe, uint req, uint type, uint value, uint index, void *buf, uint size, int timeout) {
    (void)dev; (void)pipe; (void)type; (void)value; (void)index; (void)timeout;
    if (req == HID_REQ_SET_REPORT) { sets++; assert(sets<=16); memcpy(&last_request, buf, size); sent_reports[sets-1]=last_request; return set_error && (!set_error_at || sets==set_error_at) ? set_error : (int)size; }
    gets++;
    struct razer_report r = last_request;
    r.status = !status_at || gets==status_at ? reply_status : 2;
    if(reply_size >= 0) r.data_size = reply_size;
    if (!preserve_args) { r.arguments[0] = arg0; r.arguments[1] = arg1; }
    if (wrong_command || gets <= bad_reads) { r.command_class=4; r.command_id.id=0x85; }
    if (wrong_tid) r.transaction_id.id ^= 0x20;
    if (wrong_ack_at && gets==wrong_ack_at) r.arguments[0] ^= 1;
    r.crc = razer_calculate_crc(&r);
    if (bad_crc_reads < 0 || gets <= bad_crc_reads) r.crc ^= 1;
    memcpy(buf, &r, sizeof(r));
    return get_result;
}
static void reset(void) {
    set_error=sets=gets=wrong_command=bad_reads=bad_crc_reads=wrong_tid=preserve_args=set_error_at=wrong_ack_at=status_at=lock_acquisitions=0;
    get_result=90; reply_status=2; reply_size=-1; arg0=13; arg1=0;
}
'''
functions = [function(common, name) for name in ['razer_send_control_msg', 'razer_get_usb_response', 'razer_calculate_crc', 'get_razer_report']]
functions += [function(chroma, name) for name in ['razer_chroma_misc_get_idle_time','razer_chroma_misc_set_idle_time','razer_chroma_misc_get_low_battery_threshold','razer_chroma_misc_set_low_battery_threshold','razer_chroma_misc_get_polling_rate','razer_chroma_misc_get_polling_rate2','razer_chroma_misc_set_polling_rate','razer_chroma_misc_set_polling_rate2']]
functions += [function(mouse, name) for name in ['razer_get_report', 'razer_retryable_receiver_read', 'razer_send_payload_locked', 'razer_send_payload','razer_attr_read_charge_low_threshold','razer_attr_write_charge_low_threshold','razer_attr_read_device_idle_time','razer_attr_write_device_idle_time','razer_attr_read_poll_rate','razer_set_receiver_poll_rate','razer_attr_write_poll_rate'] if re.search(r'^static (?:int|bool) ' + name + r'\(', mouse, re.M) or name.startswith('razer_attr_')]
tests = r'''
int main(void) {
    struct usb_device usb = {.descriptor.idProduct=0x00c3};
    struct razer_mouse_device mouse = {.usb_dev=&usb, .usb_pid=0x00c3};
    struct device dev = {.data=&mouse};
    struct razer_report request = {.transaction_id.id=0x1f}, response;
    char out[64];
    reset(); set_error=-EPIPE; memset(&response, 0xff, sizeof(response));
    assert(razer_get_usb_response(&usb,0,&request,0,&response,1,2)==-EPIPE);
    assert(sets==1 && gets==0 && response.status==0);
    reset(); get_result=-ETIMEDOUT;
    assert(razer_get_usb_response(&usb,0,&request,0,&response,1,2)==-ETIMEDOUT);
    reset(); get_result=12;
    assert(razer_get_usb_response(&usb,0,&request,0,&response,1,2)==-EIO);
    assert(response.status==0);
    reset(); reply_size=81;
    assert(razer_get_usb_response(&usb,0,&request,0,&response,1,2)==-EPROTO);
    assert(response.data_size==0);
    reset();
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==3 && !strcmp(out,"13\n"));
    reset(); arg0=1; arg1=44;
    assert(razer_attr_read_device_idle_time(&dev,0,out)==4 && !strcmp(out,"300\n"));
    reset(); wrong_command=1; strcpy(out,"untouched");
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)<0 && !strcmp(out,"untouched"));
    reset(); wrong_command=1;
    assert(razer_attr_read_device_idle_time(&dev,0,out)<0);
    reset(); reply_size=0;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-EIO);
    reset(); reply_size=1;
    assert(razer_attr_read_device_idle_time(&dev,0,out)==-EIO);
    reset(); reply_status=1;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-EAGAIN);
    reset(); reply_status=0;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)<0);
    reset(); set_error=-EPIPE;
    assert(razer_attr_write_charge_low_threshold(&dev,0,"13",2)==-EPIPE && sets==1 && gets==0);
    reset(); set_error=-EPIPE;
    assert(razer_attr_write_device_idle_time(&dev,0,"300",3)==-EPIPE && sets==1 && gets==0);
    reset(); wrong_command=1;
    assert(razer_attr_write_charge_low_threshold(&dev,0,"13",2)<0 && sets==1);
    reset();
    assert(razer_attr_write_device_idle_time(&dev,0,"300",3)==3);
    reset(); bad_reads=1;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==3 && !strcmp(out,"13\n"));
    assert(sets==2 && gets==2);
    reset(); bad_crc_reads=1;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==3 && sets==2);
    reset(); bad_crc_reads=-1;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-EBADMSG && sets==3);
    reset(); wrong_command=1;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-EIO && sets==3);
    reset(); wrong_tid=1;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-EIO && sets==3);
    reset(); reply_status=4;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-ETIMEDOUT && sets==1);
    reset(); reply_status=5;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-EOPNOTSUPP && sets==1);
    reset(); reply_status=1;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-EAGAIN && sets==3);
    const unsigned char reads[][2] = {{4,0x85},{4,0x86},{7,0x80},{7,0x81},{7,0x83},{7,0x84}};
    for (unsigned int i=0; i<ARRAY_SIZE(reads); i++) {
        reset(); bad_crc_reads=1;
        request=get_razer_report(reads[i][0], reads[i][1], 2); request.transaction_id.id=0x1f;
        assert(razer_send_payload(&mouse,&request,&response)==0 && sets==2);
    }
    reset(); wrong_command=1;
    request=get_razer_report(4,0x06,38); request.transaction_id.id=0x1f;
    assert(razer_send_payload(&mouse,&request,&response)==-EIO && sets==1);
    reset(); wrong_command=1;
    request=get_razer_report(0,0x82,22); request.transaction_id.id=0x1f;
    assert(razer_send_payload(&mouse,&request,&response)==-EIO && sets==1);
    reset(); wrong_command=1; mouse.usb_pid=0x00c2;
    assert(razer_attr_read_charge_low_threshold(&dev,0,out)==-EIO && sets==1);
    mouse.usb_pid=0x00c3;
    const char *invalid_rates[] = {"0", "250", "999", "65536", "-1", "8000oops", ""};
    for(unsigned int i=0; i<ARRAY_SIZE(invalid_rates); i++) {
        reset();
        assert(razer_attr_write_poll_rate(&dev,0,invalid_rates[i],strlen(invalid_rates[i]))<0 && sets==0);
    }
    reset(); set_error=-EPIPE;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-EPIPE && sets==1 && gets==0);
    reset(); reply_status=1;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-EAGAIN && sets==1);
    reset(); wrong_command=1;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-EIO && sets==1);
    reset(); get_result=-ETIMEDOUT;
    assert(razer_attr_read_poll_rate(&dev,0,out)==-ETIMEDOUT);
    reset(); reply_size=0;
    assert(razer_attr_read_poll_rate(&dev,0,out)==-EIO);
    reset(); arg0=0; arg1=3;
    assert(razer_attr_read_poll_rate(&dev,0,out)==-EIO);
    reset(); arg0=0; arg1=1; reply_size=1;
    assert(razer_attr_read_poll_rate(&dev,0,out)==5 && !strcmp(out,"8000\n"));
    const unsigned short supported_rates[] = {125,500,1000,2000,4000,8000};
    const unsigned char rate_codes[] = {64,16,8,4,2,1};
    for (unsigned int i=0; i<ARRAY_SIZE(supported_rates); i++) {
        char value[16]; int length=snprintf(value,sizeof(value),"%u\n",supported_rates[i]);
        reset(); preserve_args=1;
        assert(razer_attr_write_poll_rate(&dev,0,value,length)==length);
        assert(sets==2 && gets==2 && lock_acquisitions==1 && mouse.lock.held==0);
        for(int mode=0; mode<2; mode++) {
            assert(sent_reports[mode].transaction_id.id==0x1f);
            assert(sent_reports[mode].command_class==0 && sent_reports[mode].command_id.id==0x40);
            assert(sent_reports[mode].arguments[0]==mode && sent_reports[mode].arguments[1]==rate_codes[i]);
        }
    }
    reset(); preserve_args=1; set_error=-EPIPE; set_error_at=2;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-EPIPE && sets==2 && gets==1);
    reset(); preserve_args=1; reply_status=4; status_at=2;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-ETIMEDOUT && sets==2);
    reset(); preserve_args=1; wrong_ack_at=2;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-EIO && sets==2);
    reset(); preserve_args=1; bad_crc_reads=1;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-EBADMSG && sets==1);
    reset(); preserve_args=1; reply_size=1;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-EIO && sets==1);
    reset(); preserve_args=1; wrong_tid=1;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==-EIO && sets==1);
    reset(); arg0=0; arg1=1; reply_size=1; bad_reads=1;
    assert(razer_attr_read_poll_rate(&dev,0,out)==5 && sets==2 && !strcmp(out,"8000\n"));
    reset(); preserve_args=1; mouse.usb_pid=USB_DEVICE_ID_RAZER_VIPER_8K;
    assert(razer_attr_write_poll_rate(&dev,0,"8000",4)==4 && sets==2);
    assert(sent_reports[0].transaction_id.id==0x1f && sent_reports[1].transaction_id.id==0xff);
    assert(mouse.lock.held==0);
    puts("PASS: transport failures, short/malformed replies, stale response rejection, power reads/writes, scoped retries, exhaustion, polling routing/acks/serialization/input validation");
}
'''
with tempfile.TemporaryDirectory(prefix='openrazer-driver-tests-') as tmp:
    src = Path(tmp)/'check.c'; exe = Path(tmp)/'check'
    src.write_text(prefix+'\n'+constants+'\n'+structs+'\n'+stubs+'\n'+'\n'.join(functions)+tests)
    subprocess.run([os.environ.get('CC','cc'),'-std=gnu11','-Wall','-Wextra','-Wno-sign-compare','-Wno-unused-parameter','-Wno-unused-function','-fsanitize=address,undefined','-g',str(src),'-o',str(exe)],check=True)
    subprocess.run([str(exe)],check=True)

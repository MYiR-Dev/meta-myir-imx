#!/usr/bin/env python3
import threading
import time,os,sys

bt_param={'name':'bt_test','tid':-1,'result':0,'thread_flag':1,'dsc':'prepare to test'}
firmware=r'brcm_patchram_plus -d --enable_hci --no2bytes --tosleep 200000 --baudrate 3000000 --patchram /lib/firmware/bcmd/BCM4345C5_AP6256_CL1.hcd /dev/ttymxc0  >/dev/null 2>&1 &'
SUCCESS=1
FAIL=2

class myThread(threading.Thread):
    def __init__(self,name,args):
        threading.Thread.__init__(self)
        self.setName('new'+name)
        self.name=name
        self.args=args
        self.key = None
        self.draw = None
        x=self.read_popen('ps -aux | grep brcm_patchram_plus | wc -l')
        if int(x)  == 2:
            print("run brcm_patchram_plus")
            os.system(firmware)

    def read_popen(self,command):
        p=os.popen(command)
        x=p.read()
        p.close()
        return x

    def run(self):
        print(bt_param['name'] + " start to test")
        start_time = time.time()
        while bt_param['thread_flag'] == 1:
            mtime=20
            while mtime>0:
                x=self.read_popen('rfkill list | grep hci0')
                print('popen rfkill hci0' + x)
                bt_param['dsc']='detect rfkill hci0'
                if len(x):
                    index=x.split(':')[0]
                    command = 'rfkill unblock ' + str(index)
                    bt_param['dsc']='rfkill unblock ' + str(index)
                    print('unblock' + command)
                    os.system(command)
                    command = 'hciconfig hci0 up'
                    bt_param['dsc']='hciconfig hci0 up'
                    print('hci0 up')
                    os.system(command)
                    print('hcitoo; scan')
                    bt_param['dsc']='hcitool scan'
                    x= self.read_popen('hcitool scan')
                    print(x)
                    print(len(x.split()))

                    if len(x.split('\n')) <=2:
                        bt_param['dsc'] = 'scan nothing'
                    else:
                        bt_param['dsc'] = x.split('\n')[1]
                        print(bt_param['dsc'])
                        bt_param['result'] = SUCCESS
                        bt_param['thread_flag'] = 0
                        break


                
                mtime-=1
                time.sleep(1)
            if mtime == 0:
                bt_param['thread_flag'] = 0
                bt_param['dsc']='can not found hci0'
                bt_param['result']=FAIL
        end_time= time.time()
        test_time = round(end_time-start_time)
        print(bt_param['name'] + " test end " + " result:" + str(bt_param['result']) + " total time:"+ str(test_time))


if __name__=='__main__':
    thread1=myThread(bt_param['name'],None)
    thread1.run()
else:
    bt_param['tid'] = myThread(bt_param['name'],None)

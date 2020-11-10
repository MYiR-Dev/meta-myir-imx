#!/usr/bin/env python3
import threading
import time,os,sys

wifi_param={'name':'wifi_test','tid':-1,'result':0,'thread_flag':1,'dsc':'prepare to test'}
SUCCESS=1
FAIL=2
wifi_ssid='HUAWEI_B316_CA1C'
wifi_5g_ssid='360WiFi-4FF7C3-5G'
passwd='Myir@2018'
wlan_name='wlan0'

class myThread(threading.Thread):
    def __init__(self,name,args):
        threading.Thread.__init__(self)
        self.setName('new'+name)
        self.name=name
        self.args=args
        self.key = None
        self.draw = None

    def run(self):
        print(wifi_param['name'] + " start to test")
        start_time = time.time()
        while wifi_param['thread_flag'] == 1:
            wifi_param['dsc']="start to connect:" + wifi_ssid
            command='ifup_wifi_sta' + ' -ssid '  + wifi_ssid + ' -passwd ' + passwd +' &'
            print(command)  
            os.system(command)
            mtime=60
            command='wpa_cli' + ' -i'+ wlan_name + " -p/var/run/wpa_supplicant status | grep wpa_state | awk -F[=] '{print $2}'"
            print(command)
            while mtime > 0:
                p = os.popen(command)
                x=p.read()
                p.close()
                wifi_param['dsc']=wifi_ssid + ' : ' + x
                if x.startswith('COMPLETED'):
                    wifi_param['result'] = SUCCESS
                    wifi_param['thread_flag'] = 0
                    break
                mtime-=1
                time.sleep(1)
            if mtime == 0:
                wifi_param['thread_flag'] = 0
                wifi_param['result'] = FAIL

        end_time= time.time()
        test_time = round(end_time-start_time)
        print(wifi_param['name'] + " test end " + " result:" + str(wifi_param['result']) + " total time:"+ str(test_time))


if __name__=='__main__':
    thread1=myThread(wifi_param['name'],None)
    thread1.run()
else:
    wifi_param['tid'] = myThread(wifi_param['name'],None)
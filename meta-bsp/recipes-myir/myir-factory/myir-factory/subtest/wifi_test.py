#!/usr/bin/env python3
import threading
import time,os,sys

wifi_param={'name':'wifi_test','tid':-1,'result':0,'thread_flag':1,'dsc':'prepare to test'}
SUCCESS=1
FAIL=2
wifi_ssid='MYS-8MMX'
wifi_5g_ssid='MYS-8MMX-5G'
passwd='12345678'
wlan_name='wlan0'

class myThread(threading.Thread):
    def __init__(self,name,args):
        threading.Thread.__init__(self)
        self.setName('new'+name)
        self.name=name
        self.args=args
        self.key = None
        self.draw = None

    def read_popen(self,command):
        p=os.popen(command)
        x=p.read()
        p.close()
        return x

    def convert_wifi_data(self,command):
        mdata = {}
        key = []
        value = []
        mstring=self.read_popen(command)
        for i in mstring.split('\n'):
            if i.count('='):
                mkey,mvalue = i.split('=')
                key.append(mkey)
                value.append(mvalue)

        mdata=dict(zip(key,value))

        return mdata

    def connnect_wifi(self,m_wlan,m_ssid,m_passwd):
        wifi_param['dsc']="start to connect:" + m_ssid
        command='ifup_wifi_sta' + ' -ssid '  + m_ssid + ' -passwd ' + m_passwd +' &'
        print(command)  
        wifi_param['dsc']='start to connect:' + ' ' + m_ssid 
        os.system(command)
        mtime=30
        command='wpa_cli' + ' -i'+ m_wlan + " -p/var/run/wpa_supplicant status "
        print(command)
        while mtime > 0:

            data=self.convert_wifi_data(command)

            if len(data) :

                if 'wpa_state' in data.keys():
                    wifi_param['dsc'] = m_ssid + ':' +data['wpa_state']
                
                if 'ssid' in data.keys()  and 'freq' in data.keys()  and 'ip_address' in data.keys() and data['ssid'] == m_ssid:
                    wifi_param['dsc'] = m_ssid + ':' + 'freq:'+data['freq'] + ' ' + 'ip:' + data['ip_address']
                    break

 
            mtime-=1
            time.sleep(1)
        
        if mtime == 0:
            return FAIL
        else:
            return SUCCESS



    def run(self):
        print(wifi_param['name'] + " start to test")
        start_time = time.time()
        while wifi_param['thread_flag'] == 1:
            ret = self.connnect_wifi(wlan_name,wifi_ssid,passwd)
            if (ret == FAIL):
                wifi_param['dsc'] = wifi_ssid + " test Fail"
                wifi_param['thread_flag'] = 0
                wifi_param['result'] = FAIL
                break

            ret = self.connnect_wifi(wlan_name,wifi_5g_ssid,passwd)
            if (ret == FAIL):
                wifi_param['dsc'] = wifi_5g_ssid + " test Fail"
                wifi_param['thread_flag'] = 0
                wifi_param['result'] = FAIL
            else:
                wifi_param['result'] = SUCCESS
                wifi_param['thread_flag'] = 0



        end_time= time.time()
        test_time = round(end_time-start_time)
        print(wifi_param['name'] + " test end " + " result:" + str(wifi_param['result']) + " total time:"+ str(test_time))


if __name__=='__main__':
    thread1=myThread(wifi_param['name'],None)
    thread1.run()
else:
    wifi_param['tid'] = myThread(wifi_param['name'],None)
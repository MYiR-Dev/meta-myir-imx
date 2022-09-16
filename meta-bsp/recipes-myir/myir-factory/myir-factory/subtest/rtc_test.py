#!/usr/bin/env python3
import threading
import time,os,sys,re

rtc_param={'name':'rtc_test','tid':-1,'result':0,'thread_flag':1,'dsc':'prepare to test'}
SUCCESS=1
FAIL=2
RTC_PATH='/dev/rtc0'

class myThread(threading.Thread):
    def __init__(self,name,args):
        threading.Thread.__init__(self)
        self.setName('new'+name)
        self.name=name
        self.args=args
        self.key = None
        self.draw = None


    def run(self):
        start_time = time.time()

        while rtc_param['thread_flag'] == 1:
            command = 'hwclock -w'
            rtc_param['dsc'] = command
            os.system(command)

            command = 'hwclock'
            rtc_param['dsc'] = command
            p = os.popen(command)
            x = p.read()
            p.close()

            rtc_param['dsc'] = x
            print(x)
            if(re.match('[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]',x,re.M)):
                rtc_param['result']=SUCCESS
            else:
                rtc_param['result']=FAIL
            rtc_param['thread_flag'] = 0
        end_time= time.time()
        test_time = round(end_time-start_time)
        print(rtc_param['name'] + " test end " + " result:" + str(rtc_param['result']) + " total time:"+ str(test_time))



if __name__=='__main__':
    thread1=myThread(rtc_param['name'],None)
    thread1.run()
else:
    rtc_param['tid'] = myThread(rtc_param['name'],None)





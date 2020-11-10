#!/usr/bin/env python3
import threading
import time,os,sys
import random,string

key_param={'name':'key_test','tid':-1,'result':0,'thread_flag':1,'dsc':'wait key press'}
SUCCESS=1
FAIL=2


class myThread(threading.Thread):
    def __init__(self,name,args):
        threading.Thread.__init__(self)
        self.setName('new'+name)
        self.name=name
        self.args=args
        self.key = self.send_key
        self.draw = None
        
    def send_key(self,key):
        # print(key)
        if key == 49:
            key_param['result'] = SUCCESS
            key_param['dsc']='GET KEY: ' + str(key)



    def run(self):
        start_time = time.time()

        while key_param['thread_flag'] == 1:
            mtime=60
            while mtime > 0:
                if key_param['result'] == SUCCESS:
                    key_param['thread_flag'] =0 
                    break
                mtime-=1
                time.sleep(1)
            if mtime == 0:
                key_param['result'] = FAIL
                key_param['thread_flag'] =0 
        end_time= time.time()
        test_time = round(end_time-start_time)
        print(key_param['name'] + " test end " + " result:" + str(key_param['result']) + " total time:"+ str(test_time))



if __name__=='__main__':
	thread1=myThread(key_param['name'],2)
	thread1.run()
else:
	key_param['tid'] = myThread(key_param['name'],2)





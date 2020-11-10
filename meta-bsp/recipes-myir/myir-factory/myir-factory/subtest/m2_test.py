#!/usr/bin/env python3
import threading
import time,os,sys
m2_param={'name':'m2_test','tid':-1,'result':0,'thread_flag':1,'dsc':'prepare to test'}
SUCCESS=1
FAIL=2
PROC_MOUNTS='/proc/mounts'
M2_name='/dev/nvme'
test_file="factory.text"
factory_text='FACTORY_TEST'

class myThread(threading.Thread):
    def __init__(self,name,args):
        threading.Thread.__init__(self)
        self.setName('new'+name)
        self.name=name
        self.args=args
        self.key = None
        self.draw = None
        
    def run(self):
        print(m2_param['name'] + " start to test")
        start_time = time.time()
        while m2_param['thread_flag'] == 1:
            mtime=20
            while mtime>0:
                try:
                    with open('/proc/mounts','r') as f:
                        for line in f:
                            if line.find('/dev/nvme') != -1:
                                mount_path=line.split(' ')[1]
                                m2_param['dsc']='find nvme mount point:'+mount_path
                                absolute_file_path=mount_path+os.sep+test_file
                                with open(absolute_file_path,'w+') as write_f:
                                    write_f.write(factory_text)
                                    m2_param['dsc']='write complete'
                                os.system('sync')
                                with open(absolute_file_path,'r+') as read_f:
                                    for read_line in read_f:
                                        if read_line.find(factory_text) != -1:
                                            m2_param['result']=SUCCESS
                                            m2_param['dsc']='compare ok'
                                            m2_param['thread_flag'] = 0
                                        else:
                                            m2_param['result']=FAIL
                                            m2_param['dsc']='compare fail'

                except:
                    print(" except.{}".format(sys.exc_info()[0]))
                finally:
                    if m2_param['result'] == SUCCESS:
                        # print("success break")
                        break

                mtime-=1
                time.sleep(1)
            if mtime == 0:
                m2_param['thread_flag'] = 0
                m2_param['dsc']='test fail'
                m2_param['result']=FAIL
        end_time= time.time()
        test_time = round(end_time-start_time)
        print(m2_param['name'] + " test end " + " result:" + str(m2_param['result']) + " total time:"+ str(test_time))


if __name__ == '__main__':
	
	thread1=myThread(m2_param['name'],None)
	thread1.run()
else:
	m2_param['tid']=myThread(m2_param['name'],None)


#!/usr/bin/env python3
import threading
import time,os,sys
import random,string

qspi_param={'name':'qspi_test','tid':-1,'result':0,'thread_flag':1,'dsc':'prepare to test'}
SUCCESS=1
FAIL=2
QSPI_SIZE='0x2000000'
QSPI_DEV='/dev/mtd0'
RANDOM_SIZE=10
OFFSIZE='0x10'

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

        while qspi_param['thread_flag'] == 1:
            command='mtd_debug erase' + ' ' + QSPI_DEV + ' ' + '0' + ' ' + QSPI_SIZE
            qspi_param['dsc']=command
            os.system(command)

            mstring=''
            num=string.ascii_letters+string.digits
            for i in range(RANDOM_SIZE):
                mstring+=random.choice(num)   
            qspi_param['dsc']="write string: " + mstring
            with open('qspi_random_write','w') as f:
                f.write(mstring)

            command='mtd_debug write'+ ' ' + QSPI_DEV + ' ' + 'OFFSIZE' + ' ' + str(RANDOM_SIZE) +' ' + 'qspi_random_write'
            qspi_param['dsc']=command
            os.system(command)
			
            command='mtd_debug read'+ ' ' + QSPI_DEV + ' ' + 'OFFSIZE' + ' ' + str(RANDOM_SIZE) +' ' + 'qspi_random_read'
            qspi_param['dsc']=command
            os.system(command)

            with open('qspi_random_read','r') as f:
                read_strings=f.read()

            qspi_param['dsc']="write : " + mstring + ' '+' string: '+ read_strings
            if mstring == read_strings :
                qspi_param['result'] = SUCCESS
            else:
                qspi_param['result'] = FAIL

            qspi_param['thread_flag'] = 0
        end_time= time.time()
        test_time = round(end_time-start_time)
        print(qspi_param['name'] + " test end " + " result:" + str(qspi_param['result']) + " total time:"+ str(test_time))



if __name__=='__main__':
	thread1=myThread(qspi_param['name'],None)
	thread1.run()
else:
	qspi_param['tid'] = myThread(qspi_param['name'],None)




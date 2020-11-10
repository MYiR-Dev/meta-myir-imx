#!/usr/bin/env python3
import threading
import time,os,sys

net_param={'name':'net_test','tid':-1,'result':0,'thread_flag':1,'dsc':'prepare to test'}
SUCCESS=1
FAIL=2
NET_NAME='eth0'
LOCAL_IP ="192.168.40.127"
TARGET_IP ="192.168.40.2"



class myThread(threading.Thread):
	def __init__(self,name,args):
		threading.Thread.__init__(self)
		self.setName('new'+name)
		self.name=name
		self.args=args
		self.key = None
		self.draw = None

	def get_ping_result(self,net_name):

		try:

			command='ping ' + TARGET_IP + ' ' + ' -c 1 -I' +' ' + net_name 
			net_param['dsc']=command
			p = os.popen(command)
			x=p.read()
			p.close()
			if (x.count('1 received')):
				print('obtain net request')
				net_param['dsc']='obtain net request'
				return True
			else:
				net_param['dsc']='can not obtain net request'
				return False
		except:
			print("Unexpected error:", sys.exc_info()[0])
			return False

	def run(self):
		start_time = time.time()
		command='ifconfig '+' '+NET_NAME+' '+LOCAL_IP
		net_param['dsc']=command
		os.system(command)
		mtime=0
		while net_param['thread_flag'] == 1:
			ret = self.get_ping_result(NET_NAME)
			if ret == True:
				net_param['thread_flag']=0
				net_param['result'] = SUCCESS
	
			mtime+=1
			time.sleep(1)
			if mtime > 2:
				net_param['result'] = FAIL
				break
		end_time= time.time()
		test_time = round(end_time-start_time)
		print(net_param['name'] + " test end " + " result:" + str(net_param['result']) + " total time:"+ str(test_time))



if __name__=='__main__':
	thread1=myThread(net_param['name'],None)
	thread1.run()
else:
	net_param['tid'] = myThread(net_param['name'],None)

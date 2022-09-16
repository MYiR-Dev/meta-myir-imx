#!/usr/bin/env python3
import threading
import time,os,sys,re
import random,string

usb_param={'name':'usb_param','tid':-1,'result':0,'thread_flag':1,'dsc':'prepeare'}
SUCCESS=1
FAIL=2


PROC_MOUNTS='/proc/mounts'
test_file="factory.text"
factory_text='FACTORY_TEST'

node_point='/sys/bus/usb/drivers/usb'
usb_point='/sys/devices/platform'
usb={'usb1':0,'usb2':0,'typec':0}
usb_index=['usb1','usb2','typec']
usb_location={'usb1':'USB_TOP','usb2':'USB_BOTTOM','typec':'TYPEC'}
USB_NUMBER=3

class myThread(threading.Thread):
    def __init__(self,name,args):
        threading.Thread.__init__(self)
        self.setName('new'+name)
        self.name=name
        self.args=args
        self.key = None
        self.draw = None


    def get_mount_result(self,path):
        with open(PROC_MOUNTS,'r+') as f:
            for line in f:
                if line.startswith(path):
                    print('find mount point:'+line)
                    mount_path=line.split(' ')[1]
                    absolute_file_path=mount_path+os.sep+test_file
                    if os.access(absolute_file_path,os.F_OK) :
                        command='rm '+absolute_file_path
                        os.system(command)
                    try:
                        print('prepare to write :' + absolute_file_path)
                        with open(absolute_file_path,'w') as write_f:
                            write_f.write(factory_text)
                        os.system('sync')

                        with open(absolute_file_path,'r') as read_f:
                            for read_line in read_f:
                                print('read_line:'+ read_line)
                                if read_line.find(factory_text) != -1:
                                    print('write read success')
                                    return 1
                    except:
                        print("Unexpected error:", sys.exc_info()[0])
                        return 0
                    else:
                        return 0

    def get_file(self,path,l):
        fileList = os.listdir(path)
        #print(path)
        for filename in fileList:
            #print(filename)
            pathTmp=os.path.join(path,filename)
            # if filename[filename.rfind('/')+1:].startswith('sd'):
            if re.match('sd[a-z]',filename[filename.rfind('/')+1:],re.M):
                print("find path.{}".format(filename))
                l.append(pathTmp)
            elif os.path.isdir(pathTmp) and os.path.islink(pathTmp) == False:
                self.get_file(pathTmp,l)

    def update_usb_dsc(self):
        usb_param['dsc']=''
        for i in usb_index:
            usb_param['dsc'] +=usb_location[i] + ' ' + str(usb[i]) + ' '
          

    def run(self):
        start_time = time.time()

        while usb_param['thread_flag'] :
            mtime=20
            while mtime > 0:
                fileList = os.listdir(node_point)
                for filename in fileList:
                    # print(filename)
                    if re.match('[1]-[1].[1-2]',filename,re.M):
                        # print('usb'+filename[filename.rfind('.')+1:])
                        if usb['usb'+filename[filename.rfind('.')+1:]] !=1:
                            usb['usb'+filename[filename.rfind('.')+1:]]=filename
                    
                    elif re.match('[2]-[1]',filename,re.M):
                        # print(filename)	
                        if usb['typec'] !=1:
                            usb['typec']=filename

                self.update_usb_dsc()
                l=[]
                self.get_file(usb_point,l)
                print(l)
                #print("end find usb_point")

                for i in range(USB_NUMBER):
                    #print(usb[usb_index[i]])
                    temp_usb=usb[usb_index[i]]
                    print(temp_usb)
                    if temp_usb == 0 or temp_usb ==1:
                        continue
                    if temp_usb is not None and len(temp_usb) > 1:
                        for point in l:
                            if point.find(temp_usb) != -1:
                                usb_name=point[point.rfind('/')+1:]
                                print("usb_name.{}".format(usb_name))
                                dev_name='/dev' + os.sep + usb_name
                                print(dev_name)
                                usb[usb_index[i]]=self.get_mount_result(dev_name)
                                print("result .{}".format(usb[usb_index[i]]))
                                self.update_usb_dsc()
                                break
                k = 0
                for i in range(USB_NUMBER):
                    if usb[usb_index[i]] == 1:
                        k += 1
                        if k == USB_NUMBER:
                            usb_param['thread_flag']=0
                            usb_param['result'] = SUCCESS
                if usb_param['result'] == SUCCESS:
                    break

                mtime-=1
                time.sleep(1)
            if mtime == 0:
                usb_param['thread_flag'] = 0
                usb_param['result'] = FAIL

        end_time= time.time()
        test_time = round(end_time-start_time)
        print(usb_param['name'] + " test end " + " result:" + str(usb_param['result']) + " total time:"+ str(test_time))



if __name__=='__main__':
    thread1=myThread(usb_param['name'],None)
    thread1.run()
else:
    usb_param['tid'] = myThread(usb_param['name'],None)





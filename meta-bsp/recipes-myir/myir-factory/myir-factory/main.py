#!/usr/bin/env python3
# -*- coding: utf-8 _*_
__author__ = "coin du"
__copyright__ = "Copyright (C) 2020 MYIR TECH"


import cv2
import numpy as np
import random,string
import time
import sys

from subtest import m2_test
from subtest import wifi_test
from subtest import bt_test
from subtest import net_test
from subtest import qspi_test
from subtest import usb_test
from subtest import rtc_test
from subtest import key_test
from subtest import gpio_test

class Myirfactory():
 
    def __init__(self,m_title,m_picture,m_test_list,m_csi_mode=None):
        self.title = m_title
        self.picture = m_picture
        self.test_list = m_test_list
        self.test_total = len(self.test_list)
        self.success_num = 0
        self.testing_num=0
        self.fail_num=0
        self.img = np.zeros((1080,1444,3),np.uint8)
        self.img[:,:]=(255,255,255)
        self.flag = True
        self.fontFace = cv2.FONT_HERSHEY_SIMPLEX
        self.fontScale = 1.0
        self.thick = 3
        self.interval=10
        self.green=(0,255,0)
        self.blue=(255,0,0)
        self.red=(0,0,255)
        self.black=(0,0,0)
        self.white=(255,255,255)
        self.grey=(192,192,192)
        self.yellow=(0,255,255)
        self.start=(50,50)
        self.csi_mode=m_csi_mode
        self.csi_cap = None
        self.start_time = time.time()
        self.current_time=self.start_time
        self.cpu_temp = None
        if self.csi_mode is not None:
            self.csi_cap = cv2.VideoCapture(self.csi_mode)
        cv2.imshow(self.title,self.img)

    def run_subtest(self):
        for item in self.test_list:
            item['tid'].start()
    
    def get_cpu_temp(self):
        with open('/sys/class/thermal/thermal_zone0/temp','r') as f:
            self.cpu_temp = f.read()


    def display_text(self,x,y,text,text_color,back_color):
        (text_width,text_height),baseline=cv2.getTextSize(text,self.fontFace,self.fontScale,self.thick)
        cv2.rectangle(self.img,(x, y + baseline - self.thick),(x + text_width,y - text_height - self.thick),back_color,-1)
        cv2.putText(self.img,text,(x,y),self.fontFace,self.fontScale,text_color,thickness=self.thick,bottomLeftOrigin=0)
        y += text_height+baseline+ self.interval
        return x,y
    def display_item(self):
        # (img_height,img_width)=self.img.shape
        self.img[:,:]=self.white
        img_height,img_width,pixel = self.img.shape

        # for test bar
        x = self.start[0]
        y = self.start[1]

        text = 'FACTORY TEST LIST: '
        x,y = self.display_text(x,y,text,self.yellow,self.grey)

        self.success_num = 0
        self.fail_num=0
        self.testing_num=0
        for item in self.test_list:
            text = item['name'] + " : " +item['dsc']
            if item['result'] == 1 :
                self.success_num +=1
                text = '[OK]' + text
                x,y = self.display_text(x,y,text,self.black,self.green)
            elif item['result'] == 2 :
                self.fail_num +=1
                text = '[FAIL]' + text
                x,y = self.display_text(x,y,text,self.black,self.red)
            else:
                self.testing_num+=1
                text = '[TESTING]' + text
                x,y = self.display_text(x,y,text,self.black,self.white)

            if item['tid'].draw is not None: 
                ir = item['tid'].draw()
                item_height,item_width=ir.shape[:2]
                self.img[y:y+item_height ,x:x+ item_width]=ir
                y += item_height+ self.interval

        # i have no idea about how to display gpio_key item.. 
        # so callback gpio_key param
        # for item in self.test_list:
        #     if item['tid'].draw is not None: 
        #         ir = item['tid'].draw()
        #         item_height,item_width=ir.shape[:2]
        #         self.img[y:y+item_height ,x:x+ item_width]=ir
        #         y += item_height+ self.interval

        # for status bar
        y= img_height-300


        text = 'FACTORY STATUS LIST: '
        x,y = self.display_text(x,y,text,self.yellow,self.grey)



        self.get_cpu_temp()
        text = 'CPU TEMP: ' + str(self.cpu_temp)
        x,y = self.display_text(x,y,text,self.black,self.white)

        if self.test_total != self.success_num:
            self.current_time = time.time()
        text = 'RUN TIME: ' + str(round(self.current_time-self.start_time))
        x,y = self.display_text(x,y,text,self.black,self.white)


        #display result 
        x= img_width -300
        y= img_height -400
        text = str(self.success_num) +'/' +str(self.test_total)
        self.fontScale *=2
        if self.success_num == self.test_total:
            x,y=self.display_text(x,y,'PASS',self.black,self.green)
        else:
            x,y=self.display_text(x,y,'FAIL',self.black,self.red)
        self.fontScale /=2
        text = "TOTAL: " + str(self.test_total)
        x,y=self.display_text(x,y,text,self.black,self.grey)
        text = "SUCCUESS: " + str(self.success_num)
        x,y=self.display_text(x,y,text,self.black,self.grey)
        text = "FAIL: " + str(self.fail_num)
        x,y=self.display_text(x,y,text,self.black,self.grey)
        text = "TESTING: " + str(self.testing_num)
        x,y=self.display_text(x,y,text,self.black,self.grey)

        if self.csi_cap is not None:
            try:
                frame = self.csi_cap.read()
                csi_height,csi_width = frame[1].shape[:2]
                r_height=(int)(csi_height/2)
                r_width=(int)(csi_width/2)
                ir=cv2.resize(frame[1],(r_width,r_height))
                self.img[0:0+r_height,img_width-r_width:img_width]=ir
            except :
                print(" except.{}".format(sys.exc_info()[0]))
        cv2.imshow(self.title,self.img)

    def random_update_date(self):
        for item in self.test_list:
            item['result']=random.randint(0,2)
            item['dsc']=''
            num=string.ascii_letters+string.digits
            for i in range(10):
                item['dsc']+=random.choice(num)   
               
            

    def wait_exit_key(self):
        while self.flag:
            # self.random_update_date()
            self.display_item()
            key = cv2.waitKey(delay=50)

            if key == 49:
                for item in self.test_list:
                    if item['tid'].key is not None:
                        item['tid'].key(key)
            elif key == 50:
                item['thread_flag'] = 0
                self.flag=False
                cv2.destroyAllWindows()
                if self.csi_cap is not None:
                    self.csi_cap.release()
                break

if __name__ == '__main__':
    title='mys-8mmx factory'
    picture = r'/home/root/mys-board.jpg'
    csi="v4l2src ! video/x-raw,width={},height={} ! videoconvert ! appsink".format(640,480)
    test=[]

    
    test.append(wifi_test.wifi_param)
    test.append(bt_test.bt_param)
    test.append(net_test.net_param)
    test.append(m2_test.m2_param)
    test.append(qspi_test.qspi_param)
    test.append(usb_test.usb_param)
    test.append(rtc_test.rtc_param)
    test.append(key_test.key_param)
    test.append(gpio_test.gpio_param)

    factory_test = Myirfactory(title,picture,test,csi)
    factory_test.run_subtest()
    factory_test.wait_exit_key()

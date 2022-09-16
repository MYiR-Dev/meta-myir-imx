#!/usr/bin/env python3
import threading
import time,os,sys,re
import numpy
import cv2

gpio_param={'name':'gpio_param','tid':-1,'result':0,'thread_flag':1,'dsc':'prepeare'}
SUCCESS=1
FAIL=2



gpio_match={
    'VDD_3V3':-1,'VDD_3V3':-1,'VDD_1V8':-1,'DGND':-1,'GPIO1_IO09_33':9,
    'SAI3_TXFS':127,'SAI3_MCLK':130,'SAI3_TXD':129,'SAI3_RXD':126,'SAI3_RXFS':124,'I2C2_SCL33':144,
    'I2C2_SDA33':145,'DSI_BL_EN':8,'PDM_DATA3':88,'PDM_DATA0':85,'SAI5_MCLK':89,'SAI1_MCLK':116,
    'SAI2_TXC':121,'SAI2_TXFS':120,'UART4_RXD':156,'UART4_TXD':157,'UART3_RXD':134,'UART3_CTS':136,
    'ECSPI2_MISO':140,'ECSPI2_SS0':141,
    'VDD_5V':-1,'VDD_5V':-1,'DGND':-1,'DGND':-1,'4G_USB_DM':-1,'4G_USB_DP':-1,
    'DGND':-1,'XH_USB_DM':-1,'XH_USB_DP':-1,'SAI3_TXC':128,'SAI3_RXC':125,'GPIO1_IO05':5
    ,'PDM_DATA2':87,'PDM_CLK':84,'PDM_DATA1':86, 'SAI1_TXC':107,'SAI1_TXFS':106,'SAI2_TXD':122,
    'SAI2_RXD':119,'USB2_ID':-1,'I2C4_SDA':149,'ECSPI2_SCLK':138,'ECSPI2_MOSI':139,'UART3_RTS':137,
    'UART3_TXD':135
}

class myThread(threading.Thread):
    def __init__(self,name,args):
        threading.Thread.__init__(self)
        self.setName('new'+name)
        self.name=name
        self.args=args
        self.key = None
        self.draw = self.get_label
        self.raw=2
        self.col=25
        self.radius = 5
        self.white = (255,255,255)
        self.black = (0,0,0)
        self.green=(0,255,0)
        self.red=(0,0,255)
        self.grey=(192,192,192)
        self.label_width = self.col*(self.radius*5)+self.radius*2
        self.label_height = self.raw*(self.radius*5)+self.radius*2
        self.label_patch = numpy.zeros((self.label_height,self.label_width,3),numpy.uint8)
        self.label_patch[:,:]=self.white
        self.gpio_list=[]
        for i in range(self.raw):
            for j in range(self.col):
                x = self.radius*(2+5*j)
                y = self.radius*(2+5*i)
                self.gpio_list.append((x,y))

        self.gpio_part1=[[10,self.gpio_list[4],'GPIO1_IO09_33',0,0],[14,self.gpio_list[6],'SAI3_MCLK',0,0],[18 ,self.gpio_list[8],'SAI3_RXD',0,0],[26,self.gpio_list[12],'DSI_BL_EN',0,0]
,[30,self.gpio_list[14],'PDM_DATA0',0,0],[34,self.gpio_list[16],'SAI1_MCLK',1,0],[36,self.gpio_list[17],'SAI2_TXC',0,0],[42,self.gpio_list[20],'UART4_TXD',0,0]
,[46,self.gpio_list[22],'UART3_CTS',0,0],[19,self.gpio_list[34],'SAI3_TXC',0,0],[25,self.gpio_list[37],'PDM_DATA2',0,0],[29,self.gpio_list[39],'PDM_DATA1',0,0]
,[23,self.gpio_list[36],'GPIO1_IO05',1,0],[37,self.gpio_list[43],'SAI2_RXD',1,0],[43,self.gpio_list[46],'ECSPI2_SCLK',0,0],[47,self.gpio_list[48],'UART3_RTS',0,0]
,[50,self.gpio_list[24],'ECSPI2_SS0',0,0]
]
        self.gpio_part2=[[12,self.gpio_list[5],'SAI3_TXFS',0,0],[16,self.gpio_list[7],'SAI3_TXD',0,0],[20,self.gpio_list[9],'SAI3_RXFS',0,0],[28,self.gpio_list[13],'PDM_DATA3',0,0]
,[32,self.gpio_list[15],'SAI5_MCLK',0,0],[40,self.gpio_list[19],'UART4_RXD',1,0],[38,self.gpio_list[18],'SAI2_TXFS',0,0],[44,self.gpio_list[21],'UART3_RXD',0,0]
,[48,self.gpio_list[23],'ECSPI2_MISO',0,0],[21,self.gpio_list[35],'SAI3_RXC',0,0],[27,self.gpio_list[38],'PDM_CLK',0,0],[31,self.gpio_list[40],'SAI1_TXC',0,0]
,[35,self.gpio_list[42],'SAI2_TXD',1,0],[41,self.gpio_list[45],'I2C4_SDA',1,0],[45,self.gpio_list[47],'ECSPI2_MOSI',0,0],[49,self.gpio_list[49],'UART3_TXD',0,0]
,[33,self.gpio_list[41],'SAI1_TXFS',0,0]
]

        for i in self.gpio_list:
            cv2.line(self.label_patch,(i[0]-self.radius,i[1]),(i[0]+self.radius,i[1]),self.black,1)
            cv2.line(self.label_patch,(i[0],i[1]-self.radius),(i[0],i[1]+self.radius),self.black,1)
        print(self.label_patch.shape)
        for pt1,pt2 in zip(self.gpio_part1,self.gpio_part2):
            cv2.circle(self.label_patch,pt1[1],self.radius,self.red,-1,)
            cv2.circle(self.label_patch,pt2[1],self.radius,self.red,-1)
            if pt1[3] == 0:
                cv2.line(self.label_patch,pt1[1],pt2[1],self.red,1)
            elif pt1[3] == 1:
                cv2.line(self.label_patch,pt1[1],(pt1[1][0],pt1[1][1]+2*self.radius),self.red,1)
                cv2.line(self.label_patch,pt2[1],(pt2[1][0],pt1[1][1]+2*self.radius),self.red,1)
                cv2.line(self.label_patch,(pt1[1][0],pt1[1][1]+2*self.radius),(pt2[1][0],pt1[1][1]+2*self.radius),self.red,1)

    def get_label(self):
        return self.label_patch

    def update_label(self):
        for pt1,pt2 in zip(self.gpio_part1,self.gpio_part2):
            if pt1[4] == 0:
                cv2.circle(self.label_patch,pt1[1],self.radius,self.red,-1,)
                cv2.circle(self.label_patch,pt2[1],self.radius,self.red,-1)
                if pt1[3] == 0:
                    cv2.line(self.label_patch,pt1[1],pt2[1],self.red,1)
                elif pt1[3] == 1:
                    cv2.line(self.label_patch,pt1[1],(pt1[1][0],pt1[1][1]+2*self.radius),self.red,1)
                    cv2.line(self.label_patch,pt2[1],(pt2[1][0],pt1[1][1]+2*self.radius),self.red,1)
                    cv2.line(self.label_patch,(pt1[1][0],pt1[1][1]+2*self.radius),(pt2[1][0],pt1[1][1]+2*self.radius),self.red,1)
            elif pt1[4] == 1:
                cv2.circle(self.label_patch,pt1[1],self.radius,self.green,-1,)
                cv2.circle(self.label_patch,pt2[1],self.radius,self.green,-1)
                if pt1[3] == 0:
                    cv2.line(self.label_patch,pt1[1],pt2[1],self.green,1)
                elif pt1[3] == 1:
                    cv2.line(self.label_patch,pt1[1],(pt1[1][0],pt1[1][1]+2*self.radius),self.green,1)
                    cv2.line(self.label_patch,pt2[1],(pt2[1][0],pt1[1][1]+2*self.radius),self.green,1)
                    cv2.line(self.label_patch,(pt1[1][0],pt1[1][1]+2*self.radius),(pt2[1][0],pt1[1][1]+2*self.radius),self.green,1)

    def gpio_export(self):
        for i,j in zip(self.gpio_part1,self.gpio_part2):
            # print("i.{} j.{}".format(i[2],j[2]))
            node='/sys/class/gpio/gpio'+ repr(gpio_match[i[2]])
            print(node)
            if not os.access(node,os.F_OK):
                command='echo'+' ' + repr(gpio_match[i[2]]) + ' ' +'> /sys/class/gpio/export'
                os.system(command)
                command = 'echo out > /sys/class/gpio/gpio'+ repr(gpio_match[i[2]]) + '/direction' 
                os.system(command)	

            node='/sys/class/gpio/gpio'+ repr(gpio_match[j[2]])
            if not os.access(node,os.F_OK):
                command='echo'+' ' + repr(gpio_match[j[2]]) + ' ' +'> /sys/class/gpio/export'
                os.system(command)
                command = 'echo in > /sys/class/gpio/gpio'+ repr(gpio_match[j[2]]) + '/direction' 
                os.system(command)

    def run(self):
        start_time = time.time()
        self.gpio_export()
        while gpio_param['thread_flag'] :
            mtime=10
            while mtime > 0:
                num = 0
                for i,j in zip(self.gpio_part1,self.gpio_part2):
                    ret = 0
                    m_out = repr(gpio_match[i[2]])
                    m_in =  repr(gpio_match[j[2]])
                    # print("out:{} in:{}".format(m_out,m_in))
                    command='echo 0 > /sys/class/gpio/gpio' + m_out +'/value'
                    os.system(command)
                    command='/sys/class/gpio/gpio'+m_in+'/value'
                    with open(command,'r') as f:
                        for line in f:
                            if line.count('0'):
                                # print("out:{} in:{} write 0 success line{}".format(m_out,m_in,line))
                                ret = 1

                    command='echo 1 > /sys/class/gpio/gpio' + m_out +'/value'
                    os.system(command)
                    command='/sys/class/gpio/gpio'+m_in+'/value'
                    with open(command,'r') as f:
                        for line in f:
                            if line.count('1'):
                                # print("out:{} in:{} write 1 success".format(m_out,m_in))
                                ret &= 1
                            else :
                                ret = 0
                    
                    if ret == 1:
                        # print("test ok {}{}".format(i[2],j[2]))
                        gpio_param['dsc'] = "test ok {}-{}".format(i[2],j[2])
                        i[4] = 1
                        j[4] = 1   
                        num +=1
                self.update_label()
                if num == len(self.gpio_part1) :
                    gpio_param['dsc'] = "gpio test success"
                    gpio_param['thread_flag'] = 0
                    gpio_param['result'] = SUCCESS
                    break

                mtime-=1
                time.sleep(1)
            if mtime == 0:
                gpio_param['thread_flag'] = 0
                gpio_param['result'] = FAIL
                gpio_param['dsc'] = "test fail "

        end_time= time.time()
        test_time = round(end_time-start_time)
        print(gpio_param['name'] + " test end " + " result:" + str(gpio_param['result']) + " total time:"+ str(test_time))



if __name__=='__main__':
    thread1=myThread(gpio_param['name'],None)
    thread1.run()
else:
    gpio_param['tid'] = myThread(gpio_param['name'],None)
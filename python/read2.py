import serial


def read_byte(s):
    return int((s.read(1)).encode('hex'),16)

def convert(byte,s):
	if 125 == byte:
		if 94 == read_byte(s): 
			byte = 126
		else:
			byte = 125
	return byte

s = serial.Serial(port='COM3', baudrate=115200)
byte = read_byte(s)
newpack = False
l = 0
values = {}
List=[]
V_List=[]
H_List=[]

for j in range(0,3000):
   
	if 126 == byte:
		if 126 == read_byte(s):
			if 0 == read_byte(s):
				if 126 == read_byte(s):
					newpack = True
					print '--'
					print 'len: ',l
					print '---'
					l = 0
					#for i in range(0,12):
					#    byte = convert(read_byte(s),s)
					for i in range(1,80):
						byte = read_byte(s)
						#print byte
						byte = convert(byte,s)
						l += 1
						#print l, byte
						if (15 < i) and (80 > i):
							index = i -16
							#if (index /8) == 0:
							#    print '\n'
							List.append(byte)
							if(index/8==7 and index%8==7):
								v_sum=0
								for x in range(0,64):
									print List[x],;
									v_sum=v_sum+List[x]
									if(x%8==7):
										print '\t',v_sum/8
										v_sum=0
								List[:]=[]
							#print index/8, index%8, byte, '\t'
						
	newpack = False
	byte = read_byte(s)                    

#!/usr/bin/env python
import socket

address = ('',31500)
s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.bind(address)
s.listen(5)

while 1:
	cs,addr = s.accept()
	print 'got connected from',addr
	while 1:
		data = cs.recv(1024)
		if not data:
			break
		cs.send('[%s] %s' %("you send:",data))
		print 'get data >',data
	cs.close()
s.close()

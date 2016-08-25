#! /usr/bin/env python
#coding=utf-8

import os
import sys
import websocket

def main():
   argc = len(sys.argv)
   if argc != 3:
        print('Usage: %s <num_connect>  <num_request>' % sys.argv[0])
        sys.exit(1)

   num_connect = int(sys.argv[1])
   num_request = int(sys.argv[2])

   if (num_connect <= 0) or (num_request <= 0):
         print('Input values must be greater than zero')
         sys.exit(1)

   #websocket.enableTrace(True)
   ws = websocket.WebSocket()
   for num in xrange(num_connect):
   	print 'Connect # %d' % (num + 1)
   	ws.connect("ws://188.225.38.222/echo")
   else:
   	print "\n\r---\n\r"	

   for num in xrange(num_request):
   	print 'Request # %d' % (num + 1)
   	ws.send("")
      
   ws.close()	

if __name__ == "__main__":
	main()
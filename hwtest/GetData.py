# This file will be dedicated to classes and functions that retrieve data from the server

import SetHardware
# from epics import caget, caput, camonitor, camonitor_clear
import time

class StreamData:

	def __init__(self, bay):

		if bay == 0:

			# Written as stream0 in matlab readStreamData.m
			# Represents the imaginary component of complex phasor data
			self.q_stream = 'dans_epics:AMCc:Stream0'

			# Written as stream1 in matlab code readStreamData.m
			# This data represents the real component in complex phasor data
			self.i_stream = 'dans_epics:AMCc:Stream1'

		elif bay == 1:

			# Written as stream0 in matlab readStreamData.m
			# Represents the imaginary component of complex phasor data
			self.q_stream = 'dans_epics:AMCc:Stream4'

			# Written as stream1 in matlab code readStreamData.m
			# This data represents the real component in complex phasor data
			self.i_stream = 'dans_epics:AMCc:Stream5'

		else:
			print("ERROR: Bay unrecognized. Set to default 0")
			self.q_stream = 'dans_epics:AMCc:Stream0'
			self.i_stream = 'dans_epics:AMCc:Stream1'

		# Initializing data arrays for the i and q data
		self.get_new_idata = None
		self.get_new_qdata = None
		self.monitor_idata()

	def monitor_idata(self):
		# Extract the value passed to i_data from the monitor

		# grabs the data from the first monitor string
		# in my testing, camonitor will write to list upon initialization
		# sometimes it will write the same value twice upon initialization
		previous_data = new_idata_list[0].split(' ')[-1]

		# Checks if data received is different than the initialized data
		# While loop will continue checking for new data until self.get_new_idata is no longer None
		while self.get_new_idata is None:

			# ~~For use in Server~~
			# new_idata_list = []
			# camonitor(self.i_stream, writer=lambda arg: new_idata_list.append(arg))

			# ~~For use on this machine~~
			new_idata_list = ['test:dummyTree:AxiVersion:Scratc 2019-08-06 08:24:26.16236 0',
			                  'test:dummyTree:AxiVersion:Scratc 2019-08-06 08:24:26.16978 0',
			                  'test:dummyTree:AxiVersion:Scratc 2019-08-06 08:24:38.65490 2']
			
			for string in new_idata_list:
				data = string.split(' ')[-1]
				if data == previous_data:
					# This would occur if camonitor initializes two or more strings with same initial value
					self.get_new_idata = None
					print("No new idata")
					print("Current data:", data)
				else:
					# once we get new data this statement should execute
					self.get_new_idata = 1
					print("New idata received")
					print("New data;", data)
			time.sleep(0.1)

		# !!!!!Uncomment below line for use in EPICs!!!!!!!!
		# camonitor_clear(self.i_stream)


	def monitor_qdata(self, arg):
		# Extract the value passed to q_data from the monitor

		# ~~For use in Server~~
		# new_qdata_list = []
		# camonitor(self.q_stream, writer=lambda arg: new_qdata_list.append(arg))

		self.get_new_qdata = None

	def wait_data(self):

		while self.get_new_idata == None or self.get_new_qdata == None:
			time.sleep(0.1)

		return self.idata, self.qdata


if __name__ == "__main__":
	# Testing StreamData class and idata monitor function
	data = StreamData(bay=0)
else:
	print("GetData accessed from import")
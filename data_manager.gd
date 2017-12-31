# Author: Radu Bolovan
# This file is under MIT license.
# You can use it in any way you want. Read MIT license for more info @ https://opensource.org/licenses/MIT.
# Adding me in credits of your project is not mandatory, but it's much appreciated.

extends Node

# file status
const FILE_DOESNT_EXISTS = -2
const FILE_ALREADY_OPENED = -1
const FILE_OPENED_OK = 0

# file state
enum file_state {
	file_idle = 0,
	file_reading,
	file_writing
}
var m_file_state = file_idle

enum processing_state {
	process_not_started = 0,
	process_not_finished,
	process_finished
}

# file properties
var m_file = null # file to read from or to write to
var m_buffer = null # buffer used to read from file into it
var m_string_to_write = "" # string to write to file
var m_bytes_per_frame_to_process = 16 # bytes count to read / write per frame
var m_finished = process_not_started # the flag that says if the reading / writing is done
var m_write_current_idx = 0 # index to use for the current index from the string
var m_write_end_idx = 0 # the last index used to write a string in a frame

# _process function is not executed if a file is not opened
# check read / write functions below
func _process(delta):
	# safe check if a file is opened.
	if(m_file == null):
		print("Error: file is not opened")
		if(m_buffer != null):
			m_buffer.resize(0)
		set_process(false)
		return

	# check reading state
	if(m_file_state == file_reading):
		if(m_file.eof_reached()):
			m_buffer.resize(m_file.get_len())
			m_file.close()
			m_file = null
			m_finished = process_finished
			# stop processing if finished the job
			set_process(false)
			return
		# print("reading from file ...")
		m_buffer.append_array(m_file.get_buffer(m_bytes_per_frame_to_process))

	# check writing state
	elif(m_file_state == file_writing):
		# compute the last index that should be write into the file
		m_write_end_idx = m_write_current_idx + m_bytes_per_frame_to_process
		var current_string = ""
		# add in the current string to be written in the file
		for idx in range(m_write_current_idx, m_write_end_idx):
			if(idx >= m_string_to_write.length()):
				m_finished = process_finished
				break
			current_string += m_string_to_write[idx]
		print("writing string to file: " + current_string)
		# write the current string into the file
		m_file.store_string(current_string)
		m_write_current_idx += m_bytes_per_frame_to_process
		if(m_finished == process_finished):
			m_file.close()
			m_file = null
			# stop processing if finished the job
			set_process(false)

# parameters:
# path: path to the file for reading the data from. E.G. "user://data.dat"
# bytes_per_frame_to_process: the count of the bytes to be read in a frame. E.G. 16
# encrypted: if the file is encrypted or not
# password: the password of the file. If the file is not encrypted, this doesn't have any effect
func read(path, bytes_per_frame_to_process, encrypted = false, password = ""):
	# check if the file is already opened
	if(m_file != null):
		print("Error: File \'" + path + "\' is already opened!")
		return FILE_ALREADY_OPENED

	# create a new file
	m_file = File.new()

	# check if the file exists
	if(!m_file.file_exists(path)):
		print("Error: File \'" + path + "\' doesn't exists!")
		m_file = null
		return FILE_DOESNT_EXISTS

	# open the file for reading
	var opened = -1
	if(encrypted):
		opened = m_file.open_encrypted_with_pass(path, File.READ, password)
	else:
		opened = m_file.open(path, File.READ)
	print("File opened for reading with status: " + str(opened))

	# init the reading buffer
	if(m_buffer == null):
		m_buffer = RawArray()
	else:
		m_buffer.resize(0)

	# setup properties for reading the file
	m_bytes_per_frame_to_process = bytes_per_frame_to_process
	m_finished = process_not_finished
	m_file_state = file_reading
	set_process(true)
	return FILE_OPENED_OK

# parameters:
# path: path to the file for reading the data from. E.G. "user://data.dat"
# data: the type must be a Dictionary. Read more about dictionaries here: http://docs.godotengine.org/en/stable/classes/class_dictionary.html
# bytes_per_frame_to_process: the count of the bytes to be read in a frame. E.G. 16
# encrypted: if the data is encrypted or not
# password: the password of the file. If the file is not encrypted, this doesn't have any effect
func write(path, data, bytes_per_frame_to_process, encrypted = false, password = ""):
	# check if the file is already opened
	if(m_file != null):
		print("Error: File \'" + path + "\' is already opened!")
		return FILE_ALREADY_OPENED

	# create a new file
	m_file = File.new()

	# open the file for writing
	var opened = -1
	if(encrypted):
		opened = m_file.open_encrypted_with_pass(path, File.WRITE, password)
	else:
		opened = m_file.open(path, File.WRITE)
	print("File opened for writing with status: " + str(opened))

	# setup the writing string
	m_string_to_write = data.to_json()

	# setup properties for writing the file
	m_bytes_per_frame_to_process = bytes_per_frame_to_process
	m_finished = process_not_finished
	m_file_state = file_writing
	set_process(true)
	return FILE_OPENED_OK

func get_file_state():
	return m_file_state

# returns processing state; see processing_state
func has_finished_job():
	return m_finished

# returns an RawArray
func get_buffer():
	return m_buffer

# returns a string
func get_data_as_string():
	return m_buffer.get_string_from_utf8()

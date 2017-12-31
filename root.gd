# Author: Radu Bolovan
# This file is under MIT license.
# You can use it in any way you want. Read MIT license for more info @ https://opensource.org/licenses/MIT.
# Adding me in credits of your project is not mandatory, but it's much appreciated.

extends Control

var m_default_profile = {
	m_level = 1,
	m_experience = 0,
	m_energy = 0,
	m_coins = 0,
	m_attack = 1,
	m_defense = 1,
	m_magic = 1
}

var m_file_path = "user://data.dat"
var m_profile = {}
var m_data_password = "my_pass"

var m_file_status = g_data_manager.FILE_OPENED_OK

func _ready():
	m_profile = m_default_profile
	# try to read from file
	m_file_status = g_data_manager.read(m_file_path, 16, true, m_data_password)

	# if the file doesn't exist, save the default profile
	if(m_file_status == g_data_manager.FILE_DOESNT_EXISTS):
		g_data_manager.write(m_file_path, m_default_profile, 16, true, m_data_password)

	set_process(true)

func _process(delta):
	if(g_data_manager.get_file_state() == g_data_manager.file_reading):
		if(g_data_manager.has_finished_job() == g_data_manager.process_finished):
			print("Profile: " + m_profile.to_json())
			m_profile.parse_json(g_data_manager.get_data_as_string())
			print("Profile: " + m_profile.to_json())
			set_process(false)

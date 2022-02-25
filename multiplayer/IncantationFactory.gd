extends Node


var operation_factory: OperationFactory

var nb_threads_max: int = 12
var parallel_threads: Array

func _ready():
	operation_factory = OperationFactory.new()
	parallel_threads = []
	for i in range(nb_threads_max):
		parallel_threads.append(Thread.new())
		
func generate_incantation_threaded(data):
	if get_tree().is_network_server():
		var pattern = data[0]
		var task_nb = data[1]
		var new_operation_list = []
		var new_operation
		for p_element in pattern:
			new_operation = operation_factory.generate(p_element)
			new_operation_list.append(new_operation)
		print("Tache numero " + str(task_nb) + "terminée")
		return new_operation_list
		
func incantation_generated():
	pass
	
func generate_incantations(pattern, n: int):
	var new_incantations = []
	var i = 0
	var nb_active: int
	while i < n:
		#assign tasks to threads
		nb_active = 0
		while nb_active < nb_threads_max and i < n:
			print("Tache numéro "+str(i))
			parallel_threads[nb_active].start(self, "generate_incantation_threaded", [pattern, i])
			nb_active += 1
			i += 1
			
		#waiting
		while nb_active > 0:
			new_incantations.append(parallel_threads[nb_active-1].wait_to_finish())
			nb_active -= 1
			print(nb_active)
			print("array: " + str(new_incantations))
	print("Generation finished !")
	return new_incantations
	
func generate_incantations_not_threaded(pattern, n: int):
	var new_incantations = []
	var new_operation_list
	var new_operation
	for i in range(n):
		new_operation_list = []
		for p_element in pattern:
			new_operation = operation_factory.generate(p_element)
			new_operation_list.append(new_operation)
		print(new_operation_list)
		new_incantations.append(new_operation_list)
	return new_incantations

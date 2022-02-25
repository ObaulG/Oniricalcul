extends Node


var operation_factory: OperationFactory


func _ready():
	operation_factory = OperationFactory.new()

func generate_incantation_threaded(pattern):
	if get_tree().is_network_server():
		var new_operation_list = []
		var new_operation
		for p_element in pattern:
			new_operation = operation_factory.generate(p_element)
			new_operation_list.append(new_operation)
		return new_operation_list
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

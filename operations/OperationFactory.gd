extends Node

class_name OperationFactory

const nbMethodeCarree3 = [25,30,40,50,60,100,1000]

const dividors = {
	1: [2, 4],
	2: [10]
}

const OPERATION = global.OPERATIONS

const easy_bases = [2, 10]
const normal_bases = [2, 10, 16]

var rng
var current_seed

var perfect_squares: PoolIntArray = []
func _init():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	current_seed = rng.seed
	for i in range(1001):
		perfect_squares.append(i*i)
		
func generate(pattern_el: Array):
	var calcul_type = pattern_el[0]
	var diff = pattern_el[1]
	var subtype
	if len(pattern_el) == 3:
		subtype = pattern_el[2]
	else:
		subtype = -1
	var calcul
	match calcul_type:
		OPERATION.ADDITION:
			calcul = generateAddition(diff, subtype)
		OPERATION.SUBSTRACTION:
			calcul = generateSubstraction(diff, subtype)
		OPERATION.PRODUCT:
			calcul = generateProduct(diff, subtype)
		OPERATION.CONVERSION:
			calcul = generateConversion(diff, subtype)
	return calcul
	
#generates a dict containing the data to generate the operation
func generate_operation_dict_from_pattern_element(pattern_el: Array):
	var operation = generate(pattern_el)
	var dict = {
		"type": operation.get_type(),
		"diff": operation.get_diff(),
		"operands": operation.get_operands(), #array
		"result": operation.get_result()
	}
	return dict

#we'd prefer call this one because the operation is already generated
func generate_operation_dict_from_operation(operation):
	var dict = {
		"type": operation.get_type(),
		"diff": operation.get_diff(),
		"operands": operation.get_operands(), #array
		"result": operation.get_result()
	}
	return dict
	
func generate_single_args(calcul_type, diff):
	return generate([calcul_type, diff])
	
#generating the object on client side from dict because we can't send objets via rpcs.
func generate_operation_from_dict(op_dict: Dictionary):
	var calcul
	var type = op_dict["type"]
	var diff = op_dict["diff"]
	var operands = op_dict["operands"]
	match type:
		OPERATION.ADDITION:
			calcul = Addition.new(operands[0], operands[1], diff, type, -1)
		OPERATION.SUBSTRACTION:
			calcul = Substraction.new(operands[0], operands[1], diff, type, -1)
		OPERATION.PRODUCT:
			calcul = Product.new(operands[0], operands[1], diff, type, -1)
		OPERATION.CONVERSION:
			calcul = Conversion.new(operands[0], operands[1], operands[2], 4, type, -1)
	return calcul
	
func choice(L: Array):
	return L[rng.randi() % L.size()]
	
func random_minus_sign_for_2_numbers(nb1, nb2) -> Array:
	var alea = rng.randf()
	if alea < 0.33:
		nb1 = - nb1
	elif alea < 0.67:
		nb2 = - nb2
	else:
		nb1 = - nb1
		nb2 = - nb2
	return [nb1, nb2]
	
func generateAddition(diff := 1, subtype := -1):
	rng.randomize()
	var nb1 = 0
	var nb2 = 0
	var duo = [diff, subtype]
	match duo:
		[1, -1]:
			nb1 = rng.randi_range(0,9)
			nb2 = rng.randi_range(0,9)
		[1, 2]:
			#var dividor = choice(dividors[diff])
			nb1 = choice([-1,1])
			nb2 = rng.randi_range(0,9)
		[2, -1]:
			nb1 = rng.randi_range(1,9)
			nb2 = rng.randi_range(1,100)
		[3, -1]:
			nb1 = rng.randi_range(16,60)
			nb2 = rng.randi_range(10,50)
		[4, -1]:
			nb1 = rng.randi_range(100,800)
			nb2 = rng.randi_range(100,800)
		[5, -1]:
			nb1 = rng.randi_range(1600,9000)
			nb2 = rng.randi_range(500,9999)

	var a = Addition.new(nb1, nb2, diff, 1, subtype)
	return a
	
func generateSubstraction(diff := 1, subtype := -1):
	rng.randomize()
	var nb1 = 0
	var nb2 = 0
	match diff:
		1:
			nb1 = rng.randi_range(0,9)
			nb2 = rng.randi_range(0,nb1)
		2:
			nb1 = rng.randi_range(11,50)
			nb2 = rng.randi_range(1,10)
		3:
			nb1 = 100
			nb2 = rng.randi_range(1,100)
		4:
			nb1 = rng.randi_range(175,800)
			nb2 = rng.randi_range(175,800)
		5:
			nb1 = rng.randi_range(1600,9000)
			nb2 = rng.randi_range(500,9999)
			
	var a = Substraction.new(nb1, nb2, diff, 2, subtype)
	return a
	
func generateProduct(diff := 1, subtype := -1):
	rng.randomize()
	var nb1 = 0
	var nb2 = 0
	match diff:
		1:
			nb1 = rng.randi_range(1,5)
			nb2 = rng.randi_range(0,5)
		2:
			nb1 = rng.randi_range(3,11)
			nb2 = rng.randi_range(2,10)
		3:
			nb1 = rng.randi_range(12,24)
			nb2 = rng.randi_range(9,20)
		4:
			var base  = nbMethodeCarree3[rng.randi_range(0,nbMethodeCarree3.size()-1)]
			var ecart = rng.randi_range(1,6)
			
			nb1 = base - ecart
			nb2 = base + ecart
		5:
			nb1 = rng.randi_range(23,94)
			nb2 = rng.randi_range(27,97)
			
	var a = Product.new(nb1, nb2, diff, 3, subtype)
	return a
	
func generateConversion(diff := 1, subtype := -1):
	rng.randomize()
	var start_base
	var start_number
	var final_base
	match diff:
		1:
			start_number = rng.randi_range(0,8)
		2:
			start_number = rng.randi_range(4,32)
		3:
			start_number = rng.randi_range(32,64)
		4:
			start_number = rng.randi_range(64,128)
		5:
			start_number = rng.randi_range(255,1024)
	
	if diff < 3:
		var z = rng.randi_range(0,1)
		if z == 0:
			start_base = 2
			final_base = 10
		else:
			start_base = 10
			final_base = 2
	else:
		var bases = normal_bases.duplicate()
		var i_1 = rng.randi_range(0,len(bases))
		start_base = bases[i_1]
		bases.remove(i_1)
		var i_2 = rng.randi_range(0,len(bases))
		final_base = bases[i_2]

	var a = Conversion.new(start_base, start_number, final_base, 4, OPERATION.keys()[OPERATION.CONVERSION], subtype)
	return a

func generateExponentiation(diff: int, subtype: int):
	rng.randomize()
	
	var n: int
	var p: int = 2
	match diff:
		1:
			n = rng.randi_range(0,9)
		2:
			n = 2
			p = rng.randi_range(0,8)
		3:
			n = 2
			n = rng.randi_range(9,16)
		4:
			p = 3
			n = rng.randi_range(3,9)
	
	var op = Exponentiation.new(n, p, diff, 5)
	
func generateRoot(diff, subtype):
	rng.randomize()
	#n is the square root, and the index of
	#an element of the array perfect squares
	var n: int
	match diff:
		1:
			n = rng.randi_range(0,5)
		2:
			n = rng.randi_range(4,10)
		3:
			n = rng.randi_range(9,16)
		4:
			n = rng.randi_range(3,9)
	
	var op = SquareRootOP.new(perfect_squares[n], diff, 6)
	
func generateFracSimp(diff, subtype):
	pass
	
func generateFracAdd(diff, subtype):
	pass
	
func generateFracMul(diff, subtype):
	pass

func generateQCM(type, diff, subtype):
	pass
	
	

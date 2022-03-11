extends Object

class_name Fraction

var numerator: int
var denominator: int


func _init(num: int, den: int):
	numerator = num
	if den == 0:
		den += 1
	denominator = den
	
func simplify():
	var pgcd = factors_pgcd()
	if pgcd > 1:
		numerator = numerator / pgcd
		denominator = denominator / pgcd
	
func multiply_factors(n: int):
	numerator *= n
	denominator *= n
	
func add(frac: Fraction):
	var num = frac.numerator
	var den = frac.denominator
	
	if den == denominator:
		numerator += num
	else:
		var new_common_den = Math.ppcm(den, denominator)
		var coeffA = int(new_common_den/denominator)
		var coeffB = int(new_common_den/den)
		multiply_factors(coeffA)
		frac.multiply_factors(coeffB)
		numerator += frac.numerator
		
func mul(frac: Fraction):
	numerator *= frac.numerator
	denominator *= frac.denominator
	
func div(frac: Fraction):
	numerator *= frac.denominator
	denominator *= frac.numerator
	
func inv():
	var t = numerator
	numerator = denominator
	denominator = t

func power(n: int):
	numerator = int(pow(numerator, n))
	denominator = int(pow(denominator, n))
	

func factors_pgcd() -> int:
	return Math.pgcd(numerator, denominator)

func is_irreductible() -> bool:
	return factors_pgcd() == 1

func equals(num: int, den: int) -> bool:
	return max(num, numerator) / min(num, numerator) == max(den, denominator) / min(denominator, den)
	
func equals_frac(frac: Fraction) -> bool:
	return equals(frac.numerator, frac.denominator)
	
func get_numerator() -> int:
	return numerator
	
func get_denominator() -> int:
	return denominator

extends Object

class_name Math

static func pgcd(nb1: int, nb2: int) -> int:
	var a = max(nb1, nb2)
	var b = min(nb1, nb2)
	var c: int
	while b > 1:
		c = b
		b = a % b
		a = c
	return a

static func ppcm(a: int, b: int) -> int:
	return int(abs(a*b)/pgcd(a,b))

"""
	Bonus task: load all the available coffee recipes from the folder 'recipes/'
	File format:
		first line: coffee name
		next lines: resource=percentage

	info and examples for handling files:
		http://cs.curs.pub.ro/wiki/asc/asc:lab1:index#operatii_cu_fisiere
		https://docs.python.org/3/library/io.html
		https://docs.python.org/3/library/os.path.html
"""

RECIPES_FOLDER = "recipes"

import io

def load_recipes(type_coffee: str) -> str:
	directory = f"{RECIPES_FOLDER}/{type_coffee}.txt"
	recipe = ""

	with open(directory, 'r') as f:
		f.readline()
		for line in f:
			recipe += line

	return recipe
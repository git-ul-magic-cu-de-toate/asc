"""
A command-line controlled coffee maker.
"""

import sys
import load_recipes
import io

"""
Implement the coffee maker's commands. Interact with the user via stdin and print to stdout.

Requirements:
    - use functions
    - use __main__ code block
    - access and modify dicts and/or lists
    - use at least once some string formatting (e.g. functions such as strip(), lower(),
    format()) and types of printing (e.g. "%s %s" % tuple(["a", "b"]) prints "a b"
    - BONUS: read the coffee recipes from a file, put the file-handling code in another module
    and import it (see the recipes/ folder)

There's a section in the lab with syntax and examples for each requirement.

Feel free to define more commands, other coffee types, more resources if you'd like and have time.
"""

"""
Tips:
*  Start by showing a message to the user to enter a command, remove our initial messages
*  Keep types of available coffees in a data structure such as a list or dict
e.g. a dict with coffee name as a key and another dict with resource mappings (resource:percent)
as value
"""

# Commands
EXIT = "exit"
LIST_COFFEES = "list"
MAKE_COFFEE = "make"  #!!! when making coffee you must first check that you have enough resources!
HELP = "help"
REFILL = "refill"
RESOURCE_STATUS = "status"
commands = [EXIT, LIST_COFFEES, MAKE_COFFEE, REFILL, RESOURCE_STATUS, HELP]

# Coffee examples
ESPRESSO = "espresso"
AMERICANO = "americano"
CAPPUCCINO = "cappuccino"

coffees = [ESPRESSO, AMERICANO, CAPPUCCINO]

# Resources examples
WATER = "water"
COFFEE = "coffee"
MILK = "milk"

# Coffee maker's resources - the values represent the fill percents
RESOURCES = {WATER: 100, COFFEE: 100, MILK: 100}

"""
Example result/interactions:

I'm a smart coffee maker
Enter command:
list
americano, cappuccino, espresso
Enter command:
status
water: 100%
coffee: 100%
milk: 100%
Enter command:
make
Which coffee?
espresso
Here's your espresso!
Enter command:
refill
Which resource? Type 'all' for refilling everything
water
water: 100%
coffee: 90%
milk: 100%
Enter command:
exit
"""

commands = [EXIT, LIST_COFFEES, MAKE_COFFEE, REFILL, RESOURCE_STATUS, HELP]

def list_coffees():
    print("These are the available coffees:")
    for coffee in coffees:
        print(coffee)

def make_coffee():
    type_coffee = input("Please choose a coffee: \n")
    recipe = load_recipes.load_recipes(type_coffee)

    for line in io.StringIO(recipe):
        line.split("=")
        print(line)

def refill():
    resource = input("Which resource would you like to refill?"
    " Type \"all\" for refilling all")

    if resource == "water":
        RESOURCES[WATER] = 100
    elif resource == "coffee":
        RESOURCES[COFFEE] = 100
    elif resource == "milk":
        RESOURCES[MILK] = 100

def status():
    print(f"water: {RESOURCES[WATER]}% \n"
    f"coffee: {RESOURCES[COFFEE]}% \n"
    f"milk: {RESOURCES[MILK]}%")

def check_command(command: str):
    if command == EXIT:
            exit()
            print("Bye bye")
    elif command == LIST_COFFEES:
        list_coffees()
    elif command == MAKE_COFFEE:
        make_coffee()
    elif command == REFILL:
        refill()
    elif command == RESOURCE_STATUS:
        status()
    elif command == HELP:
        print(f"Available commands are {commands}")

if __name__ == "__main__":
    print("I'm a smart coffee maker")
    
    while True:
        command = input("Enter command: \n")
        
        check_command(command)


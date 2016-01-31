# ShakespearePL-Swift

## Objective

This is an attempt to parse the [Shakespeare Programming Language](http://shakespearelang.sourceforge.net/report/shakespeare/). You can find all the langauge specs on their website.

## Procedure

There are three parts of the program - a tokenizer, a parser and a simulator. The tokenizer breaks input into tokens; the parser picks up the tokens and construct a list of top level abstract syntax trees; finally the simulator runs the AST and spit out output.

## Usage

	// Input is a String
	let parser = Parser(input: input)
    do {
        let nodes = try parser.parse()
        Simulator().runNodes(nodes)
    } catch {
        print(error)
    }

## Help Needed

The second example (Primes.spl) from the [official website](http://shakespearelang.sourceforge.net/report/shakespeare/) does not really work. Please let me know where I did wrong.

